import 'package:flutter/material.dart';
import 'package:pluviometro_app/services/preferences_service.dart';
import 'package:pluviometro_app/theme/app_colors.dart';
import 'package:pluviometro_app/features/home/home_screen.dart';

class SkipLoginScreen extends StatefulWidget {
  const SkipLoginScreen({super.key});

  @override
  State<SkipLoginScreen> createState() => _SkipLoginScreenState();
}

class _SkipLoginScreenState extends State<SkipLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = PreferencesService.instance;
    await prefs.setLoggedIn(false);
    await prefs.setUserSetupCompleted(true);
    await prefs.setOnboardingCompleted(true);
    await prefs.setUserName(_nameController.text);
    await prefs.setUserCity(_cityController.text);

    if (!mounted) return;

    setState(() => _isLoading = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // Icon
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Seus Dados',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Precisamos de algumas informações básicas para continuar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 48),
                // Name field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Seu nome',
                    prefixIcon: Icon(Icons.person_outlined),
                    hintText: 'Ex: João Silva',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite seu nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // City field
                TextFormField(
                  controller: _cityController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Sua cidade',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    hintText: 'Ex: Londrina - PR',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite sua cidade';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 48),
                // Continue button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleContinue,
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
                      : const Icon(Icons.arrow_forward),
                  label: Text(_isLoading ? 'Aguarde...' : 'Continuar'),
                ),
                const SizedBox(height: 24),
                // Info text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Seus dados ficam salvos apenas neste aparelho e podem ser '
                          'editados quando quiser no seu perfil.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
