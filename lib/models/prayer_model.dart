class PrayerRequest {
  final String   id;
  final String   memberName;
  final String   memberEmail;
  final String   request;
  final String   category;
  final String   status;
  final DateTime createdAt;
  final bool     isAnonymous;

  PrayerRequest({
    required this.id,
    required this.memberName,
    required this.memberEmail,
    required this.request,
    required this.category,
    required this.status,
    required this.createdAt,
    this.isAnonymous = false,
  });

  factory PrayerRequest.fromFirestore(
      Map<String, dynamic> data, String id) {
    return PrayerRequest(
      id:          id,
      memberName:  data['memberName']  ?? '',
      memberEmail: data['memberEmail'] ?? '',
      request:     data['request']     ?? '',
      category:    data['category']    ?? 'General',
      status:      data['status']      ?? 'Pending',
      createdAt:   DateTime.parse(
          data['createdAt'] ?? DateTime.now().toIso8601String()),
      isAnonymous: data['isAnonymous'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberName':  memberName,
      'memberEmail': memberEmail,
      'request':     request,
      'category':    category,
      'status':      status,
      'createdAt':   createdAt.toIso8601String(),
      'isAnonymous': isAnonymous,
    };
  }
}