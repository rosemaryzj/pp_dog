import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/check_in_model.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'pages/home_page.dart';

import 'pages/calendar_page.dart';
import 'pages/statistics_page.dart';
import 'pages/settings_page.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化时区
  tz.initializeTimeZones();

  // 初始化本地化数据
  await initializeDateFormatting('zh_CN', null);

  // 初始化通知服务
  await NotificationService.initialize();

  // 初始化数据库
  await DatabaseService.initialize();

  // 请求通知权限
  await Permission.notification.request();

  // 设置屏幕方向
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CheckInModel()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '小朋友练习打卡',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              colorScheme:
                  ColorScheme.fromSeed(
                    seedColor: const Color(0xFF6366F1),
                    brightness: Brightness.light,
                  ).copyWith(
                    primary: const Color(0xFF6366F1),
                    secondary: const Color(0xFF10B981),
                    surface: Colors.white,
                    onPrimary: Colors.white,
                    onSecondary: Colors.white,
                    onSurface: Colors.black87,
                  ),
              useMaterial3: true,
              fontFamily: 'PingFang SC',
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                centerTitle: true,
              ),
              cardTheme: const CardThemeData(
                elevation: 0,
                shadowColor: Colors.transparent,
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black87),
                bodyMedium: TextStyle(color: Colors.black54),
                titleLarge: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                titleMedium: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              colorScheme:
                  ColorScheme.fromSeed(
                    seedColor: const Color(0xFF6366F1),
                    brightness: Brightness.dark,
                  ).copyWith(
                    primary: const Color(0xFF6366F1),
                    secondary: const Color(0xFF10B981),
                    surface: const Color(0xFF1C1C1E),
                    onPrimary: Colors.white,
                    onSecondary: Colors.white,
                    onSurface: Colors.white,
                  ),
              useMaterial3: true,
              fontFamily: 'PingFang SC',
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1C1C1E),
                foregroundColor: Colors.white,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                centerTitle: true,
              ),
              cardTheme: const CardThemeData(
                elevation: 0,
                shadowColor: Colors.transparent,
                color: Color(0xFF1C1C1E),
                surfaceTintColor: Colors.transparent,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white70),
                titleLarge: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                titleMedium: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const MainPage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 在应用启动时加载打卡记录
    Provider.of<CheckInModel>(context, listen: false).loadRecords();
  }

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(onNavigate: _navigateTo),
      const CalendarPage(),
      const StatisticsPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.green,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade400
            : Colors.grey,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors
                  .grey
                  .shade900 // 暗黑模式下使用深灰色背景
            : Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedLabelStyle: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade400
              : Colors.grey,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '日历',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '统计'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
