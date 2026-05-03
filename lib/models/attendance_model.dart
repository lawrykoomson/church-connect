class AttendanceRecord {
  final String id;
  final String serviceTitle;
  final String serviceDate;
  final String serviceType;
  final List<String> presentMembers;
  final String markedBy;
  final DateTime createdAt;

  AttendanceRecord({
    required this.id,
    required this.serviceTitle,
    required this.serviceDate,
    required this.serviceType,
    required this.presentMembers,
    required this.markedBy,
    required this.createdAt,
  });

  factory AttendanceRecord.fromFirestore(Map<String, dynamic> data, String id) {
    return AttendanceRecord(
      id: id,
      serviceTitle: data['serviceTitle'] ?? '',
      serviceDate: data['serviceDate'] ?? '',
      serviceType: data['serviceType'] ?? 'Sunday Service',
      presentMembers: List<String>.from(data['presentMembers'] ?? []),
      markedBy: data['markedBy'] ?? '',
      createdAt:
          DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceTitle': serviceTitle,
      'serviceDate': serviceDate,
      'serviceType': serviceType,
      'presentMembers': presentMembers,
      'markedBy': markedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
