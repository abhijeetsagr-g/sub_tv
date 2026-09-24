import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sub_tv/feature/auth/service/auth_service.dart';
import 'package:sub_tv/feature/subscription/model/show.dart';
import 'package:sub_tv/feature/subscription/service/subscription_service.dart';

class SubscriptionServiceImpl implements SubscriptionService {
  static const _cacheTtl = Duration(days: 1);

  /// API cap for `subscriptions.list` per page.
  static const _maxResults = 50;

  /// 1000 shows max — guards against a pathological response looping forever.
  static const _maxPages = 20;

  final Dio dio;
  final AuthService auth;
  final SharedPreferencesAsync prefs;

  SubscriptionServiceImpl({
    required this.auth,
    Dio? dio,
    SharedPreferencesAsync? prefs,
  }) : dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: 'https://www.googleapis.com/youtube/v3',
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 15),
             ),
           ),
       prefs = prefs ?? SharedPreferencesAsync();

  /// Cache keys are scoped to the signed-in user so one account's shows can
  /// never be served to another — `clearCache()` on sign-out is hygiene on top
  /// of this, not the protection itself.
  String get _cacheKey => 'shows_${auth.currentUser?.id ?? 'anonymous'}.list';
  String get _cachedAtKey =>
      'shows_${auth.currentUser?.id ?? 'anonymous'}.cached_at';

  @override
  Future<List<Show>> fetchShows({bool forceRetry = false}) async {
    if (!forceRetry) {
      final cached = await _readCache();
      if (cached != null) return cached;
    }

    final shows = await _fetchAllShows();
    await _writeCache(shows);
    return shows;
  }

  @override
  Future<void> clearCache() async {
    await prefs.remove(_cacheKey);
    await prefs.remove(_cachedAtKey);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    // Tokens live ~1 hour but google_sign_in refreshes them in the background,
    // so asking at call time keeps every request fresh.
    final token = await auth.currentAccessToken();
    if (token == null) {
      throw SubscriptionUnauthorizedException('no token available');
    }

    try {
      final response = await dio.get<String>(
        path,
        queryParameters: {...?queryParameters},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.plain,
        ),
      );
      if (response.data == null) throw Exception('Empty response');

      return jsonDecode(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw SubscriptionUnauthorizedException(e);
      }
      rethrow;
    }
  }

  Future<List<Show>> _fetchAllShows() async {
    final shows = <Show>[];
    String? pageToken;
    var pages = 0;

    do {
      final data = await _get(
        '/subscriptions',
        queryParameters: {
          'part': 'snippet',
          'mine': 'true',
          'maxResults': '$_maxResults',
          if (pageToken != null) 'pageToken': pageToken,
        },
      );

      for (final item in data['items'] as List<dynamic>? ?? <dynamic>[]) {
        shows.add(_parseShow(item as Map<String, dynamic>));
      }

      pageToken = data['nextPageToken'] as String?;
      pages++;
    } while (pageToken != null && pages < _maxPages);

    return shows;
  }

  Show _parseShow(Map<String, dynamic> item) {
    final snippet = item['snippet'] as Map<String, dynamic>;

    // item['id'] is the subscription RESOURCE id — the channel we want is
    // the subscribed channel under snippet.resourceId.channelId.
    return Show(
      id:
          (snippet['resourceId'] as Map<String, dynamic>)['channelId']
              as String,
      title: snippet['title'] as String,
      description: snippet['description'] as String? ?? '',
      thumbnailUrl: _thumbUrl(snippet['thumbnails'] as Map<String, dynamic>?),
    );
  }

  String? _thumbUrl(Map<String, dynamic>? thumbs) {
    if (thumbs == null) return null;
    for (final size in ['high', 'medium', 'default']) {
      final entry = thumbs[size];
      if (entry is Map<String, dynamic> && entry['url'] is String) {
        return entry['url'] as String;
      }
    }
    return null;
  }

  /// Serves the cached list only while it's still within [_cacheTtl];
  /// a stale cache counts as a miss so the caller refetches.
  Future<List<Show>?> _readCache() async {
    final raw = await prefs.getString(_cacheKey);
    final cachedAt = await prefs.getInt(_cachedAtKey);
    if (raw == null || cachedAt == null) return null;

    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(cachedAt),
    );
    if (age > _cacheTtl) return null;

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Show.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeCache(List<Show> shows) async {
    await prefs.setString(
      _cacheKey,
      jsonEncode(shows.map((s) => s.toJson()).toList()),
    );
    await prefs.setInt(_cachedAtKey, DateTime.now().millisecondsSinceEpoch);
  }
}
