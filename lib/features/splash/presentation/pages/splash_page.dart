import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/constants/app_colors.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bgScaleAnimation;
  late Animation<double> _contentOpacityAnimation;
  late Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Fundo: zoom suave durante toda a animação
    _bgScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Logo e nome: fade in + slide up nos primeiros 700ms
    _contentOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    // Trigger navigation check
    _checkProfileAndNavigate();
  }

  Future<void> _checkProfileAndNavigate() async {
    // Aguarda animação
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final repo = ref.read(userProfileRepositoryProvider);
    final profile = await repo.getProfile();

    if (!mounted) return;

    // Navega imediatamente — sync roda em background
    if (profile == null) {
      context.go('/welcome');
    } else {
      context.go('/');
    }

    // Sync em background sem bloquear navegação
    final auth = ref.read(authServiceProvider);
    if (auth.currentUser != null) {
      final syncService = ref.read(syncServiceProvider);
      Future(() async {
        try {
          await syncService.uploadLocalDataToFirestore()
              .timeout(const Duration(seconds: 10));
        } catch (_) {}
        try {
          await syncService.downloadDataFromFirestore();
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // LAYER 1: The Living Background
          AnimatedBuilder(
            animation: _bgScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bgScaleAnimation.value,
                child: Image.asset(
                  'assets/images/splash_bg_gym.png', // New realistic asset
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: const Color(0xFF121212));
                  },
                ),
              );
            },
          ),

          // LAYER 2: The Dramatic Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4), // See ceiling/lights
                  Colors.black.withOpacity(0.9), // Solid base for text
                ],
                stops: const [0.0, 0.8],
              ),
            ),
          ),

          // LAYER 3: The Brand
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _contentOpacityAnimation,
                  child: SlideTransition(
                    position: _contentSlideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Image.asset('assets/icon/logo.png', height: 100),
                        const SizedBox(height: 16),
                        // App Name
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2.0,
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
                        const SizedBox(height: 40),
                        // Loading bar
                        SizedBox(
                          width: 160,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              minHeight: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
