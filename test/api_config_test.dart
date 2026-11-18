import 'package:flutter_test/flutter_test.dart';

import 'package:agent_payment_ai_recomendation/core/config/api_config.dart';

void main() {
  test('without --dart-define the app talks to the API on Render', () {
    // A plain `flutter build apk --release` must work on a physical phone.
    expect(ApiConfig.baseUrl, 'https://prompt-solution-client-api.onrender.com');
  });

  test('a wrong address fails fast instead of looking like a wake-up', () {
    expect(ApiConfig.connectTimeout, lessThan(ApiConfig.wakeTimeout));
  });

  test('the server name shown on screen', () {
    expect(
      serverName('https://prompt-solution-client-api.onrender.com'),
      'prompt-solution-client-api.onrender.com',
    );
    expect(serverName('http://10.0.2.2:8000'), '10.0.2.2:8000');
    expect(serverName('http://localhost:8000/'), 'localhost:8000');
    expect(serverName('no es una url'), 'no es una url');
  });
}
