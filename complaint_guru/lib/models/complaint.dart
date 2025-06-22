class Complaint {
  final String? id;
  final String title;
  final String description;
  final String imageUrl;
  final String videoUrl;
  final String studentId;
  final String batchId;
  final String advisorId;
  final String? hodId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Complaint({ this.id, required this.title, required this.description, required this.imageUrl, required this.videoUrl, required this.studentId, required this.batchId, required this.advisorId, this.hodId, required this.status, required this.createdAt, required this.updatedAt });

  factory Complaint.fromMap(Map<String, dynamic> m) => Complaint(
    id: m['id'],
    title: m['title'],
    description: m['description'],
    imageUrl: m['image_url'],
    videoUrl: m['video_url'],
    studentId: m['student_id'],
    batchId: m['batch_id'],
    advisorId: m['advisor_id'],
    hodId: m['hod_id'],
    status: m['status'],
    createdAt: DateTime.parse(m['created_at']),
    updatedAt: DateTime.parse(m['updated_at']),
  );

  Map<String, dynamic> toMap() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'video_url': videoUrl,
      if (studentId.isNotEmpty) 'student_id': studentId else 'student_id': null,
      if (batchId.isNotEmpty) 'batch_id': batchId else 'batch_id': null,
      if (advisorId.isNotEmpty) 'advisor_id': advisorId else 'advisor_id': null,
      if (hodId != null && hodId!.isNotEmpty) 'hod_id': hodId else 'hod_id': null,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // TODO: Add methods to check complaint status, validate URLs, and fetch timeline/history.
}
