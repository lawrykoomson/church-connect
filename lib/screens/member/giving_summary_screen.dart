import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';

class GivingSummaryScreen extends StatefulWidget {
  const GivingSummaryScreen({super.key});

  @override
  State<GivingSummaryScreen> createState() => _GivingSummaryScreenState();
}

class _GivingSummaryScreenState extends State<GivingSummaryScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;

  // Summary totals
  double _totalDues = 0;
  double _totalTithe = 0;
  double _totalOffering = 0;
  double _totalBuilding = 0;
  double _totalWelfare = 0;
  double _totalOther = 0;
  double _grandTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadGivingSummary();
  }

  Future<void> _loadGivingSummary() async {
    setState(() => _isLoading = true);
    try {
      final uid = _auth.currentUser!.uid;
      final snap = await _firestore
          .collection(AppConstants.paymentsCollection)
          .where('uid', isEqualTo: uid)
          .get();

      final allPayments = snap.docs.map((doc) => doc.data()).toList();

      // Filter by selected year
      final payments = allPayments.where((p) {
        final date = DateTime.parse(p['paymentDate']);
        return date.year == _selectedYear;
      }).toList();

      // Sort by date
      payments.sort((a, b) {
        final dateA = DateTime.parse(a['paymentDate']);
        final dateB = DateTime.parse(b['paymentDate']);
        return dateB.compareTo(dateA);
      });

      // Calculate totals
      double dues = 0;
      double tithe = 0;
      double offering = 0;
      double building = 0;
      double welfare = 0;
      double other = 0;

      for (final p in payments) {
        final amount = (p['amount'] ?? 0).toDouble();
        final type = p['paymentType'] ?? '';

        switch (type) {
          case 'Monthly Dues':
            dues += amount;
            break;
          case 'Tithe':
            tithe += amount;
            break;
          case 'Offering':
            offering += amount;
            break;
          case 'Building Fund':
            building += amount;
            break;
          case 'Welfare':
            welfare += amount;
            break;
          default:
            other += amount;
            break;
        }
      }

      setState(() {
        _payments = payments;
        _totalDues = dues;
        _totalTithe = tithe;
        _totalOffering = offering;
        _totalBuilding = building;
        _totalWelfare = welfare;
        _totalOther = other;
        _grandTotal = dues + tithe + offering + building + welfare + other;
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
          'Giving Summary',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Year selector
          DropdownButton<int>(
            value: _selectedYear,
            dropdownColor: AppColors.primary,
            iconEnabledColor: Colors.white,
            underline: const SizedBox(),
            items: [
              DateTime.now().year,
              DateTime.now().year - 1,
              DateTime.now().year - 2,
            ]
                .map((year) => DropdownMenuItem(
                      value: year,
                      child: Text(
                        '$year',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (year) {
              setState(() => _selectedYear = year!);
              _loadGivingSummary();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.secondary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Grand Total Banner ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Giving',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'GHS ${_grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Year $_selectedYear',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_payments.length} transaction${_payments.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Breakdown by Category ──
                  const Text(
                    'Breakdown by Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
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
                      children: [
                        _CategoryRow(
                          label: 'Monthly Dues',
                          amount: _totalDues,
                          total: _grandTotal,
                          color: AppColors.primary,
                          icon: Icons.calendar_month,
                        ),
                        const Divider(height: 20),
                        _CategoryRow(
                          label: 'Tithe',
                          amount: _totalTithe,
                          total: _grandTotal,
                          color: AppColors.secondary,
                          icon: Icons.volunteer_activism,
                        ),
                        const Divider(height: 20),
                        _CategoryRow(
                          label: 'Offering',
                          amount: _totalOffering,
                          total: _grandTotal,
                          color: const Color(0xFF8E44AD),
                          icon: Icons.favorite_outline,
                        ),
                        const Divider(height: 20),
                        _CategoryRow(
                          label: 'Building Fund',
                          amount: _totalBuilding,
                          total: _grandTotal,
                          color: const Color(0xFF2980B9),
                          icon: Icons.home_work_outlined,
                        ),
                        const Divider(height: 20),
                        _CategoryRow(
                          label: 'Welfare',
                          amount: _totalWelfare,
                          total: _grandTotal,
                          color: AppColors.paid,
                          icon: Icons.people_outline,
                        ),
                        if (_totalOther > 0) ...[
                          const Divider(height: 20),
                          _CategoryRow(
                            label: 'Other',
                            amount: _totalOther,
                            total: _grandTotal,
                            color: AppColors.textGrey,
                            icon: Icons.more_horiz,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Monthly Breakdown ──
                  const Text(
                    'Monthly Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMonthlyBreakdown(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthlyBreakdown() {
    // Group payments by month
    Map<String, double> monthlyTotals = {};

    for (final p in _payments) {
      final date = DateTime.parse(p['paymentDate']);
      final month = DateFormat('MMM yyyy').format(date);
      final amount = (p['amount'] ?? 0).toDouble();
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + amount;
    }

    if (monthlyTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            'No payments for this year.',
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: monthlyTotals.entries.map((entry) {
          final percent = _grandTotal > 0 ? entry.value / _grandTotal : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'GHS ${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
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
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.secondary,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// CATEGORY ROW WIDGET
// ══════════════════════════════════════════════
class _CategoryRow extends StatelessWidget {
  final String label;
  final double amount;
  final double total;
  final Color color;
  final IconData icon;

  const _CategoryRow({
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? amount / total : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'GHS ${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
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
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
