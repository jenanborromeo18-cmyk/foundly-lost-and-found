class LostItem {
  const LostItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.location,
    required this.occurredAt,
    required this.status,
    required this.createdAt,
    this.photoUrl,
    this.photoPath,
    this.ownerName,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final String type;
  final String category;
  final String location;
  final DateTime? occurredAt;
  final String status;
  final DateTime createdAt;
  final String? photoUrl;
  final String? photoPath;
  final String? ownerName;

  bool get isLost => type == 'lost';

  factory LostItem.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'];
    final profileMap = profile is Map<String, dynamic> ? profile : null;
    return LostItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: map['item_type'] as String,
      category: map['category'] as String,
      location: map['location_name'] as String,
      occurredAt: map['occurred_at'] == null
          ? null
          : DateTime.tryParse(map['occurred_at'] as String),
      status: map['status'] as String? ?? 'open',
      createdAt: DateTime.parse(map['created_at'] as String),
      photoUrl: map['photo_url'] as String?,
      photoPath: map['photo_path'] as String?,
      ownerName: profileMap?['full_name'] as String?,
    );
  }
}

class ItemClaim {
  const ItemClaim({
    required this.id,
    required this.itemId,
    required this.claimantId,
    required this.message,
    required this.status,
    required this.createdAt,
    this.claimantName,
    this.ownerMessage,
  });

  final String id;
  final String itemId;
  final String claimantId;
  final String message;
  final String status;
  final DateTime createdAt;
  final String? claimantName;
  final String? ownerMessage;

  factory ItemClaim.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'];
    final profileMap = profile is Map<String, dynamic> ? profile : null;
    return ItemClaim(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      claimantId: map['claimant_id'] as String,
      message: map['message'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      claimantName: profileMap?['full_name'] as String?,
      ownerMessage: map['owner_message'] as String?,
    );
  }
}

class MyClaim {
  const MyClaim({required this.claim, required this.item});
  final ItemClaim claim;
  final LostItem item;

  factory MyClaim.fromMap(Map<String, dynamic> map) => MyClaim(
        claim: ItemClaim.fromMap(map),
        item: LostItem.fromMap(map['items'] as Map<String, dynamic>),
      );
}
