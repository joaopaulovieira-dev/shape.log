import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workout_provider.dart';
import 'package:shape_log/core/constants/app_colors.dart';

class WorkoutListPage extends ConsumerWidget {
  const WorkoutListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsyncVal = ref.watch(routineListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treinos'),
        // Report logic temporarily disabled until History UI is ready
      ),
      body: routinesAsyncVal.when(
        data: (routines) => routines.isEmpty
            ? const Center(child: Text('Nenhum treino cadastrado.'))
            : ListView.builder(
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  // Format scheduled days
                  final daysStr = routine.scheduledDays.isEmpty
                      ? 'Sem agendamento'
                      : routine.scheduledDays
                            .map((d) {
                              // Simple mapping or use DateFormat if needed, but 'd' is int 1-7
                              const days = [
                                'Dom',
                                'Seg',
                                'Ter',
                                'Qua',
                                'Qui',
                                'Sex',
                                'Sáb',
                              ];
                              // Note: ISO 8601: 1=Mon, 7=Sun. List index: 0=Dom(Sun)?
                              // Let's assume user input 1=Mon.
                              // Dart DateTime.weekday: 1=Mon, 7=Sun.
                              // My days array: 0=Dom.
                              // Let's settle on: 1=Mon (Seg), 7=Sun (Dom).
                              // Index for days array:
                              // 1 (Seg) -> Index 1. 7 (Dom) -> Index 0.
                              if (d == 7) return 'Dom';
                              return days[d]; // 1=Seg, 2=Ter...
                            })
                            .join(', ');

                  final now = DateTime.now();
                  final isToday = routine.scheduledDays.contains(now.weekday);
                  final isExpired =
                      routine.expiryDate != null &&
                      routine.expiryDate!.isBefore(now);

                  return Dismissible(
                    key: ValueKey(routine.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await ref
                          .read(workoutRepositoryProvider)
                          .deleteRoutine(routine.id);
                      ref.invalidate(routineListProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Treino excluído')),
                        );
                      }
                    },
                    child: Card(
                      color: isToday
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surface,
                      shape: isToday
                          ? RoundedRectangleBorder(
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            )
                          : RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                      elevation: isToday ? 4 : 0,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isToday
                              ? AppColors.primary
                              : Colors.white12,
                          foregroundColor: isToday
                              ? Colors.black
                              : AppColors.textPrimary,
                          child: Text(
                            routine.name.isNotEmpty
                                ? routine.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              routine.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              _buildBadge(
                                'HOJE',
                                AppColors.primary,
                                Colors.black,
                              ),
                            ],
                            if (isExpired) ...[
                              const SizedBox(width: 8),
                              _buildBadge(
                                'VENCIDO',
                                AppColors.error,
                                Colors.white,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          daysStr,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Text(
                          '${routine.targetDurationMinutes} min',
                          style: const TextStyle(color: AppColors.primary),
                        ),
                        onTap: () {
                          context.go('/workouts/${routine.id}');
                        },
                      ),
                    ),
                  );
                },
              ),
        error: (err, stack) => Center(child: Text('Erro: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/workouts/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
