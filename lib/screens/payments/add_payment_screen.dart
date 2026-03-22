import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_constants.dart';
import '../../../models/payment_model.dart';
import '../../../models/member_model.dart';
import '../../../services/payment_service.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _paymentService   = PaymentService();
  final _amountController = TextEditingController();
  final _firestore        = FirebaseFirestore.instance;

  String?  _selectedMemberId;
  String?  _selectedMemberName;
  String?  _selectedMemberPhone;
  String   _selectedPaymentType = 'Monthly Dues';
  DateTime _selectedDate        = DateTime.now();
  bool     _isLoading           = false;
  List<Member> _members         = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final snap = await _firestore
        .collection(AppConstants.membersCollection)
        .orderBy('fullName')
        .get();
    setState(() {
      _members = snap.docs
          .map((doc) => Member.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:      context,
      initialDate:  _selectedDate,
      firstDate:    DateTime(2020),
      lastDate:     DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _savePayment() async {
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a member.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the payment amount.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payment = Payment(
        id:          '',
        memberId:    _selectedMemberId!,
        memberName:  _selectedMemberName!,
        phoneNumber: _selectedMemberPhone!,
        amount:      double.tryParse(
            _amountController.text) ?? 0,
        paymentType: _selectedPaymentType,
        paymentDate: _selectedDate,
        recordedBy:  'Admin',
        createdAt:   DateTime.now(),
      );

      await _paymentService.recordPayment(payment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully!'),
            backgroundColor: AppColors.paid,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Record Payment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Select Member
                  const Text(
                    'Select Member *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMemberId,
                        isExpanded: true,
                        hint: const Text(
                          'Choose a member',
                          style: TextStyle(
                            color: AppColors.textLight,
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.primary,
                        ),
                        items: _members.map((member) {
                          return DropdownMenuItem<String>(
                            value: member.id,
                            child: Text(member.fullName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          final selected = _members
                              .firstWhere((m) => m.id == val);
                          setState(() {
                            _selectedMemberId    = val;
                            _selectedMemberName  = selected.fullName;
                            _selectedMemberPhone = selected.phoneNumber;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Type
                  const Text(
                    'Payment Type *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPaymentType,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.primary,
                        ),
                        items: AppConstants.paymentTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (val) => setState(
                            () => _selectedPaymentType = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  const Text(
                    'Amount (GHS) *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 50.00',
                      hintStyle: const TextStyle(
                        color: AppColors.textLight,
                      ),
                      prefixIcon: const Icon(
                        Icons.money,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.secondary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Date
                  const Text(
                    'Payment Date *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd MMMM yyyy')
                                .format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.paid,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      )
                    : const Text(
                        'Record Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
}