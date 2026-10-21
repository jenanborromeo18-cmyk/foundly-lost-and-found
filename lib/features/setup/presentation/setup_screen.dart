import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.hub_rounded,
                              color: AppColors.teal, size: 40),
                          const SizedBox(height: 20),
                          const Text('Connect your Supabase project',
                              style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink)),
                          const SizedBox(height: 10),
                          const Text(
                              'Foundly is ready to run. Add your project URL and public anon key to start using it.',
                              style: TextStyle(
                                  color: AppColors.muted, height: 1.5)),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: AppColors.canvas,
                                borderRadius: BorderRadius.circular(14)),
                            child: const SelectableText(
                                'flutter run --dart-define-from-file=.env.json',
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: AppColors.ink)),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                              'Copy env.example.json to .env.json, fill in both values, then run the command above. See README.md for the database setup.',
                              style: TextStyle(
                                  color: AppColors.muted, height: 1.5)),
                        ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
