import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/setup/presentation/setup_screen.dart';

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key, required this.isConfigured});

  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foundly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: isConfigured ? const AuthGate() : const SetupScreen(),
    );
  }
}
