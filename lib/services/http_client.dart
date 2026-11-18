import 'package:http/http.dart' as http;

import 'http_client_stub.dart'
    if (dart.library.io) 'http_client_io.dart' as platform;

/// The HTTP client the app talks to the API with.
///
/// On phones and desktop it gives up opening a connection after
/// [ApiConfig.connectTimeout], so a wrong address fails in seconds instead
/// of looking like an API that is waking up. Browsers handle connections
/// themselves, so on web it is the plain client.
http.Client createHttpClient() => platform.createHttpClient();
