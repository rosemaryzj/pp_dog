import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsCacheService {
  static const String _weeklyActivityKey = 'weekly_activity_cache';
  static const String _averageActivityKey = 'average_activity_cache';
  static const String _streakDataKey = 'streak_data_cache';
  static const String _lastUpdateKey = 'statistics_last_update';

  static StatisticsCacheService? _instance;
  static StatisticsCacheService get instance {
    _instance ??= StatisticsCacheService._internal();
    return _instance!;
  }

  StatisticsCacheService._internal();

  // 缓存每日活跃度数据
  Future<void> cacheWeeklyActivity(List<double> weeklyData) async {
    final prefs = await SharedPreferences.getInstance();
    final dataMap = {
      'data': weeklyData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_weeklyActivityKey, jsonEncode(dataMap));
  }

  // 获取缓存的每日活跃度数据
  Future<List<double>?> getCachedWeeklyActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_weeklyActivityKey);
    if (cachedData != null) {
      try {
        final dataMap = jsonDecode(cachedData);
        final timestamp = dataMap['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;

        // 如果缓存超过1小时，则认为过期
        if (now - timestamp < 3600000) {
          return List<double>.from(dataMap['data']);
        }
      } catch (e) {
        debugPrint('Error parsing cached weekly activity: $e');
      }
    }
    return null;
  }

  // 缓存平均活跃度数据
  Future<void> cacheAverageActivity(double avgActivity) async {
    final prefs = await SharedPreferences.getInstance();
    final dataMap = {
      'average': avgActivity,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_averageActivityKey, jsonEncode(dataMap));
  }

  // 获取缓存的平均活跃度
  Future<double?> getCachedAverageActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_averageActivityKey);
    if (cachedData != null) {
      try {
        final dataMap = jsonDecode(cachedData);
        final timestamp = dataMap['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;

        // 如果缓存超过1小时，则认为过期
        if (now - timestamp < 3600000) {
          return dataMap['average'] as double;
        }
      } catch (e) {
        debugPrint('Error parsing cached average activity: $e');
      }
    }
    return null;
  }

  // 缓存连续打卡数据
  Future<void> cacheStreakData(Map<String, dynamic> streakData) async {
    final prefs = await SharedPreferences.getInstance();
    final dataMap = {
      'streakData': streakData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_streakDataKey, jsonEncode(dataMap));
  }

  // 获取缓存的连续打卡数据
  Future<Map<String, dynamic>?> getCachedStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_streakDataKey);
    if (cachedData != null) {
      try {
        final dataMap = jsonDecode(cachedData);
        final timestamp = dataMap['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;

        // 如果缓存超过30分钟，则认为过期
        if (now - timestamp < 1800000) {
          return Map<String, dynamic>.from(dataMap['streakData']);
        }
      } catch (e) {
        debugPrint('Error parsing cached streak data: $e');
      }
    }
    return null;
  }

  // 记录最后更新时间
  Future<void> updateLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  // 获取最后更新时间
  Future<DateTime?> getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastUpdateKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // 清除所有缓存
  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_weeklyActivityKey);
    await prefs.remove(_averageActivityKey);
    await prefs.remove(_streakDataKey);
    await prefs.remove(_lastUpdateKey);
  }

  // 检查是否需要更新缓存
  Future<bool> shouldUpdateCache() async {
    final lastUpdate = await getLastUpdateTime();
    if (lastUpdate == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    // 如果超过1小时未更新，则需要更新
    return difference.inHours >= 1;
  }
}
