import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class PdfInvoiceGenerator {
  
  // Fixed contractor details (Khyber Corporation)
  static const String contractorName = 'M/S Khyber Corporation Faisalabad';
  static const String contractorNTN = '3662376-5';
  static const String contractorAddress = 'P-4 St No. 1 Umair Town, Sargodha Road, Faisalabad, Pakistan.';
  
  // Fixed client details (SNGPL)
  static const String clientName = 'M/S.Sui Northern Gas Pipeline Limited';
  static const String clientNTN = '0801137-7';
  static const String clientAddress = 'Gas house, 21-Kashmir Road Lahore';
  
  // HS Code fixed
  static const String hsCode = '9809.0000';
  static const String description = '98-33-Labour and Manpower Services';

  static Future<Uint8List> generateInvoice({
    required DateTime invoiceDate,
    required String jobNo,
    required String workOrderNo,
    required double exclusiveValue,
    required double pstRate,
    required double pstAmount,
    required double totalAmount,
    Uint8List? letterheadImage, // Optional letterhead image
  }) async {
    final pdf = pw.Document();
    
    // Hardcoded small integer invoice number
    const String invoiceNumber = '359';
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          // Create a stack for background image if provided
          return pw.Stack(
            children: [
              // Background Letterhead (if provided)
              if (letterheadImage != null)
                pw.Positioned.fill(
                  child: pw.Opacity(
                    opacity: 0.3, // 30% opacity for background
                    child: pw.Image(
                      pw.MemoryImage(letterheadImage),
                      fit: pw.BoxFit.contain,
                      alignment: pw.Alignment.topCenter,
                    ),
                  ),
                ),
              
              // Main Content
              pw.Container(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header - PROVINCIAL SALES TAX INVOICE
                    pw.Center(
                      child: pw.Text(
                        'PROVINCIAL SALES TAX INVOICE',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // Contractor Details Box
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            contractorName,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text('PNTN: $contractorNTN'),
                          pw.Text('Address $contractorAddress'),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 16),

                    // Service Provided To Box
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Service Provided To:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text('Name: $clientName'),
                          pw.Text('NTN: $clientNTN'),
                          pw.Text('Address $clientAddress'),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // Invoice Details Table - Modified for better width distribution
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left box - Smaller width (flex: 1)
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(width: 1),
                            ),
                            child: pw.Column(
                              children: [
                                _buildInfoRow('INVOICE NUMBER', invoiceNumber),
                                pw.SizedBox(height: 8),
                                pw.Divider(),
                                pw.SizedBox(height: 8),
                                _buildInfoRow('INVOICE DATE', _formatDate(invoiceDate)),
                                pw.SizedBox(height: 8),
                                pw.Divider(),
                                pw.SizedBox(height: 8),
                                _buildInfoRow('HS Code', hsCode),
                              ],
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        // Right box - Larger width (flex: 2)
                        pw.Expanded(
                          flex: 2,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(width: 1),
                            ),
                            child: pw.Column(
                              children: [
                                _buildInfoRow('Description : ', description),
                                pw.SizedBox(height: 8),
                                pw.Divider(),
                                pw.SizedBox(height: 8),
                                _buildInfoRow('Job No : ', jobNo),
                                pw.SizedBox(height: 8),
                                pw.Divider(),
                                pw.SizedBox(height: 8),
                                _buildInfoRow('Work Order No : ', workOrderNo),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),

                    // Provincial Sales Tax Rate
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                        color: PdfColors.grey200,
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Provincial Sales Tax Rate',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            '${pstRate.toStringAsFixed(0)}%',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // Main Table with Work Description
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                      ),
                      child: pw.Column(
                        children: [
                          // Table Header
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            color: PdfColors.grey200,
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    'DESCRIPTION OF WORK',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 1,
                                  child: pw.Text(
                                    'Exclusive value',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 1,
                                  child: pw.Text(
                                    'PST RATE',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 1,
                                  child: pw.Text(
                                    'PST',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 1,
                                  child: pw.Text(
                                    'PST Inclusive Value',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Table Row 1 - Description line 1
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    'Pipe Laying / Ditching services,',
                                    style: pw.TextStyle(fontSize: 11),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 1,
                                  child: pw.Text(
                                    _formatCurrency(exclusiveValue),
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(fontSize: 11),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 1,
                                  child: pw.Text(
                                    '${pstRate.toStringAsFixed(0)}%',
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(fontSize: 11),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 1,
                                  child: pw.Text(
                                    _formatCurrency(pstAmount),
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(fontSize: 11),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 1,
                                  child: pw.Text(
                                    _formatCurrency(totalAmount),
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                      fontSize: 11,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Table Row 2 - Against Work Order line
                          pw.Container(
                            padding: const pw.EdgeInsets.only(left: 8, right: 8, bottom: 10),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    'Against Work Order NO.',
                                    style: pw.TextStyle(fontSize: 11),
                                  ),
                                ),
                                pw.Expanded(flex: 1, child: pw.Container()),
                                pw.Expanded(flex: 1, child: pw.Container()),
                                pw.Expanded(flex: 1, child: pw.Container()),
                                pw.Expanded(flex: 1, child: pw.Container()),
                              ],
                            ),
                          ),
                          
                          // Table Row 3 - Work Order Number
                          pw.Container(
                            padding: const pw.EdgeInsets.only(left: 8, right: 8, bottom: 10),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Container(
                                    padding: const pw.EdgeInsets.only(left: 20),
                                    child: pw.Text(
                                      workOrderNo,
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                pw.Expanded(flex: 1, child: pw.Container()),
                                pw.Expanded(flex: 1, child: pw.Container()),
                                pw.Expanded(flex: 1, child: pw.Container()),
                                pw.Expanded(flex: 1, child: pw.Container()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 30),

                    // Bottom Row with Payment Instructions and Signature
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Payment Instructions (Left side)
                        pw.Expanded(
                          flex: 2,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(12),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(width: 1),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'MAKE ALL CHECKS PAYABLE',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  contractorName,
                                  style: pw.TextStyle(fontSize: 11),
                                ),
                                pw.Text(
                                  contractorAddress,
                                  style: pw.TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        pw.SizedBox(width: 20),
                        
                        // Signature Space (Right side)
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            height: 100,
                            padding: const pw.EdgeInsets.all(12),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(width: 1),
                            ),
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Container(
                                  height: 40,
                                  child: pw.Center(
                                    child: pw.Text(
                                      '(Signature)',
                                      style: pw.TextStyle(
                                        fontSize: 10,
                                        color: PdfColors.grey600,
                                      ),
                                    ),
                                  ),
                                ),
                                pw.Divider(thickness: 1),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'M/S Khyber Corporation',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.Text(
                                  '(CEO)',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.grey700,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    
    return pdf.save();
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${_getMonthAbbr(date.month)}-${date.year}';
  }

  static String _getMonthAbbr(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  static String _formatCurrency(double amount) {
    // Format with commas but without decimals (like in the example)
    return amount.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
