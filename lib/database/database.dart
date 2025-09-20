import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class GoldDatabaseHelper {
  static final GoldDatabaseHelper instance = GoldDatabaseHelper._init();
  static Database? _database;

  GoldDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gold_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE gold_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customerName TEXT,
      dryWeight REAL,
      wetWeight REAL,
      density TEXT,
      karat TEXT,
      purity TEXT,
      pureGold TEXT,
      timestamp TEXT
    )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add customerName column if upgrading from version 1
      await db.execute('ALTER TABLE gold_history ADD COLUMN customerName TEXT');
    }
  }

  Future<void> insertResult(Map<String, String> result, double dryWeight, double wetWeight, String customerName) async {
    final db = await instance.database;

    await db.insert('gold_history', {
      'customerName': customerName.isEmpty ? 'N/A' : customerName,
      'dryWeight': dryWeight,
      'wetWeight': wetWeight,
      'density': result['Density (g/cm³)'],
      'karat': result['Karat'],
      'purity': result['Purity (%)'],
      'pureGold': result['Pure Gold (g)'],
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchHistory() async {
    final db = await instance.database;
    return await db.query('gold_history', orderBy: 'timestamp DESC');
  }

  Future<void> deleteRecord(int id) async {
    final db = await instance.database;
    await db.delete('gold_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllHistory() async {
    final db = await instance.database;
    await db.delete('gold_history');
  }
}