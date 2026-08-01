// edit_group_screen.dart
import 'package:flutter/material.dart';

import '../../models/coach.dart';
import '../../models/group.dart';
import '../../repositories/coach_repository.dart';
import '../../repositories/group_repository.dart';
import '../../services/session_service.dart';
import '/widgets/group_form.dart';

class EditGroupScreen extends StatefulWidget {
  const EditGroupScreen({
    required this.repository,
    required this.group,
    this.coachRepository,
    super.key,
  });

  final GroupRepository repository;
  final TrainingGroupModel group;
  final CoachRepository? coachRepository;

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isAdmin = false;
  String? _errorMessage;
  TrainingGroupModel? _group;
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
      final TrainingGroupModel latestGroup =
      await widget.repository.getGroup(widget.group.id);

      List<CoachModel> coaches = const <CoachModel>[];

      if (isAdmin) {
        final CoachRepository? repository = widget.coachRepository;

        if (repository == null) {
          throw const GroupRepositoryException(
            'CoachRepository is required for administrator group editing.',
          );
        }

        coaches = (await repository.getCoaches(limit: 100))
            .where(
              (CoachModel coach) =>
          coach.status == 'active' ||
              coach.id == latestGroup.coachId,
        )
            .toList(growable: false);

        if (coaches.isEmpty) {
          throw const GroupRepositoryException(
            'No coaches are available for this group.',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _isAdmin = isAdmin;
        _coaches = coaches;
        _group = latestGroup;
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
    if (_isSubmitting || _group == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.repository.updateGroup(
        id: _group!.id,
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
      _showError('Unable to update group: $error');
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Group'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _group == null) {
      return _EditSetupError(
        message: _errorMessage ?? 'The group could not be loaded.',
        onRetry: _loadSetup,
      );
    }

    final TrainingGroupModel group = _group!;

    return PopScope(
      canPop: !_isSubmitting,
      child: GroupForm(
        key: ValueKey<int>(group.id),
        title: 'Edit Group',
        headerTitle: 'Update Training Group',
        headerSubtitle:
        'Edit the group information, capacity, and weekly schedule.',
        submitLabel: 'Save Changes',
        submittingLabel: 'Saving Changes...',
        isSubmitting: _isSubmitting,
        isAdmin: _isAdmin,
        coaches: _coaches,
        initialName: group.name,
        initialLevel: group.level,
        initialMaxPlayers: group.maxPlayers,
        initialCoachId: group.coachId,
        initialSchedules: group.schedules,
        minimumMaxPlayers:
        group.safePlayersCount > 0 ? group.safePlayersCount : 1,
        onSubmit: _submit,
      ),
    );
  }
}

class _EditSetupError extends StatelessWidget {
  const _EditSetupError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Group')),
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

