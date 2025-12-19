class UserModel {
  final String id, email, name, role;
  final String batchId, departmentId;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    required this.batchId,
    required this.departmentId,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id: m['id'] ?? '',
        email: m['email'] ?? '',
        name: m['name'] ?? '',
        role: m['role'] ?? '',
        batchId: m['batch_id'] ?? '',
        departmentId: m['department_id'] ?? '',
        createdAt: m['created_at'] != null ? DateTime.parse(m['created_at']) : DateTime.now(),
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'batch_id': batchId,
      'department_id': departmentId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // TODO: Add methods to check user role (isStudent, isAdvisor, etc.)
  // TODO: Add methods for display name formatting
  // TODO: Add methods to update user info
}
