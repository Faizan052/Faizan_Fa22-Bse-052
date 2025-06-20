class User {
  final String id;
  final String email;
  final String role;
  final String name;
  final String? batchId;
  final String? departmentId;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.batchId,
    this.departmentId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      name: json['name'],
      batchId: json['batch_id'],
      departmentId: json['department_id'],
    );
  }
}