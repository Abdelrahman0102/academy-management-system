// groups_screen.dart
import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../repositories/coach_repository.dart';
import '../../repositories/group_repository.dart';
import 'create_group_screen.dart';
import 'edit_group_screen.dart';
import 'group_details_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({
    required this.repository,
    this.coachRepository,
    super.key,
  });

  static const String routeName = '/groups';

  final GroupRepository repository;
  final CoachRepository? coachRepository;

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  List<TrainingGroupModel> _allGroups = <TrainingGroupModel>[];
  List<TrainingGroupModel> _visibleGroups = <TrainingGroupModel>[];

  bool _isLoading = true;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<TrainingGroupModel> groups =
      await widget.repository.getGroups();

      if (!mounted) return;

      final String query = _searchController.text.trim().toLowerCase();

      setState(() {
        _allGroups = groups;
        _visibleGroups = _filterGroups(groups, query);
        _isLoading = false;
      });

      _fadeController
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

  Future<void> _refreshGroups() async {
    try {
      final List<TrainingGroupModel> groups =
      await widget.repository.refresh();

      if (!mounted) return;

      final String query = _searchController.text.trim().toLowerCase();

      setState(() {
        _allGroups = groups;
        _visibleGroups = _filterGroups(groups, query);
        _errorMessage = null;
      });
    } catch (error) {
      if (mounted) _showError(error.toString());
    }
  }

  List<TrainingGroupModel> _filterGroups(
      List<TrainingGroupModel> groups,
      String query,
      ) {
    if (query.isEmpty) return List<TrainingGroupModel>.from(groups);

    return groups.where((TrainingGroupModel group) {
      return group.name.toLowerCase().contains(query) ||
          (group.level ?? '').toLowerCase().contains(query) ||
          (group.coachName ?? '').toLowerCase().contains(query) ||
          (group.schedule ?? '').toLowerCase().contains(query);
    }).toList(growable: false);
  }

  void _onSearchChanged(String value) {
    final String query = value.trim().toLowerCase();

    setState(() {
      _visibleGroups = _filterGroups(_allGroups, query);
    });
  }

  Future<void> _openCreate() async {
    final bool? created = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CreateGroupScreen(
          repository: widget.repository,
          coachRepository: widget.coachRepository,
        ),
      ),
    );

    if (created != true) return;

    await _loadGroups();

    if (mounted) _showMessage('Group created successfully.');
  }

  Future<void> _openDetails(TrainingGroupModel group) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => GroupDetailsScreen(
          repository: widget.repository,
          groupId: group.id,
          initialGroup: group,
          coachRepository: widget.coachRepository,
        ),
      ),
    );

    // Always refresh after returning because details may have edited
    // or deleted data before the user comes back.
    await _loadGroups();
  }

  Future<void> _openEdit(TrainingGroupModel group) async {
    final bool? updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => EditGroupScreen(
          repository: widget.repository,
          group: group,
          coachRepository: widget.coachRepository,
        ),
      ),
    );

    if (updated != true) return;

    await _loadGroups();

    if (mounted) _showMessage('Group updated successfully.');
  }

  Future<void> _delete(TrainingGroupModel group) async {
    if (_isDeleting) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ColorScheme scheme =
            Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text('Delete Group'),
          content: Text(
            'Delete "${group.name}"?\n\n'
                'A group containing active players cannot be deleted.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await widget.repository.deleteGroup(group.id);

      if (!mounted) return;

      await _loadGroups();

      if (mounted) _showMessage('Group deleted successfully.');
    } on GroupRepositoryException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
            const Text('Groups'),
            Text(
              'Manage Training Groups',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isDeleting ? null : _openCreate,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Group'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: <Widget>[
                _SearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                ),
                Expanded(
                  child: _isLoading
                      ? const _GroupsSkeleton()
                      : _errorMessage != null
                      ? _ErrorState(
                    message: _errorMessage!,
                    onRetry: _loadGroups,
                  )
                      : _visibleGroups.isEmpty
                      ? _EmptyState(onRefresh: _loadGroups)
                      : FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: _refreshGroups,
                      child: ListView.builder(
                        physics:
                        const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          96,
                        ),
                        itemCount: _visibleGroups.length,
                        itemBuilder:
                            (BuildContext context, int index) {
                          final TrainingGroupModel group =
                          _visibleGroups[index];

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: _GroupCard(
                              group: group,
                              onDetails: () =>
                                  _openDetails(group),
                              onEdit: () => _openEdit(group),
                              onDelete: () => _delete(group),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search by group, coach, level or schedule',
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
          fillColor: scheme.surfaceContainerLow,
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
            borderSide: BorderSide(
              color: scheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final TrainingGroupModel group;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer,
                      ),
                      child: Icon(
                        Icons.groups_rounded,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  group.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                  theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              _AvailabilityBadge(group: group),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            group.level ?? 'No level specified',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _InfoLine(
                            icon: Icons.sports_rounded,
                            text: group.coachName ?? 'Coach not available',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Capacity(group: group),
                if (group.schedules.isNotEmpty ||
                    (group.schedule?.trim().isNotEmpty ?? false)) ...<Widget>[
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 10),
                  _ScheduleSummary(group: group),
                ],
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.visibility_rounded,
                        label: 'Details',
                        onPressed: onDetails,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        onPressed: onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        onPressed: onDelete,
                        destructive: true,
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

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.group});

  final TrainingGroupModel group;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color color = group.isFull ? scheme.error : scheme.primary;
    final String label = group.isFull
        ? 'Full'
        : group.availablePlaces != null
        ? '${group.availablePlaces} available'
        : 'Open';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Capacity extends StatelessWidget {
  const _Capacity({required this.group});

  final TrainingGroupModel group;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String text = group.hasCapacityLimit
        ? '${group.safePlayersCount} / ${group.maxPlayers} Players'
        : '${group.safePlayersCount} Players';

    return Column(
      children: <Widget>[
        _InfoLine(
          icon: Icons.people_alt_rounded,
          text: text,
        ),
        if (group.hasCapacityLimit) ...<Widget>[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: group.capacityPercentage,
              minHeight: 6,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              color: group.isFull ? scheme.error : scheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _ScheduleSummary extends StatelessWidget {
  const _ScheduleSummary({required this.group});

  final TrainingGroupModel group;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (group.schedules.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: group.schedules
            .map(
              (GroupScheduleModel item) => Chip(
            avatar: Icon(
              Icons.schedule_rounded,
              size: 16,
              color: scheme.primary,
            ),
            label: Text(item.displayLabel),
          ),
        )
            .toList(growable: false),
      );
    }

    return _InfoLine(
      icon: Icons.schedule_rounded,
      text: group.schedule!,
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = destructive ? scheme.error : scheme.onSurface;

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: destructive
              ? scheme.error.withValues(alpha: 0.4)
              : scheme.outlineVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _GroupsSkeleton extends StatelessWidget {
  const _GroupsSkeleton();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color block = scheme.onSurface.withValues(alpha: 0.06);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 5,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 180,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: block,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 150,
                            height: 16,
                            decoration: BoxDecoration(
                              color: block,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 12,
                            decoration: BoxDecoration(
                              color: block,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: block,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 220,
                  height: 34,
                  decoration: BoxDecoration(
                    color: block,
                    borderRadius: BorderRadius.circular(14),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

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
                color: scheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 32,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Groups Found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Training groups you create will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

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
                color: scheme.error.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: scheme.error,
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
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

