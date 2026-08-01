import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/coach.dart';
import '../../../models/group.dart';

class GroupFormValue {
  const GroupFormValue({
    required this.groupName,
    required this.level,
    required this.maxPlayers,
    required this.coachId,
    required this.schedules,
  });

  final String groupName;
  final String? level;
  final int? maxPlayers;
  final int? coachId;
  final List<GroupScheduleRequest> schedules;
}

class GroupForm extends StatefulWidget {
  const GroupForm({
    required this.title,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.submitLabel,
    required this.submittingLabel,
    required this.isSubmitting,
    required this.isAdmin,
    required this.coaches,
    required this.onSubmit,
    this.initialName = '',
    this.initialLevel,
    this.initialMaxPlayers = 30,
    this.initialCoachId,
    this.initialSchedules = const <GroupScheduleModel>[],
    this.minimumMaxPlayers = 1,
    super.key,
  });

  final String title;
  final String headerTitle;
  final String headerSubtitle;
  final String submitLabel;
  final String submittingLabel;
  final bool isSubmitting;
  final bool isAdmin;
  final List<CoachModel> coaches;
  final Future<void> Function(GroupFormValue value) onSubmit;

  final String initialName;
  final String? initialLevel;
  final int? initialMaxPlayers;
  final int? initialCoachId;
  final List<GroupScheduleModel> initialSchedules;
  final int minimumMaxPlayers;

  @override
  State<GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<GroupForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _levelController;
  late final TextEditingController _maxPlayersController;

  late List<_EditableSchedule> _schedules;
  int? _selectedCoachId;
  String? _scheduleError;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);
    _levelController = TextEditingController(text: widget.initialLevel ?? '');
    _maxPlayersController = TextEditingController(
      text: widget.initialMaxPlayers?.toString() ?? '',
    );

    final bool coachExists = widget.coaches.any(
          (CoachModel coach) => coach.id == widget.initialCoachId,
    );
    _selectedCoachId = coachExists ? widget.initialCoachId : null;

    _schedules = widget.initialSchedules
        .map(
          (GroupScheduleModel schedule) => _EditableSchedule(
        dayNumber: schedule.dayNumber,
        startTime: _parseTime(schedule.startTime),
        endTime: _parseTime(schedule.endTime),
      ),
    )
        .toList();

    if (_schedules.isEmpty) {
      _schedules = <_EditableSchedule>[
        _EditableSchedule(dayNumber: 1),
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _levelController.dispose();
    _maxPlayersController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final String normalized = value?.trim() ?? '';

    if (normalized.isEmpty) return 'Group name is required.';
    if (normalized.length > 100) {
      return 'Group name cannot exceed 100 characters.';
    }

    return null;
  }

  String? _validateLevel(String? value) {
    if ((value?.trim().length ?? 0) > 50) {
      return 'Level cannot exceed 50 characters.';
    }

    return null;
  }

  String? _validateMaximumPlayers(String? value) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return null;

    final int? parsed = int.tryParse(normalized);

    if (parsed == null ||
        parsed < widget.minimumMaxPlayers ||
        parsed > 1000) {
      if (widget.minimumMaxPlayers > 1) {
        return 'Maximum players must be between '
            '${widget.minimumMaxPlayers} and 1000.';
      }

      return 'Maximum players must be between 1 and 1000.';
    }

    return null;
  }

  String? _validateCoach(int? value) {
    if (widget.isAdmin && value == null) {
      return 'Select the coach responsible for this group.';
    }

    return null;
  }

  bool _validateSchedules() {
    if (_schedules.isEmpty) {
      setState(() {
        _scheduleError = 'At least one training schedule is required.';
      });
      return false;
    }

    final Set<String> uniqueSlots = <String>{};

    for (final _EditableSchedule schedule in _schedules) {
      if (schedule.startTime == null || schedule.endTime == null) {
        setState(() {
          _scheduleError =
          'Choose a start and end time for every schedule.';
        });
        return false;
      }

      final int startMinutes = _minutes(schedule.startTime!);
      final int endMinutes = _minutes(schedule.endTime!);

      if (endMinutes <= startMinutes) {
        setState(() {
          _scheduleError =
          'The end time must be later than the start time.';
        });
        return false;
      }

      final String duplicateKey =
          '${schedule.dayNumber}|${_format24(schedule.startTime!)}';

      if (!uniqueSlots.add(duplicateKey)) {
        setState(() {
          _scheduleError =
          'The same day and start time cannot be repeated.';
        });
        return false;
      }
    }

    setState(() {
      _scheduleError = null;
    });

    return true;
  }

  Future<void> _submit() async {
    if (widget.isSubmitting) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final bool validForm = _formKey.currentState?.validate() ?? false;
    final bool validSchedules = _validateSchedules();

    if (!validForm || !validSchedules) return;

    final List<GroupScheduleRequest> requests = _schedules
        .map(
          (_EditableSchedule schedule) => GroupScheduleRequest(
        dayNumber: schedule.dayNumber,
        startTime: _format24(schedule.startTime!),
        endTime: _format24(schedule.endTime!),
      ),
    )
        .toList(growable: false)
      ..sort(
            (GroupScheduleRequest left, GroupScheduleRequest right) {
          final int day = left.dayNumber.compareTo(right.dayNumber);
          return day != 0 ? day : left.startTime.compareTo(right.startTime);
        },
      );

    await widget.onSubmit(
      GroupFormValue(
        groupName: _nameController.text.trim(),
        level: _nullableText(_levelController.text),
        maxPlayers: _nullableInt(_maxPlayersController.text),
        coachId: widget.isAdmin ? _selectedCoachId : null,
        schedules: requests,
      ),
    );
  }

  void _addSchedule() {
    if (widget.isSubmitting) return;

    setState(() {
      _schedules.add(_EditableSchedule(dayNumber: 1));
      _scheduleError = null;
    });
  }

  void _removeSchedule(int index) {
    if (widget.isSubmitting || _schedules.length == 1) return;

    setState(() {
      _schedules.removeAt(index);
      _scheduleError = null;
    });
  }

  Future<void> _pickTime({
    required int index,
    required bool start,
  }) async {
    if (widget.isSubmitting) return;

    final _EditableSchedule schedule = _schedules[index];

    final TimeOfDay initialTime = start
        ? schedule.startTime ?? const TimeOfDay(hour: 17, minute: 0)
        : schedule.endTime ?? const TimeOfDay(hour: 18, minute: 30);

    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (!mounted || selected == null) return;

    setState(() {
      if (start) {
        schedule.startTime = selected;
      } else {
        schedule.endTime = selected;
      }

      _scheduleError = null;
    });
  }

  String? _nullableText(String value) {
    final String normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  int? _nullableInt(String value) {
    final String normalized = value.trim();
    return normalized.isEmpty ? null : int.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: <Widget>[
                  _HeaderCard(
                    colorScheme: colorScheme,
                    title: widget.headerTitle,
                    subtitle: widget.headerSubtitle,
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Group Information',
                    subtitle:
                    'Enter the name and level used to identify this group.',
                    icon: Icons.groups_rounded,
                    children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        enabled: !widget.isSubmitting,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: _validateName,
                        decoration: const InputDecoration(
                          labelText: 'Group Name',
                          hintText: 'Under 14 - A',
                          prefixIcon: Icon(Icons.badge_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _levelController,
                        enabled: !widget.isSubmitting,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: _validateLevel,
                        decoration: const InputDecoration(
                          labelText: 'Level',
                          hintText:
                          'Beginner, Intermediate, Advanced...',
                          prefixIcon: Icon(Icons.trending_up_rounded),
                        ),
                      ),
                    ],
                  ),
                  if (widget.isAdmin) ...<Widget>[
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Coach Assignment',
                      subtitle:
                      'Select the coach responsible for this training group.',
                      icon: Icons.sports_rounded,
                      children: <Widget>[
                        DropdownButtonFormField<int>(
                          value: _selectedCoachId,
                          isExpanded: true,
                          validator: _validateCoach,
                          onChanged: widget.isSubmitting
                              ? null
                              : (int? value) {
                            setState(() {
                              _selectedCoachId = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Coach',
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                          items: widget.coaches
                              .map(
                                (CoachModel coach) =>
                                DropdownMenuItem<int>(
                                  value: coach.id,
                                  child: Text(
                                    _coachLabel(coach),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                          )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Training Schedule',
                    subtitle:
                    'Add one or more weekly training days and times.',
                    icon: Icons.schedule_rounded,
                    children: <Widget>[
                      for (int index = 0;
                      index < _schedules.length;
                      index++) ...<Widget>[
                        _ScheduleRow(
                          index: index,
                          schedule: _schedules[index],
                          enabled: !widget.isSubmitting,
                          canRemove: _schedules.length > 1,
                          onDayChanged: (int dayNumber) {
                            setState(() {
                              _schedules[index].dayNumber = dayNumber;
                              _scheduleError = null;
                            });
                          },
                          onPickStart: () =>
                              _pickTime(index: index, start: true),
                          onPickEnd: () =>
                              _pickTime(index: index, start: false),
                          onRemove: () => _removeSchedule(index),
                        ),
                        if (index != _schedules.length - 1)
                          const SizedBox(height: 12),
                      ],
                      if (_scheduleError != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          _scheduleError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed:
                        widget.isSubmitting ? null : _addSchedule,
                        icon: const Icon(Icons.add_alarm_rounded),
                        label: const Text('Add Schedule'),
                      ),
                      if (_validSchedulePreview().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.primary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colorScheme.primary
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _validSchedulePreview()
                                .map(
                                  (String item) => Chip(
                                avatar: const Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                ),
                                label: Text(item),
                              ),
                            )
                                .toList(growable: false),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Capacity',
                    subtitle:
                    'Set the maximum number of active players allowed in the group.',
                    icon: Icons.people_alt_rounded,
                    children: <Widget>[
                      TextFormField(
                        controller: _maxPlayersController,
                        enabled: !widget.isSubmitting,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: _validateMaximumPlayers,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Maximum Players',
                          hintText: 'Leave empty for no limit',
                          prefixIcon: const Icon(
                            Icons.person_add_alt_1_rounded,
                          ),
                          helperText: widget.minimumMaxPlayers > 1
                              ? 'Cannot be lower than the current '
                              '${widget.minimumMaxPlayers} players.'
                              : 'Recommended value: 30',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.isSubmitting ? null : _submit,
                      icon: widget.isSubmitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
                      )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        widget.isSubmitting
                            ? widget.submittingLabel
                            : widget.submitLabel,
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

  String _coachLabel(CoachModel coach) {
    final String specialization = coach.specialization?.trim() ?? '';

    if (specialization.isEmpty) return coach.fullName;
    return '${coach.fullName} — $specialization';
  }

  List<String> _validSchedulePreview() {
    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);

    final List<_EditableSchedule> valid = _schedules
        .where(
          (_EditableSchedule item) =>
      item.startTime != null && item.endTime != null,
    )
        .toList()
      ..sort((_EditableSchedule left, _EditableSchedule right) {
        final int day = left.dayNumber.compareTo(right.dayNumber);

        if (day != 0) return day;

        return _minutes(left.startTime!)
            .compareTo(_minutes(right.startTime!));
      });

    return valid
        .map(
          (_EditableSchedule schedule) =>
      '${_dayName(schedule.dayNumber)} '
          '${localizations.formatTimeOfDay(schedule.startTime!)}'
          '–'
          '${localizations.formatTimeOfDay(schedule.endTime!)}',
    )
        .toList(growable: false);
  }
}

class _EditableSchedule {
  _EditableSchedule({
    required this.dayNumber,
    this.startTime,
    this.endTime,
  });

  int dayNumber;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.index,
    required this.schedule,
    required this.enabled,
    required this.canRemove,
    required this.onDayChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onRemove,
  });

  final int index;
  final _EditableSchedule schedule;
  final bool enabled;
  final bool canRemove;
  final ValueChanged<int> onDayChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: LayoutBuilder(
        builder: (
            BuildContext context,
            BoxConstraints constraints,
            ) {
          final bool compact = constraints.maxWidth < 480;

          final Widget dayField = DropdownButtonFormField<int>(
            value: schedule.dayNumber,
            isExpanded: true,
            onChanged: enabled
                ? (int? value) {
              if (value != null) onDayChanged(value);
            }
                : null,
            decoration: const InputDecoration(
              labelText: 'Day',
              prefixIcon: Icon(Icons.calendar_today_rounded),
            ),
            items: List<DropdownMenuItem<int>>.generate(
              7,
                  (int itemIndex) {
                final int dayNumber = itemIndex + 1;

                return DropdownMenuItem<int>(
                  value: dayNumber,
                  child: Text(_dayName(dayNumber)),
                );
              },
            ),
          );

          final Widget startField = _TimePickerField(
            label: 'Start Time',
            value: schedule.startTime == null
                ? null
                : localizations.formatTimeOfDay(schedule.startTime!),
            enabled: enabled,
            onTap: onPickStart,
          );

          final Widget endField = _TimePickerField(
            label: 'End Time',
            value: schedule.endTime == null
                ? null
                : localizations.formatTimeOfDay(schedule.endTime!),
            enabled: enabled,
            onTap: onPickEnd,
          );

          final Widget removeButton = IconButton(
            tooltip: 'Remove schedule',
            onPressed: enabled && canRemove ? onRemove : null,
            color: colorScheme.error,
            icon: const Icon(Icons.delete_outline_rounded),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Schedule ${index + 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    removeButton,
                  ],
                ),
                const SizedBox(height: 8),
                dayField,
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(child: startField),
                    const SizedBox(width: 10),
                    Expanded(child: endField),
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 3, child: dayField),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: startField),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: endField),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: removeButton,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String? value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time_rounded),
          enabled: enabled,
        ),
        child: Text(
          value ?? 'Select',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: value == null
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.colorScheme,
    required this.title,
    required this.subtitle,
  });

  final ColorScheme colorScheme;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary,
            ),
            child: Icon(
              Icons.group_add_rounded,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.78),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
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
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

TimeOfDay? _parseTime(String value) {
  final List<String> parts = value.split(':');

  if (parts.length < 2) return null;

  final int? hour = int.tryParse(parts[0]);
  final int? minute = int.tryParse(parts[1]);

  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }

  return TimeOfDay(hour: hour, minute: minute);
}

int _minutes(TimeOfDay value) => value.hour * 60 + value.minute;

String _format24(TimeOfDay value) {
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _dayName(int value) {
  switch (value) {
    case 1:
      return 'Saturday';
    case 2:
      return 'Sunday';
    case 3:
      return 'Monday';
    case 4:
      return 'Tuesday';
    case 5:
      return 'Wednesday';
    case 6:
      return 'Thursday';
    case 7:
      return 'Friday';
    default:
      return 'Saturday';
  }
}
