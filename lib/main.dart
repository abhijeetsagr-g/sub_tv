import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sub_tv/core/theme/app_theme.dart';
import 'package:sub_tv/feature/auth/presentation/view/auth_gate.dart';

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SubTV',
      theme: AppTheme.theme,
      home: AuthGate(),
    );
  }
}
