import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import 'package:shape_log/features/workout/domain/entities/workout.dart';
import 'package:shape_log/features/workout/data/models/workout_history_hive_model.dart';

// 1. Weekly Consistency Strip
class WeeklyConsistencyStrip extends StatelessWidget {
  final List<WorkoutHistoryHiveModel> history;

  const WeeklyConsistencyStrip({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Start of week (Sunday)
    final diff = now.weekday % 7;
    final startOfWeek = today.subtract(Duration(days: diff));

    // Generate 7 days (Sunday to Saturday)
    final days = List.generate(7, (index) {
      return startOfWeek.add(Duration(days: index));
    });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark surface
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CONSISTÊNCIA SEMANAL",
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((date) {
              final isToday = _isSameDay(date, now);
              final hasWorkout = history.any(
                (h) => _isSameDay(h.completedDate, date),
              );

              return _DayBubble(
                date: date,
                isToday: isToday,
                hasWorkout: hasWorkout,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayBubble extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool hasWorkout;

  const _DayBubble({
    required this.date,
    required this.isToday,
    required this.hasWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat(
      'E',
      'pt_BR',
    ).format(date)[0].toUpperCase(); // S, T, Q...

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: hasWorkout ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isToday
                  ? AppColors.primary
                  : (hasWorkout ? AppColors.primary : Colors.grey[800]!),
              width: isToday ? 2 : 1,
            ),
            boxShadow: hasWorkout
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: hasWorkout
                ? const Icon(Icons.check, size: 16, color: Colors.black)
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 10,
            color: isToday ? AppColors.primary : Colors.grey[500],
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// 2. Smart Action Card
class SmartActionCard extends StatelessWidget {
  final Workout? suggestedWorkout;
  final VoidCallback onStart;

  const SmartActionCard({
    super.key,
    required this.suggestedWorkout,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Linear Gradient for Hero effect
        gradient: LinearGradient(
          colors: [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          // Subtle background decoration (optional)
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.bolt,
              size: 150,
              color: Colors.white.withOpacity(0.03),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "PRÓXIMA MISSÃO",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  suggestedWorkout?.name ?? "Iniciar Jornada",
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  suggestedWorkout != null
                      ? "${suggestedWorkout!.exercises.length} Exercícios • Foco em ${suggestedWorkout!.name.contains('A') ? 'Push' : (suggestedWorkout!.name.contains('B') ? 'Pull' : 'Força')}" // Simple logic, can be improved
                      : "Crie seu primeiro treino para começar",
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "INICIAR AGORA",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.rocket_launch, size: 20),
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
}

// 3. Last Session Recap
class LastSessionRecap extends StatelessWidget {
  final WorkoutHistoryHiveModel? lastSession;

  const LastSessionRecap({super.key, this.lastSession});

  @override
  Widget build(BuildContext context) {
    if (lastSession == null) return const SizedBox.shrink();

    final hasImage =
        lastSession!.imagePaths != null && lastSession!.imagePaths!.isNotEmpty;
    final dateFormat = DateFormat('dd/MM • HH:mm');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          // Background Image with Overlay if exists
          if (hasImage)
            Positioned.fill(
              child: Image.file(
                File(lastSession!.imagePaths!.first),
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.7), // Darken
                colorBlendMode: BlendMode.darken,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ÚLTIMO TREINO",
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: hasImage ? Colors.white70 : Colors.grey[500],
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (lastSession == null) Container(), // Placeholder
                    Text(
                      dateFormat.format(lastSession!.completedDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: hasImage ? Colors.white70 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lastSession!.workoutName,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${lastSession!.durationMinutes} min • ${lastSession!.exercises.length} Ex • Carga: ???kg", // TODO: Calculate volume if possible
                            style: TextStyle(
                              color: hasImage
                                  ? Colors.white70
                                  : Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasImage)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 4. Weekly Performance Card (Replaces Quick Menu)
class WeeklyPerformanceCard extends StatelessWidget {
  final List<WorkoutHistoryHiveModel> history;

  const WeeklyPerformanceCard({super.key, required this.history});

  Map<String, dynamic> _calculateWeeklyStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Start of week (Sunday)
    final diff = now.weekday % 7;
    final startOfWeek = today.subtract(Duration(days: diff));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    // Filter history for this week
    final weeklyWorkouts = history.where((h) {
      return h.completedDate.isAfter(startOfWeek) &&
          h.completedDate.isBefore(endOfWeek);
    }).toList();

    double totalVolume = 0;
    int totalDurationMinutes = 0;

    for (var workout in weeklyWorkouts) {
      totalDurationMinutes += workout.durationMinutes;
      for (var exercise in workout.exercises) {
        for (var set in exercise.setsHistory) {
          totalVolume += (set.weight * set.reps);
        }
      }
    }

    return {
      'volume': totalVolume,
      'duration': totalDurationMinutes,
      'workouts': weeklyWorkouts.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateWeeklyStats();
    final volume = stats['volume'] as double;
    final duration = stats['duration'] as int;

    // Format Volume (e.g. 12.500 kg)
    final numberFormat = NumberFormat('#,##0', 'pt_BR');
    final volumeText = '${numberFormat.format(volume)} kg';

    // Format Duration
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    String durationText = '';
    if (hours > 0) durationText += '${hours}h ';
    durationText += '${minutes}m';

    // Progress Goal (Logic: Standard 10 tons or based on average? Let's fix 10 tons/week for now as requested)
    const double weeklyGoal = 10000; // 10 Tons
    final double progress = (volume / weeklyGoal).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "VOLUME DA SEMANA",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    volumeText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[800],
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${(progress * 100).toInt()}% da meta",
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 12),

          // Sub-stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Levantados",
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$durationText de foco",
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
