import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pluviometro_app/services/preferences_service.dart';
import 'package:pluviometro_app/shared/widgets/shared_app_bar.dart';
import 'package:pluviometro_app/features/profile/profile_screen.dart';
import 'package:pluviometro_app/features/data_management/manage_data_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => SettingsTabState();
}

class SettingsTabState extends State<SettingsTab> {
  final PreferencesService _prefs = PreferencesService.instance;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Refreshes notification settings state — called by HomeScreen on tab switch.
  void refresh() {
    setState(() {
      _notificationsEnabled = _prefs.notificationsEnabled;
    });
  }

  void _loadSettings() {
    _notificationsEnabled = _prefs.notificationsEnabled;
  }


  void _navigateToManageData() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ManageDataScreen()));
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'contato@paulojunqueira.com',
      queryParameters: {'subject': 'Pluviômetro Digital - Contato'},
    );
    try {
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o email'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Configurações',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Personalize o app do seu jeito',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Profile navigation tile
          Card(
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    SharedAppBar.getInitials(_prefs.userName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                _prefs.userName.isNotEmpty ? _prefs.userName : 'Meu Perfil',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Informações pessoais e propriedade'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ))
                    .then((_) => setState(() {}));
              },
            ),
          ),

          const SizedBox(height: 24),

          // Notifications toggle
          Card(
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: Colors.orange.shade400,
                ),
              ),
              title: const Text(
                'Notificações',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Receber lembretes'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _prefs.setNotificationsEnabled(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Notificações ativadas'
                          : 'Notificações desativadas',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Data management tile
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.storage_outlined,
                  color: Colors.purple.shade400,
                ),
              ),
              title: const Text(
                'Gerenciar Dados',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Backup, restaurar e excluir'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
              onTap: _navigateToManageData,
            ),
          ),

          const SizedBox(height: 24),

          // About section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.water_drop,
                      color: Theme.of(context).primaryColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pluviômetro Digital',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versão 1.0.2',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Desenvolvido por',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Paulo Junqueira',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'paulojunqueira.com',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Text(
                    'contato@paulojunqueira.com',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _launchEmail,
                        icon: const Icon(Icons.email_outlined, size: 18),
                        label: const Text('E-mail'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _launchUrl('https://paulojunqueira.com'),
                        icon: const Icon(Icons.language, size: 18),
                        label: const Text('Site'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              'Feito com ❤️ para o produtor rural',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
