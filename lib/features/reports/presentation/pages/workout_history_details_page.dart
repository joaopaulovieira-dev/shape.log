import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shape_log/core/utils/snackbar_utils.dart';
import 'package:shape_log/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:shape_log/features/workout/domain/entities/workout_history.dart';
import 'package:shape_log/features/workout/domain/services/workout_report_service.dart';

import 'package:shape_log/features/workout/presentation/providers/workout_provider.dart';

class WorkoutHistoryDetailsPage extends ConsumerWidget {
  final WorkoutHistory history;

  const WorkoutHistoryDetailsPage({super.key, required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Generate Report
    final userAsync = ref.watch(userProfileProvider);
    final user = userAsync.value;
    final reportText = WorkoutReportService().generateDetailedReport(
      history,
      user,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('dd/MM/yyyy - HH:mm').format(history.completedDate),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copiar Relatório',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: reportText));
              if (context.mounted) {
                SnackbarUtils.showSuccess(
                  context,
                  'Relatório copiado para IA!',
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: SelectableText(
                  reportText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _confirmDelete(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_forever),
                label: const Text(
                  'EXCLUIR REGISTRO',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Treino?'),
        content: const Text(
          'Essa ação apagará permanentemente este registro do seu histórico e afetará seus gráficos. Tem certeza?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close Dialog

              // Perform Delete
              await ref
                  .read(workoutRepositoryProvider)
                  .deleteHistory(history.id);

              if (context.mounted) {
                Navigator.pop(context); // Close Page
                SnackbarUtils.showSuccess(
                  context,
                  'Treino excluído com sucesso.',
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SIM, EXCLUIR'),
          ),
        ],
      ),
    );
  }
}
