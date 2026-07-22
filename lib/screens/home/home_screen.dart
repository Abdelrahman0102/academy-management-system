// home_screen.dart
import 'package:flutter/material.dart';

/// Coach Dashboard — Home screen for the Sports Academy Management System.
///
/// Layout order: transparent app bar -> greeting -> "Today's Overview"
/// stat grid -> "Quick Actions" grid -> floating action button.
///
/// Styling comes entirely from `Theme.of(context)` (see `light_theme.dart`
/// / `dark_theme.dart` / `text_styles.dart`). No colors or fonts are
/// hardcoded here. Routes, navigation, providers and architecture are
/// unchanged from the previous implementation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // Sample data shown until this screen is wired to the Coach provider.
  static const String _coachName = 'Ahmed';
  static const String _coachInitial = 'A';
  static const String _coachRole = 'Head Coach';

  static const List<_StatItem> _overviewStats = <_StatItem>[
    _StatItem(label: 'Players', value: '24', icon: Icons.groups_rounded),
    _StatItem(
      label: 'Sessions',
      value: '3',
      icon: Icons.event_note_rounded,
    ),
    _StatItem(
      label: 'Attendance',
      value: '92%',
      icon: Icons.fact_check_rounded,
    ),
    _StatItem(
      label: 'Evaluations',
      value: '4',
      icon: Icons.insights_rounded,
    ),
  ];

   static const List<_QuickAction> _quickActions = <_QuickAction>[
    _QuickAction(
      label: 'التدريب',
      icon: Icons.groups_rounded,
      route: '/attendance/qr-scan',

    ),
     _QuickAction(
       label: 'اللاعبين',
       icon: Icons.sports_soccer_rounded,
       route: '/players',
     ),
    _QuickAction(
      label: 'الحضور',
      icon: Icons.fact_check_rounded,
      route: '/attendance',
    ),
    _QuickAction(
      label: 'المجموعات',
      icon: Icons.groups_rounded,
      route: '/groups',
    ),
    _QuickAction(
      label: 'التقارير',
      icon: Icons.bar_chart_rounded,
      route: '/reports',
    ),
    _QuickAction(
      label: 'تقييم اللاعبين',
      icon: Icons.insights_rounded,
      route: '/evaluations',
    ),
  ];

  static const List<_DrawerItem> _drawerItems = <_DrawerItem>[
    _DrawerItem(icon: Icons.home_rounded, label: 'Home', route: '/home'),
    _DrawerItem(
      icon: Icons.sports_soccer_rounded,
      label: 'Players',
      route: '/players',
    ),
    _DrawerItem(icon: Icons.groups_rounded, label: 'Groups', route: '/groups'),
    _DrawerItem(
      icon: Icons.event_note_rounded,
      label: 'Sessions',
      route: '/sessions',
    ),
    _DrawerItem(
      icon: Icons.fact_check_rounded,
      label: 'Attendance',
      route: '/attendance',
    ),
    _DrawerItem(
      icon: Icons.insights_rounded,
      label: 'Evaluations',
      route: '/evaluations',
    ),
    _DrawerItem(
      icon: Icons.bar_chart_rounded,
      label: 'Reports',
      route: '/reports',
    ),
    _DrawerItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      route: '/profile',
    ),
    _DrawerItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final bool isTablet = size.shortestSide >= 600;
    final int overviewCrossAxisCount = isTablet ? 4 : 2;
    final int actionsCrossAxisCount = isTablet ? 3 : 2;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const _HomeAppBar(coachInitial: _coachInitial),
      drawer: const _HomeDrawer(
        currentRoute: HomeScreen.routeName,
        coachName: 'Coach $_coachName',
        coachRole: _coachRole,
        coachInitial: _coachInitial,
        items: _drawerItems,
      ),
      floatingActionButton: _HomeFab(
        onPressed: () => Navigator.pushNamed(context, '/sessions/create'),
      ),
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: <Widget>[
              const SliverToBoxAdapter(
                child: _GreetingSection(coachName: _coachName),
              ),
              SliverToBoxAdapter(
                child: _OverviewCard(
                  items: _overviewStats,
                  crossAxisCount: overviewCrossAxisCount,
                ),
              ),
              SliverToBoxAdapter(
                child: _QuickActionsSection(
                  actions: _quickActions,
                  crossAxisCount: actionsCrossAxisCount,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

/// Transparent, unelevated Material 3 app bar with a menu icon, a
/// notification icon and a small tappable coach avatar.
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar({required this.coachInitial});

  final String coachInitial;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 4,
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      actions: <Widget>[
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
          icon: Badge(
            smallSize: 8,
            backgroundColor: colorScheme.error,
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 16),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Hero(
              tag: 'coach_avatar',
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  coachInitial,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting
// ---------------------------------------------------------------------------

/// "Good Morning / Coach {name} 👋" greeting with a short subtitle.
class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.coachName});

  final String coachName;

  static String _greetingForHour(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String greeting = _greetingForHour(DateTime.now().hour);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            greeting,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coach $coachName 👋',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Here's today's academy overview.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today's overview
// ---------------------------------------------------------------------------

/// Immutable description of a single overview / quick-action statistic.
class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

/// Dark, rounded container holding a 2x2 grid of the day's key numbers.
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.items, required this.crossAxisCount});

  final List<_StatItem> items;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Today's Overview",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.5,
              ),
              itemBuilder: (BuildContext context, int index) {
                return _OverviewStatTile(item: items[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A single stat tile: small icon, large number, small label, with a
/// soft green highlight consistent with the primary accent color.
class _OverviewStatTile extends StatelessWidget {
  const _OverviewStatTile({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(item.icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            item.value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

/// Immutable description of a single quick-action button.
class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool isPrimary;
}

/// "Quick Actions" title plus a two-column grid of action buttons. The
/// first action ("Start QR") is highlighted in the primary green;
/// the rest use the surface color.
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.actions,
    required this.crossAxisCount,
  });

  final List<_QuickAction> actions;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (BuildContext context, int index) {
              return _QuickActionButton(action: actions[index]);
            },
          ),
        ],
      ),
    );
  }
}

/// A single quick-action button with an icon, a label, ripple feedback
/// and a subtle press-scale animation.
class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({required this.action});

  final _QuickAction action;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();

  void _onTapUp(TapUpDetails details) => _controller.reverse();

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isPrimary = widget.action.isPrimary;

    final Color backgroundColor =
    isPrimary ? colorScheme.primary : colorScheme.surfaceContainerLow;
    final Color foregroundColor =
    isPrimary ? colorScheme.onPrimary : colorScheme.onSurface;
    final Color iconBackground = isPrimary
        ? colorScheme.onPrimary.withValues(alpha: 0.16)
        : colorScheme.primary.withValues(alpha: 0.12);
    final Color iconColor =
    isPrimary ? colorScheme.onPrimary : colorScheme.primary;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, widget.action.route),
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          splashColor: foregroundColor.withValues(alpha: 0.1),
          highlightColor: foregroundColor.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBackground,
                  ),
                  child: Icon(widget.action.icon, size: 20, color: iconColor),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating action button
// ---------------------------------------------------------------------------

/// Circular, green, bottom-right FAB with a soft shadow.
class _HomeFab extends StatelessWidget {
  const _HomeFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drawer (unchanged navigation, restyled to match the theme)
// ---------------------------------------------------------------------------

/// Immutable description of a single drawer destination.
class _DrawerItem {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

/// Navigation drawer with a coach header, a list of destinations
/// (current page highlighted), and a logout action.
class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({
    required this.currentRoute,
    required this.coachName,
    required this.coachRole,
    required this.coachInitial,
    required this.items,
  });

  final String currentRoute;
  final String coachName;
  final String coachRole;
  final String coachInitial;
  final List<_DrawerItem> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      coachInitial,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          coachName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          coachRole,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  final _DrawerItem item = items[index];
                  final bool isSelected = item.route == currentRoute;
                  return _DrawerTile(
                    item: item,
                    isSelected: isSelected,
                    onTap: () {
                      Navigator.pop(context);
                      if (!isSelected) {
                        Navigator.pushNamed(context, item.route);
                      }
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _DrawerTile(
                item: const _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  route: '/logout',
                ),
                isSelected: false,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/logout',
                        (Route<dynamic> route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// A single row inside the drawer, styled to show a selected /
/// destructive (logout) state.
class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.isDestructive = false,
  });

  final _DrawerItem item;
  final bool isSelected;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Color foregroundColor = isDestructive
        ? colorScheme.error
        : isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: Icon(item.icon, color: foregroundColor),
          title: Text(
            item.label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: foregroundColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}