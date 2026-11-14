import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agent_payment_ai_recomendation/services/api_status.dart';

/// What the API answers to `GET /v1/meta`.
const _meta = {
  'modelo_version': 'xgb-v10-b2afda2f',
  'capa2': {
    'w_propension': 0.5,
    'w_beneficio': 0.5,
    'ref_incentivo_cop': 15000.0,
    'incentivo_aplica_a': 'DIRECT_ACCOUNT_TRANSFER',
    'tope_incentivo_cop': 25000,
    'uso_cupo_max': 0.9,
  },
};

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

ApiStatus _status(MockClientHandler handler, {DateTime Function()? clock}) =>
    ApiStatus(
      client: MockClient(handler),
      baseUrl: 'http://api.test',
      wakeTimeout: const Duration(milliseconds: 200),
      clock: clock,
    );

void main() {
  test('starts without knowing whether the API is awake', () {
    final status = _status((_) async => _json(_meta));

    expect(status.state, ApiState.unknown);
    expect(status.isFresh, isFalse);
    expect(status.params, isNull);
  });

  test('an answer of the API means ready and brings the layer-2 weights',
      () async {
    late http.Request sent;
    final status = _status((request) async {
      sent = request;
      return _json(_meta);
    });
    final states = <ApiState>[];
    status.addListener(() => states.add(status.state));

    expect(await status.check(), isTrue);

    expect(sent.method, 'GET');
    expect(sent.url.toString(), 'http://api.test/v1/meta');
    expect(states, [ApiState.checking, ApiState.ready]);
    expect(status.isFresh, isTrue);
    final params = status.params!;
    expect(params.propensityWeight, 0.5);
    expect(params.benefitWeight, 0.5);
    expect(params.incentiveReferenceCop, 15000);
    expect(params.maxCreditUsage, 0.9);
    // The utility of the transfer in the demo: 19 % + an incentive of $14.500.
    expect(params.utility(0.1869, 14500), closeTo(0.5768, 1e-4));
  });

  test('ready without weights when the API publishes other parameters',
      () async {
    final status = _status(
      (_) async => _json({'modelo_version': 'xgb-v11', 'capa2': {'alfa': 1}}),
    );

    expect(await status.check(), isTrue);
    expect(status.params, isNull);
  });

  group('unreachable when', () {
    Future<void> expectUnreachable(MockClientHandler handler) async {
      final status = _status(handler);
      expect(await status.check(), isFalse);
      expect(status.state, ApiState.unreachable);
      expect(status.isFresh, isFalse);
    }

    test('the request fails', () async {
      await expectUnreachable(
        (_) async => throw http.ClientException('sin conexión'),
      );
    });

    test('the server answers an error', () async {
      await expectUnreachable((_) async => _json({}, 502));
    });

    test('something that is not the API answers', () async {
      await expectUnreachable(
        (_) async => http.Response('<html>Waking up…</html>', 200),
      );
    });

    test('it does not wake up in time', () async {
      await expectUnreachable((_) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return _json(_meta);
      });
    });
  });

  test('calls made during a check join it', () async {
    var requests = 0;
    final answer = Completer<http.Response>();
    final status = _status((_) {
      requests++;
      return answer.future;
    });

    final first = status.check();
    final second = status.check();
    answer.complete(_json(_meta));

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(requests, 1);

    // Once it finished, a new call asks again.
    await status.check();
    expect(requests, 2);
  });

  test('a check that takes long means the API is waking up', () async {
    var now = DateTime(2026, 11, 14, 12);
    final answer = Completer<http.Response>();
    final status = _status((_) => answer.future, clock: () => now);

    final check = status.check();
    expect(status.isWaking, isFalse);

    now = now.add(const Duration(seconds: 3));
    expect(status.isWaking, isTrue);

    answer.complete(_json(_meta));
    await check;
    expect(status.isWaking, isFalse);
    expect(status.checkingSince, isNull);
  });

  test('ready is trusted for ten minutes', () async {
    var now = DateTime(2026, 11, 14, 12);
    final status = _status((_) async => _json(_meta), clock: () => now);
    await status.check();

    now = now.add(const Duration(minutes: 9));
    expect(status.isFresh, isTrue);

    now = now.add(const Duration(minutes: 1));
    expect(status.isFresh, isFalse);

    // A recommendation the API just answered counts as a sign of life.
    status.markReady();
    expect(status.isFresh, isTrue);
  });
}
