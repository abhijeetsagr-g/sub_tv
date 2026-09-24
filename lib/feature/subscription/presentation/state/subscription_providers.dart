import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sub_tv/feature/auth/presentation/state/auth_providers.dart';
import 'package:sub_tv/feature/subscription/model/show.dart';
import 'package:sub_tv/feature/subscription/service/subscription_service.dart';
import 'package:sub_tv/feature/subscription/service/subscription_service_impl.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final auth = ref.watch(authServiceProvider);
  return SubscriptionServiceImpl(auth: auth);
});

final subscriptionShowsProvider =
    NotifierProvider<SubscriptionNotifier, AsyncValue<List<Show>>>(
      SubscriptionNotifier.new,
    );

class SubscriptionNotifier extends Notifier<AsyncValue<List<Show>>> {
  SubscriptionService get _service => ref.read(subscriptionServiceProvider);

  @override
  AsyncValue<List<Show>> build() {
    // The cache is keyed per-account. On sign-out, drop both the stored cache
    // and local state; on (re-)sign-in, load that account's shows.
    ref.listen(authUserProvider, (previous, next) {
      final prevUser = previous?.value;
      final nextUser = next.value;

      if (nextUser == null) {
        if (prevUser != null) {
          unawaited(_service.clearCache());
          state = const AsyncValue.data([]);
        }
      } else if (prevUser == null || prevUser.id != nextUser.id) {
        state = const AsyncValue.loading();
        unawaited(refetch());
      }
    });

    // When a session is already live by the time this provider is first watched
    // (post-login navigation, hot reload), `ref.listen` above won't fire — fetch
    // here instead. The cold-start path is covered by the listener when the
    // async session restore lands.
    if (ref.read(authUserProvider).value != null) {
      unawaited(refetch());
    }
    return const AsyncValue.loading();
  }

  Future<void> refetch({bool forceRetry = false}) async {
    try {
      final shows = await _service.fetchShows(forceRetry: forceRetry);
      if (ref.mounted) state = AsyncValue.data(shows);
    } catch (e, st) {
      if (ref.mounted) state = AsyncValue.error(e, st);
    }
  }
}
