import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pluviometro_app/services/database_service.dart';
import 'package:pluviometro_app/services/preferences_service.dart';
import 'package:pluviometro_app/models/rain_record.dart';
import 'package:pluviometro_app/shared/widgets/shared_app_bar.dart';
import 'package:pluviometro_app/features/dashboard/widgets/stat_card.dart';
import 'package:pluviometro_app/features/dashboard/widgets/rainy_days_card.dart';
import 'package:pluviometro_app/features/dashboard/widgets/rain_classification_card.dart';
import 'package:pluviometro_app/features/dashboard/widgets/historical_avg_card.dart';
import 'package:pluviometro_app/features/dashboard/widgets/monthly_bar_chart.dart';
import 'package:pluviometro_app/features/dashboard/widgets/recent_record_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => DashboardTabState();
}

class DashboardTabState extends State<DashboardTab> {
  final DatabaseService _db = DatabaseService.instance;
  final PreferencesService _prefs = PreferencesService.instance;

  List<RainRecord> _recentRecords = [];
  double _monthlyTotal = 0.0;
  double _yearlyTotal = 0.0;
  double _historicalMonthlyAvg = 0.0;
  int _rainyDaysThisMonth = 0;
  Map<String, double> _monthlyTotals = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Refreshes all dashboard data — called externally by HomeScreen on tab switch.
  void refresh() => _loadData();

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final now = DateTime.now();

    // Run lightweight, targeted SQL queries — avoids loading all records into memory
    final recentRecords = await _db.getRecentRecords(5);
    final monthRecords = await _db.getRecordsByMonth(now.year, now.month);
    final yearlyTotal = await _db.getTotalMmByYear(now.year);
    final monthlyTotals = await _db.getMonthlyTotals(6);

    // Exit early if the widget was unmounted during async database queries
    if (!mounted) return;

    // Aggregate monthly total and count unique rainy days
    double monthlyTotal = 0.0;
    final Set<String> rainyDays = {};
    for (final record in monthRecords) {
      monthlyTotal += record.millimeters;
      rainyDays.add(DateFormat('yyyy-MM-dd').format(record.date));
    }

    // Historical average: only consider months that had at least some rainfall
    double historicalAvg = 0.0;
    final nonZero = monthlyTotals.values.where((v) => v > 0).toList();
    if (nonZero.isNotEmpty) {
      historicalAvg = nonZero.reduce((a, b) => a + b) / nonZero.length;
    }

    setState(() {
      _recentRecords = recentRecords;
      _monthlyTotal = monthlyTotal;
      _yearlyTotal = yearlyTotal;
      _rainyDaysThisMonth = rainyDays.length;
      _monthlyTotals = monthlyTotals;
      _historicalMonthlyAvg = historicalAvg;
      _isLoading = false;
    });
  }

  String _getFirstName() {
    final name = _prefs.userName;
    if (name.isEmpty) return 'Produtor';
    return name.trim().split(' ').first;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Bom dia';
    if (hour >= 12 && hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM', 'pt_BR').format(now);
    final propertyName = _prefs.propertyName;

    return Scaffold(
      appBar: const SharedAppBar(),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Greeting header
                  Text(
                    '${_getGreeting()}, ${_getFirstName()}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (propertyName.isNotEmpty)
                    Text(
                      propertyName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Monthly and yearly totals
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.water_drop,
                          iconColor: Colors.blue,
                          title: 'Este mês',
                          subtitle: monthName.toUpperCase(),
                          value: '${_monthlyTotal.toStringAsFixed(1)} mm',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.calendar_today,
                          iconColor: Colors.green,
                          title: 'Este ano',
                          subtitle: '${now.year}',
                          value: '${_yearlyTotal.toStringAsFixed(1)} mm',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rainy days count + rain intensity classification
                  Row(
                    children: [
                      Expanded(
                        child: RainyDaysCard(rainyDays: _rainyDaysThisMonth),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RainClassificationCard(
                          monthlyMm: _monthlyTotal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Historical monthly average with current-month comparison
                  HistoricalAvgCard(
                    monthlyTotal: _monthlyTotal,
                    historicalAvg: _historicalMonthlyAvg,
                  ),
                  const SizedBox(height: 12),

                  // 6-month animated bar chart
                  MonthlyBarChart(monthlyTotals: _monthlyTotals),
                  const SizedBox(height: 32),

                  // Recent records section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Registros Recentes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.history, color: Colors.grey.shade600),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_recentRecords.isEmpty)
                    const DashboardEmptyState()
                  else
                    ..._recentRecords.map(
                      (record) => RecentRecordCard(record: record),
                    ),
                ],
              ),
            ),
    );
  }
}
