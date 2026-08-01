// group_details_screen.dart
import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../repositories/coach_repository.dart';
import '../../repositories/group_repository.dart';
import 'edit_group_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({
    required this.repository,
    required this.groupId,
    this.initialGroup,
    this.coachRepository,
    super.key,
  });

  final GroupRepository repository;
  final int groupId;
  final TrainingGroupModel? initialGroup;
  final CoachRepository? coachRepository;

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  TrainingGroupModel? _group;
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _group = widget.initialGroup;
    _isLoading = widget.initialGroup == null;
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    if (_group == null && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final TrainingGroupModel group =
      await widget.repository.getGroup(widget.groupId);

      if (!mounted) return;

      setState(() {
        _group = group;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _openEdit() async {
    final TrainingGroupModel? group = _group;
    if (group == null) return;

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

    if (updated == true) await _loadGroup();
  }

  Future<void> _deleteGroup() async {
    final TrainingGroupModel? group = _group;
    if (group == null || _isDeleting) return;

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

      Navigator.of(context).pop(true);
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

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final TrainingGroupModel? group = _group;

    if (_isLoading && group == null) {
      return const _DetailsSkeleton();
    }

    if (group == null) {
      return _DetailsError(
        message: _errorMessage ?? 'The group could not be loaded.',
        onRetry: _loadGroup,
      );
    }

    final ThemeData theme = Theme.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final double horizontalPadding =
    size.shortestSide >= 600 ? 32 : 16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit Group',
            onPressed: _isDeleting ? null : _openEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: RefreshIndicator(
              onRefresh: _loadGroup,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  32,
                ),
                children: <Widget>[
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MaterialBanner(
                        content: Text(_errorMessage!),
                        actions: <Widget>[
                          TextButton(
                            onPressed: _loadGroup,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  _HeaderCard(group: group),
                  const SizedBox(height: 16),
                  _CapacityCard(group: group),
                  const SizedBox(height: 16),
                  _ScheduleCard(group: group),
                  const SizedBox(height: 16),
                  _InfoCard(group: group),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _isDeleting ? null : _openEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit Group'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isDeleting ? null : _deleteGroup,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    icon: _isDeleting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.delete_rounded),
                    label: Text(
                      _isDeleting ? 'Deleting...' : 'Delete Group',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.group});

  final TrainingGroupModel group;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color statusColor = group.isFull ? scheme.error : scheme.primary;
    final String status = group.isFull
        ? 'Full'
        : group.availablePlaces != null
        ? '${group.availablePlaces} Places Available'
        : 'Open Group';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary,
            ),
            child: Icon(
              Icons.groups_rounded,
              color: scheme.onPrimary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  group.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  group.level ?? 'No level specified',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer
                        .withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _HeaderChip(
                      icon: Icons.sports_rounded,
                      label: group.coachName ?? 'Coach not available',
                    ),
                    _HeaderChip(
                      icon: Icons.circle_rounded,
                      label: status,
                      color: statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color effective = color ?? scheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effective.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: effective),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: effective,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  const _CapacityCard({required this.group});

  final TrainingGroupModel group;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return _DetailsCard(
      title: 'Capacity',
      subtitle: 'Current active players and available places.',
      icon: Icons.people_alt_rounded,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _Metric(
                  label: 'Current Players',
                  value: '${group.safePlayersCount}',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Maximum',
                  value: group.maxPlayers?.toString() ?? 'No limit',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Available',
                  value: group.availablePlaces?.toString() ?? 'Unlimited',
                ),
              ),
            ],
          ),
          if (group.hasCapacityLimit) ...<Widget>[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: group.capacityPercentage,
                minHeight: 8,
                backgroundColor:
                scheme.primary.withValues(alpha: 0.12),
                color: group.isFull ? scheme.error : scheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.group});

  final TrainingGroupModel group;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final List<GroupScheduleModel> schedules =
    List<GroupScheduleModel>.from(group.schedules)
      ..sort((GroupScheduleModel a, GroupScheduleModel b) {
        final int day = a.dayNumber.compareTo(b.dayNumber);
        return day != 0 ? day : a.startTime.compareTo(b.startTime);
      });

    return _DetailsCard(
      title: 'Training Schedule',
      subtitle: 'Weekly training days and times.',
      icon: Icons.schedule_rounded,
      child: schedules.isNotEmpty
          ? Column(
        children: List<Widget>.generate(
          schedules.length,
              (int index) {
            final GroupScheduleModel item = schedules[index];

            return Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.dayOfWeek,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${item.startTime}–${item.endTime}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (index != schedules.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      height: 1,
                      color: scheme.outlineVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
              ],
            );
          },
        ),
      )
          : Text(
        group.schedule?.trim().isNotEmpty == true
            ? group.schedule!
            : 'No training schedule is available.',
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.group});

  final TrainingGroupModel group;

  @override
  Widget build(BuildContext context) {
    return _DetailsCard(
      title: 'Group Information',
      subtitle: 'System and schedule information.',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: <Widget>[
          _InfoRow(label: 'Group ID', value: group.id.toString()),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Created At',
            value: group.createdAt ?? 'Not available',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Structured Schedule',
            value:
            group.hasStructuredSchedule ? 'Available' : 'Not configured',
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      children: <Widget>[
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color block = scheme.onSurface.withValues(alpha: 0.06);

    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: List<Widget>.generate(
              4,
                  (int index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  height: index == 0 ? 150 : 180,
                  decoration: BoxDecoration(
                    color: block,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: scheme.error,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

