import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../utils/app_constants.dart';

class PaymentService {
  final _firestore = FirebaseFirestore.instance;

  // Get all payments as stream
  Stream<List<Payment>> getPayments() {
    return _firestore
        .collection(AppConstants.paymentsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Payment.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Record a new payment and update member status
  Future<void> recordPayment(Payment payment) async {
    // Add payment record
    await _firestore
        .collection(AppConstants.paymentsCollection)
        .add(payment.toFirestore());

    // Update member dues status to Paid
    if (payment.memberId.isNotEmpty) {
      await _firestore
          .collection(AppConstants.membersCollection)
          .doc(payment.memberId)
          .update({
        'duesStatus': AppConstants.statusPaid,
        'lastPaymentDate': payment.paymentDate.toIso8601String(),
        'lastPaymentAmount': payment.amount,
        'amountOutstanding': 0,
      });
    }
  }

  // Get payments for a specific member
  Stream<List<Payment>> getMemberPayments(String memberId) {
    return _firestore
        .collection(AppConstants.paymentsCollection)
        .where('memberId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Payment.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Get total amount collected
  Future<double> getTotalCollected() async {
    final snap =
        await _firestore.collection(AppConstants.paymentsCollection).get();
    double total = 0;
    for (var doc in snap.docs) {
      total += (doc.data()['amount'] ?? 0).toDouble();
    }
    return total;
  }
}
