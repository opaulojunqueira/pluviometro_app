import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/rain_record.dart';
import '../models/saved_report.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pluviometro.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rain_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        millimeters REAL NOT NULL,
        observation TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        generated_at TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS saved_reports (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          generated_at TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_name TEXT NOT NULL
        )
      ''');
    }
  }

  // ==================== SAVED REPORTS ====================

  // CREATE Report
  Future<SavedReport> createReport(SavedReport report) async {
    final db = await database;
    final id = await db.insert('saved_reports', report.toMap());
    return report.copyWith(id: id);
  }

  // READ - Get all reports
  Future<List<SavedReport>> getAllReports() async {
    final db = await database;
    final result = await db.query(
      'saved_reports',
      orderBy: 'generated_at DESC',
    );
    return result.map((map) => SavedReport.fromMap(map)).toList();
  }

  // DELETE Report
  Future<int> deleteReport(int id) async {
    final db = await database;
    return await db.delete('saved_reports', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== RAIN RECORDS ====================

  // CREATE
  Future<RainRecord> createRecord(RainRecord record) async {
    final db = await database;
    final id = await db.insert('rain_records', record.toMap());
    return record.copyWith(id: id);
  }

  // READ - Get all records
  Future<List<RainRecord>> getAllRecords() async {
    final db = await database;
    final result = await db.query('rain_records', orderBy: 'date DESC');
    return result.map((map) => RainRecord.fromMap(map)).toList();
  }

  // READ - Get recent records with limit (efficient for dashboard)
  Future<List<RainRecord>> getRecentRecords(int limit) async {
    final db = await database;
    final result = await db.query(
      'rain_records',
      orderBy: 'date DESC',
      limit: limit,
    );
    return result.map((map) => RainRecord.fromMap(map)).toList();
  }

  // READ - Get total mm by year (efficient, no full load)
  Future<double> getTotalMmByYear(int year) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(millimeters) as total FROM rain_records WHERE date LIKE ?",
      ['$year%'],
    );
    if (result.isEmpty || result.first['total'] == null) return 0.0;
    return (result.first['total'] as num).toDouble();
  }

  // READ - Get monthly totals for the last N months (for bar chart)
  Future<Map<String, double>> getMonthlyTotals(int monthsBack) async {
    final db = await database;
    final Map<String, double> totals = {};
    final now = DateTime.now();

    for (int i = monthsBack - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final year = date.year;
      final month = date.month.toString().padLeft(2, '0');
      final key = '$year-$month';

      final result = await db.rawQuery(
        "SELECT SUM(millimeters) as total FROM rain_records WHERE date LIKE ?",
        ['$year-$month%'],
      );
      final val = result.isEmpty || result.first['total'] == null
          ? 0.0
          : (result.first['total'] as num).toDouble();
      totals[key] = val;
    }
    return totals;
  }

  // READ - Get record by id
  Future<RainRecord?> getRecordById(int id) async {
    final db = await database;
    final result = await db.query(
      'rain_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return RainRecord.fromMap(result.first);
  }

  // READ - Get records by date
  Future<List<RainRecord>> getRecordsByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final result = await db.query(
      'rain_records',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => RainRecord.fromMap(map)).toList();
  }

  // READ - Get records by month
  Future<List<RainRecord>> getRecordsByMonth(int year, int month) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final result = await db.query(
      'rain_records',
      where: 'date LIKE ?',
      whereArgs: ['$year-$monthStr%'],
      orderBy: 'date DESC',
    );
    return result.map((map) => RainRecord.fromMap(map)).toList();
  }

  // READ - Get records by date range
  Future<List<RainRecord>> getRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];
    final result = await db.query(
      'rain_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date ASC',
    );
    return result.map((map) => RainRecord.fromMap(map)).toList();
  }

  // READ - Get total mm by month
  Future<double> getTotalMmByMonth(int year, int month) async {
    final records = await getRecordsByMonth(year, month);
    return records.fold<double>(
      0.0,
      (double sum, record) => sum + record.millimeters,
    );
  }

  // READ - Get records with rain for calendar markers
  Future<Map<DateTime, List<RainRecord>>> getRecordsMap() async {
    final records = await getAllRecords();
    final Map<DateTime, List<RainRecord>> recordsMap = {};

    for (var record in records) {
      final dateKey = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      if (recordsMap[dateKey] == null) {
        recordsMap[dateKey] = [];
      }
      recordsMap[dateKey]!.add(record);
    }

    return recordsMap;
  }

  // UPDATE
  Future<int> updateRecord(RainRecord record) async {
    final db = await database;
    return await db.update(
      'rain_records',
      record.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  // DELETE
  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete('rain_records', where: 'id = ?', whereArgs: [id]);
  }

  // DELETE all records
  Future<int> deleteAllRecords() async {
    final db = await database;
    return await db.delete('rain_records');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
