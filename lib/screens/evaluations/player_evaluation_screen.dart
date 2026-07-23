// player_evaluation_screen.dart
import 'package:flutter/material.dart';

import 'evaluation_screen.dart';
import '/models/player.dart';
import '/repositories/player_repository.dart';

/// Player Evaluation entry screen for the Sports Academy Management
/// System.
///
/// Deliberately mirrors `PlayersScreen` — same AppBar, search bar,
/// player cards, loading/empty states and selection behaviour — so it
/// feels like it was built together with the rest of the Players
/// module. The only real difference is the bottom action: instead of
/// "Details" / "Edit" there is a single "Evaluate Player" button that
/// opens `EvaluationScreen` for the selected player.
class PlayerEvaluationScreen extends StatefulWidget {
  const PlayerEvaluationScreen({
    super.key,
    required this.repository,
  });

  static const String routeName = '/player-evaluation';

  final PlayerRepository repository;

  @override
  State<PlayerEvaluationScreen> createState() =>
      _PlayerEvaluationScreenState();
}

class _PlayerEvaluationScreenState extends State<PlayerEvaluationScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final AnimationController _listFadeController;
  late final Animation<double> _listFadeAnimation;

  List<PlayerModel> _allPlayers = <PlayerModel>[];
  List<PlayerModel> _filteredPlayers = <PlayerModel>[];
  int? _selectedPlayerId;
  bool _isLoading = true;

  PlayerRepository get _repository => widget.repository;

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

    _loadPlayers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listFadeController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final List<PlayerModel> players = await _repository.getPlayers();

      if (!mounted) return;

      final String query = _searchController.text.trim().toLowerCase();

      setState(() {
        _allPlayers = players;
        _filteredPlayers = _filterPlayers(players, query);
        _isLoading = false;

        if (_selectedPlayerId != null &&
            !_allPlayers.any((PlayerModel p) => p.id == _selectedPlayerId)) {
          _selectedPlayerId = null;
        }
      });

      _listFadeController
        ..reset()
        ..forward();
    } on PlayerRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(error.toString());
    }
  }

  List<PlayerModel> _filterPlayers(
      List<PlayerModel> players,
      String normalized,
      ) {
    if (normalized.isEmpty) return List<PlayerModel>.from(players);

    return players.where((PlayerModel player) {
      return player.name.toLowerCase().contains(normalized) ||
          player.code.toLowerCase().contains(normalized) ||
          (player.parentPhone ?? '').contains(normalized);
    }).toList();
  }

  void _onSearchChanged(String query) {
    final String normalized = query.trim().toLowerCase();

    setState(() {
      _filteredPlayers = _filterPlayers(_allPlayers, normalized);

      if (_selectedPlayerId != null &&
          !_filteredPlayers.any(
                (PlayerModel player) => player.id == _selectedPlayerId,
          )) {
        _selectedPlayerId = null;
      }
    });
  }

  void _onPlayerTap(PlayerModel player) {
    setState(() {
      _selectedPlayerId = _selectedPlayerId == player.id ? null : player.id;
    });
  }

  void _clearSelection() => setState(() => _selectedPlayerId = null);

  PlayerModel? get _selectedPlayer {
    if (_selectedPlayerId == null) return null;

    for (final PlayerModel player in _allPlayers) {
      if (player.id == _selectedPlayerId) return player;
    }

    return null;
  }

  Future<void> _openEvaluation(PlayerModel player) async {
    try {
      final PlayerModel detailedPlayer =
      await _repository.getPlayer(player.id);

      if (!mounted) return;

      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => EvaluationScreen(
            player: detailedPlayer,
            repository: _repository,
          ),
        ),
      );

      if (!mounted) return;
      _clearSelection();
      await _loadPlayers();
    } on PlayerRepositoryException catch (error) {
      if (mounted) _showError(error.message);
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
    final bool hasSelection = _selectedPlayer != null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Player Evaluation'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _EvalPlayerSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPlayers.isEmpty
                  ? const _EmptyEvalPlayersState()
                  : FadeTransition(
                opacity: _listFadeAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadPlayers,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      hasSelection ? 112 : 24,
                    ),
                    itemCount: _filteredPlayers.length,
                    itemBuilder: (BuildContext context, int index) {
                      final PlayerModel player =
                      _filteredPlayers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EvalPlayerCard(
                          player: player,
                          isSelected:
                          player.id == _selectedPlayerId,
                          onTap: () => _onPlayerTap(player),
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
      bottomSheet: _EvalActionBar(
        player: _selectedPlayer,
        onEvaluate: _openEvaluation,
      ),
    );
  }
}

class _EvalPlayerSearchBar extends StatelessWidget {
  const _EvalPlayerSearchBar({
    required this.controller,
    required this.onChanged,
  });

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
          hintText: 'Search by name, code or phone',
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

class _EvalPlayerCard extends StatelessWidget {
  const _EvalPlayerCard({
    required this.player,
    required this.isSelected,
    required this.onTap,
  });

  final PlayerModel player;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Color borderColor =
    isSelected ? colorScheme.primary : Colors.transparent;
    final Color backgroundColor = isSelected
        ? colorScheme.primary.withValues(alpha: 0.08)
        : colorScheme.surfaceContainerLow;
    final String groupText = player.group ?? '-';
    final String ageText = player.age?.toString() ?? '-';
    final String attendanceText = player.attendance == null
        ? '-'
        : '${(player.attendance! * 100).round()}%';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.25)
                : colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: isSelected ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                _EvalPlayerAvatar(player: player, isSelected: isSelected),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              player.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _EvalStatusBadge(status: player.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$groupText • $ageText yrs',
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
                            Icons.fact_check_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$attendanceText attendance',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> anim) {
                    return ScaleTransition(scale: anim, child: child);
                  },
                  child: isSelected
                      ? Container(
                    key: const ValueKey<bool>(true),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: colorScheme.onPrimary,
                    ),
                  )
                      : const SizedBox(
                    key: ValueKey<bool>(false),
                    width: 26,
                    height: 26,
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

class _EvalPlayerAvatar extends StatelessWidget {
  const _EvalPlayerAvatar({required this.player, required this.isSelected});

  final PlayerModel player;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
        image: player.photo == null
            ? null
            : DecorationImage(
          image: NetworkImage(player.photo!),
          fit: BoxFit.cover,
        ),
        border: isSelected
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: player.photo == null
          ? Text(
        player.initial,
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      )
          : null,
    );
  }
}

class _EvalStatusBadge extends StatelessWidget {
  const _EvalStatusBadge({required this.status});

  final String status;

  String _label() {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'injured':
        return 'Injured';
      case 'inactive':
      default:
        return 'Inactive';
    }
  }

  Color _color(ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'active':
        return colorScheme.primary;
      case 'injured':
        return colorScheme.error;
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

/// Sticky bottom action bar with a single "Evaluate Player" button,
/// shown once a player is selected. Mirrors `_PlayerActionBar` from
/// `PlayersScreen` but with one action instead of two.
class _EvalActionBar extends StatelessWidget {
  const _EvalActionBar({
    required this.player,
    required this.onEvaluate,
  });

  final PlayerModel? player;
  final ValueChanged<PlayerModel> onEvaluate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final PlayerModel? current = player;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      offset: current == null ? const Offset(0, 1) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: current == null ? 0 : 1,
        child: IgnorePointer(
          ignoring: current == null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: current == null
                  ? const SizedBox(height: 0)
                  : Row(
                children: <Widget>[
                  _EvalPlayerAvatar(player: current, isSelected: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          current.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          current.group ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => onEvaluate(current),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    icon: const Icon(Icons.assessment_rounded, size: 18),
                    label: const Text('Evaluate Player'),
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

class _EmptyEvalPlayersState extends StatelessWidget {
  const _EmptyEvalPlayersState();

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
                Icons.groups_rounded,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Players Found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Players you add will show up here for evaluation.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
