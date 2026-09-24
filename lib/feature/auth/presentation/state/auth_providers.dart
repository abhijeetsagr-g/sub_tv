import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sub_tv/feature/auth/service/auth_service.dart';
import 'package:sub_tv/feature/auth/service/google_auth_service_impl.dart';
import 'package:sub_tv/shared/model/user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final service = GoogleAuthServiceImpl();
  ref.onDispose(service.dispose);
  return service;
});

final authUserProvider = NotifierProvider<AuthUserNotifier, AsyncValue<User?>>(
  AuthUserNotifier.new,
);

// Auth Controller is the notifier that works like cubit;
// It have a AsyncState [User]
class AuthUserNotifier extends Notifier<AsyncValue<User?>> {
  AuthService get _auth => ref.read(authServiceProvider);

  @override
  AsyncValue<User?> build() {
    // Attach the listener BEFORE kicking off init so no auth event can be
    // missed, then start the one-time plugin init + silent session restore.
    // "loading" lets the gate show a spinner while we check for a session.
    final sub = _auth.changes.listen(
      (_) {
        if (!ref.mounted) return;
        state = AsyncValue.data(_auth.currentUser);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!ref.mounted) return;
        state = AsyncValue.error(error, stackTrace);
      },
    );
    ref.onDispose(sub.cancel);

    unawaited(_restoreSession());
    return const AsyncValue.loading();
  }

  /// One-time v7 `initialize()` + silent restore of a previous session.
  /// The stream listener above keeps state in sync afterwards.
  Future<void> _restoreSession() async {
    try {
      await _auth.initialize();
      if (!ref.mounted) return;
      state = AsyncValue.data(_auth.currentUser);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn() async {
    final user = await ref.read(authServiceProvider).signIn();
    if (user != null) state = AsyncData(user); // canceled → state unchanged
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    state = const AsyncData(null);
  }

  Future<bool> ensureYoutubeAccess() =>
      ref.read(authServiceProvider).ensureYoutubeAccess();
}
