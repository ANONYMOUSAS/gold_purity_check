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

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> filteredHistory = [];
  String selectedField = 'All';
  String searchText = '';

  final List<String> fields = [
    'All',
    'dryWeight',
    'wetWeight',
    'density',
    'karat',
    'purity',
    'pureGold',
  ];

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  void fetchHistory() async {
    final data = await GoldDatabaseHelper.instance.fetchHistory();
    setState(() {
      history = data;
      filteredHistory = data;
    });
  }

  void filterHistory(String text) {
    setState(() {
      searchText = text;
      filteredHistory = history.where((entry) {
        return entry.entries.any((e) =>
            e.value.toString().toLowerCase().contains(text.toLowerCase()));
      }).toList();
    });
  }

  pw.Widget buildRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              "$label:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  // void shareHistory() {
  //   String historyText = filteredHistory.map((entry) {
  //     final timestamp = DateTime.parse(entry['timestamp']);
  //     final formattedDate =
  //     DateFormat('dd-MM-yyyy h:mm a').format(timestamp);
  //
  //     if (selectedField == 'All') {
  //       return "Dry: ${entry['dryWeight']}g, Wet: ${entry['wetWeight']}g, Density: ${entry['density']}, Karat: ${entry['karat']}, Purity: ${entry['purity']}%, Pure Gold: ${entry['pureGold']}g, Date: $formattedDate";
  //     } else {
  //       return "${selectedField}: ${entry[selectedField]}, Date: $formattedDate";
  //     }
  //   }).join("\n\n");
  //
  //   Share.share(historyText, subject: "Gold Purity History");
  // }

  Future<void> shareSingleRowAsPdf(Map<String, dynamic> row) async {
    final pdf = pw.Document();
    final timestamp = DateTime.parse(row['timestamp']);
    final formattedDate = DateFormat('dd-MM-yyyy h:mm a').format(timestamp);
    final generatedDate = DateFormat('dd-MM-yyyy').format(DateTime.now()); // Today's date

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Mughal Zargar House',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.Text(
                        'Gold Purity Report',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    generatedDate,
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.grey),
              pw.SizedBox(height: 20),

              // Title Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                color: PdfColors.amber100,
                child: pw.Text(
                  "Gold Purity Entry",
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),

              // Body
              buildRow("Dry Weight", "${row['dryWeight']} g"),
              buildRow("Wet Weight", "${row['wetWeight']} g"),
              buildRow("Density", "${row['density']}"),
              buildRow("Karat", "${row['karat']}"),
              buildRow("Purity", "${row['purity']}%"),
              buildRow("Pure Gold", "${row['pureGold']} g"),
              buildRow("Date", formattedDate),

              /*// Footer Section (for every page)
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Address: Sadar Bazar Narang, Pakistan",
                    style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                  ),
                  pw.Text(
                    "Phone: +92 310 9786001",
                    style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                  ),
                ],
              ),*/
            ],
          ),
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/row_history.pdf");
    await file.writeAsBytes(await pdf.save());

    Share.shareXFiles([XFile(file.path)], text: "Gold Purity Entry PDF");
  }

  Future<void> shareFullHistoryAsPdf() async {
    if (history.isEmpty) return;

    final pdf = pw.Document();
    final generatedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

    // Header for full history page
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section (same as in single row)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Mughal Zargar House',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.Text(
                        'Gold Purity Report',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    generatedDate,
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.grey),
              pw.SizedBox(height: 20),

              // Title Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                color: PdfColors.amber100,
                child: pw.Text(
                  "Full Gold Purity History",
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),

              // Table for the history data
              pw.Table.fromTextArray(
                headers: [
                  'SN', 'Dry (g)', 'Wet (g)', 'Density', 'Karat',
                  'Purity (%)', 'Pure Gold (g)', 'Date'
                ],
                data: history.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final h = entry.value;
                  final timestamp = DateTime.parse(h['timestamp']);
                  final formattedDate = DateFormat('dd-MM-yyyy h:mm a').format(timestamp);

                  return [
                    index.toString(),
                    h['dryWeight'].toString(),
                    h['wetWeight'].toString(),
                    double.parse(h['density']).toStringAsFixed(2),
                    double.parse(h['karat']).round().toString(),
                    double.parse(h['purity']).toStringAsFixed(2),
                    double.parse(h['pureGold']).toStringAsFixed(2),
                    formattedDate,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                rowDecoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    /*// Adding footer manually to the full history page
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Address: Sadar Bazar Narang, Pakistan",
                  style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                ),
                pw.Text(
                  "Phone: +92 310 9786001",
                  style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );*/

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/full_history.pdf");
    await file.writeAsBytes(await pdf.save());

    Share.shareXFiles([XFile(file.path)], text: "Full Gold Purity History PDF");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gold Purity History"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: filteredHistory.isNotEmpty ? shareFullHistoryAsPdf : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Field
            TextField(
              decoration: InputDecoration(
                hintText: 'Search history...',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: filterHistory,
            ),
            const SizedBox(height: 16),

            // History Table
            Expanded(
              child: filteredHistory.isNotEmpty
                  ? Card(
                margin: const EdgeInsets.only(top: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 12,
                      columns: const [
                        DataColumn(label: Text('SN')),
                        DataColumn(label: Text('Dry Weight (g)')),
                        DataColumn(label: Text('Wet Weight (g)')),
                        DataColumn(label: Text('Density (g/cm³)')),
                        DataColumn(label: Text('Karat')),
                        DataColumn(label: Text('Purity (%)')),
                        DataColumn(label: Text('Pure Gold (g)')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Share')),
                      ],
                      rows: filteredHistory.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final h = entry.value;
                        final timestamp = DateTime.parse(h['timestamp']);
                        final formattedDate = DateFormat('dd-MM-yyyy h:mm a').format(timestamp);

                        return DataRow(
                          cells: [
                            DataCell(Text(index.toString())),
                            DataCell(Text(h['dryWeight'].toString())),
                            DataCell(Text(h['wetWeight'].toString())),
                            DataCell(Text(double.parse(h['density']).toStringAsFixed(2))),
                            DataCell(Text(double.parse(h['karat']).round().toString())),
                            DataCell(Text(double.parse(h['purity']).toStringAsFixed(2))),
                            DataCell(Text(double.parse(h['pureGold']).toStringAsFixed(2))),
                            DataCell(Text(formattedDate)),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () => shareSingleRowAsPdf(h),
                              ),
                            ),

                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              )
                  : const Center(child: Text('No history available')),
            ),
          ],
        ),
      ),
    );
  }
}
