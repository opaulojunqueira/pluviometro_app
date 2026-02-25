import 'package:flutter/material.dart';
import 'package:pluviometro_app/services/preferences_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PreferencesService _prefs = PreferencesService.instance;
  final _propertyController = TextEditingController();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isEditingUserInfo = false;
  bool _isEditingProperty = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    _propertyController.text = _prefs.propertyName;
    _nameController.text = _prefs.userName;
    _cityController.text = _prefs.userCity;
  }

  @override
  void dispose() {
    _propertyController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveUserInfo() async {
    await _prefs.setUserName(_nameController.text);
    await _prefs.setUserCity(_cityController.text);
    setState(() => _isEditingUserInfo = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informações salvas com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _savePropertyName() async {
    await _prefs.setPropertyName(_propertyController.text);
    setState(() => _isEditingProperty = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Propriedade salva com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _getInitials() {
    final name = _prefs.userName;
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar grande
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text
                  : 'Usuário',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (_cityController.text.isNotEmpty)
            Center(
              child: Text(
                _cityController.text,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),

          const SizedBox(height: 32),

          // Seção: Suas Informações
          _buildSectionTitle('Suas Informações', Icons.person_outline),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.person_outlined,
                    label: 'Nome',
                    value: _nameController.text,
                    controller: _nameController,
                    isEditing: _isEditingUserInfo,
                    hintText: 'Digite seu nome',
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.location_city_outlined,
                    label: 'Cidade',
                    value: _cityController.text,
                    controller: _cityController,
                    isEditing: _isEditingUserInfo,
                    hintText: 'Digite sua cidade',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _isEditingUserInfo
                        ? Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    _loadPreferences();
                                    setState(() => _isEditingUserInfo = false);
                                  },
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _saveUserInfo,
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Salvar'),
                                ),
                              ),
                            ],
                          )
                        : OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => _isEditingUserInfo = true),
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Seção: Propriedade Rural
          _buildSectionTitle('Propriedade Rural', Icons.agriculture),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.home_work_outlined,
                    label: 'Nome da Propriedade',
                    value: _propertyController.text,
                    controller: _propertyController,
                    isEditing: _isEditingProperty,
                    hintText: 'Ex: Fazenda São João',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _isEditingProperty
                        ? Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    _loadPreferences();
                                    setState(() => _isEditingProperty = false);
                                  },
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _savePropertyName,
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Salvar'),
                                ),
                              ),
                            ],
                          )
                        : OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => _isEditingProperty = true),
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    required String hintText,
  }) {
    if (isEditing) {
      return TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          hintText: hintText,
        ),
      );
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : 'Não informado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: value.isNotEmpty
                      ? Colors.black87
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
