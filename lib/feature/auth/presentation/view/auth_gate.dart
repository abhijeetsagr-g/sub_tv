import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sub_tv/feature/auth/presentation/state/auth_providers.dart';
import 'package:sub_tv/feature/auth/presentation/view/home_view.dart';
import 'package:sub_tv/feature/auth/presentation/view/sign_in_view.dart';

class AuthGate extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authUserProvider);
    return auth.when(
      data: (user) => user == null ? SignInView() : const HomeView(),
      error: (error, stackTrace) => SignInView(),
      loading: () =>
          Scaffold(body: Center(child: CircularProgressIndicator.adaptive())),
    );
  }
}
