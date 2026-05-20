import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/image_path_resolver.dart';

import '../providers/workout_provider.dart';
import '../../domain/entities/exercise.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/duration_format.dart';

class ExerciseDetailsPage extends ConsumerWidget {
  final String workoutId;
  final int exerciseIndex;

  const ExerciseDetailsPage({
    super.key,
    required this.workoutId,
    required this.exerciseIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routineListProvider);

    return routinesAsync.when(
      data: (routines) {
        final workout = routines.firstWhere(
          (w) => w.id == workoutId,
          orElse: () => throw Exception('Treino não encontrado'),
        );

        if (exerciseIndex >= workout.exercises.length) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: Text('Exercício não encontrado')),
          );
        }

        final exercise = workout.exercises[exerciseIndex];
        final mediaList = exercise.imagePaths;

        if (kIsWeb) {
          return _buildWebLayout(context, exercise, mediaList, workout.id);
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: CustomScrollView(
            slivers: [
              // 1. Premium Header
              SliverAppBar(
                expandedHeight: 120.0,
                floating: true,
                pinned: true,
                backgroundColor: AppColors.background,
                iconTheme: const IconThemeData(
                  color: Colors.white,
                ), // Standardized
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16),
                  title: Text(
                    'Exercício',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                    ), // Standardized
                    onPressed: () {
                      context.push(
                        '/workouts/$workoutId/exercises/$exerciseIndex/edit',
                      );
                    },
                  ),
                ],
              ),

              // 2. Media / Title Section
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (mediaList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: CarouselSlider(
                          options: CarouselOptions(
                            height: 350.0,
                            enableInfiniteScroll: mediaList.length > 1,
                            enlargeCenterPage: true,
                            viewportFraction: 0.9,
                          ),
                          items: mediaList.map((path) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: AppCachedImage(path: path, fit: BoxFit.contain),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Exercise Name Card
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        exercise.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (exercise.equipmentNumber != null &&
                                        exercise.equipmentNumber!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '#${exercise.equipmentNumber}',
                                          style: GoogleFonts.outfit(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 2,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildStatsRow(exercise),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Technique / Observations
                          if (exercise.technique != null &&
                              exercise.technique!.isNotEmpty)
                            _buildInfoSection(
                              'Orientação Técnica',
                              exercise.technique!,
                              Icons.lightbulb_outline,
                            ),

                          const SizedBox(height: 16),

                          // YouTube Tutorial Button
                          if (exercise.youtubeUrl != null &&
                              exercise.youtubeUrl!.isNotEmpty)
                            _buildYouTubeButton(context, exercise.youtubeUrl!),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Erro: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(Exercise exercise) {
    if (exercise.type == ExerciseTypeEntity.cardio) {
      return Row(
        children: [
          _buildStatItem(
            'Duração',
            formatCardioDuration(exercise.cardioDurationMinutes),
            Icons.timer_outlined,
          ),
          _buildDivider(),
          _buildStatItem(
            'Intensidade',
            exercise.cardioIntensity ?? 'Normal',
            Icons.speed_outlined,
          ),
          _buildDivider(),
          _buildStatItem(
            'Descanso',
            '${exercise.restTimeSeconds}s',
            Icons.update,
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildStatItem('Séries', '${exercise.sets}', Icons.reorder),
        _buildDivider(),
        _buildStatItem('Reps', '${exercise.reps}', Icons.repeat),
        _buildDivider(),
        _buildStatItem('Carga', '${exercise.weight}kg', Icons.fitness_center),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeButton(BuildContext context, String videoUrl) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final url = Uri.parse(videoUrl);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } else {
              if (context.mounted) {
                SnackbarUtils.showError(
                  context,
                  'Não foi possível abrir o tutorial.',
                );
              }
            }
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assistir Tutorial',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Aprenda a execução correta',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Web layout ─────────────────────────────────────────────────────────────
  Widget _buildWebLayout(
    BuildContext context,
    Exercise exercise,
    List<String> mediaList,
    String workoutId,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Top bar
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            color: const Color(0xFF0A0A0A),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white54, size: 20),
                  onPressed: () => context.pop(),
                  tooltip: 'Voltar',
                ),
                const SizedBox(width: 8),
                if (exercise.equipmentNumber != null &&
                    exercise.equipmentNumber!.isNotEmpty)
                  Text('#${exercise.equipmentNumber} ',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                Text(
                  exercise.name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push(
                    '/workouts/$workoutId/exercises/$exerciseIndex/edit'),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text('Editar', style: GoogleFonts.outfit()),
                  style: TextButton.styleFrom(foregroundColor: Colors.white54),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withOpacity(0.06)),
          // Conteúdo em duas colunas
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Esquerda — galeria de imagens
                SizedBox(
                  width: 400,
                  child: mediaList.isEmpty
                      ? Container(
                          color: const Color(0xFF111111),
                          child: const Center(
                            child: Icon(Icons.fitness_center,
                                color: AppColors.primary, size: 64),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: mediaList.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final path = mediaList[i];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: AppCachedImage(path: path, fit: BoxFit.cover),
                              ),
                            );
                          },
                        ),
                ),
                Container(width: 1, color: Colors.white.withOpacity(0.06)),
                // Direita — informações
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats
                        _webSectionLabel('ESTATÍSTICAS'),
                        const SizedBox(height: 12),
                        if (exercise.type == ExerciseTypeEntity.cardio) ...[
                          _webStat('Duração',
                              formatCardioDuration(exercise.cardioDurationMinutes)),
                          const SizedBox(height: 8),
                          if (exercise.cardioIntensity?.isNotEmpty == true)
                            _webStat('Intensidade', exercise.cardioIntensity!),
                        ] else ...[
                          _webStat('Séries', '${exercise.sets}'),
                          const SizedBox(height: 8),
                          _webStat('Repetições', '${exercise.reps}'),
                          const SizedBox(height: 8),
                          _webStat('Carga', '${exercise.weight} kg'),
                        ],
                        const SizedBox(height: 8),
                        _webStat('Descanso', '${exercise.restTimeSeconds}s'),

                        if (exercise.technique?.isNotEmpty == true) ...[
                          const SizedBox(height: 24),
                          _webSectionLabel('TÉCNICA'),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.07)),
                            ),
                            child: Text(exercise.technique!,
                                style: GoogleFonts.outfit(
                                    fontSize: 14, color: Colors.white70,
                                    height: 1.6)),
                          ),
                        ],

                        if (exercise.youtubeUrl?.isNotEmpty == true) ...[
                          const SizedBox(height: 24),
                          _webSectionLabel('TUTORIAL'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(exercise.youtubeUrl!);
                              if (await canLaunchUrl(uri)) launchUrl(uri);
                            },
                            icon: const Icon(Icons.play_circle_outline, size: 18),
                            label: Text('Assistir no YouTube',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600)),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _webSectionLabel(String text) => Text(
        text,
        style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white38,
            letterSpacing: 1.2),
      );

  Widget _webStat(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54)),
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      );
}
