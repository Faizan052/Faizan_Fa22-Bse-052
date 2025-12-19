class Batch {
  final String id;
  final String name;
  final String departmentId;
  final String advisorId;

  Batch({required this.id, required this.name, required this.departmentId, required this.advisorId});

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'],
      name: map['name'],
      departmentId: map['department_id'],
      advisorId: map['advisor_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'department_id': departmentId,
      'advisor_id': advisorId,
    };
  }

  // TODO: Add methods to assign advisor, list batch students, and format batch info if needed.
}
