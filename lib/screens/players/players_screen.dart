// players_screen.dart
import 'package:flutter/material.dart';

import 'add_player_screen.dart';
import 'edit_player_screen.dart';
import 'player_details_screen.dart';

/// Dummy player model used until the screen is wired to the MySQL-backed
/// API. Field shape is kept close to what that API is expected to return
/// so swapping the data source later only touches [_PlayersScreenState._loadPlayers].
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.code,
    required this.phone,
    required this.group,
    required this.age,
    required this.attendance,
    required this.status,
  });

  final String id;
  final String name;
  final String code;
  final String phone;
  final String group;
  final int age;
  final double attendance;
  final PlayerStatus status;

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

enum PlayerStatus { active, inactive, pending }

extension PlayerStatusLabel on PlayerStatus {
  String get label {
    switch (this) {
      case PlayerStatus.active:
        return 'Active';
      case PlayerStatus.inactive:
        return 'Inactive';
      case PlayerStatus.pending:
        return 'Pending';
    }
  }
}

/// Players list screen for the Sports Academy Management System.
///
/// UX: players are browsed and searched first; tapping a card selects it
/// (single-selection only) and reveals a bottom action bar with
/// "Player Details" and "Edit Player". Adding a player is always
/// available via the app bar action / FAB and is never part of the
/// selection-dependent bottom bar.
///
/// Styling comes entirely from `Theme.of(context)` — no hardcoded colors
/// or fonts. Data is dummy for now; [_loadPlayers] is the single seam to
/// replace with the real MySQL-backed API call.
class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  static const String routeName = '/players';

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final AnimationController _listFadeController;
  late final Animation<double> _listFadeAnimation;

  List<Player> _allPlayers = <Player>[];
  List<Player> _filteredPlayers = <Player>[];
  String? _selectedPlayerId;

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

    _allPlayers = _loadPlayers();
    _filteredPlayers = _allPlayers;
    _listFadeController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listFadeController.dispose();
    super.dispose();
  }

  /// TODO(api): Replace with a call to the players endpoint backed by
  /// MySQL. Keep the return type as `List<Player>` so the rest of the
  /// screen needs no changes when the real data source lands.
  List<Player> _loadPlayers() {
    return const <Player>[
      Player(
        id: 'p1',
        name: 'Youssef Hassan',
        code: 'PLY-1042',
        phone: '01012345678',
        group: 'U14 - Falcons',
        age: 13,
        attendance: 0.94,
        status: PlayerStatus.active,
      ),
      Player(
        id: 'p2',
        name: 'Karim Mostafa',
        code: 'PLY-1043',
        phone: '01098765432',
        group: 'U16 - Eagles',
        age: 15,
        attendance: 0.81,
        status: PlayerStatus.active,
      ),
      Player(
        id: 'p3',
        name: 'Omar Adel',
        code: 'PLY-1044',
        phone: '01122334455',
        group: 'U12 - Cubs',
        age: 11,
        attendance: 0.67,
        status: PlayerStatus.pending,
      ),
      Player(
        id: 'p4',
        name: 'Ziad Tarek',
        code: 'PLY-1045',
        phone: '01234567890',
        group: 'U14 - Falcons',
        age: 13,
        attendance: 0.5,
        status: PlayerStatus.inactive,
      ),
      Player(
        id: 'p5',
        name: 'Mahmoud Nabil',
        code: 'PLY-1046',
        phone: '01555667788',
        group: 'U16 - Eagles',
        age: 16,
        attendance: 0.88,
        status: PlayerStatus.active,
      ),
    ];
  }

  void _onSearchChanged(String query) {
    final String normalized = query.trim().toLowerCase();
    setState(() {
      _filteredPlayers = normalized.isEmpty
          ? _allPlayers
          : _allPlayers.where((Player player) {
        return player.name.toLowerCase().contains(normalized) ||
            player.code.toLowerCase().contains(normalized) ||
            player.phone.contains(normalized);
      }).toList();

      if (_selectedPlayerId != null &&
          !_filteredPlayers.any((Player p) => p.id == _selectedPlayerId)) {
        _selectedPlayerId = null;
      }
    });
  }

  void _onPlayerTap(Player player) {
    setState(() {
      _selectedPlayerId = _selectedPlayerId == player.id ? null : player.id;
    });
  }

  void _clearSelection() => setState(() => _selectedPlayerId = null);

  Player? get _selectedPlayer {
    if (_selectedPlayerId == null) return null;
    for (final Player player in _allPlayers) {
      if (player.id == _selectedPlayerId) return player;
    }
    return null;
  }

  Future<void> _openAddPlayer() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const AddPlayerScreen()),
    );
  }

  Future<void> _openPlayerDetails(Player player) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        // TODO(api): pass the selected player once PlayerDetailsScreen
        // accepts a Player / playerId argument.
        builder: (_) => const PlayerDetailsScreen(),
      ),
    );
  }

  Future<void> _openEditPlayer(Player player) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        // TODO(api): pass the selected player once EditPlayerScreen
        // accepts a Player / playerId argument.
        builder: (_) => const EditPlayerScreen(),
      ),
    );
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
        title: const Text('Players'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add Player',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: _openAddPlayer,
          ),
        ],
      ),
      floatingActionButton: hasSelection
          ? null
          : FloatingActionButton(
        onPressed: _openAddPlayer,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _PlayerSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
            Expanded(
              child: _filteredPlayers.isEmpty
                  ? _EmptyPlayersState(onAddPlayer: _openAddPlayer)
                  : FadeTransition(
                opacity: _listFadeAnimation,
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    hasSelection ? 112 : 24,
                  ),
                  itemCount: _filteredPlayers.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Player player = _filteredPlayers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlayerCard(
                        player: player,
                        isSelected: player.id == _selectedPlayerId,
                        onTap: () => _onPlayerTap(player),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _PlayerActionBar(
        player: _selectedPlayer,
        onDetails: (Player player) => _openPlayerDetails(player),
        onEdit: (Player player) => _openEditPlayer(player),
        onDismiss: _clearSelection,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

/// Search field filtering by player name, code, or phone number.
class _PlayerSearchBar extends StatelessWidget {
  const _PlayerSearchBar({required this.controller, required this.onChanged});

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

// ---------------------------------------------------------------------------
// Player card
// ---------------------------------------------------------------------------

/// A single player row: avatar, name, group, age, attendance and status
/// badge. Reflects selection with a green border, glow, background tint
/// and a check icon, animating between states.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player,
    required this.isSelected,
    required this.onTap,
  });

  final Player player;
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
                _PlayerAvatar(player: player, isSelected: isSelected),
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
                          _StatusBadge(status: player.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${player.group} • ${player.age} yrs',
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
                            '${(player.attendance * 100).round()}% attendance',
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

/// Circular avatar showing the player's initial, with a highlighted
/// ring when the card is selected.
class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.player, required this.isSelected});

  final Player player;
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
        border: isSelected
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        player.initial,
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Small pill showing the player's status (active / inactive / pending).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PlayerStatus status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Color color;
    switch (status) {
      case PlayerStatus.active:
        color = colorScheme.primary;
        break;
      case PlayerStatus.inactive:
        color = colorScheme.error;
        break;
      case PlayerStatus.pending:
        color = colorScheme.tertiary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar
// ---------------------------------------------------------------------------

/// Bottom bar that slides up once a single player is selected, offering
/// only "Player Details" and "Edit Player". Hidden entirely otherwise.
class _PlayerActionBar extends StatelessWidget {
  const _PlayerActionBar({
    required this.player,
    required this.onDetails,
    required this.onEdit,
    required this.onDismiss,
  });

  final Player? player;
  final ValueChanged<Player> onDetails;
  final ValueChanged<Player> onEdit;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Player? current = player;

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
                  _PlayerAvatar(player: current, isSelected: true),
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
                          current.group,
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
                  _ActionBarButton(
                    icon: Icons.visibility_rounded,
                    label: 'Details',
                    onPressed: () => onDetails(current),
                  ),
                  const SizedBox(width: 8),
                  _ActionBarButton(
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    isPrimary: true,
                    onPressed: () => onEdit(current),
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

/// A single button inside the bottom action bar.
class _ActionBarButton extends StatelessWidget {
  const _ActionBarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (isPrimary) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

/// Shown when there are no players (or no matches for the current
/// search), with a direct call to action to add the first player.
class _EmptyPlayersState extends StatelessWidget {
  const _EmptyPlayersState({required this.onAddPlayer});

  final VoidCallback onAddPlayer;

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
              'Add your first player to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddPlayer,
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
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Player'),
            ),
          ],
        ),
      ),
    );
  }
}