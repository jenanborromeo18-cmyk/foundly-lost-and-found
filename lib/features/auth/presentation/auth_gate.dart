import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/app_loading.dart';
import '../../home/presentation/home_shell.dart';
import '../data/auth_providers.dart';
import 'sign_in_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final session = auth.asData?.value.session ??
        Supabase.instance.client.auth.currentSession;
    if (session != null) return const HomeShell();
    if (auth.isLoading &&
        Supabase.instance.client.auth.currentSession == null) {
      return const Scaffold(body: AppLoading(label: 'Getting things ready…'));
    }
    return const SignInScreen();
  }
}
