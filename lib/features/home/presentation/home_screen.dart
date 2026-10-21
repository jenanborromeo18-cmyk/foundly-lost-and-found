import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../items/data/item_repository.dart';
import '../../items/presentation/item_card.dart';
import '../../items/presentation/item_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = Supabase.instance.client.auth.currentUser
        ?.userMetadata?['full_name'] as String?;
    final firstName = name?.trim().split(' ').first;
    final feed = ref.watch(
        listingsProvider((query: '', type: null, category: null, mine: false)));
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 19, 20, 16),
          child: Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: AppColors.paleTeal,
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.volunteer_activism_rounded,
                    color: AppColors.teal)),
            const SizedBox(width: 12),
            const Text('Foundly',
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const Spacer(),
            CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                    (firstName?.isNotEmpty == true ? firstName![0] : 'F')
                        .toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.teal, fontWeight: FontWeight.bold))),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(listingsProvider((
                query: '',
                type: null,
                category: null,
                mine: false,
              )));
            },
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.tealDark, AppColors.teal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Good day${firstName == null ? '' : ', $firstName'} 👋',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          const Text('Every lost thing has a way home.',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          const Text(
                              'Help your community reconnect with the things they care about.',
                              style: TextStyle(
                                  color: Colors.white70, height: 1.4)),
                          const SizedBox(height: 18),
                          Row(children: [
                            const Icon(Icons.favorite_rounded,
                                color: AppColors.orange, size: 17),
                            const SizedBox(width: 6),
                            Text(
                                '${feed.valueOrNull?.length ?? '…'} open community posts',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ]),
                  ),
                  const SizedBox(height: 25),
                  const Text('Recently posted',
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  const SizedBox(height: 7),
                  feed.when(
                    loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 45),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.teal))),
                    error: (error, stack) => const _FeedMessage(
                        text:
                            'Could not load listings. Pull down to try again.'),
                    data: (items) => items.isEmpty
                        ? const _FeedMessage(
                            text:
                                'No open posts just yet. Be the first to share one!')
                        : Column(
                            children: items
                                .take(5)
                                .map((item) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      child: ItemCard(
                                          item: item,
                                          onTap: () => Navigator.of(context)
                                              .push(MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      ItemDetailScreen(
                                                          item: item)))),
                                    ))
                                .toList()),
                  ),
                ]),
          ),
        ),
      ]),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 18),
        child: Center(
            child: Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.5))),
      );
}
