import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../../workout/presentation/providers/workout_provider.dart';

class WebLoginPage extends ConsumerStatefulWidget {
  const WebLoginPage({super.key});

  @override
  ConsumerState<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends ConsumerState<WebLoginPage> {
  bool _loading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      final credential =
          await ref.read(authServiceProvider).signInWithGoogle();

      if (credential != null) {
        final syncService = ref.read(syncServiceProvider);
        try {
          await syncService.downloadDataFromFirestore();
          await syncService.uploadLocalDataToFirestore();
        } catch (_) {}

        ref.invalidate(userProfileProvider);
        ref.invalidate(routineListProvider);

        if (mounted) context.go('/');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Erro ao entrar com Google: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isNarrow = size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Row(
        children: [
          // ── Painel esquerdo — hero visual ──────────────────────────────
          if (!isNarrow)
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradiente de fundo
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0A0A0A), Color(0xFF111111)],
                      ),
                    ),
                  ),

                  // Grid decorativo
                  CustomPaint(painter: _GridPainter()),

                  // Glow neon
                  Positioned(
                    top: -120,
                    left: -120,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    right: -80,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Conteúdo hero
                  Padding(
                    padding: const EdgeInsets.all(56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                children: [
                                  const TextSpan(text: 'Shape'),
                                  TextSpan(
                                    text: '.log',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Headline
                        Text(
                          'Gerencie seus\ntreinos em qualquer\nlugar.',
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Dashboard web para importar treinos, visualizar '
                          'histórico e acompanhar suas métricas corporais.',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.white54,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Feature badges
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: const [
                            _FeatureBadge(
                              icon: Icons.fitness_center,
                              label: 'Gestão de Treinos',
                            ),
                            _FeatureBadge(
                              icon: Icons.bar_chart,
                              label: 'Relatórios',
                            ),
                            _FeatureBadge(
                              icon: Icons.monitor_weight_outlined,
                              label: 'Body Tracker',
                            ),
                            _FeatureBadge(
                              icon: Icons.cloud_sync,
                              label: 'Sync em Tempo Real',
                            ),
                          ],
                        ),

                        const SizedBox(height: 56),

                        // Stat bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.07),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Stat(value: '100%', label: 'Offline-first'),
                              _divider(),
                              _Stat(value: 'iOS', label: 'App nativo'),
                              _divider(),
                              _Stat(value: 'Android', label: 'App nativo'),
                              _divider(),
                              _Stat(value: 'AI', label: 'Import JSON'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Painel direito — formulário de login ───────────────────────
          Container(
            width: isNarrow ? size.width : 520,
            color: const Color(0xFF0D0D0D),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo (só no mobile/narrow)
                      if (isNarrow) ...[
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                children: [
                                  const TextSpan(text: 'Shape'),
                                  TextSpan(
                                    text: '.log',
                                    style:
                                        TextStyle(color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],

                      Text(
                        'Bem-vindo de volta',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entre com sua conta Google para acessar o painel.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white38,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Botão Google
                      _GoogleSignInButton(
                        loading: _loading,
                        onPressed: _handleGoogleSignIn,
                      ),

                      const SizedBox(height: 32),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'acesso web',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.white24,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'O painel web é voltado para gestão. '
                                'Para treinar, use o app iOS ou Android.',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.white60,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Footer
                      Text(
                        '© 2025 Shape.log · Desenvolvido por João Paulo',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 32,
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.white.withOpacity(0.08),
      );
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white24,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black54,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continuar com Google',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
        ),
      ],
    );
  }
}

// Grid decorativo de fundo
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
