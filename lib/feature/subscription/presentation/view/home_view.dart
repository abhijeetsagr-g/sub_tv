import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:sub_tv/feature/auth/presentation/state/auth_providers.dart';
import 'package:sub_tv/feature/subscription/model/show.dart';
import 'package:sub_tv/feature/subscription/presentation/state/subscription_providers.dart';
import 'package:sub_tv/feature/subscription/service/subscription_service.dart';
import 'package:sub_tv/shared/model/user.dart';

/// Signed-in landing screen — hosts the subscription list streamed from
/// [subscriptionShowsProvider].
///
/// Renders every provider state (loading / error / data) so the
/// subscription pipeline can be exercised end-to-end:
/// * error   → "Try again" refetches; a [SubscriptionUnauthorizedException]
///   offers "Re-authorize YouTube" which re-runs `ensureYoutubeAccess()` and
///   then refetches.
/// * data    → pull-to-refresh re-fetches with `forceRetry: true`, bypassing
///   the day-long cache.
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).value;
    final shows = ref.watch(subscriptionShowsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SvgPicture.asset('assets/image/icon.svg', width: 24, height: 24),
            const SizedBox(width: 8),
            const Text('SubTV'),
          ],
        ),
        actions: [
          // Sign-out flips the auth stream; the gate then swaps back to
          // SignInView automatically — no navigation needed here.
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => ref.read(authUserProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: shows.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(error: error),
          data: (items) => items.isEmpty
              ? _EmptyState(user: user)
              : _ShowList(user: user, shows: items),
        ),
      ),
    );
  }
}

/// Pull-to-refresh list of subscribed channels.
class _ShowList extends ConsumerWidget {
  const _ShowList({required this.user, required this.shows});

  final User? user;
  final List<Show> shows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () => ref
          .read(subscriptionShowsProvider.notifier)
          .refetch(forceRetry: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: shows.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 88),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${_firstName(user)}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${shows.length} channel${shows.length == 1 ? '' : 's'}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final show = shows[index - 1];
          return _ShowTile(key: ValueKey(show.id), show: show);
        },
      ),
    );
  }
}

/// One subscribed channel: thumbnail, title, description.
class _ShowTile extends StatelessWidget {
  const _ShowTile({super.key, required this.show});

  final Show show;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: _Thumbnail(show: show),
      title: Text(
        show.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.titleSmall,
      ),
      subtitle: show.description.isEmpty
          ? null
          : Text(
              show.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}

/// Channel thumbnail, falling back to a letter tile when there's no image
/// (or the network image fails to load).
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.show});

  final Show show;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = show.thumbnailUrl;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? _FallbackThumb(show: show)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _1, _2) => _FallbackThumb(show: show),
            ),
    );
  }
}

class _FallbackThumb extends StatelessWidget {
  const _FallbackThumb({required this.show});

  final Show show;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = show.title.isEmpty ? '?' : show.title[0].toUpperCase();

    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
    );
  }
}

/// Provider error state: surfaces the failure and offers recovery.
class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final unauthorized = error is SubscriptionUnauthorizedException;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              unauthorized ? Icons.video_library_outlined : Icons.cloud_off,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              unauthorized
                  ? 'YouTube access needed'
                  : "Couldn't load your subscriptions",
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              unauthorized
                  ? 'Re-authorize SubTV with your YouTube account to '
                      'see your channels.'
                  : 'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (unauthorized)
              FilledButton.icon(
                onPressed: () => _reauthorize(context, ref),
                icon: const Icon(Icons.account_circle),
                label: const Text('Re-authorize YouTube'),
              )
            else
              FilledButton.icon(
                onPressed: () => _retry(ref),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
          ],
        ),
      ),
    );
  }

  void _retry(WidgetRef ref) {
    ref.read(subscriptionShowsProvider.notifier).refetch(forceRetry: true);
  }

  Future<void> _reauthorize(BuildContext context, WidgetRef ref) async {
    final granted =
        await ref.read(authUserProvider.notifier).ensureYoutubeAccess();
    // On success the auth stream fires → provider refetches automatically,
    // even across accounts. Without a grant, keep showing the error state.
    if (granted && context.mounted) {
      ref.read(subscriptionShowsProvider.notifier).refetch(forceRetry: true);
    }
  }
}

/// Friendly empty state before the first channel shows up.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/image/icon.svg',
                width: 64,
                height: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome, ${_firstName(user)}',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No subscriptions yet. Subscribe to YouTube channels and '
              'pull down to refresh — they will appear here as TV channels.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// First name for the greeting (display name > email local part > fallback).
String _firstName(User? user) {
  final raw = user?.displayName ?? user?.email ?? '';
  final first = raw.split(' ').first;
  return first.isEmpty ? 'there' : first;
}