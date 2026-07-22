// add_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Training groups available for selection.
///
/// TODO(api): replace with groups fetched from `GET /groups` once the
/// backend endpoint is wired in.


/// Training schedules available for selection.
///
/// TODO(api): replace with schedules fetched from the backend once the
/// relevant endpoint is wired in.


/// Add Player screen for the Sports Academy Management System.
///
/// Opened from `PlayersScreen` via the existing Add Player action.
/// Collects player and parent information inside premium rounded
/// sections, validates the form client-side, and is structured to be
/// wired to `POST /players` later — no networking is implemented here.
///
/// Styling comes entirely from `Theme.of(context)`; no colors or fonts
/// are hardcoded.
class AddPlayerScreen extends StatefulWidget {
  const AddPlayerScreen({super.key});

  static const String routeName = '/players/add';

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController =

  TextEditingController();
  final TextEditingController _groupController = TextEditingController();
  final TextEditingController _scheduleController = TextEditingController();

  // String? _selectedGroup;
  // String? _selectedSchedule;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
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

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    final int? age = int.tryParse(value.trim());
    if (age == null) {
      return 'Enter a valid age';
    }
    if (age < 3 || age > 25) {
      return 'Age must be between 3 and 25';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Parent phone number is required';
    }
    final String digitsOnly = value.trim();
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validateDropdown(String? value, String fieldLabel) {
    if (value == null || value.isEmpty) {
      return 'Please select a $fieldLabel';
    }
    return null;
  }

  Future<void> _submit() async {
    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    // TODO(api): POST /players
    // final payload = {
    //   'name': _nameController.text.trim(),
    //   'age': int.parse(_ageController.text.trim()),
    //   'group': _selectedGroup,  'group': _groupController.text.trim(),
   // 'schedule': _scheduleController.text.trim(),
    //   'schedule': _selectedSchedule,
    //   'parent_name': _parentNameController.text.trim(),
    //   'parent_phone': _parentPhoneController.text.trim(),
    // };
    // await playersRepository.createPlayer(payload);

    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.pop(context);
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
                        _PlayerPhotoSection(),
                        const SizedBox(height: 20),
                        _SectionCard(
                          icon: Icons.assignment_ind_rounded,
                          title: 'Player Information',
                          children: <Widget>[
                            _LabeledField(
                              label: 'Player Name',
                              isRequired: true,
                              child: TextFormField(
                                controller: _nameController,
                                textCapitalization:
                                TextCapitalization.words,
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
                              label: 'Age',
                              isRequired: true,
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Enter age',
                                ),
                                validator: _validateAge,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _LabeledField(
                              label: 'Training Group',
                              isRequired: true,
                              child: TextFormField(
                                controller: _groupController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Enter training group',
                                ),
                                validator: (value) =>
                                    _validateRequired(value, 'Training Group'),
                              ),
                            ),

                            const SizedBox(height: 16),

                            _LabeledField(
                              label: 'Training Schedule',
                              isRequired: true,
                              child: TextFormField(
                                controller: _scheduleController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Enter training schedule',
                                ),
                                validator: (value) =>
                                    _validateRequired(value, 'Training Schedule'),
                              ),
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
                                textCapitalization:
                                TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: "Enter parent's full name",
                                ),
                                validator: (String? value) =>
                                    _validateRequired(
                                        value, 'Parent name'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Parent Phone Number',
                              isRequired: true,
                              child: TextFormField(
                                controller: _parentPhoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
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
                          ],
                        ),
                      ],
                    ),
                 ] ),
                ),
              )),
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

// ---------------------------------------------------------------------------
// Photo section
// ---------------------------------------------------------------------------

/// Large circular avatar placeholder with a camera overlay. Tapping it
/// is prepared for future photo-picking; no implementation is wired yet.
class _PlayerPhotoSection extends StatelessWidget {
  const _PlayerPhotoSection();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        children: <Widget>[
          GestureDetector(
            // TODO(feature): open an image picker and upload the photo
            // once photo upload is implemented.
            onTap: () {},
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
                  child: Icon(
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
            'Tap to add photo',
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
// Section card
// ---------------------------------------------------------------------------

/// A rounded, softly-shadowed card wrapping one form section, with an
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
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Labeled field
// ---------------------------------------------------------------------------

/// A field wrapper adding a small label above the input, with a
/// required-field asterisk. Validation error text is rendered by the
/// wrapped `TextFormField` / `DropdownButtonFormField` itself.
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

// ---------------------------------------------------------------------------
// Bottom action bar
// ---------------------------------------------------------------------------

/// Full-width, sticky "Add Player" button with a loading state ready
/// for the future submit call.
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