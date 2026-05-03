import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  int _totalMembers = 0;
  int _paidMembers = 0;
  int _overdueMembers = 0;
  int _pendingMembers = 0;
  double _totalRevenue = 0;
  int _totalPayments = 0;
  int _totalEvents = 0;
  int _totalPrayers = 0;
  bool _isLoading = true;

  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _allPayments = [];
  List<Map<String, dynamic>> _recentPrayers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      // Load members
      final membersSnap =
          await _firestore.collection(AppConstants.membersCollection).get();
      _allMembers =
          membersSnap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      _totalMembers = _allMembers.length;
      _paidMembers = _allMembers.where((m) => m['duesStatus'] == 'Paid').length;
      _overdueMembers =
          _allMembers.where((m) => m['duesStatus'] == 'Overdue').length;
      _pendingMembers =
          _allMembers.where((m) => m['duesStatus'] == 'Pending').length;

      // Load payments
      final paymentsSnap =
          await _firestore.collection(AppConstants.paymentsCollection).get();
      _allPayments = paymentsSnap.docs.map((d) => d.data()).toList();
      _totalPayments = _allPayments.length;
      _totalRevenue = _allPayments.fold(
        0,
        (sum, p) => sum + (p['amount'] ?? 0).toDouble(),
      );

      // Load events
      final eventsSnap =
          await _firestore.collection(AppConstants.eventsCollection).get();
      _totalEvents = eventsSnap.docs.length;

      // Load prayers
      final prayersSnap = await _firestore
          .collection('prayers')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      _recentPrayers = prayersSnap.docs.map((d) => d.data()).toList();
      _totalPrayers = prayersSnap.docs.length;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStats,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Members'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(
                  totalMembers: _totalMembers,
                  paidMembers: _paidMembers,
                  overdueMembers: _overdueMembers,
                  pendingMembers: _pendingMembers,
                  totalRevenue: _totalRevenue,
                  totalPayments: _totalPayments,
                  totalEvents: _totalEvents,
                  totalPrayers: _totalPrayers,
                  recentPrayers: _recentPrayers,
                ),
                _MembersTab(members: _allMembers),
                _PaymentsTab(payments: _allPayments),
              ],
            ),
    );
  }
}

// ── Overview Tab ──
class _OverviewTab extends StatelessWidget {
  final int totalMembers;
  final int paidMembers;
  final int overdueMembers;
  final int pendingMembers;
  final double totalRevenue;
  final int totalPayments;
  final int totalEvents;
  final int totalPrayers;
  final List<Map<String, dynamic>> recentPrayers;

  const _OverviewTab({
    required this.totalMembers,
    required this.paidMembers,
    required this.overdueMembers,
    required this.pendingMembers,
    required this.totalRevenue,
    required this.totalPayments,
    required this.totalEvents,
    required this.totalPrayers,
    required this.recentPrayers,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats grid
          FadeInDown(
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  title: 'Total Members',
                  value: '$totalMembers',
                  icon: Icons.people,
                  color: AppColors.primary,
                ),
                _StatCard(
                  title: 'Total Revenue',
                  value: 'GHS ${totalRevenue.toStringAsFixed(2)}',
                  icon: Icons.account_balance_wallet,
                  color: AppColors.paid,
                ),
                _StatCard(
                  title: 'Paid Members',
                  value: '$paidMembers',
                  icon: Icons.check_circle,
                  color: AppColors.paid,
                ),
                _StatCard(
                  title: 'Overdue Members',
                  value: '$overdueMembers',
                  icon: Icons.warning_amber,
                  color: AppColors.overdue,
                ),
                _StatCard(
                  title: 'Total Payments',
                  value: '$totalPayments',
                  icon: Icons.payment,
                  color: const Color(0xFF2980B9),
                ),
                _StatCard(
                  title: 'Total Events',
                  value: '$totalEvents',
                  icon: Icons.event,
                  color: const Color(0xFF8E44AD),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dues status breakdown
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dues Status Breakdown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatusBar(
                    label: 'Paid',
                    count: paidMembers,
                    total: totalMembers,
                    color: AppColors.paid,
                  ),
                  const SizedBox(height: 8),
                  _StatusBar(
                    label: 'Pending',
                    count: pendingMembers,
                    total: totalMembers,
                    color: AppColors.pending,
                  ),
                  const SizedBox(height: 8),
                  _StatusBar(
                    label: 'Overdue',
                    count: overdueMembers,
                    total: totalMembers,
                    color: AppColors.overdue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recent prayer requests
          if (recentPrayers.isNotEmpty) ...[
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: const Text(
                'Recent Prayer Requests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...recentPrayers.take(5).map((prayer) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.volunteer_activism,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayer['memberName'] ?? 'Anonymous',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              prayer['request'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: prayer['status'] == 'Prayed'
                              ? AppColors.paid.withOpacity(0.1)
                              : AppColors.pending.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          prayer['status'] ?? 'Pending',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: prayer['status'] == 'Prayed'
                                ? AppColors.paid
                                : AppColors.pending,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ── Members Tab ──
class _MembersTab extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  const _MembersTab({required this.members});

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Paid', 'Pending', 'Overdue'];
    var filtered = widget.members;
    if (_filter != 'All') {
      filtered =
          widget.members.where((m) => m['duesStatus'] == _filter).toList();
    }

    return Column(
      children: [
        // Filter tabs
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: filters.map((f) {
              final isSelected = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Members list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final member = filtered[index];
              final status = member['duesStatus'] ?? 'Pending';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (member['fullName'] ?? 'M')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['fullName'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '${member['department'] ?? ''} • ${member['phoneNumber'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'Paid'
                            ? AppColors.paid.withOpacity(0.1)
                            : status == 'Overdue'
                                ? AppColors.overdue.withOpacity(0.1)
                                : AppColors.pending.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: status == 'Paid'
                              ? AppColors.paid
                              : status == 'Overdue'
                                  ? AppColors.overdue
                                  : AppColors.pending,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Payments Tab ──
class _PaymentsTab extends StatelessWidget {
  final List<Map<String, dynamic>> payments;
  const _PaymentsTab({required this.payments});

  @override
  Widget build(BuildContext context) {
    final sorted = [...payments]..sort((a, b) {
        final dateA = a['paymentDate'] ?? '';
        final dateB = b['paymentDate'] ?? '';
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final payment = sorted[index];
        final amount = (payment['amount'] ?? 0).toDouble();
        final date = payment['paymentDate'] != null
            ? DateTime.parse(payment['paymentDate'])
            : DateTime.now();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                      payment['memberName'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${payment['paymentType'] ?? ''} • ${DateFormat('dd MMM yyyy').format(date)}',
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
                  fontSize: 14,
                  color: AppColors.paid,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Stat Card Widget ──
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Bar Widget ──
class _StatusBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
