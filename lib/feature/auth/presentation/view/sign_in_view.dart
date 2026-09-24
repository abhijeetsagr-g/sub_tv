import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sub_tv/feature/auth/presentation/state/auth_providers.dart';

/// First screen for signed-out users: brand + the Google sign-in trigger.
///
/// The button press is a user interaction, which matters on Android —
/// both `authenticate()` (via `scopeHint`) and the fallback
/// `ensureYoutubeAccess()` need one to show system UI.
class SignInView extends ConsumerWidget {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authUserProvider);
    final busy = auth.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand block.
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.live_tv,
                  size: 56,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SubTV',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your subscriptions, as linear TV channels.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              // Sign-in trigger. Only needs identity: scopes are requested
              // via scopeHint inside the service, so one tap covers auth+authz.
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : () =>
                          ref.read(authUserProvider.notifier).signIn(),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.g_mobiledata, size: 28),
                label: Text(busy ? 'Signing in…' : 'Sign in with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}