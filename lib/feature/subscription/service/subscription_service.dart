import 'package:sub_tv/feature/subscription/model/show.dart';

abstract class SubscriptionService {
  /// Cached shows first; hits the API only when the cache is empty, stale,
  /// or [forceRetry] is set.
  Future<List<Show>> fetchShows({bool forceRetry = false});

  /// Drops the cached show list so the next fetch goes to the network.
  Future<void> clearCache();
}

/// The request couldn't be authorized: either no token exists yet (not signed
/// in / `youtube.readonly` never approved) or the API rejected it with 401
/// (expired/revoked). UI reacts by re-running `AuthService.ensureYoutubeAccess()`.
class SubscriptionUnauthorizedException implements Exception {
  final Object? cause;

  SubscriptionUnauthorizedException([this.cause]);

  @override
  String toString() =>
      'SubscriptionUnauthorizedException: authorization missing or rejected (401)';
}
