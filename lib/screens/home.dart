import 'package:flutter/material.dart';


import '../database/database.dart';
import 'history.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController dryWeightController = TextEditingController();
  final TextEditingController wetWeightController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  Map<String, String> result = {};
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
  }

  Map<String, String> calculateGoldDetails(double dryWeight, double wetWeight) {
    double volume = dryWeight - wetWeight;
    double density = dryWeight / volume;
    double karatPurity = (density / 19.32) * 24;

    if (karatPurity > 24) karatPurity = 24;

    // Round karat to nearest 0.5
    karatPurity = (karatPurity * 2).round() / 2.0;

    double purityPercentage = (karatPurity / 24) * 100;
    double pureGold = (purityPercentage / 100) * dryWeight;

    final now = DateTime.now();

    return {
      'Density (g/cm³)': density.toStringAsFixed(2),
      'Karat': karatPurity.toStringAsFixed(1),
      'Purity (%)': purityPercentage.toStringAsFixed(2),
      'Pure Gold (g)': pureGold.toStringAsFixed(2),
      'Date': "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
    };
  }


  Future<void> calculate() async {
    final dryWeight = double.tryParse(dryWeightController.text);
    final wetWeight = double.tryParse(wetWeightController.text);

    if (dryWeight == null || wetWeight == null || dryWeight <= wetWeight) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid weights')),
      );
      return;
    }

    final calcResult = calculateGoldDetails(dryWeight, wetWeight);
    await GoldDatabaseHelper.instance.insertResult(calcResult, dryWeight, wetWeight);

    setState(() {
      result = calcResult;
    });

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gold Purity"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Inside your HomeScreen class
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dryWeightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Dry Weight (g)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: wetWeightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Wet Weight (g)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 40.0,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: calculate,
                  child: const Text("Calculate", style: TextStyle(fontSize: 20.0),),
                ),
              ),
              const SizedBox(height: 24),
              if (result.isNotEmpty)
                DataTable(
                  columns: const [
                    DataColumn(label: Text("Metric")),
                    DataColumn(label: Text("Value")),
                  ],
                  rows: result.entries
                      .map((e) => DataRow(cells: [
                    DataCell(Text(e.key)),
                    DataCell(Text(e.value)),
                  ]))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}