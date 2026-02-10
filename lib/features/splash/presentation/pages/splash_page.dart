import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';

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
      duration: const Duration(milliseconds: 3500), // Total 3.5s
    );

    // Layer 1: Background "Breathing" (Slow Zoom)
    // 0ms -> 3500ms: Scale 1.0 -> 1.08
    _bgScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear, // Constant slow movement
      ),
    );

    // Layer 3: Brand Entrance (Fade In + Slide Up)
    // Starts at 500ms, ends at 2000ms (1.5s duration)
    // 500ms / 3500ms ~= 0.14
    // 2000ms / 3500ms ~= 0.57
    _contentOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.14, 0.57, curve: Curves.easeOut),
      ),
    );

    _contentSlideAnimation =
        Tween<Offset>(
          begin: const Offset(
            0,
            0.1,
          ), // Start slightly below (approx 30px relative)
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.14, 0.57, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();

    // Trigger navigation check
    _checkProfileAndNavigate();
  }

  Future<void> _checkProfileAndNavigate() async {
    // Wait for animation to complete roughly
    await Future.delayed(const Duration(milliseconds: 3500));

    if (mounted) {
      final repo = ref.read(userProfileRepositoryProvider);
      final profile = await repo.getProfile();

      if (mounted) {
        if (profile == null) {
          context.go('/welcome');
        } else {
          context.go('/');
        }
      }
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
                        Text(
                          'Shape.log',
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.0, // Premium spacing
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
