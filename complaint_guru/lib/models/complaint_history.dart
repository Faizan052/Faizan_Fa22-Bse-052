class ComplaintHistory {
  final String id;
  final String complaintId;
  final String action;
  final String comment;
  final String userId;
  final DateTime createdAt;

  ComplaintHistory({
    required this.id,
    required this.complaintId,
    required this.action,
    required this.comment,
    required this.userId,
    required this.createdAt,
  });

  factory ComplaintHistory.fromMap(Map<String, dynamic> map) {
    return ComplaintHistory(
      id: map['id'],
      complaintId: map['complaint_id'],
      action: map['action'],
      comment: map['comment'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'action': action,
      'comment': comment,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // TODO: Add methods to fetch user name/role for each history entry and format action display.
  // TODO: Integrate with timeline feature if needed.
}
