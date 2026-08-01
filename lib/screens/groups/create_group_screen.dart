// create_group_screen.dart
import 'package:flutter/material.dart';

import '../../models/coach.dart';
import '../../repositories/coach_repository.dart';
import '../../repositories/group_repository.dart';
import '../../services/session_service.dart';
import '/widgets/group_form.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({
    required this.repository,
    this.coachRepository,
    super.key,
  });

  static const String routeName = '/groups/create';

  final GroupRepository repository;
  final CoachRepository? coachRepository;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isAdmin = false;
  String? _errorMessage;
  List<CoachModel> _coaches = const <CoachModel>[];

  @override
  void initState() {
    super.initState();
    _loadSetup();
  }

  Future<void> _loadSetup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bool isAdmin = await SessionService.isAdmin();
      List<CoachModel> coaches = const <CoachModel>[];

      if (isAdmin) {
        final CoachRepository? repository = widget.coachRepository;

        if (repository == null) {
          throw const GroupRepositoryException(
            'CoachRepository is required for administrator group creation.',
          );
        }

        coaches = (await repository.getCoaches(limit: 100))
            .where((CoachModel coach) => coach.status == 'active')
            .toList(growable: false);

        if (coaches.isEmpty) {
          throw const GroupRepositoryException(
            'No active coaches are available. Create or activate a coach first.',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _isAdmin = isAdmin;
        _coaches = coaches;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _submit(GroupFormValue value) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.repository.createGroup(
        groupName: value.groupName,
        level: value.level,
        maxPlayers: value.maxPlayers,
        schedules: value.schedules,
        coachId: _isAdmin ? value.coachId : null,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on GroupRepositoryException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      _showError('Unable to create group: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
    if (_isLoading) {
      return const _SetupLoadingScreen(title: 'Add Group');
    }

    if (_errorMessage != null) {
      return _SetupErrorScreen(
        title: 'Add Group',
        message: _errorMessage!,
        onRetry: _loadSetup,
      );
    }

    return PopScope(
      canPop: !_isSubmitting,
      child: GroupForm(
        title: 'Add Group',
        headerTitle: 'Create Training Group',
        headerSubtitle:
        'Define the group, coach, capacity, and weekly training schedule.',
        submitLabel: 'Create Group',
        submittingLabel: 'Creating Group...',
        isSubmitting: _isSubmitting,
        isAdmin: _isAdmin,
        coaches: _coaches,
        onSubmit: _submit,
      ),
    );
  }
}

class _SetupLoadingScreen extends StatelessWidget {
  const _SetupLoadingScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _SetupErrorScreen extends StatelessWidget {
  const _SetupErrorScreen({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

