import 'package:flutter/material.dart';
import 'package:pluviometro_app/theme/app_colors.dart';

/// Estado de carregamento padrão do app.
///
/// Centraliza o indicador + rótulo que antes era duplicado em Dashboard,
/// Calendário e Relatórios.
class LoadingView extends StatelessWidget {
  final String message;

  const LoadingView({super.key, this.message = 'Carregando...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
