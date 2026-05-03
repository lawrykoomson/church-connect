import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../services/pdf_service.dart';

class TitheCertificateScreen extends StatefulWidget {
  const TitheCertificateScreen({super.key});

  @override
  State<TitheCertificateScreen> createState() => _TitheCertificateScreenState();
}

class _TitheCertificateScreenState extends State<TitheCertificateScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _memberName = '';
  String _email = '';
  String _phone = '';
  String _department = '';
  String _selectedYear = DateTime.now().year.toString();
  bool _isLoading = false;

  double _totalTithe = 0;
  double _totalOffering = 0;
  double _totalDues = 0;
  double _grandTotal = 0;

  final List<String> _years = [
    '2026',
    '2025',
    '2024',
    '2023',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final uid = _auth.currentUser!.uid;

    // Load member details
    final memberDoc = await _firestore
        .collection(AppConstants.membersCollection)
        .doc(uid)
        .get();

    if (memberDoc.exists) {
      _memberName = memberDoc.data()!['fullName'] ?? '';
      _email = memberDoc.data()!['email'] ?? '';
      _phone = memberDoc.data()!['phoneNumber'] ?? '';
      _department = memberDoc.data()!['department'] ?? '';
    }

    // Load payments for selected year
    final paymentsSnap = await _firestore
        .collection(AppConstants.paymentsCollection)
        .where('uid', isEqualTo: uid)
        .get();

    double tithe = 0;
    double offering = 0;
    double dues = 0;

    for (final doc in paymentsSnap.docs) {
      final data = doc.data();
      final paymentDate = data['paymentDate'] ?? '';
      final amount = (data['amount'] ?? 0).toDouble();
      final type = data['paymentType'] ?? '';

      if (paymentDate.startsWith(_selectedYear)) {
        if (type == 'Tithe') tithe += amount;
        if (type == 'Offering') offering += amount;
        if (type == 'Monthly Dues') dues += amount;
      }
    }

    setState(() {
      _totalTithe = tithe;
      _totalOffering = offering;
      _totalDues = dues;
      _grandTotal = tithe + offering + dues;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Giving Certificate',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Certificate preview card
                  FadeInDown(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.workspace_premium,
                            color: Colors.amber,
                            size: 60,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'GIVING CERTIFICATE',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Great Mountains Of God International Ministry',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _memberName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          Text(
                            _department,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Year selector
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Select Year:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedYear,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: _years
                                  .map((y) => DropdownMenuItem(
                                        value: y,
                                        child: Text(y),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() => _selectedYear = val!);
                                _loadData();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Giving breakdown
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(20),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giving Summary — $_selectedYear',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildRow('Tithe', _totalTithe),
                          const Divider(),
                          _buildRow('Offering', _totalOffering),
                          const Divider(),
                          _buildRow('Monthly Dues', _totalDues),
                          const Divider(thickness: 2),
                          _buildRow(
                            'Grand Total',
                            _grandTotal,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Download button
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _grandTotal == 0
                            ? null
                            : () async {
                                await PdfService.generateTitheCertificate(
                                  memberName: _memberName,
                                  email: _email,
                                  phone: _phone,
                                  department: _department,
                                  totalTithe: _totalTithe,
                                  totalOffering: _totalOffering,
                                  totalDues: _totalDues,
                                  grandTotal: _grandTotal,
                                  year: _selectedYear,
                                  certificateNumber:
                                      'GMOGIM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.download),
                        label: Text(
                          _grandTotal == 0
                              ? 'No giving records for $_selectedYear'
                              : 'Download Giving Certificate',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildRow(
    String label,
    double amount, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.primary : AppColors.textGrey,
            ),
          ),
          Text(
            'GHS ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.primary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
