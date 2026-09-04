/// In-memory session state for the prototype.
///
/// The MVP does not have real auth — we only track whether the user has
/// entered credentials during this app run, so the QR flow can skip the
/// verification sheet when a session is already active.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  bool _loggedIn = false;
  bool get isLoggedIn => _loggedIn;

  void login() => _loggedIn = true;
  void logout() => _loggedIn = false;
}
