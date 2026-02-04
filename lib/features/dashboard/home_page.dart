import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon/logo.png', height: 32),
            const SizedBox(width: 12),
            const Text('Shape.log'),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Resumo da semana...'),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                // TODO: Quick start workout
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Treino Rápido'),
            ),
          ],
        ),
      ),
    );
  }
}
