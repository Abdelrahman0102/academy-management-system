import 'package:flutter/material.dart';

import '../models/parent_account_request.dart';
import '../repositories/parent_account_request_repository.dart';

class ParentAccountRequestsScreen
    extends StatefulWidget {
  const ParentAccountRequestsScreen({
    super.key,
    required this.repository,
  });

  final ParentAccountRequestRepository repository;

  @override
  State<ParentAccountRequestsScreen> createState() =>
      _ParentAccountRequestsScreenState();
}

class _ParentAccountRequestsScreenState
    extends State<ParentAccountRequestsScreen> {
  List<ParentAccountRequestModel> _requests =
  const <ParentAccountRequestModel>[];
  String? _error;
  bool _loading = true;
  final Set<int> _reviewing = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<ParentAccountRequestModel>
      requests =
      await widget.repository.getPendingRequests();

      if (!mounted) return;

      setState(() {
        _requests = requests;
        _error = null;
        _loading = false;
      });
    } on ParentApprovalException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _review(
      ParentAccountRequestModel request,
      String action,
      ) async {
    if (_reviewing.contains(request.userId)) {
      return;
    }

    final bool confirmed =
    await _confirmReview(request, action);

    if (!confirmed || !mounted) return;

    setState(() => _reviewing.add(request.userId));

    try {
      if (action == 'approve') {
        await widget.repository.approve(
          request.userId,
        );
      } else {
        await widget.repository.reject(
          request.userId,
        );
      }

      if (!mounted) return;

      setState(() {
        _requests = _requests
            .where(
              (ParentAccountRequestModel item) =>
          item.userId != request.userId,
        )
            .toList(growable: false);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve'
                ? 'تمت الموافقة على الحساب.'
                : 'تم رفض طلب الحساب.',
          ),
        ),
      );
    } on ParentApprovalException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(
              () => _reviewing.remove(request.userId),
        );
      }
    }
  }

  Future<bool> _confirmReview(
      ParentAccountRequestModel request,
      String action,
      ) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final bool approve = action == 'approve';

        return AlertDialog(
          title: Text(
            approve
                ? 'تأكيد الموافقة'
                : 'تأكيد الرفض',
          ),
          content: Text(
            approve
                ? 'هل تريد تفعيل حساب '
                '${request.fullName}؟'
                : 'هل تريد رفض طلب حساب '
                '${request.fullName}؟',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    dialogContext,
                    false,
                  ),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                    dialogContext,
                    true,
                  ),
              child: Text(
                approve ? 'موافقة' : 'رفض',
              ),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'طلبات حسابات أولياء الأمور',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : _error != null
            ? ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const SizedBox(height: 120),
            Text(
              _error!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              child: const Text(
                'إعادة المحاولة',
              ),
            ),
          ],
        )
            : _requests.isEmpty
            ? ListView(
          padding:
          const EdgeInsets.all(24),
          children: <Widget>[
            const SizedBox(height: 120),
            Icon(
              Icons.how_to_reg_rounded,
              size: 64,
              color: theme.colorScheme
                  .onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد طلبات موافقة جديدة.',
              textAlign:
              TextAlign.center,
            ),
          ],
        )
            : ListView.separated(
          padding:
          const EdgeInsets.all(20),
          itemCount: _requests.length,
          separatorBuilder: (_, __) =>
          const SizedBox(
            height: 14,
          ),
          itemBuilder: (
              BuildContext context,
              int index,
              ) {
            final request =
            _requests[index];

            return _RequestCard(
              request: request,
              loading: _reviewing
                  .contains(
                request.userId,
              ),
              onApprove: () => _review(
                request,
                'approve',
              ),
              onReject: () => _review(
                request,
                'reject',
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.loading,
    required this.onApprove,
    required this.onReject,
  });

  final ParentAccountRequestModel request;
  final bool loading;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor:
                colors.primaryContainer,
                child: Icon(
                  Icons.family_restroom_rounded,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      request.fullName,
                      style: theme
                          .textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      request.phone,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        color:
                        colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'المتدربون المرتبطون',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          for (final ParentRequestPlayerModel player
          in request.players)
            Padding(
              padding:
              const EdgeInsets.only(bottom: 6),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.sports_soccer_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${player.fullName} '
                          '(${player.playerCode})',
                    ),
                  ),
                  Text(
                    player.relationship,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          if (loading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                    label: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(
                      Icons.check_rounded,
                    ),
                    label: const Text('موافقة'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
