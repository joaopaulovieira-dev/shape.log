import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import 'package:shape_log/features/profile/domain/entities/user_profile.dart';
import 'dart:io';

// 1. Profile Hero Card
class ProfileHeroCard extends StatelessWidget {
  final UserProfile?
  userProfile; // Can be Entity or HiveModel, let's use dynamic or specific if possible.
  // Using UserProfile entity from domain is better, but HiveModel is used in SettingsPage.
  // Let's assume UserProfile object.
  final int totalWorkouts;
  final VoidCallback onEditTap;

  const ProfileHeroCard({
    super.key,
    required this.userProfile,
    required this.totalWorkouts,
    required this.onEditTap,
  });

  String _getBadge(int count) {
    if (count > 50) return "Elite";
    if (count > 10) return "Atleta";
    return "Novato";
  }

  Color _getBadgeColor(int count) {
    return AppColors.primary; // Enforce Neon Green for all badges
  }

  @override
  Widget build(BuildContext context) {
    final badge = _getBadge(totalWorkouts);
    final badgeColor = _getBadgeColor(totalWorkouts);
    final hasPhoto = userProfile?.profilePicturePath != null;
    final neonGreen = AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Standard Card Background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: neonGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: neonGreen.withOpacity(0.5),
                    width: 2,
                  ),
                  image: hasPhoto
                      ? DecorationImage(
                          image: FileImage(
                            File(userProfile!.profilePicturePath!),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasPhoto
                    ? Center(
                        child: Text(
                          userProfile?.name.isNotEmpty == true
                              ? userProfile!.name[0].toUpperCase()
                              : "U",
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: neonGreen,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfile?.name ?? "Usuário",
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userProfile != null
                          ? "${userProfile!.age} ANOS • ${userProfile!.height}m"
                          : "CONFIGURE SEU PERFIL",
                      style: GoogleFonts.robotoMono(
                        color: Colors.grey[400],
                        fontSize: 12,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Badge Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor.withOpacity(0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        badge.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Edit Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: IconButton(
                  onPressed: onEditTap,
                  icon: Icon(
                    Icons.edit,
                    color: neonGreen.withOpacity(0.8),
                    size: 20,
                  ),
                  tooltip: 'Editar Perfil',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 2. System Health Card
class SystemHealthCard extends StatelessWidget {
  final int workoutCount;
  final int historyCount;
  final int measurementCount;

  const SystemHealthCard({
    super.key,
    required this.workoutCount,
    required this.historyCount,
    required this.measurementCount,
  });

  @override
  Widget build(BuildContext context) {
    final totalRecords = workoutCount + historyCount + measurementCount;
    // Mock storage usage based on records roughly
    final storageUsageVal = (totalRecords * 0.005).clamp(
      0.05,
      0.9,
    ); // 0.5% per record, fake

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined, color: Colors.blueGrey),
              const SizedBox(width: 8),
              const Text(
                "ESTADO DO SISTEMA",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.blueGrey,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatColumn(label: "Treinos", value: "$workoutCount"),
              _StatColumn(label: "Histórico", value: "$historyCount"),
              _StatColumn(label: "Medidas", value: "$measurementCount"),
              _StatColumn(label: "Registros", value: "$totalRecords"),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Armazenamento Local",
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: storageUsageVal,
            backgroundColor: Colors.grey[800],
            color: Colors.blueGrey,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }
}

// 3. Data Vault Card
class DataVaultCard extends StatelessWidget {
  final DateTime? lastBackupDate;
  final VoidCallback onBackup;
  final VoidCallback onRestore;

  const DataVaultCard({
    super.key,
    required this.lastBackupDate,
    required this.onBackup,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysSince = lastBackupDate != null
        ? now.difference(lastBackupDate!).inDays
        : 999;

    final isSafe = daysSince < 7;
    final statusColor = isSafe ? Colors.green : Colors.orange;
    final statusIcon = isSafe ? Icons.shield : Icons.warning_amber_rounded;
    final statusText = isSafe ? "DADOS SEGUROS" : "BACKUP NECESSÁRIO";
    final lastBackupText = lastBackupDate != null
        ? "Último: ${DateFormat('dd/MM HH:mm').format(lastBackupDate!)}"
        : "Nenhum backup recente";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastBackupText,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onBackup,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("CRIAR BACKUP"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRestore,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("RESTAURAR DADOS"),
            ),
          ),
        ],
      ),
    );
  }
}

// 4. Settings Menu Item (Generic)
class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const SettingsMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
