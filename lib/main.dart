import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: ShapeLogApp()));
}

class ShapeLogApp extends ConsumerWidget {
  const ShapeLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Shape.log',
      debugShowCheckedModeBanner: false,
      theme: appTheme.themeData,
      routerConfig: router,
    );
  }
}
