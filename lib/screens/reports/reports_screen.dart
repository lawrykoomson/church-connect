import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _firestore = FirebaseFirestore.instance;

  // Members stats
  int _totalMembers = 0;
  int _paidMembers = 0;
  int _overdueMembers = 0;
  int _pendingMembers = 0;

  // Department breakdown
  Map<String, int> _departmentCounts = {};

  // Payment stats
  double _totalCollected = 0;
  double _monthlyCollected = 0;
  int _totalPayments = 0;
  Map<String, double> _paymentTypeBreakdown = {};

  // Events stats
  int _totalEvents = 0;
  int _upcomingEvents = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      // Load members
      final membersSnap =
          await _firestore.collection(AppConstants.membersCollection).get();

      int paid = 0, overdue = 0, pending = 0;
      Map<String, int> deptCounts = {};

      for (var doc in membersSnap.docs) {
        final data = doc.data();
        final status = data['duesStatus'] ?? '';
        final dept = data['department'] ?? 'General';

        if (status == AppConstants.statusPaid) paid++;
        if (status == AppConstants.statusOverdue) overdue++;
        if (status == AppConstants.statusPending) pending++;

        deptCounts[dept] = (deptCounts[dept] ?? 0) + 1;
      }

      // Load payments
      final paymentsSnap =
          await _firestore.collection(AppConstants.paymentsCollection).get();

      double total = 0;
      double monthly = 0;
      Map<String, double> typeBreakdown = {};
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);

      for (var doc in paymentsSnap.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final type = data['paymentType'] ?? 'Other';
        final date = data['paymentDate'] != null
            ? DateTime.parse(data['paymentDate'])
            : DateTime.now();

        total += amount;
        typeBreakdown[type] = (typeBreakdown[type] ?? 0) + amount;

        if (date.isAfter(thisMonth)) monthly += amount;
      }

      // Load events
      final eventsSnap =
          await _firestore.collection(AppConstants.eventsCollection).get();

      int upcoming = 0;
      for (var doc in eventsSnap.docs) {
        final date = doc.data()['date'] != null
            ? DateTime.parse(doc.data()['date'])
            : DateTime.now();
        if (date.isAfter(DateTime.now())) upcoming++;
      }

      setState(() {
        _totalMembers = membersSnap.docs.length;
        _paidMembers = paid;
        _overdueMembers = overdue;
        _pendingMembers = pending;
        _departmentCounts = deptCounts;
        _totalCollected = total;
        _monthlyCollected = monthly;
        _totalPayments = paymentsSnap.docs.length;
        _paymentTypeBreakdown = typeBreakdown;
        _totalEvents = eventsSnap.docs.length;
        _upcomingEvents = upcoming;
        _isLoading = false;
      });
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
          'Reports & Analytics',
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
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.secondary,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadReports,
              color: AppColors.secondary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Financial Summary ──
                    _sectionTitle('Financial Summary'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Collected',
                            value: 'GHS ${_totalCollected.toStringAsFixed(2)}',
                            icon: Icons.account_balance_wallet,
                            color: AppColors.paid,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'This Month',
                            value:
                                'GHS ${_monthlyCollected.toStringAsFixed(2)}',
                            icon: Icons.calendar_month,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      title: 'Total Transactions',
                      value: '$_totalPayments payments recorded',
                      icon: Icons.receipt_long,
                      color: AppColors.secondary,
                      wide: true,
                    ),
                    const SizedBox(height: 24),

                    // ── Payment Type Breakdown ──
                    _sectionTitle('Payment Type Breakdown'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: _paymentTypeBreakdown.isEmpty
                          ? const Center(
                              child: Text(
                                'No payment data yet',
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                ),
                              ),
                            )
                          : Column(
                              children: _paymentTypeBreakdown.entries
                                  .map((entry) => _BarRow(
                                        label: entry.key,
                                        amount: entry.value,
                                        total: _totalCollected,
                                        color: AppColors.secondary,
                                      ))
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // ── Member Statistics ──
                    _sectionTitle('Member Statistics'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Members',
                            value: '$_totalMembers',
                            icon: Icons.people,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Compliance Rate',
                            value: _totalMembers > 0
                                ? '${((_paidMembers / _totalMembers) * 100).toStringAsFixed(0)}%'
                                : '0%',
                            icon: Icons.pie_chart,
                            color: AppColors.paid,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Dues status breakdown
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        children: [
                          _StatusRow(
                            label: 'Paid',
                            count: _paidMembers,
                            total: _totalMembers,
                            color: AppColors.paid,
                          ),
                          const SizedBox(height: 12),
                          _StatusRow(
                            label: 'Overdue',
                            count: _overdueMembers,
                            total: _totalMembers,
                            color: AppColors.overdue,
                          ),
                          const SizedBox(height: 12),
                          _StatusRow(
                            label: 'Pending',
                            count: _pendingMembers,
                            total: _totalMembers,
                            color: AppColors.pending,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Department Breakdown ──
                    _sectionTitle('Members by Department'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: _departmentCounts.isEmpty
                          ? const Center(
                              child: Text(
                                'No department data yet',
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                ),
                              ),
                            )
                          : Column(
                              children: _departmentCounts.entries
                                  .map((entry) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                entry.key,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 5,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: _totalMembers > 0
                                                      ? entry.value /
                                                          _totalMembers
                                                      : 0,
                                                  backgroundColor:
                                                      AppColors.border,
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                    AppColors.primary,
                                                  ),
                                                  minHeight: 8,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              '${entry.value}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // ── Events Summary ──
                    _sectionTitle('Events Summary'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Events',
                            value: '$_totalEvents',
                            icon: Icons.event,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Upcoming',
                            value: '$_upcomingEvents',
                            icon: Icons.upcoming,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }
}

// ══════════════════════════════════════════════
// SUMMARY CARD
// ══════════════════════════════════════════════
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: wide ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// BAR ROW — Payment type breakdown
// ══════════════════════════════════════════════
class _BarRow extends StatelessWidget {
  final String label;
  final double amount;
  final double total;
  final Color color;

  const _BarRow({
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? amount / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'GHS ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// STATUS ROW — Dues status breakdown
// ══════════════════════════════════════════════
class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            Text(
              '$count of $total members',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
