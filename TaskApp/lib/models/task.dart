class Task {
  final int? id;
  final String title;
  final String? description;
  bool isCompleted;
  final bool isRepeatable;
  final DateTime createdAt;
  final int? parentId;

  Task({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.isRepeatable,
    required this.createdAt,
    this.parentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'isRepeatable': isRepeatable ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'parentId': parentId,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
      isRepeatable: map['isRepeatable'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      parentId: map['parentId'],
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    bool? isRepeatable,
    DateTime? createdAt,
    int? parentId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isRepeatable: isRepeatable ?? this.isRepeatable,
      createdAt: createdAt ?? this.createdAt,
      parentId: parentId ?? this.parentId,
    );
  }
}