import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../items/data/item_repository.dart';
import 'my_claims_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser!;
    final fullName = user.userMetadata?['full_name'] as String?;
    final name = fullName?.trim().isNotEmpty == true
        ? fullName!.trim()
        : 'Community member';
    return SafeArea(
      child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
          children: [
            const Text('Your profile',
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: 22),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(children: [
                      CircleAvatar(
                          radius: 29,
                          backgroundColor: AppColors.paleTeal,
                          child: Text(name[0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.tealDark,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800))),
                      const SizedBox(width: 15),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(name,
                                style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(user.email ?? '',
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 13))
                          ])),
                    ]))),
            const SizedBox(height: 19),
            const Text('Your activity',
                style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            Card(
              child: Column(children: [
                ListTile(
                    leading: const Icon(Icons.mark_email_unread_outlined,
                        color: AppColors.teal),
                    title: const Text('My claim requests'),
                    subtitle: const Text('Track replies from item owners'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const MyClaimsScreen()))),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('About Foundly',
                style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Foundly helps neighbors share lost and found items, verify claims, and reunite belongings with their owners.',
                        style:
                            TextStyle(color: AppColors.muted, height: 1.5)))),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                ref.invalidate(listingsProvider);
                ref.invalidate(myClaimsProvider);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ]),
    );
  }
}
