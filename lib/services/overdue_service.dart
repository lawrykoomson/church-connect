import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sheets_service.dart';
import 'email_service.dart';

class OverdueService {
  static final _firestore = FirebaseFirestore.instance;
  static const _adminEmail = 'greatmountainsofgod@gmail.com';

  static Future<int> checkAndSendOverdueReminders() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Only run for admin
    if (currentUser?.email != _adminEmail) return 0;

    try {
      final now = DateTime.now();
      final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final lastUpdated = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      print('Current month: $thisMonth');

      // ── Check Firestore if already ran this month ──
      final settingsDoc =
          await _firestore.collection('settings').doc('overdue_check').get();

      if (settingsDoc.exists) {
        final lastRanMonth =
            settingsDoc.data()?['lastRanMonth']?.toString().trim() ?? '';
        print('Last ran month from Firestore: "$lastRanMonth"');
        print('This month: "$thisMonth"');
        print('Are they equal: ${lastRanMonth == thisMonth}');

        if (lastRanMonth == thisMonth) {
          print('Overdue check already ran this month. Skipping.');
          return 0;
        }
      } else {
        print('Settings document does not exist yet.');
      }

      int count = 0;

      // Get all members
      final membersSnap = await _firestore.collection('members').get();

      for (final doc in membersSnap.docs) {
        final data = doc.data();
        final fullName = data['fullName'] ?? '';
        final email = data['email'] ?? '';
        final phone = data['phoneNumber'] ?? '';
        final status = data['duesStatus'] ?? 'Pending';
        final outstanding = (data['amountOutstanding'] ?? 50.0).toDouble();

        // Skip paid members and admin
        if (status == 'Paid') continue;
        if (email == _adminEmail) continue;

        // Check if member has paid Monthly Dues this month
        final paymentsSnap = await _firestore
            .collection('payments')
            .where('uid', isEqualTo: doc.id)
            .where('paymentType', isEqualTo: 'Monthly Dues')
            .get();

        bool paidThisMonth = false;
        for (final payment in paymentsSnap.docs) {
          final paymentDate = payment.data()['paymentDate'] ?? '';
          if (paymentDate.startsWith(thisMonth)) {
            paidThisMonth = true;
            break;
          }
        }

        // Only process members who have NOT paid this month
        if (!paidThisMonth) {
          // Send overdue reminder email
          await EmailService.sendOverdueReminder(
            memberName: fullName,
            email: email,
            amountOutstanding: outstanding,
          );

          // Add to overdue Google Sheet
          await SheetsService.addOverdueMember(
            fullName: fullName,
            email: email,
            phone: phone,
            amountOutstanding: outstanding,
            lastUpdated: lastUpdated,
          );

          // Update Firestore status to Overdue
          await _firestore
              .collection('members')
              .doc(doc.id)
              .update({'duesStatus': 'Overdue'});

          count++;
          print('Overdue reminder sent to: $fullName');

          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // ── Save this month to Firestore ──
      await _firestore.collection('settings').doc('overdue_check').set({
        'lastRanMonth': thisMonth,
        'lastRanDate': lastUpdated,
        'count': count,
      });

      print('Total overdue reminders sent: $count');
      return count;
    } catch (e) {
      print('Overdue check error: $e');
      return 0;
    }
  }
}
