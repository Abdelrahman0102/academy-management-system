import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '/models/group.dart';
import '/models/player.dart';
import '/repositories/player_repository.dart';

class AddPlayerScreen extends StatefulWidget {
  const AddPlayerScreen({
    super.key,
    required this.repository,
  });

  static const String routeName = '/players/add';

  final PlayerRepository repository;

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedPhoto;
  Uint8List? _selectedPhotoBytes;


  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _medicalNotesController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedStatus = 'active';
  String _selectedRelationship = 'Father';

  List<TrainingGroupModel> _groups = <TrainingGroupModel>[];
  int? _selectedGroupId;
  bool _isLoadingGroups = true;
  String? _groupsError;

  bool _isSubmitting = false;


  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    _medicalNotesController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldLabel) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Parent phone number is required';
    }

    if (value.trim().length < 10 || value.trim().length > 15) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  Future<void> _loadGroups() async {
    if (mounted) {
      setState(() {
        _isLoadingGroups = true;
        _groupsError = null;
      });
    }

    try {
      final List<TrainingGroupModel> groups =
      await widget.repository.getGroups();

      debugPrint('GROUPS COUNT: ${groups.length}');

      for (final TrainingGroupModel group in groups) {
        debugPrint(
          'GROUP: id=${group.id}, '
              'name=${group.name}, '
              'coach=${group.coachName}, '
              'players=${group.playersCount}, '
              'max=${group.maxPlayers}, '
              'available=${group.availablePlaces}, '
              'isFull=${group.isFull}',
        );
      }

      if (!mounted) return;

      final bool selectedStillExists =
          _selectedGroupId != null &&
              groups.any(
                    (TrainingGroupModel group) =>
                group.id == _selectedGroupId,
              );

      setState(() {
        _groups = groups;

        _selectedGroupId =
        selectedStillExists
            ? _selectedGroupId
            : null;

        _isLoadingGroups = false;
      });
    } on PlayerRepositoryException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingGroups = false;
        _groupsError = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingGroups = false;
        _groupsError =
        'Unable to load training groups: $error';
      });
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? selectedPhoto = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (selectedPhoto == null) return;

      final Uint8List bytes = await selectedPhoto.readAsBytes();

      const int maximumSize = 5 * 1024 * 1024;

      if (bytes.lengthInBytes > maximumSize) {
        if (!mounted) return;

        _showError('Photo cannot exceed 5 MB.');
        return;
      }

      setState(() {
        _selectedPhoto = selectedPhoto;
        _selectedPhotoBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;
      _showError('Unable to select photo: $error');
    }
  }

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 10),
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );

    if (selected == null) return;

    _birthDateController.text =
    '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';
  }


  Future<void> _submit() async {
    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final PlayerInput input = PlayerInput(
        code: _codeController.text,
        name: _nameController.text,
        birthDate: _birthDateController.text,
        gender: _selectedGender,
        status: _selectedStatus,
        groupId: _selectedGroupId,
        parentName: _parentNameController.text,
        parentPhone: _parentPhoneController.text,
        relationship: _selectedRelationship,
        medicalNotes: _medicalNotesController.text,
      );

      final PlayerModel created =
      await widget.repository.createPlayer(input);

      if (_selectedPhoto != null) {
        await widget.repository.uploadPlayerPhoto(
          playerId: created.id,
          photo: _selectedPhoto!,
        );
      }

      final PlayerModel completedPlayer =
      await widget.repository.getPlayer(created.id);

      if (!mounted) return;
      Navigator.pop(context, completedPlayer);
    } on PlayerRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError(error.toString());
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
    final double horizontalPadding = isTablet ? 32 : 20;
    final double maxContentWidth = isTablet ? 640 : double.infinity;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Add Player'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
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
                        _PlayerPhotoSection(
                          photoBytes: _selectedPhotoBytes,
                          onTap: _pickPhoto,
                        ),
                        const SizedBox(height: 20),
                        _SectionCard(
                          icon: Icons.assignment_ind_rounded,
                          title: 'Player Information',
                          children: <Widget>[
                            _LabeledField(
                              label: 'Player Code',
                              isRequired: true,
                              child: TextFormField(
                                controller: _codeController,
                                textCapitalization: TextCapitalization.characters,
                                textInputAction: TextInputAction.next,
                                inputFormatters: <TextInputFormatter>[
                                  LengthLimitingTextInputFormatter(30),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Enter unique player code',
                                ),
                                validator: (String? value) =>
                                    _validateRequired(value, 'Player code'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Player Name',
                              isRequired: true,
                              child: TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: "Enter player's full name",
                                ),
                                validator: (String? value) =>
                                    _validateRequired(value, 'Player name'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Birth Date',
                              isRequired: true,
                              child: TextFormField(
                                controller: _birthDateController,
                                readOnly: true,
                                onTap: _pickBirthDate,
                                decoration: const InputDecoration(
                                  hintText: 'YYYY-MM-DD',
                                  suffixIcon: Icon(Icons.calendar_month_rounded),
                                ),
                                validator: (String? value) =>
                                    _validateRequired(value, 'Birth date'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Gender',
                              isRequired: true,
                              child: DropdownButtonFormField<String>(
                                value: _selectedGender,
                                decoration: const InputDecoration(),
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem(
                                    value: 'Male',
                                    child: Text('Male'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Female',
                                    child: Text('Female'),
                                  ),
                                ],
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() => _selectedGender = value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Status',
                              isRequired: true,
                              child: DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                decoration: const InputDecoration(),
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem(
                                    value: 'active',
                                    child: Text('Active'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'inactive',
                                    child: Text('Inactive'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'injured',
                                    child: Text('Injured'),
                                  ),
                                ],
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() => _selectedStatus = value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Medical Notes',
                              child: TextFormField(
                                controller: _medicalNotesController,
                                minLines: 2,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Optional medical notes',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Training Group',
                              isRequired: true,
                              child: _GroupSelectionField(
                                groups: _groups,
                                selectedGroupId: _selectedGroupId,
                                isLoading: _isLoadingGroups,
                                errorMessage: _groupsError,
                                enabled: !_isSubmitting,
                                onRetry: _loadGroups,
                                onChanged: (int? groupId) {
                                  setState(() {
                                    _selectedGroupId = groupId;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          icon: Icons.family_restroom_rounded,
                          title: 'Parent Information',
                          children: <Widget>[
                            _LabeledField(
                              label: 'Parent Name',
                              isRequired: true,
                              child: TextFormField(
                                controller: _parentNameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: "Enter parent's full name",
                                ),
                                validator: (String? value) =>
                                    _validateRequired(value, 'Parent name'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Parent Phone Number',
                              isRequired: true,
                              child: TextFormField(
                                controller: _parentPhoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(15),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Enter phone number',
                                ),
                                validator: _validatePhone,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Relationship',
                              isRequired: true,
                              child: DropdownButtonFormField<String>(
                                value: _selectedRelationship,
                                decoration: const InputDecoration(),
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem(
                                    value: 'Father',
                                    child: Text('Father'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Mother',
                                    child: Text('Mother'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Guardian',
                                    child: Text('Guardian'),
                                  ),
                                ],
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(
                                          () => _selectedRelationship = value,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _AddPlayerBottomBar(
                isLoading: _isSubmitting,
                onPressed: _submit,
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

class _GroupSelectionField extends StatelessWidget {
  const _GroupSelectionField({
    required this.groups,
    required this.selectedGroupId,
    required this.isLoading,
    required this.errorMessage,
    required this.enabled,
    required this.onRetry,
    required this.onChanged,
  });

  final List<TrainingGroupModel> groups;
  final int? selectedGroupId;
  final bool isLoading;
  final String? errorMessage;
  final bool enabled;
  final Future<void> Function() onRetry;
  final ValueChanged<int?> onChanged;

  TrainingGroupModel? get _selectedGroup {
    for (final TrainingGroupModel group in groups) {
      if (group.id == selectedGroupId) {
        return group;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant,
          ),
        ),
        child: const Row(
          children: <Widget>[
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text('Loading available groups...'),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
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
                errorMessage!,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (groups.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.groups_rounded,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No groups with available places were found. '
                    'Create a group or increase its capacity first.',
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Reload groups',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      );
    }

    final TrainingGroupModel? selected = _selectedGroup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<int>(
          value: selectedGroupId,
          isExpanded: true,
          menuMaxHeight: 380,
          decoration: const InputDecoration(
            hintText: 'Choose a training group',
            prefixIcon: Icon(Icons.groups_rounded),
          ),
          items: groups
              .map(
                (TrainingGroupModel group) =>
                DropdownMenuItem<int>(
                  value: group.id,
                  child: Text(
                    _optionLabel(group),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
          )
              .toList(growable: false),
          onChanged: enabled ? onChanged : null,
          validator: (int? value) {
            if (value == null) {
              return 'Training group is required';
            }

            return null;
          },
        ),
        if (selected != null) ...<Widget>[
          const SizedBox(height: 12),
          _SelectedGroupDetails(group: selected),
        ],
      ],
    );
  }

  static String _optionLabel(
      TrainingGroupModel group,
      ) {
    final String level = group.level?.trim() ?? '';

    if (level.isEmpty) {
      return group.name;
    }

    return '${group.name} — $level';
  }
}

class _SelectedGroupDetails extends StatelessWidget {
  const _SelectedGroupDetails({
    required this.group,
  });

  final TrainingGroupModel group;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final String schedule = _scheduleText(group);
    final String capacity = group.maxPlayers == null
        ? '${group.safePlayersCount} players'
        : '${group.safePlayersCount} / '
        '${group.maxPlayers} players';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.sports_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.coachName ?? 'Coach not available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.schedule_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  schedule,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: <Widget>[
              Icon(
                Icons.people_alt_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.availablePlaces == null
                      ? capacity
                      : '$capacity • '
                      '${group.availablePlaces} places available',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _scheduleText(
      TrainingGroupModel group,
      ) {
    if (group.schedules.isNotEmpty) {
      return group.schedules
          .map(
            (GroupScheduleModel schedule) =>
        schedule.displayLabel,
      )
          .join(' / ');
    }

    final String legacy = group.schedule?.trim() ?? '';

    return legacy.isEmpty
        ? 'No schedule available'
        : legacy;
  }
}

class _PlayerPhotoSection extends StatelessWidget {
  const _PlayerPhotoSection({
    required this.onTap,
    this.photoBytes,
  });

  final VoidCallback onTap;
  final Uint8List? photoBytes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: photoBytes != null
                      ? Image.memory(
                    photoBytes!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                      : Icon(
                    Icons.person_rounded,
                    size: 56,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            photoBytes == null
                ? 'Tap to add photo'
                : 'Tap to change photo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

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
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.isRequired = false,
  });

  final String label;
  final Widget child;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RichText(
          text: TextSpan(
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            children: <InlineSpan>[
              TextSpan(text: label),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: colorScheme.error),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _AddPlayerBottomBar extends StatelessWidget {
  const _AddPlayerBottomBar({
    required this.isLoading,
    required this.onPressed,
    required this.maxContentWidth,
    required this.horizontalPadding,
  });

  final bool isLoading;
  final VoidCallback onPressed;
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
                height: 56,
                child: FilledButton(
                  onPressed: isLoading ? null : onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    disabledBackgroundColor:
                    colorScheme.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                      : Text(
                    'Add Player',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
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
