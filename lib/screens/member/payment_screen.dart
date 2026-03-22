import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../services/paystack_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _amountController = TextEditingController();

  String _selectedPaymentType = 'Monthly Dues';
  String _selectedPaymentMethod = 'Mobile Money';
  bool _isLoading = false;
  String _memberName = '';
  String _memberEmail = '';
  String _memberPhone = '';
  String _duesStatus = 'Pending';

  final List<Map<String, dynamic>> _paymentTypes = [
    {
      'name': 'Monthly Dues',
      'icon': Icons.calendar_month,
      'color': AppColors.primary
    },
    {
      'name': 'Tithe',
      'icon': Icons.volunteer_activism,
      'color': const Color(0xFF8E44AD)
    },
    {
      'name': 'Offering',
      'icon': Icons.favorite_outline,
      'color': AppColors.secondary
    },
    {
      'name': 'Building Fund',
      'icon': Icons.home_work_outlined,
      'color': const Color(0xFF2980B9)
    },
    {'name': 'Welfare', 'icon': Icons.people_outline, 'color': AppColors.paid},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': AppColors.textGrey},
  ];

  final List<String> _paymentMethods = [
    'Mobile Money',
    'Bank Transfer',
  ];

  final Map<String, Map<String, String>> _momoDetails = {
    'MTN Mobile Money': {
      'number': '059 000 0000',
      'name': 'ChurchConnect',
    },
    'Vodafone Cash': {
      'number': '050 000 0000',
      'name': 'ChurchConnect',
    },
    'AirtelTigo Money': {
      'number': '057 000 0000',
      'name': 'ChurchConnect',
    },
  };

  final Map<String, String> _bankDetails = {
    'Bank Name': 'GCB Bank',
    'Account Name': 'ChurchConnect',
    'Account Number': '1234567890',
    'Branch': 'Cape Coast Main',
    'Sort Code': '030100',
  };

  String _selectedMomo = 'MTN Mobile Money';

  @override
  void initState() {
    super.initState();
    _loadMemberDetails();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberDetails() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore
        .collection(AppConstants.membersCollection)
        .doc(uid)
        .get();
    if (doc.exists) {
      setState(() {
        _memberName = doc.data()!['fullName'] ?? '';
        _memberEmail = doc.data()!['email'] ?? '';
        _memberPhone = doc.data()!['phoneNumber'] ?? '';
        _duesStatus = doc.data()!['duesStatus'] ?? 'Pending';
      });
    }
  }

  Future<void> _confirmPayment() async {
    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _confirmRow('Type', _selectedPaymentType),
            _confirmRow('Amount', 'GHS ${amount.toStringAsFixed(2)}'),
            _confirmRow('Method', _selectedPaymentMethod),
            if (_selectedPaymentMethod == 'Mobile Money')
              _confirmRow('Network', _selectedMomo),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final reference = PaystackService.generateReference();

      final transaction = await PaystackService.initializeTransaction(
        email: _memberEmail,
        amount: amount,
        reference: reference,
        metadata: {
          'memberName': _memberName,
          'paymentType': _selectedPaymentType,
          'paymentMethod': _selectedPaymentMethod,
          'phone': _memberPhone,
        },
      );

      setState(() => _isLoading = false);

      if (transaction == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not initialize payment. Please try again.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Save pending payment reference
      await PaystackService.savePendingReference(
        reference: reference,
        amount: amount,
        paymentType: _selectedPaymentType,
        paymentMethod: _selectedPaymentMethod +
            (_selectedPaymentMethod == 'Mobile Money'
                ? ' ($_selectedMomo)'
                : ''),
      );

      // Open Paystack checkout
      final authUrl = transaction['authorization_url'];
      await PaystackService.openCheckout(authUrl);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Complete payment on Paystack then tap Verify Payment on dashboard.',
            ),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 5),
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

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Make Payment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dues Reminder Banner ──
            if (_duesStatus != 'Paid' && _selectedPaymentType != 'Monthly Dues')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.overdue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.overdue,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.overdue,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Dues Pending',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.overdue,
                              fontSize: 13,
                            ),
                          ),
                          const Text(
                            'Please remember to pay your Monthly Dues.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(
                        () => _selectedPaymentType = 'Monthly Dues',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.overdue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Pay Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Payment Type ──
            const Text(
              'Select Payment Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: _paymentTypes.map((type) {
                final isSelected = _selectedPaymentType == type['name'];
                final color = type['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(
                    () => _selectedPaymentType = type['name'] as String,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? color : AppColors.border,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                              ),
                            ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          color: isSelected ? Colors.white : color,
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          type['name'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Amount ──
            const Text(
              'Enter Amount (GHS)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                  prefixIcon: const Icon(
                    Icons.attach_money,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.secondary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 24),

            // ── Payment Method ──
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _paymentMethods.map((method) {
                final isSelected = _selectedPaymentMethod == method;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                      () => _selectedPaymentMethod = method,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.3)
                                : Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            method == 'Mobile Money'
                                ? Icons.phone_android
                                : Icons.account_balance,
                            color:
                                isSelected ? Colors.white : AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            method,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Mobile Money Networks ──
            if (_selectedPaymentMethod == 'Mobile Money') ...[
              const Text(
                'Select Network',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ..._momoDetails.entries.map((entry) {
                final isSelected = _selectedMomo == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMomo = entry.key),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.secondary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.secondary.withOpacity(0.1)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.phone_android,
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.textGrey,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isSelected
                                      ? AppColors.secondary
                                      : AppColors.textDark,
                                ),
                              ),
                              Text(
                                'Send to: ${entry.value['number']} (${entry.value['name']})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            // ── Bank Transfer Details ──
            if (_selectedPaymentMethod == 'Bank Transfer') ...[
              const Text(
                'Bank Details',
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
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  children: _bankDetails.entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // ── Pay Button ──
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pay GHS ${_amountController.text.isEmpty ? '0.00' : double.tryParse(_amountController.text)?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Security note
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.security,
                    size: 14,
                    color: AppColors.textLight,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Secured by Paystack & ChurchConnect',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
