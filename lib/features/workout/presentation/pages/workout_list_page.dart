import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workout_provider.dart';

class WorkoutListPage extends ConsumerWidget {
  const WorkoutListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsyncVal = ref.watch(routineListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon/logo.png', height: 32),
            const SizedBox(width: 12),
            const Text('Shape.log'),
          ],
        ),
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
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          routine.name.isNotEmpty
                              ? routine.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(routine.name),
                      subtitle: Text(daysStr),
                      trailing: Text('${routine.targetDurationMinutes} min'),
                      onTap: () {
                        context.go('/workouts/${routine.id}');
                      },
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
}
