import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agent_payment_ai_recomendation/data/mock_repository.dart';
import 'package:agent_payment_ai_recomendation/models/merchant.dart';
import 'package:agent_payment_ai_recomendation/models/payment_product.dart';
import 'package:agent_payment_ai_recomendation/models/payment_recommendation.dart';
import 'package:agent_payment_ai_recomendation/services/api_recommendation_service.dart';
import 'package:agent_payment_ai_recomendation/services/api_status.dart';

const _repo = MockRepository();

const _cafe = Merchant(
  id: 'TXN-20417-K',
  name: 'Café La Candelaria',
  location: 'Bogotá, COL',
  category: MerchantCategory.restaurant,
  amount: 48000,
);

/// A real answer of the API for the café purchase with profile USR-1483.
Map<String, dynamic> _apiAnswer({
  String? recommended = 'DIRECT_ACCOUNT_TRANSFER',
  Map<String, String> excluded = const {},
  double incentive = 4800,
}) {
  return {
    'disponible': true,
    'recomendacion': recommended,
    'habito': 'DEBIT_CARD',
    'sugerencia_activa': true,
    'propensiones': {
      'CREDIT_CARD_BANK': 0.2837,
      'DEBIT_CARD': 0.4884,
      'DIRECT_ACCOUNT_TRANSFER': 0.2279,
    },
    'utilidades': {
      'CREDIT_CARD_BANK': 0.1418,
      'DEBIT_CARD': 0.2442,
      'DIRECT_ACCOUNT_TRANSFER': 0.2739,
    },
    'factibles': ['CREDIT_CARD_BANK', 'DEBIT_CARD', 'DIRECT_ACCOUNT_TRANSFER'],
    'excluidos': excluded,
    'beneficio_cop': recommended == 'DIRECT_ACCOUNT_TRANSFER' ? incentive : 0,
    'motivo': 'Lo más probable es que pagues con débito (49 %), pero con '
        'transferencia ahorras \$4.800 por el incentivo del comercio.',
    'contexto': {'incentivo_cop': incentive},
    'modelo_version': 'xgb-v10-test',
    'latencia_ms': 5.0,
  };
}

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

/// What `GET /v1/meta` answers: the app's "are you awake?" question.
const _meta = {
  'modelo_version': 'xgb-v10-test',
  'capa2': {
    'w_propension': 0.5,
    'w_beneficio': 0.5,
    'ref_incentivo_cop': 15000.0,
    'uso_cupo_max': 0.9,
  },
};

Future<http.Response> _awake(http.Request _) async => _json(_meta);

/// [recommend] answers the recommendation request. [meta] answers the
/// "are you awake?" check; by default it behaves like [recommend], as a
/// server that is down or broken would.
ApiRecommendationService _service(
  MockClientHandler recommend, {
  MockClientHandler? meta,
}) {
  final client = MockClient(
    (request) => request.url.path == '/v1/meta'
        ? (meta ?? recommend)(request)
        : recommend(request),
  );
  const short = Duration(milliseconds: 200);
  return ApiRecommendationService(
    client: client,
    baseUrl: 'http://api.test',
    timeout: short,
    retryTimeout: short,
    status: ApiStatus(
      client: client,
      baseUrl: 'http://api.test',
      wakeTimeout: short,
    ),
  );
}

/// The customer with the three payment methods, and the one without a
/// credit card.
const _withCredit = 'USR-1483';
const _withoutCredit = 'USR-1167';

Future<PaymentRecommendation> _recommend(
  ApiRecommendationService service, {
  void Function()? onWaking,
  String profileId = _withCredit,
}) =>
    service.recommend(
      merchant: _cafe,
      products: _repo.userProducts(profileId),
      profileId: profileId,
      onWaking: onWaking,
    );

void main() {
  test('sends the purchase and the customer data to the API', () async {
    late http.Request sent;
    final service = _service((request) async {
      sent = request;
      return _json(_apiAnswer());
    });

    await _recommend(service);

    expect(sent.method, 'POST');
    expect(sent.url.toString(), 'http://api.test/v1/recomendacion');
    expect(jsonDecode(sent.body), {
      'user_id': 'USR-1483',
      'merchant_id': 'TXN-20417-K',
      'categoria': 'restaurant',
      'monto': 48000,
      'canal': 'QR_DYNAMIC',
      // Taken from the customer's products: nobody types it.
      'cliente': {
        'saldo_cop': 150000,
        'uso_cupo': 0.15,
        'medios': [
          'CREDIT_CARD_BANK',
          'DEBIT_CARD',
          'DIRECT_ACCOUNT_TRANSFER',
        ],
      },
    });
  });

  group('a customer without a credit card', () {
    const noCredit = {'CREDIT_CARD_BANK': 'sin_producto'};

    test('is reported to the API with the credit limit fully used', () async {
      late http.Request sent;
      final service = _service((request) async {
        sent = request;
        return _json(_apiAnswer(excluded: noCredit));
      });

      await _recommend(service, profileId: _withoutCredit);

      expect(jsonDecode(sent.body)['cliente'], {
        'saldo_cop': 600000,
        'uso_cupo': 1,
        'medios': ['DEBIT_CARD', 'DIRECT_ACCOUNT_TRANSFER'],
      });
    });

    test('only gets products of the methods they own', () async {
      final result = await _recommend(
        _service((_) async => _json(_apiAnswer(excluded: noCredit))),
        profileId: _withoutCredit,
      );

      expect(result.source, RecommendationSource.ai);
      expect(result.best.product.type, ProductType.currentAccount);
      expect(
        result.ranked.map((s) => s.product.type),
        [ProductType.currentAccount, ProductType.debitCard],
      );
      expect(result.ranked.every((s) => s.isAvailable), isTrue);
    });

    test('falls back to the rules if an older API suggests credit', () async {
      // An API that ignores the customer data may suggest a method the
      // customer doesn't own.
      final result = await _recommend(
        _service(
          (_) async => _json(_apiAnswer(recommended: 'CREDIT_CARD_BANK')),
        ),
        profileId: _withoutCredit,
      );

      expect(result.source, RecommendationSource.rules);
      expect(result.notice, contains('No tienes un producto'));
      expect(
        result.ranked.any((s) => s.product.type == ProductType.creditCard),
        isFalse,
      );
    });
  });

  test('the method recommended by the model becomes the best product',
      () async {
    final result = await _recommend(_service((_) async => _json(_apiAnswer())));

    expect(result.source, RecommendationSource.ai);
    expect(result.hasSuggestion, isTrue);
    expect(result.best.product.type, ProductType.currentAccount);
    expect(result.best.probability, closeTo(0.2279, 1e-9));
    expect(result.best.rewardType, RewardType.cashback);
    expect(result.best.benefitValue, 4800);
    expect(result.best.rewardLabel, contains('incentivo del comercio'));
    expect(result.deltaVsBaseline, 4800);
    // Accents survive: the body is decoded as UTF-8.
    expect(result.reason, startsWith('Lo más probable es que pagues con débito'));
    // Every product carries the probability of its payment method.
    expect(result.ranked.every((s) => s.probability != null), isTrue);
    expect(result.ranked.every((s) => s.isAvailable), isTrue);
  });

  test('inside the recommended method the best reward wins', () async {
    final answer = _apiAnswer(recommended: 'CREDIT_CARD_BANK');
    final result = await _recommend(_service((_) async => _json(answer)));

    // Visa Infinite gives 3x points at restaurants; Mastercard Black 2 %.
    expect(result.best.product.name, 'Visa Infinite');
    expect(result.ranked[1].product.type, ProductType.creditCard);
  });

  test('methods the user cannot pay with are flagged and ranked last',
      () async {
    final answer = _apiAnswer(
      recommended: 'CREDIT_CARD_BANK',
      excluded: const {
        'DEBIT_CARD': 'saldo_insuficiente',
        'DIRECT_ACCOUNT_TRANSFER': 'saldo_insuficiente',
      },
    );
    final result = await _recommend(_service((_) async => _json(answer)));

    expect(result.best.product.type, ProductType.creditCard);
    final unavailable = result.ranked.where((s) => !s.isAvailable).toList();
    expect(
      unavailable.map((s) => s.product.type),
      unorderedEquals([ProductType.debitCard, ProductType.currentAccount]),
    );
    expect(result.ranked.sublist(2), unavailable);
    expect(unavailable.first.unavailableReason, contains('Saldo insuficiente'));
  });

  test('no feasible method means no suggestion', () async {
    final answer = _apiAnswer(
      recommended: null,
      excluded: const {
        'CREDIT_CARD_BANK': 'cupo_agotado',
        'DEBIT_CARD': 'saldo_insuficiente',
        'DIRECT_ACCOUNT_TRANSFER': 'saldo_insuficiente',
      },
    );
    final result = await _recommend(_service((_) async => _json(answer)));

    expect(result.source, RecommendationSource.ai);
    expect(result.hasSuggestion, isFalse);
    expect(result.ranked.any((s) => s.isAvailable), isFalse);
  });

  group('when the API is asleep', () {
    test('waits for it to wake up and asks once more', () async {
      var posts = 0;
      var waking = 0;
      final service = _service(
        (_) async {
          posts++;
          if (posts == 1) throw http.ClientException('sin respuesta');
          return _json(_apiAnswer());
        },
        meta: _awake,
      );

      final result = await _recommend(service, onWaking: () => waking++);

      expect(result.source, RecommendationSource.ai);
      expect(result.ai, isNotNull);
      expect(result.canRetryAi, isFalse);
      expect(posts, 2);
      expect(waking, 1);
      expect(service.status.state, ApiState.ready);
    });

    test('an answer that comes too late also triggers the second attempt',
        () async {
      var posts = 0;
      final service = _service(
        (_) async {
          posts++;
          if (posts == 1) {
            await Future<void>.delayed(const Duration(seconds: 1));
          }
          return _json(_apiAnswer());
        },
        meta: _awake,
      );

      final result = await _recommend(service);

      expect(result.source, RecommendationSource.ai);
      expect(posts, 2);
    });

    test('does not announce a wake-up when the API answers in time', () async {
      var waking = 0;
      final result = await _recommend(
        _service((_) async => _json(_apiAnswer()), meta: _awake),
        onWaking: () => waking++,
      );

      expect(result.source, RecommendationSource.ai);
      expect(waking, 0);
    });

    test('joins a wake-up already under way instead of asking twice',
        () async {
      var now = DateTime(2026, 11, 14, 12);
      final awake = Completer<http.Response>();
      var posts = 0;
      final client = MockClient((request) {
        if (request.url.path == '/v1/meta') return awake.future;
        posts++;
        return Future.value(_json(_apiAnswer()));
      });
      final status = ApiStatus(
        client: client,
        baseUrl: 'http://api.test',
        clock: () => now,
      );
      final service = ApiRecommendationService(
        client: client,
        baseUrl: 'http://api.test',
        status: status,
      );

      // The app has been waiting for the API for five seconds.
      unawaited(status.check());
      now = now.add(const Duration(seconds: 5));
      var waking = 0;
      final pending = _recommend(service, onWaking: () => waking++);
      await Future<void>.delayed(Duration.zero);

      expect(waking, 1);
      expect(posts, 0);

      awake.complete(_json(_meta));
      final result = await pending;

      expect(result.source, RecommendationSource.ai);
      expect(posts, 1);
    });

    test('a request the API rejects is not sent again', () async {
      var posts = 0;
      var checks = 0;
      final service = _service(
        (_) async {
          posts++;
          return _json({'detail': "Perfil 'USR-0000' no encontrado."}, 404);
        },
        meta: (request) {
          checks++;
          return _awake(request);
        },
      );

      final result = await _recommend(service);

      expect(result.source, RecommendationSource.rules);
      expect(posts, 1);
      expect(checks, 0);
    });
  });

  group('falls back to the local rules when', () {
    void expectRules(PaymentRecommendation result) {
      expect(result.source, RecommendationSource.rules);
      expect(result.notice, isNotNull);
      expect(result.ai, isNull);
      expect(result.best.product.name, 'Visa Infinite');
      expect(result.ranked.every((s) => s.probability == null), isTrue);
    }

    test('the API returns an error', () async {
      final result = await _recommend(_service((_) async => _json({}, 500)));
      expectRules(result);
      // The AI gave no answer: asking again may work.
      expect(result.canRetryAi, isTrue);
    });

    test('the API wakes up but still gives no answer', () async {
      var posts = 0;
      final result = await _recommend(_service(
        (_) async {
          posts++;
          throw http.ClientException('sin respuesta');
        },
        meta: _awake,
      ));
      expectRules(result);
      expect(posts, 2);
    });

    test('the API is unreachable', () async {
      expectRules(await _recommend(
        _service((_) async => throw http.ClientException('sin conexión')),
      ));
    });

    test('the API takes too long', () async {
      expectRules(await _recommend(_service((_) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return _json(_apiAnswer());
      })));
    });

    test('the answer is not valid JSON', () async {
      expectRules(await _recommend(
        _service((_) async => http.Response('<html>', 200)),
      ));
    });

    test('the model does not cover the category', () async {
      final result = await _recommend(_service((_) async => _json({
            'disponible': false,
            'motivo': "El modelo no fue entrenado con la categoría 'travel'.",
            'modelo_version': 'xgb-v10-test',
            'latencia_ms': 0.1,
          })));
      expectRules(result);
      expect(result.notice, contains('no cubre esta categoría'));
      // The AI did answer: asking again gives the same result.
      expect(result.canRetryAi, isFalse);
    });
  });
}
