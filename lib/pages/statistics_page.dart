import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/check_in_model.dart';
import '../models/practice_type_model.dart';
import '../services/database_service.dart';
import '../services/statistics_cache_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  List<PracticeType> practiceTypes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPracticeTypes();
  }

  // 计算整体连续打卡天数
  int _calculateOverallStreak(CheckInModel model) {
    final now = DateTime.now();
    int streak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    while (true) {
      // 检查这一天是否有任何类型的打卡记录
      final dayRecords = model.getRecordsByDate(checkDate);
      final hasCompletedRecord = dayRecords.any((record) => record.completed);

      if (hasCompletedRecord) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Widget _buildStreakCard(CheckInModel model) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 计算整体连续打卡天数（任意类型打卡都算）
    int maxStreak = _calculateOverallStreak(model);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: const Color(0xFF2C2C2E), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isDark ? 8 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: .2)
                      : Colors.orange.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_fire_department,
                  color: isDark ? Colors.white : Colors.orange.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '连续打卡',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$maxStreak',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '天',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up, 
                  color: isDark ? Colors.white : Colors.orange.shade600, 
                  size: 16
                ),
                const SizedBox(width: 8),
                Text(
                  maxStreak > 0 ? '保持良好习惯！' : '开始你的打卡之旅',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.orange.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPracticeTypes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final types = await DatabaseService.getPracticeTypes();
      setState(() {
        practiceTypes = types;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载数据失败: $e')));
      }
    }
  }

  IconData _getIconData(String iconString) {
    switch (iconString) {
      case 'book':
        return Icons.book;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'music_note':
        return Icons.music_note;
      case 'palette':
        return Icons.palette;
      case 'code':
        return Icons.code;
      case 'language':
        return Icons.language;
      case 'calculate':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      body: SafeArea(
        child: Consumer<CheckInModel>(
          builder: (context, model, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStreakCard(model),
                const SizedBox(height: 24),
                _buildOverallStats(model),
                const SizedBox(height: 24),
                _buildWeeklyActivity(model),
                const SizedBox(height: 24),
                _buildSubjectStats(model),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverallStats(CheckInModel model) {
    // 计算总打卡次数
    int totalCheckIns = model.records
        .where((record) => record.completed)
        .length;

    // 计算最长连续打卡天数
    int maxStreak = _calculateOverallStreak(model);

    // 计算本月完成次数
    final now = DateTime.now();
    int monthlyCount = model.records
        .where(
          (record) =>
              record.completed &&
              record.date.year == now.year &&
              record.date.month == now.month,
        )
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            '总打卡次数',
            '$totalCheckIns',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            '最长连续',
            '$maxStreak天',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            '本月完成',
            '$monthlyCount次',
            Icons.calendar_today,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: const Color(0xFF2C2C2E), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isDark ? 8 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivity(CheckInModel model) {
    final List<String> weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return FutureBuilder<List<double>>(
      future: _getWeeklyActivityData(model),
      builder: (context, snapshot) {
        final List<double> weeklyData = snapshot.data ?? List.filled(7, 0.0);

        // 计算平均活跃度
        final avgActivity = weeklyData.isNotEmpty
            ? weeklyData.reduce((a, b) => a + b) / weeklyData.length
            : 0.0;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? Border.all(color: const Color(0xFF2C2C2E), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: isDark ? 8 : 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.show_chart,
                      color: isDark
                          ? Colors.purple.shade400
                          : Colors.blue.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '最近7天活跃度',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 活跃度条形图
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final height = (weeklyData[index] * 60).clamp(4.0, 60.0);
                    final isToday = index == 6;
                    return Column(
                      children: [
                        Container(
                          width: 24,
                          height: height,
                          decoration: BoxDecoration(
                            color: isToday
                                ? (isDark
                                      ? Colors.purple.shade500
                                      : Colors.blue.shade600)
                                : weeklyData[index] > 0.5
                                ? Colors.green.shade400
                                : (isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weekDays[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: isToday
                                ? (isDark
                                      ? Colors.purple.shade400
                                      : Colors.blue.shade600)
                                : (isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600),
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '平均活跃度',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${(avgActivity * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: avgActivity > 0.7
                            ? Colors.green
                            : avgActivity > 0.4
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  avgActivity > 0.7
                      ? '表现优秀！保持下去 🎉'
                      : avgActivity > 0.4
                      ? '还不错，可以更努力一些 💪'
                      : '需要加油了！ 🚀',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 获取每周活跃度数据（带缓存）
  Future<List<double>> _getWeeklyActivityData(CheckInModel model) async {
    final cacheService = StatisticsCacheService.instance;

    // 尝试从缓存获取数据
    final cachedData = await cacheService.getCachedWeeklyActivity();
    if (cachedData != null) {
      return cachedData;
    }

    // 计算新的数据
    final now = DateTime.now();
    final List<double> weeklyData = [];

    for (int i = 6; i >= 0; i--) {
      final checkDate = now.subtract(Duration(days: i));
      final dayRecords = model.records
          .where(
            (record) =>
                record.completed &&
                record.date.year == checkDate.year &&
                record.date.month == checkDate.month &&
                record.date.day == checkDate.day,
          )
          .toList();

      final completedTypes = dayRecords.map((r) => r.type).toSet();
      final completionRate = practiceTypes.isNotEmpty
          ? completedTypes.length / practiceTypes.length
          : 0.0;
      weeklyData.add(completionRate);
    }

    // 缓存数据
    await cacheService.cacheWeeklyActivity(weeklyData);

    return weeklyData;
  }

  // 计算特定类型的连续打卡天数
  int _calculateTypeStreak(CheckInModel model, String type) {
    final now = DateTime.now();
    int streak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    while (true) {
      final dayRecords = model.getRecordsByDate(checkDate);
      final hasCompletedRecord = dayRecords.any(
        (record) => record.type == type && record.completed,
      );

      if (hasCompletedRecord) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Widget _buildSubjectStats(CheckInModel model) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: const Color(0xFF2C2C2E), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isDark ? 8 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: isDark
                      ? Colors.purple.shade400
                      : Colors.purple.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '科目统计',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...practiceTypes.map((type) {
              final typeRecords = model.records
                  .where(
                    (record) => record.type == type.type && record.completed,
                  )
                  .toList();
              final streak = _calculateTypeStreak(model, type.type);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(type.color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconData(type.icon),
                        color: Color(type.color),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.type,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '总计 ${typeRecords.length} 次',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$streak',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(type.color),
                          ),
                        ),
                        Text(
                          '连续天数',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
