import 'payment_product.dart';

/// Payment methods the AI model chooses between.
enum PaymentMethod {
  credit('CREDIT_CARD_BANK', 'crédito'),
  debit('DEBIT_CARD', 'débito'),
  transfer('DIRECT_ACCOUNT_TRANSFER', 'transferencia');

  const PaymentMethod(this.apiCode, this.label);

  /// Class label used by the model and the API.
  final String apiCode;
  final String label;

  static PaymentMethod? fromApi(String? code) {
    for (final m in values) {
      if (m.apiCode == code) return m;
    }
    return null;
  }

  /// The method a product pays with: the API picks the method, the app
  /// picks the product inside it.
  static PaymentMethod ofProduct(ProductType type) {
    switch (type) {
      case ProductType.creditCard:
        return PaymentMethod.credit;
      case ProductType.debitCard:
        return PaymentMethod.debit;
      case ProductType.currentAccount:
        return PaymentMethod.transfer;
    }
  }
}

/// Response of `POST /v1/recomendacion`.
class AiRecommendation {
  /// False when the model does not cover the purchase (e.g. a merchant
  /// category it was not trained on).
  final bool available;

  /// Null when no method is feasible for this purchase.
  final PaymentMethod? recommended;

  /// The most probable method according to layer 1, before incentives.
  final PaymentMethod? habit;

  /// Estimated probability of each method (layer 1).
  final Map<PaymentMethod, double> propensities;

  /// Utility of each method (layer 2).
  final Map<PaymentMethod, double> utilities;

  /// Methods the user can't pay with, and the API's reason code.
  final Map<PaymentMethod, String> excluded;

  /// Merchant incentive in COP. It applies to [incentiveMethod] only.
  final double incentiveCop;
  final PaymentMethod? incentiveMethod;

  /// Saving in COP obtained by following the recommendation.
  final double benefitCop;

  /// One-sentence explanation, ready to show to the user.
  final String reason;

  /// The customer data the API decided with: balance in COP, share of the
  /// credit limit in use (0-1) and the payment methods they own. Null when
  /// the API doesn't report them.
  final double? balanceCop;
  final double? creditUsage;
  final Set<PaymentMethod>? ownedMethods;

  /// True when that data is the one the app sent; false when the API took
  /// it from its own catalog. Null when the API doesn't say.
  final bool? usedAppData;

  /// When the API scored the purchase, in Bogotá time: hour (0-23), day of
  /// the week (0 = Monday) and whether it is a payroll day.
  final int? hour;
  final int? weekday;
  final bool? payrollDay;

  final String modelVersion;

  /// Time the API took to decide, in milliseconds.
  final double? latencyMs;

  const AiRecommendation({
    required this.available,
    required this.recommended,
    required this.propensities,
    required this.utilities,
    required this.excluded,
    required this.incentiveCop,
    required this.benefitCop,
    required this.reason,
    this.habit,
    this.incentiveMethod,
    this.balanceCop,
    this.creditUsage,
    this.ownedMethods,
    this.usedAppData,
    this.hour,
    this.weekday,
    this.payrollDay,
    this.modelVersion = '',
    this.latencyMs,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    final context = json['contexto'] as Map<String, dynamic>? ?? const {};
    final incentive = (context['incentivo_cop'] as num?)?.toDouble() ?? 0;
    final owned = context['medios'];
    final source = context['fuente_perfil'];
    return AiRecommendation(
      available: json['disponible'] as bool? ?? false,
      recommended: PaymentMethod.fromApi(json['recomendacion'] as String?),
      habit: PaymentMethod.fromApi(json['habito'] as String?),
      propensities: _byMethod<double>(json['propensiones'], (v) => (v as num).toDouble()),
      utilities: _byMethod<double>(json['utilidades'], (v) => (v as num).toDouble()),
      excluded: _byMethod<String>(json['excluidos'], (v) => v as String),
      incentiveCop: incentive,
      // The model's campaigns reward transfers; the API says so explicitly.
      incentiveMethod:
          PaymentMethod.fromApi(context['incentivo_aplica_a'] as String?) ??
              (incentive > 0 ? PaymentMethod.transfer : null),
      benefitCop: (json['beneficio_cop'] as num?)?.toDouble() ?? 0,
      reason: json['motivo'] as String? ?? '',
      balanceCop: (context['saldo_cop'] as num?)?.toDouble(),
      creditUsage: (context['uso_cupo'] as num?)?.toDouble(),
      ownedMethods: owned is List
          ? {
              for (final code in owned)
                ?PaymentMethod.fromApi(code is String ? code : null),
            }
          : null,
      usedAppData: source is String ? source == 'peticion' : null,
      hour: (context['hora'] as num?)?.toInt(),
      weekday: (context['dia_semana'] as num?)?.toInt(),
      payrollDay: context['dia_quincena'] as bool?,
      modelVersion: json['modelo_version'] as String? ?? '',
      latencyMs: (json['latencia_ms'] as num?)?.toDouble(),
    );
  }

  /// Incentive in COP the user gets by paying with [method]; 0 when none.
  double incentiveFor(PaymentMethod method) =>
      method == incentiveMethod ? incentiveCop : 0;

  /// Methods ordered the way layer 2 sees them: the ones the user can pay
  /// with first, by utility; the discarded ones last.
  List<PaymentMethod> get methodsByUtility {
    final methods = utilities.keys.toList();
    methods.sort((a, b) {
      final aOut = excluded.containsKey(a);
      final bOut = excluded.containsKey(b);
      if (aOut != bOut) return aOut ? 1 : -1;
      return utilities[b]!.compareTo(utilities[a]!);
    });
    return methods;
  }

  /// The feasible method that comes right after the recommended one.
  PaymentMethod? get runnerUp {
    for (final method in methodsByUtility) {
      if (method != recommended && !excluded.containsKey(method)) return method;
    }
    return null;
  }

  static Map<PaymentMethod, T> _byMethod<T>(Object? raw, T Function(Object?) convert) {
    final result = <PaymentMethod, T>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        final method = PaymentMethod.fromApi(key as String?);
        if (method != null) result[method] = convert(value);
      });
    }
    return result;
  }
}
