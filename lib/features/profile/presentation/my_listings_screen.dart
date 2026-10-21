import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../items/data/item_repository.dart';
import '../../items/presentation/listings_content.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const filter = (query: '', type: null, category: null, mine: true);
    final listings = ref.watch(listingsProvider(filter));
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 5),
          child: Text('My posts',
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Text('Manage the items you have reported.',
              style: TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: listings.hasError && listings.valueOrNull == null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Could not load your posts.',
                      style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                      onPressed: () => ref.invalidate(listingsProvider(filter)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'))
                ]))
              : ListingsContent(
                  items: listings.valueOrNull,
                  isLoading: listings.isLoading,
                  onRefresh: () async {
                    ref.invalidate(listingsProvider(filter));
                  },
                  emptyTitle: 'No posts yet',
                  emptyMessage:
                      'Your lost and found reports will show up here.',
                ),
        ),
      ]),
    );
  }
}
