import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sub_tv/feature/auth/presentation/state/auth_providers.dart';
import 'package:sub_tv/feature/auth/service/auth_service.dart';
import 'package:sub_tv/feature/subscription/model/show.dart';
import 'package:sub_tv/feature/subscription/presentation/state/subscription_providers.dart';
import 'package:sub_tv/feature/subscription/presentation/view/home_view.dart';
import 'package:sub_tv/feature/subscription/service/subscription_service.dart';
import 'package:sub_tv/shared/model/user.dart';

void main() {
  final user = User(
    id: 'u1',
    email: 'zeen@example.com',
    displayName: 'Zeen A',
  );

  final mkbhd = Show(
    id: 'c1',
    title: 'MKBHD',
    description: 'Tech reviews and more.',
  );
  final ltt = Show(
    id: 'c2',
    title: 'Linus Tech Tips',
    description: 'Computer hardware and cooling.',
  );

  Widget buildApp(FakeSubscriptionService service) => ProviderScope(
    overrides: [
      subscriptionServiceProvider.overrideWithValue(service),
      authServiceProvider.overrideWithValue(FakeAuthService(user: user)),
      authUserProvider.overrideWith(() => FakeAuthUserNotifier(user)),
    ],
    child: const MaterialApp(home: HomeView()),
  );

  testWidgets('renders the subscription list from the provider', (
    tester,
  ) async {
    final service = FakeSubscriptionService(shows: [mkbhd, ltt]);

    await tester.pumpWidget(buildApp(service));
    await tester.pump();

    // Header greeting + channel count.
    expect(find.text('Welcome, Zeen'), findsOneWidget);
    expect(find.text('2 channels'), findsOneWidget);

    // One tile per show, with title + description.
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('MKBHD'), findsOneWidget);
    expect(find.text('Tech reviews and more.'), findsOneWidget);
    expect(find.text('Linus Tech Tips'), findsOneWidget);
    expect(
      find.text('Computer hardware and cooling.'),
      findsOneWidget,
    );

    expect(service.fetchCount, 1);
    expect(service.forceRetries, [false]); // cache-first on cold start
  });

  testWidgets('shows a spinner while the provider is loading', (
    tester,
  ) async {
    final service = FakeSubscriptionService();
    final completer = Completer<List<Show>>();
    service.pending = completer;

    await tester.pumpWidget(buildApp(service));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete([mkbhd]);
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('MKBHD'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no subscriptions', (
    tester,
  ) async {
    final service = FakeSubscriptionService(shows: []);

    await tester.pumpWidget(buildApp(service));
    await tester.pumpAndSettle();

    expect(find.textContaining('No subscriptions yet'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('surfaces generic errors with Try again and refetches', (
    tester,
  ) async {
    final service = FakeSubscriptionService(
      shows: [mkbhd],
      error: Exception('network down'),
    );

    await tester.pumpWidget(buildApp(service));
    await tester.pump();

    expect(find.text("Couldn't load your subscriptions"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    // Recovery: the next fetch succeeds and the list appears.
    service.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text('MKBHD'), findsOneWidget);
    expect(service.fetchCount, 2);
    expect(service.forceRetries.last, isTrue); // retry bypasses the cache
  });

  testWidgets('surfaces unauthorized errors with Re-authorize and recovers', (
    tester,
  ) async {
    final service = FakeSubscriptionService(
      shows: [mkbhd],
      error: SubscriptionUnauthorizedException(),
    );

    await tester.pumpWidget(buildApp(service));
    await tester.pump();

    expect(find.text('YouTube access needed'), findsOneWidget);
    expect(find.text('Re-authorize YouTube'), findsOneWidget);

    // Fake auth grants the scope; the provider refetches the list.
    service.error = null;
    await tester.tap(find.text('Re-authorize YouTube'));
    await tester.pump();
    await tester.pump();

    expect(find.text('MKBHD'), findsOneWidget);
    expect(service.fetchCount, 2);
    expect(service.forceRetries.last, isTrue);
  });

  testWidgets('pull-to-refresh refetches with forceRetry', (tester) async {
    final service = FakeSubscriptionService(shows: [mkbhd]);

    await tester.pumpWidget(buildApp(service));
    await tester.pump();
    expect(find.byType(ListTile), findsOneWidget);

    // Simulate new subscriptions appearing server-side.
    service.shows = [mkbhd, ltt];

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(find.text('2 channels'), findsOneWidget);
    expect(find.text('Linus Tech Tips'), findsOneWidget);
    expect(service.fetchCount, 2);
    expect(service.forceRetries.last, isTrue);
  });
}

/// Scriptable [SubscriptionService]: the test swaps `shows` / `error` /
/// `pending` between asserts, and records every call.
class FakeSubscriptionService implements SubscriptionService {
  FakeSubscriptionService({this.shows = const [], this.error});

  List<Show> shows;
  Object? error;

  /// When set, `fetchShows` stalls on this future — for loading-state tests.
  Completer<List<Show>>? pending;

  int fetchCount = 0;
  final List<bool> forceRetries = [];

  @override
  Future<List<Show>> fetchShows({bool forceRetry = false}) {
    fetchCount++;
    forceRetries.add(forceRetry);

    if (pending case final completer?) return completer.future;
    if (error case final err?) return Future<List<Show>>.error(err);
    return Future.value(List.of(shows));
  }

  @override
  Future<void> clearCache() async {}
}

/// Stubs just enough of [AuthService] for the overridden auth notifier and
/// the "Re-authorize" recovery path.
class FakeAuthService implements AuthService {
  FakeAuthService({this.user, this.granted = true});

  final User? user;
  final bool granted;

  @override
  User? get currentUser => user;

  @override
  bool get isSignedIn => user != null;

  @override
  Stream<bool> get changes => const Stream<bool>.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<User?> signIn() async => user;

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> ensureYoutubeAccess() async => granted;

  @override
  Future<String?> currentAccessToken() async => 'fake-token';
}

/// Overrides [AuthUserNotifier]'s build so no Google plugin is ever touched;
/// state is a fixed signed-in user.
class FakeAuthUserNotifier extends AuthUserNotifier {
  FakeAuthUserNotifier(this.user);

  final User? user;

  @override
  AsyncValue<User?> build() => AsyncValue.data(user);
}