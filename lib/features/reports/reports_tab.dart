import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pluviometro_app/features/reports/report_screen.dart';
import 'package:pluviometro_app/shared/widgets/shared_app_bar.dart';
import 'package:pluviometro_app/services/database_service.dart';
import 'package:pluviometro_app/models/saved_report.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => ReportsTabState();
}

class ReportsTabState extends State<ReportsTab> {
  final DatabaseService _db = DatabaseService.instance;
  List<SavedReport> _reports = [];
  int _totalRecords = 0;
  double _totalMm = 0;
  bool _isLoading = true;

  // Pagination state
  static const int _itemsPerPage = 6;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Refreshes report list and stats — called by HomeScreen on tab switch.
  void refresh() {
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final records = await _db.getAllRecords();
    final reports = await _db.getAllReports();

    if (!mounted) return;

    double total = 0;
    for (var r in records) {
      total += r.millimeters;
    }

    setState(() {
      _totalRecords = records.length;
      _totalMm = total;
      _reports = reports;
      _isLoading = false;
    });
  }

  int get _totalPages => (_reports.length / _itemsPerPage).ceil();

  List<SavedReport> get _paginatedReports {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _reports.length);
    if (startIndex >= _reports.length) return [];
    return _reports.sublist(startIndex, endIndex);
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  Future<void> _navigateToGenerateReport() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ReportScreen()));

    if (result == true && mounted) {
      _loadData();
    }
  }

  Future<void> _openReport(SavedReport report) async {
    final file = File(report.filePath);
    if (await file.exists()) {
      try {
        await Share.shareXFiles([
          XFile(report.filePath),
        ], text: 'Relatório Pluviométrico');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao abrir arquivo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arquivo não encontrado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _deleteReport(SavedReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Relatório'),
        content: Text(
          'Deseja excluir o relatório gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(report.generatedAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true && report.id != null) {
      // Tentar deletar o arquivo também
      try {
        final file = File(report.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      await _db.deleteReport(report.id!);
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relatório excluído'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título
                    const Text(
                      'Relatórios',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gere e gerencie seus relatórios de chuva',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Resumo rápido
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Resumo Geral',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.format_list_numbered,
                                    label: 'Registros',
                                    value: '$_totalRecords',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey.shade300,
                                ),
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.water_drop,
                                    label: 'Total',
                                    value: '${_totalMm.toStringAsFixed(1)} mm',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botão gerar relatório
                    Card(
                      child: InkWell(
                        onTap: _navigateToGenerateReport,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red.shade400,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Gerar Novo Relatório',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Exporte seus dados em PDF',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Lista de relatórios gerados
                    if (_reports.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Relatórios Gerados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_reports.length} relatório(s)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Lista paginada
                      ..._paginatedReports.map(
                        (report) => _buildReportCard(report),
                      ),

                      // Controles de paginação
                      if (_totalPages > 1) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _currentPage > 0
                                  ? _previousPage
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                              style: IconButton.styleFrom(
                                backgroundColor: _currentPage > 0
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade100,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${_currentPage + 1} de $_totalPages',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: _currentPage < _totalPages - 1
                                  ? _nextPage
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                              style: IconButton.styleFrom(
                                backgroundColor: _currentPage < _totalPages - 1
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade100,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ] else ...[
                      // Estado vazio
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum relatório gerado',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Clique no botão acima para gerar seu primeiro relatório',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildReportCard(SavedReport report) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final period =
        '${dateFormat.format(report.startDate)} - ${dateFormat.format(report.endDate)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.picture_as_pdf, color: Colors.red.shade400),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gerado em ${dateFormat.format(report.generatedAt)} às ${timeFormat.format(report.generatedAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _openReport(report),
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Abrir',
              color: Theme.of(context).primaryColor,
            ),
            IconButton(
              onPressed: () => _deleteReport(report),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
