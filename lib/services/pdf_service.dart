import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generatePaymentReceipt({
    required String memberName,
    required String email,
    required String phone,
    required String paymentType,
    required double amount,
    required String paymentMethod,
    required String paymentDate,
    required String receiptNumber,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──
              pw.Container(
                width:   double.infinity,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color:        PdfColor.fromHex('6A0DAD'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Great Mountains Of God International Ministry',
                      style: pw.TextStyle(
                        fontSize:   22,
                        fontWeight: pw.FontWeight.bold,
                        color:      PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'Kasoa, Galilea - Cola Factory',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color:    PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // ── Receipt Title ──
              pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PAYMENT RECEIPT',
                    style: pw.TextStyle(
                      fontSize:   20,
                      fontWeight: pw.FontWeight.bold,
                      color:      PdfColor.fromHex('6A0DAD'),
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Receipt #$receiptNumber',
                        style: pw.TextStyle(
                          fontSize:   12,
                          fontWeight: pw.FontWeight.bold,
                          color:      PdfColor.fromHex('E74C3C'),
                        ),
                      ),
                      pw.Text(
                        paymentDate,
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color:    PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(
                color:     PdfColor.fromHex('6A0DAD'),
                thickness: 2,
              ),
              pw.SizedBox(height: 20),

              // ── Member Details ──
              pw.Text(
                'Member Information',
                style: pw.TextStyle(
                  fontSize:   14,
                  fontWeight: pw.FontWeight.bold,
                  color:      PdfColor.fromHex('6A0DAD'),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color:        PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _pdfRow('Full Name', memberName),
                    _pdfRow('Email',     email),
                    _pdfRow('Phone',     phone),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // ── Payment Details ──
              pw.Text(
                'Payment Details',
                style: pw.TextStyle(
                  fontSize:   14,
                  fontWeight: pw.FontWeight.bold,
                  color:      PdfColor.fromHex('6A0DAD'),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color:        PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _pdfRow('Payment Type',   paymentType),
                    _pdfRow('Payment Method', paymentMethod),
                    _pdfRow('Payment Date',   paymentDate),
                    _pdfRow('Status',         'Recorded'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // ── Amount Box ──
              pw.Container(
                width:   double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color:        PdfColor.fromHex('6A0DAD'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL AMOUNT PAID',
                      style: pw.TextStyle(
                        fontSize:   14,
                        fontWeight: pw.FontWeight.bold,
                        color:      PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'GHS ${amount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize:   24,
                        fontWeight: pw.FontWeight.bold,
                        color:      PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // ── Footer ──
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for your faithfulness and generosity.',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color:    PdfColors.grey,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'God bless you abundantly.',
                      style: pw.TextStyle(
                        fontSize:   12,
                        fontWeight: pw.FontWeight.bold,
                        color:      PdfColor.fromHex('6A0DAD'),
                      ),
                    ),
                    pw.Text(
                      'Great Mountains Of God International Ministry',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color:    PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 12,
              color:    PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize:   12,
              fontWeight: pw.FontWeight.bold,
              color:      PdfColor.fromHex('2C3E50'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Generate Tithe Certificate ──
  static Future<void> generateTitheCertificate({
    required String memberName,
    required String email,
    required String phone,
    required String department,
    required double totalTithe,
    required double totalOffering,
    required double totalDues,
    required double grandTotal,
    required String year,
    required String certificateNumber,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header
                pw.Container(
                  width:   double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color:        PdfColor.fromHex('6A0DAD'),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'GREAT MOUNTAINS OF GOD',
                        style: pw.TextStyle(
                          fontSize:   22,
                          fontWeight: pw.FontWeight.bold,
                          color:      PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'INTERNATIONAL MINISTRY',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color:    PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Kasoa, Galilea - Cola Factory',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color:    PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Certificate title
                pw.Text(
                  'GIVING CERTIFICATE',
                  style: pw.TextStyle(
                    fontSize:   28,
                    fontWeight: pw.FontWeight.bold,
                    color:      PdfColor.fromHex('6A0DAD'),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  'Year $year',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color:    PdfColor.fromHex('E74C3C'),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width:  100,
                  height: 3,
                  color:  PdfColor.fromHex('6A0DAD'),
                ),
                pw.SizedBox(height: 30),

                // Member details
                pw.Text(
                  'This is to certify that',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color:    PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  memberName,
                  style: pw.TextStyle(
                    fontSize:   24,
                    fontWeight: pw.FontWeight.bold,
                    color:      PdfColor.fromHex('2C3E50'),
                  ),
                ),
                pw.Text(
                  department,
                  style: pw.TextStyle(
                    fontSize: 14,
                    color:    PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 30),

                // Giving breakdown table
                pw.Container(
                  width:   double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color:        PdfColor.fromHex('F5F6FA'),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: const pw.Border(
                      left: pw.BorderSide(
                        color: PdfColors.deepPurple,
                        width: 4,
                      ),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Giving Summary for $year',
                        style: pw.TextStyle(
                          fontSize:   14,
                          fontWeight: pw.FontWeight.bold,
                          color:      PdfColor.fromHex('6A0DAD'),
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      _buildCertRow(
                        'Tithe',
                        'GHS ${totalTithe.toStringAsFixed(2)}',
                      ),
                      _buildCertRow(
                        'Offering',
                        'GHS ${totalOffering.toStringAsFixed(2)}',
                      ),
                      _buildCertRow(
                        'Dues',
                        'GHS ${totalDues.toStringAsFixed(2)}',
                      ),
                      pw.Divider(
                        color: PdfColor.fromHex('6A0DAD'),
                      ),
                      _buildCertRow(
                        'Grand Total',
                        'GHS ${grandTotal.toStringAsFixed(2)}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Bible verse
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColor.fromHex('E74C3C'),
                      width: 1,
                    ),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    '"Bring the whole tithe into the storehouse, that there may be food in my house." — Malachi 3:10',
                    style: pw.TextStyle(
                      fontSize:  12,
                      color:     PdfColors.grey700,
                      fontStyle: pw.FontStyle.italic,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 30),

                // Footer
                pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '________________________',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('6A0DAD'),
                          ),
                        ),
                        pw.Text(
                          'Apostle Wisdom Wetsi',
                          style: pw.TextStyle(
                            fontSize:   12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Senior Pastor',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color:    PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Certificate No: $certificateNumber',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color:    PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color:    PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
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

  static pw.Widget _buildCertRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize:   13,
              fontWeight: isBold
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              color: isBold
                  ? PdfColor.fromHex('6A0DAD')
                  : PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize:   13,
              fontWeight: isBold
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              color: isBold
                  ? PdfColor.fromHex('6A0DAD')
                  : PdfColor.fromHex('2C3E50'),
            ),
          ),
        ],
      ),
    );
  }
}