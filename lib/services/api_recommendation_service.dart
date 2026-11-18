import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/formatters.dart';
import '../models/ai_recommendation.dart';
import '../models/customer_context.dart';
import '../models/merchant.dart';
import '../models/payment_product.dart';
import '../models/payment_recommendation.dart';
import 'api_status.dart';
import 'http_client.dart';
import 'recommendation_service.dart';

/// Asks the recommendation API (XGBoost propensities + utility function)
/// which payment method to suggest, and turns the answer into a ranked
/// product list.
///
/// The app tells the API what the customer has (balance, credit usage and
/// payment methods, taken from their products) and the API picks the
/// *method* (credit, debit or transfer) among the ones they can pay with.
/// The product inside that method is picked with the local reward rules.
/// If the API fails, takes too long or doesn't cover the purchase, the
/// result is the plain rule-based ranking, so the payment flow never
/// depends on the network.
class ApiRecommendationService {
  ApiRecommendationService({
    http.Client? client,
    String? baseUrl,
    this.timeout = ApiConfig.timeout,
    this.retryTimeout = ApiConfig.retryTimeout,
    this.rules = const RecommendationService(),
    ApiStatus? status,
  })  : _client = client ?? createHttpClient(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        // A service pointed somewhere else (tests) gets its own status, so
        // it never reads or changes the state of the app's API.
        status = status ??
            (client == null && baseUrl == null
                ? ApiStatus.instance
                : ApiStatus(client: client, baseUrl: baseUrl));

  final http.Client _client;
  final String _baseUrl;

  /// Deadline of the first attempt.
  final Duration timeout;

  /// Deadline of the second attempt, made after the API woke up.
  final Duration retryTimeout;

  /// Local reward rules: the fallback, and the tie-breaker between products
  /// of the same payment method.
  final RecommendationService rules;

  /// Whether the API is awake.
  final ApiStatus status;

  /// [onWaking] is called when the API gave no answer and the service starts
  /// waiting for it to wake up, so the screen can say so.
  Future<PaymentRecommendation> recommend({
    required Merchant merchant,
    required List<PaymentProduct> products,
    required String profileId,
    void Function()? onWaking,
  }) async {
    final byRules = rules.rank(merchant: merchant, products: products);
    final purchase = _body(
      merchant,
      profileId,
      CustomerContext.fromProducts(products),
    );

    final AiRecommendation ai;
    try {
      ai = await _fetchAwake(purchase, onWaking);
    } catch (_) {
      return byRules.withNotice(
        'No hubo respuesta del modelo de IA. Se usaron las reglas de beneficios.',
        canRetryAi: true,
      );
    }
    if (!ai.available) {
      return byRules.withNotice(
        'El modelo de IA no cubre esta categoría. Se usaron las reglas de beneficios.',
      );
    }
    return _merge(ai, byRules) ??
        byRules.withNotice(
          'No tienes un producto para el medio sugerido por la IA. '
          'Se usaron las reglas de beneficios.',
        );
  }

  void close() => _client.close();

  /// The request sent to the API: the purchase, and the customer's balance,
  /// credit usage and payment methods ([customer]). The API takes the rest
  /// of what the model needs (the customer's behaviour) from [profileId].
  String _body(Merchant merchant, String profileId, CustomerContext customer) {
    return jsonEncode({
      'user_id': profileId,
      'merchant_id': merchant.id,
      'categoria': merchant.category.name,
      'monto': merchant.amount,
      'canal': 'QR_DYNAMIC',
      'cliente': customer.toJson(),
    });
  }

  /// Asks the API. If it gives no answer, waits for it to wake up and asks
  /// once more with a longer deadline.
  Future<AiRecommendation> _fetchAwake(
    String purchase,
    void Function()? onWaking,
  ) async {
    // A wake-up already under way: the short attempt would only add delay.
    if (!status.isWaking) {
      try {
        final ai = await _fetch(purchase, timeout);
        status.markReady();
        return ai;
      } on _Rejected {
        // The API is awake and refused the request: asking again won't help.
        rethrow;
      } catch (_) {
        // No answer: it is probably asleep.
      }
    }
    onWaking?.call();
    if (!await status.check()) {
      throw http.ClientException('La API de recomendación no responde');
    }
    final ai = await _fetch(purchase, retryTimeout);
    status.markReady();
    return ai;
  }

  Future<AiRecommendation> _fetch(String purchase, Duration deadline) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/v1/recomendacion'),
          headers: const {'Content-Type': 'application/json'},
          body: purchase,
        )
        .timeout(deadline);
    if (response.statusCode >= 400 && response.statusCode < 500) {
      throw _Rejected(response.statusCode);
    }
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}');
    }
    // bodyBytes: the API answers UTF-8 without declaring the charset.
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    return AiRecommendation.fromJson(json as Map<String, dynamic>);
  }

  /// Returns null when the user owns no usable product for the method the
  /// model recommends.
  PaymentRecommendation? _merge(
    AiRecommendation ai,
    PaymentRecommendation byRules,
  ) {
    final scored = byRules.ranked.map((s) => _withAiData(s, ai)).toList();

    int group(ScoredProduct s) {
      if (!s.isAvailable) return 2;
      return _methodOf(s) == ai.recommended ? 0 : 1;
    }

    // Recommended method first, then by layer-2 utility; inside a method,
    // the product with the best reward wins.
    scored.sort((a, b) {
      final byGroup = group(a).compareTo(group(b));
      if (byGroup != 0) return byGroup;
      final byUtility = (ai.utilities[_methodOf(b)] ?? 0)
          .compareTo(ai.utilities[_methodOf(a)] ?? 0);
      if (byUtility != 0) return byUtility;
      return b.benefitValue.compareTo(a.benefitValue);
    });

    final hasSuggestion = ai.recommended != null;
    if (hasSuggestion && group(scored.first) != 0) return null;

    return PaymentRecommendation(
      ranked: scored,
      reason: ai.reason,
      deltaVsBaseline: ai.benefitCop,
      source: RecommendationSource.ai,
      hasSuggestion: hasSuggestion,
      ai: ai,
    );
  }

  ScoredProduct _withAiData(ScoredProduct s, AiRecommendation ai) {
    final method = _methodOf(s);
    final incentive = ai.incentiveFor(method);
    final hasIncentive = incentive > 0;
    return ScoredProduct(
      product: s.product,
      rewardType: hasIncentive ? RewardType.cashback : s.rewardType,
      rewardLabel: hasIncentive
          ? 'Ahorra ${Formatters.cop.format(incentive)} · incentivo del comercio'
          : s.rewardLabel,
      benefitValue: hasIncentive ? incentive : s.benefitValue,
      probability: ai.propensities[method],
      unavailableReason: unavailableLabel(ai.excluded[method]),
    );
  }

  PaymentMethod _methodOf(ScoredProduct s) =>
      PaymentMethod.ofProduct(s.product.type);

  /// Text for the API's reason code of a method the user can't pay with.
  /// Null when [code] is null (the method is usable).
  static String? unavailableLabel(String? code) {
    switch (code) {
      case null:
        return null;
      case 'sin_producto':
        return 'No tienes este medio de pago';
      case 'saldo_insuficiente':
        return 'Saldo insuficiente para esta compra';
      case 'cupo_agotado':
        return 'Cupo de crédito agotado';
      default:
        return 'No disponible para esta compra';
    }
  }
}

/// The API answered with a client error (unknown profile, invalid amount).
class _Rejected implements Exception {
  const _Rejected(this.statusCode);
  final int statusCode;

  @override
  String toString() => 'HTTP $statusCode';
}
