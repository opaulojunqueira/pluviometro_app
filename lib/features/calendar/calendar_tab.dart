import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pluviometro_app/services/database_service.dart';
import 'package:pluviometro_app/models/rain_record.dart';
import 'package:pluviometro_app/features/add_record/add_record_screen.dart';
import 'package:pluviometro_app/shared/widgets/shared_app_bar.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => CalendarTabState();
}

class CalendarTabState extends State<CalendarTab> {
  final DatabaseService _db = DatabaseService.instance;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<RainRecord>> _events = {};
  List<RainRecord> _selectedDayRecords = [];
  bool _isLoading = true;

  // Date bounds for allowing new record entries (last 30 days only)
  DateTime get _minAllowedDate =>
      DateTime.now().subtract(const Duration(days: 30));
  DateTime get _maxAllowedDate => DateTime.now();

  @override
  void initState() {
    super.initState();
    _resetToToday();
    _loadEvents();
  }

  /// Resets the calendar focus and selection to today's date.
  void resetToToday() {
    setState(() {
      final now = DateTime.now();
      _focusedDay = now;
      _selectedDay = now;
      _selectedDayRecords = _getEventsForDay(now);
    });
    _loadEvents();
  }

  void _resetToToday() {
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final recordsMap = await _db.getRecordsMap();

    if (!mounted) return;
    setState(() {
      _events = recordsMap;
      _selectedDayRecords = _getEventsForDay(_selectedDay!);
      _isLoading = false;
    });
  }

  List<RainRecord> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedDayRecords = _getEventsForDay(selectedDay);
      });
    }
  }

  /// Verifica se a data selecionada permite adicionar registros
  bool _canAddRecord() {
    if (_selectedDay == null) return false;

    final selected = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    final minDate = DateTime(
      _minAllowedDate.year,
      _minAllowedDate.month,
      _minAllowedDate.day,
    );
    final maxDate = DateTime(
      _maxAllowedDate.year,
      _maxAllowedDate.month,
      _maxAllowedDate.day,
    );

    return !selected.isBefore(minDate) && !selected.isAfter(maxDate);
  }

  Future<void> _navigateToAddRecord() async {
    if (!_canAddRecord()) {
      String message;
      if (_selectedDay!.isAfter(_maxAllowedDate)) {
        message = 'Não é possível adicionar registros em datas futuras';
      } else {
        message = 'Só é permitido adicionar registros dos últimos 30 dias';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.orange),
      );
      return;
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(selectedDate: _selectedDay!),
      ),
    );

    if (result == true && mounted) {
      _loadEvents();
    }
  }

  Future<void> _editRecord(RainRecord record) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AddRecordScreen(selectedDate: record.date, existingRecord: record),
      ),
    );

    if (result == true && mounted) {
      _loadEvents();
    }
  }

  Future<void> _deleteRecord(RainRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Registro'),
        content: Text(
          'Deseja excluir o registro de ${record.millimeters.toStringAsFixed(1)} mm do dia ${DateFormat('dd/MM/yyyy').format(record.date)}?',
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

    if (confirmed == true && record.id != null && mounted) {
      await _db.deleteRecord(record.id!);
      if (!mounted) return;
      _loadEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro excluído com sucesso'),
          backgroundColor: Colors.red,
        ),
      );
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
          : Column(
              children: [
                // Title section with left accent bar for visual consistency
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left accent bar
                      Container(
                        width: 4,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Calendário',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Selecione um dia para ver ou adicionar',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Calendar card
                Card(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TableCalendar<RainRecord>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Mês',
                      CalendarFormat.twoWeeks: '2 Semanas',
                      CalendarFormat.week: 'Semana',
                    },
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    locale: 'pt_BR',
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      // Weekend days: muted blue-grey instead of jarring red
                      weekendTextStyle: TextStyle(color: Colors.blueGrey.shade400),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      // Marker uses theme primary so it always matches
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      markerSize: 6,
                      markersMaxCount: 1,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      formatButtonDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      formatButtonTextStyle: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onDaySelected: _onDaySelected,
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
                  ),
                ),

                // Selected day info bar
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR')
                                .format(_selectedDay!),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (_selectedDayRecords.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_getTotalForDay().toStringAsFixed(1)} mm',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Records list
                Expanded(
                  child: _selectedDayRecords.isEmpty
                      ? _buildEmptyDayState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _selectedDayRecords.length,
                          itemBuilder: (context, index) {
                            final record = _selectedDayRecords[index];
                            return _buildRecordCard(record);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddRecord,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }

  double _getTotalForDay() {
    return _selectedDayRecords.fold(
      0.0,
      (sum, record) => sum + record.millimeters,
    );
  }

  Widget _buildRecordCard(RainRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.water_drop,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          '${record.millimeters.toStringAsFixed(1)} mm',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: record.observation != null && record.observation!.isNotEmpty
            ? Text(
                record.observation!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : Text(
                'Registrado em ${DateFormat('HH:mm').format(record.createdAt)}',
                style: TextStyle(color: Colors.grey.shade500),
              ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _editRecord(record);
            } else if (value == 'delete') {
              _deleteRecord(record);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDayState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Sem registros neste dia',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão "Adicionar" para registrar a chuva',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }
}
