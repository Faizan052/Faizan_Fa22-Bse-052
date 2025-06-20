class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? batchId;
  final String? departmentId;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.batchId,
    this.departmentId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      batchId: json['batch_id'],
      departmentId: json['department_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role,
    if (batchId != null) 'batch_id': batchId,
    if (departmentId != null) 'department_id': departmentId,
  };
}

class Complaint {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? videoUrl;
  final String studentId;
  final String batchId;
  final String advisorId;
  final String? hodId;
  final String status;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.videoUrl,
    required this.studentId,
    required this.batchId,
    required this.advisorId,
    this.hodId,
    required this.status,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      studentId: json['student_id'] ?? '',
      batchId: json['batch_id'] ?? '',
      advisorId: json['advisor_id'] ?? '',
      hodId: json['hod_id'],
      status: json['status'] ?? 'Pending',
    );
  }
}

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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      hodId: json['hod_id'] ?? '',
    );
  }
}

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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      departmentId: json['department_id'] ?? '',
      advisorId: json['advisor_id'] ?? '',
    );
  }
}