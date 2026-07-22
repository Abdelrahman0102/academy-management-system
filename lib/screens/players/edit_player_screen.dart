import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/models/player.dart';
import '/models/group.dart';
import '/repositories/player_repository.dart';

class EditPlayerScreen extends StatefulWidget {
  const EditPlayerScreen({
    super.key,
    required this.player,
    required this.repository,
  });

  static const String routeName = '/players/edit';

  final PlayerModel player;
  final PlayerRepository repository;

  @override
  State<EditPlayerScreen> createState() => _EditPlayerScreenState();
}

class _EditPlayerScreenState extends State<EditPlayerScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _medicalNotesController;
  late final TextEditingController _parentNameController;
  late final TextEditingController _parentPhoneController;
  late final TextEditingController _scheduleController;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  List<TrainingGroupModel> _groups = <TrainingGroupModel>[];
  int? _selectedGroupId;
  late String _selectedGender;
  late String _selectedStatus;
  late String _selectedRelationship;
  bool _isSaving = false;
  bool _isLoadingGroups = true;

  @override
  void initState() {
    super.initState();

    final PlayerModel player = widget.player;

    _codeController = TextEditingController(text: player.code);
    _nameController = TextEditingController(text: player.name);
    _birthDateController = TextEditingController(text: player.birthDate);
    _medicalNotesController =
        TextEditingController(text: player.medicalNotes ?? '');
    _parentNameController =
        TextEditingController(text: player.parentName ?? '');
    _parentPhoneController =
        TextEditingController(text: player.parentPhone ?? '');
    _scheduleController = TextEditingController(text: player.schedule ?? '-');

    _selectedGroupId = player.groupId;
    _selectedGender = player.gender == 'Female' ? 'Female' : 'Male';
    _selectedStatus = <String>{'active', 'inactive', 'injured'}
        .contains(player.status.toLowerCase())
        ? player.status.toLowerCase()
        : 'inactive';
    _selectedRelationship =
    <String>{'Father', 'Mother', 'Guardian'}
        .contains(player.parentRelationship)
        ? player.parentRelationship!
        : 'Father';

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

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
    _scheduleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final List<TrainingGroupModel> groups =
      await widget.repository.getGroups();

      if (!mounted) return;

      TrainingGroupModel? selected;
      for (final TrainingGroupModel group in groups) {
        if (group.id == _selectedGroupId) {
          selected = group;
          break;
        }
      }

      setState(() {
        _groups = groups;
        _isLoadingGroups = false;
        _scheduleController.text =
            selected?.schedule ?? widget.player.schedule ?? '-';
      });
    } on PlayerRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingGroups = false);
      _showError(error.message);
    }
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

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = DateTime.tryParse(_birthDateController.text) ??
        DateTime(now.year - 10);
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );

    if (selected == null) return;

    _birthDateController.text =
    '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';
  }

  void _onGroupChanged(int? groupId) {
    TrainingGroupModel? selected;

    for (final TrainingGroupModel group in _groups) {
      if (group.id == groupId) {
        selected = group;
        break;
      }
    }

    setState(() {
      _selectedGroupId = groupId;
      _scheduleController.text = selected?.schedule ?? '-';
    });
  }

  Future<void> _submit() async {
    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final PlayerModel updated = await widget.repository.updatePlayer(
        widget.player.id,
        PlayerInput(
          code: _codeController.text,
          name: _nameController.text,
          birthDate: _birthDateController.text,
          gender: _selectedGender,
          status: _selectedStatus,
          groupId: _selectedGroupId,
          parentName: _parentNameController.text,
          parentPhone: _parentPhoneController.text,
          relationship: _selectedRelationship,
          photo: widget.player.photo,
          medicalNotes: _medicalNotesController.text,
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, updated);
    } on PlayerRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
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
        title: const Text('Edit Player'),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
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
                            heroTag: 'player_avatar_${widget.player.id}',
                            initial: widget.player.initial,
                            photoUrl: widget.player.photo,
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
                                  textCapitalization:
                                  TextCapitalization.characters,
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
                                    suffixIcon:
                                    Icon(Icons.calendar_month_rounded),
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
                                child: DropdownButtonFormField<int>(
                                  value: _groups.any(
                                        (TrainingGroupModel group) =>
                                    group.id == _selectedGroupId,
                                  )
                                      ? _selectedGroupId
                                      : null,
                                  decoration: InputDecoration(
                                    hintText: _isLoadingGroups
                                        ? 'Loading groups...'
                                        : 'Select training group',
                                  ),
                                  items: _groups
                                      .map(
                                        (TrainingGroupModel group) =>
                                        DropdownMenuItem<int>(
                                          value: group.id,
                                          child: Text(group.name),
                                        ),
                                  )
                                      .toList(growable: false),
                                  onChanged:
                                  _isLoadingGroups ? null : _onGroupChanged,
                                  validator: (int? value) => value == null
                                      ? 'Please select a training group'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _LabeledField(
                                label: 'Training Schedule',
                                child: TextFormField(
                                  controller: _scheduleController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    hintText: 'Schedule comes from the group',
                                  ),
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
                _EditPlayerBottomBar(
                  isLoading: _isSaving,
                  onPressed: _submit,
                  maxContentWidth: maxContentWidth,
                  horizontalPadding: horizontalPadding,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerPhotoSection extends StatelessWidget {
  const _PlayerPhotoSection({
    required this.heroTag,
    required this.initial,
    this.photoUrl,
  });

  final String heroTag;
  final String initial;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () {},
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Hero(
                  tag: heroTag,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primaryContainer,
                      image: photoUrl != null
                          ? DecorationImage(
                        image: NetworkImage(photoUrl!),
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
                    child: photoUrl == null
                        ? Text(
                      initial,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                        : null,
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
            'Tap to change photo',
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

class _EditPlayerBottomBar extends StatelessWidget {
  const _EditPlayerBottomBar({
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
                height: 55,
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
                    'Save Changes',
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
