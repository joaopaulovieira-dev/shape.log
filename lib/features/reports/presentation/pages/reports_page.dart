import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import 'package:shape_log/features/body_tracker/presentation/providers/body_tracker_provider.dart';
import 'package:shape_log/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:shape_log/features/workout/presentation/providers/workout_provider.dart';
import 'package:shape_log/features/reports/presentation/widgets/advanced_analytics_widgets.dart';
import 'package:shape_log/features/workout/domain/services/workout_report_service.dart';
import 'package:shape_log/features/workout/domain/entities/workout_history.dart';
import 'package:shape_log/features/workout/domain/entities/exercise.dart';
import 'package:shape_log/features/reports/presentation/pages/workout_history_details_page.dart';

// Hive imports
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../../../../features/workout/data/models/workout_history_hive_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/utils/image_path_resolver.dart';
import '../../../image_library/presentation/image_source_sheet.dart';
import '../../../common/presentation/widgets/full_screen_image_viewer.dart';
import '../../../common/services/image_storage_service.dart';
import '../../../../core/services/web_image_service.dart';
import '../../../../core/presentation/widgets/app_modals.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
import '../../../../core/services/sync_service.dart';

enum HubMode { analytics, logs }

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  HubMode _currentMode = HubMode.analytics;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: kIsWeb
          ? ref
                .watch(historyListProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _buildWebLayout(<WorkoutHistory>[]),
                  data: (list) {
                    final sorted = [...list]
                      ..sort(
                        (a, b) => b.completedDate.compareTo(a.completedDate),
                      );
                    return _buildWebLayout(sorted);
                  },
                )
          : ValueListenableBuilder<Box<WorkoutHistoryHiveModel>>(
              valueListenable: Hive.box<WorkoutHistoryHiveModel>(
                'history_log',
              ).listenable(),
              builder: (context, box, _) {
                final historyList = box.values.map((e) => e.toEntity()).toList()
                  ..sort((a, b) => b.completedDate.compareTo(a.completedDate));
                return _buildBody(historyList);
              },
            ),
    );
  }

  // ── Web layout ────────────────────────────────────────────────────────────
  Widget _buildWebLayout(List<WorkoutHistory> history) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // Sidebar com tabs
          Container(
            width: 200,
            color: const Color(0xFF0A0A0A),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'HUB',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white38,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _WebTabButton(
                  icon: Icons.bar_chart,
                  label: 'Analytics',
                  selected: _currentMode == HubMode.analytics,
                  onTap: () => setState(() => _currentMode = HubMode.analytics),
                ),
                const SizedBox(height: 4),
                _WebTabButton(
                  icon: Icons.list_alt,
                  label: 'Histórico',
                  selected: _currentMode == HubMode.logs,
                  onTap: () => setState(() => _currentMode = HubMode.logs),
                ),
              ],
            ),
          ),
          Container(width: 1, color: Colors.white.withOpacity(0.06)),
          // Conteúdo
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _currentMode == HubMode.analytics
                  ? _AnalyticsTab(
                      key: const ValueKey('analytics_web'),
                      history: history,
                    )
                  : _HistoryTab(
                      key: const ValueKey('logs_web'),
                      history: history,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<WorkoutHistory> historyList) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                'Intelligence Hub',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: _buildHubSelector(),
            ),
          ),
        ];
      },
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: _currentMode == HubMode.analytics
            ? _AnalyticsTab(
                key: const ValueKey('analytics'),
                history: historyList,
              )
            : _HistoryTab(key: const ValueKey('logs'), history: historyList),
      ),
    );
  }

  Widget _buildHubSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _buildSelectorOption(
            mode: HubMode.analytics,
            label: 'ANALYTICS',
            icon: Icons.auto_graph_rounded,
          ),
          _buildSelectorOption(
            mode: HubMode.logs,
            label: 'LOGS & IA',
            icon: Icons.history_edu_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorOption({
    required HubMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.black : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isSelected ? Colors.black : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsTab extends StatefulWidget {
  final List<WorkoutHistory> history;

  const _AnalyticsTab({super.key, required this.history});

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  String _filterMode = '30_days'; // '30_days', 'all'

  @override
  Widget build(BuildContext context) {
    // Use passed history instead of ref.watch
    final history = widget.history;

    if (history.isEmpty) {
      return const AppEmptyState(
        icon: Icons.bar_chart_rounded,
        title: 'Sem dados suficientes',
        subtitle:
            'Complete seu primeiro treino para desbloquear a análise inteligente de volume, consistência e grupamentos musculares.',
      );
    }

    // Apply Filter
    final filteredHistory = history.where((h) {
      if (_filterMode == 'all') return true;
      final diff = DateTime.now().difference(h.completedDate).inDays;
      if (_filterMode == '7_days') return diff <= 7;
      if (_filterMode == '30_days') return diff <= 30;
      if (_filterMode == '90_days') return diff <= 90;
      return true;
    }).toList();

    if (filteredHistory.isEmpty && _filterMode != 'all') {
      return const AppEmptyState(
        icon: Icons.filter_list_off_rounded,
        title: 'Sem dados no período',
        subtitle: 'Nenhum treino foi concluído no período selecionado.',
      );
    }

    // ── Filtro comum ──────────────────────────────────────────────────────────
    final filterWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: PopupMenuButton<String>(
        initialValue: _filterMode,
        onSelected: (value) => setState(() => _filterMode = value),
        offset: const Offset(0, 40),
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list, color: Colors.grey, size: 16),
            const SizedBox(width: 8),
            Text(
              _filterMode == 'all'
                  ? 'Tudo'
                  : _filterMode == '30_days'
                  ? '30 Dias'
                  : _filterMode == '90_days'
                  ? '90 Dias'
                  : '7 Dias',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 16),
          ],
        ),
        itemBuilder: (context) => [
          _buildPopupItem('all', 'Tudo'),
          _buildPopupItem('90_days', 'Últimos 90 dias'),
          _buildPopupItem('30_days', 'Últimos 30 dias'),
          _buildPopupItem('7_days', 'Últimos 7 dias'),
        ],
      ),
    );

    if (kIsWeb) {
      return _buildWebAnalytics(filteredHistory, filterWidget);
    }

    // ── Mobile layout ─────────────────────────────────────────────────────────
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [filterWidget],
          ),
          const SizedBox(height: 24),
          VolumeLoadChart(
            history: filteredHistory,
            isAllTime: _filterMode == 'all',
          ),
          const SizedBox(height: 24),
          ConsistencyHeatmap(history: filteredHistory),
          const SizedBox(height: 24),
          BalancePieChart(history: filteredHistory),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Web analytics layout — grid 2 colunas ──────────────────────────────────
  Widget _buildWebAnalytics(List<WorkoutHistory> history, Widget filterWidget) {
    // Métricas de resumo
    final totalSessions = history.length;
    final avgDuration = totalSessions == 0
        ? 0
        : (history.fold(0, (s, h) => s + h.durationMinutes) / totalSessions)
              .round();
    final avgCompletion = totalSessions == 0
        ? 0.0
        : history.fold(0.0, (s, h) => s + h.completionPercentage) /
              totalSessions;
    final totalVolume = history.fold(0.0, (sum, h) {
      for (final ex in h.exercises) {
        if (ex.type == ExerciseTypeEntity.weight) {
          if (ex.setsHistory != null && ex.setsHistory!.isNotEmpty) {
            for (final s in ex.setsHistory!) {
              sum += s.weight * s.reps;
            }
          } else {
            sum += ex.weight * ex.reps * ex.sets;
          }
        }
      }
      return sum;
    });

    Widget kpi(String label, String value, IconData icon, Color c) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: c, size: 16),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    Widget card(String title, Widget child, {String? hint}) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (dialogContext) => Dialog(
                      backgroundColor: const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: SizedBox(
                        width: 420,
                        child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              hint,
                              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70, height: 1.6),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text('Fechar', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                  child: Icon(Icons.help_outline_rounded, size: 15, color: Colors.white24),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtro + KPIs
          Row(
            children: [
              kpi(
                'Sessões',
                '$totalSessions',
                Icons.fitness_center,
                AppColors.primary,
              ),
              const SizedBox(width: 12),
              kpi(
                'Duração média',
                '${avgDuration}min',
                Icons.timer_outlined,
                Colors.blueAccent,
              ),
              const SizedBox(width: 12),
              kpi(
                'Conclusão média',
                '${avgCompletion.toStringAsFixed(0)}%',
                Icons.check_circle_outline,
                Colors.tealAccent,
              ),
              const SizedBox(width: 12),
              kpi(
                'Volume total',
                totalVolume >= 1000
                    ? '${(totalVolume / 1000).toStringAsFixed(1)}t'
                    : '${totalVolume.toStringAsFixed(0)}kg',
                Icons.bar_chart,
                Colors.purpleAccent,
              ),
              const SizedBox(width: 16),
              filterWidget,
            ],
          ),
          const SizedBox(height: 24),

          // Linha 1: Volume + Consistência
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: card(
                  'Volume de Treino',
                  VolumeLoadChart(
                    history: history,
                    isAllTime: _filterMode == 'all',
                  ),
                  hint: 'Mostra a carga total movida por semana (kg × repetições × séries). Picos indicam semanas de alta intensidade; quedas podem sinalizar deload ou ausências. Use para identificar tendências de progressão ao longo do tempo.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: card(
                  'Consistência Semanal',
                  ConsistencyHeatmap(history: history),
                  hint: 'Mapa de calor com a frequência de treinos por dia da semana. Quanto mais intensa a cor, mais sessões foram realizadas naquele dia. Ajuda a identificar seus dias mais produtivos e eventuais lacunas de consistência.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Linha 2: Balanço muscular + Duração das sessões
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: card(
                  'Balanço Muscular',
                  BalancePieChart(history: history),
                  hint: 'Distribuição dos treinos por grupo muscular principal. Um gráfico equilibrado indica uma rotina completa. Fatias muito grandes em um grupo podem indicar sobretreinamento; fatias pequenas revelam grupos negligenciados.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: card(
                  'Duração das Sessões',
                  _SessionDurationChart(history: history),
                  hint: 'Duração de cada sessão de treino em minutos, ordenada do mais recente para o mais antigo. A linha de referência indica sua média. Sessões muito curtas podem indicar treinos incompletos; muito longas podem sinalizar baixa intensidade.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Linha 3: Top exercícios (largura total)
          card(
            'Top Exercícios por Frequência',
            _TopExercisesChart(history: history),
            hint: 'Os exercícios mais realizados no período selecionado, ordenados por número de aparições nos treinos. Revela seus movimentos base e pode indicar excessiva repetição ou, pelo contrário, exercícios importantes pouco praticados.',
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(
        label,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
      ),
    );
  }
}

class _HistoryTab extends ConsumerStatefulWidget {
  final List<WorkoutHistory> history;

  const _HistoryTab({super.key, required this.history});

  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<_HistoryTab> {
  List<WorkoutHistory> get history => widget.history;

  Future<void> _refresh() async {
    try {
      await ref.read(syncServiceProvider).syncHistoryFromFirestore();
    } catch (e) {
      debugPrint('[refresh] $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebHistory(context, ref);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () async {
                try {
                  final measurements = ref.read(bodyTrackerProvider);
                  final user = await ref.read(userProfileProvider.future);

                  final report = WorkoutReportService().generateGeneralReport(
                    history,
                    measurements,
                    user,
                  );

                  await Clipboard.setData(ClipboardData(text: report));

                  if (context.mounted) {
                    SnackbarUtils.showSuccess(
                      context,
                      'Dossiê Geral copiado para IA!',
                    );
                  }
                } catch (e) {
                  debugPrint('Error generating report: $e');
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'EXPORTAR DOSSIÊ GERAL (IA)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            backgroundColor: const Color(0xFF1A1A1A),
            child: history.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 80),
                    AppEmptyState(
                      icon: Icons.history_rounded,
                      title: 'Nenhum treino realizado',
                      subtitle:
                          'Seu histórico de treinos concluídos aparecerá aqui. Inicie um treino hoje mesmo!',
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final h = history[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: InkWell(
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WorkoutHistoryDetailsPage(history: h),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Workout Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          h.workoutName,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat(
                                                'dd/MM • HH:mm',
                                              ).format(h.completedDate),
                                              style: GoogleFonts.robotoMono(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.timer_outlined,
                                              size: 14,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${h.durationMinutes} min',
                                              style: GoogleFonts.robotoMono(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // RPE Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Text(
                                      _getRpeEmoji(h.rpe),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ],
                              ),

                              // Actions / Thumbnails
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  // Photo Manager Button
                                  InkWell(
                                    onTap: () {
                                      AppModals.showAppModal(
                                        context: context,
                                        title: 'Galeria do Treino',
                                        child: _PhotoManagerDialog(history: h),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Thumbnails List
                                  if (h.imagePaths.isNotEmpty)
                                    Expanded(
                                      child: SizedBox(
                                        height: 40,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: h.imagePaths.length,
                                          separatorBuilder: (c, i) =>
                                              const SizedBox(width: 8),
                                          itemBuilder: (c, i) {
                                            return InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        FullScreenImageViewer(
                                                          imagePaths:
                                                              h.imagePaths,
                                                          initialIndex: i,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child:
                                                    ImagePathResolver.isRemote(
                                                      h.imagePaths[i],
                                                    )
                                                    ? Image.network(
                                                        h.imagePaths[i],
                                                        width: 40,
                                                        height: 40,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.file(
                                                        ImagePathResolver.resolveToFile(
                                                          h.imagePaths[i],
                                                        ),
                                                        width: 40,
                                                        height: 40,
                                                        fit: BoxFit.cover,
                                                      ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
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

  String _getRpeEmoji(int? rpe) {
    if (rpe == null) return '❓';
    if (rpe == 1) return '😁';
    if (rpe == 2) return '🙂';
    if (rpe == 3) return '😐';
    if (rpe == 4) return '😫';
    if (rpe == 5) return '🥵';
    return '❓';
  }

  // ── Layout web da aba Histórico ───────────────────────────────────────────
  Widget _buildWebHistory(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Barra de ações
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Row(
            children: [
              Text(
                '${history.length} sessão${history.length != 1 ? 'ões' : ''} registrada${history.length != 1 ? 's' : ''}',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    final measurements = ref.read(bodyTrackerProvider);
                    final user = await ref.read(userProfileProvider.future);
                    final report = WorkoutReportService().generateGeneralReport(
                      history,
                      measurements,
                      user,
                    );
                    await Clipboard.setData(ClipboardData(text: report));
                    if (context.mounted) {
                      SnackbarUtils.showSuccess(
                        context,
                        'Dossiê copiado para IA!',
                      );
                    }
                  } catch (e) {
                    debugPrint('Report error: $e');
                  }
                },
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: Text(
                  'Exportar Dossiê IA',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
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
        // Cabeçalho da tabela
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Row(
              children: [
                _HCol('Data/Hora', flex: 2),
                _HCol('Treino', flex: 3),
                _HCol('Duração', flex: 1),
                _HCol('Conclusão', flex: 2),
                _HCol('RPE', flex: 2),
                _HCol('', flex: 1),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Linhas
        if (history.isEmpty)
          const Expanded(
            child: AppEmptyState(
              icon: Icons.history_rounded,
              title: 'Nenhum treino realizado',
              subtitle: 'Seu histórico aparecerá aqui.',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              itemCount: history.length,
              separatorBuilder: (_, i) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                final h = history[index];
                final isFirst = index == 0;
                final d = h.completedDate;
                final dateStr =
                    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                final pct = h.completionPercentage;
                final pctColor = pct >= 80
                    ? AppColors.primary
                    : pct >= 50
                    ? Colors.orangeAccent
                    : Colors.redAccent;

                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutHistoryDetailsPage(history: h),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  hoverColor: Colors.white.withOpacity(0.03),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isFirst
                          ? AppColors.primary.withOpacity(0.05)
                          : const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFirst
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.white.withOpacity(0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            dateStr,
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Text(
                                h.workoutName,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: isFirst
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isFirst) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'RECENTE',
                                    style: GoogleFonts.outfit(
                                      fontSize: 8,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${h.durationMinutes}min',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: (pct / 100).clamp(0.0, 1.0),
                                    backgroundColor: Colors.white.withOpacity(
                                      0.08,
                                    ),
                                    valueColor: AlwaysStoppedAnimation(
                                      pctColor,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: GoogleFonts.outfit(
                                  color: pctColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Text(
                                _getRpeEmoji(h.rpe),
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                h.rpe != null ? '${h.rpe}/5' : '—',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white24,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _HCol extends StatelessWidget {
  final String label;
  final int flex;
  const _HCol(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white38,
        letterSpacing: 0.4,
      ),
    ),
  );
}

class _PhotoManagerDialog extends StatefulWidget {
  final WorkoutHistory history;

  const _PhotoManagerDialog({required this.history});

  @override
  State<_PhotoManagerDialog> createState() => _PhotoManagerDialogState();
}

class _PhotoManagerDialogState extends State<_PhotoManagerDialog> {
  final ImageStorageService _imageService = ImageStorageService();

  late List<String> _currentImages;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentImages = List.from(widget.history.imagePaths);
  }

  Future<void> _deleteImage(int index) async {
    try {
      setState(() => _isLoading = true);

      final pathToDelete = _currentImages[index];

      // 1. Delete file
      await _imageService.deleteImage(pathToDelete);

      // 2. Update local state
      setState(() {
        _currentImages.removeAt(index);
      });

      // 3. Update Hive
      await _updateHive();

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Erro ao remover foto: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateHive() async {
    final box = Hive.box<WorkoutHistoryHiveModel>('history_log');

    final key = box.keys.firstWhere(
      (k) => box.get(k)?.id == widget.history.id,
      orElse: () => null,
    );

    if (key != null) {
      final oldModel = box.get(key)!;
      final oldEntity = oldModel.toEntity();

      final updatedModel = WorkoutHistoryHiveModel.fromEntity(
        WorkoutHistory(
          id: oldEntity.id,
          workoutId: oldEntity.workoutId,
          workoutName: oldEntity.workoutName,
          completedDate: oldEntity.completedDate,
          durationMinutes: oldEntity.durationMinutes,
          exercises: oldEntity.exercises,
          notes: oldEntity.notes,
          startTime: oldEntity.startTime,
          endTime: oldEntity.endTime,
          completionPercentage: oldEntity.completionPercentage,
          rpe: oldEntity.rpe,
          imagePaths: _currentImages,
        ),
      );

      await box.put(key, updatedModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const LinearProgressIndicator(color: AppColors.primary),

          const SizedBox(height: 16),

          Expanded(
            child: _currentImages.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma foto adicionada ainda.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _currentImages.length,
                    itemBuilder: (context, index) {
                      final path = _currentImages[index];
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImageViewer(
                                    imagePaths: _currentImages,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ImagePathResolver.isRemote(path)
                                  ? Image.network(path, fit: BoxFit.cover)
                                  : Image.file(
                                      ImagePathResolver.resolveToFile(path),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _deleteImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // Large Green "Add Photo" Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (kIsWeb) {
                  final url = await WebImageService.pickAndUpload(
                    WebImageService.folderHistory,
                  );
                  if (url != null) setState(() => _currentImages.add(url));
                } else {
                  await AppModals.showAppModal(
                    context: context,
                    title: 'Selecionar Imagem',
                    child: const ImageSourceSheet(showLibrary: false),
                  ).then((files) async {
                    if (files != null && files is List<File>) {
                      setState(() => _isLoading = true);
                      for (final file in files) {
                        try {
                          final xFile = XFile(file.path);
                          final permanentPath = await _imageService.saveImage(
                            xFile,
                          );
                          setState(() => _currentImages.add(permanentPath));
                        } catch (e) {
                          debugPrint('Error saving image: $e');
                        }
                      }
                      await _updateHive();
                      setState(() => _isLoading = false);
                    }
                  });
                }
              },
              icon: const Icon(Icons.add_a_photo),
              label: const Text('ADICIONAR FOTO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _WebTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withOpacity(0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.primary : Colors.white38,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Gráfico: Duração das sessões (barras) ─────────────────────────────────────

class _SessionDurationChart extends StatelessWidget {
  final List<WorkoutHistory> history;
  const _SessionDurationChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final data = history.take(12).toList().reversed.toList();
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'Sem dados',
          style: TextStyle(color: Colors.white24, fontSize: 13),
        ),
      );
    }

    final maxDur = data
        .map((h) => h.durationMinutes)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.asMap().entries.map((entry) {
          final h = entry.value;
          final isLast = entry.key == data.length - 1;
          final frac = maxDur == 0 ? 0.0 : h.durationMinutes / maxDur;
          final d = h.completedDate;
          final label =
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${h.durationMinutes}',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      color: isLast ? AppColors.primary : Colors.white38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: (130 * frac).clamp(6.0, 120.0),
                    decoration: BoxDecoration(
                      color: isLast
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      color: isLast ? Colors.white54 : Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Gráfico: Top exercícios por frequência (barras horizontais) ───────────────

class _TopExercisesChart extends StatelessWidget {
  final List<WorkoutHistory> history;
  const _TopExercisesChart({required this.history});

  @override
  Widget build(BuildContext context) {
    // Conta frequência de cada exercício
    final freq = <String, int>{};
    for (final h in history) {
      for (final ex in h.exercises) {
        freq[ex.name] = (freq[ex.name] ?? 0) + 1;
      }
    }

    if (freq.isEmpty) {
      return const Center(
        child: Text(
          'Sem dados',
          style: TextStyle(color: Colors.white24, fontSize: 13),
        ),
      );
    }

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(8).toList();
    final maxVal = top.first.value;

    return Column(
      children: top.asMap().entries.map((entry) {
        final i = entry.key;
        final name = entry.value.key;
        final count = entry.value.value;
        final frac = maxVal == 0 ? 0.0 : count / maxVal;
        final colors = [
          AppColors.primary,
          const Color(0xFF00CFFF),
          const Color(0xFFAA80FF),
          Colors.orangeAccent,
          Colors.tealAccent,
          Colors.pinkAccent,
          Colors.blueAccent,
          Colors.deepOrangeAccent,
        ];
        final c = colors[i % colors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 160,
                child: Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: frac.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 32,
                child: Text(
                  '$count×',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: c,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
