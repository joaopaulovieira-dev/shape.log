import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import 'package:shape_log/features/body_tracker/presentation/providers/body_tracker_provider.dart';
import 'package:shape_log/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:shape_log/features/reports/presentation/widgets/analytics_widgets.dart';
import 'package:shape_log/features/workout/domain/services/workout_report_service.dart';
import 'package:shape_log/features/workout/presentation/providers/workout_provider.dart';
import 'package:shape_log/features/workout/domain/entities/workout_history.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intelligence Hub'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'Analytics'),
            Tab(icon: Icon(Icons.history_edu), text: 'Logs & IA'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_AnalyticsTab(), _HistoryTab()],
      ),
    );
  }
}

class _AnalyticsTab extends ConsumerStatefulWidget {
  const _AnalyticsTab();

  @override
  ConsumerState<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends ConsumerState<_AnalyticsTab> {
  String _filterMode = '30_days'; // '30_days', 'all'

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyListProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return _buildEmptyState(context);
        }

        // Apply Filter
        final filteredHistory = history.where((h) {
          if (_filterMode == 'all') return true;
          final diff = DateTime.now().difference(h.completedDate).inDays;
          return diff <= 30;
        }).toList();

        if (filteredHistory.isEmpty && _filterMode != 'all') {
          return Center(
            child: Text(
              'Sem dados nos últimos 30 dias.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Prepare Data
        final volumeData = _calculateVolumeData(filteredHistory);
        final frequencyData = _calculateFrequencyData(filteredHistory);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Toggle
              Center(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: '30_days',
                      label: Text('30 Dias'),
                      icon: Icon(Icons.calendar_view_month),
                    ),
                    ButtonSegment<String>(
                      value: 'all',
                      label: Text('Todo o Período'),
                      icon: Icon(Icons.all_inclusive),
                    ),
                  ],
                  selected: {_filterMode},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _filterMode = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>((
                      Set<MaterialState> states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return AppColors.primary;
                      }
                      return AppColors.surface;
                    }),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>((
                      Set<MaterialState> states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.black;
                      }
                      return Colors.white;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Volume de Treino (Carga Total)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: VolumeChart(volumeData: volumeData),
              ), // Increased height
              const SizedBox(height: 32),

              const Text(
                'Frequência Semanal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250, // Increased height
                child: FrequencyChart(frequencyData: frequencyData),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erro: $e')),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'Sem dados suficientes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete seu primeiro treino para desbloquear os gráficos!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  List<MapEntry<DateTime, double>> _calculateVolumeData(
    List<WorkoutHistory> history,
  ) {
    final Map<DateTime, double> volumeMap = {};

    for (final h in history) {
      double totalLoad = 0;
      for (final ex in h.exercises) {
        if (ex.setsHistory != null && ex.setsHistory!.isNotEmpty) {
          for (final set in ex.setsHistory!) {
            totalLoad += (set.weight * set.reps);
          }
        } else {
          totalLoad += (ex.weight * ex.reps * ex.sets);
        }
      }

      final dateCtx = DateTime(
        h.completedDate.year,
        h.completedDate.month,
        h.completedDate.day,
      );
      volumeMap[dateCtx] = (volumeMap[dateCtx] ?? 0) + totalLoad;
    }

    return volumeMap.entries.toList();
  }

  List<int> _calculateFrequencyData(List<WorkoutHistory> history) {
    final counts = List.filled(7, 0);
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7)); // Sunday
    final endOfWeek = startOfWeek.add(const Duration(days: 6)); // Saturday

    for (final h in history) {
      // Only count if within current week? Or distribution of all time?
      // The user prompt implies "Frequência Semanal", which typically means "This Week".
      // However, for "All Time", it might be "Average per day".
      // Given the implementation was checking specific week range, I'll keep it as "Activity by Day of Week"
      // but strictly speaking the previous logic filtered ONLY for the current week.
      // Only for "30 days" or "All", maybe we want "Workouts by Day of Week (Aggregate)"?
      // Let's stick to the previous logic (Current Week) unless user wants history.
      // Actually, "Frequência Semanal" usually means "How many times I worked out this week".
      // Let's keep the logic of "Current Week" for now as it was, but ensure it works.

      // WAIT: If I filter 30 days, I probably want to see "How many workouts I did on Monday, Tuesday..." over the last 30 days OR just "This week".
      // The previous code filtered: if date > startOfWeek-1 && date < endOfWeek+1.
      // This restricts CHART to current week only.
      // If I have a 30 day filter, I probably want to see the Volume Chart for 30 days.
      // The Frequency Chart logic seems specific to "Current Week".
      // I will leave it as "Current Week Activity" for now to avoid breaking logic,
      // since the Volume Chart is the main "Time Series".

      if (h.completedDate.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          ) &&
          h.completedDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
        final weekdayIndex = h.completedDate.weekday % 7;
        counts[weekdayIndex]++;
      }
    }
    return counts;
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56, // Standard height
            child: FilledButton.icon(
              onPressed: () async {
                try {
                  final history = await ref.read(historyListProvider.future);
                  final measurements = ref.read(bodyTrackerProvider);
                  final user = await ref.read(userProfileProvider.future);

                  final report = WorkoutReportService().generateGeneralReport(
                    history,
                    measurements,
                    user,
                  );

                  await Clipboard.setData(ClipboardData(text: report));

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surface,
                        content: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Dossiê Geral copiado para IA!',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                backgroundColor: AppColors.primary, // Neon Green
                foregroundColor: Colors.black, // High Contrast
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
            ),
          ),
        ),
        Expanded(
          child: historyAsync.when(
            data: (allHistory) {
              if (allHistory.isEmpty)
                return const Center(child: Text("Sem histórico."));

              final history = List.of(allHistory)
                ..sort((a, b) => b.completedDate.compareTo(a.completedDate));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final h = history[index];
                  return Card(
                    elevation: 0, // Flat look on dark theme
                    color: AppColors.surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        h.workoutName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${DateFormat('dd/MM - HH:mm').format(h.completedDate)} • ${h.durationMinutes} min',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getRpeEmoji(h.rpe),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      onTap: () async {
                        // Individual Copy logic
                        final user = await ref.read(userProfileProvider.future);
                        final report = WorkoutReportService()
                            .generateClipboardReport(h, user);
                        await Clipboard.setData(ClipboardData(text: report));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.surface,
                              content: Text(
                                'Treino individual copiado!',
                                style: TextStyle(color: Colors.white),
                              ),
                              showCloseIcon: true,
                              closeIconColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Erro: $e')),
          ),
        ),
      ],
    );
  }

  String _getRpeEmoji(int? rpe) {
    if (rpe == null) return '❓';
    if (rpe <= 2) return '🟢';
    if (rpe <= 3) return '🟡';
    if (rpe <= 4) return '🟠';
    return '🔴';
  }
}
