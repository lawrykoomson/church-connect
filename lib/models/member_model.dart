class Member {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String department;
  final String duesStatus;
  final double amountOutstanding;
  final DateTime createdAt;
  final String uid;

  Member({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.department,
    required this.duesStatus,
    required this.amountOutstanding,
    required this.createdAt,
    required this.uid,
  });

  factory Member.fromFirestore(Map<String, dynamic> data, String id) {
    return Member(
      id: id,
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      department: data['department'] ?? '',
      duesStatus: data['duesStatus'] ?? 'Pending',
      amountOutstanding: (data['amountOutstanding'] ?? 0).toDouble(),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      uid: data['uid'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'department': department,
      'duesStatus': duesStatus,
      'amountOutstanding': amountOutstanding,
      'createdAt': createdAt.toIso8601String(),
      'uid': uid,
    };
  }
}
