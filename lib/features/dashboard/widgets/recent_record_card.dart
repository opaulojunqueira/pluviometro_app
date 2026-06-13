import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pluviometro_app/models/rain_record.dart';
import 'package:pluviometro_app/theme/app_colors.dart';

/// Single rainfall record card shown in the dashboard's "recent records" list.
class RecentRecordCard extends StatelessWidget {
  final RainRecord record;

  const RecentRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.water_drop, color: AppColors.primary),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy').format(record.date),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: record.observation != null && record.observation!.isNotEmpty
            ? Text(
                record.observation!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${record.millimeters.toStringAsFixed(1)} mm',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state widget shown when no rainfall records exist yet.
class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum registro ainda',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vá para o calendário e adicione seu primeiro registro de chuva!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }
}
