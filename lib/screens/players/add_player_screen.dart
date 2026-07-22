import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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
  final TextEditingController _groupController = TextEditingController();
  final TextEditingController _scheduleController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedStatus = 'active';
  String _selectedRelationship = 'Father';
  bool _isSubmitting = false;


  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    _medicalNotesController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _groupController.dispose();
    _scheduleController.dispose();
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
        groupName: _groupController.text,
        schedule: _scheduleController.text,
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
                              child: TextFormField(
                                controller: _groupController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                inputFormatters: <TextInputFormatter>[
                                  LengthLimitingTextInputFormatter(100),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Enter training group',
                                ),
                                validator: (String? value) =>
                                    _validateRequired(value, 'Training group'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Training Schedule',
                              isRequired: true,
                              child: TextFormField(
                                controller: _scheduleController,
                                textCapitalization: TextCapitalization.sentences,
                                textInputAction: TextInputAction.next,
                                inputFormatters: <TextInputFormatter>[
                                  LengthLimitingTextInputFormatter(255),
                                ],
                                decoration: const InputDecoration(
                                  hintText:
                                  'Example: Sat / Mon / Wed - 5:00 PM',
                                ),
                                validator: (String? value) =>
                                    _validateRequired(
                                      value,
                                      'Training schedule',
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
