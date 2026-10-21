import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_loading.dart' show showMessage;
import '../data/item_repository.dart';
import '../data/lost_item.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.item});
  final LostItem item;
  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late String _status = widget.item.status;
  bool _busy = false;

  bool get _isOwner =>
      Supabase.instance.client.auth.currentUser?.id == widget.item.userId;

  Future<void> _claim() async {
    final controller = TextEditingController();
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            22, 22, 22, MediaQuery.viewInsetsOf(context).bottom + 22),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Could this be yours?',
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              const Text(
                  'Share a detail that helps the poster confirm it belongs to you. Keep private information out of your message.',
                  style: TextStyle(color: AppColors.muted, height: 1.45)),
              const SizedBox(height: 15),
              TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 400,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      hintText: 'Describe a detail only the owner would know…',
                      alignLabelWithHint: true)),
              const SizedBox(height: 12),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(controller.text.trim()),
                      child: const Text('Send claim request'))),
            ]),
      ),
    );
    controller.dispose();
    if (message == null) return;
    if (message.length < 10) {
      if (mounted) {
        showMessage(context,
            'Add a little more detail so the poster can verify your claim.',
            isError: true);
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(itemRepositoryProvider)
          .submitClaim(itemId: widget.item.id, message: message);
      ref.invalidate(itemClaimsProvider(widget.item.id));
      ref.invalidate(myClaimsProvider);
      if (mounted) showMessage(context, 'Your claim request was sent.');
    } catch (_) {
      if (mounted) {
        showMessage(context,
            'Could not send your request. You may have already submitted one.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(String status) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(itemRepositoryProvider)
          .updateStatus(widget.item.id, status);
      if (!mounted) return;
      setState(() => _status = status);
      ref.invalidate(listingsProvider);
      ref.invalidate(itemClaimsProvider(widget.item.id));
      ref.invalidate(myClaimsProvider);
      showMessage(
          context,
          status == 'open'
              ? 'Your listing is open again.'
              : 'Listing updated.');
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Could not update this listing.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteListing() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this post?'),
        content:
            const Text('This will remove the listing and its claim requests.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'))
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(itemRepositoryProvider).deleteListing(widget.item.id);
      ref.invalidate(listingsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Could not delete this post.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewClaim(ItemClaim claim, String status) async {
    String? ownerMessage;
    if (status == 'approved') {
      final controller = TextEditingController();
      ownerMessage = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approve claim'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Add a safe way to coordinate, such as where to meet. This message will be visible to the claimant.',
                    style: TextStyle(height: 1.45)),
                const SizedBox(height: 14),
                TextField(
                    controller: controller,
                    maxLines: 3,
                    maxLength: 300,
                    decoration:
                        const InputDecoration(hintText: 'Optional message')),
              ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Approve')),
          ],
        ),
      );
      controller.dispose();
      if (ownerMessage == null) return;
    }
    setState(() => _busy = true);
    try {
      final repository = ref.read(itemRepositoryProvider);
      await repository.updateClaimStatus(claim.id, status,
          ownerMessage: ownerMessage);
      if (status == 'approved') {
        if (mounted) {
          setState(() => _status = 'matched');
        }
      }
      ref.invalidate(itemClaimsProvider(widget.item.id));
      ref.invalidate(myClaimsProvider);
      ref.invalidate(listingsProvider);
      if (mounted) {
        showMessage(
            context,
            status == 'approved'
                ? 'Claim approved. Coordinate with the person who reached out.'
                : 'Claim declined.');
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Could not update this claim.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final claims = ref.watch(itemClaimsProvider(widget.item.id));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    ItemClaim? myClaim;
    for (final claim in claims.valueOrNull ?? const <ItemClaim>[]) {
      if (claim.claimantId == currentUserId) {
        myClaim = claim;
        break;
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Listing details'), actions: [
        if (_isOwner)
          PopupMenuButton<String>(
            onSelected: (value) =>
                value == 'delete' ? _deleteListing() : _setStatus(value),
            itemBuilder: (context) => [
              if (_status != 'open')
                const PopupMenuItem(
                    value: 'open', child: Text('Reopen listing')),
              if (_status == 'open' || _status == 'matched')
                const PopupMenuItem(
                    value: 'returned', child: Text('Mark as returned')),
              const PopupMenuItem(value: 'delete', child: Text('Delete post')),
            ],
          ),
      ]),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 35),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: widget.item.photoUrl == null
                  ? Container(
                      height: 235,
                      color: const Color(0xFFEAF0EF),
                      child: const Center(
                          child: Icon(Icons.image_outlined,
                              size: 52, color: Color(0xFF9BAEAB))))
                  : Image.network(widget.item.photoUrl!,
                      height: 235,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                          height: 235,
                          color: const Color(0xFFEAF0EF),
                          child: const Icon(Icons.image_not_supported_outlined,
                              size: 42, color: AppColors.muted))),
            ),
            const SizedBox(height: 19),
            Row(children: [
              _StatusTag(
                  label: widget.item.isLost ? 'LOST' : 'FOUND',
                  color: widget.item.isLost
                      ? const Color(0xFFFFF0DE)
                      : AppColors.paleTeal),
              const SizedBox(width: 8),
              _StatusTag(
                  label: widget.item.category,
                  color: AppColors.canvas,
                  textColor: AppColors.muted),
              const Spacer(),
              if (_status != 'open')
                _StatusTag(
                    label: _status.toUpperCase(),
                    color: AppColors.canvas,
                    textColor: AppColors.muted),
            ]),
            const SizedBox(height: 11),
            Text(widget.item.title,
                style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    height: 1.15)),
            const SizedBox(height: 12),
            _InfoLine(
                icon: Icons.location_on_outlined, text: widget.item.location),
            const SizedBox(height: 8),
            _InfoLine(
                icon: Icons.calendar_today_outlined,
                text:
                    '${widget.item.isLost ? 'Lost' : 'Found'} ${formatDate(widget.item.occurredAt)}  ·  Posted ${relativeDate(widget.item.createdAt)}'),
            const SizedBox(height: 8),
            _InfoLine(
                icon: Icons.person_outline_rounded,
                text:
                    'Posted by ${widget.item.ownerName ?? 'Community member'}'),
            const SizedBox(height: 20),
            const Text('About this item',
                style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(widget.item.description,
                style: const TextStyle(
                    color: AppColors.muted, height: 1.55, fontSize: 15)),
            const SizedBox(height: 22),
            if (_isOwner) ...[
              const Text('Claim requests',
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              claims.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2))),
                error: (error, stack) => const Text(
                    'Could not load claim requests.',
                    style: TextStyle(color: AppColors.muted)),
                data: (values) => values.isEmpty
                    ? const Text('No one has reached out yet.',
                        style: TextStyle(color: AppColors.muted))
                    : Column(
                        children: values
                            .map((claim) => _ClaimCard(
                                claim: claim,
                                busy: _busy,
                                onApprove: () =>
                                    _reviewClaim(claim, 'approved'),
                                onDecline: () =>
                                    _reviewClaim(claim, 'rejected')))
                            .toList()),
              ),
              const SizedBox(height: 20),
            ] else if (_status == 'open') ...[
              if (myClaim != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.paleTeal,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.tealDark),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text('Your claim request is ${myClaim.status}.',
                            style: const TextStyle(
                                color: AppColors.tealDark,
                                fontWeight: FontWeight.w700)))
                  ]),
                )
              else
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: _busy ? null : _claim,
                        icon: const Icon(Icons.pan_tool_alt_outlined),
                        label: const Text('I think this is mine'))),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(15)),
                child: myClaim == null
                    ? const Text('This listing has been marked as resolved.',
                        style: TextStyle(color: AppColors.muted))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text('Your claim request is ${myClaim.status}.',
                                style: const TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700)),
                            if (myClaim.ownerMessage?.isNotEmpty == true) ...[
                              const SizedBox(height: 8),
                              Text(myClaim.ownerMessage!,
                                  style: const TextStyle(
                                      color: AppColors.muted, height: 1.45)),
                            ],
                          ]),
              ),
            ],
            if (_isOwner && _status == 'matched') ...[
              const SizedBox(height: 3),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _setStatus('returned'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark as returned'))),
            ],
          ]),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 17, color: AppColors.muted),
        const SizedBox(width: 7),
        Expanded(
            child: Text(text,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)))
      ]);
}

class _StatusTag extends StatelessWidget {
  const _StatusTag(
      {required this.label,
      required this.color,
      this.textColor = AppColors.tealDark});
  final String label;
  final Color color;
  final Color textColor;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: textColor,
              fontSize: 10,
              letterSpacing: .4,
              fontWeight: FontWeight.w700)));
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard(
      {required this.claim,
      required this.busy,
      required this.onApprove,
      required this.onDecline});
  final ItemClaim claim;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(claim.claimantName ?? 'Community member',
                      style: const TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w700))),
              Text(claim.status.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700))
            ]),
            const SizedBox(height: 8),
            Text(claim.message,
                style: const TextStyle(color: AppColors.muted, height: 1.45)),
            if (claim.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: busy ? null : onDecline,
                        child: const Text('Decline'))),
                const SizedBox(width: 9),
                Expanded(
                    child: FilledButton(
                        onPressed: busy ? null : onApprove,
                        child: const Text('Approve'))),
              ]),
            ],
          ]),
        ),
      );
}
