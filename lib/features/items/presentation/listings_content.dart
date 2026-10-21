import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading.dart';
import '../data/lost_item.dart';
import 'item_card.dart';
import 'item_detail_screen.dart';

class ListingsContent extends StatelessWidget {
  const ListingsContent(
      {super.key,
      required this.items,
      required this.isLoading,
      required this.onRefresh,
      this.emptyTitle = 'Nothing here yet',
      this.emptyMessage = 'Try another search or check back later.'});

  final List<LostItem>? items;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading && items == null) {
      return const AppLoading(label: 'Finding listings…');
    }
    final data = items ?? const <LostItem>[];
    if (data.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child:
            ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
          const SizedBox(height: 100),
          const Icon(Icons.search_off_rounded,
              size: 46, color: AppColors.muted),
          const SizedBox(height: 12),
          Center(
              child: Text(emptyTitle,
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 18))),
          const SizedBox(height: 5),
          Center(
              child: Text(emptyMessage,
                  style: const TextStyle(color: AppColors.muted))),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        itemCount: data.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) => ItemCard(
          item: data[index],
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => ItemDetailScreen(item: data[index]))),
        ),
      ),
    );
  }
}
