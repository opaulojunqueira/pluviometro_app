import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pluviometro_app/services/database_service.dart';
import 'package:pluviometro_app/services/preferences_service.dart';
import 'package:pluviometro_app/models/rain_record.dart';

class ManageDataScreen extends StatefulWidget {
  const ManageDataScreen({super.key});

  @override
  State<ManageDataScreen> createState() => _ManageDataScreenState();
}

class _ManageDataScreenState extends State<ManageDataScreen> {
  final PreferencesService _prefs = PreferencesService.instance;
  int _totalRecords = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final records = await DatabaseService.instance.getAllRecords();
    setState(() {
      _totalRecords = records.length;
      _isLoading = false;
    });
  }

  Future<void> _exportData() async {
    try {
      final records = await DatabaseService.instance.getAllRecords();

      // Criar JSON com os dados
      final data = {
        'app': 'Pluviômetro Digital',
        'version': '1.0.2',
        'exportDate': DateTime.now().toIso8601String(),
        'user': {
          'name': _prefs.userName,
          'city': _prefs.userCity,
          'propertyName': _prefs.propertyName,
        },
        'records': records
            .map(
              (r) => {
                'date': r.date.toIso8601String().split('T')[0],
                'millimeters': r.millimeters,
                'observation': r.observation,
              },
            )
            .toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Salvar arquivo
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'pluviometro_backup_${DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now())}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      // Compartilhar
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Backup dos dados do Pluviômetro Digital');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup exportado: ${records.length} registros + dados do perfil',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Verificar se é um backup válido
      if (data['app'] != 'Pluviômetro Digital') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arquivo de backup inválido'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final records = data['records'] as List<dynamic>;

      // Extrair dados do usuário (suporta formato novo e antigo)
      String? userName;
      String? userCity;
      String? propertyName;

      if (data['user'] != null) {
        // Formato novo
        final user = data['user'] as Map<String, dynamic>;
        userName = user['name'] as String?;
        userCity = user['city'] as String?;
        propertyName = user['propertyName'] as String?;
      } else {
        // Formato antigo
        userName = data['userName'] as String?;
        userCity = data['userCity'] as String?;
        propertyName = data['propertyName'] as String?;
      }

      // Confirmar importação
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            Icons.cloud_download_outlined,
            color: Theme.of(context).primaryColor,
            size: 48,
          ),
          title: const Text('Importar Dados'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Serão importados ${records.length} registros.'),
              const SizedBox(height: 12),
              if (userName != null && userName.isNotEmpty)
                Text('• Nome: $userName'),
              if (userCity != null && userCity.isNotEmpty)
                Text('• Cidade: $userCity'),
              if (propertyName != null && propertyName.isNotEmpty)
                Text('• Propriedade: $propertyName'),
              const SizedBox(height: 12),
              const Text(
                'Registros duplicados serão ignorados.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Deseja importar também os dados do perfil?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, 'records_only'),
              child: const Text('Só Registros'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Importar Tudo'),
            ),
          ],
        ),
      );

      if (confirmed == false || confirmed == null) return;

      // Importar dados do perfil se solicitado
      if (confirmed == true) {
        if (userName != null && userName.isNotEmpty) {
          await _prefs.setUserName(userName);
        }
        if (userCity != null && userCity.isNotEmpty) {
          await _prefs.setUserCity(userCity);
        }
        if (propertyName != null && propertyName.isNotEmpty) {
          await _prefs.setPropertyName(propertyName);
        }
      }

      int imported = 0;
      for (var record in records) {
        try {
          final date = DateTime.parse(record['date']);
          final millimeters = (record['millimeters'] as num).toDouble();
          final observation = record['observation'] as String?;

          // Verificar se já existe registro nessa data
          final existing = await DatabaseService.instance.getRecordsByDate(
            date,
          );
          if (existing.isEmpty) {
            final newRecord = RainRecord(
              date: date,
              millimeters: millimeters,
              observation: observation,
            );
            await DatabaseService.instance.createRecord(newRecord);
            imported++;
          }
        } catch (_) {}
      }

      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$imported registros importados com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
          size: 48,
        ),
        title: const Text('Atenção!'),
        content: const Text(
          'Esta ação irá excluir TODOS os registros de chuva salvos.\n\n'
          'Esta ação não pode ser desfeita. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir Tudo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.deleteAllRecords();
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos os registros foram excluídos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Dados')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estatísticas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_outlined,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLoading ? '...' : '$_totalRecords',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'registros salvos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Backup',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Exportar dados
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.upload_outlined,
                  color: Colors.green.shade600,
                  size: 28,
                ),
              ),
              title: const Text(
                'Exportar Dados',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Criar backup em JSON'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
              onTap: _exportData,
            ),
          ),

          const SizedBox(height: 8),

          // Importar dados
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.download_outlined,
                  color: Colors.blue.shade600,
                  size: 28,
                ),
              ),
              title: const Text(
                'Importar Dados',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Restaurar backup JSON'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
              onTap: _importData,
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Zona de Perigo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Excluir dados
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade200),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.red.shade600,
                  size: 28,
                ),
              ),
              title: const Text(
                'Excluir Todos os Dados',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Remove permanentemente todos os registros',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
              onTap: _confirmDeleteAllData,
            ),
          ),

          const SizedBox(height: 32),

          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dica',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Faça backup regularmente para não perder seus dados.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
