import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../profile/presentation/providers/user_profile_provider.dart';
import '../../body_tracker/presentation/providers/body_tracker_provider.dart';
import '../../workout/presentation/providers/workout_provider.dart';
import '../data/services/backup_service.dart';
import '../data/repositories/settings_repository.dart';
import '../../image_library/presentation/image_library_settings_page.dart';
import '../../../../core/utils/snackbar_utils.dart';

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
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Biblioteca de Ativos'),
                  subtitle: const Text('Gerenciar imagens de equipamentos'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ImageLibrarySettingsPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
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
                  onTap: () => _handleRestore(context, ref),
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
        SnackbarUtils.showSuccess(context, 'Backup enviado!');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Hide loading on error
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
      final confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          title: const Text("Restaurar Backup?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Isso substituirá TODOS os dados atuais pelos do arquivo selecionado:",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("CANCELAR"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("CONFIRMAR RESTAURAÇÃO"),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // 3. Execute Restore
      if (!context.mounted) return;

      showDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      print('Starting Full Restore...');
      final success = await ref
          .read(backupServiceProvider)
          .restoreFromAnalysis(analysis);
      print('Full Restore finished. Success: $success');

      await Future.delayed(const Duration(milliseconds: 200));

      if (rootNavigator.canPop()) {
        rootNavigator.pop(); // Hide loading
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
        rootNavigator.pop();
      }
      if (context.mounted) {
        SnackbarUtils.showError(context, 'Erro ao restaurar: $e');
      }
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
