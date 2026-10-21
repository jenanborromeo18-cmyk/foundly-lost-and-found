import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../data/lost_item.dart';

class ItemCard extends StatelessWidget {
  const ItemCard(
      {super.key,
      required this.item,
      required this.onTap,
      this.compact = false});

  final LostItem item;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isLost = item.isLost;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (item.photoUrl != null && item.photoUrl!.isNotEmpty)
            Image.network(
              item.photoUrl!,
              height: compact ? 132 : 178,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  _PhotoPlaceholder(height: compact ? 132 : 178),
            )
          else
            _PhotoPlaceholder(height: compact ? 132 : 178),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _Tag(
                    label: isLost ? 'LOST' : 'FOUND',
                    color:
                        isLost ? const Color(0xFFFFF0DE) : AppColors.paleTeal,
                    textColor:
                        isLost ? const Color(0xFF9B5B0F) : AppColors.tealDark),
                const SizedBox(width: 7),
                _Tag(
                    label: item.category,
                    color: AppColors.canvas,
                    textColor: AppColors.muted),
                const Spacer(),
                Text(relativeDate(item.createdAt),
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
              const SizedBox(height: 10),
              Text(item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.muted),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13))),
              ]),
              if (item.status != 'open') ...[
                const SizedBox(height: 10),
                _Tag(
                    label: item.status.toUpperCase(),
                    color: AppColors.canvas,
                    textColor: AppColors.muted),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFFEAF0EF),
        child: const Center(
            child:
                Icon(Icons.image_outlined, size: 38, color: Color(0xFF9BAEAB))),
      );
}

class _Tag extends StatelessWidget {
  const _Tag(
      {required this.label, required this.color, required this.textColor});
  final String label;
  final Color color;
  final Color textColor;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(30)),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                letterSpacing: .4,
                fontWeight: FontWeight.w700,
                color: textColor)),
      );
}
