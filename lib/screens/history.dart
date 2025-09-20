import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database.dart';
import 'package:pdf/widgets.dart' as pw;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> filteredHistory = [];
  String searchText = '';
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    fetchHistory();
  }

  // POS Thermal Printer Receipt (58mm width)
  Future<void> shareThermalReceiptPdf(Map<String, dynamic> row) async {
    final pdf = pw.Document();
    final timestamp = DateTime.parse(row['timestamp']);
    final formattedDate = DateFormat('dd/MM/yy HH:mm').format(timestamp);
    final receiptNumber = DateTime.now().millisecondsSinceEpoch.toString().substring(8);

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity),
        margin: const pw.EdgeInsets.all(4),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Header
            pw.Text(
              'MUGHAL ZARGAR HOUSE',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'Gold Testing Receipt',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'Sadar Bazar Narang',
              style: const pw.TextStyle(fontSize: 6),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              '+92 310 9786001',
              style: const pw.TextStyle(fontSize: 6),
              textAlign: pw.TextAlign.center,
            ),

            pw.SizedBox(height: 4),
            pw.Container(height: 0.5, width: double.infinity, color: PdfColors.black),
            pw.SizedBox(height: 4),

            // Receipt Details
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Receipt#:', style: const pw.TextStyle(fontSize: 6)),
                pw.Text('TR$receiptNumber', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date:', style: const pw.TextStyle(fontSize: 6)),
                pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 6)),
              ],
            ),

            if (row['customerName'] != null && row['customerName'].toString().isNotEmpty && row['customerName'] != 'N/A') ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Customer:', style: const pw.TextStyle(fontSize: 6)),
                  pw.Flexible(
                    child: pw.Text(
                      '${row['customerName']}',
                      style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],

            pw.SizedBox(height: 4),
            pw.Container(height: 0.5, width: double.infinity, color: PdfColors.black),
            pw.SizedBox(height: 4),

            // Test Results
            pw.Text(
              'TEST RESULTS',
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 2),

            _buildReceiptRow('Dry Weight:', '${row['dryWeight']}g'),
            _buildReceiptRow('Wet Weight:', '${row['wetWeight']}g'),
            _buildReceiptRow('Density:', '${row['density']}g/cm³'),

            pw.SizedBox(height: 2),
            pw.Container(height: 0.3, width: double.infinity, color: PdfColors.grey),
            pw.SizedBox(height: 2),

            _buildReceiptRow('KARAT:', '${row['karat']}K', isBold: true),
            _buildReceiptRow('PURITY:', '${row['purity']}%', isBold: true),
            _buildReceiptRow('PURE GOLD:', '${row['pureGold']}g', isBold: true),

            pw.SizedBox(height: 4),
            pw.Container(height: 0.5, width: double.infinity, color: PdfColors.black),
            pw.SizedBox(height: 4),

            // Footer
            pw.Text(
              'Results based on sample provided',
              style: const pw.TextStyle(fontSize: 5),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'Thank you for choosing us!',
              style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),

            pw.SizedBox(height: 6),
            pw.Text(
              '- - - - - - - - - - - - - - - -',
              style: const pw.TextStyle(fontSize: 6),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/thermal_receipt_TR$receiptNumber.pdf");
    await file.writeAsBytes(await pdf.save());

    Share.shareXFiles([XFile(file.path)], text: "Thermal Receipt - TR$receiptNumber");
  }

  // Helper method for receipt rows
  pw.Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isBold ? 7 : 6,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isBold ? 7 : 6,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void fetchHistory() async {
    setState(() {
      isLoading = true;
    });

    final data = await GoldDatabaseHelper.instance.fetchHistory();
    setState(() {
      history = data;
      filteredHistory = data;
      isLoading = false;
    });

    _animationController.forward();
  }

  void filterHistory(String text) {
    setState(() {
      searchText = text;
      filteredHistory = history.where((entry) {
        return entry['customerName']?.toString().toLowerCase().contains(text.toLowerCase()) == true ||
            entry['karat']?.toString().toLowerCase().contains(text.toLowerCase()) == true ||
            entry['purity']?.toString().toLowerCase().contains(text.toLowerCase()) == true;
      }).toList();
    });
  }

  Future<void> deleteRecord(int id) async {
    await GoldDatabaseHelper.instance.deleteRecord(id);
    fetchHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text('Record deleted successfully'),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> clearAllHistory() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Clear All History'),
          ],
        ),
        content: const Text('Are you sure you want to delete all history records? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await GoldDatabaseHelper.instance.clearAllHistory();
              fetchHistory();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  pw.Widget buildPdfRow(String label, String value, {bool isBold = false}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: isBold ? 12 : 11,
                color: isBold ? PdfColors.amber800 : PdfColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> shareSingleRowAsPdf(Map<String, dynamic> row) async {
    final pdf = pw.Document();
    final timestamp = DateTime.parse(row['timestamp']);
    final formattedDate = DateFormat('dd-MM-yyyy h:mm a').format(timestamp);
    final generatedDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
    final reportNumber = 'GPR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.only(left: 40.0, right: 40.0, top: 40.0, bottom: 30.0),
        build: (context) => pw.Column(
          // crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header Section with Logo Space
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                gradient: const pw.LinearGradient(
                  colors: [PdfColors.amber700, PdfColors.orange600],
                ),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MUGHAL ZARGAR HOUSE',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Professional Gold Testing & Evaluation',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Sadar Bazar Narang, Pakistan',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
                      ),
                      pw.Text(
                        'Phone: +92 310 9786001',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
                      ),
                    ],
                  ),
                  // pw.Container(
                  //   width: 80,
                  //   height: 80,
                  //   decoration: pw.BoxDecoration(
                  //     color: PdfColors.white,
                  //     borderRadius: pw.BorderRadius.circular(40),
                  //   ),
                  //   child: pw.Center(
                  //     child: pw.Text(
                  //       '💎',
                  //       style: const pw.TextStyle(fontSize: 40),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Report Info Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'GOLD PURITY CERTIFICATE',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.amber800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Report No: $reportNumber', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Generated: $generatedDate', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    border: pw.Border.all(color: PdfColors.amber300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'TEST DATE',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        formattedDate,
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // Customer Information
            if (row['customerName'] != null && row['customerName'].toString().isNotEmpty && row['customerName'] != 'N/A')
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CUSTOMER INFORMATION',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Name: ${row['customerName']}',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),

            pw.SizedBox(height: 20),

            // Test Results Section
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 2),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TEST RESULTS',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber800,
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  buildPdfRow('Sample Dry Weight', '${row['dryWeight']} grams'),
                  buildPdfRow('Sample Wet Weight', '${row['wetWeight']} grams'),
                  buildPdfRow('Calculated Density', '${row['density']} g/cm³'),
                  buildPdfRow('Gold Karat', '${row['karat']} K', isBold: true),
                  buildPdfRow('Purity Percentage', '${row['purity']}%', isBold: true),
                  buildPdfRow('Pure Gold Content', '${row['pureGold']} grams', isBold: true),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Disclaimer Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DISCLAIMER',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'This certificate is issued based on the sample provided and testing methodology used. '
                        'Results are accurate to the best of our testing capabilities. This certificate is valid '
                        'only for the specific sample tested.',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // Footer with Signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      height: 1,
                      width: 120,
                      color: PdfColors.grey400,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Authorized Signature',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Gold Testing Specialist',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Certified by',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Mughal Zargar House',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
            pw.Spacer(),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  textAlign: pw.TextAlign.center,
                  '© 2025 Nanocraft Technology (Private) Limited. All rights reserved.',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/gold_certificate_$reportNumber.pdf");
    await file.writeAsBytes(await pdf.save());

    Share.shareXFiles([XFile(file.path)], text: "Gold Purity Certificate - $reportNumber");
  }

  /*Future<void> shareFullHistoryAsPdf() async {
    if (history.isEmpty) return;

    final pdf = pw.Document();
    final generatedDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.only(left: 40.0, right: 40.0, top: 40.0, bottom: 30.0),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header Section
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                gradient: const pw.LinearGradient(
                  colors: [PdfColors.amber700, PdfColors.orange600],
                ),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MUGHAL ZARGAR HOUSE',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Complete Gold Testing History Report',
                        style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Generated: $generatedDate',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
                      ),
                    ],
                  ),
                  // pw.Container(
                  //   width: 60,
                  //   height: 60,
                  //   decoration: pw.BoxDecoration(
                  //     color: PdfColors.white,
                  //     borderRadius: pw.BorderRadius.circular(30),
                  //   ),
                  //   child: pw.Center(
                  //     child: pw.Text('💎', style: const pw.TextStyle(fontSize: 30)),
                  //   ),
                  // ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Summary Stats
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        '${history.length}',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Total Tests', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Container(width: 1, height: 30, color: PdfColors.grey300),
                  pw.Column(
                    children: [
                      pw.Text(
                        DateFormat('MMM yyyy').format(DateTime.parse(history.first['timestamp'])),
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Latest Test', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // History Table
            pw.Expanded(
              child: pw.Table.fromTextArray(
                headerHeight: 35,
                cellHeight: 25,
                headers: [
                  'S.No', 'Customer', 'Dry (g)', 'Wet (g)', 'Karat', 'Purity %', 'Pure Gold (g)', 'Date'
                ],
                data: history.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final h = entry.value;
                  final timestamp = DateTime.parse(h['timestamp']);
                  final formattedDate = DateFormat('dd/MM/yy').format(timestamp);

                  return [
                    index.toString(),
                    h['customerName']?.toString().isNotEmpty == true && h['customerName'] != 'N/A'
                        ? h['customerName'].toString().substring(0, h['customerName'].toString().length > 10 ? 10 : h['customerName'].toString().length)
                        : 'N/A',
                    h['dryWeight'].toString(),
                    h['wetWeight'].toString(),
                    double.parse(h['karat']).toStringAsFixed(1),
                    double.parse(h['purity']).toStringAsFixed(1),
                    double.parse(h['pureGold']).toStringAsFixed(2),
                    formattedDate,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.amber700,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.center,
                rowDecoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  ),
                ),
              ),
            ),

            pw.SizedBox(height: 20),

            // Footer
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Sadar Bazar Narang, Pakistan | Phone: +92 310 9786001',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Professional Gold Testing Services',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/complete_gold_history_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    Share.shareXFiles([XFile(file.path)], text: "Complete Gold Testing History Report");
  }*/

  Future<void> shareFullHistoryAsPdf() async {
    if (history.isEmpty) return;

    final pdf = pw.Document();
    // final generatedDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(30),
        footer: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Sadar Bazar Narang, Pakistan | Phone: +92 310 9786001',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Professional Gold Testing Services',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              '© 2025 Nanocraft Technology (Private) Limited. All rights reserved.',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
          ],
        ),
        build: (context) => [
          // Header Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [PdfColors.amber700, PdfColors.orange600],
              ),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MUGHAL ZARGAR HOUSE',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Professional Gold Testing & Evaluation',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Sadar Bazar Narang, Pakistan',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
                    ),
                    pw.Text(
                      'Phone: +92 310 9786001',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
                    ),
                  ],
                ),
                // pw.Container(
                //   width: 80,
                //   height: 80,
                //   decoration: pw.BoxDecoration(
                //     color: PdfColors.white,
                //     borderRadius: pw.BorderRadius.circular(40),
                //   ),
                //   child: pw.Center(
                //     child: pw.Text(
                //       '💎',
                //       style: const pw.TextStyle(fontSize: 40),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Summary Stats
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text(
                      '${history.length}',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Total Tests', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Container(width: 1, height: 30, color: PdfColors.grey300),
                pw.Column(
                  children: [
                    pw.Text(
                      DateFormat('MMM yyyy').format(DateTime.parse(history.first['timestamp'])),
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Latest Test', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // History Table
          pw.Table.fromTextArray(
            headerHeight: 35,
            cellHeight: 25,
            headers: [
              'S.No', 'Customer', 'Dry (g)', 'Wet (g)', 'Karat',
              'Purity %', 'Pure Gold (g)', 'Date'
            ],
            data: history.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final h = entry.value;
              final timestamp = DateTime.parse(h['timestamp']);
              final formattedDate = DateFormat('dd/MM/yy').format(timestamp);

              return [
                index.toString(),
                h['customerName']?.toString().isNotEmpty == true && h['customerName'] != 'N/A'
                    ? h['customerName'].toString().substring(0, h['customerName'].toString().length > 10 ? 10 : h['customerName'].toString().length)
                    : 'N/A',
                h['dryWeight'].toString(),
                h['wetWeight'].toString(),
                double.parse(h['karat']).toStringAsFixed(1),
                double.parse(h['purity']).toStringAsFixed(1),
                double.parse(h['pureGold']).toStringAsFixed(2),
                formattedDate,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.amber700,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.center,
            rowDecoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
              ),
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/complete_gold_history_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    Share.shareXFiles([XFile(file.path)], text: "Complete Gold Testing History Report");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              "Testing History",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.amber.shade700, Colors.orange.shade600],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf, size: 20),
              onPressed: filteredHistory.isNotEmpty ? shareFullHistoryAsPdf : null,
              tooltip: 'Export All as PDF',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_forever, size: 20),
              onPressed: history.isNotEmpty ? clearAllHistory : null,
              tooltip: 'Clear All History',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search and Stats Section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${history.length}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                const Text(
                                  'Total Tests',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${filteredHistory.length}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                const Text(
                                  'Showing',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search Field
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by customer name, karat, or purity...',
                        prefixIcon: Icon(Icons.search, color: Colors.amber.shade700),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onChanged: filterHistory,
                    ),
                  ],
                ),
              ),

              // History Table Section
              Expanded(
                child: isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                )
                    : filteredHistory.isNotEmpty
                    ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade700, Colors.orange.shade600],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.table_chart, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Gold Testing Records',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Table Content
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columnSpacing: 16,
                                horizontalMargin: 20,
                                headingRowHeight: 60,
                                dataRowMinHeight: 70,
                                dataRowMaxHeight: 70,
                                headingTextStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                                columns: [
                                  DataColumn(
                                    label: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.numbers, size: 16),
                                          SizedBox(height: 4),
                                          Text('S.No'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.person, size: 16),
                                          SizedBox(height: 4),
                                          Text('Customer'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.monitor_weight, size: 16),
                                          SizedBox(height: 4),
                                          Text('Dry (g)'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.water_drop, size: 16),
                                          SizedBox(height: 4),
                                          Text('Wet (g)'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.diamond, size: 16),
                                          SizedBox(height: 4),
                                          Text('Karat'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.percent, size: 16),
                                          SizedBox(height: 4),
                                          Text('Purity'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.auto_awesome, size: 16),
                                          SizedBox(height: 4),
                                          Text('Pure Gold'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.calendar_today, size: 16),
                                          SizedBox(height: 4),
                                          Text('Date'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.settings, size: 16),
                                          SizedBox(height: 4),
                                          Text('Actions'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                rows: filteredHistory.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final record = entry.value;
                                  final timestamp = DateTime.parse(record['timestamp']);
                                  final formattedDate = DateFormat('dd/MM/yy\nh:mm a').format(timestamp);

                                  // Better customer name handling
                                  String customerName = 'Anonymous';
                                  if (record['customerName'] != null &&
                                      record['customerName'].toString().isNotEmpty &&
                                      record['customerName'].toString().trim() != '' &&
                                      record['customerName'] != 'N/A') {
                                    customerName = record['customerName'].toString();
                                  }

                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>(
                                          (Set<WidgetState> states) {
                                        if (index.isEven) return Colors.grey.shade50;
                                        return Colors.white;
                                      },
                                    ),
                                    cells: [
                                      // Serial Number
                                      DataCell(
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.amber.shade400, Colors.orange.shade400],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Customer Name
                                      DataCell(
                                        Container(
                                          constraints: const BoxConstraints(maxWidth: 120),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                customerName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: customerName == 'Anonymous'
                                                      ? Colors.grey.shade500
                                                      : Colors.grey.shade800,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              if (customerName == 'Anonymous')
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    'No name',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Dry Weight
                                      DataCell(
                                        Text(
                                          '${record['dryWeight']}g',
                                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                        ),
                                      ),

                                      // Wet Weight
                                      DataCell(
                                        Text(
                                          '${record['wetWeight']}g',
                                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                        ),
                                      ),

                                      // Karat
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${double.parse(record['karat']).toStringAsFixed(1)}K',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade800,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Purity
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${double.parse(record['purity']).toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Pure Gold
                                      DataCell(
                                        Text(
                                          '${double.parse(record['pureGold']).toStringAsFixed(2)}g',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.amber.shade800,
                                          ),
                                        ),
                                      ),

                                      // Date
                                      DataCell(
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),

                                      // Actions
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                icon: Icon(Icons.picture_as_pdf, color: Colors.blue.shade700, size: 16),
                                                onPressed: () => shareSingleRowAsPdf(record),
                                                tooltip: 'Export PDF',
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                icon: Icon(Icons.delete, color: Colors.red.shade700, size: 16),
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                      title: const Row(
                                                        children: [
                                                          Icon(Icons.delete_forever, color: Colors.red),
                                                          SizedBox(width: 8),
                                                          Text('Delete Record'),
                                                        ],
                                                      ),
                                                      content: Text('Delete record for ${customerName}?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child: const Text('Cancel'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                            deleteRecord(record['id']);
                                                          },
                                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                tooltip: 'Delete',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          Icons.history,
                          size: 60,
                          color: Colors.amber.shade300,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        searchText.isNotEmpty ? 'No records found' : 'No history available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        searchText.isNotEmpty
                            ? 'Try adjusting your search terms'
                            : 'Start testing gold to see history here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
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
    );
  }
}