import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Added for DateFormat
import '../../../settings/data/services/backup_service.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/sync_service.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.03),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  // Logo with glow
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/icon/logo.png',
                        height: 140,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.fitness_center,
                            size: 100,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Bem-vindo ao\nShape.log',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seu companheiro definitivo de treinos e monitoramento corporal.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.grey[400],
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 2),

                  // Google Sign-In Button
                  SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => _handleGoogleSignIn(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Custom colored G for Google icon representation
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'ENTRAR COM O GOOGLE',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider OR
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OU',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Create Local Profile Button
                  SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => context.go('/profile/create'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'USAR MODO CONVIDADO (OFFLINE)',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Restore Backup Button
                  SizedBox(
                    height: 60,
                    child: TextButton.icon(
                      onPressed: () => _handleRestoreBackup(context, ref),
                      icon: const Icon(Icons.restore_page_outlined, size: 20),
                      label: const Text('RESTAURAR BACKUP LOCAL'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey[800]!),
                        ),
                        textStyle: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    try {
      AppDialogs.showLoadingDialog(context);
      final credential = await ref.read(authServiceProvider).signInWithGoogle();

      if (credential != null) {
        final syncService = ref.read(syncServiceProvider);

        // Se o usuário já tiver dados locais pré-existentes no Hive,
        // podemos enviá-los ao Firestore (Merge).
        // Se for um novo dispositivo sem dados locais, podemos baixar o Firestore.
        // Vamos rodar ambos em sequência de forma inteligente:
        // Primeiro tentamos fazer o download das informações salvas na nuvem.
        await syncService.downloadDataFromFirestore();

        // Em seguida, se houver dados locais que não estavam na nuvem, enviamos (Merge)
        await syncService.uploadLocalDataToFirestore();

        // Recarrega os dados do perfil local
        ref.invalidate(userProfileProvider);
        ref.invalidate(routineListProvider);

        if (context.mounted) {
          AppDialogs.hideLoadingDialog(context);

          // Verificar se o perfil agora existe localmente
          final repo = ref.read(userProfileRepositoryProvider);
          final profile = await repo.getProfile();

          if (profile != null) {
            context.go('/');
          } else {
            // Se o perfil ainda é nulo, redirecionamos para criação do perfil
            context.go('/profile/create');
          }
        }
      } else {
        if (context.mounted) {
          AppDialogs.hideLoadingDialog(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.hideLoadingDialog(context);
        SnackbarUtils.showError(context, 'Erro ao entrar com Google: $e');
      }
    }
  }

  Future<void> _handleRestoreBackup(BuildContext context, WidgetRef ref) async {
    try {
      final analysis = await ref
          .read(backupServiceProvider)
          .pickAndAnalyzeBackup();

      if (analysis != null) {
        if (!context.mounted) return;

        // Show confirmation dialog with summary
        // Show confirmation dialog with summary
        final confirmed = await AppDialogs.showConfirmDialog<bool>(
          context: context,
          title: "Restaurar Backup?",
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Resumo do arquivo selecionado:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "📅 Data: ${DateFormat('dd/MM/yyyy HH:mm').format(analysis.timestamp)}",
              ),
              Text("🏋️ Treinos: ${analysis.workoutCount}"),
              Text("📅 Histórico: ${analysis.historyCount}"),
              Text("📸 Imagens: ${analysis.imageCount}"),
            ],
          ),
          confirmText: "RESTAURAR",
        );

        if (confirmed != true) return;

        if (!context.mounted) return;

        // Show loading
        // Show loading
        AppDialogs.showLoadingDialog(context);

        final success = await ref
            .read(backupServiceProvider)
            .restoreFromAnalysis(analysis);

        if (context.mounted) {
          AppDialogs.hideLoadingDialog(context); // Hide loading
        }

        if (success) {
          // Invalidate providers to reload data
          ref.invalidate(userProfileProvider);
          ref.invalidate(routineListProvider);
          // ref.invalidate(historyListProvider); // Ensure this provider exists or remove if not needed. It was invalidating in previous code.

          if (context.mounted) {
            SnackbarUtils.showSuccess(
              context,
              'Backup restaurado com sucesso!',
            );
            context.go('/');
          }
        } else {
          if (context.mounted)
            SnackbarUtils.showError(context, "Falha na restauração.");
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, 'Erro ao restaurar backup: $e');
      }
    }
  }
}
