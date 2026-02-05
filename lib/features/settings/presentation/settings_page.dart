import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../profile/presentation/providers/user_profile_provider.dart';
import '../../body_tracker/presentation/providers/body_tracker_provider.dart';
import '../../workout/presentation/providers/workout_provider.dart';
import '../data/services/backup_service.dart';
import '../data/repositories/settings_repository.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileState = ref.watch(userProfileProvider);
    final userProfile = userProfileState.asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, "DADOS PESSOAIS"),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: const Text(
                'Meu Perfil Bio-Data',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                userProfile != null
                    ? '${userProfile.age} anos • ${userProfile.height}m • ${userProfile.targetWeight}kg (Meta)'
                    : 'Toque para configurar seu perfil',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/profile/edit');
              },
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, "SISTEMA"),
          const SizedBox(height: 8),

          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Sobre'),
                  subtitle: const Text('Versão 1.0.0'),
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, "DADOS & SEGURANÇA"),
          const SizedBox(height: 8),

          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildBackupStatusTile(context, ref),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.blue,
                  ),
                  title: const Text('Fazer Backup Agora'),
                  subtitle: const Text(
                    'Gera um arquivo .ZIP para salvar externamente',
                  ),
                  onTap: () => _handleBackup(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.settings_backup_restore,
                    color: Colors.orange,
                  ),
                  title: const Text('Restaurar Backup'),
                  subtitle: const Text('Importa dados de um arquivo anterior'),
                  onTap: () => _showRestoreConfirmation(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupStatusTile(BuildContext context, WidgetRef ref) {
    final settingsRepo = ref.watch(settingsRepositoryProvider);
    final lastBackup = settingsRepo.getLastBackupDate();

    String statusText = 'Nunca';
    Color textColor = Colors.grey;
    bool isUrgent = false;

    if (lastBackup != null) {
      final daysSince = DateTime.now().difference(lastBackup).inDays;
      statusText = DateFormat('dd/MM/yyyy HH:mm').format(lastBackup);

      if (daysSince > 7) {
        textColor = Colors.red;
        isUrgent = true;
      } else {
        textColor = Colors.green;
      }
    }

    return ListTile(
      leading: Icon(
        isUrgent ? Icons.warning_amber_rounded : Icons.security,
        color: textColor,
      ),
      title: const Text('Último backup'),
      subtitle: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontWeight: isUrgent ? FontWeight.bold : null,
        ),
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading using root navigator to avoid GoRouter conflicts
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await ref.read(backupServiceProvider).createFullBackup();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Hide loading
      }

      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Backup enviado!'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Hide loading on error
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Erro ao realizar backup: $e')),
        );
      }
    }
  }

  void _showRestoreConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text("Restaurar Backup?"),
        content: const Text(
          "AVISO: Isso substituirá todos os seus dados atuais (Treinos, Medidas e Perfil) pelos dados do arquivo. Esta ação não pode ser desfeita.",
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text("CANCELAR"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              _handleRestore(context, ref);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("ENTENDO, RESTAURAR"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    // Show loading
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print('Starting Full Restore...');
      final success = await ref.read(backupServiceProvider).restoreFullBackup();
      print('Full Restore finished. Success: $success');

      // Small delay to ensure the dialog is fully rendered before popping
      await Future.delayed(const Duration(milliseconds: 200));

      if (rootNavigator.canPop()) {
        rootNavigator.pop(); // Hide loading
      }

      if (success) {
        // Invalidate/Refresh providers AFTER popping the dialog
        final _ = ref.refresh(userProfileProvider);
        ref.invalidate(bodyTrackerProvider);
        ref.invalidate(routineListProvider);
        ref.invalidate(historyListProvider);

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Backup completo restaurado! Dados e fotos foram atualizados.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Restauração cancelada ou falhou.')),
        );
      }
    } catch (e) {
      print('Restore process error: $e');
      // Ensure dialog is closed even on error
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro ao restaurar backup: $e')),
      );
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text("Shape.log"),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
