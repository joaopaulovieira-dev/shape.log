import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workout_provider.dart';
import '../../data/services/workout_import_service.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
import '../../../../core/presentation/widgets/app_modals.dart';

class WorkoutListPage extends ConsumerWidget {
  const WorkoutListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsyncVal = ref.watch(routineListProvider);
    final historyListAsync = ref.watch(historyListProvider);

    return Scaffold(
      body: routinesAsyncVal.when(
        data: (routines) {
          if (kIsWeb) {
            return _buildWebList(context, ref, routines);
          }
          return CustomScrollView(
          slivers: [
            // Modern Header
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 16),
                title: Text(
                  'Meus Treinos',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _showCreateOptions(context, ref),
                ),
              ],
            ),

            // Content
            if (routines.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: Icons.fitness_center_rounded,
                  title: 'Nenhum treino encontrado',
                  subtitle: 'Crie um treino personalizado ou importe um arquivo JSON para começar a registrar seus treinos.',
                  actionLabel: 'Criar ou Importar',
                  onActionPressed: () => _showCreateOptions(context, ref),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final routine = routines[index];
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
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      return await AppDialogs.showConfirmDialog<bool>(
                        context: context,
                        title: 'Excluir Treino?',
                        description:
                            'Tem certeza que deseja excluir "${routine.name}"?',
                        confirmText: 'EXCLUIR',
                        isDestructive: true,
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
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: isToday
                            ? Border.all(
                                color: AppColors.primary.withOpacity(0.5),
                                width: 1,
                              )
                            : Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: InkWell(
                        onTap: () => context.go('/workouts/${routine.id}'),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row: Title + Badges
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      routine.name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isExpired)
                                    _buildBadge(
                                      'VENCIDO',
                                      AppColors.error.withOpacity(0.2),
                                      AppColors.error,
                                    ),
                                  if (isToday) ...[
                                    const SizedBox(width: 8),
                                    _buildBadge(
                                      'HOJE',
                                      AppColors.primary,
                                      Colors.black,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Middle Row: Days + Duration
                              Row(
                                children: [
                                  // Day Indicators
                                  Expanded(
                                    child: Row(
                                      children: List.generate(7, (i) {
                                        final dayIndex = i + 1; // 1=Mon...7=Sun
                                        // Adjust because routine uses 7=Sun, 1=Mon typically
                                        // Let's assume strict mapping for simplicity
                                        // Code used: 7=Sun, 1=Mon.
                                        final isActive = routine.scheduledDays
                                            .contains(dayIndex);
                                        final isTodayDot =
                                            now.weekday == dayIndex;

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isActive
                                                ? (isTodayDot
                                                      ? AppColors.primary
                                                      : Colors.white)
                                                : Colors.white12,
                                            boxShadow: isTodayDot
                                                ? [
                                                    const BoxShadow(
                                                      color: AppColors.primary,
                                                      blurRadius: 4,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  // Duration
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 16,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${routine.targetDurationMinutes} min',
                                        style: GoogleFonts.robotoMono(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Footer: Done Status or CTA
                              if (isDoneToday) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Treino concluído hoje!',
                                      style: TextStyle(
                                        color: AppColors.primary.withOpacity(
                                          0.8,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Toque para iniciar',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: routines.length),
              ),
          ],
        );
        },
        error: (err, stack) => Center(child: Text('Erro: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildWebList(BuildContext context, WidgetRef ref, List routines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
          child: Row(
            children: [
              Text(
                '${routines.length} treino${routines.length != 1 ? 's' : ''}',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showCreateOptions(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Novo Treino',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (routines.isEmpty)
          Expanded(
            child: AppEmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'Nenhum treino cadastrado',
              subtitle: 'Crie ou importe um treino para começar.',
              actionLabel: 'Criar ou Importar',
              onActionPressed: () => _showCreateOptions(context, ref),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 480,
                  mainAxisExtent: 130,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  final days = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
                  final dayStr = (routine.scheduledDays as List)
                      .map((d) => d < days.length ? days[d] : '')
                      .join(', ');
                  return InkWell(
                    onTap: () => context.go('/workouts/${routine.id}'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.07)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  routine.name as String,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18, color: Colors.white38),
                                    onPressed: () => context
                                        .push('/workouts/${routine.id}/edit'),
                                    tooltip: 'Editar',
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.fitness_center,
                                  size: 14, color: Colors.white38),
                              const SizedBox(width: 4),
                              Text(
                                '${(routine.exercises as List).length} exercícios',
                                style: GoogleFonts.outfit(
                                    fontSize: 12, color: Colors.white38),
                              ),
                              if (dayStr.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.calendar_today,
                                    size: 14, color: Colors.white38),
                                const SizedBox(width: 4),
                                Text(
                                  dayStr,
                                  style: GoogleFonts.outfit(
                                      fontSize: 12, color: Colors.white38),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  void _showCreateOptions(BuildContext context, WidgetRef ref) {
    AppModals.showAppModal(
      context: context,
      title: 'Criar ou Importar',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.note_add_outlined, color: Colors.white),
            title: const Text(
              'Importar Arquivo (.json)',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _handleFileImport(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.content_paste_go, color: Colors.white),
            title: const Text(
              'Colar Treino',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _showPasteJsonDialog(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.white),
            title: const Text(
              'Criar Novo Treino',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/workouts/add');
            },
          ),
          const SizedBox(height: 16),
        ],
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
        backgroundColor: AppColors.surface,
        elevation: 0,
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.5),
        ),
        title: Text(
          'Colar Treino (JSON)',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 10,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Cole o JSON aqui...',
            hintStyle: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[400],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'CANCELAR',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 4),
          FilledButton(
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
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'PROCESSAR',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
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
