// coaches_screen.dart
import 'package:flutter/material.dart';

import '/models/coach.dart';
import '/repositories/coach_repository.dart';
import '/screens/coaches/add_coach_screen.dart';

// NOTE ON ASSUMPTIONS
// --------------------------------------------------------------------------
// Only coaches_screen.dart was requested, so this file assumes the
// following already exist elsewhere in the project, following the same
// conventions as PlayerModel / PlayerRepository:
//
//   class CoachModel {
//     final int id;
//     final String fullName;
//     final String phone;
//     final String specialization;
//     final String status; // 'active' | 'inactive'
//     final String? createdAt;
//   }
//
//   class CoachesRepository {
//     Future<List<CoachModel>> getCoaches();
//     Future<List<CoachModel>> searchCoaches(String query);
//     Future<List<CoachModel>> refresh();
//     Future<void> deleteCoach(int id);
//   }
//
// AddCoachScreen / CoachDetailsScreen / EditCoachScreen do not exist yet
// per the brief ("placeholder navigation only"), so this screen pushes a
// small in-file `_ComingSoonScreen` placeholder instead of importing
// screens that would break compilation. Swap the three `_open...`
// methods below over to real screens once they're built.

/// Admin-only screen for managing academy coaches.
///
/// Mirrors `PlayersScreen` — same search bar, pull-to-refresh, card
/// layout, selection-free per-card actions, loading skeleton style
/// borrowed from `PlayerDetailsScreen`, and empty/error states styled
/// to match. Coach users must never be routed to this screen; access
/// control is assumed to be handled before navigation, per the brief.
class CoachesScreen extends StatefulWidget {
  const CoachesScreen({
    super.key,
    required this.repository,
  });

  static const String routeName = '/coaches';

  final CoachRepository repository;

  @override
  State<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends State<CoachesScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final AnimationController _listFadeController;
  late final Animation<double> _listFadeAnimation;

  List<CoachModel> _allCoaches = <CoachModel>[];
  List<CoachModel> _filteredCoaches = <CoachModel>[];
  bool _isLoading = true;
  String? _errorMessage;

  CoachRepository get _repository => widget.repository;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _listFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _listFadeAnimation = CurvedAnimation(
      parent: _listFadeController,
      curve: Curves.easeOut,
    );

    _loadCoaches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listFadeController.dispose();
    super.dispose();
  }

  Future<void> _loadCoaches() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<CoachModel> coaches = await _repository.getCoaches();

      if (!mounted) return;

      final String query = _searchController.text.trim().toLowerCase();

      setState(() {
        _allCoaches = coaches;
        _filteredCoaches = _filterCoaches(coaches, query);
        _isLoading = false;
      });

      _listFadeController
        ..reset()
        ..forward();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _refreshCoaches() async {
    try {
      final List<CoachModel> coaches = await _repository.refresh();

      if (!mounted) return;

      final String query = _searchController.text.trim().toLowerCase();

      setState(() {
        _allCoaches = coaches;
        _filteredCoaches = _filterCoaches(coaches, query);
        _errorMessage = null;
      });
    } catch (error) {
      if (mounted) _showError(error.toString());
    }
  }

  List<CoachModel> _filterCoaches(
      List<CoachModel> coaches,
      String normalized,
      ) {
    if (normalized.isEmpty) return List<CoachModel>.from(coaches);

    return coaches.where((CoachModel coach) {
      return coach.fullName.toLowerCase().contains(normalized) ||
          coach.phone.contains(normalized) ||
          (coach.specialization ?? '').toLowerCase().contains(normalized);
    }).toList();
  }

  // Search filters the already-loaded list instantly, the same way
  // PlayersScreen does. `CoachesRepository.searchCoaches()` remains
  // available for a server-side search if the coach list grows large
  // enough that client-side filtering stops being practical.
  void _onSearchChanged(String query) {
    final String normalized = query.trim().toLowerCase();

    setState(() {
      _filteredCoaches = _filterCoaches(_allCoaches, normalized);
    });
  }

  Future<void> _openAddCoach() async {
    final bool? created = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => AddCoachScreen(
          repository: _repository,
        ),
      ),
    );

    if (created != true) return;

    await _loadCoaches();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Coach created successfully.'),
        ),
      );
  }

  Future<void> _openCoachDetails(CoachModel coach) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _ComingSoonScreen(title: 'Coach Details — ${coach.fullName}'),
      ),
    );
  }

  Future<void> _openEditCoach(CoachModel coach) async {
    final bool? updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => _ComingSoonScreen(title: 'Edit Coach — ${coach.fullName}'),
      ),
    );

    if (updated == true) {
      await _loadCoaches();
    }
  }

  Future<void> _confirmDeleteCoach(CoachModel coach) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Coach'),
          content: const Text('Are you sure you want to delete this coach?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteCoach(coach.id);
      if (!mounted) return;
      await _loadCoaches();
    } catch (error) {
      if (mounted) _showError(error.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final bool isTablet = size.shortestSide >= 600;
    final double horizontalPadding = isTablet ? 32 : 16;
    final double maxContentWidth = isTablet ? 720 : double.infinity;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Coaches'),
            Text(
              'Manage Academy Coaches',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCoach,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Coach'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: <Widget>[
                _CoachSearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                ),
                Expanded(
                  child: _isLoading
                      ? const _CoachesListSkeleton()
                      : _errorMessage != null
                      ? _CoachesErrorState(
                    message: _errorMessage!,
                    onRetry: _loadCoaches,
                  )
                      : _filteredCoaches.isEmpty
                      ? _EmptyCoachesState(onRefresh: _loadCoaches)
                      : FadeTransition(
                    opacity: _listFadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: _refreshCoaches,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          88,
                        ),
                        itemCount: _filteredCoaches.length,
                        itemBuilder:
                            (BuildContext context, int index) {
                          final CoachModel coach =
                          _filteredCoaches[index];
                          return Padding(
                            padding:
                            const EdgeInsets.only(bottom: 12),
                            child: _CoachCard(
                              coach: coach,
                              onDetails: () =>
                                  _openCoachDetails(coach),
                              onEdit: () => _openEditCoach(coach),
                              onDelete: () =>
                                  _confirmDeleteCoach(coach),
                            ),
                          );
                        },
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
}

// ---------------------------------------------------------------------------
// Search bar (identical styling to PlayersScreen's search field)
// ---------------------------------------------------------------------------

class _CoachSearchBar extends StatelessWidget {
  const _CoachSearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search by name, phone or specialization',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              controller.clear();
              onChanged('');
            },
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Coach card
// ---------------------------------------------------------------------------

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.coach,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final CoachModel coach;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onDetails,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _CoachAvatar(coach: coach),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  coach.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _CoachStatusBadge(status: coach.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            coach.specialization ?? '-',

                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.call_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                coach.phone,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (coach.createdAt != null) ...<Widget>[
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  coach.createdAt!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _CardActionButton(
                        icon: Icons.visibility_rounded,
                        label: 'Details',
                        onPressed: onDetails,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CardActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        onPressed: onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CardActionButton(
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        onPressed: onDelete,
                        isDestructive: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color color = isDestructive ? colorScheme.error : colorScheme.onSurface;

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: isDestructive
              ? colorScheme.error.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({required this.coach});

  final CoachModel coach;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String initial =
    coach.fullName.isEmpty ? '?' : coach.fullName[0].toUpperCase();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CoachStatusBadge extends StatelessWidget {
  const _CoachStatusBadge({required this.status});

  final String status;

  String _label() {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
      default:
        return 'Inactive';
    }
  }

  Color _color(ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'active':
        return colorScheme.primary;
      case 'inactive':
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color color = _color(colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton (same block/card skeleton language as
// PlayerDetailsScreen's _ProfileSkeleton, repeated as list rows)
// ---------------------------------------------------------------------------

class _CoachesListSkeleton extends StatelessWidget {
  const _CoachesListSkeleton();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color blockColor = colorScheme.onSurface.withValues(alpha: 0.06);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 6,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 96,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: blockColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 140,
                        height: 16,
                        decoration: BoxDecoration(
                          color: blockColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: blockColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyCoachesState extends StatelessWidget {
  const _EmptyCoachesState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.groups_2_rounded,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Coaches Found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Coaches you add will show up here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(color: colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _CoachesErrorState extends StatelessWidget {
  const _CoachesErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.error.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something Went Wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder destination for Add/Details/Edit until the real screens
// are built.
// ---------------------------------------------------------------------------

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title is coming soon.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
