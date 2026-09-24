import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:sub_tv/feature/auth/presentation/state/auth_providers.dart';
import 'package:sub_tv/feature/auth/presentation/widget/google_sign_in_button.dart';

class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
  /// True while an interactive sign-in is in flight, so the button shows a
  /// spinner and can't be double-tapped. If the flow is canceled, the gate
  /// keeps showing this view and `_signingIn` resets, re-enabling the button.
  bool _signingIn = false;

  Future<void> _signIn() async {
    if (_signingIn) return;
    setState(() => _signingIn = true);
    try {
      await ref.read(authUserProvider.notifier).signIn();
    } finally {
      // Successful sign-in swaps the gate to HomeView and unmounts us, so the
      // mounted guard keeps the reset from firing on a dead element.
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand block.
              SvgPicture.asset(
                'assets/image/icon.svg',
                width: 96,
                height: 96,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                'Your subscriptions, as linear TV channels.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              GoogleSignInButton(
                onPressed: () => _signIn(),
                pending: _signingIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
