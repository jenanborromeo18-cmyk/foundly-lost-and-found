import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'lost_item.dart';

typedef ListingFilter = ({
  String query,
  String? type,
  String? category,
  bool mine
});

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemRepository(Supabase.instance.client),
);

final listingsProvider = FutureProvider.family<List<LostItem>, ListingFilter>(
  (ref, filter) => ref.read(itemRepositoryProvider).fetchListings(filter),
);

final itemClaimsProvider = FutureProvider.family<List<ItemClaim>, String>(
  (ref, itemId) => ref.read(itemRepositoryProvider).fetchClaims(itemId),
);

final myClaimsProvider = FutureProvider<List<MyClaim>>(
  (ref) => ref.read(itemRepositoryProvider).fetchMyClaims(),
);

class ItemRepository {
  ItemRepository(this._client);
  final SupabaseClient _client;

  Future<List<LostItem>> fetchListings(ListingFilter filter) async {
    var query = _client.from('items').select('*, profiles(full_name)');
    if (filter.mine) {
      query = query.eq('user_id', _client.auth.currentUser!.id);
    } else {
      query = query.eq('status', 'open');
    }
    if (filter.type != null) query = query.eq('item_type', filter.type!);
    if (filter.category != null) query = query.eq('category', filter.category!);
    if (filter.query.trim().isNotEmpty) {
      final safeQuery =
          filter.query.trim().replaceAll('%', r'\%').replaceAll('_', r'\_');
      query = query.ilike('title', '%$safeQuery%');
    }
    final rows = await query.order('created_at', ascending: false).limit(100);
    return rows.map((row) => LostItem.fromMap(row)).toList();
  }

  Future<void> createListing({
    required String title,
    required String description,
    required String type,
    required String category,
    required String location,
    required DateTime occurredAt,
    Uint8List? photoBytes,
    String? photoName,
  }) async {
    final userId = _client.auth.currentUser!.id;
    String? photoUrl;
    String? photoPath;
    if (photoBytes != null && photoName != null) {
      final extension = photoName.contains('.')
          ? photoName.split('.').last.toLowerCase()
          : 'jpg';
      photoPath = '$userId/${DateTime.now().microsecondsSinceEpoch}.$extension';
      await _client.storage.from('item-photos').uploadBinary(
            photoPath,
            photoBytes,
            fileOptions:
                FileOptions(contentType: _contentType(extension), upsert: true),
          );
      photoUrl = _client.storage.from('item-photos').getPublicUrl(photoPath);
    }
    try {
      await _client.from('items').insert({
        'user_id': userId,
        'title': title.trim(),
        'description': description.trim(),
        'item_type': type,
        'category': category,
        'location_name': location.trim(),
        'occurred_at': occurredAt.toUtc().toIso8601String(),
        'photo_url': photoUrl,
        'photo_path': photoPath,
      });
    } catch (_) {
      if (photoPath != null) {
        try {
          await _client.storage.from('item-photos').remove([photoPath]);
        } catch (_) {}
      }
      rethrow;
    }
  }

  String _contentType(String extension) => switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        _ => 'image/jpeg',
      };

  Future<void> updateStatus(String itemId, String status) async {
    await _client.rpc('set_item_status', params: {
      'p_item_id': itemId,
      'p_status': status,
    });
  }

  Future<void> deleteListing(String itemId) async {
    final row = await _client
        .from('items')
        .select('photo_path')
        .eq('id', itemId)
        .maybeSingle();
    await _client.from('items').delete().eq('id', itemId);
    final photoPath = row?['photo_path'] as String?;
    if (photoPath != null) {
      try {
        await _client.storage.from('item-photos').remove([photoPath]);
      } catch (_) {
        // The listing is already removed; a storage cleanup failure should not undo it.
      }
    }
  }

  Future<void> submitClaim(
      {required String itemId, required String message}) async {
    await _client.from('claims').insert({
      'item_id': itemId,
      'claimant_id': _client.auth.currentUser!.id,
      'message': message.trim(),
    });
  }

  Future<List<ItemClaim>> fetchClaims(String itemId) async {
    final rows = await _client
        .from('claims')
        .select('*, profiles:profiles!claims_claimant_id_fkey(full_name)')
        .eq('item_id', itemId)
        .order('created_at', ascending: false);
    return rows.map((row) => ItemClaim.fromMap(row)).toList();
  }

  Future<List<MyClaim>> fetchMyClaims() async {
    final rows = await _client
        .from('claims')
        .select('*, items:items!claims_item_id_fkey(*, profiles(full_name))')
        .eq('claimant_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false);
    return rows.map((row) => MyClaim.fromMap(row)).toList();
  }

  Future<void> updateClaimStatus(String claimId, String status,
      {String? ownerMessage}) async {
    await _client.rpc('review_item_claim', params: {
      'p_claim_id': claimId,
      'p_status': status,
      'p_owner_message': ownerMessage?.trim(),
    });
  }
}
