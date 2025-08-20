import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/practice_type_model.dart';
import '../services/database_service.dart';
import '../models/check_in_model.dart';

class DailyPlanPage extends StatefulWidget {
  const DailyPlanPage({super.key});

  @override
  State<DailyPlanPage> createState() => _DailyPlanPageState();
}

class _DailyPlanPageState extends State<DailyPlanPage> {
  DateTime selectedDate = DateTime.now();
  List<PracticeType> allPracticeTypes = [];
  List<String> selectedPracticeTypes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 加载所有练习类型
      final types = await DatabaseService.getPracticeTypes();

      // 加载当前日期的计划
      final dailyPlan = await DatabaseService.getDailyPlan(selectedDate);

      setState(() {
        allPracticeTypes = types;
        selectedPracticeTypes = dailyPlan ?? [];
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

  Future<void> _saveDailyPlan() async {
    try {
      await DatabaseService.insertDailyPlan(
        selectedDate,
        selectedPracticeTypes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('每日计划保存成功'),
            backgroundColor: Colors.green,
          ),
        );

        // 刷新首页数据
        context.read<CheckInModel>().loadRecords();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateRandomPlan() async {
    if (allPracticeTypes.isEmpty) return;

    // 随机选择2-4个练习类型
    final random = DateTime.now().millisecondsSinceEpoch;
    final count = 2 + (random % 3); // 2-4个

    List<String> shuffled = allPracticeTypes.map((e) => e.type).toList();
    shuffled.shuffle();

    setState(() {
      selectedPracticeTypes = shuffled.take(count).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日计划'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: _generateRandomPlan,
            tooltip: '随机生成计划',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDailyPlan,
            tooltip: '保存计划',
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildDateSelector(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildPlanSummary(),
                        const SizedBox(height: 16),
                        _buildPracticeTypesList(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade600, Colors.blue.shade400],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.subtract(const Duration(days: 1));
              });
              _loadData();
            },
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                  });
                  _loadData();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.add(const Duration(days: 1));
              });
              _loadData();
            },
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.blueGrey.shade800
                  : Colors.blue.shade50,
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.blueGrey.shade700
                  : Colors.blue.shade100,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '今日计划',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedPracticeTypes.isEmpty)
              Text(
                '暂无计划，请选择练习类型',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedPracticeTypes.map((type) {
                  final practiceType = allPracticeTypes.firstWhere(
                    (pt) => pt.type == type,
                    orElse: () => PracticeType(
                      type: type,
                      icon: 'Icons.help',
                      // ignore: deprecated_member_use
                      color: Colors.grey.value,
                      description: '',
                      emoji: '📝',
                      subTypes: [],
                    ),
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color(practiceType.color).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(practiceType.color),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          practiceType.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          type,
                          style: TextStyle(
                            color: Color(practiceType.color),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeTypesList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.blueGrey.shade800
                  : Colors.grey.shade50,
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.blueGrey.shade700
                  : Colors.grey.shade100,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Colors.grey.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '选择练习类型',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...allPracticeTypes.map((practiceType) {
              final isSelected = selectedPracticeTypes.contains(
                practiceType.type,
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedPracticeTypes.remove(practiceType.type);
                        } else {
                          selectedPracticeTypes.add(practiceType.type);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(practiceType.color).withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Color(practiceType.color)
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(
                                practiceType.color,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                practiceType.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  practiceType.type,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Color(practiceType.color)
                                        : null,
                                  ),
                                ),
                                if (practiceType.description.isNotEmpty)
                                  Text(
                                    practiceType.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? Color(practiceType.color)
                                : Colors.grey.shade400,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
