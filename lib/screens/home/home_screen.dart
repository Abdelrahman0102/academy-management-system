// home_screen.dart
import 'package:flutter/material.dart';

import '/models/dashboard.dart';
import '/repositories/dashboard_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.dashboardRepository,
    this.apiBaseUrl =
    'https://turbo-app.com/api/sports_academy',
  });

  static const String routeName = '/home';

  /// Optional injection keeps existing tests and routing flexible.
  final DashboardRepository? dashboardRepository;

  /// Existing `const HomeScreen()` calls keep working without main.dart edits.
  final String apiBaseUrl;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final DashboardRepository _dashboardRepository;

  DashboardData? _dashboard;
  String? _dashboardError;
  bool _isLoadingDashboard = true;
  bool _ownsRepository = false;
  bool _isAdmin = false;

  static const List<_QuickAction> _quickActions =
  <_QuickAction>[
    _QuickAction(
      label: 'المدربين',
      icon: Icons.groups_rounded,
      route: '/coaches',
      adminOnly: true,
    ),
    _QuickAction(
      label: 'طلبات أولياء الأمور',
      icon: Icons.how_to_reg_rounded,
      route: '/parent-account-requests',
      adminOnly: true,
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

  static const List<_DrawerItem> _drawerItems =
  <_DrawerItem>[
    _DrawerItem(
      icon: Icons.home_rounded,
      label: 'Home',
      route: '/home',
    ),
    _DrawerItem(
      icon: Icons.how_to_reg_rounded,
      label: 'Parent Approvals',
      route: '/parent-account-requests',
      adminOnly: true,
    ),
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
    // _DrawerItem(
    //
    //   icon: Icons.settings_rounded,
    //   label: 'Settings',
    //   route: '/settings',
    //
    // ),
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

    _dashboardRepository =
        widget.dashboardRepository ??
            DashboardRepository(
              baseUrl: widget.apiBaseUrl,
            );
    _ownsRepository =
        widget.dashboardRepository == null;

    _fadeController.forward();
    _loadDashboard();
  }

  Future<void> _loadDashboard({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoadingDashboard = true;
        _dashboardError = null;
      });
    }

    try {
      final DashboardData dashboard =
      await _dashboardRepository.getDashboard();

      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _isAdmin = dashboard.user.isAdmin;
        _dashboardError = null;
        _isLoadingDashboard = false;
      });
    } on DashboardRepositoryException catch (error) {
      if (!mounted) return;

      setState(() {
        _dashboardError = error.message;
        _isLoadingDashboard = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _dashboardError =
        'Unable to load dashboard: $error';
        _isLoadingDashboard = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();

    if (_ownsRepository) {
      _dashboardRepository.dispose();
    }

    super.dispose();
  }

  String _attendanceText(double? percentage) {
    if (percentage == null) {
      return '—';
    }

    final bool isWhole =
        percentage == percentage.roundToDouble();

    return '${percentage.toStringAsFixed(isWhole ? 0 : 1)}%';
  }

  List<_StatItem> _overviewStats() {
    final DashboardOverview? overview =
        _dashboard?.overview;

    return <_StatItem>[
      _StatItem(
        label: 'Players',
        value: _isLoadingDashboard
            ? '—'
            : '${overview?.players ?? 0}',
        icon: Icons.groups_rounded,
      ),
      _StatItem(
        label: 'Sessions',
        value: _isLoadingDashboard
            ? '—'
            : '${overview?.sessions ?? 0}',
        icon: Icons.event_note_rounded,
      ),
      _StatItem(
        label: 'Attendance',
        value: _isLoadingDashboard
            ? '—'
            : _attendanceText(
          overview?.attendancePercentage,
        ),
        icon: Icons.fact_check_rounded,
      ),
      _StatItem(
        label: 'Evaluations',
        value: _isLoadingDashboard
            ? '—'
            : '${overview?.evaluations ?? 0}',
        icon: Icons.insights_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final bool isTablet =
        size.shortestSide >= 600;
    final bool isVeryNarrow =
        size.width < 340;

    final int overviewCrossAxisCount =
    isTablet ? 4 : isVeryNarrow ? 1 : 2;
    final int actionsCrossAxisCount =
    isTablet ? 3 : 2;

    final DashboardUser? user = _dashboard?.user;
    final String fullName =
        user?.fullName ?? 'User';
    final String initial =
        user?.initial ?? 'U';
    final String roleLabel = user?.roleLabel ??
        (_isAdmin ? 'Administrator' : 'Coach');

    final List<_QuickAction> visibleQuickActions =
    _quickActions
        .where(
          (_QuickAction action) =>
      !action.adminOnly || _isAdmin,
    )
        .toList(growable: false);

    final List<_DrawerItem> visibleDrawerItems =
    _drawerItems
        .where(
          (_DrawerItem item) =>
      !item.adminOnly || _isAdmin,
    )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _HomeAppBar(
        userInitial: initial,
      ),
      drawer: _HomeDrawer(
        currentRoute: HomeScreen.routeName,
        userName: fullName,
        roleLabel: roleLabel,
        userInitial: initial,
        items: visibleDrawerItems,
      ),
      floatingActionButton: _HomeFab(
        onPressed: () => Navigator.pushNamed(
          context,
          '/sessions/create',
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () => _loadDashboard(
              showLoading: false,
            ),
            child: CustomScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: _GreetingSection(
                    fullName: fullName,
                    isAdmin: _isAdmin,
                    isLoading: _isLoadingDashboard,
                  ),
                ),
                if (_dashboardError != null)
                  SliverToBoxAdapter(
                    child: _DashboardErrorBanner(
                      message: _dashboardError!,
                      onRetry: () {
                        _loadDashboard();
                      },
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _OverviewCard(
                    items: _overviewStats(),
                    crossAxisCount:
                    overviewCrossAxisCount,
                    isTablet: isTablet,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _QuickActionsSection(
                    actions: visibleQuickActions,
                    crossAxisCount:
                    actionsCrossAxisCount,
                    isTablet: isTablet,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 96),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _HomeAppBar({
    required this.userInitial,
  });

  final String userInitial;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

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
            onPressed: () =>
                Scaffold.of(context).openDrawer(),
          );
        },
      ),
      actions: <Widget>[
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => Navigator.pushNamed(
            context,
            '/notifications',
          ),
          icon: Badge(
            smallSize: 8,
            backgroundColor: colorScheme.error,
            child: const Icon(
              Icons.notifications_none_rounded,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            right: 16,
          ),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/profile',
            ),
            child: Hero(
              tag: 'coach_avatar',
              child: CircleAvatar(
                radius: 18,
                backgroundColor:
                colorScheme.primaryContainer,
                child: Text(
                  userInitial,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(
                    color:
                    colorScheme.onPrimaryContainer,
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

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({
    required this.fullName,
    required this.isAdmin,
    required this.isLoading,
  });

  final String fullName;
  final bool isAdmin;
  final bool isLoading;

  static String _greetingForHour(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;
    final String greeting =
    _greetingForHour(DateTime.now().hour);
    final String titlePrefix =
    isAdmin ? 'Admin' : 'Coach';

    return Padding(
      padding:
      const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            greeting,
            style:
            theme.textTheme.bodyLarge?.copyWith(
              color:
              colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration:
            const Duration(milliseconds: 220),
            child: Text(
              isLoading
                  ? 'Loading your dashboard...'
                  : '$titlePrefix $fullName 👋',
              key: ValueKey<String>(
                '$isLoading-$fullName-$isAdmin',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Here's today's academy overview.",
            style:
            theme.textTheme.bodyMedium?.copyWith(
              color:
              colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorBanner
    extends StatelessWidget {
  const _DashboardErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
      const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Material(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            10,
            8,
            10,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                    colorScheme.onErrorContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.items,
    required this.crossAxisCount,
    required this.isTablet,
  });

  final List<_StatItem> items;
  final int crossAxisCount;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    return Padding(
      padding:
      const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
          colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colorScheme.shadow
                  .withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Today's Overview",
              style:
              theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,

                /*
                 * A fixed, generous tile height prevents the old
                 * "Bottom overflowed by 9 pixels" error on phones.
                 */
                mainAxisExtent: isTablet ? 92 : 104,
              ),
              itemBuilder:
                  (BuildContext context, int index) {
                return _OverviewStatTile(
                  item: items[index],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewStatTile extends StatelessWidget {
  const _OverviewStatTile({
    required this.item,
  });

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    return LayoutBuilder(
      builder: (
          BuildContext context,
          BoxConstraints constraints,
          ) {
        final bool useVertical =
            constraints.maxWidth < 150;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: useVertical ? 10 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary
                  .withValues(alpha: 0.16),
            ),
          ),
          child: useVertical
              ? _VerticalStatContent(
            item: item,
          )
              : _HorizontalStatContent(
            item: item,
          ),
        );
      },
    );
  }
}

class _VerticalStatContent extends StatelessWidget {
  const _VerticalStatContent({
    required this.item,
  });

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          item.icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.value,
              style:
              theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style:
          theme.textTheme.bodySmall?.copyWith(
            color:
            colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HorizontalStatContent
    extends StatelessWidget {
  const _HorizontalStatContent({
    required this.item,
  });

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.primary
                .withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.icon,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge
                    ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                theme.textTheme.bodySmall?.copyWith(
                  color:
                  colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
    this.isPrimary = false,
    this.adminOnly = false,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool isPrimary;
  final bool adminOnly;
}

class _QuickActionsSection
    extends StatelessWidget {
  const _QuickActionsSection({
    required this.actions,
    required this.crossAxisCount,
    required this.isTablet,
  });

  final List<_QuickAction> actions;
  final int crossAxisCount;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    return Padding(
      padding:
      const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
          colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colorScheme.shadow
                  .withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primary
                        .withValues(alpha: 0.12),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent:
                isTablet ? 128 : 124,
              ),
              itemBuilder:
                  (BuildContext context, int index) {
                return _QuickActionButton(
                  action: actions[index],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({
    required this.action,
  });

  final _QuickAction action;

  @override
  State<_QuickActionButton> createState() =>
      _QuickActionButtonState();
}

class _QuickActionButtonState
    extends State<_QuickActionButton>
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

    _scaleAnimation =
        Tween<double>(begin: 1, end: 0.96).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;
    final bool isPrimary =
        widget.action.isPrimary;

    final Color accentColor = colorScheme.primary;
    final Color foregroundColor = isPrimary
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final Color cardStart = isPrimary
        ? colorScheme.primary
        : colorScheme.surfaceContainerHigh;
    final Color cardEnd = isPrimary
        ? colorScheme.primary.withValues(alpha: 0.86)
        : colorScheme.surfaceContainerLow;
    final Color framedLabelColor = isPrimary
        ? colorScheme.onPrimary.withValues(alpha: 0.12)
        : accentColor.withValues(alpha: 0.09);
    final Color framedLabelBorder = isPrimary
        ? colorScheme.onPrimary.withValues(alpha: 0.34)
        : accentColor.withValues(alpha: 0.30);
    final Color iconBackground = isPrimary
        ? colorScheme.onPrimary.withValues(alpha: 0.16)
        : accentColor.withValues(alpha: 0.14);
    final Color iconColor = isPrimary
        ? colorScheme.onPrimary
        : accentColor;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (
          BuildContext context,
          Widget? child,
          ) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              cardStart,
              cardEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPrimary
                ? colorScheme.onPrimary
                .withValues(alpha: 0.22)
                : accentColor.withValues(alpha: 0.22),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: accentColor.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
            BoxShadow(
              color: colorScheme.shadow
                  .withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              widget.action.route,
            ),
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) => _controller.reverse(),
            onTapCancel: () => _controller.reverse(),
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: -24,
                  right: -22,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 10,
                        color: isPrimary
                            ? colorScheme.onPrimary
                            .withValues(alpha: 0.08)
                            : accentColor
                            .withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 10,
                  child: Icon(
                    Icons.sports_soccer_rounded,
                    size: 22,
                    color: isPrimary
                        ? colorScheme.onPrimary
                        .withValues(alpha: 0.12)
                        : accentColor
                        .withValues(alpha: 0.11),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(11),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: iconBackground,
                              borderRadius:
                              BorderRadius.circular(13),
                              border: Border.all(
                                color: isPrimary
                                    ? colorScheme.onPrimary
                                    .withValues(alpha: 0.22)
                                    : accentColor
                                    .withValues(alpha: 0.24),
                              ),
                            ),
                            child: Icon(
                              widget.action.icon,
                              size: 21,
                              color: iconColor,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 27,
                            height: 27,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPrimary
                                  ? colorScheme.onPrimary
                                  .withValues(alpha: 0.13)
                                  : accentColor
                                  .withValues(alpha: 0.10),
                            ),
                            child: Icon(
                              Icons.arrow_outward_rounded,
                              size: 15,
                              color: iconColor,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: framedLabelColor,
                          borderRadius:
                          BorderRadius.circular(11),
                          border: Border.all(
                            color: framedLabelBorder,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                widget.action.label,
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis,
                                style: theme
                                    .textTheme.titleSmall
                                    ?.copyWith(
                                  fontWeight:
                                  FontWeight.w800,
                                  color:
                                  foregroundColor,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 5,
                              height: 18,
                              decoration: BoxDecoration(
                                color: iconColor,
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _HomeFab extends StatelessWidget {
  const _HomeFab({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.primary
                .withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: colorScheme.primary,
        foregroundColor:
        colorScheme.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    this.adminOnly = false,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool adminOnly;
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({
    required this.currentRoute,
    required this.userName,
    required this.roleLabel,
    required this.userInitial,
    required this.items,
  });

  final String currentRoute;
  final String userName;
  final String roleLabel;
  final String userInitial;
  final List<_DrawerItem> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                20,
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                    colorScheme.primaryContainer,
                    child: Text(
                      userInitial,
                      style: theme
                          .textTheme.titleLarge
                          ?.copyWith(
                        color: colorScheme
                            .onPrimaryContainer,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          userName,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: theme
                              .textTheme.titleMedium
                              ?.copyWith(
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                        Text(
                          roleLabel,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: theme
                              .textTheme.bodySmall
                              ?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant,
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
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                itemCount: items.length,
                itemBuilder: (
                    BuildContext context,
                    int index,
                    ) {
                  final _DrawerItem item =
                  items[index];
                  final bool isSelected =
                      item.route == currentRoute;

                  return _DrawerTile(
                    item: item,
                    isSelected: isSelected,
                    onTap: () {
                      Navigator.pop(context);

                      if (!isSelected) {
                        Navigator.pushNamed(
                          context,
                          item.route,
                        );
                      }
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4,
              ),
              child: _DrawerTile(
                item: const _DrawerItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  route: '/settings',
                ),
                isSelected:
                currentRoute == '/settings',
                onTap: () {
                  Navigator.pop(context);

                  if (currentRoute != '/settings') {
                    Navigator.pushNamed(
                      context,
                      '/settings',
                    );
                  }
                },
              ),
            ),

            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
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
    final ColorScheme colorScheme =
        theme.colorScheme;

    final Color foregroundColor = isDestructive
        ? colorScheme.error
        : isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer
            .withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(14),
          ),
          leading: Icon(
            item.icon,
            color: foregroundColor,
          ),
          title: Text(
            item.label,
            style:
            theme.textTheme.bodyLarge?.copyWith(
              color: foregroundColor,
              fontWeight: isSelected
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
