import 'package:flutter/material.dart';

/// Paleta central do Pluviômetro Digital.
///
/// Identidade: **azul-chuva** como cor-mãe (a essência do pluviômetro é a
/// água/chuva) e **verde-agro** como cor de apoio. O âmbar/sol é reservado
/// para alertas de estiagem e destaques pontuais.
///
/// Todas as telas devem consumir estas constantes em vez de declarar cores
/// soltas — assim a experiência fica consistente de ponta a ponta.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Azul-chuva — cor primária
  // ---------------------------------------------------------------------------
  /// Cor principal da marca, usada em botões, ícones ativos e destaques.
  static const Color primary = Color(0xFF1565C0);

  /// Tom mais profundo — AppBar, splash e estados pressionados.
  static const Color primaryDark = Color(0xFF0D4D94);

  /// Fundo claro para realces, chips e containers de ícone.
  static const Color primarySoft = Color(0xFFE7F0FA);

  // ---------------------------------------------------------------------------
  // Verde-agro — cor de apoio
  // ---------------------------------------------------------------------------
  static const Color secondary = Color(0xFF2E7D32);
  static const Color secondarySoft = Color(0xFFE6F2E7);

  // ---------------------------------------------------------------------------
  // Âmbar/sol — alertas de estiagem e destaques quentes
  // ---------------------------------------------------------------------------
  static const Color amber = Color(0xFFE08A1E);
  static const Color amberSoft = Color(0xFFFBF0DD);

  // ---------------------------------------------------------------------------
  // Superfícies e estrutura
  // ---------------------------------------------------------------------------
  /// Fundo geral das telas — neutro com leve viés azulado.
  static const Color background = Color(0xFFF4F7FB);

  /// Superfície de cards e folhas.
  static const Color surface = Colors.white;

  /// Borda sutil dos cards (substitui sombras pesadas).
  static const Color border = Color(0xFFE6EBF1);

  // ---------------------------------------------------------------------------
  // Texto
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Color(0xFF1B2733);
  static const Color textSecondary = Color(0xFF5C6B7A);
  static const Color textMuted = Color(0xFF93A1AE);

  // ---------------------------------------------------------------------------
  // Cores semânticas
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF2E7D32);
  static const Color successSoft = Color(0xFFE6F2E7);
  static const Color warning = Color(0xFFE08A1E);
  static const Color warningSoft = Color(0xFFFBF0DD);
  static const Color danger = Color(0xFFD24A41);
  static const Color dangerSoft = Color(0xFFFBE7E5);
}
