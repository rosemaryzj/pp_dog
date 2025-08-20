import 'package:flutter/widgets.dart';
import '../services/database_service.dart';

class CheckInRecord {
  final int? id;
  final DateTime date;
  final String type;
  final String? subType; // 新增：子类型
  final String? note;
  final int? duration; // 新增：练习时长（分钟）
  final bool completed;
  final int? parentId; // 新增：父记录ID
  final String? imagePath; // 新增：图片路径

  CheckInRecord({
    this.id,
    required this.date,
    required this.type,
    this.subType,
    this.note,
    this.duration,
    required this.completed,
    this.parentId,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'type': type,
      'sub_type': subType,
      'note': note,
      'duration': duration,
      'completed': completed ? 1 : 0,
      'parent_id': parentId,
      'image_path': imagePath,
    };
  }

  factory CheckInRecord.fromMap(Map<String, dynamic> map) {
    return CheckInRecord(
      id: map['id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      type: map['type'],
      subType: map['sub_type'],
      note: map['note'],
      duration: map['duration'],
      completed: map['completed'] == 1,
      parentId: map['parent_id'],
      imagePath: map['image_path'],
    );
  }
}

class CheckInModel extends ChangeNotifier {
  List<CheckInRecord> _records = [];
  bool _isLoading = false;

  List<CheckInRecord> get records => _records;
  bool get isLoading => _isLoading;

  // 获取今日打卡记录
  CheckInRecord? getTodayRecord(String type, {String? subType}) {
    final today = DateTime.now();
    final todayRecords = _records.where((record) {
      return record.date.year == today.year &&
          record.date.month == today.month &&
          record.date.day == today.day &&
          record.type == type &&
          record.subType == subType;
    });
    return todayRecords.isNotEmpty ? todayRecords.first : null;
  }

  // 检查今日是否已打卡
  bool isTodayCheckedIn(String type, {String? subType}) {
    final todayRecord = getTodayRecord(type, subType: subType);
    return todayRecord?.completed ?? false;
  }

  // 添加打卡记录
  Future<void> addCheckIn(
    String type, {
    String? subType,
    String? note,
    int? duration,
    int? parentId,
    String? imagePath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final record = CheckInRecord(
        date: DateTime.now(),
        type: type,
        subType: subType,
        note: note,
        duration: duration,
        completed: true,
        parentId: parentId,
        imagePath: imagePath,
      );

      final id = await DatabaseService.insertCheckIn(record);
      final newRecord = CheckInRecord(
        id: id,
        date: record.date,
        type: record.type,
        subType: record.subType,
        note: record.note,
        duration: record.duration,
        completed: record.completed,
        parentId: record.parentId,
        imagePath: record.imagePath,
      );

      _records.add(newRecord);

      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 加载所有打卡记录
  Future<void> loadRecords() async {
    _isLoading = true;

    try {
      _records = await DatabaseService.getCheckInRecords();
      // 检查是否需要每日重置
      await _checkAndResetDaily();
    } finally {
      _isLoading = false;
    }

    // 延迟通知，避免在build过程中调用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 获取连续打卡天数
  int getStreakDays(String type, {String? subType}) {
    final now = DateTime.now();
    final typeRecords = _records
        .where(
          (record) =>
              record.type == type &&
              record.subType == subType &&
              record.completed,
        )
        .toList();

    typeRecords.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    for (final record in typeRecords) {
      final recordDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      if (recordDate.isAtSameMomentAs(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // 获取本月打卡天数
  int getMonthlyCheckIns(String type, {String? subType}) {
    final now = DateTime.now();
    return _records.where((record) {
      return record.type == type &&
          record.subType == subType &&
          record.completed &&
          record.date.year == now.year &&
          record.date.month == now.month;
    }).length;
  }

  // 获取子打卡记录
  List<CheckInRecord> getSubRecords(int parentId) {
    return _records.where((record) => record.parentId == parentId).toList();
  }

  // 获取特定日期的打卡记录
  List<CheckInRecord> getRecordsByDate(DateTime date) {
    return _records.where((record) {
      return record.date.year == date.year &&
          record.date.month == date.month &&
          record.date.day == date.day;
    }).toList();
  }

  // 获取特定子任务的所有打卡记录
  List<CheckInRecord> getCheckInsForSubtask(String subtaskName) {
    return _records.where((record) {
      return record.subType == subtaskName && record.completed;
    }).toList()..sort((a, b) => b.date.compareTo(a.date)); // 按时间倒序排列
  }

  // 获取特定月份的打卡记录
  List<CheckInRecord> getRecordsByMonth(int year, int month) {
    return _records.where((record) {
      return record.date.year == year && record.date.month == month;
    }).toList();
  }

  // 获取日历数据 - 返回每天的打卡状态
  Map<DateTime, List<CheckInRecord>> getCalendarData(int year, int month) {
    final Map<DateTime, List<CheckInRecord>> calendarData = {};
    final monthRecords = getRecordsByMonth(year, month);

    for (final record in monthRecords) {
      final dateKey = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      if (calendarData[dateKey] == null) {
        calendarData[dateKey] = [];
      }
      calendarData[dateKey]!.add(record);
    }

    return calendarData;
  }

  // 检查是否需要重置今日数据（新的一天开始）
  bool shouldResetToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 检查是否有今天的记录
    final todayRecords = getRecordsByDate(today);

    // 如果没有今天的记录，说明需要重置
    return todayRecords.isEmpty;
  }

  // 获取某天的打卡完成率
  double getDayCompletionRate(DateTime date) {
    final dayRecords = getRecordsByDate(date);
    if (dayRecords.isEmpty) return 0.0;

    final completedCount = dayRecords
        .where((record) => record.completed)
        .length;
    return completedCount / dayRecords.length;
  }

  // 获取某天已完成的打卡类型
  List<String> getCompletedTypesForDate(DateTime date) {
    final dayRecords = getRecordsByDate(date);
    return dayRecords
        .where((record) => record.completed)
        .map((record) => record.type)
        .toSet()
        .toList();
  }

  // 获取最近的打卡记录（用于统计）
  List<CheckInRecord> getRecentRecords({int days = 7}) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    return _records.where((record) {
      return record.date.isAfter(startDate) &&
          record.date.isBefore(now.add(const Duration(days: 1)));
    }).toList();
  }

  // 检查并执行每日重置
  Future<void> _checkAndResetDaily() async {
    // 移除自动初始化逻辑，只在实际打卡时创建记录
    // 这样可以避免创建大量未完成的记录
  }

  // 更新打卡记录
  Future<void> updateCheckIn(CheckInRecord record) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseService.updateCheckIn(record);

      // 更新本地记录
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = record;
      }

      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 删除打卡记录
  Future<void> deleteCheckIn(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseService.deleteCheckIn(id);

      // 从本地记录中移除
      _records.removeWhere((record) => record.id == id);

      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 手动触发每日重置（用于测试）
  Future<void> resetDaily() async {
    // 不再调用已删除的 _initializeDailyRecords 方法
    notifyListeners();
  }

  // 清理多余的打卡记录数据
  Future<void> cleanupExcessiveData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // 获取30天前的记录
      final oldRecords = _records.where((record) {
        return record.date.isBefore(thirtyDaysAgo);
      }).toList();

      // 删除30天前的记录
      for (final record in oldRecords) {
        if (record.id != null) {
          await DatabaseService.deleteCheckIn(record.id!);
          _records.removeWhere((r) => r.id == record.id);
        }
      }

      // 清理重复的记录（同一天同一类型的多个记录，只保留最新的）
      final Map<String, CheckInRecord> latestRecords = {};
      final recordsToDelete = <CheckInRecord>[];

      for (final record in _records) {
        final key =
            '${record.date.year}-${record.date.month}-${record.date.day}-${record.type}-${record.subType ?? ""}';

        if (latestRecords.containsKey(key)) {
          final existing = latestRecords[key]!;
          if (record.date.isAfter(existing.date)) {
            // 当前记录更新，删除旧记录
            recordsToDelete.add(existing);
            latestRecords[key] = record;
          } else {
            // 现有记录更新，删除当前记录
            recordsToDelete.add(record);
          }
        } else {
          latestRecords[key] = record;
        }
      }

      // 删除重复记录
      for (final record in recordsToDelete) {
        if (record.id != null) {
          await DatabaseService.deleteCheckIn(record.id!);
          _records.removeWhere((r) => r.id == record.id);
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
