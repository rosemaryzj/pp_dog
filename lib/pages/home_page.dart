import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/check_in_model.dart';
import '../models/practice_type_model.dart';
import '../services/database_service.dart';
import 'daily_plan_page.dart';
import 'practice_type_management_page.dart';

class HomePage extends StatefulWidget {
  final Function(int) onNavigate;
  const HomePage({super.key, required this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<PracticeType> practiceTypes = [];
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
      // 获取今日的每日计划
      final today = DateTime.now();
      final dailyPlanTypes = await DatabaseService.getDailyPlan(today);

      if (dailyPlanTypes != null && dailyPlanTypes.isNotEmpty) {
        // 如果有每日计划，只显示计划中的练习类型
        final allTypes = await DatabaseService.getPracticeTypes();
        final filteredTypes = allTypes
            .where((type) => dailyPlanTypes.contains(type.type))
            .toList();

        setState(() {
          practiceTypes = filteredTypes;
          isLoading = false;
        });
      } else {
        // 如果没有每日计划，显示所有练习类型
        final types = await DatabaseService.getPracticeTypes();

        setState(() {
          practiceTypes = types;
          isLoading = false;
        });
      }

      if (mounted) {
        context.read<CheckInModel>().loadRecords();
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: '制定每日练习计划',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DailyPlanPage()),
              ).then((_) => _loadData()); // 返回后刷新数据
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '练习类型管理',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PracticeTypeManagementPage(),
                ),
              ).then((_) => _loadData()); // 返回后刷新数据
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Consumer<CheckInModel>(
              builder: (context, model, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),
                    _buildPracticeTypesSection(model),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
              : [Colors.blue.shade400, Colors.purple.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.blue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pets, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今日练习',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '坚持每一天，成就更好的自己',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeTypesSection(CheckInModel model) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (practiceTypes.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                '暂无练习类型',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '请先添加练习类型',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2C2C2E)
                  : Colors.grey.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              ...practiceTypes.map(
                (type) => _buildPracticeTypeCard(
                  type,
                  model.isTodayCheckedIn(type.type),
                  model,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeTypeCard(
    PracticeType type,
    bool isCompleted,
    CheckInModel model,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getSubtasksForType(type, model),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        List<Map<String, dynamic>> subtasks = snapshot.data!;

        return _buildPracticeTypeCardContent(
          type,
          isCompleted,
          model,
          subtasks,
        );
      },
    );
  }

  Widget _buildPracticeTypeCardContent(
    PracticeType type,
    bool isCompleted,
    CheckInModel model,
    List<Map<String, dynamic>> subtasks,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主练习类型
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.school,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  type.type,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 子任务列表
          ...subtasks.map((subtask) => _buildSubtaskItem(subtask, model)),
        ],
      ),
    );
  }

  Widget _buildSubtaskItem(Map<String, dynamic> subtask, CheckInModel model) {
    final bool isCompleted = subtask['completed'];
    final String subtaskName = subtask['name'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted
            ? (isDark
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : const Color(0xFF10B981).withValues(alpha: 0.1))
            : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: isCompleted
            ? Border.all(color: const Color(0xFF10B981), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? const Color(0xFF10B981) : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtaskName,
              style: TextStyle(
                fontSize: 14,
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (!isCompleted)
            TextButton(
              onPressed: () => _showCheckInDialog(subtaskName),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('打卡', style: TextStyle(fontSize: 12)),
            ),
          if (isCompleted)
            TextButton(
              onPressed: () => _showCheckInHistory(subtaskName),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('查看', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getSubtasksForType(
    PracticeType type,
    CheckInModel model,
  ) async {
    try {
      return type.subTypes
          .map(
            (subtask) => {
              'name': subtask,
              'completed': model.isTodayCheckedIn(type.type, subType: subtask),
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  void _showCheckInDialog(String subtaskName) async {
    final TextEditingController durationController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    File? selectedImage;
    final ImagePicker picker = ImagePicker();

    // 从子任务名称推断主练习类型
    String mainType = await _getMainTypeFromSubtask(subtaskName);

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Text('完成$subtaskName'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('恭喜你完成了$subtaskName！'),
                const SizedBox(height: 16),
                const Text(
                  '练习时长（分钟）：',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '请输入练习时长',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '上传图片：',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 80,
                        );
                        if (image != null) {
                          setDialogState(() {
                            selectedImage = File(image.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text('拍照'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 80,
                        );
                        if (image != null) {
                          setDialogState(() {
                            selectedImage = File(image.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: const Text('相册'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                if (selectedImage != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () =>
                        _showFullScreenImage(context, selectedImage!.path),
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedImage = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  '练习心得：',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '记录一下今天的学习感受吧...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final model = Provider.of<CheckInModel>(context, listen: false);

                try {
                  // 保存图片到应用目录
                  String? imagePath;
                  if (selectedImage != null) {
                    final directory = await getApplicationDocumentsDirectory();
                    final fileName =
                        'checkin_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final savedImage = await selectedImage!.copy(
                      '${directory.path}/$fileName',
                    );
                    imagePath = savedImage.path;
                  }

                  await model.addCheckIn(
                    mainType,
                    subType: subtaskName,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                    duration: durationController.text.trim().isEmpty
                        ? null
                        : int.tryParse(durationController.text.trim()),
                    imagePath: imagePath,
                  );

                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  // 刷新界面以更新按钮状态
                  if (mounted) {
                    setState(() {});
                  }

                  // 显示成功动画
                  // ignore: use_build_context_synchronously
                  _showSuccessAnimation(context, subtaskName);
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('打卡失败：$e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('确认打卡'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckInHistory(String subtaskName) async {
    final model = Provider.of<CheckInModel>(context, listen: false);
    final checkIns = model.getCheckInsForSubtask(subtaskName);

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.history, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text('$subtaskName 打卡记录'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: checkIns.isEmpty
              ? const Center(
                  child: Text(
                    '暂无打卡记录',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: checkIns.length,
                  itemBuilder: (context, index) {
                    final checkIn = checkIns[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${checkIn.date.month}月${checkIn.date.day}日',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const Spacer(),
                                if (checkIn.duration != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${checkIn.duration}分钟',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (checkIn.imagePath != null) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _showFullScreenImage(
                                  context,
                                  checkIn.imagePath!,
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(checkIn.imagePath!),
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.zoom_in,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (checkIn.note != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                checkIn.note!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showSuccessAnimation(BuildContext context, String taskName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                Text(
                  '🎉 打卡成功！',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$taskName已完成',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('继续加油！'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _getMainTypeFromSubtask(String subtaskName) async {
    final prefs = await SharedPreferences.getInstance();

    // 检查每个主类型的子任务列表
    List<String> mainTypes = ['语文', '数学', '英语'];

    for (String mainType in mainTypes) {
      List<String> subtasks = prefs.getStringList('${mainType}_subtasks') ?? [];
      if (subtasks.contains(subtaskName)) {
        return mainType;
      }
    }

    // 如果没找到，使用默认映射
    Map<String, String> defaultMapping = {
      '阅读': '语文',
      '练字': '语文',
      '背诵': '语文',
      '口算': '数学',
      '应用题': '数学',
      '几何': '数学',
      '单词': '英语',
      '听力': '英语',
      '对话': '英语',
    };

    return defaultMapping[subtaskName] ?? '其他';
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // 背景点击关闭
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withValues(alpha: 0.9),
                ),
              ),
              // 图片查看器
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '图片加载失败',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // 关闭按钮
              Positioned(
                top: 50,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
