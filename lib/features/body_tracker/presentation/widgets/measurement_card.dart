import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../common/presentation/widgets/full_screen_image_viewer.dart';
import '../../domain/entities/body_measurement.dart';
import '../utils/bmi_utils.dart';
import 'bmi_gauge_bar.dart';
import 'trend_badge.dart';
import 'package:flutter/services.dart';
import '../utils/body_tracker_formatter.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 1. Radar/Status Line (Subtle Gradient Header)
          _buildRadarHeader(),

          // 2. Main Content (Summary)
          InkWell(
            onTap: onExpand,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Date & Options
                  _buildDateAndOptionsRow(context),
                  const SizedBox(height: 20),

                  // Split View: Weight | BMI
                  Row(
                    children: [
                      // Weight Side
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "PESO",
                              style: GoogleFonts.outfit(
                                color: Colors.grey[500],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  measurement.weight.toStringAsFixed(1),
                                  style: GoogleFonts.outfit(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    "kg",
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.white.withOpacity(0.05),
                      ),

                      // BMI Side
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "IMC",
                              style: GoogleFonts.outfit(
                                color: Colors.grey[500],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (bmi != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    bmi.toStringAsFixed(1),
                                    style: GoogleFonts.outfit(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      BMIUtils.getBMIGrade(bmi),
                                      style: GoogleFonts.outfit(
                                        color: BMIUtils.getBMIColor(bmi),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              BmiGaugeBar(bmi: bmi),
                            ] else
                              Text(
                                "-",
                                style: GoogleFonts.outfit(
                                  color: Colors.grey[800],
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
          InkWell(
            onTap: onExpand,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.02)),
              child: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey[700],
                size: 20,
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
      height: 3,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.5),
            AppColors.primary,
            AppColors.primary.withOpacity(0.5),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                DateFormat(
                  'dd MMM yyyy',
                ).format(measurement.date).toUpperCase(),
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
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
                  child: Row(
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
                  style: TextStyle(color: Colors.redAccent),
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
      color: Colors.black.withOpacity(0.35),
      padding: const EdgeInsets.all(20),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neonBlue.withOpacity(0.1)),
              ),
              child: Wrap(
                spacing: 24,
                runSpacing: 20,
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
              // 1. Pescoço
              if ((measurement.neck ?? 0) > 0)
                _buildGridItem(
                  "Pescoço",
                  measurement.neck!,
                  previousMeasurement?.neck,
                  lowerIsBetter: false,
                ),
              // 2. Ombros
              if ((measurement.shoulders ?? 0) > 0)
                _buildGridItem(
                  "Ombros",
                  measurement.shoulders!,
                  previousMeasurement?.shoulders,
                  lowerIsBetter: false,
                ),
              // 3. Peitoral
              if (measurement.chestCircumference > 0)
                _buildGridItem(
                  "Peitoral",
                  measurement.chestCircumference,
                  previousMeasurement?.chestCircumference,
                  lowerIsBetter: false,
                ),
              // 4. Cintura
              if (measurement.waistCircumference > 0)
                _buildGridItem(
                  "Cintura",
                  measurement.waistCircumference,
                  previousMeasurement?.waistCircumference,
                  lowerIsBetter: true,
                ),
              // 5. Quadril
              if ((measurement.hipsCircumference ?? 0) > 0)
                _buildGridItem(
                  "Quadril",
                  measurement.hipsCircumference!,
                  previousMeasurement?.hipsCircumference,
                  lowerIsBetter: true,
                ),
              // 6. Braços (Bíceps)
              if (measurement.bicepsLeft > 0)
                _buildGridItem(
                  "Bíceps (Esq)",
                  measurement.bicepsLeft,
                  previousMeasurement?.bicepsLeft,
                  lowerIsBetter: false,
                ),
              if (measurement.bicepsRight > 0)
                _buildGridItem(
                  "Bíceps (Dir)",
                  measurement.bicepsRight,
                  previousMeasurement?.bicepsRight,
                  lowerIsBetter: false,
                ),
              // 7. Antebraços
              if ((measurement.forearmLeft ?? 0) > 0)
                _buildGridItem(
                  "Antebraço (Esq)",
                  measurement.forearmLeft!,
                  previousMeasurement?.forearmLeft,
                  lowerIsBetter: false,
                ),
              if ((measurement.forearmRight ?? 0) > 0)
                _buildGridItem(
                  "Antebraço (Dir)",
                  measurement.forearmRight!,
                  previousMeasurement?.forearmRight,
                  lowerIsBetter: false,
                ),
              // 8. Coxas
              if ((measurement.thighLeft ?? 0) > 0)
                _buildGridItem(
                  "Coxa (Esq)",
                  measurement.thighLeft!,
                  previousMeasurement?.thighLeft,
                  lowerIsBetter: false,
                ),
              if ((measurement.thighRight ?? 0) > 0)
                _buildGridItem(
                  "Coxa (Dir)",
                  measurement.thighRight!,
                  previousMeasurement?.thighRight,
                  lowerIsBetter: false,
                ),
              // 9. Panturrilhas
              if ((measurement.calvesLeft ?? 0) > 0)
                _buildGridItem(
                  "Panturrilha (Esq)",
                  measurement.calvesLeft!,
                  previousMeasurement?.calvesLeft,
                  lowerIsBetter: false,
                ),
              if ((measurement.calvesRight ?? 0) > 0)
                _buildGridItem(
                  "Panturrilha (Dir)",
                  measurement.calvesRight!,
                  previousMeasurement?.calvesRight,
                  lowerIsBetter: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
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
              style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 11),
            ),
            if (isHighlighted)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.star, size: 10, color: AppColors.primary),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayValue,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 17,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (prev != null) ...[
              const SizedBox(width: 8),
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
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          "${value.toStringAsFixed(1)} kg",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 10),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "${value.toStringAsFixed(1)} cm",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
