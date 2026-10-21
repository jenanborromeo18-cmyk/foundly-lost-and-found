import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_loading.dart';
import '../../items/data/item_repository.dart';
import '../../items/data/lost_item.dart';
import '../../items/presentation/item_detail_screen.dart';

class MyClaimsScreen extends ConsumerWidget {
  const MyClaimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claims = ref.watch(myClaimsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My claim requests')),
      body: claims.when(
        loading: () => const AppLoading(label: 'Loading your requests…'),
        error: (error, stack) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Could not load your claim requests.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
              onPressed: () => ref.invalidate(myClaimsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'))
        ])),
        data: (values) => values.isEmpty
            ? const _EmptyClaims()
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myClaimsProvider);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  itemCount: values.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) => _MyClaimCard(
                      claim: values[index].claim, item: values[index].item),
                ),
              ),
      ),
    );
  }
}

class _EmptyClaims extends StatelessWidget {
  const _EmptyClaims();
  @override
  Widget build(BuildContext context) => const Center(
      child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.mark_email_unread_outlined,
                color: AppColors.muted, size: 40),
            SizedBox(height: 12),
            Text('No claim requests yet',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontSize: 17)),
            SizedBox(height: 5),
            Text(
                'If you reach out about a found item, you can track the reply here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.45))
          ])));
}

class _MyClaimCard extends StatelessWidget {
  const _MyClaimCard({required this.claim, required this.item});
  final ItemClaim claim;
  final LostItem item;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => ItemDetailScreen(item: item))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(item.title,
                        style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800))),
                _ClaimStatus(status: claim.status)
              ]),
              const SizedBox(height: 7),
              Text('Sent ${relativeDate(claim.createdAt)} · ${item.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              if (claim.ownerMessage?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.paleTeal,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(claim.ownerMessage!,
                        style: const TextStyle(
                            color: AppColors.tealDark, height: 1.4))),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Text('Status: ${claim.status}',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12)),
                const Spacer(),
                const Text('View listing',
                    style: TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward_rounded,
                    size: 15, color: AppColors.teal)
              ]),
            ]),
          ),
        ),
      );
}

class _ClaimStatus extends StatelessWidget {
  const _ClaimStatus({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final approved = status == 'approved';
    final rejected = status == 'rejected';
    final color = approved
        ? AppColors.tealDark
        : rejected
            ? AppColors.danger
            : const Color(0xFF9B5B0F);
    final bg = approved
        ? AppColors.paleTeal
        : rejected
            ? const Color(0xFFFFEAEC)
            : const Color(0xFFFFF0DE);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(status.toUpperCase(),
            style: TextStyle(
                color: color,
                fontSize: 9,
                letterSpacing: .4,
                fontWeight: FontWeight.w800)));
  }
}
