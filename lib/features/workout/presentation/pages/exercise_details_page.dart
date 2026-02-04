import 'dart:io';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/workout_provider.dart';
import 'package:shape_log/core/constants/app_colors.dart';

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
            body: Center(child: Text('Exercício não encontrado')),
          );
        }

        final exercise = workout.exercises[exerciseIndex];
        final mediaList = exercise.imagePaths;

        return Scaffold(
          appBar: AppBar(
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: exercise.name),
                  if (exercise.equipmentNumber != null &&
                      exercise.equipmentNumber!.isNotEmpty)
                    TextSpan(
                      text: ' #${exercise.equipmentNumber}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  context.push(
                    '/workouts/$workoutId/exercises/$exerciseIndex/edit',
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (mediaList.isNotEmpty)
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 350.0,
                      enableInfiniteScroll: mediaList.length > 1,
                      enlargeCenterPage: true,
                    ),
                    items: mediaList.map((path) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(path),
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, stack) => const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  )
                else
                  Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Séries', '${exercise.sets}'),
                      const Divider(),
                      _buildInfoRow('Repetições', '${exercise.reps}'),
                      const Divider(),
                      _buildInfoRow('Carga', '${exercise.weight} kg'),
                      if (exercise.technique != null &&
                          exercise.technique!.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Técnica / Observações:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exercise.technique!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                      const Divider(),
                      if (exercise.youtubeUrl != null &&
                          exercise.youtubeUrl!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(exercise.youtubeUrl!);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Não foi possível abrir o link.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.red,
                          ),
                          label: const Text('Ver no YouTube'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Erro: $err'))),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
