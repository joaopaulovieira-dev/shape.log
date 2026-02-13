import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import 'package:shape_log/features/body_tracker/presentation/providers/body_tracker_provider.dart';
import 'package:shape_log/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:shape_log/features/reports/presentation/widgets/advanced_analytics_widgets.dart';
import 'package:shape_log/features/workout/domain/services/workout_report_service.dart';
import 'package:shape_log/features/workout/domain/entities/workout_history.dart';
import 'package:shape_log/features/reports/presentation/pages/workout_history_details_page.dart';

// Hive imports
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../features/workout/data/models/workout_history_hive_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../image_library/presentation/image_source_sheet.dart';
import '../../../common/presentation/widgets/full_screen_image_viewer.dart';
import '../../../common/services/image_storage_service.dart';
import '../../../../core/presentation/widgets/app_modals.dart';

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
      body: ValueListenableBuilder<Box<WorkoutHistoryHiveModel>>(
        valueListenable: Hive.box<WorkoutHistoryHiveModel>(
          'history_log',
        ).listenable(),
        builder: (context, box, _) {
          final historyList = box.values.map((e) => e.toEntity()).toList();
          historyList.sort(
            (a, b) => b.completedDate.compareTo(a.completedDate),
          );

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
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
                    scale: Tween<double>(
                      begin: 0.98,
                      end: 1.0,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _currentMode == HubMode.analytics
                  ? _AnalyticsTab(
                      key: const ValueKey('analytics'),
                      history: historyList,
                    )
                  : _HistoryTab(
                      key: const ValueKey('logs'),
                      history: historyList,
                    ),
            ),
          );
        },
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
      return _buildEmptyState(context);
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
      final label = _filterMode == '30_days'
          ? '30 dias'
          : (_filterMode == '90_days' ? '90 dias' : '7 dias');
      return Center(
        child: Text(
          'Sem dados nos últimos $label.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Toggle
          // Filter - Mirrored from Body Tracker
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: PopupMenuButton<String>(
                  initialValue: _filterMode,
                  onSelected: (value) => setState(() => _filterMode = value),
                  offset: const Offset(0, 40),
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.filter_list,
                        color: Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _filterMode == 'all'
                            ? "Tudo"
                            : (_filterMode == '30_days'
                                  ? "30 Dias"
                                  : (_filterMode == '90_days'
                                        ? "90 Dias"
                                        : "7 Dias")),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                  itemBuilder: (context) => [
                    _buildPopupItem('all', 'Tudo'),
                    _buildPopupItem('90_days', 'Últimos 90 dias'),
                    _buildPopupItem('30_days', 'Últimos 30 dias'),
                    _buildPopupItem('7_days', 'Últimos 7 dias'),
                  ],
                ),
              ),
            ],
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

  PopupMenuItem<String> _buildPopupItem(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(
        label,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
      ),
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
}

class _HistoryTab extends ConsumerWidget {
  final List<WorkoutHistory> history;

  const _HistoryTab({super.key, required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[800]),
                      const SizedBox(height: 16),
                      Text(
                        "Sem histórico de treinos.",
                        style: GoogleFonts.outfit(
                          color: Colors.grey[600],
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
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
                                                child: Image.file(
                                                  File(h.imagePaths[i]),
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
      ],
    );
  }

  String _getRpeEmoji(int? rpe) {
    if (rpe == null) return '❓';
    if (rpe == 1) return '😁'; // Muito Leve
    if (rpe == 2) return '🙂'; // Leve
    if (rpe == 3) return '😐'; // Moderado
    if (rpe == 4) return '😫'; // Difícil
    if (rpe == 5) return '🥵'; // Exaustão
    return '❓';
  }
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
                              child: Image.file(File(path), fit: BoxFit.cover),
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
                await AppModals.showAppModal(
                  context: context,
                  title: 'Selecionar Imagem',
                  child: const ImageSourceSheet(showLibrary: false),
                ).then((files) async {
                  if (files != null && files is List<File>) {
                    setState(() => _isLoading = true);
                    for (final file in files) {
                      try {
                        // Create XFile from File
                        final xFile = XFile(file.path);
                        final permanentPath = await _imageService.saveImage(
                          xFile,
                        );
                        setState(() {
                          _currentImages.add(permanentPath);
                        });
                      } catch (e) {
                        debugPrint('Error saving image: $e');
                      }
                    }
                    await _updateHive();
                    setState(() => _isLoading = false);
                  }
                });
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
