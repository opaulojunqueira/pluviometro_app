import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pluviometro_app/services/database_service.dart';
import 'package:pluviometro_app/services/preferences_service.dart';
import 'package:pluviometro_app/models/rain_record.dart';
import 'package:pluviometro_app/models/saved_report.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final PreferencesService _prefs = PreferencesService.instance;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Definir intervalo padrão: mês atual
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now(),
        end: _endDate ?? DateTime.now(),
      ),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione o período',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      saveText: 'Salvar',
      fieldStartHintText: 'Data inicial',
      fieldEndHintText: 'Data final',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o período do relatório'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final records = await _db.getRecordsByDateRange(_startDate!, _endDate!);
      final pdfBytes = await _buildPdf(records);

      if (!mounted) return;

      // Salvar o arquivo PDF localmente
      final now = DateTime.now();
      final fileName =
          'Relatorio_${DateFormat('yyyy-MM-dd').format(_startDate!)}_${DateFormat('yyyy-MM-dd').format(_endDate!)}_${DateFormat('HHmmss').format(now)}.pdf';

      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/relatorios');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final filePath = '${reportsDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Salvar registro no banco de dados
      final savedReport = SavedReport(
        startDate: _startDate!,
        endDate: _endDate!,
        generatedAt: now,
        filePath: filePath,
        fileName: fileName,
      );
      await _db.createReport(savedReport);

      // Mostrar opção de compartilhar/imprimir
      await Printing.layoutPdf(
        onLayout: (format) async => Uint8List.fromList(pdfBytes),
        name: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relatório salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar relatório: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<List<int>> _buildPdf(List<RainRecord> records) async {
    final pdf = pw.Document();
    final userName = _prefs.userName;
    final propertyName = _prefs.propertyName;
    final userCity = _prefs.userCity;

    // Calcular estatísticas
    double totalMm = 0;
    int rainyDays = 0;
    Map<String, double> dailyTotals = {};

    for (var record in records) {
      totalMm += record.millimeters;
      final dateKey = DateFormat('yyyy-MM-dd').format(record.date);
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + record.millimeters;
    }
    rainyDays = dailyTotals.length;

    // Gerar lista de todos os dias no intervalo
    List<DateTime> allDays = [];
    DateTime current = _startDate!;
    while (!current.isAfter(_endDate!)) {
      allDays.add(current);
      current = current.add(const Duration(days: 1));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(userName, propertyName, userCity),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),

          // Resumo
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total de Chuva',
                  '${totalMm.toStringAsFixed(1)} mm',
                ),
                _buildSummaryItem('Dias com Chuva', '$rainyDays dias'),
                _buildSummaryItem('Total de Dias', '${allDays.length} dias'),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Título da tabela
          pw.Text(
            'Detalhamento por Dia',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),

          pw.SizedBox(height: 12),

          // Tabela de dias
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(3),
            },
            children: [
              // Cabeçalho
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  _buildTableHeader('Data'),
                  _buildTableHeader('Dia da Semana'),
                  _buildTableHeader('Chuva (mm)'),
                  _buildTableHeader('Observação'),
                ],
              ),
              // Linhas de dados
              ...allDays.map((day) {
                final dateKey = DateFormat('yyyy-MM-dd').format(day);
                final dayRecords = records
                    .where(
                      (r) => DateFormat('yyyy-MM-dd').format(r.date) == dateKey,
                    )
                    .toList();
                final totalDay = dailyTotals[dateKey] ?? 0;
                final hasRain = totalDay > 0;
                final observation =
                    dayRecords.isNotEmpty &&
                        dayRecords.first.observation != null
                    ? dayRecords.first.observation!
                    : '-';

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: hasRain ? PdfColors.lightBlue50 : PdfColors.white,
                  ),
                  children: [
                    _buildTableCell(DateFormat('dd/MM/yyyy').format(day)),
                    _buildTableCell(_getDayOfWeek(day)),
                    _buildTableCell(
                      totalDay.toStringAsFixed(1),
                      align: pw.TextAlign.center,
                    ),
                    _buildTableCell(observation),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 24),

          // Rodapé com informações do app
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Pluviômetro Digital',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Aplicação para registro e acompanhamento de dados pluviométricos.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Desenvolvido por Paulo Junqueira',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Site: paulojunqueira.com',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'E-mail: contato@paulojunqueira.com',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfHeader(
    String userName,
    String propertyName,
    String userCity,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Relatório Pluviométrico',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Período: ${DateFormat("dd/MM/yyyy").format(_startDate!)} a ${DateFormat("dd/MM/yyyy").format(_endDate!)}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (propertyName.isNotEmpty)
                pw.Text(
                  propertyName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              if (userName.isNotEmpty)
                pw.Text(
                  userName,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              if (userCity.isNotEmpty)
                pw.Text(
                  userCity,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gerado por Pluviômetro Digital',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Data: ${DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
          color: PdfColors.blue900,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: align,
      ),
    );
  }

  String _getDayOfWeek(DateTime date) {
    final days = [
      'Domingo',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
    ];
    return days[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Gerar Relatório')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ícone e título
            Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Relatório Pluviométrico',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Gere um PDF com os dados de chuva do período selecionado',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 32),

            // Card de seleção de período
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Período do Relatório',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Data inicial
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data Inicial',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  _startDate != null
                                      ? dateFormat.format(_startDate!)
                                      : 'Não selecionada',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Ícone de seta
                    Center(
                      child: Icon(
                        Icons.arrow_downward,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Data final
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data Final',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  _endDate != null
                                      ? dateFormat.format(_endDate!)
                                      : 'Não selecionada',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botão selecionar período
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.edit_calendar),
                        label: const Text('Alterar Período'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Card de informações do relatório
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'O relatório incluirá',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      Icons.water_drop,
                      'Total de milímetros de chuva',
                    ),
                    _buildInfoItem(Icons.cloud, 'Quantidade de dias com chuva'),
                    _buildInfoItem(
                      Icons.table_chart,
                      'Tabela com todos os dias do período',
                    ),
                    _buildInfoItem(
                      Icons.wb_sunny,
                      'Indicação de dias com e sem chuva',
                    ),
                    _buildInfoItem(Icons.note, 'Observações registradas'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botão gerar relatório
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateReport,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isGenerating ? 'Gerando...' : 'Gerar Relatório PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
