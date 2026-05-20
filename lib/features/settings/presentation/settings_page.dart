import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../profile/presentation/providers/user_profile_provider.dart';
import '../../body_tracker/presentation/providers/body_tracker_provider.dart';
import '../../workout/presentation/providers/workout_provider.dart';
import '../data/services/backup_service.dart';
import '../data/repositories/settings_repository.dart';
import '../../image_library/presentation/image_library_settings_page.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_version_provider.dart';
import 'widgets/settings_widgets.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/image_path_resolver.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileState = ref.watch(userProfileProvider);
    final userProfile = userProfileState.asData?.value;
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.asData?.value != null;

    final appVersion = ref.watch(appVersionProvider).asData?.value ?? '…';
    final routinesAsync = ref.watch(routineListProvider);
    final historyAsync = ref.watch(historyListProvider);
    final measurements = ref.watch(bodyTrackerProvider);
    final settingsRepo = ref.watch(settingsRepositoryProvider);

    final workoutCount = routinesAsync.asData?.value.length ?? 0;
    final historyCount = historyAsync.asData?.value.length ?? 0;
    final measurementCount = measurements.length;
    final lastBackup = settingsRepo.getLastBackupDate();

    if (kIsWeb) {
      return _buildWebSettings(
        context, ref,
        userProfile: userProfile,
        isLoggedIn: isLoggedIn,
        workoutCount: workoutCount,
        historyCount: historyCount,
        measurementCount: measurementCount,
        appVersion: appVersion,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
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

                  // 3. Data Vault (Backup) — só no mobile
                  if (!kIsWeb) ...[
                    DataVaultCard(
                      lastBackupDate: lastBackup,
                      onBackup: () => _handleBackup(context, ref),
                      onRestore: () => _handleRestore(context, ref),
                    ),
                    const SizedBox(height: 24),
                  ],

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

                  if (!kIsWeb)
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
                    subtitle: 'v$appVersion \u00b7 Shape.log',
                    iconColor: Colors.tealAccent,
                    onTap: () => _showAboutDialog(context, appVersion),
                  ),

                  // Logout (visível apenas quando autenticado com Google)
                  if (isLoggedIn) ...[
                    const SizedBox(height: 8),
                    const Divider(color: Colors.red, thickness: 0.3),
                    const SizedBox(height: 8),
                    SettingsMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Deslogar da conta',
                      subtitle: 'Sair da conta Google conectada',
                      iconColor: Colors.redAccent,
                      onTap: () => _handleLogout(context, ref),
                    ),
                  ],

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
      final zipFilePath = await ref
          .read(backupServiceProvider)
          .generateFullBackupZip();

      if (context.mounted) {
        AppDialogs.hideLoadingDialog(
          context,
        ); // Hide loading as soon as ZIP is generated
      }

      if (zipFilePath == null) {
        if (context.mounted) {
          SnackbarUtils.showError(
            context,
            'Erro ao gerar o arquivo de backup.',
          );
        }
        return;
      }

      final now = DateTime.now();
      final dateStr = DateFormat('dd_MM_yyyy').format(now);
      final timeStr = DateFormat('HH_mm').format(now);
      final fileName = 'shapelog_backup_$dateStr - $timeStr.zip';

      final size = MediaQuery.sizeOf(context);
      final sharePositionOrigin = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 1,
        height: 1,
      );

      // Now open Share Sheet outside of modal loading context
      final result = await Share.shareXFiles(
        [XFile(zipFilePath, mimeType: 'application/zip', name: fileName)],
        subject: 'Shape.log Full Backup - $dateStr $timeStr',
        sharePositionOrigin: sharePositionOrigin,
      );

      if (result.status == ShareResultStatus.success) {
        await ref.read(settingsRepositoryProvider).setLastBackupDate(now);
        if (context.mounted) {
          SnackbarUtils.showSuccess(context, 'Backup enviado!');
        }
      }
    } catch (e) {
      // Just in case loading dialog is still open
      try {
        if (context.mounted) {
          AppDialogs.hideLoadingDialog(context);
        }
      } catch (_) {}

      if (context.mounted) {
        SnackbarUtils.showError(context, 'Erro ao realizar backup: $e');
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    try {
      // 1. Seleciona e Analisa
      BackupAnalysis? analysis;
      try {
        analysis = await ref.read(backupServiceProvider).pickAndAnalyzeBackup();
      } catch (e) {
        if (context.mounted) {
          SnackbarUtils.showError(
            context,
            'Arquivo inválido ou corrompido. Selecione um backup gerado pelo Shape.log.',
          );
        }
        return;
      }

      if (analysis == null) {
        // Usuário cancelou o seletor de arquivos
        return;
      }

      if (!context.mounted) return;

      final isLibraryOnly = analysis.metadata['libraryOnly'] == true;

      // 2. Diálogo específico para backup legado (apenas imagens de biblioteca)
      if (isLibraryOnly) {
        final confirmedLegacy = await AppDialogs.showConfirmDialog<bool>(
          context: context,
          title: "Backup Legado Detectado",
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Este arquivo não contém dados de treinos ou medidas.",
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                "📸 Imagens da biblioteca: ${analysis.imageCount} arquivos",
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                "Deseja importar apenas as imagens da biblioteca mesmo assim?",
                style: GoogleFonts.outfit(
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          confirmText: "IMPORTAR IMAGENS",
          isDestructive: false,
        );
        if (confirmedLegacy != true) return;
      } else {
        // 2b. Diálogo padrão para backup completo
        final confirmed = await AppDialogs.showConfirmDialog<bool>(
          context: context,
          title: "Importar Backup?",
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Os dados do backup serão mesclados com os dados atuais do app.",
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                "📅 Data: ${DateFormat('dd/MM/yyyy HH:mm').format(analysis.timestamp)}",
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "🏋️ Treinos: ${analysis.workoutCount}",
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              Text(
                "📅 Histórico: ${analysis.historyCount} registros",
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              Text(
                "📏 Medidas: ${analysis.measurementCount} registros",
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              Text(
                "📸 Imagens: ${analysis.imageCount} arquivos",
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                "Registros com o mesmo ID serão atualizados. Dados existentes não serão apagados.",
                style: GoogleFonts.outfit(
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          confirmText: "IMPORTAR BACKUP",
          isDestructive: false,
        );
        if (confirmed != true) return;
      }

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

        // Se o usuário está autenticado, sincronizar dados restaurados com o Firebase
        final syncService = ref.read(syncServiceProvider);
        if (syncService.isUserAuthenticated) {
          if (context.mounted) {
            AppDialogs.showLoadingDialog(
              context,
              message: 'Enviando arquivos\npara o Firebase...',
            );
          }
          try {
            await syncService.uploadLocalDataToFirestore();
            // Sobe biblioteca separadamente (pode ser lento — erros são silenciosos)
            syncService.uploadLibraryToStorage().ignore();
            if (context.mounted) {
              AppDialogs.hideLoadingDialog(context);
              SnackbarUtils.showSuccess(
                context,
                'Backup restaurado e sincronizado com o Firebase!',
              );
            }
          } catch (syncError) {
            print('Aviso ao sincronizar backup com o Firestore: $syncError');
            if (context.mounted) {
              AppDialogs.hideLoadingDialog(context);
              SnackbarUtils.showSuccess(
                context,
                'Backup restaurado! A sincronização ocorrerá quando houver conexão.',
              );
            }
          }
        } else {
          if (context.mounted) {
            SnackbarUtils.showSuccess(
              context,
              'Backup restaurado com sucesso!',
            );
          }
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

  void _showAboutDialog(BuildContext context, String version) {
    AppDialogs.showInfoDialog(
      context: context,
      title: "Shape.log",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Seu companheiro de treinos e medidas."),
          const SizedBox(height: 8),
          Text("Vers\u00e3o: $version"),
          const Text("Desenvolvido com Flutter & Riverpod."),
        ],
      ),
      buttonText: "OK",
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialogs.showConfirmDialog<bool>(
      context: context,
      title: "Deslogar da conta?",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Você será desconectado da sua conta Google.",
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Text(
            "Por motivos de segurança e privacidade, os dados locais serão limpos deste dispositivo. Eles continuarão salvos em sua conta na nuvem.",
            style: GoogleFonts.outfit(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
      confirmText: "DESLOGAR",
      isDestructive: true,
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      AppDialogs.showLoadingDialog(context);

      // Limpa dados locais por privacidade/segurança de múltiplos usuários
      await ref.read(settingsRepositoryProvider).clearAllBoxes();

      // Realiza o logout do FirebaseAuth e GoogleSignIn
      await ref.read(authServiceProvider).signOut();

      // Invalida os providers de dados para limpar o cache em memória
      ref.invalidate(userProfileProvider);
      ref.invalidate(routineListProvider);
      ref.invalidate(historyListProvider);
      ref.invalidate(bodyTrackerProvider);

      if (context.mounted) {
        AppDialogs.hideLoadingDialog(context);
        context.go('/welcome');
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.hideLoadingDialog(context);
        SnackbarUtils.showError(context, 'Erro ao deslogar: $e');
      }
    }
  }

  // ── Layout web SaaS ───────────────────────────────────────────────────────
  Widget _buildWebSettings(
    BuildContext context,
    WidgetRef ref, {
    required dynamic userProfile,
    required bool isLoggedIn,
    required int workoutCount,
    required int historyCount,
    required int measurementCount,
    required String appVersion,
  }) {
    final name = userProfile?.name ?? '—';
    final pic = userProfile?.profilePicturePath;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Perfil ───────────────────────────────────────────────────
            _SectionLabel('CONTA'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: _cardDeco(),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    backgroundImage: pic != null
                        ? ImagePathResolver.resolveToImageProvider(pic)
                        : null,
                    child: pic == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isLoggedIn ? 'Conta Google conectada' : 'Modo convidado',
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.push('/profile/edit'),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text('Editar perfil',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Stats ─────────────────────────────────────────────────────
            _SectionLabel('DADOS'),
            const SizedBox(height: 12),
            Row(
              children: [
                _WebStatCard(
                    icon: Icons.fitness_center,
                    label: 'Treinos',
                    value: '$workoutCount',
                    color: AppColors.primary),
                const SizedBox(width: 16),
                _WebStatCard(
                    icon: Icons.history,
                    label: 'Histórico',
                    value: '$historyCount',
                    color: Colors.blueAccent),
                const SizedBox(width: 16),
                _WebStatCard(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Medidas',
                    value: '$measurementCount',
                    color: Colors.purpleAccent),
              ],
            ),

            const SizedBox(height: 32),

            // ── Sistema ───────────────────────────────────────────────────
            _SectionLabel('SISTEMA'),
            const SizedBox(height: 12),
            Container(
              decoration: _cardDeco(),
              child: Column(
                children: [
                  _WebMenuItem(
                    icon: Icons.info_outline,
                    title: 'Sobre',
                    subtitle: 'v$appVersion · Shape.log',
                    iconColor: Colors.tealAccent,
                    onTap: () => _showAboutDialog(context, appVersion),
                  ),
                  if (isLoggedIn) ...[
                    Divider(
                        height: 1,
                        color: Colors.white.withOpacity(0.07)),
                    _WebMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Sair da conta',
                      subtitle: 'Desconectar conta Google',
                      iconColor: Colors.redAccent,
                      onTap: () => _handleLogout(context, ref),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      );
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white38,
          letterSpacing: 1.2,
        ),
      );
}

class _WebStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _WebStatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(label,
                    style:
                        GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WebMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;
  const _WebMenuItem(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.iconColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      hoverColor: Colors.white.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                Text(subtitle,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.white38)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}
