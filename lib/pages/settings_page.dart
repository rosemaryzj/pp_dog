import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await NotificationService.getReminderSettings();
      if (!mounted) return;
      setState(() {
        _reminderEnabled = settings['enabled'];
        _reminderTime = TimeOfDay(
          hour: settings['hour'],
          minute: settings['minute'],
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await NotificationService.saveReminderSettings(
        enabled: _reminderEnabled,
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('设置已保存'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimationLimiter(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    60,
                    16,
                    16,
                  ), // 增加更多顶部padding避免灵动岛遮挡
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      _buildThemeSettings(),
                      const SizedBox(height: 16),
                      _buildNotificationSettings(),
                      const SizedBox(height: 16),
                      _buildDataManagementSettings(),
                      const SizedBox(height: 16),
                      _buildAppInfo(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSettings() {
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
                Icon(Icons.palette, color: Colors.purple.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '外观设置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSettingItem(
              title: '深色模式',
              subtitle: '切换应用的主题颜色',
              trailing: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Switch(
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      context.read<ThemeProvider>().toggleTheme(value);
                    },
                    activeThumbColor: Theme.of(context).colorScheme.secondary,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
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
                  Icons.notifications,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  '提醒设置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSettingItem(
              title: '每日提醒',
              subtitle: '开启后会在指定时间提醒你练习',
              trailing: Switch(
                value: _reminderEnabled,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _reminderEnabled = value;
                        });
                        _saveSettings();
                      },
                activeThumbColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
            if (_reminderEnabled) ...<Widget>[
              const Divider(),
              _buildSettingItem(
                title: '提醒时间',
                subtitle: '每日将在指定时间提醒',
                trailing: TextButton(
                  onPressed: _isLoading ? null : _selectTime,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _reminderTime.format(context),
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (!mounted) return;
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      _saveSettings();
    }
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      trailing: trailing,
    );
  }

  Widget _buildDataManagementSettings() {
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
                Icon(Icons.import_export, color: Colors.teal.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '数据管理',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSettingItem(
              title: '导出数据',
              subtitle: '将所有数据导出到文件中',
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _exportData,
            ),
            const Divider(),
            _buildSettingItem(
              title: '导入数据',
              subtitle: '从文件中导入数据，会覆盖现有数据',
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _importData,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final allData = await DatabaseService.exportData();
      final jsonString = jsonEncode(allData);
      final bytes = utf8.encode(jsonString);

      if (!mounted) return;
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '请选择保存文件的位置:',
        fileName: 'checkin_backup.json',
        bytes: bytes,
      );

      if (outputFile != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('数据导出成功')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('数据导出失败: $e')));
    }
  }

  Future<void> _importData() async {
    try {
      if (!mounted) return;
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          File file = File(result.files.single.path!);
          final jsonString = await file.readAsString();
          if (!mounted) return;
          final allData = jsonDecode(jsonString);

          await DatabaseService.importData(allData);

          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('导入成功'),
              content: const Text('数据已成功导入。为了确保所有更改都已正确应用，请重新启动应用。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('好的'),
                ),
              ],
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('数据导入失败: $e')));
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('数据导入失败: $e')));
    }
  }

  Widget _buildAppInfo() {
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
                Icon(Icons.info, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '应用信息',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoItem('应用名称', '瑞宝打卡'),
            _buildInfoItem('版本号', '1.0.0'),
            _buildInfoItem('开发者', '瑞宝爸爸'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
