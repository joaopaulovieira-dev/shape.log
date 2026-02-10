import 'package:flutter/material.dart';
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
      body: ValueListenableBuilder<Box<WorkoutHistoryHiveModel>>(
        valueListenable: Hive.box<WorkoutHistoryHiveModel>(
          'history_log',
        ).listenable(),
        builder: (context, box, _) {
          // Convert Hive models to Domain entities
          final historyList = box.values.map((e) => e.toEntity()).toList();

          // Sort by date descending (newest first)
          historyList.sort(
            (a, b) => b.completedDate.compareTo(a.completedDate),
          );

          return TabBarView(
            controller: _tabController,
            children: [
              _AnalyticsTab(history: historyList),
              _HistoryTab(history: historyList),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsTab extends StatefulWidget {
  final List<WorkoutHistory> history;

  const _AnalyticsTab({required this.history});

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
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return AppColors.surface;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.black;
                  }
                  return Colors.white;
                }),
              ),
            ),
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

  const _HistoryTab({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No longer watching provider here, using passed history

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
                  // We can use the passed history directly
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
                backgroundColor: AppColors.primary, // Neon Green
                foregroundColor: Colors.black, // High Contrast
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        Expanded(
          child: history.isEmpty
              ? const Center(child: Text("Sem histórico."))
              : ListView.builder(
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
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          h.workoutName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${DateFormat('dd/MM - HH:mm').format(h.completedDate)} • ${h.durationMinutes} min',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.attach_file,
                                          color: AppColors.primary,
                                        ),
                                        tooltip: 'Gerenciar Fotos',
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(20),
                                                  ),
                                            ),
                                            builder: (ctx) =>
                                                _PhotoManagerDialog(history: h),
                                          );
                                        },
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          _getRpeEmoji(h.rpe),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      // Delete button REMOVED
                                    ],
                                  ),
                                ],
                              ),

                              // Thumbnails
                              if (h.imagePaths.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 60,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: h.imagePaths.length,
                                    separatorBuilder: (c, i) =>
                                        const SizedBox(width: 6),
                                    itemBuilder: (c, i) {
                                      return InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  FullScreenImageViewer(
                                                    imagePaths: h.imagePaths,
                                                    initialIndex: i,
                                                  ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            File(h.imagePaths[i]),
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
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
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.7, // Slightly taller
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Galeria do Treino',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                // Open modal directly, handled by ImageSourceSheet logic (but wait, ImageSourceSheet is a widget).
                // We need to show modal bottom sheet with ImageSourceSheet.
                await showModalBottomSheet(
                  context: context,
                  builder: (context) =>
                      const ImageSourceSheet(showLibrary: false),
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
