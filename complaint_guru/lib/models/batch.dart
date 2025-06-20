class Batch {
  final String id;
  final String name;
  final String departmentId;
  final String advisorId;

  Batch({
    required this.id,
    required this.name,
    required this.departmentId,
    required this.advisorId,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'],
      name: json['name'],
      departmentId: json['department_id'],
      advisorId: json['advisor_id'],
    );
  }
}