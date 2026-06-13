import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pluviometro_app/models/rain_record.dart';
import 'package:pluviometro_app/theme/app_colors.dart';

/// A partir de quantos dias sem chuva o app sinaliza alerta de estiagem.
const int kDroughtAlertDays = 10;

/// Card de destaque (hero) do dashboard.
///
/// Reúne duas informações que o produtor mais procura ao abrir o app:
///  • a **última leitura** registrada (valor + quando);
///  • há **quantos dias não chove**, com alerta de estiagem quando o período
///    passa de [kDroughtAlertDays] dias.
class LastReadingCard extends StatelessWidget {
  /// Registro mais recente (qualquer valor, inclusive 0 mm).
  final RainRecord lastRecord;

  /// Registro mais recente com chuva de verdade (mm > 0). Pode ser nulo.
  final RainRecord? lastRainyRecord;

  const LastReadingCard({
    super.key,
    required this.lastRecord,
    required this.lastRainyRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Última leitura',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                _relativeDay(lastRecord.date),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_formatMm(lastRecord.millimeters)} mm',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatus(),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    final _DroughtStatus status = _resolveStatus();

    // Estado de alerta: âmbar sólido com texto escuro (alto contraste).
    // Estado normal: faixa translúcida sobre o azul, texto branco.
    final Color bg = status.isAlert
        ? AppColors.amber
        : Colors.white.withValues(alpha: 0.16);
    final Color fg = status.isAlert ? AppColors.textPrimary : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(status.icon, color: fg, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status.label,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _DroughtStatus _resolveStatus() {
    if (lastRainyRecord == null) {
      return const _DroughtStatus(
        label: 'Nenhuma chuva registrada ainda',
        icon: Icons.info_outline,
        isAlert: false,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rainyDay = DateTime(
      lastRainyRecord!.date.year,
      lastRainyRecord!.date.month,
      lastRainyRecord!.date.day,
    );
    final days = today.difference(rainyDay).inDays;

    if (days <= 0) {
      return const _DroughtStatus(
        label: 'Choveu hoje',
        icon: Icons.water_drop,
        isAlert: false,
      );
    }
    if (days == 1) {
      return const _DroughtStatus(
        label: 'Choveu ontem',
        icon: Icons.water_drop,
        isAlert: false,
      );
    }
    if (days < kDroughtAlertDays) {
      return _DroughtStatus(
        label: 'Há $days dias sem chuva',
        icon: Icons.schedule,
        isAlert: false,
      );
    }
    return _DroughtStatus(
      label: '$days dias sem chuva — atenção à estiagem',
      icon: Icons.wb_sunny,
      isAlert: true,
    );
  }

  /// Texto relativo amigável para a data ("Hoje", "Ontem", "Há N dias" ou data).
  String _relativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;

    if (diff <= 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    if (diff < 7) return 'Há $diff dias';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatMm(double mm) => mm.toStringAsFixed(1).replaceAll('.', ',');
}

/// Resultado da avaliação de estiagem (texto, ícone e se é alerta).
class _DroughtStatus {
  final String label;
  final IconData icon;
  final bool isAlert;

  const _DroughtStatus({
    required this.label,
    required this.icon,
    required this.isAlert,
  });
}
