import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pluviometro_app/models/rain_record.dart';

/// Single rainfall record card shown in the dashboard's "recent records" list.
class RecentRecordCard extends StatelessWidget {
  final RainRecord record;

  const RecentRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.water_drop, color: Colors.blue.shade700),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy').format(record.date),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: record.observation != null && record.observation!.isNotEmpty
            ? Text(
                record.observation!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${record.millimeters.toStringAsFixed(1)} mm',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
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
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum registro ainda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vá para o calendário e adicione seu primeiro registro de chuva!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
