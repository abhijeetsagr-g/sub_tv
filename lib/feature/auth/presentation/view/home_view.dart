import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:sub_tv/feature/auth/presentation/state/auth_providers.dart';
import 'package:sub_tv/shared/model/user.dart';

/// Signed-in landing screen — the shell where the channel grid will live.
///
/// The channels feature doesn't exist yet, so for now this renders the app
/// chrome (brand, user identity, sign-out) plus an empty state that the linear
/// TV channel list will eventually replace.
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AuthGate only builds us while signed in, so `value` is non-null here;
    // the guard keeps the widget safe to preview in isolation too.
    final user = ref.watch(authUserProvider).value;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Avatar(user: user),
                const SizedBox(height: 16),
                Text(
                  'Welcome, ${_firstName(user)}',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                // Empty state: placeholder for the upcoming channel grid.
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
                  'No channels yet',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your YouTube subscriptions will appear here as linear TV '
                  'channels. This is where the retro channel grid lands.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// First name for the greeting (display name > email local part > fallback).
  String _firstName(User? user) {
    final raw = user?.displayName ?? user?.email ?? '';
    final first = raw.split(' ').first;
    return first.isEmpty ? 'there' : first;
  }
}

/// User avatar: photo when available, initials otherwise.
class _Avatar extends StatelessWidget {
  const _Avatar({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user?.imageUrl;
    return CircleAvatar(
      radius: 40,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
      child: Text(
        _initials(),
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
    );
  }

  String _initials() {
    final name = user?.displayName?.trim();
    if (name == null || name.isEmpty) {
      final email = user?.email ?? '';
      return email.isEmpty ? '?' : email[0].toUpperCase();
    }
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}
