import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../models/member_model.dart';
import '../../services/paystack_service.dart';
import '../../services/email_service.dart';
import '../../services/sheets_service.dart';
import '../../services/overdue_service.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Member? _member;
  List<Map<String, dynamic>> _recentPayments = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  bool _isLoading = true;
  bool _hasPendingPayment = false;
  Map<String, dynamic>? _pendingPayment;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    setState(() => _isLoading = true);
    try {
      final uid = _auth.currentUser!.uid;

      // Load member profile
      final memberDoc = await _firestore
          .collection(AppConstants.membersCollection)
          .doc(uid)
          .get();

      if (memberDoc.exists) {
        _member = Member.fromFirestore(memberDoc.data()!, memberDoc.id);
      }

      // Load recent payments
      final paymentsSnap = await _firestore
          .collection(AppConstants.paymentsCollection)
          .where('uid', isEqualTo: uid)
          .limit(5)
          .get();

      _recentPayments = paymentsSnap.docs.map((doc) => doc.data()).toList();

      // Load ALL events then filter upcoming in Dart
      final eventsSnap =
          await _firestore.collection(AppConstants.eventsCollection).get();

      _upcomingEvents = eventsSnap.docs.map((doc) => doc.data()).where((data) {
        try {
          final date = DateTime.parse(data['date'] ?? '');
          return date.isAfter(DateTime.now());
        } catch (e) {
          return false;
        }
      }).toList();

      // Sort by date ascending
      _upcomingEvents.sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateA.compareTo(dateB);
      });

      // Keep only first 3
      if (_upcomingEvents.length > 3) {
        _upcomingEvents = _upcomingEvents.sublist(0, 3);
      }

      // Check for pending payment
      final pending = await PaystackService.getPendingPayment();

      // Run overdue check if admin
      final currentUser = _auth.currentUser;
      if (currentUser?.email == AppConstants.adminEmail) {
        OverdueService.checkAndSendOverdueReminders().then((count) {
          if (count > 0 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Overdue reminders sent to $count member(s).',
                ),
                backgroundColor: AppColors.overdue,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
      }

      setState(() {
        _hasPendingPayment = pending != null;
        _pendingPayment = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyPendingPayment() async {
    if (_pendingPayment == null) return;

    final reference = _pendingPayment!['reference'] as String;
    final amount = _pendingPayment!['amount'] as double;
    final paymentType = _pendingPayment!['paymentType'] as String;
    final method = _pendingPayment!['method'] as String;

    setState(() => _isLoading = true);

    try {
      final isVerified = await PaystackService.verifyTransaction(reference);

      if (!isVerified) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Payment not verified. Please complete payment on Paystack first.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Payment verified — record in Firestore
      final uid = _auth.currentUser!.uid;

      await _firestore.collection(AppConstants.paymentsCollection).add({
        'uid': uid,
        'memberName': _member?.fullName ?? '',
        'phoneNumber': _member?.phoneNumber ?? '',
        'email': _member?.email ?? '',
        'amount': amount,
        'paymentType': paymentType,
        'paymentMethod': 'Paystack - $method',
        'paymentDate': DateTime.now().toIso8601String(),
        'reference': reference,
        'status': 'Paid',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Update dues status if Monthly Dues
      if (paymentType == 'Monthly Dues') {
        await _firestore
            .collection(AppConstants.membersCollection)
            .doc(uid)
            .update({
          'duesStatus': 'Paid',
          'amountOutstanding': 0.0,
        });
      }

      // Save to Google Sheets
      await SheetsService.addPayment(
        memberName: _member?.fullName ?? '',
        email: _member?.email ?? '',
        phone: _member?.phoneNumber ?? '',
        paymentType: paymentType,
        amount: amount,
        paymentMethod: 'Paystack - $method',
        paymentDate: DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()),
      );

      // Send email confirmation
      final emailService = EmailService();
      await emailService.sendPaymentConfirmation(
        memberName: _member?.fullName ?? '',
        email: _member?.email ?? '',
        paymentType: paymentType,
        amount: amount,
        paymentMethod: 'Paystack - $method',
        paymentDate: DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()),
        memberPhone: _member?.phoneNumber ?? '',
      );

      // Clear pending payment
      await PaystackService.clearPendingReference();

      // Reload dashboard
      await _loadMemberData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verified and recorded successfully!'),
            backgroundColor: AppColors.paid,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Color get _statusColor {
    switch (_member?.duesStatus) {
      case 'Paid':
        return AppColors.paid;
      case 'Overdue':
        return AppColors.overdue;
      default:
        return AppColors.pending;
    }
  }

  IconData get _statusIcon {
    switch (_member?.duesStatus) {
      case 'Paid':
        return Icons.check_circle;
      case 'Overdue':
        return Icons.warning_amber;
      default:
        return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.secondary,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMemberData,
              color: AppColors.secondary,
              child: CustomScrollView(
                slivers: [
                  // ── App Bar ──
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/profile',
                        ).then((_) => _loadMemberData()),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                        ),
                        onPressed: _signOut,
                      ),
                      if (_auth.currentUser?.email == AppConstants.adminEmail)
                        IconButton(
                          icon: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/admin-dashboard',
                          ),
                          tooltip: 'Admin Dashboard',
                        ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 40),
                                FadeInDown(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 45,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            (_member?.fullName ?? 'M')
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Welcome back,',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          Text(
                                            _member?.fullName ?? 'Member',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Dues Status Card
                                FadeInUp(
                                  delay: const Duration(milliseconds: 200),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _statusIcon,
                                          color: _statusColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Dues Status: ${_member?.duesStatus ?? 'Pending'}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if ((_member?.amountOutstanding ?? 0) >
                                            0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.overdue,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'GHS ${_member!.amountOutstanding.toStringAsFixed(2)} due',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Body Content ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Pending Payment Banner ──
                          if (_hasPendingPayment)
                            FadeInUp(
                              delay: const Duration(milliseconds: 100),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.secondary,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.pending_actions,
                                      color: AppColors.secondary,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Payment Pending Verification',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'GHS ${(_pendingPayment?['amount'] as double? ?? 0).toStringAsFixed(2)} — ${_pendingPayment?['paymentType'] ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: _verifyPendingPayment,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text(
                                        'Verify',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ── Quick Actions ──
                          FadeInUp(
                            delay: const Duration(milliseconds: 200),
                            child: const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Actions Grid
                          FadeInUp(
                            delay: const Duration(milliseconds: 300),
                            child: GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.0,
                              children: [
                                _ActionCard(
                                  title: 'Make Payment',
                                  icon: Icons.payment,
                                  color: AppColors.secondary,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/payment',
                                  ).then((_) => _loadMemberData()),
                                ),
                                _ActionCard(
                                  title: 'History',
                                  icon: Icons.history,
                                  color: AppColors.primary,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/payment-history',
                                  ),
                                ),
                                _ActionCard(
                                  title: 'Events',
                                  icon: Icons.event,
                                  color: const Color(0xFF8E44AD),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/events',
                                  ).then((_) => _loadMemberData()),
                                ),
                                _ActionCard(
                                  title: 'Giving',
                                  icon: Icons.bar_chart,
                                  color: const Color(0xFF16A085),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/giving-summary',
                                  ),
                                ),
                                _ActionCard(
                                  title: 'ID Card',
                                  icon: Icons.badge,
                                  color: const Color(0xFF2980B9),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/id-card',
                                  ),
                                ),
                                _ActionCard(
                                  title: 'Profile',
                                  icon: Icons.person_outline,
                                  color: const Color(0xFFE67E22),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/profile',
                                  ).then((_) => _loadMemberData()),
                                ),
                                _ActionCard(
                                  title: 'Announcements',
                                  icon: Icons.campaign,
                                  color: const Color(0xFF6A0DAD),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/announcements',
                                  ),
                                ),
                                _ActionCard(
                                  title: 'Prayer',
                                  icon: Icons.volunteer_activism,
                                  color: const Color(0xFF27AE60),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/prayer',
                                  ),
                                ),
                                _ActionCard(
                                  title: 'Directory',
                                  icon: Icons.people,
                                  color: const Color(0xFF2980B9),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/directory',
                                  ),
                                ),
                                _ActionCard(
                                  title: 'Attendance',
                                  icon: Icons.how_to_reg,
                                  color: const Color(0xFF16A085),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/attendance',
                                  ),
                                ),
                                _ActionCard(
                                  title: 'Certificate',
                                  icon: Icons.workspace_premium,
                                  color: Colors.amber,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/certificate',
                                  ),
                                ),
                                _ActionCard(
                                  title: 'Bulletin',
                                  icon: Icons.menu_book,
                                  color: const Color(0xFF8E44AD),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/bulletin',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Recent Payments ──
                          FadeInUp(
                            delay: const Duration(milliseconds: 400),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Payments',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/payment-history',
                                  ),
                                  child: const Text(
                                    'See all',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInUp(
                            delay: const Duration(milliseconds: 500),
                            child: _recentPayments.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'No payments yet. Make your first payment!',
                                        style: TextStyle(
                                          color: AppColors.textGrey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: _recentPayments
                                        .map((payment) => _PaymentTile(
                                              payment: payment,
                                            ))
                                        .toList(),
                                  ),
                          ),
                          const SizedBox(height: 24),

                          // ── Upcoming Events ──
                          FadeInUp(
                            delay: const Duration(milliseconds: 600),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Upcoming Events',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/events',
                                  ).then((_) => _loadMemberData()),
                                  child: const Text(
                                    'See all',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInUp(
                            delay: const Duration(milliseconds: 700),
                            child: _upcomingEvents.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'No upcoming events. Check back later!',
                                        style: TextStyle(
                                          color: AppColors.textGrey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: _upcomingEvents
                                        .map((event) => _EventTile(
                                              event: event,
                                            ))
                                        .toList(),
                                  ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ══════════════════════════════════════════════
// ACTION CARD
// ══════════════════════════════════════════════
class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// PAYMENT TILE
// ══════════════════════════════════════════════
class _PaymentTile extends StatelessWidget {
  final Map<String, dynamic> payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final amount = (payment['amount'] ?? 0).toDouble();
    final type = payment['paymentType'] ?? 'Payment';
    final date = payment['paymentDate'] != null
        ? DateTime.parse(payment['paymentDate'])
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.paid.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.paid,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'GHS ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.paid,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// EVENT TILE
// ══════════════════════════════════════════════
class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final date =
        event['date'] != null ? DateTime.parse(event['date']) : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(date),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                if ((event['location'] ?? '').isNotEmpty)
                  Text(
                    event['location'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            DateFormat('h:mm a').format(date),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
