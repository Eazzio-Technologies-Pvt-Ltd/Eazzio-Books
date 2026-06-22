class Task {
  final int id;
  final String title;
  final int userId;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.userId,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      userId: json['user_id'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    int? userId,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
