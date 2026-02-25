import 'package:flutter/material.dart';
import 'package:pluviometro_app/features/dashboard/dashboard_tab.dart';
import 'package:pluviometro_app/features/calendar/calendar_tab.dart';
import 'package:pluviometro_app/features/reports/reports_tab.dart';
import 'package:pluviometro_app/features/settings/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // GlobalKeys used to call refresh() on each tab when switching
  final GlobalKey<DashboardTabState> _dashboardKey =
      GlobalKey<DashboardTabState>();
  final GlobalKey<CalendarTabState> _calendarKey =
      GlobalKey<CalendarTabState>();
  final GlobalKey<ReportsTabState> _reportsKey = GlobalKey<ReportsTabState>();
  final GlobalKey<SettingsTabState> _settingsKey =
      GlobalKey<SettingsTabState>();

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      DashboardTab(key: _dashboardKey),
      CalendarTab(key: _calendarKey),
      ReportsTab(key: _reportsKey),
      SettingsTab(key: _settingsKey),
    ];
  }

  void _onTabTapped(int index) {
    // Refresh tab data when switching to it
    switch (index) {
      case 0:
        _dashboardKey.currentState?.refresh();
        break;
      case 1:
        _calendarKey.currentState?.resetToToday();
        break;
      case 2:
        _reportsKey.currentState?.refresh();
        break;
      case 3:
        _settingsKey.currentState?.refresh();
        break;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Calendário',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment),
              label: 'Relatórios',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
