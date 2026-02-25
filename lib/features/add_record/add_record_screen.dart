import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pluviometro_app/services/database_service.dart';
import 'package:pluviometro_app/models/rain_record.dart';

class AddRecordScreen extends StatefulWidget {
  final DateTime selectedDate;
  final RainRecord? existingRecord;

  const AddRecordScreen({
    super.key,
    required this.selectedDate,
    this.existingRecord,
  });

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mmController = TextEditingController();
  final _observationController = TextEditingController();
  final DatabaseService _db = DatabaseService.instance;
  bool _isLoading = false;

  bool get isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _mmController.text = widget.existingRecord!.millimeters.toString();
      _observationController.text = widget.existingRecord!.observation ?? '';
    }
  }

  @override
  void dispose() {
    _mmController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final millimeters = double.parse(_mmController.text.replaceAll(',', '.'));
      final observation = _observationController.text.trim();

      if (isEditing) {
        final updatedRecord = widget.existingRecord!.copyWith(
          millimeters: millimeters,
          observation: observation.isEmpty ? null : observation,
        );
        await _db.updateRecord(updatedRecord);
      } else {
        final newRecord = RainRecord(
          date: widget.selectedDate,
          millimeters: millimeters,
          observation: observation.isEmpty ? null : observation,
        );
        await _db.createRecord(newRecord);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Registro atualizado com sucesso!'
                : 'Registro salvo com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Registro' : 'Novo Registro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date display
              Card(
                elevation: 0,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.blue.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data do registro',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                "EEEE, dd 'de' MMMM 'de' yyyy",
                                'pt_BR',
                              ).format(widget.selectedDate),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Millimeters input
              Text(
                'Quantidade de chuva *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mmController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0.0',
                  suffixText: 'mm',
                  suffixStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                  prefixIcon: const Icon(Icons.water_drop, size: 28),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite a quantidade em mm';
                  }
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null) {
                    return 'Valor inválido';
                  }
                  if (parsed < 0) {
                    return 'O valor não pode ser negativo';
                  }
                  if (parsed > 500) {
                    return 'Valor parece muito alto. Verifique!';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),
              Text(
                'Dica: Verifique o pluviômetro e anote a quantidade de água acumulada em milímetros.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),

              const SizedBox(height: 24),

              // Observation input
              Text(
                'Observações (opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _observationController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ex: Chuva forte no final da tarde, com granizo...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.notes),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Quick values
              Text(
                'Valores rápidos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickValueChip(5),
                  _buildQuickValueChip(10),
                  _buildQuickValueChip(15),
                  _buildQuickValueChip(20),
                  _buildQuickValueChip(25),
                  _buildQuickValueChip(30),
                  _buildQuickValueChip(50),
                  _buildQuickValueChip(100),
                ],
              ),

              const SizedBox(height: 32),

              // Save button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveRecord,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(isEditing ? Icons.save : Icons.add),
                label: Text(
                  _isLoading
                      ? 'Salvando...'
                      : (isEditing ? 'Atualizar Registro' : 'Salvar Registro'),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel button
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickValueChip(int value) {
    return ActionChip(
      label: Text('$value mm'),
      onPressed: () {
        _mmController.text = value.toString();
      },
      backgroundColor: Colors.blue.shade50,
      labelStyle: TextStyle(
        color: Colors.blue.shade700,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
