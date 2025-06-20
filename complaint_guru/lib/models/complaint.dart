class Complaint {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? videoUrl;
  final String studentId;
  final String batchId;
  final String? advisorId;
  final String? hodId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.videoUrl,
    required this.studentId,
    required this.batchId,
    this.advisorId,
    this.hodId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      studentId: json['student_id'],
      batchId: json['batch_id'],
      advisorId: json['advisor_id'],
      hodId: json['hod_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}