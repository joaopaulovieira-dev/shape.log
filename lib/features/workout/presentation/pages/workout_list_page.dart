import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workout_provider.dart';
import '../../data/services/workout_import_service.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';

class WorkoutListPage extends ConsumerWidget {
  const WorkoutListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsyncVal = ref.watch(routineListProvider);
    final historyListAsync = ref.watch(historyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treinos'),
        // Report logic temporarily disabled until History UI is ready
      ),
      body: routinesAsyncVal.when(
        data: (routines) => routines.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Nenhum treino cadastrado.'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _showCreateOptions(context, ref),
                      child: const Text('Criar ou Importar Treino'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  // Format scheduled days
                  final daysStr = routine.scheduledDays.isEmpty
                      ? 'Sem agendamento'
                      : routine.scheduledDays
                            .map((d) {
                              const days = [
                                'Dom',
                                'Seg',
                                'Ter',
                                'Qua',
                                'Qui',
                                'Sex',
                                'Sáb',
                              ];
                              if (d == 7) return 'Dom';
                              return days[d];
                            })
                            .join(', ');

                  final now = DateTime.now();
                  final isToday = routine.scheduledDays.contains(now.weekday);
                  final isExpired =
                      routine.expiryDate != null &&
                      routine.expiryDate!.isBefore(now);

                  final isDoneToday =
                      historyListAsync.asData?.value.any(
                        (h) =>
                            h.workoutId == routine.id &&
                            h.completedDate.year == now.year &&
                            h.completedDate.month == now.month &&
                            h.completedDate.day == now.day,
                      ) ??
                      false;

                  return Dismissible(
                    key: ValueKey(routine.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text(
                              'Excluir Treino?',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            content: Text(
                              'Tem certeza que deseja excluir "${routine.name}"? Esta ação não pode ser desfeita.',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Excluir'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (_) async {
                      await ref
                          .read(workoutRepositoryProvider)
                          .deleteRoutine(routine.id);
                      ref.invalidate(routineListProvider);
                      if (context.mounted) {
                        SnackbarUtils.showInfo(context, 'Treino excluído');
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
                            Expanded(
                              child: MarqueeWidget(
                                child: Text(
                                  routine.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              daysStr,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (isDoneToday)
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Treino Finalizado',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
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
        onPressed: () => _showCreateOptions(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Importar Arquivo (.json)'),
              onTap: () {
                Navigator.pop(context);
                _handleFileImport(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste_go),
              title: const Text('Colar Treino'),
              onTap: () {
                Navigator.pop(context);
                _showPasteJsonDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Criar Novo Treino'),
              onTap: () {
                Navigator.pop(context);
                context.go('/workouts/add');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFileImport(BuildContext context, WidgetRef ref) async {
    try {
      final count = await ref
          .read(workoutImportServiceProvider)
          .importFromFile(context);
      if (count != null && context.mounted) {
        SnackbarUtils.showSuccess(
          context,
          '$count ${count == 1 ? 'treino importado' : 'treinos importados'} com sucesso!',
        );
      }
    } catch (e) {
      debugPrint('Erro importação arquivo: $e');
      if (context.mounted) {
        SnackbarUtils.showError(context, 'Erro ao importar arquivo: $e');
      }
    }
  }

  void _showPasteJsonDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Colar Treino (JSON)'),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Cole o JSON aqui...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;

              Navigator.pop(context);
              try {
                final count = await ref
                    .read(workoutImportServiceProvider)
                    .importFromText(text);
                if (count != null && context.mounted) {
                  SnackbarUtils.showSuccess(
                    context,
                    '$count ${count == 1 ? 'treino importado' : 'treinos importados'} com sucesso!',
                  );
                }
              } catch (e) {
                debugPrint('Erro ao colar JSON: $e');
                if (context.mounted) {
                  SnackbarUtils.showError(context, 'Erro: $e');
                }
              }
            },
            child: const Text('Processar'),
          ),
        ],
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

class MarqueeWidget extends StatefulWidget {
  final Widget child;
  final Duration animationDuration, backDuration, pauseDuration;

  const MarqueeWidget({
    super.key,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 6000),
    this.backDuration = const Duration(milliseconds: 800),
    this.pauseDuration = const Duration(milliseconds: 800),
  });

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scroll());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scroll() async {
    while (_scrollController.hasClients) {
      await Future.delayed(widget.pauseDuration);
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions &&
          _scrollController.position.maxScrollExtent > 0) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: widget.animationDuration,
          curve: Curves.linear,
        );
      }
      await Future.delayed(widget.pauseDuration);
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions &&
          _scrollController.offset > 0) {
        await _scrollController.animateTo(
          0.0,
          duration: widget.backDuration,
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      physics: const NeverScrollableScrollPhysics(), // Automatic scroll
      child: widget.child,
    );
  }
}
