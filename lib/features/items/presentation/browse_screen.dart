import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/item_categories.dart';
import '../data/item_repository.dart';
import 'listings_content.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});
  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _type;
  String? _category;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter =
        (query: _query, type: _type, category: _category, mine: false);
    final listings = ref.watch(listingsProvider(filter));
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 5),
          child: Text('Browse listings',
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text('Search your community for a match.',
              style: TextStyle(color: AppColors.muted)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: TextField(
            controller: _search,
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350),
                  () => setState(() => _query = value));
            },
            decoration: InputDecoration(
              hintText: 'Search by item name',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _debounce?.cancel();
                        _search.clear();
                        setState(() => _query = '');
                      }),
            ),
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(
          height: 43,
          child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                _FilterChip(
                    label: 'All',
                    selected: _type == null,
                    onTap: () => setState(() => _type = null)),
                _FilterChip(
                    label: 'Lost',
                    selected: _type == 'lost',
                    onTap: () => setState(() => _type = 'lost')),
                _FilterChip(
                    label: 'Found',
                    selected: _type == 'found',
                    onTap: () => setState(() => _type = 'found')),
                const SizedBox(width: 6),
                PopupMenuButton<String?>(
                  onSelected: (value) => setState(() => _category = value),
                  itemBuilder: (context) => [
                    const PopupMenuItem<String?>(
                        value: null, child: Text('All categories')),
                    ...itemCategories.map((category) =>
                        PopupMenuItem(value: category, child: Text(category))),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.border)),
                    child: Row(children: [
                      Text(_category ?? 'Category',
                          style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 5),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18)
                    ]),
                  ),
                ),
              ]),
        ),
        const SizedBox(height: 9),
        Expanded(
          child: listings.hasError && listings.valueOrNull == null
              ? _LoadError(
                  onRetry: () => ref.invalidate(listingsProvider(filter)))
              : ListingsContent(
                  items: listings.valueOrNull,
                  isLoading: listings.isLoading,
                  onRefresh: () async {
                    ref.invalidate(listingsProvider(filter));
                  },
                  emptyTitle: 'No matches found',
                  emptyMessage: 'Try a different search or filter.',
                ),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 7),
        child: ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onTap(),
            showCheckmark: false),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Could not load listings.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again')),
        ]),
      );
}
