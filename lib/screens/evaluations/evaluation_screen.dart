// evaluation_screen.dart
import 'package:flutter/material.dart';

import '/models/player.dart';
import '/repositories/player_repository.dart';

/// Player Evaluation form for the Sports Academy Management System.
///
/// Opened from `PlayerEvaluationScreen` after a coach picks a player.
/// Scores several categories (technical, physical, tactical,
/// psychological, personal traits, discipline, match pressure) plus a
/// free-text note, with live running totals. Visual language (cards,
/// radii, shadows, spacing, typography) is pulled directly from
/// `Theme.of(context)` and matches `PlayerDetailsScreen` /
/// `PlayersScreen` — no new colors, fonts or shapes are introduced.
///
/// Score calculations here are UI-only; the backend recomputes and
/// persists the authoritative totals on save.
class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({
    super.key,
    required this.player,
    required this.repository,
  });

  final PlayerModel player;
  final PlayerRepository repository;

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final TextEditingController _notesController;

  bool _isSaving = false;

  final Map<String, int> _technical = <String, int>{
    for (final _ScoreField f in _technicalFields) f.id: 0,
  };
  final Map<String, int> _physical = <String, int>{
    for (final _ScoreField f in _physicalFields) f.id: 0,
  };
  final Map<String, int> _tactical = <String, int>{
    for (final _ScoreField f in _tacticalFields) f.id: 0,
  };
  final Map<String, int> _psychological = <String, int>{
    for (final _ScoreField f in _psychologicalFields) f.id: 0,
  };
  final Map<String, int> _personal = <String, int>{
    for (final _ScoreField f in _personalFields) f.id: 0,
  };
  final Map<String, int> _discipline = <String, int>{
    for (final _ScoreField f in _disciplineFields) f.id: 0,
  };
  int _pressure = 0;

  static const List<_ScoreField> _technicalFields = <_ScoreField>[
    _ScoreField('passing', 'Passing'),
    _ScoreField('dribbling', 'Dribbling'),
    _ScoreField('shooting', 'Shooting'),
    _ScoreField('running_with_ball', 'Running with Ball'),
    _ScoreField('ball_control', 'Ball Control'),
  ];

  static const List<_ScoreField> _physicalFields = <_ScoreField>[
    _ScoreField('agility_flexibility', 'Agility & Flexibility'),
    _ScoreField('strength', 'Strength'),
    _ScoreField('speed', 'Speed'),
    _ScoreField('coordination', 'Coordination'),
  ];

  static const List<_ScoreField> _tacticalFields = <_ScoreField>[
    _ScoreField('attack', 'Attack'),
    _ScoreField('defense', 'Defense'),
  ];

  static const List<_ScoreField> _psychologicalFields = <_ScoreField>[
    _ScoreField('decision_making', 'Decision Making'),
    _ScoreField('awareness', 'Awareness'),
    _ScoreField('attention_focus', 'Attention & Focus'),
  ];

  static const List<_ScoreField> _personalFields = <_ScoreField>[
    _ScoreField('determination', 'Determination'),
    _ScoreField('creativity', 'Creativity'),
    _ScoreField('self_confidence', 'Self Confidence'),
    _ScoreField('leadership', 'Leadership'),
    _ScoreField('cooperation', 'Cooperation'),
  ];

  static const List<_ScoreField> _disciplineFields = <_ScoreField>[
    _ScoreField('emotional_stability', 'Emotional Stability'),
    _ScoreField('training_attendance', 'Training Attendance'),
    _ScoreField('following_instructions', 'Following Instructions'),
    _ScoreField('uniform_commitment', 'Uniform Commitment'),
    _ScoreField('behavior', 'Behavior'),
  ];

  static const int _pressureMax = 40;

  int get _technicalTotal => _technical.values.fold(0, (a, b) => a + b);
  int get _physicalTotal => _physical.values.fold(0, (a, b) => a + b);
  int get _tacticalTotal => _tactical.values.fold(0, (a, b) => a + b);
  int get _psychologicalTotal =>
      _psychological.values.fold(0, (a, b) => a + b);
  int get _personalTotal => _personal.values.fold(0, (a, b) => a + b);
  int get _disciplineTotal => _discipline.values.fold(0, (a, b) => a + b);

  int get _maxTechnical => _technicalFields.length * 5;
  int get _maxPhysical => _physicalFields.length * 5;
  int get _maxTactical => _tacticalFields.length * 10;
  int get _maxPsychological => _psychologicalFields.length * 5;
  int get _maxPersonal => _personalFields.length * 5;
  int get _maxDiscipline => _disciplineFields.length * 5;

  int get _overallScore =>
      _technicalTotal +
          _physicalTotal +
          _tacticalTotal +
          _psychologicalTotal +
          _personalTotal +
          _disciplineTotal +
          _pressure;

  int get _overallMax =>
      _maxTechnical +
          _maxPhysical +
          _maxTactical +
          _maxPsychological +
          _maxPersonal +
          _maxDiscipline +
          _pressureMax;

  double get _overallPercentage =>
      _overallMax == 0 ? 0 : (_overallScore / _overallMax) * 100;

  String get _ratingLabel {
    final double pct = _overallPercentage;
    if (pct >= 90) return 'Exceptional';
    if (pct >= 75) return 'Very Good';
    if (pct >= 60) return 'Good';
    if (pct >= 40) return 'Average';
    return 'Needs Improvement';
  }

  Color _ratingColor(ColorScheme colorScheme) {
    final double pct = _overallPercentage;
    if (pct >= 75) return colorScheme.primary;
    if (pct >= 40) return colorScheme.secondary;
    return colorScheme.error;
  }

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
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
    _notesController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _setScore(Map<String, int> bucket, String id, int value, int max) {
    setState(() => bucket[id] = value.clamp(0, max));
  }

  Future<void> _saveEvaluation() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final String normalizedNotes = _notesController.text.trim();

    final Map<String, dynamic> evaluationData = <String, dynamic>{
      'player_id': widget.player.id,

      // Technical
      'passing': _technical['passing'] ?? 0,
      'dribbling': _technical['dribbling'] ?? 0,
      'shooting': _technical['shooting'] ?? 0,
      'running_with_ball': _technical['running_with_ball'] ?? 0,
      'ball_control': _technical['ball_control'] ?? 0,

      // Physical
      'agility_flexibility': _physical['agility_flexibility'] ?? 0,
      'strength': _physical['strength'] ?? 0,
      'speed': _physical['speed'] ?? 0,
      'coordination': _physical['coordination'] ?? 0,

      // Tactical
      'attack': _tactical['attack'] ?? 0,
      'defense': _tactical['defense'] ?? 0,

      // Psychological
      'decision_making': _psychological['decision_making'] ?? 0,
      'awareness': _psychological['awareness'] ?? 0,
      'attention_focus': _psychological['attention_focus'] ?? 0,

      // Personal
      'determination': _personal['determination'] ?? 0,
      'creativity': _personal['creativity'] ?? 0,
      'self_confidence': _personal['self_confidence'] ?? 0,
      'leadership': _personal['leadership'] ?? 0,
      'cooperation': _personal['cooperation'] ?? 0,

      // Discipline
      'emotional_stability': _discipline['emotional_stability'] ?? 0,
      'training_attendance': _discipline['training_attendance'] ?? 0,
      'following_instructions':
      _discipline['following_instructions'] ?? 0,
      'uniform_commitment': _discipline['uniform_commitment'] ?? 0,
      'behavior': _discipline['behavior'] ?? 0,

      // Pressure
      'pressure_performance': _pressure,

      // Optional field
      'notes': normalizedNotes.isEmpty ? null : normalizedNotes,
    };

    try {
      final Map<String, dynamic> savedEvaluation =
      await widget.repository.saveEvaluation(evaluationData);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Evaluation saved successfully')),
        );

      Navigator.pop(context, savedEvaluation);
    } on PlayerRepositoryException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error.message)),
        );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Unable to save evaluation: $error')),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final bool isTablet = size.shortestSide >= 600;
    final double horizontalPadding = isTablet ? 32 : 20;
    final double maxContentWidth = isTablet ? 640 : double.infinity;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Player Evaluation'),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        24,
                      ),
                      children: <Widget>[
                        _EvalHeaderCard(player: widget.player),
                        const SizedBox(height: 16),
                        _FadeSlideIn(
                          index: 0,
                          child: _CategoryCard(
                            icon: Icons.sports_soccer_rounded,
                            titleAr: 'الفني والمهاري',
                            titleEn: 'Technical & Skills',
                            fields: _technicalFields,
                            perFieldMax: 5,
                            values: _technical,
                            subtotal: _technicalTotal,
                            max: _maxTechnical,
                            onChanged: (String id, int v) =>
                                _setScore(_technical, id, v, 5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FadeSlideIn(
                          index: 1,
                          child: _CategoryCard(
                            icon: Icons.fitness_center_rounded,
                            titleAr: 'البدني',
                            titleEn: 'Physical',
                            fields: _physicalFields,
                            perFieldMax: 5,
                            values: _physical,
                            subtotal: _physicalTotal,
                            max: _maxPhysical,
                            onChanged: (String id, int v) =>
                                _setScore(_physical, id, v, 5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FadeSlideIn(
                          index: 2,
                          child: _CategoryCard(
                            icon: Icons.psychology_alt_rounded,
                            titleAr: 'الخططي',
                            titleEn: 'Tactical',
                            fields: _tacticalFields,
                            perFieldMax: 10,
                            values: _tactical,
                            subtotal: _tacticalTotal,
                            max: _maxTactical,
                            onChanged: (String id, int v) =>
                                _setScore(_tactical, id, v, 10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FadeSlideIn(
                          index: 3,
                          child: _CategoryCard(
                            icon: Icons.self_improvement_rounded,
                            titleAr: 'الأداء النفسي',
                            titleEn: 'Psychological Performance',
                            fields: _psychologicalFields,
                            perFieldMax: 5,
                            values: _psychological,
                            subtotal: _psychologicalTotal,
                            max: _maxPsychological,
                            onChanged: (String id, int v) =>
                                _setScore(_psychological, id, v, 5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FadeSlideIn(
                          index: 4,
                          child: _CategoryCard(
                            icon: Icons.emoji_events_rounded,
                            titleAr: 'السمات الشخصية',
                            titleEn: 'Personal Traits',
                            fields: _personalFields,
                            perFieldMax: 5,
                            values: _personal,
                            subtotal: _personalTotal,
                            max: _maxPersonal,
                            onChanged: (String id, int v) =>
                                _setScore(_personal, id, v, 5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FadeSlideIn(
                          index: 5,
                          child: _CategoryCard(
                            icon: Icons.rule_rounded,
                            titleAr: 'القواعد التنظيمية',
                            titleEn: 'Discipline & Rules',
                            fields: _disciplineFields,
                            perFieldMax: 5,
                            values: _discipline,
                            subtotal: _disciplineTotal,
                            max: _maxDiscipline,
                            onChanged: (String id, int v) =>
                                _setScore(_discipline, id, v, 5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FadeSlideIn(
                          index: 6,
                          child: _PressureCard(
                            value: _pressure,
                            max: _pressureMax,
                            onChanged: (int v) =>
                                setState(() => _pressure = v.clamp(0, _pressureMax)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FadeSlideIn(
                          index: 7,
                          child: _NotesCard(controller: _notesController),
                        ),
                        const SizedBox(height: 16),
                        _FadeSlideIn(
                          index: 8,
                          child: _SummaryCard(
                            technical: _technicalTotal,
                            maxTechnical: _maxTechnical,
                            physical: _physicalTotal,
                            maxPhysical: _maxPhysical,
                            tactical: _tacticalTotal,
                            maxTactical: _maxTactical,
                            psychological: _psychologicalTotal,
                            maxPsychological: _maxPsychological,
                            personal: _personalTotal,
                            maxPersonal: _maxPersonal,
                            discipline: _disciplineTotal,
                            maxDiscipline: _maxDiscipline,
                            pressure: _pressure,
                            maxPressure: _pressureMax,
                            overallScore: _overallScore,
                            overallMax: _overallMax,
                            overallPercentage: _overallPercentage,
                            ratingLabel: _ratingLabel,
                            ratingColor: _ratingColor(theme.colorScheme),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _SaveBar(
                isSaving: _isSaving,
                onSave: _saveEvaluation,
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
// Field config
// ---------------------------------------------------------------------------

class _ScoreField {
  const _ScoreField(this.id, this.label);

  final String id;
  final String label;
}

// ---------------------------------------------------------------------------
// Staggered fade-in wrapper
// ---------------------------------------------------------------------------

/// Fades and slides its child in shortly after being built, staggered
/// by [index] so cards appear one after another rather than all at
/// once.
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header card
// ---------------------------------------------------------------------------

/// Compact player summary card at the top of the evaluation form.
/// Matches the section-card style used throughout
/// `PlayerDetailsScreen` (surfaceContainerLow, 20 radius, soft shadow).
class _EvalHeaderCard extends StatelessWidget {
  const _EvalHeaderCard({required this.player});

  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String groupText = player.group ?? '-';
    final String ageText = player.age?.toString() ?? '-';

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
      child: Row(
        children: <Widget>[
          Hero(
            tag: 'player_avatar_${player.id}',
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: player.photo == null || player.photo!.trim().isEmpty
                  ? Text(
                player.initial,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              )
                  : Image.network(
                player.photo!.trim(),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  player.initial,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _HeaderStatusBadge(status: player.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${player.code} • $groupText • $ageText yrs',
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

class _HeaderStatusBadge extends StatelessWidget {
  const _HeaderStatusBadge({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
// Category card (technical / physical / tactical / psychological /
// personal / discipline all share this shape, just different fields
// and per-field max)
// ---------------------------------------------------------------------------

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.titleAr,
    required this.titleEn,
    required this.fields,
    required this.perFieldMax,
    required this.values,
    required this.subtotal,
    required this.max,
    required this.onChanged,
  });

  final IconData icon;
  final String titleAr;
  final String titleEn;
  final List<_ScoreField> fields;
  final int perFieldMax;
  final Map<String, int> values;
  final int subtotal;
  final int max;
  final void Function(String id, int value) onChanged;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      titleAr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      titleEn,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _SubtotalBadge(value: subtotal, max: max),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < fields.length; i++) ...<Widget>[
            _ScoreStepperRow(
              label: fields[i].label,
              value: values[fields[i].id] ?? 0,
              max: perFieldMax,
              onChanged: (int v) => onChanged(fields[i].id, v),
            ),
            if (i != fields.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Small pill showing "current / max" for a category, with an
/// animated transition whenever the value changes.
class _SubtotalBadge extends StatelessWidget {
  const _SubtotalBadge({required this.value, required this.max});

  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> anim) {
          return ScaleTransition(scale: anim, child: child);
        },
        child: Text(
          '$value/$max',
          key: ValueKey<int>(value),
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Beautiful, compact stepper: label on the left, filled-tonal minus
/// button, animated numeric value, filled plus button.
class _ScoreStepperRow extends StatelessWidget {
  const _ScoreStepperRow({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          style: IconButton.styleFrom(
            minimumSize: const Size(32, 32),
            padding: EdgeInsets.zero,
          ),
          icon: const Icon(Icons.remove_rounded, size: 16),
        ),
        SizedBox(
          width: 34,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (Widget child, Animation<double> anim) {
                return ScaleTransition(scale: anim, child: child);
              },
              child: Text(
                '$value',
                key: ValueKey<int>(value),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        IconButton.filled(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            minimumSize: const Size(32, 32),
            padding: EdgeInsets.zero,
          ),
          icon: const Icon(Icons.add_rounded, size: 16),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pressure card
// ---------------------------------------------------------------------------

class _PressureCard extends StatelessWidget {
  const _PressureCard({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

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
                child: Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'الأداء تحت ضغط المنافس',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Performance Under Match Pressure',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _SubtotalBadge(value: value, max: max),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (Widget child, Animation<double> anim) {
                return ScaleTransition(scale: anim, child: child);
              },
              child: Text(
                '$value',
                key: ValueKey<int>(value),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: max.toDouble(),
              divisions: max,
              label: '$value',
              onChanged: (double v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notes card
// ---------------------------------------------------------------------------

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller});

  final TextEditingController controller;

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
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Coach Notes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            minLines: 4,
            maxLines: 8,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Write notes about this evaluation...',
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.all(14),
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.technical,
    required this.maxTechnical,
    required this.physical,
    required this.maxPhysical,
    required this.tactical,
    required this.maxTactical,
    required this.psychological,
    required this.maxPsychological,
    required this.personal,
    required this.maxPersonal,
    required this.discipline,
    required this.maxDiscipline,
    required this.pressure,
    required this.maxPressure,
    required this.overallScore,
    required this.overallMax,
    required this.overallPercentage,
    required this.ratingLabel,
    required this.ratingColor,
  });

  final int technical;
  final int maxTechnical;
  final int physical;
  final int maxPhysical;
  final int tactical;
  final int maxTactical;
  final int psychological;
  final int maxPsychological;
  final int personal;
  final int maxPersonal;
  final int discipline;
  final int maxDiscipline;
  final int pressure;
  final int maxPressure;
  final int overallScore;
  final int overallMax;
  final double overallPercentage;
  final String ratingLabel;
  final Color ratingColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final List<MapEntry<String, String>> chips = <MapEntry<String, String>>[
      MapEntry<String, String>('Technical', '$technical/$maxTechnical'),
      MapEntry<String, String>('Physical', '$physical/$maxPhysical'),
      MapEntry<String, String>('Tactical', '$tactical/$maxTactical'),
      MapEntry<String, String>(
        'Psychological',
        '$psychological/$maxPsychological',
      ),
      MapEntry<String, String>('Personal', '$personal/$maxPersonal'),
      MapEntry<String, String>('Discipline', '$discipline/$maxDiscipline'),
      MapEntry<String, String>('Pressure', '$pressure/$maxPressure'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
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
                  Icons.insights_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Evaluation Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((MapEntry<String, String> entry) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entry.key}  ${entry.value}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$overallScore',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '/ $overallMax',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ratingColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ratingLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ratingColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: (overallPercentage / 100).clamp(0.0, 1.0),
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (BuildContext context, double value, Widget? _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(ratingColor),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${overallPercentage.toStringAsFixed(1)}%',
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
// Sticky save bar
// ---------------------------------------------------------------------------

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isSaving,
    required this.onSave,
    required this.maxContentWidth,
    required this.horizontalPadding,
  });

  final bool isSaving;
  final VoidCallback onSave;
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
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: isSaving
                      ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(isSaving ? 'Saving...' : 'Save Evaluation'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
