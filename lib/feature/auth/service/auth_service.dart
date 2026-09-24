import '../../../shared/model/user.dart';

abstract class AuthService {
  /// One-time init: registers the plugin and silently tries to restore a
  /// previous session. Idempotent — safe to call more than once.
  Future<void> initialize();

  /// Interactive Google sign-in. Returns the signed-in [User], or null if the
  /// user canceled the flow. Configuration errors are rethrown, never mistaken
  /// for a cancel.
  Future<User?> signIn();

  Future<void> signOut();

  /// Ensures the `youtube.readonly` scope is authorized for the current user.
  ///
  /// Returns true if the scope is authorized (now), false if the user declined.
  /// On platforms where authorization requires user interaction (Android), this
  /// MUST be invoked from a user interaction such as a button press, not from
  /// background logic.
  Future<bool> ensureYoutubeAccess();

  /// The current `youtube.readonly`-scoped OAuth2 access token, or null when
  /// not signed in or not authorized yet. Tokens live ~1 hour — callers treat
  /// null / HTTP 401 as "re-authorize required" (see [ensureYoutubeAccess]).
  Future<String?> currentAccessToken();

  /// Whether a user is currently signed in.
  bool get isSignedIn;

  /// The currently signed-in user, or null.
  User? get currentUser;

  /// Emits whenever the sign-in state flips (sign-in or sign-out). Drives the
  /// reactive auth gate at the app root.
  Stream<bool> get changes;
}