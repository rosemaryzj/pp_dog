import 'package:flutter/material.dart';
import '../models/practice_type_model.dart';
import '../services/database_service.dart';

class PracticeTypeManagementPage extends StatefulWidget {
  const PracticeTypeManagementPage({super.key});

  @override
  State<PracticeTypeManagementPage> createState() =>
      _PracticeTypeManagementPageState();
}

class _PracticeTypeManagementPageState
    extends State<PracticeTypeManagementPage> {
  List<PracticeType> _practiceTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPracticeTypes();
  }

  Future<void> _loadPracticeTypes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final types = await DatabaseService.getPracticeTypes();
      setState(() {
        _practiceTypes = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载练习类型失败: $e')));
      }
    }
  }

  Future<void> _showAddEditDialog({PracticeType? practiceType}) async {
    final isEdit = practiceType != null;
    final typeController = TextEditingController(
      text: practiceType?.type ?? '',
    );
    final descriptionController = TextEditingController(
      text: practiceType?.description ?? '',
    );
    final emojiController = TextEditingController(
      text: practiceType?.emoji ?? '',
    );
    List<String> subTypes = List<String>.from(practiceType?.subTypes ?? []);

    String selectedIcon = practiceType?.icon ?? 'Icons.school';
    Color selectedColor = practiceType != null
        ? Color(practiceType.color)
        : Colors.blue;

    final availableIcons = {
      'Icons.school': Icons.school,
      'Icons.calculate': Icons.calculate,
      'Icons.menu_book': Icons.menu_book,
      'Icons.language': Icons.language,
      'Icons.science': Icons.science,
      'Icons.palette': Icons.palette,
      'Icons.music_note': Icons.music_note,
      'Icons.sports_soccer': Icons.sports_soccer,
      'Icons.computer': Icons.computer,
      'Icons.psychology': Icons.psychology,
    };

    final availableColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? '编辑练习类型' : '新增练习类型'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: '练习类型名称',
                    hintText: '如：数学、语文等',
                  ),
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: emojiController,
                  decoration: const InputDecoration(
                    labelText: 'Emoji表情',
                    hintText: '如：📚、🔢等',
                  ),
                  maxLength: 2,
                ),
                const SizedBox(height: 16),
                const Text('子任务列表'),
                const SizedBox(height: 8),
                if (subTypes.isEmpty)
                  const Text('暂无子任务', style: TextStyle(color: Colors.grey)),
                ...subTypes.map((subType) {
                  return Chip(
                    label: Text(subType),
                    onDeleted: () {
                      setDialogState(() {
                        subTypes.remove(subType);
                      });
                    },
                  );
                }),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('添加子任务'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () async {
                    final newSubType = await _showAddSubTypeDialog();
                    if (newSubType != null && newSubType.isNotEmpty) {
                      setDialogState(() {
                        subTypes.add(newSubType);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('选择图标：'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: availableIcons.entries.map((entry) {
                    final isSelected = selectedIcon == entry.key;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedIcon = entry.key;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? selectedColor : Colors.grey,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          entry.value,
                          color: isSelected ? selectedColor : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('选择颜色：'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: availableColors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () async {
                if (typeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请输入练习类型名称')));
                  return;
                }

                final newPracticeType = PracticeType(
                  id: practiceType?.id,
                  type: typeController.text.trim(),
                  icon: selectedIcon,
                  // ignore: deprecated_member_use
                  color: selectedColor.value,
                  description: descriptionController.text.trim().isEmpty
                      ? '${typeController.text.trim()}练习'
                      : descriptionController.text.trim(),
                  emoji: emojiController.text.trim().isEmpty
                      ? '📚'
                      : emojiController.text.trim(),
                  subTypes: subTypes,
                  createdAt: practiceType?.createdAt ?? DateTime.now(),
                );

                try {
                  if (isEdit) {
                    await DatabaseService.updatePracticeType(newPracticeType);
                  } else {
                    await DatabaseService.insertPracticeType(newPracticeType);
                  }

                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                  await _loadPracticeTypes();

                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? '练习类型更新成功' : '练习类型添加成功')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      // ignore: use_build_context_synchronously
                      context,
                    ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
                  }
                }
              },
              child: Text(isEdit ? '更新' : '添加'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showAddSubTypeDialog() async {
    final subTypeController = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加子任务'),
        content: TextField(
          controller: subTypeController,
          decoration: const InputDecoration(labelText: '子任务名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              Navigator.of(context).pop(subTypeController.text.trim());
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePracticeType(PracticeType practiceType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除「${practiceType.type}」吗？\n\n注意：删除后相关的打卡记录仍会保留，但可能无法正常显示。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && practiceType.id != null) {
      try {
        await DatabaseService.deletePracticeType(practiceType.id!);
        await _loadPracticeTypes();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('练习类型删除成功')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('练习类型管理'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPracticeTypes,
              child: _practiceTypes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '暂无练习类型',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '点击右下角的 + 按钮添加练习类型',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _practiceTypes.length,
                      itemBuilder: (context, index) {
                        final practiceType = _practiceTypes[index];
                        final iconData = _getIconData(practiceType.icon);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Color(
                                  practiceType.color,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                iconData,
                                color: Color(practiceType.color),
                                size: 24,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  practiceType.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  practiceType.type,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  practiceType.description,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                if (practiceType.subTypes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: practiceType.subTypes.map((
                                      subType,
                                    ) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(
                                            practiceType.color,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Color(
                                              practiceType.color,
                                            ).withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          subType,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(practiceType.color),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showAddEditDialog(
                                    practiceType: practiceType,
                                  );
                                } else if (value == 'delete') {
                                  _deletePracticeType(practiceType);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('编辑'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '删除',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconData(String iconString) {
    switch (iconString) {
      case 'Icons.calculate':
        return Icons.calculate;
      case 'Icons.menu_book':
        return Icons.menu_book;
      case 'Icons.language':
        return Icons.language;
      case 'Icons.science':
        return Icons.science;
      case 'Icons.palette':
        return Icons.palette;
      case 'Icons.music_note':
        return Icons.music_note;
      case 'Icons.sports_soccer':
        return Icons.sports_soccer;
      case 'Icons.computer':
        return Icons.computer;
      case 'Icons.psychology':
        return Icons.psychology;
      default:
        return Icons.school;
    }
  }
}
