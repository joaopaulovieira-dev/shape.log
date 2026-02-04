import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Perfil'),
            subtitle: Text('Editar perfil'),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notificações'),
            subtitle: Text('Gerenciar notificações'),
          ),
        ],
      ),
    );
  }
}
