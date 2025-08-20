import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/check_in_model.dart';

class SubtaskManagementPage extends StatefulWidget {
  final String parentType;
  final String? parentSubType;
  final int? parentId;

  const SubtaskManagementPage({
    super.key,
    required this.parentType,
    this.parentSubType,
    this.parentId,
  });

  @override
  State<SubtaskManagementPage> createState() => _SubtaskManagementPageState();
}

class _SubtaskManagementPageState extends State<SubtaskManagementPage> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  List<Map<String, dynamic>> _subtasks = [];

  @override
  void initState() {
    super.initState();
    _loadSubtasks();
  }

  void _loadSubtasks() {
    if (widget.parentId != null) {
      final model = context.read<CheckInModel>();
      final subRecords = model.getSubRecords(widget.parentId!);
      if (mounted) {
        setState(() {
          _subtasks = subRecords
              .map(
                (record) => {
                  'id': record.id,
                  'name': record.subType ?? '未命名任务',
                  'note': record.note ?? '',
                  'duration': record.duration ?? 0,
                  'completed': record.completed,
                },
              )
              .toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.parentType} - 子任务管理'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _subtasks.isEmpty ? _buildEmptyState() : _buildSubtaskList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubtaskDialog,
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 子任务管理',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '管理 ${widget.parentType} 的具体练习任务',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '还没有子任务',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角的 + 按钮添加新任务',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtaskList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subtasks.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildSubtaskCard(_subtasks[index], index),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubtaskCard(Map<String, dynamic> subtask, int index) {
    final bool isCompleted = subtask['completed'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isCompleted
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade50, Colors.green.shade100],
                  )
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? Colors.white : Colors.blue.shade600,
              ),
            ),
            title: Text(
              subtask['name'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey.shade600 : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtask['note'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtask['note'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
                if (subtask['duration'] > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${subtask['duration']} 分钟',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCompleted)
                  ElevatedButton(
                    onPressed: () => _checkInSubtask(subtask, index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('打卡', style: TextStyle(fontSize: 12)),
                  ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditSubtaskDialog(subtask, index);
                        break;
                      case 'delete':
                        _deleteSubtask(index);
                        break;
                      case 'toggle':
                        _toggleSubtaskCompletion(subtask, index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isCompleted ? Icons.undo : Icons.check,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(isCompleted ? '标记未完成' : '标记完成'),
                        ],
                      ),
                    ),

                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => _toggleSubtaskCompletion(subtask, index),
          ),
        ),
      ),
    );
  }

  void _showAddSubtaskDialog() {
    _taskController.clear();
    _noteController.clear();
    _durationController.clear();

    showDialog(
      context: context,
      builder: (context) => _buildSubtaskDialog('添加子任务', false),
    );
  }

  void _showEditSubtaskDialog(Map<String, dynamic> subtask, int index) {
    _taskController.text = subtask['name'];
    _noteController.text = subtask['note'];
    _durationController.text = subtask['duration'].toString();

    showDialog(
      context: context,
      builder: (context) => _buildSubtaskDialog('编辑子任务', true, index),
    );
  }

  Widget _buildSubtaskDialog(String title, bool isEdit, [int? index]) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isEdit ? Icons.edit : Icons.add_task,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '任务名称',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _taskController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '输入任务名称',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '备注（可选）',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '添加备注信息',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text(
              '预计时长（分钟）',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _durationController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '输入预计时长',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                suffixIcon: Icon(
                  Icons.access_time,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            '取消',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_taskController.text.trim().isNotEmpty) {
              if (isEdit && index != null) {
                _updateSubtask(index);
              } else {
                _addSubtask();
              }
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            isEdit ? '更新' : '添加',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  void _addSubtask() async {
    final model = context.read<CheckInModel>();

    // 添加到数据库
    await model.addCheckIn(
      widget.parentType,
      subType: _taskController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      duration: int.tryParse(_durationController.text) ?? 0,
      parentId: widget.parentId,
    );

    // 重新加载子任务列表
    _loadSubtasks();
  }

  void _updateSubtask(int index) async {
    final model = context.read<CheckInModel>();
    final subtask = _subtasks[index];

    if (subtask['id'] != null) {
      // 更新数据库中的记录
      final updatedRecord = CheckInRecord(
        id: subtask['id'],
        date: DateTime.now(),
        type: widget.parentType,
        subType: _taskController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        duration: int.tryParse(_durationController.text) ?? 0,
        completed: subtask['completed'],
        parentId: widget.parentId,
      );

      await model.updateCheckIn(updatedRecord);

      // 重新加载子任务列表
      _loadSubtasks();
    }
  }

  void _deleteSubtask(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个子任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final model = context.read<CheckInModel>();
              final subtask = _subtasks[index];

              if (subtask['id'] != null) {
                // 从数据库删除
                await model.deleteCheckIn(subtask['id']);

                // 重新加载子任务列表
                _loadSubtasks();
              }

              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleSubtaskCompletion(Map<String, dynamic> subtask, int index) async {
    final model = context.read<CheckInModel>();

    if (subtask['id'] != null) {
      final updatedRecord = CheckInRecord(
        id: subtask['id'],
        date: DateTime.now(),
        type: widget.parentType,
        subType: subtask['name'],
        note: subtask['note'],
        duration: subtask['duration'],
        completed: !subtask['completed'],
        parentId: widget.parentId,
      );

      await model.updateCheckIn(updatedRecord);

      // 重新加载子任务列表
      _loadSubtasks();
    }
  }

  void _checkInSubtask(Map<String, dynamic> subtask, int index) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController noteController = TextEditingController();
        final TextEditingController durationController =
            TextEditingController();
        File? selectedImage;
        final ImagePicker picker = ImagePicker();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text('完成${subtask['name']}'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('恭喜你完成了${subtask['name']}！'),
                    const SizedBox(height: 16),
                    const Text(
                      '练习时长（分钟）：',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '输入练习分钟数',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '上传图片（可选）：',
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
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
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
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
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
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedImage = null;
                              });
                            },
                            child: const Text('删除图片'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      '练习心得（可选）：',
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();

                    // 保存图片到应用目录
                    String? imagePath;
                    if (selectedImage != null) {
                      try {
                        final directory =
                            await getApplicationDocumentsDirectory();
                        final imageDir = Directory(
                          '${directory.path}/check_in_images',
                        );
                        if (!await imageDir.exists()) {
                          await imageDir.create(recursive: true);
                        }

                        final fileName =
                            'checkin_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        final savedImage = await selectedImage!.copy(
                          '${imageDir.path}/$fileName',
                        );
                        imagePath = savedImage.path;
                        // ignore: empty_catches
                      } catch (e) {}
                    }

                    // 添加打卡记录到数据库
                    // ignore: use_build_context_synchronously
                    final model = context.read<CheckInModel>();
                    await model.addCheckIn(
                      widget.parentType,
                      subType: subtask['name'],
                      note: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                      duration: int.tryParse(durationController.text),
                      imagePath: imagePath,
                    );

                    // 更新本地状态
                    setState(() {
                      _subtasks[index]['completed'] = true;
                      _subtasks[index]['note'] = noteController.text.trim();
                      _subtasks[index]['duration'] =
                          int.tryParse(durationController.text) ?? 0;
                    });

                    if (context.mounted) {
                      _showSuccessAnimation(context, subtask['name']);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('确认打卡'),
                ),
              ],
            );
          },
        );
      },
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('继续加油'),
                ),
              ],
            ),
          ),
        );
      },
    );

    // 2秒后自动关闭
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _taskController.dispose();
    _noteController.dispose();
    _durationController.dispose();
    super.dispose();
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
