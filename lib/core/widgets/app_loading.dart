import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.label = 'Loading…'});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.teal),
          ),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(color: AppColors.muted)),
        ]),
      );
}

void showMessage(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? AppColors.danger : AppColors.ink,
    ));
}
