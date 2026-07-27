// add_coach_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/repositories/coach_repository.dart';

class AddCoachScreen extends StatefulWidget {
  const AddCoachScreen({
    super.key,
    required this.repository,
  });

  static const String routeName = '/coaches/add';

  final CoachRepository repository;

  @override
  State<AddCoachScreen> createState() => _AddCoachScreenState();
}

class _AddCoachScreenState extends State<AddCoachScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _specializationController;
  late final TextEditingController _notesController;

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _specializationController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specializationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    final String name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Full name is required.';
    }

    if (name.length > 100) {
      return 'Full name cannot exceed 100 characters.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final String phone =
    (value ?? '').replaceAll(RegExp(r'\D'), '');

    String normalized = phone;

    if (normalized.startsWith('0020')) {
      normalized = normalized.substring(4);
    } else if (
    normalized.startsWith('20') &&
        normalized.length == 12) {
      normalized = normalized.substring(2);
    }

    if (!RegExp(r'^01[0125][0-9]{8}$').hasMatch(normalized)) {
      return 'Enter a valid Egyptian mobile number.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required.';
    }

    if (password.length < 8) {
      return 'Password must contain at least 8 characters.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Confirm the password.';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  String? _validateSpecialization(String? value) {
    if ((value?.trim().length ?? 0) > 100) {
      return 'Specialization cannot exceed 100 characters.';
    }

    return null;
  }

  String? _validateNotes(String? value) {
    if ((value?.trim().length ?? 0) > 5000) {
      return 'Notes cannot exceed 5000 characters.';
    }

    return null;
  }

  String _normalizedPhone() {
    String phone = _phoneController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (phone.startsWith('0020')) {
      phone = phone.substring(4);
    } else if (phone.startsWith('20') && phone.length == 12) {
      phone = phone.substring(2);
    }

    return phone;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.repository.createCoachFromData(
        fullName: _fullNameController.text.trim(),
        phone: _normalizedPhone(),
        password: _passwordController.text,
        specialization: _nullableText(
          _specializationController.text,
        ),
        notes: _nullableText(_notesController.text),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on CoachRepositoryException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      _showError('Unable to create coach: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _nullableText(String value) {
    final String normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Coach'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 640,
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    32,
                  ),
                  children: <Widget>[
                    _HeaderCard(colorScheme: colorScheme),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Account Information',
                      subtitle:
                      'The coach will use the phone and password to sign in.',
                      icon: Icons.account_circle_rounded,
                      children: <Widget>[
                        TextFormField(
                          controller: _fullNameController,
                          enabled: !_isSubmitting,
                          textCapitalization:
                          TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[
                            AutofillHints.name,
                          ],
                          validator: _validateFullName,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter coach full name',
                            prefixIcon:
                            Icon(Icons.person_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          enabled: !_isSubmitting,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[
                            AutofillHints.telephoneNumber,
                          ],
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+ ]'),
                            ),
                            LengthLimitingTextInputFormatter(16),
                          ],
                          validator: _validatePhone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: '01012345678',
                            prefixIcon: Icon(Icons.call_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isSubmitting,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[
                            AutofillHints.newPassword,
                          ],
                          validator: _validatePassword,
                          onChanged: (_) {
                            if (_confirmPasswordController
                                .text.isNotEmpty) {
                              _formKey.currentState?.validate();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'At least 8 characters',
                            prefixIcon:
                            const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                setState(() {
                                  _obscurePassword =
                                  !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller:
                          _confirmPasswordController,
                          enabled: !_isSubmitting,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[
                            AutofillHints.newPassword,
                          ],
                          validator: _validateConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Enter password again',
                            prefixIcon: const Icon(
                              Icons.lock_reset_rounded,
                            ),
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirmPassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                setState(() {
                                  _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Coach Information',
                      subtitle:
                      'Optional information for academy management.',
                      icon: Icons.sports_soccer_rounded,
                      children: <Widget>[
                        TextFormField(
                          controller: _specializationController,
                          enabled: !_isSubmitting,
                          textCapitalization:
                          TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: _validateSpecialization,
                          decoration: const InputDecoration(
                            labelText: 'Specialization',
                            hintText:
                            'Football, fitness, goalkeeping...',
                            prefixIcon:
                            Icon(Icons.workspace_premium_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _notesController,
                          enabled: !_isSubmitting,
                          minLines: 4,
                          maxLines: 7,
                          textCapitalization:
                          TextCapitalization.sentences,
                          textInputAction:
                          TextInputAction.newline,
                          validator: _validateNotes,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            hintText:
                            'Add any optional notes about the coach',
                            alignLabelWithHint: true,
                            prefixIcon:
                            Icon(Icons.notes_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                        _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2.2,
                          ),
                        )
                            : const Icon(
                          Icons.person_add_alt_1_rounded,
                        ),
                        label: Text(
                          _isSubmitting
                              ? 'Creating Coach...'
                              : 'Create Coach',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.colorScheme,
  });

  final ColorScheme colorScheme;

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
              Icons.person_add_alt_1_rounded,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Create Coach Account',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The account will be active immediately.',
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
          color: colorScheme.outlineVariant
              .withValues(alpha: 0.6),
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
                  color:
                  colorScheme.primary.withValues(alpha: 0.12),
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
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style:
                      theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style:
                      theme.textTheme.bodySmall?.copyWith(
                        color:
                        colorScheme.onSurfaceVariant,
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
