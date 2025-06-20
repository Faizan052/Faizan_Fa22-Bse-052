class Department {
  final String id;
  final String name;
  final String hodId;

  Department({
    required this.id,
    required this.name,
    required this.hodId,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
      hodId: json['hod_id'],
    );
  }
}