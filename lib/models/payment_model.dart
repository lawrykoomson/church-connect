class Payment {
  final String id;
  final String memberId;
  final String memberName;
  final String phoneNumber;
  final double amount;
  final String paymentType;
  final DateTime paymentDate;
  final String recordedBy;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.phoneNumber,
    required this.amount,
    required this.paymentType,
    required this.paymentDate,
    required this.recordedBy,
    required this.createdAt,
  });

  factory Payment.fromFirestore(Map<String, dynamic> data, String id) {
    return Payment(
      id: id,
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentType: data['paymentType'] ?? 'Monthly Dues',
      paymentDate: data['paymentDate'] != null
          ? DateTime.parse(data['paymentDate'])
          : DateTime.now(),
      recordedBy: data['recordedBy'] ?? 'Admin',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'paymentType': paymentType,
      'paymentDate': paymentDate.toIso8601String(),
      'recordedBy': recordedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
