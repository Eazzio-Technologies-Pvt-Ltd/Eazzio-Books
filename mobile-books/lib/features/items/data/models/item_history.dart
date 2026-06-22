class ItemHistory {
  final int id;
  final int itemId;
  final int userId;
  final String action;
  final String description;
  final String? username;
  final DateTime? createdAt;

  ItemHistory({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.action,
    required this.description,
    this.username,
    this.createdAt,
  });

  factory ItemHistory.fromJson(Map<String, dynamic> json) {
    return ItemHistory(
      id: json['id'] as int,
      itemId: json['item_id'] as int? ?? json['itemId'] as int? ?? 0,
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      action: json['action'] as String? ?? 'UPDATED',
      description: json['description'] as String? ?? '',
      username: json['username'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'user_id': userId,
      'action': action,
      'description': description,
      'username': username,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
