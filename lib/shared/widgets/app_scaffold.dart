import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

/// Replica del layout nav del original Nuxt (default.vue):
/// - Mobile: top bar + bottom nav con 5 items (Inicio, Ejercicios, Nutrición, Cuerpo, Salud, Ajustes)
/// - Desktop: sidebar colapsable a la izquierda
class AppScaffold extends StatefulWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _sidebarCollapsed = false;

  static const _navItems = [
    _NavItem(path: '/dashboard', label: 'Inicio', icon: Icons.home_outlined, activeIcon: Icons.home),
    _NavItem(path: '/workout', label: 'Ejercicios', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
    _NavItem(path: '/nutrition', label: 'Nutrición', icon: Icons.restaurant_outlined, activeIcon: Icons.restaurant),
    _NavItem(path: '/body', label: 'Cuerpo', icon: Icons.accessibility_new_outlined, activeIcon: Icons.accessibility_new),
    _NavItem(path: '/health', label: 'Salud', icon: Icons.monitor_heart_outlined, activeIcon: Icons.monitor_heart),
    _NavItem(path: '/settings', label: 'Ajustes', icon: Icons.settings_outlined, activeIcon: Icons.settings),
  ];

  int _currentIndex(String location) {
    if (location.startsWith('/workout')) return 1;
    if (location.startsWith('/nutrition')) return 2;
    if (location.startsWith('/body')) return 3;
    if (location.startsWith('/health')) return 4;
    if (location.startsWith('/settings')) return 5;
    return 0;
  }

  bool _isActive(String path, String location) {
    if (path == '/dashboard') return location == '/dashboard' || location == '/';
    return location.startsWith(path);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    if (isDesktop) {
      return _buildDesktop(location);
    }
    return _buildMobile(location);
  }

  Widget _buildDesktop(String location) {
    final sidebarW = _sidebarCollapsed ? 64.0 : 240.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: sidebarW,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.background,
                  Color(0xFF0D110D), // via primary/5
                  Color(0xFF0E0A0E), // to pink-500/10
                ],
              ),
              border: Border(right: BorderSide(color: AppTheme.border, width: 0.5)),
            ),
            child: Column(
              children: [
                // Logo
                InkWell(
                  onTap: () => GoRouter.of(context).go('/dashboard'),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.show_chart,
                              color: AppTheme.primary, size: 16),
                        ),
                        if (!_sidebarCollapsed) ...[
                          const SizedBox(width: 12),
                          const Text(
                            'Shadow Health',
                            style: TextStyle(
                              color: AppTheme.foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Nav items
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Column(
                      children: _navItems.map((item) {
                        final active = _isActive(item.path, location);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _SidebarItem(
                            item: item,
                            active: active,
                            collapsed: _sidebarCollapsed,
                            onTap: () => GoRouter.of(context).go(item.path),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Collapse toggle
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () =>
                        setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.18)),
                      ),
                      child: Icon(
                        _sidebarCollapsed
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(String location) {
    final idx = _currentIndex(location);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Mobile top bar
          Container(
            color: AppTheme.background,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.show_chart,
                          color: AppTheme.primary, size: 14),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Shadow Health',
                      style: TextStyle(
                        color: AppTheme.foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(location, idx),
    );
  }

  Widget _buildBottomNav(String location, int idx) {
    // Show only core 5 items on mobile (Inicio, Ejercicios, Nutrición, Cuerpo, Salud)
    // Settings goes inside somewhere else or as last item
    final mobileItems = _navItems.take(6).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: mobileItems.map((item) {
              final active = _isActive(item.path, location);
              return Expanded(
                child: _BottomNavItem(
                  item: item,
                  active: active,
                  onTap: () => GoRouter.of(context).go(item.path),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Sidebar Item (Desktop) ────────────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 0 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppTheme.primary.withOpacity(0.2)
                : Colors.transparent,
          ),
          gradient: active
              ? LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.15),
                    AppTheme.primary.withOpacity(0.08),
                  ],
                )
              : null,
        ),
        child: Row(
          children: [
            if (collapsed)
              Center(
                child: Icon(
                  active ? item.activeIcon : item.icon,
                  color: active ? AppTheme.primary : AppTheme.mutedForeground,
                  size: 20,
                ),
              )
            else ...[
              Icon(
                active ? item.activeIcon : item.icon,
                color: active ? AppTheme.primary : AppTheme.mutedForeground,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: active
                        ? AppTheme.primary
                        : AppTheme.mutedForeground,
                    fontSize: 14,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (active)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Bottom Nav Item (Mobile) ──────────────────────────────────────────────────
class _BottomNavItem extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            active ? item.activeIcon : item.icon,
            color: active ? AppTheme.primary : AppTheme.mutedForeground,
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              color: active ? AppTheme.primary : AppTheme.mutedForeground,
              fontSize: 10,
              fontWeight:
                  active ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────
class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
