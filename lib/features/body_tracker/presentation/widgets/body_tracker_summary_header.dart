import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/body_measurement.dart';
import '../../presentation/utils/body_tracker_formatter.dart';
import 'package:google_fonts/google_fonts.dart';

class BodyTrackerSummaryHeader extends StatelessWidget {
  final List<BodyMeasurement> measurements;

  const BodyTrackerSummaryHeader({super.key, required this.measurements});

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) return const SizedBox.shrink();

    // Sort by date ascending to get first and last
    final sorted = List<BodyMeasurement>.from(measurements)
      ..sort((a, b) => a.date.compareTo(b.date));
    final first = sorted.first;
    final last = sorted.last;

    final weightDiff = last.weight - first.weight;

    // Muscle Diff - Compare with first AVAILABLE muscle data
    final firstMuscle = sorted.firstWhere(
      (e) => e.muscleMassKg != null && e.muscleMassKg! > 0,
      orElse: () => last,
    );
    final muscleDiff =
        (last.muscleMassKg != null && firstMuscle.muscleMassKg != null)
        ? last.muscleMassKg! - firstMuscle.muscleMassKg!
        : 0.0;

    // Fat % Diff - Compare with first AVAILABLE fat data
    final firstFat = sorted.firstWhere(
      (e) => e.fatPercentage != null && e.fatPercentage! > 0,
      orElse: () => last,
    );
    final fatDiff =
        (last.fatPercentage != null && firstFat.fatPercentage != null)
        ? last.fatPercentage! - firstFat.fatPercentage!
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CONQUISTAS TOTAIS",
                    style: GoogleFonts.outfit(
                      color: Colors.grey[500],
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      final text = BodyTrackerFormatter.formatSummary(
                        measurements,
                      );
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Resumo copiado para o seu Agente de IA! 🤖",
                          ),
                          backgroundColor: AppColors.surface,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neonBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.neonBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.smart_toy,
                            color: AppColors.neonBlue,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "COPIAR IA",
                            style: GoogleFonts.outfit(
                              color: AppColors.neonBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              _buildHealthBadge(weightDiff, muscleDiff, fatDiff),
            ],
          ),
          const SizedBox(height: 20),

          // 3-Column Stats Layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Weight (Main stat)
              Expanded(
                child: _buildMainStat(
                  context,
                  "Peso Total",
                  weightDiff,
                  Icons.monitor_weight_outlined,
                  isWeight: true,
                ),
              ),

              Container(width: 1, height: 40, color: Colors.white10),

              // 2. Muscle
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildStatItem(
                    context,
                    "Músculo",
                    muscleDiff,
                    Icons.fitness_center,
                    unit: "kg",
                    invertColor: true, // Gain is good
                    incentive: muscleDiff > 0 ? "💪" : "",
                  ),
                ),
              ),

              // 3. Fat
              Expanded(
                child: _buildStatItem(
                  context,
                  "Gordura",
                  fatDiff,
                  Icons.local_fire_department,
                  unit: "%",
                  invertColor: false, // Loss is good
                  incentive: fatDiff < 0 ? "🔥" : "",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBadge(double wDiff, double mDiff, double fDiff) {
    // Determine status logic
    String text = "Em Evolução";
    Color color = AppColors.primary;
    IconData icon = Icons.trending_up;

    if (wDiff < 0 || mDiff > 0 || fDiff < 0) {
      text = "Mandou Bem! 🎉";
      color = AppColors.success;
      icon = Icons.verified;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStat(
    BuildContext context,
    String label,
    double value,
    IconData icon, {
    bool isWeight = false,
  }) {
    final isPositive = value > 0;
    final color = value <= 0 ? AppColors.success : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.outfit(
                color: Colors.grey[500],
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${isPositive ? '+' : ''}${value.toStringAsFixed(1)}",
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: color.withValues(alpha: 0.3), blurRadius: 10),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Text(
                "kg",
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    double value,
    IconData icon, {
    required String unit,
    bool invertColor = false,
    String incentive = "",
  }) {
    // If invertColor is true (e.g. Muscle), Positive is Good (Success), Negative is Bad (Error)
    // If invertColor is false (e.g. Fat), Negative is Good (Success), Positive is Bad (Error)

    final isPositive = value > 0;
    final isGood = invertColor ? isPositive : !isPositive;
    final color = isGood ? AppColors.success : AppColors.error;

    // If value is roughly 0, use neutral color
    final isNeutral = value.abs() < 0.1;
    final finalColor = isNeutral ? Colors.white60 : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.outfit(
                color: Colors.grey[600],
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Text(
                "${isPositive ? '+' : ''}${value.toStringAsFixed(1)}$unit",
                style: GoogleFonts.outfit(
                  color: finalColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (incentive.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(incentive, style: const TextStyle(fontSize: 14)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
