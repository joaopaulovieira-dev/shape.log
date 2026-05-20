import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../../features/profile/presentation/providers/user_profile_provider.dart';

class WebScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const WebScaffold({super.key, required this.child});

  @override
  ConsumerState<WebScaffold> createState() => _WebScaffoldState();
}

class _WebScaffoldState extends ConsumerState<WebScaffold> {
  bool _collapsed = false;

  static const double _expandedWidth = 240;
  static const double _collapsedWidth = 64;

  (String, String) _pageInfo(String location) {
    if (location == '/') return ('Dashboard', 'Visão geral dos seus dados');
    if (location.startsWith('/workouts')) return ('Treinos', 'Gerencie suas rotinas de treino');
    if (location.startsWith('/body-tracker')) return ('Medidas Corporais', 'Acompanhe sua evolução física');
    if (location.startsWith('/reports')) return ('Relatórios', 'Análise de desempenho e histórico');
    if (location.startsWith('/settings')) return ('Configurações', 'Backup, perfil e preferências');
    return ('Shape.log', '');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final pageInfo = _pageInfo(location);

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Row(
        children: [
          // Sidebar animada
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: _collapsed ? _collapsedWidth : _expandedWidth,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(),
            child: _WebSidebar(
              currentLocation: location,
              collapsed: _collapsed,
              onToggle: () => setState(() => _collapsed = !_collapsed),
            ),
          ),
          Container(width: 1, color: Colors.white.withOpacity(0.06)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WebTopBar(
                  title: pageInfo.$1,
                  subtitle: pageInfo.$2,
                ),
                Container(height: 1, color: Colors.white.withOpacity(0.06)),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────────────────────

class _WebSidebar extends ConsumerWidget {
  final String currentLocation;
  final bool collapsed;
  final VoidCallback onToggle;

  const _WebSidebar({
    required this.currentLocation,
    required this.collapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.asData?.value;

    if (collapsed) {
      // Modo ícone-only
      return Container(
        color: const Color(0xFF0A0A0A),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Logo + botão expandir
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icon/logo_fundopreto.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Tooltip(
              message: 'Expandir menu',
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Divider(color: Colors.white.withOpacity(0.06), indent: 8, endIndent: 8),
            const SizedBox(height: 8),
            _IconNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, route: '/', isActive: currentLocation == '/'),
            _IconNavItem(icon: Icons.fitness_center_outlined, activeIcon: Icons.fitness_center, route: '/workouts', isActive: currentLocation.startsWith('/workouts')),
            _IconNavItem(icon: Icons.monitor_weight_outlined, activeIcon: Icons.monitor_weight, route: '/body-tracker', isActive: currentLocation.startsWith('/body-tracker')),
            _IconNavItem(icon: Icons.assessment_outlined, activeIcon: Icons.assessment, route: '/reports', isActive: currentLocation.startsWith('/reports')),
            const Spacer(),
            Divider(color: Colors.white.withOpacity(0.06), indent: 8, endIndent: 8),
            _IconNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, route: '/settings', isActive: currentLocation.startsWith('/settings')),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icon/logo_fundopreto.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: RichText(
                    overflow: TextOverflow.clip,
                    maxLines: 1,
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
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Recolher menu',
                  child: InkWell(
                    onTap: onToggle,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.chevron_left, color: Colors.white24, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(color: Colors.white.withOpacity(0.06)),
          ),
          const SizedBox(height: 8),

          // Label seção
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'NAVEGAÇÃO',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white24,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // Itens de navegação
          _NavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            route: '/',
            isActive: currentLocation == '/',
          ),
          _NavItem(
            icon: Icons.fitness_center_outlined,
            activeIcon: Icons.fitness_center,
            label: 'Treinos',
            route: '/workouts',
            isActive: currentLocation.startsWith('/workouts'),
          ),
          _NavItem(
            icon: Icons.monitor_weight_outlined,
            activeIcon: Icons.monitor_weight,
            label: 'Medidas',
            route: '/body-tracker',
            isActive: currentLocation.startsWith('/body-tracker'),
          ),
          _NavItem(
            icon: Icons.assessment_outlined,
            activeIcon: Icons.assessment,
            label: 'Relatórios',
            route: '/reports',
            isActive: currentLocation.startsWith('/reports'),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(color: Colors.white.withOpacity(0.06)),
          ),

          // Configurações
          _NavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Configurações',
            route: '/settings',
            isActive: currentLocation.startsWith('/settings'),
          ),

          const SizedBox(height: 8),

          // Perfil + logout
          _UserTile(profile: profile, ref: ref),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive
            ? AppColors.primary.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(route),
          hoverColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 18,
                  color: isActive ? AppColors.primary : Colors.white38,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? Colors.white : Colors.white54,
                    ),
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final dynamic profile;
  final WidgetRef ref;

  const _UserTile({required this.profile, required this.ref});

  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? 'Usuário';
    final picPath = profile?.profilePicturePath;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showLogoutMenu(context),
          hoverColor: Colors.white.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Avatar com fallback para iniciais em caso de erro (ex: 429)
                _Avatar(picPath: picPath, name: name),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Web Dashboard',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Sair',
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white38,
                    ),
                  ),
                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        title: Text(
          'Sair da conta',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Deseja encerrar a sessão?',
          style: GoogleFonts.outfit(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.outfit(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/welcome');
            },
            child: Text(
              'Sair',
              style: GoogleFonts.outfit(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ─────────────────────────────────────────────────────────────────

class _WebTopBar extends StatelessWidget {
  final String title;
  final String subtitle;

  const _WebTopBar({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFF0A0A0A),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
            ],
          ),
          const Spacer(),
          // Badge versão
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              'v1.2.0 · Web',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ícone de navegação compacto (sidebar recolhido) ─────────────────────────

class _IconNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final bool isActive;

  const _IconNavItem({
    required this.icon,
    required this.activeIcon,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Tooltip(
        message: route == '/'
            ? 'Dashboard'
            : route.startsWith('/workouts')
                ? 'Treinos'
                : route.startsWith('/body-tracker')
                    ? 'Medidas'
                    : route.startsWith('/reports')
                        ? 'Relatórios'
                        : 'Configurações',
        preferBelow: false,
        child: Material(
          color: isActive
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.go(route),
            hoverColor: Colors.white.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 20,
                color: isActive ? AppColors.primary : Colors.white38,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Avatar com fallback para iniciais ───────────────────────────────────────

class _Avatar extends StatefulWidget {
  final String? picPath;
  final String name;

  const _Avatar({required this.picPath, required this.name});

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> {
  bool _error = false;

  @override
  void didUpdateWidget(_Avatar old) {
    super.didUpdateWidget(old);
    if (old.picPath != widget.picPath) setState(() => _error = false);
  }

  Widget _fallback(String initial) => CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.primary.withOpacity(0.2),
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final initial =
        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'U';

    if (widget.picPath == null || _error) return _fallback(initial);

    return ClipOval(
      child: Image.network(
        widget.picPath!,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              if (mounted) setState(() => _error = true);
            },
          );
          return _fallback(initial);
        },
      ),
    );
  }
}
