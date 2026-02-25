import 'package:flutter/material.dart';

/// Agronomy-based classification of monthly rainfall.
class RainClassification {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const RainClassification({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  /// Returns a [RainClassification] based on monthly total in millimeters.
  static RainClassification fromMillimeters(double mm) {
    if (mm == 0) {
      return RainClassification(
        label: 'Sem Chuva',
        icon: Icons.wb_sunny,
        color: Colors.grey.shade500,
        background: Colors.grey.shade100,
      );
    } else if (mm <= 50) {
      return RainClassification(
        label: 'Chuva Leve',
        icon: Icons.grain,
        color: Colors.amber.shade700,
        background: Colors.amber.shade50,
      );
    } else if (mm <= 100) {
      return RainClassification(
        label: 'Chuva Moderada',
        icon: Icons.water_drop,
        color: Colors.blue.shade600,
        background: Colors.blue.shade50,
      );
    } else if (mm <= 200) {
      return RainClassification(
        label: 'Chuva Boa',
        icon: Icons.cloudy_snowing,
        color: Colors.green.shade600,
        background: Colors.green.shade50,
      );
    } else {
      return RainClassification(
        label: 'Chuva Intensa',
        icon: Icons.thunderstorm,
        color: Colors.purple.shade600,
        background: Colors.purple.shade50,
      );
    }
  }
}
