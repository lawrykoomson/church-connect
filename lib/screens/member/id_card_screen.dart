import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../models/member_model.dart';

class IdCardScreen extends StatefulWidget {
  const IdCardScreen({super.key});

  @override
  State<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends State<IdCardScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Member? _member;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  Future<void> _loadMember() async {
    setState(() => _isLoading = true);
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore
          .collection(AppConstants.membersCollection)
          .doc(uid)
          .get();
      if (doc.exists) {
        _member = Member.fromFirestore(doc.data()!, doc.id);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadIdCard() async {
    if (_member == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat:
            PdfPageFormat(85.6 * PdfPageFormat.mm, 53.98 * PdfPageFormat.mm),
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            child: pw.Stack(
              children: [
                // Background circle decoration
                pw.Positioned(
                  right: -20,
                  top: -20,
                  child: pw.Container(
                    width: 100,
                    height: 100,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                ),
                pw.Positioned(
                  left: -15,
                  bottom: -15,
                  child: pw.Container(
                    width: 70,
                    height: 70,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F39C12'),
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                ),

                // Content
                pw.Padding(
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'ChurchConnect',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.Text(
                                'Member ID Card',
                                style: const pw.TextStyle(
                                  fontSize: 7,
                                  color: PdfColors.orange,
                                ),
                              ),
                            ],
                          ),
                          pw.Container(
                            width: 30,
                            height: 30,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.orange,
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                _member!.fullName.substring(0, 1).toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),

                      // Member Name
                      pw.Text(
                        _member!.fullName,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        _member!.department,
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.orange,
                        ),
                      ),
                      pw.SizedBox(height: 8),

                      // Details
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _idRow('Email', _member!.email),
                                pw.SizedBox(height: 4),
                                _idRow('Phone', _member!.phoneNumber),
                              ],
                            ),
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: _member!.duesStatus == 'Paid'
                                      ? PdfColors.green
                                      : PdfColors.orange,
                                  borderRadius: pw.BorderRadius.circular(10),
                                ),
                                child: pw.Text(
                                  _member!.duesStatus,
                                  style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                  ),
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'ID: ${_member!.id.substring(0, 8).toUpperCase()}',
                                style: const pw.TextStyle(
                                  fontSize: 7,
                                  color: PdfColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _idRow(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 6,
            color: PdfColors.grey,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Member ID Card',
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
                color: AppColors.secondary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Your Church Member ID Card',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Download and save your digital membership card',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // ── ID Card Preview ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ChurchConnect',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Member ID Card',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (_member?.fullName ?? 'M')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Member Name
                        Text(
                          _member?.fullName ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _member?.department ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Member Details
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _detailRow(
                                    'Email',
                                    _member?.email ?? '',
                                  ),
                                  const SizedBox(height: 8),
                                  _detailRow(
                                    'Phone',
                                    _member?.phoneNumber ?? '',
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _member?.duesStatus == 'Paid'
                                        ? AppColors.paid
                                        : AppColors.pending,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _member?.duesStatus ?? 'Pending',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ID: ${(_member?.id ?? '').substring(0, 8).toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Download Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _downloadIdCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.download),
                      label: const Text(
                        'Download ID Card',
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

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white60,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
