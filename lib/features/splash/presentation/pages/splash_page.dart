import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkProfileAndNavigate();
  }

  Future<void> _checkProfileAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final repo = ref.read(userProfileRepositoryProvider);
      final profile = await repo.getProfile();

      if (mounted) {
        if (profile == null) {
          context.go('/profile/create');
        } else {
          context.go('/');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/logo.png', height: 120),
            const SizedBox(height: 24),
            const Text(
              'Shape.log',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
