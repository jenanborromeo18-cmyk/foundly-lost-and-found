import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final publicKey = supabasePublishableKey.isNotEmpty
      ? supabasePublishableKey
      : supabaseAnonKey;
  final isConfigured = supabaseUrl.isNotEmpty && publicKey.isNotEmpty;

  if (isConfigured) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: publicKey);
  }

  runApp(ProviderScope(child: LostFoundApp(isConfigured: isConfigured)));
}
