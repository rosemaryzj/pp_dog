import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/check_in_model.dart';
import '../providers/theme_provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final ValueNotifier<List<CheckInRecord>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier([]);
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<CheckInRecord> _getEventsForDay(DateTime day, CheckInModel? checkInModel) {
    if (checkInModel == null) return [];
    
    // 获取当天所有已完成的打卡记录
    final allRecords = checkInModel.getRecordsByDate(day).where((record) => record.completed).toList();
    
    // 只返回有子任务的记录，过滤掉没有子任务的父任务记录
    return allRecords.where((record) => record.subType != null).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay, CheckInModel checkInModel) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay, checkInModel);
    }
  }

  void _showCleanupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理数据'),
        content: const Text('这将删除30天前的记录和重复的记录，确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final checkInModel = Provider.of<CheckInModel>(context, listen: false);
              await checkInModel.cleanupExcessiveData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('数据清理完成'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('确定清理', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          '打卡日历',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () => _showCleanupDialog(context),
            tooltip: '清理数据',
          ),
        ],
      ),
      body: Consumer<CheckInModel>(builder: (context, checkInModel, child) {
        // 初始化选中日期的事件数据
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_selectedDay != null) {
            _selectedEvents.value = _getEventsForDay(_selectedDay!, checkInModel);
          }
        });
        
        return Column(
          children: [
            // 日历组件
            Container(
              height: 230,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isDark ? Border.all(color: const Color(0xFF2C2C2E), width: 1) : null,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
                    blurRadius: isDark ? 8 : 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TableCalendar<CheckInRecord>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: (day) => _getEventsForDay(day, checkInModel),
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: 'zh_CN',
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) => _onDaySelected(selectedDay, focusedDay, checkInModel),
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(
                    color: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFDC2626),
                    fontWeight: FontWeight.w500,
                  ),
                  holidayTextStyle: TextStyle(
                    color: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFDC2626),
                    fontWeight: FontWeight.w500,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF6366F1), width: 2),
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(
                    color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  cellMargin: const EdgeInsets.all(4),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  titleTextFormatter: (date, locale) => DateFormat.yMMMM('zh_CN').format(date),
                  titleTextStyle: TextStyle(
                     color: isDark ? Colors.white : Colors.black87,
                     fontSize: 18,
                     fontWeight: FontWeight.w700,
                     letterSpacing: -0.5,
                   ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                  weekendStyle: TextStyle(
                    color: isDark ? Colors.red[300] : Colors.red[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            
            // 选中日期的打卡记录
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedDay != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          '${DateFormat('yyyy年MM月dd日').format(_selectedDay!)} 的打卡记录',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ValueListenableBuilder<List<CheckInRecord>>(
                          valueListenable: _selectedEvents,
                          builder: (context, events, _) {
                            if (events.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today_outlined,
                                        size: 32,
                                        color: isDark ? Colors.white38 : Colors.black26,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      '这一天还没有打卡记录',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white54 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return ListView.builder(
                              itemCount: events.length,
                              itemBuilder: (context, index) {
                                final event = events[index];
                                return _buildEventCard(event, isDark);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEventCard(CheckInRecord record, bool isDark) {
    final typeEmojis = {
      '数学': '🔢',
      '语文': '📚',
      '英语': '🔤',
      '阅读': '📖',
    };
    
    final subtaskEmojis = {
      '口算': '🧮',
      '应用题': '📊',
      '几何': '📐',
      '阅读': '📖',
      '练字': '✍️',
      '背诵': '📝',
      '单词': '📚',
      '听力': '👂',
      '对话': '💬',
    };
    
    return GestureDetector(
      onTap: () => _showCheckInDetails(record, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: const Color(0xFF2C2C2E), width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
              blurRadius: isDark ? 8 : 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Row(
        children: [
          // 类型图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: record.completed 
                  ? const Color(0xFF10B981)
                  : const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: record.completed
                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                  : Text(
                      subtaskEmojis[record.subType] ?? typeEmojis[record.type] ?? '📝',
                      style: const TextStyle(fontSize: 20),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          
          // 打卡信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 类型和子类型
                Text(
                  '${record.type} - ${record.subType}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                // 持续时间
                if (record.duration != null)
                  Text(
                    '持续时间: ${record.duration}分钟',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                const SizedBox(height: 8),
                // 完成状态
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: record.completed 
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record.completed ? '已完成' : '未完成',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: record.completed 
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ),
                if (record.note != null && record.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      record.note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 时间
          Text(
            DateFormat('HH:mm').format(record.date),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showCheckInDetails(CheckInRecord record, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text('打卡详情'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 基本信息
                Text(
                  '${record.type} - ${record.subType}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '打卡时间: ${DateFormat('yyyy年MM月dd日 HH:mm').format(record.date)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (record.duration != null) ...[
                   const SizedBox(height: 4),
                   Text(
                     '练习时长: ${record.duration}分钟',
                     style: TextStyle(
                       fontSize: 14,
                       color: Colors.grey.shade600,
                     ),
                   ),
                 ],
                const SizedBox(height: 16),
                
                // 上传的图片
                if (record.imagePath != null && record.imagePath!.isNotEmpty) ...[
                  const Text(
                    '上传的图片:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showFullScreenImage(context, record.imagePath!),
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Image.file(
                              File(record.imagePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('图片加载失败', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // 练习心得
                if (record.note != null && record.note!.isNotEmpty) ...[
                  Text(
                    '练习心得:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3C3C3E) : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      record.note!,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        letterSpacing: 0.2,
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                
                // 如果没有图片和心得
                if ((record.imagePath == null || record.imagePath!.isEmpty) &&
                    (record.note == null || record.note!.isEmpty)) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          '这次打卡没有上传图片或心得',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
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
                            Icon(Icons.broken_image, size: 64, color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              '图片加载失败',
                              style: TextStyle(color: Colors.white, fontSize: 16),
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