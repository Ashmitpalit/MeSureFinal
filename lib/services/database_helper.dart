import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/health_metric.dart';
import '../models/medication.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ppg_app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Health metrics table
    await db.execute('''
      CREATE TABLE health_metrics(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        secondary_value TEXT,
        timestamp TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Medications table
    await db.execute('''
      CREATE TABLE medications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        reminder_times TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Medication logs table (for tracking when medications were taken)
    await db.execute('''
      CREATE TABLE medication_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        taken_at TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (medication_id) REFERENCES medications (id)
      )
    ''');
  }

  // Health Metrics CRUD operations
  Future<int> insertHealthMetric(HealthMetric metric) async {
    final db = await database;
    // Remove the id from the map to let SQLite auto-generate it
    final map = metric.toMap();
    map.remove('id');
    return await db.insert('health_metrics', map);
  }

  Future<List<HealthMetric>> getHealthMetrics({
    String? type,
    int? limit,
  }) async {
    final db = await database;
    String query = 'SELECT * FROM health_metrics';
    List<dynamic> whereArgs = [];

    if (type != null) {
      query += ' WHERE type = ?';
      whereArgs.add(type);
    }

    query += ' ORDER BY timestamp DESC';

    if (limit != null) {
      query += ' LIMIT ?';
      whereArgs.add(limit);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);
    return List.generate(maps.length, (i) => HealthMetric.fromMap(maps[i]));
  }

  Future<HealthMetric?> getLatestHealthMetric(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'health_metrics',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return HealthMetric.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteHealthMetric(int id) async {
    final db = await database;
    return await db.delete('health_metrics', where: 'id = ?', whereArgs: [id]);
  }

  // Medications CRUD operations
  Future<int> insertMedication(Medication medication) async {
    final db = await database;
    return await db.insert('medications', medication.toMap());
  }

  Future<List<Medication>> getMedications({bool? activeOnly}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (activeOnly == true) {
      whereClause = 'WHERE is_active = 1';
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM medications $whereClause ORDER BY name',
      whereArgs,
    );
    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  Future<Medication?> getMedication(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Medication.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateMedication(Medication medication) async {
    final db = await database;
    return await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> deleteMedication(int id) async {
    final db = await database;
    return await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  // Medication logs
  Future<int> logMedicationTaken(int medicationId, {String? notes}) async {
    final db = await database;
    return await db.insert('medication_logs', {
      'medication_id': medicationId,
      'taken_at': DateTime.now().toIso8601String(),
      'notes': notes,
    });
  }

  Future<List<Map<String, dynamic>>> getMedicationLogs(
    int medicationId, {
    int? days,
  }) async {
    final db = await database;
    String query = '''
      SELECT ml.*, m.name as medication_name 
      FROM medication_logs ml 
      JOIN medications m ON ml.medication_id = m.id 
      WHERE ml.medication_id = ?
    ''';
    List<dynamic> whereArgs = [medicationId];

    if (days != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      query += ' AND ml.taken_at >= ?';
      whereArgs.add(cutoffDate.toIso8601String());
    }

    query += ' ORDER BY ml.taken_at DESC';

    return await db.rawQuery(query, whereArgs);
  }
}
