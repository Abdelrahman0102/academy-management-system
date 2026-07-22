// home_screen.dart
import 'package:flutter/material.dart';

/// Home Dashboard Screen for the Sports Academy Management System.
///
/// Displays a coach-facing overview: quick-access management cards,
/// a floating action button for creating new sessions, a navigation
/// drawer, and a summary of academy statistics.
///
/// This screen relies entirely on `Theme.of(context)` for styling
/// (see `light_theme.dart` / `dark_theme.dart` / `text_styles.dart`)
/// and does not hardcode colors or fonts.
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

  static const List<_DashboardItem> _dashboardItems = <_DashboardItem>[
    _DashboardItem(
      title: 'اللاعبين',
      subtitle: 'Manage player profiles',
      icon: Icons.sports_soccer_rounded,
      route: '/players',
    ),
    _DashboardItem(
      title: 'المجموعات',
      subtitle: 'Organize training groups',
      icon: Icons.groups_rounded,
      route: '/groups',
    ),
    _DashboardItem(
      title: 'التدريبات',
      subtitle: 'Plan training sessions',
      icon: Icons.event_note_rounded,
      route: '/sessions',
    ),
    _DashboardItem(
      title: 'الغياب',
      subtitle: 'Track daily attendance',
      icon: Icons.fact_check_rounded,
      route: '/attendance',
    ),
    _DashboardItem(
      title: 'تقييم اللاعبين',
      subtitle: 'Assess player progress',
      icon: Icons.insights_rounded,
      route: '/evaluations',
    ),
    _DashboardItem(
      title: 'المدربين',
      subtitle: 'Manage coaching staff',
      icon: Icons.badge_rounded,
      route: '/coaches',
    ),
    _DashboardItem(
      title: 'التقارير',
      subtitle: 'View academy reports',
      icon: Icons.bar_chart_rounded,
      route: '/reports',
    ),
    _DashboardItem(
      title: 'الاعدادات',
      subtitle: 'Configure preferences',
      icon: Icons.settings_rounded,
      route: '/settings',
    ),
  ];

  static const List<_StatItem> _statItems = <_StatItem>[
    _StatItem(
      label: 'Total Players',
      value: '128',
      icon: Icons.sports_soccer_rounded,
    ),
    _StatItem(
      label: "Today's Attendance",
      value: '92%',
      icon: Icons.fact_check_rounded,
    ),
    _StatItem(
      label: 'Active Groups',
      value: '14',
      icon: Icons.groups_rounded,
    ),
    _StatItem(
      label: 'Completed Sessions',
      value: '256',
      icon: Icons.event_available_rounded,
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
    final bool isLandscape = size.width > size.height;
    final int crossAxisCount = isTablet ? (isLandscape ? 4 : 3) : 2;

    return Scaffold(
      appBar: _HomeAppBar(coachInitial: _coachInitial),
      drawer: const _HomeDrawer(
        currentRoute: HomeScreen.routeName,
        coachName: 'Coach $_coachName',
        coachRole: _coachRole,
        coachInitial: _coachInitial,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/sessions/create'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: <Widget>[
              const SliverToBoxAdapter(
                child: _DashboardHeader(coachName: _coachName),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                      return _DashboardCard(item: _dashboardItems[index]);
                    },
                    childCount: _dashboardItems.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _StatisticsSection(
                  items: _statItems,
                  crossAxisCount: isTablet ? 4 : 2,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Transparent, unelevated Material 3 app bar with menu, title,
/// notifications and a tappable coach avatar.
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar({required this.coachInitial});

  final String coachInitial;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: Text(
        'Sports Academy',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
          icon: Badge(
            smallSize: 8,
            backgroundColor: theme.colorScheme.error,
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
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  coachInitial,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
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

/// Large greeting header shown above the dashboard grid.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.coachName});

  final String coachName;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Welcome Back,',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Coach $coachName',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage your academy efficiently.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Immutable description of a single dashboard destination.
class _DashboardItem {
  const _DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

/// A single tappable dashboard card with a scale-down press animation
/// and Material ripple feedback. Navigates via [Navigator.pushNamed].
class _DashboardCard extends StatefulWidget {
  const _DashboardCard({required this.item});

  final _DashboardItem item;

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
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

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, widget.item.route),
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          splashColor: colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: colorScheme.primary.withValues(alpha: 0.04),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    widget.item.icon,
                    size: 26,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

/// Immutable description of a single academy statistic.
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

/// "Academy Overview" section: a responsive grid of small stat cards.
class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection({
    required this.items,
    required this.crossAxisCount,
  });

  final List<_StatItem> items;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Academy Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.9,
            ),
            itemBuilder: (BuildContext context, int index) {
              return _StatCard(item: items[index]);
            },
          ),
        ],
      ),
    );
  }
}

/// Small statistic card showing an icon, a value and a label.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.secondaryContainer,
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
          ),
        ],
      ),
    );
  }
}

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
  });

  final String currentRoute;
  final String coachName;
  final String coachRole;
  final String coachInitial;

  static const List<_DrawerItem> _items = <_DrawerItem>[
    _DrawerItem(icon: Icons.home_rounded, label: 'Home', route: '/home'),
    _DrawerItem(
      icon: Icons.sports_soccer_rounded,
      label: 'Players',
      route: '/players',
    ),
    _DrawerItem(
      icon: Icons.groups_rounded,
      label: 'Groups',
      route: '/groups',
    ),
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
                itemCount: _items.length,
                itemBuilder: (BuildContext context, int index) {
                  final _DrawerItem item = _items[index];
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
