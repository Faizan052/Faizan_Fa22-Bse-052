class Department {
  final String id;
  final String name;
  final String hodId;

  Department({required this.id, required this.name, required this.hodId});

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'],
      name: map['name'],
      hodId: map['hod_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hod_id': hodId,
    };
  }

  // TODO: Add methods to assign HOD, list department users, and format department info if needed.
}
