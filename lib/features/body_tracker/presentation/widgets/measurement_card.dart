import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../common/presentation/widgets/full_screen_image_viewer.dart';
import '../../../common/presentation/widgets/glass_container.dart';
import '../../domain/entities/body_measurement.dart';
import '../utils/bmi_utils.dart';
import 'bmi_gauge_bar.dart';
import 'trend_badge.dart';
import 'package:flutter/services.dart';
import '../utils/body_tracker_formatter.dart';

class MeasurementCard extends StatelessWidget {
  final BodyMeasurement measurement;
  final BodyMeasurement? previousMeasurement;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final double? userHeight; // For BMI calculation

  const MeasurementCard({
    super.key,
    required this.measurement,
    this.previousMeasurement,
    required this.isExpanded,
    required this.onExpand,
    required this.onEdit,
    required this.onDelete,
    this.userHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate BMI
    double? bmi;
    if (userHeight != null && userHeight! > 0) {
      bmi = measurement.weight / (userHeight! * userHeight!);
    } else {
      bmi = measurement.bmi;
    }

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(0), // Inner padding handled by contents
      color: AppColors.surface.withOpacity(0.8),
      child: Column(
        children: [
          // 1. Radar/Status Line (Projected)
          _buildRadarHeader(),

          // 2. Main Content (Summary)
          InkWell(
            onTap: onExpand,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Date & Options
                  _buildDateAndOptionsRow(context),
                  const SizedBox(height: 16),

                  // Split View: Weight | BMI
                  Row(
                    children: [
                      // Weight Side
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "PESO",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  measurement.weight.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    "kg",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            TrendBadge(
                              value: measurement.weight,
                              previousValue: previousMeasurement?.weight,
                              lowerIsBetter: true,
                              unit: "kg",
                            ),
                          ],
                        ),
                      ),

                      // Vertical Divider
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      const SizedBox(width: 16),

                      // BMI Side
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "IMC",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (bmi != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    bmi.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      BMIUtils.getBMIGrade(bmi),
                                      style: TextStyle(
                                        color: BMIUtils.getBMIColor(bmi),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              BmiGaugeBar(bmi: bmi),
                            ] else
                              const Text(
                                "-",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Expanded Details
          if (isExpanded) _buildExpandedDetails(context),

          // Expand Toggle Indicator
          GestureDetector(
            onTap: onExpand,
            child: Container(
              width: double.infinity,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                border: const Border(
                  top: BorderSide(color: Colors.transparent),
                ), // Clean look
              ),
              child: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.white.withOpacity(0.3),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarHeader() {
    // Simple visual line indicating "High Tech" feel.
    // Logic: Fat (Left), Muscle (Center), Weight (Right) status.
    // For now, static gradient or simple logic.
    return Container(
      height: 4,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue, // Fat
            AppColors.primary, // Muscle
            Colors.orange, // Weight
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndOptionsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                DateFormat(
                  'dd MMM yyyy',
                ).format(measurement.date).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (measurement.imagePaths.isNotEmpty) ...[
              const SizedBox(width: 8),
              const Icon(Icons.camera_alt, size: 14, color: Colors.grey),
            ],
            if (measurement.reportUrl != null &&
                measurement.reportUrl!.isNotEmpty) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(measurement.reportUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neonBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.neonBlue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons
                            .description, // Changed to generic doc icon or medical
                        size: 14,
                        color: AppColors.neonBlue,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "VER EXAME",
                        style: TextStyle(
                          color: AppColors.neonBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),

        // Menu
        SizedBox(
          height: 24,
          width: 24,
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
            onSelected: (value) {
              if (value == 'copy_ai') {
                final text = BodyTrackerFormatter.formatMeasurement(
                  measurement,
                  previous: previousMeasurement,
                );
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Medidas copiadas para o seu Agente de IA! 🤖",
                    ),
                    backgroundColor: AppColors.surface,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_ai',
                child: Row(
                  children: [
                    Icon(Icons.smart_toy, size: 16, color: AppColors.neonBlue),
                    SizedBox(width: 8),
                    Text("Copiar para IA"),
                  ],
                ),
              ),
              const PopupMenuItem(value: 'edit', child: Text("Editar")),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  "Excluir",
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.2),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. PHOTOS (Parallax-like)
          if (measurement.imagePaths.isNotEmpty) ...[
            _buildSectionTitle("GALERIA", Icons.photo_library),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: measurement.imagePaths.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            imagePaths: measurement.imagePaths,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                        image: DecorationImage(
                          image: FileImage(File(measurement.imagePaths[index])),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // B. BIOIMPEDANCE (Premium)
          if (measurement.fatPercentage != null ||
              measurement.muscleMassKg != null) ...[
            _buildSectionTitle("BIOIMPEDÂNCIA (CORE)", Icons.flash_on),
            const SizedBox(height: 12),
            GlassContainer(
              color: AppColors.neonBlue.withOpacity(0.05),
              border: Border.all(color: AppColors.neonBlue.withOpacity(0.2)),
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  if (measurement.fatPercentage != null)
                    _buildDetailItem(
                      "Gordura",
                      "${measurement.fatPercentage!.toStringAsFixed(1)}%",
                      measurement.fatPercentage!,
                      previousMeasurement?.fatPercentage,
                      lowerIsBetter: true,
                      digits: 1,
                    ),
                  if (measurement.muscleMassKg != null)
                    _buildDetailItem(
                      "Massa Muscular",
                      "${measurement.muscleMassKg!.toStringAsFixed(1)} kg",
                      measurement.muscleMassKg!,
                      previousMeasurement?.muscleMassKg,
                      lowerIsBetter: false,
                      digits: 1,
                      isHighlighted: true,
                    ),
                  if (measurement.visceralFat != null)
                    _buildDetailItem(
                      "Gordura Visceral",
                      "${measurement.visceralFat}",
                      measurement.visceralFat!.toDouble(),
                      previousMeasurement?.visceralFat?.toDouble(),
                      lowerIsBetter: true,
                      digits: 0,
                      isHighlighted: true,
                    ),
                  if (measurement.bodyAge != null)
                    _buildDetailItem(
                      "Idade Corp.",
                      "${measurement.bodyAge}",
                      measurement.bodyAge!.toDouble(),
                      previousMeasurement?.bodyAge?.toDouble(),
                      digits: 0,
                      lowerIsBetter: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // C. SEGMENTED (Silhouette)
          if (measurement.muscleRightArm != null) ...[
            _buildSectionTitle("SEGMENTADA", Icons.accessibility_new),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLimbStat(
                        "Braço Esq.",
                        measurement.muscleLeftArm,
                        previousMeasurement?.muscleLeftArm,
                      ),
                      const Icon(Icons.person, color: Colors.grey, size: 48),
                      _buildLimbStat(
                        "Braço Dir.",
                        measurement.muscleRightArm,
                        previousMeasurement?.muscleRightArm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLimbStat(
                        "Perna Esq.",
                        measurement.muscleLeftLeg,
                        previousMeasurement?.muscleLeftLeg,
                      ),
                      _buildLimbStat(
                        "Perna Dir.",
                        measurement.muscleRightLeg,
                        previousMeasurement?.muscleRightLeg,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // D. CIRCUMFERENCES
          _buildSectionTitle("CIRCUNFERÊNCIAS", Icons.straighten),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 16,
            children: [
              if (measurement.waistCircumference > 0)
                _buildGridItem(
                  "Cintura",
                  measurement.waistCircumference,
                  previousMeasurement?.waistCircumference,
                ),
              if ((measurement.hipsCircumference ?? 0) > 0)
                _buildGridItem(
                  "Quadril",
                  measurement.hipsCircumference!,
                  previousMeasurement?.hipsCircumference,
                ),
              if (measurement.chestCircumference > 0)
                _buildGridItem(
                  "Peitoral",
                  measurement.chestCircumference,
                  previousMeasurement?.chestCircumference,
                  lowerIsBetter: false,
                ),
              if (measurement.bicepsRight > 0)
                _buildGridItem(
                  "Bíceps (Dir)",
                  measurement.bicepsRight,
                  previousMeasurement?.bicepsRight,
                  lowerIsBetter: false,
                ),
              if (measurement.thighRight != null && measurement.thighRight! > 0)
                _buildGridItem(
                  "Coxa (Dir)",
                  measurement.thighRight!,
                  previousMeasurement?.thighRight,
                  lowerIsBetter: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    String label,
    String displayValue,
    double value,
    double? prev, {
    bool lowerIsBetter = false,
    int digits = 1,
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            if (isHighlighted)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.star, size: 10, color: AppColors.primary),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayValue,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (prev != null) ...[
              const SizedBox(width: 6),
              TrendBadge(
                value: value,
                previousValue: prev,
                lowerIsBetter: lowerIsBetter,
                precision: digits,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildLimbStat(String label, double? value, double? prev) {
    if (value == null) return const SizedBox.shrink();
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(
          "${value.toStringAsFixed(1)} kg",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        TrendBadge(value: value, previousValue: prev, lowerIsBetter: false),
      ],
    );
  }

  Widget _buildGridItem(
    String label,
    double value,
    double? prev, {
    bool lowerIsBetter = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${value.toStringAsFixed(1)} cm",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TrendBadge(
                value: value,
                previousValue: prev,
                lowerIsBetter: lowerIsBetter,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
