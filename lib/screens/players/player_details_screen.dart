// player_details_screen.dart
import 'package:flutter/material.dart';

import 'edit_player_screen.dart';

/// Player Details screen for the Sports Academy Management System.
///
/// Read-only profile view opened from `PlayersScreen` after selecting a
/// player and pressing "Player Details". Displays basic info, parent
/// info, training info, latest evaluation, and quick statistics, plus
/// two bottom actions (Call Parent — UI only, Edit Player — navigates
/// to `EditPlayerScreen`).
///
/// TODO(api): this screen currently seeds its view with dummy data via
/// [_loadDummyPlayer]. Once `PlayersScreen` passes the selected player
/// (or its id) through navigation, replace that seed with the real
/// values / a `GET /players/{id}` fetch, and use [_isLoading] /
/// [_ProfileSkeleton] to show the fetch's loading state.
///
/// Styling comes entirely from `Theme.of(context)`; no colors or fonts
/// are hardcoded. This screen has no forms, no editable fields, and no
/// save actions.
class PlayerDetailsScreen extends StatefulWidget {
  const PlayerDetailsScreen({super.key, this.playerId});

  static const String routeName = '/players/details';

  /// Id of the player being viewed. Optional for now — wire this in
  /// once `PlayersScreen` passes the selected player through.
  final String? playerId;

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // TODO(api): set this from a real GET /players/{id} call and flip it
  // back to false once the response arrives. Kept false here since the
  // dummy data is available synchronously.
  final bool _isLoading = false;

  late final _PlayerDetails _player;

  @override
  void initState() {
    super.initState();
   // _player = _loadDummyPlayer(widget.playerId);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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

  /// Dummy player data standing in for the selected player until
  /// `PlayersScreen` passes real data through navigation.
  // _PlayerDetails _loadDummyPlayer(String? playerId) {
  //   return const _PlayerDetails(
  //     id: 'p1',
  //     name: 'Youssef Hassan',
  //     age: 13,
  //     group: 'U14 - Falcons',
  //     schedule: 'Sat / Mon / Wed - Morning',
  //     status: _PlayerStatus.active,
  //     photoUrl: null,
  //     registrationDate: '02 Sep 2024',
  //     parentName: 'Hassan Ibrahim',
  //     parentPhone: '01012345678',
  //     coachName: 'Coach Ahmed',
  //     attendance: 0.92,
  //     sessionsAttended: 46,
  //     sessionsMissed: 4,
  //     totalEvaluations: 6,
  //     evaluationRating: 4.8,
  //     latestCoachNote: 'Excellent discipline and improving every week.',
  //   );
  // }

  Future<void> _openEditPlayer() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => EditPlayerScreen(playerId: _player.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final bool isTablet = size.shortestSide >= 600;
    final double horizontalPadding = isTablet ? 32 : 20;
    final double maxContentWidth = isTablet ? 640 : double.infinity;
    final int statsCrossAxisCount = isTablet ? 4 : 2;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Player Details'),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _isLoading
              ? const _ProfileSkeleton()
              : Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                    BoxConstraints(maxWidth: maxContentWidth),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        24,
                      ),
                      children: <Widget>[
                        _ProfileHeader(player: _player),
                        const SizedBox(height: 20),
                        _SectionCard(
                          icon: Icons.assignment_ind_rounded,
                          title: 'Basic Information',
                          children: <Widget>[
                            _InfoRow(
                              label: 'Player Name',
                              value: _player.name,
                            ),
                            _InfoRow(
                              label: 'Age',
                              value: '${_player.age} years',
                            ),
                            _InfoRow(
                              label: 'Training Group',
                              value: _player.group,
                            ),
                            _InfoRow(
                              label: 'Training Schedule',
                              value: _player.schedule,
                            ),
                            _InfoRow(
                              label: 'Registration Date',
                              value: _player.registrationDate,
                            ),
                            _InfoRow(
                              label: 'Player ID',
                              value: _player.id,
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          icon: Icons.family_restroom_rounded,
                          title: 'Parent Information',
                          children: <Widget>[
                            _InfoRow(
                              label: 'Parent Name',
                              value: _player.parentName,
                            ),
                            _InfoRow(
                              label: 'Parent Phone',
                              value: _player.parentPhone,
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          icon: Icons.sports_soccer_rounded,
                          title: 'Training Information',
                          children: <Widget>[
                            _InfoRow(
                              label: 'Training Group',
                              value: _player.group,
                            ),
                            _InfoRow(
                              label: 'Training Schedule',
                              value: _player.schedule,
                            ),
                            _InfoRow(
                              label: 'Coach Name',
                              value: _player.coachName,
                            ),
                            const SizedBox(height: 12),
                            _AttendanceIndicator(
                              attendance: _player.attendance,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _EvaluationCard(player: _player),
                        const SizedBox(height: 16),
                        _QuickStatsSection(
                          player: _player,
                          crossAxisCount: statsCrossAxisCount,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              _DetailsBottomBar(
                player: _player,
                onEdit: _openEditPlayer,
                maxContentWidth: maxContentWidth,
                horizontalPadding: horizontalPadding,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data shape
// ---------------------------------------------------------------------------

enum _PlayerStatus { active, inactive, injured }

extension _PlayerStatusLabel on _PlayerStatus {
  String get label {
    switch (this) {
      case _PlayerStatus.active:
        return 'Active';
      case _PlayerStatus.inactive:
        return 'Inactive';
      case _PlayerStatus.injured:
        return 'Injured';
    }
  }
}

/// Read-only player profile shape used to populate this screen. Field
/// names are kept close to what `GET /players/{id}` is expected to
/// return so wiring the real API later only touches
/// [_PlayerDetailsScreenState._loadDummyPlayer].
class _PlayerDetails {
  const _PlayerDetails({
    required this.id,
    required this.name,
    required this.age,
    required this.group,
    required this.schedule,
    required this.status,
    required this.photoUrl,
    required this.registrationDate,
    required this.parentName,
    required this.parentPhone,
    required this.coachName,
    required this.attendance,
    required this.sessionsAttended,
    required this.sessionsMissed,
    required this.totalEvaluations,
    required this.evaluationRating,
    required this.latestCoachNote,
  });

  final String id;
  final String name;
  final int age;
  final String group;
  final String schedule;
  final _PlayerStatus status;
  final String? photoUrl;
  final String registrationDate;
  final String parentName;
  final String parentPhone;
  final String coachName;
  final double attendance;
  final int sessionsAttended;
  final int sessionsMissed;
  final int totalEvaluations;
  final double evaluationRating;
  final String latestCoachNote;

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

/// Profile header: large avatar (Hero-animated), name, group, age and
/// a status badge.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.player});

  final _PlayerDetails player;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        children: <Widget>[
          Hero(
            tag: 'player_avatar_${player.id}',
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
                image: player.photoUrl != null
                    ? DecorationImage(
                  image: NetworkImage(player.photoUrl!),
                  fit: BoxFit.cover,
                )
                    : null,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: player.photoUrl == null
                  ? Text(
                player.initial,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            player.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${player.group} • ${player.age} yrs',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          _StatusBadge(status: player.status),
        ],
      ),
    );
  }
}

/// Pill showing the player's current status.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _PlayerStatus status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Color color;
    switch (status) {
      case _PlayerStatus.active:
        color = colorScheme.primary;
        break;
      case _PlayerStatus.inactive:
        color = colorScheme.onSurfaceVariant;
        break;
      case _PlayerStatus.injured:
        color = colorScheme.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card + info row
// ---------------------------------------------------------------------------

/// A rounded, softly-shadowed card wrapping one info section, with an
/// icon + title header.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(icon, size: 16, color: colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

/// A single read-only label/value row inside a section card.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Attendance indicator
// ---------------------------------------------------------------------------

/// Modern linear progress bar with the attendance percentage displayed
/// beside it.
class _AttendanceIndicator extends StatelessWidget {
  const _AttendanceIndicator({required this.attendance});

  final double attendance;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Text(
          'Attendance',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: attendance.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(attendance * 100).round()}%',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Evaluation
// ---------------------------------------------------------------------------

/// Highlighted card showing the overall rating (stars + numeric score)
/// and the latest coach note.
class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.player});

  final _PlayerDetails player;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final int fullStars = player.evaluationRating.floor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.16),
                ),
                child: Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Latest Evaluation',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Row(
                children: List<Widget>.generate(5, (int index) {
                  return Icon(
                    index < fullStars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  );
                }),
              ),
              const SizedBox(width: 10),
              Text(
                '${player.evaluationRating.toStringAsFixed(1)} / 5',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${player.latestCoachNote}"',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick statistics
// ---------------------------------------------------------------------------

/// "Quick Statistics" title plus a responsive grid of stat cards.
class _QuickStatsSection extends StatelessWidget {
  const _QuickStatsSection({
    required this.player,
    required this.crossAxisCount,
  });

  final _PlayerDetails player;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final List<_StatEntry> stats = <_StatEntry>[
      _StatEntry(
        label: 'Attendance',
        value: '${(player.attendance * 100).round()}%',
        icon: Icons.fact_check_rounded,
      ),
      _StatEntry(
        label: 'Sessions Attended',
        value: '${player.sessionsAttended}',
        icon: Icons.event_available_rounded,
      ),
      _StatEntry(
        label: 'Missed Sessions',
        value: '${player.sessionsMissed}',
        icon: Icons.event_busy_rounded,
      ),
      _StatEntry(
        label: 'Total Evaluations',
        value: '${player.totalEvaluations}',
        icon: Icons.insights_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Quick Statistics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (BuildContext context, int index) {
            return _StatCard(entry: stats[index]);
          },
        ),
      ],
    );
  }
}

class _StatEntry {
  const _StatEntry({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

/// A single quick-statistic tile: icon, large value, small label.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.entry});

  final _StatEntry entry;

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
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(entry.icon, size: 17, color: colorScheme.primary),
          ),
          const SizedBox(height: 10),
          Text(
            entry.value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            entry.label,
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
// Bottom actions
// ---------------------------------------------------------------------------

/// "Call Parent" (UI only) and "Edit Player" (navigates to
/// `EditPlayerScreen`) actions, pinned to the bottom.
class _DetailsBottomBar extends StatelessWidget {
  const _DetailsBottomBar({
    required this.player,
    required this.onEdit,
    required this.maxContentWidth,
    required this.horizontalPadding,
  });

  final _PlayerDetails player;
  final VoidCallback onEdit;
  final double maxContentWidth;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding,
                14,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO(feature): initiate a phone call to
                          // player.parentPhone once calling is wired in.
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          side: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Call Parent'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit Player'),
                      ),
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

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

/// Placeholder skeleton shown while the future `GET /players/{id}` call
/// is in flight.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color blockColor = colorScheme.onSurface.withValues(alpha: 0.06);

    Widget block({double width = double.infinity, double height = 16}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: blockColor,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    Widget card({required double height}) {
      return Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: <Widget>[
        Center(
          child: Column(
            children: <Widget>[
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blockColor,
                ),
              ),
              const SizedBox(height: 14),
              block(width: 160, height: 20),
              const SizedBox(height: 8),
              block(width: 120, height: 14),
            ],
          ),
        ),
        const SizedBox(height: 24),
        card(height: 160),
        const SizedBox(height: 16),
        card(height: 100),
        const SizedBox(height: 16),
        card(height: 140),
      ],
    );
  }
}