import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../workout/domain/entities/workout_history.dart';
import '../../../workout/domain/entities/exercise.dart';

// --- VISUALIZATION 1: VOLUME LOAD EVOLUTION ---
class VolumeLoadChart extends StatelessWidget {
  final List<WorkoutHistory> history;
  final bool isAllTime;

  const VolumeLoadChart({
    super.key,
    required this.history,
    required this.isAllTime,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Prepare Data
    // Group by Date -> Sum of (Weight * Reps) for Strength exercises only
    final Map<DateTime, double> volumeMap = {};

    for (final h in history) {
      final date = DateTime(
        h.completedDate.year,
        h.completedDate.month,
        h.completedDate.day,
      );

      double dailyLoad = 0;
      for (final ex in h.exercises) {
        if (ex.type != ExerciseTypeEntity.weight) continue;

        if (ex.setsHistory != null && ex.setsHistory!.isNotEmpty) {
          for (final s in ex.setsHistory!) {
            dailyLoad += (s.weight * s.reps);
          }
        } else {
          // Fallback if no setsHistory (legacy)
          dailyLoad += (ex.weight * ex.reps * ex.sets);
        }
      }

      if (dailyLoad > 0) {
        volumeMap[date] = (volumeMap[date] ?? 0) + dailyLoad;
      }
    }

    final sortedEntries = volumeMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Filter for chart bounds (if needed, though passed history should already be filtered)
    if (sortedEntries.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Sem dados de carga.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Create Spots
    final spots = sortedEntries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'VOLUME DE CARGA',
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.black,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.black,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final val = spot.y.toStringAsFixed(0);
                        // Try to find date
                        final index = spot.x.toInt();
                        String dateStr = '';
                        if (index >= 0 && index < sortedEntries.length) {
                          dateStr = DateFormat(
                            'dd/MM',
                          ).format(sortedEntries[index].key);
                        }

                        return LineTooltipItem(
                          '$dateStr\n$val kg',
                          GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- VISUALIZATION 2: CONSISTENCY HEATMAP ---
// Using custom grid approach since fl_chart doesn't have a heatmap specific widget,
// but we can build it easily with GridView or Row/Column.
class ConsistencyHeatmap extends StatelessWidget {
  final List<WorkoutHistory> history;

  const ConsistencyHeatmap({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    // 1. Setup Grid 7 rows (Sun-Sat) x 12 Cols (Last 12 weeks)
    final now = DateTime.now();
    final endOfWeek = now.add(
      Duration(days: (DateTime.saturday - now.weekday + 7) % 7),
    );
    final startDate = endOfWeek.subtract(const Duration(days: 7 * 12 - 1));

    final Map<DateTime, int> intensityMap = {};

    for (final h in history) {
      final date = DateTime(
        h.completedDate.year,
        h.completedDate.month,
        h.completedDate.day,
      );
      if (date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endOfWeek.add(const Duration(days: 1)))) {
        intensityMap[date] = (intensityMap[date] ?? 0) + h.durationMinutes;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.grid_on_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'CONSISTÊNCIA',
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              children: List.generate(12, (colIndex) {
                return Expanded(
                  child: Column(
                    children: List.generate(7, (rowIndex) {
                      final dayOffset = (colIndex * 7) + rowIndex;
                      final cellDate = startDate.add(Duration(days: dayOffset));
                      final minutes =
                          intensityMap[DateTime(
                            cellDate.year,
                            cellDate.month,
                            cellDate.day,
                          )] ??
                          0;

                      Color cellColor;
                      if (minutes == 0) {
                        cellColor = Colors.grey.withValues(alpha: 0.1);
                      } else if (minutes < 30) {
                        cellColor = AppColors.primary.withValues(alpha: 0.5);
                      } else {
                        cellColor = AppColors.primary;
                      }

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendItem(
                Colors.grey.withValues(alpha: 0.1),
                'Sem treino',
              ),
              const SizedBox(width: 8),
              _buildLegendItem(
                AppColors.primary.withValues(alpha: 0.5),
                '< 30min',
              ),
              const SizedBox(width: 8),
              _buildLegendItem(AppColors.primary, '> 30min'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// --- VISUALIZATION 3: HYBRID BALANCE ---
class BalancePieChart extends StatelessWidget {
  final List<WorkoutHistory> history;

  const BalancePieChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    double totalCardioMinutes = 0;
    double totalStrengthMinutes = 0;

    for (final h in history) {
      // 1. Cardio from explicit cardio duration in summary (usually from session timer)
      // OR sum of cardio exercises?
      // Let's look at h.exercises.

      double workoutCardio = 0;
      double workoutStrength = 0;

      // Heuristic: If we have explicit exercise log
      for (final ex in h.exercises) {
        if (ex.type == ExerciseTypeEntity.cardio) {
          // Use logged cardio duration if available
          workoutCardio += ex.cardioDurationMinutes ?? 0;
        } else {
          // Strength Estimation: Sets * (Execute 45s + Rest)
          final sets = ex.setsHistory?.length ?? ex.sets;
          final durationPerSet = 45 + ex.restTimeSeconds; // seconds
          workoutStrength += (sets * durationPerSet) / 60; // minutes
        }
      }

      // Determine if valid based on exercises
      if (workoutCardio > 0 || workoutStrength > 0) {
        totalCardioMinutes += workoutCardio;
        totalStrengthMinutes += workoutStrength;
      } else {
        // Fallback: use total duration based on workout name or just split evenly?
        // Risky. Let's assume if no exercises logged, we skip or trust h.durationMinutes
        // But we don't know the type. Let's skip empty details.
      }
    }

    // Safety check
    if (totalCardioMinutes == 0 && totalStrengthMinutes == 0) {
      return const SizedBox(); // Or empty state
    }

    final totalMinutes = totalCardioMinutes + totalStrengthMinutes;
    final totalHours = (totalMinutes / 60).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pie_chart_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'DISTRIBUIÇÃO DE TREINO',
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.primary,
                        value: totalStrengthMinutes,
                        title:
                            '${(totalStrengthMinutes / totalMinutes * 100).toStringAsFixed(0)}%',
                        radius: 50,
                        titleStyle: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      PieChartSectionData(
                        color: Colors.cyanAccent,
                        value: totalCardioMinutes,
                        title:
                            '${(totalCardioMinutes / totalMinutes * 100).toStringAsFixed(0)}%',
                        radius: 50,
                        titleStyle: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    '${totalHours}h\nTotal',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(AppColors.primary, 'Força'),
              const SizedBox(width: 24),
              _buildLegend(Colors.cyanAccent, 'Cardio'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
