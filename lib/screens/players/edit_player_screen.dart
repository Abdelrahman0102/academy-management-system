// edit_player_screen.dart
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


/// Edit Player screen for the Sports Academy Management System.
///
/// Opened from `PlayersScreen` after a player is selected and the Edit
/// action is pressed. All fields arrive pre-filled with the selected
/// player's current data so the coach edits existing values rather than
/// entering new ones.
///
/// TODO(api): this screen currently seeds its form with dummy data via
/// [_loadDummyPlayer]. Once `PlayersScreen` passes the selected player
/// (or its id) through navigation, replace that seed with the real
/// values / a `GET /players/{id}` fetch, and wire [_submit] to
/// `PUT /players/{id}`.
///
/// Styling comes entirely from `Theme.of(context)`; no colors or fonts
/// are hardcoded.
class EditPlayerScreen extends StatefulWidget {
  const EditPlayerScreen({super.key, this.playerId});

  static const String routeName = '/players/edit';

  /// Id of the player being edited. Optional for now — wire this in
  /// once `PlayersScreen` passes the selected player through.
  final String? playerId;

  @override
  State<EditPlayerScreen> createState() => _EditPlayerScreenState();
}

class _EditPlayerScreenState extends State<EditPlayerScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _groupController = TextEditingController();
  final TextEditingController _scheduleController = TextEditingController();

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _parentNameController;
  late final TextEditingController _parentPhoneController;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  String? _selectedGroup;
  String? _selectedSchedule;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final _DummyPlayer player = _loadDummyPlayer(widget.playerId);
    _nameController = TextEditingController(text: player.name);
    _ageController = TextEditingController(text: player.age.toString());
    _parentNameController = TextEditingController(text: player.parentName);
    _parentPhoneController =
        TextEditingController(text: player.parentPhone);

    _selectedGroup = player.group;
    _selectedSchedule = player.schedule;


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
    _nameController.dispose();
    _ageController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Dummy player data standing in for the selected player until
  /// `PlayersScreen` passes real data through navigation.
  _DummyPlayer _loadDummyPlayer(String? playerId) {
    return const _DummyPlayer(
      id: 'p1',
      name: 'Youssef Hassan',
      age: 13,
      group: 'U14 - Falcons',
      schedule: 'Sat / Mon / Wed - Morning',
      parentName: 'Hassan Ibrahim',
      parentPhone: '01012345678',
      photoUrl: null,
    );
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
    if (!isValid || _isSaving) return;

    setState(() => _isSaving = true);

    // TODO(api): PUT /players/{id}
    // final payload = {
    //   'name': _nameController.text.trim(),
    //   'age': int.parse(_ageController.text.trim()),
    //   'group': _selectedGroup,
    //   'schedule': _selectedSchedule,
    //   'parent_name': _parentNameController.text.trim(),
    //   'parent_phone': _parentPhoneController.text.trim(),
    // };
    // await playersRepository.updatePlayer(widget.playerId, payload);

    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _isSaving = false);
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
                          _PlayerPhotoSection(
                            heroTag:
                            'player_avatar_${widget.playerId ?? 'p1'}',
                            initial: _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : '?',
                          ),
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
                                      _validateRequired(
                                          value, 'Player name'),
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
           ]),
                  ),
      )),
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

/// Minimal dummy player shape used only to seed the form until real
/// player data is passed into this screen.
class _DummyPlayer {
  const _DummyPlayer({
    required this.id,
    required this.name,
    required this.age,
    required this.group,
    required this.schedule,
    required this.parentName,
    required this.parentPhone,
    required this.photoUrl,
  });

  final String id;
  final String name;
  final int age;
  final String group;
  final String schedule;
  final String parentName;
  final String parentPhone;
  final String? photoUrl;
}

// ---------------------------------------------------------------------------
// Photo section
// ---------------------------------------------------------------------------

/// Large circular avatar showing the player's current photo (or a
/// placeholder initial), with a camera overlay and a Hero tag so it
/// animates from the players list / details screen. UI only — no image
/// picker is wired in.
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
            // TODO(feature): open an image picker and upload the new
            // photo once photo upload is implemented.
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

/// Full-width, sticky "Save Changes" button with a loading state ready
/// for the future PUT call.
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