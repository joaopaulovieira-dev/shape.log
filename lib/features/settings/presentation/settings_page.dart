import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // Add this import
import '../../profile/presentation/providers/user_profile_provider.dart';
import '../../body_tracker/presentation/providers/body_tracker_provider.dart';
import '../../workout/presentation/providers/workout_provider.dart';
import '../data/services/backup_service.dart';
import '../data/repositories/settings_repository.dart';
import '../../image_library/presentation/image_library_settings_page.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/constants/app_colors.dart'; // Add this import
import 'widgets/settings_widgets.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileState = ref.watch(userProfileProvider);
    final userProfile = userProfileState.asData?.value;

    final routinesAsync = ref.watch(routineListProvider);
    final historyAsync = ref.watch(historyListProvider);
    final measurements = ref.watch(bodyTrackerProvider);
    final settingsRepo = ref.watch(settingsRepositoryProvider);

    final workoutCount = routinesAsync.asData?.value.length ?? 0;
    final historyCount = historyAsync.asData?.value.length ?? 0;
    final measurementCount = measurements.length;
    final lastBackup = settingsRepo.getLastBackupDate();

    return Scaffold(
      backgroundColor: Colors.black, // Ensure background matches other screens
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                'Central de Ajustes',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.background,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Profile Hero (ID Badge)
                  ProfileHeroCard(
                    userProfile: userProfile,
                    totalWorkouts:
                        historyCount, // Badge based on experience (history)
                    onEditTap: () => context.push('/profile/edit'),
                  ),
                  const SizedBox(height: 24),

                  // 2. System Health (Stats)
                  SystemHealthCard(
                    workoutCount: workoutCount,
                    historyCount: historyCount,
                    measurementCount: measurementCount,
                  ),
                  const SizedBox(height: 24),

                  // 3. Data Vault (Backup)
                  DataVaultCard(
                    lastBackupDate: lastBackup,
                    onBackup: () => _handleBackup(context, ref),
                    onRestore: () => _handleRestore(context, ref),
                  ),
                  const SizedBox(height: 24),

                  // 4. General Settings Grid/List
                  const Text(
                    "PREFERÊNCIAS & SISTEMA",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SettingsMenuItem(
                    icon: Icons.photo_library,
                    title: 'Biblioteca de Ativos',
                    subtitle: 'Gerenciar imagens de equipamentos',
                    iconColor: Colors.purpleAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ImageLibrarySettingsPage(),
                        ),
                      );
                    },
                  ),
                  SettingsMenuItem(
                    icon: Icons.info_outline,
                    title: 'Sobre',
                    subtitle: 'Versão 1.0.0 • Shape.log',
                    iconColor: Colors.tealAccent,
                    onTap: () => _showAboutDialog(context),
                  ),

                  // Bottom padding for scrolling
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context, WidgetRef ref) async {
    // Show loading using root navigator to avoid GoRouter conflicts
    AppDialogs.showLoadingDialog(context);

    try {
      final success = await ref.read(backupServiceProvider).createFullBackup();

      if (context.mounted) {
        AppDialogs.hideLoadingDialog(context); // Hide loading
      }

      if (success) {
        SnackbarUtils.showSuccess(context, 'Backup enviado!');
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.hideLoadingDialog(context); // Hide loading on error
        SnackbarUtils.showError(context, 'Erro ao realizar backup: $e');
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    try {
      // 1. Pick and Analyze
      final analysis = await ref
          .read(backupServiceProvider)
          .pickAndAnalyzeBackup();

      if (analysis == null) {
        // User cancelled picker or error analysis (error printed in service)
        return;
      }

      if (!context.mounted) return;

      // 2. Show Detailed Confirmation
      final confirmed = await AppDialogs.showConfirmDialog<bool>(
        context: context,
        title: "Restaurar Backup?",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Isso substituirá TODOS os dados atuais pelos do arquivo selecionado:",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              "📅 Data: ${DateFormat('dd/MM/yyyy HH:mm').format(analysis.timestamp)}",
            ),
            const SizedBox(height: 8),
            Text("🏋️ Treinos: ${analysis.workoutCount}"),
            Text("📅 Histórico: ${analysis.historyCount} registros"),
            Text("📏 Medidas: ${analysis.measurementCount} registros"),
            Text("📸 Imagens: ${analysis.imageCount} arquivos"),
            const SizedBox(height: 16),
            const Text(
              "Essa ação não pode ser desfeita.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        confirmText: "CONFIRMAR RESTAURAÇÃO",
        isDestructive: true,
      );

      if (confirmed != true) return;

      // 3. Execute Restore
      if (!context.mounted) return;

      AppDialogs.showLoadingDialog(context);

      print('Starting Full Restore...');
      final success = await ref
          .read(backupServiceProvider)
          .restoreFromAnalysis(analysis);
      print('Full Restore finished. Success: $success');

      await Future.delayed(const Duration(milliseconds: 200));

      if (rootNavigator.canPop()) {
        AppDialogs.hideLoadingDialog(context); // Hide loading
      }

      if (success) {
        // Invalidate/Refresh providers
        final _ = ref.refresh(userProfileProvider);
        ref.invalidate(bodyTrackerProvider);
        ref.invalidate(routineListProvider);
        ref.invalidate(historyListProvider);

        if (context.mounted) {
          SnackbarUtils.showSuccess(context, 'Backup restaurado com sucesso!');
        }
      } else {
        if (context.mounted) {
          SnackbarUtils.showInfo(context, 'Falha ao restaurar backup.');
        }
      }
    } catch (e) {
      print('Restore process error: $e');
      if (rootNavigator.canPop()) {
        AppDialogs.hideLoadingDialog(context);
      }
      if (context.mounted) {
        SnackbarUtils.showError(context, 'Erro ao restaurar: $e');
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    AppDialogs.showInfoDialog(
      context: context,
      title: "Shape.log",
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Seu companheiro de treinos e medidas."),
          SizedBox(height: 8),
          Text("Versão: 1.0.0"),
          Text("Desenvolvido com Flutter & Riverpod."),
        ],
      ),
      buttonText: "OK",
    );
  }
}
