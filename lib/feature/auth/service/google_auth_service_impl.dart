import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sub_tv/feature/auth/service/auth_service.dart';
import 'package:sub_tv/shared/model/user.dart';

class GoogleAuthServiceImpl implements AuthService {
  /// Web OAuth client ID from Google Cloud Console.
  static const serverClientId =
      '456616852405-qpfua7m8f90kfk3lari2bu5jpv326gtr.apps.googleusercontent.com';

  /// The only API scope this app asks for.
  static const List<String> scopes = [
    'https://www.googleapis.com/auth/youtube.readonly',
  ];

  // Injectable so tests can substitute a fake.
  late GoogleSignIn _signIn;
  GoogleAuthServiceImpl({GoogleSignIn? signIn})
    : _signIn = signIn ?? GoogleSignIn.instance;

  GoogleSignInAccount? _account;
  bool _initialized = false;
  bool _signedIn = false;

  final StreamController<bool> _changes = StreamController<bool>.broadcast();
  StreamSubscription<GoogleSignInAuthenticationEvent>? _eventsSub;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _signIn.initialize(serverClientId: serverClientId);

    // Subscribe BEFORE attempting restore so no events are missed. In v7 the
    // plugin no longer tracks a single "current user"; every auth outcome —
    // including failures — arrives on this stream.
    _eventsSub = _signIn.authenticationEvents.listen(
      _onAuthEvent,
      onError: (Object error, StackTrace stackTrace) {
        // Stream failures mean "not signed in". Let the UI surface the error.
        _account = null;
        _emitIfChanged(false);
      },
    );

    // Silent restore of a previous session. The returned Future is not
    // guaranteed to complete with an account on all platforms (web answers
    // via the stream instead), so the stream above stays the source of truth.
    final restored = await _signIn.attemptLightweightAuthentication();
    if (restored != null) {
      _account = restored;
      _emitIfChanged(true);
    }
  }

  @override
  Future<User?> signIn() async {
    // Web must use the SDK-rendered button, not a custom tap.
    if (!_signIn.supportsAuthenticate()) return null;

    try {
      // scopeHint primes the combined auth+authorize flow where the platform
      // supports it (Android). Where it doesn't, the app completes
      // authorization via ensureYoutubeAccess().
      final account = await _signIn.authenticate(scopeHint: scopes);
      _account = account;
      _emitIfChanged(true);
      return _toUser(account);
    } on GoogleSignInException catch (e) {
      // v7 throws for every failed outcome; only user-driven cancellations are
      // a normal "no". Anything else (e.g. clientConfigurationError) must
      // propagate so misconfiguration isn't silently swallowed as a cancel.
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _signIn.signOut();
    _account = null;
    _emitIfChanged(false);
  }

  @override
  Future<bool> ensureYoutubeAccess() async {
    final account = _account;
    if (account == null) return false;

    // Already authorized? Silent token, no UI.
    final existing = await account.authorizationClient.authorizationForScopes(
      scopes,
    );
    if (existing != null) return true;

    // Otherwise ask the user. On platforms where
    // authorizationRequiresUserInteraction() is true (Android), this must be
    // triggered from a button press.
    try {
      await account.authorizationClient.authorizeScopes(scopes);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
    return true;
  }

  @override
  Future<String?> currentAccessToken() async {
    final account = _account;
    if (account == null) return null;
    final authorization = await account.authorizationClient
        .authorizationForScopes(scopes);
    return authorization?.accessToken;
  }

  @override
  bool get isSignedIn => _signedIn;

  @override
  User? get currentUser => _account == null ? null : _toUser(_account!);

  @override
  Stream<bool> get changes => _changes.stream;

  void _onAuthEvent(GoogleSignInAuthenticationEvent event) {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      _account = event.user;
      _emitIfChanged(true);
    } else if (event is GoogleSignInAuthenticationEventSignOut) {
      _account = null;
      _emitIfChanged(false);
    }
  }

  /// Re-emits only on actual transitions — the events stream may double-fire
  /// (e.g. `attemptLightweightAuthentication` + its own SignIn event).
  void _emitIfChanged(bool signedIn) {
    if (_signedIn == signedIn) return;
    _signedIn = signedIn;
    if (!_changes.isClosed) _changes.add(signedIn);
  }

  User _toUser(GoogleSignInAccount account) => User(
    id: account.id,
    email: account.email,
    displayName: account.displayName,
    imageUrl: account.photoUrl,
  );

  /// Releases stream subscriptions. Call when the app-level provider dies.
  void dispose() {
    _eventsSub?.cancel();
    _changes.close();
  }
}
