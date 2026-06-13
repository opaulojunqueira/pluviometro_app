import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pluviometro_app/services/database_service.dart';
import 'package:pluviometro_app/services/preferences_service.dart';
import 'package:pluviometro_app/models/rain_record.dart';
import 'package:pluviometro_app/theme/app_colors.dart';
import 'package:pluviometro_app/shared/widgets/shared_app_bar.dart';
import 'package:pluviometro_app/shared/widgets/loading_view.dart';
import 'package:pluviometro_app/features/dashboard/widgets/stat_card.dart';
import 'package:pluviometro_app/features/dashboard/widgets/rainy_days_card.dart';
import 'package:pluviometro_app/features/dashboard/widgets/rain_classification_card.dart';
import 'package:pluviometro_app/features/dashboard/widgets/historical_avg_card.dart';
import 'package:pluviometro_app/features/dashboard/widgets/monthly_bar_chart.dart';
import 'package:pluviometro_app/features/dashboard/widgets/recent_record_card.dart';
import 'package:pluviometro_app/features/dashboard/widgets/last_reading_card.dart';
import 'package:pluviometro_app/features/dashboard/widgets/yearly_comparison_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => DashboardTabState();
}

class DashboardTabState extends State<DashboardTab> {
  final DatabaseService _db = DatabaseService.instance;
  final PreferencesService _prefs = PreferencesService.instance;

  List<RainRecord> _recentRecords = [];
  RainRecord? _lastRainyRecord;
  double _monthlyTotal = 0.0;
  double _yearlyTotal = 0.0;
  double _historicalMonthlyAvg = 0.0;
  int _rainyDaysThisMonth = 0;
  Map<String, double> _monthlyTotals = {};
  Map<int, double> _yearlyTotals = {};
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
    final lastRainyRecord = await _db.getLastRainyRecord();
    final yearlyTotals = await _db.getYearlyTotals(3);

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
      _lastRainyRecord = lastRainyRecord;
      _monthlyTotal = monthlyTotal;
      _yearlyTotal = yearlyTotal;
      _rainyDaysThisMonth = rainyDays.length;
      _monthlyTotals = monthlyTotals;
      _yearlyTotals = yearlyTotals;
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
          ? const LoadingView()
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
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (propertyName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        propertyName,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Hero: última leitura + alerta de estiagem
                  if (_recentRecords.isNotEmpty) ...[
                    LastReadingCard(
                      lastRecord: _recentRecords.first,
                      lastRainyRecord: _lastRainyRecord,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Monthly and yearly totals
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.water_drop,
                            iconColor: AppColors.primary,
                            title: 'Este mês',
                            subtitle: monthName.toUpperCase(),
                            value: '${_monthlyTotal.toStringAsFixed(1)} mm',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.calendar_today,
                            iconColor: AppColors.secondary,
                            title: 'Este ano',
                            subtitle: '${now.year}',
                            value: '${_yearlyTotal.toStringAsFixed(1)} mm',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rainy days count + rain intensity classification
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: RainyDaysCard(rainyDays: _rainyDaysThisMonth),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RainClassificationCard(monthlyMm: _monthlyTotal),
                        ),
                      ],
                    ),
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
                  const SizedBox(height: 12),

                  // Annual comparison (shown only when there is yearly data)
                  if (_yearlyTotals.values.any((v) => v > 0)) ...[
                    YearlyComparisonCard(yearlyTotals: _yearlyTotals),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),

                  // Recent records section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Registros Recentes',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Icon(Icons.history, color: AppColors.textMuted),
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
