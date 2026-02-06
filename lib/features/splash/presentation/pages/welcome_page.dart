import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/data/services/backup_service.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../../../../core/constants/app_colors.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo
              Center(
                child: Image.asset(
                  'assets/icon/logo.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.fitness_center,
                      size: 100,
                      color: AppColors.primary,
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Bem-vindo ao\nShape.log',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Seu companheiro definitivo de treinos e monitoramento corporal.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const Spacer(),

              // Create New Profile Button
              ElevatedButton(
                onPressed: () => context.go('/profile/create'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Criar Novo Perfil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Restore Backup Button
              OutlinedButton.icon(
                onPressed: () => _handleRestoreBackup(context, ref),
                icon: const Icon(Icons.restore_page),
                label: const Text('Restaurar Backup Existente'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRestoreBackup(BuildContext context, WidgetRef ref) async {
    try {
      final success = await ref.read(backupServiceProvider).restoreFullBackup();
      if (success) {
        // Invalidate providers to reload data
        ref.invalidate(userProfileProvider);
        ref.invalidate(routineListProvider);
        ref.invalidate(
          historyListProvider,
        ); // Ensure this provider exists or remove if not needed

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup restaurado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          // Put logic to verify if profile exists now, just in case backup was empty of profile?
          // Assuming backup has profile if it was a full backup.
          context.go('/');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao restaurar backup: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
