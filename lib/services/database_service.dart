import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/check_in_model.dart';
import '../models/practice_type_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'check_in.db';
  static const int _databaseVersion = 5; // 版本号+1

  static const String _tableCheckIn = 'check_in_records';
  static const String _tablePracticeTypes = 'practice_types';
  static const String _tableDailyPlans = 'daily_plans';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableCheckIn (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        type TEXT NOT NULL,
        sub_type TEXT,
        note TEXT,
        duration INTEGER,
        completed INTEGER NOT NULL,
        parent_id INTEGER,
        image_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tablePracticeTypes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL UNIQUE,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        description TEXT,
        emoji TEXT NOT NULL,
        sub_types TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tableDailyPlans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL UNIQUE,
        practice_types TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // 插入默认练习类型
    await _insertDefaultPracticeTypes(db);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $_tableCheckIn ADD COLUMN sub_type TEXT');
      await db.execute(
        'ALTER TABLE $_tableCheckIn ADD COLUMN duration INTEGER',
      );
      await db.execute(
        'ALTER TABLE $_tableCheckIn ADD COLUMN parent_id INTEGER',
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE $_tablePracticeTypes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL UNIQUE,
          icon TEXT NOT NULL,
          color INTEGER NOT NULL,
          description TEXT,
          emoji TEXT NOT NULL,
          sub_types TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      await _insertDefaultPracticeTypes(db);
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE $_tableDailyPlans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date INTEGER NOT NULL UNIQUE,
          practice_types TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE $_tableCheckIn ADD COLUMN image_path TEXT');
    }
  }

  static Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    final List<Map<String, dynamic>> checkInRecords =
        await db.query(_tableCheckIn);
    final List<Map<String, dynamic>> practiceTypes =
        await db.query(_tablePracticeTypes);
    final List<Map<String, dynamic>> dailyPlans =
        await db.query(_tableDailyPlans);

    // 获取主题设置
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? true;

    return {
      'check_in_records': checkInRecords,
      'practice_types': practiceTypes,
      'daily_plans': dailyPlans,
      'settings': {'isDarkMode': isDarkMode},
    };
  }

  static Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_tableCheckIn);
      await txn.delete(_tablePracticeTypes);
      await txn.delete(_tableDailyPlans);
  
      for (var record in data['check_in_records']) {
        await txn.insert(_tableCheckIn, record, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var type in data['practice_types']) {
        await txn.insert(_tablePracticeTypes, type, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var plan in data['daily_plans']) {
        await txn.insert(_tableDailyPlans, plan, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  
    // 恢复主题设置
    if (data.containsKey('settings')) {
      final settings = data['settings'] as Map<String, dynamic>;
      if (settings.containsKey('isDarkMode')) {
        final isDarkMode = settings['isDarkMode'] as bool;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isDarkMode', isDarkMode);
      }
    }
  }

  static Future<void> initialize() async {
    await database;
  }

  static Future<int> insertCheckIn(CheckInRecord record) async {
    final db = await database;
    final result = await db.insert(_tableCheckIn, record.toMap());
    // 自动备份
    await autoBackup();
    return result;
  }

  static Future<List<CheckInRecord>> getCheckInRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableCheckIn,
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return CheckInRecord.fromMap(maps[i]);
    });
  }

  static Future<List<CheckInRecord>> getCheckInRecordsByType(
    String type,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableCheckIn,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return CheckInRecord.fromMap(maps[i]);
    });
  }

  static Future<List<CheckInRecord>> getCheckInRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableCheckIn,
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return CheckInRecord.fromMap(maps[i]);
    });
  }

  static Future<int> updateCheckIn(CheckInRecord record) async {
    final db = await database;
    final result = await db.update(
      _tableCheckIn,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    // 自动备份
    await autoBackup();
    return result;
  }

  static Future<int> deleteCheckIn(int id) async {
    final db = await database;
    final result = await db.delete(
      _tableCheckIn,
      where: 'id = ?',
      whereArgs: [id],
    );
    // 自动备份
    await autoBackup();
    return result;
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // 插入默认练习类型
  static Future<void> _insertDefaultPracticeTypes(Database db) async {
    final defaultTypes = [
      {
        'type': '数学',
        'icon': 'Icons.calculate',
        'color': 0xFF2196F3, // Colors.blue
        'description': '数学练习',
        'emoji': '🔢',
        'sub_types': jsonEncode(['口算', '应用题', '几何']),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'type': '语文',
        'icon': 'Icons.menu_book',
        'color': 0xFF4CAF50, // Colors.green
        'description': '语文练习',
        'emoji': '📚',
        'sub_types': jsonEncode(['阅读', '练字', '背诵']),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'type': '英语',
        'icon': 'Icons.language',
        'color': 0xFFFF9800, // Colors.orange
        'description': '英语练习',
        'emoji': '🌍',
        'sub_types': jsonEncode(['单词', '听力', '对话']),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    ];

    for (var type in defaultTypes) {
      await db.insert(_tablePracticeTypes, type);
    }
  }

  // 练习类型相关操作
  static Future<int> insertPracticeType(PracticeType practiceType) async {
    final db = await database;
    return await db.insert(_tablePracticeTypes, practiceType.toMap());
  }

  static Future<List<PracticeType>> getPracticeTypes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tablePracticeTypes,
      orderBy: 'created_at ASC',
    );

    return List.generate(maps.length, (i) {
      return PracticeType.fromMap(maps[i]);
    });
  }

  static Future<int> updatePracticeType(PracticeType practiceType) async {
    final db = await database;
    return await db.update(
      _tablePracticeTypes,
      practiceType.toMap(),
      where: 'id = ?',
      whereArgs: [practiceType.id],
    );
  }

  static Future<int> deletePracticeType(int id) async {
    final db = await database;
    return await db.delete(
      _tablePracticeTypes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 每日计划相关操作
  static Future<int> insertDailyPlan(
    DateTime date,
    List<String> practiceTypes,
  ) async {
    final db = await database;
    final dateKey = DateTime(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch;

    return await db.insert(_tableDailyPlans, {
      'date': dateKey,
      'practice_types': jsonEncode(practiceTypes),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<String>?> getDailyPlan(DateTime date) async {
    final db = await database;
    final dateKey = DateTime(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      _tableDailyPlans,
      where: 'date = ?',
      whereArgs: [dateKey],
    );

    if (maps.isEmpty) {
      return null;
    }

    final practiceTypesJson = maps.first['practice_types'] as String;
    return List<String>.from(jsonDecode(practiceTypesJson));
  }

  static Future<Map<DateTime, List<String>>> getDailyPlansInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final startKey = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ).millisecondsSinceEpoch;
    final endKey = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      _tableDailyPlans,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startKey, endKey],
      orderBy: 'date ASC',
    );

    Map<DateTime, List<String>> result = {};
    for (var map in maps) {
      final date = DateTime.fromMillisecondsSinceEpoch(map['date']);
      final practiceTypesJson = map['practice_types'] as String;
      final practiceTypes = List<String>.from(jsonDecode(practiceTypesJson));
      result[date] = practiceTypes;
    }

    return result;
  }

  static Future<int> deleteDailyPlan(DateTime date) async {
    final db = await database;
    final dateKey = DateTime(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch;

    return await db.delete(
      _tableDailyPlans,
      where: 'date = ?',
      whereArgs: [dateKey],
    );
  }

  // 数据备份功能
  static Future<String?> backupData() async {
    try {
      final db = await database;

      // 获取所有表的数据
      final checkInRecords = await db.query(_tableCheckIn);
      final practiceTypes = await db.query(_tablePracticeTypes);
      final dailyPlans = await db.query(_tableDailyPlans);

      // 创建备份数据结构
      final backupData = {
        'version': _databaseVersion,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'check_in_records': checkInRecords,
        'practice_types': practiceTypes,
        'daily_plans': dailyPlans,
      };

      // 转换为JSON字符串
      final jsonString = jsonEncode(backupData);

      // 保存到SharedPreferences作为自动备份
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('data_backup', jsonString);
      await prefs.setInt(
        'backup_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      return jsonString;
    } catch (e) {
      return null;
    }
  }

  // 数据恢复功能
  static Future<bool> restoreData(String backupJson) async {
    try {
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;
      final db = await database;

      // 开始事务
      await db.transaction((txn) async {
        // 清空现有数据
        await txn.delete(_tableCheckIn);
        await txn.delete(_tablePracticeTypes);
        await txn.delete(_tableDailyPlans);

        // 恢复打卡记录
        final checkInRecords = backupData['check_in_records'] as List<dynamic>;
        for (final record in checkInRecords) {
          await txn.insert(_tableCheckIn, Map<String, dynamic>.from(record));
        }

        // 恢复练习类型
        final practiceTypes = backupData['practice_types'] as List<dynamic>;
        for (final type in practiceTypes) {
          await txn.insert(
            _tablePracticeTypes,
            Map<String, dynamic>.from(type),
          );
        }

        // 恢复每日计划
        final dailyPlans = backupData['daily_plans'] as List<dynamic>;
        for (final plan in dailyPlans) {
          await txn.insert(_tableDailyPlans, Map<String, dynamic>.from(plan));
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // 从SharedPreferences恢复自动备份
  static Future<bool> restoreFromAutoBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupJson = prefs.getString('data_backup');

      if (backupJson != null) {
        return await restoreData(backupJson);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // 获取备份信息
  static Future<Map<String, dynamic>?> getBackupInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('backup_timestamp');

      if (timestamp != null) {
        return {
          'timestamp': timestamp,
          'date': DateTime.fromMillisecondsSinceEpoch(timestamp),
          'hasBackup': true,
        };
      }

      return {'hasBackup': false};
    } catch (e) {
      return {'hasBackup': false};
    }
  }

  // 自动备份（在每次数据变更后调用）
  static Future<void> autoBackup() async {
    await backupData();
  }
}
