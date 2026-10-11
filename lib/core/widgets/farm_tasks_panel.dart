import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_dialog.dart';
import 'crop_variety_modal_frame.dart';

/// Shared farm task list for the two administrator farm detail screens.
class FarmTasksPanel extends ConsumerStatefulWidget {
  const FarmTasksPanel({super.key, required this.farmId, this.api});
  final String farmId;
  final SuperAdminApiService? api;
  @override
  ConsumerState<FarmTasksPanel> createState() => _FarmTasksPanelState();
}

class _FarmTasksPanelState extends ConsumerState<FarmTasksPanel> {
  late final _api = widget.api ?? SuperAdminApiService();
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FarmTasksPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.farmId != widget.farmId) _load();
  }

  int _revision = 0;
  Future<void> _load() async {
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await _api.getFarmTasks();
      if (!mounted || revision != _revision) return;
      setState(() {
        _tasks = tasks.where((t) => t['farm_id'] == widget.farmId).toList();
        _loading = false;
      });
    } catch (error) {
      if (mounted && revision == _revision) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> task) async {
    final deleted = await showAppDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TaskDeleteModal(task: task, api: _api));
    if (!mounted || deleted != true) return;
    setState(() => _tasks.removeWhere((t) => t[r'$id'] == task[r'$id']));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user?.isAdmin != true && user?.isSuperAdmin != true) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.task_alt_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('Farm tasks', style: AppTypography.h6)),
            IconButton(
                tooltip: 'Refresh tasks',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, size: 20))
          ]),
          Text('Assigned caretaker and technician tasks',
              style: AppTypography.bodySmall),
          const SizedBox(height: 12),
          if (_loading)
            const LinearProgressIndicator()
          else if (_error != null) ...[
            Text(_error!,
                style: AppTypography.bodySmall.copyWith(color: colors.error)),
            TextButton(onPressed: _load, child: const Text('Retry'))
          ] else if (_tasks.isEmpty)
            Text('No tasks assigned to this farm.',
                style: AppTypography.bodyMedium)
          else
            ..._tasks.map((task) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('${task['title'] ?? 'Task'}',
                                style: AppTypography.bodyMedium),
                            const SizedBox(height: 4),
                            Text(
                                '${task['assigned_to_name'] ?? 'Unassigned'} · ${task['status'] ?? 'Pending'}',
                                style: AppTypography.bodySmall),
                            if ('${task['description'] ?? ''}'.isNotEmpty)
                              Text('${task['description']}',
                                  style: AppTypography.bodySmall),
                            if ('${task['due_date'] ?? ''}'.isNotEmpty)
                              Text('Due: ${task['due_date']}',
                                  style: AppTypography.bodySmall),
                          ])),
                      IconButton(
                          tooltip: 'Delete task',
                          onPressed: () => _delete(task),
                          icon: Icon(Icons.delete_outline_rounded,
                              color: colors.error, size: 20)),
                    ]))),
        ]));
  }
}

class TaskDeleteModal extends StatefulWidget {
  const TaskDeleteModal({super.key, required this.task, required this.api});
  final Map<String, dynamic> task;
  final SuperAdminApiService api;
  @override
  State<TaskDeleteModal> createState() => _TaskDeleteModalState();
}

class _TaskDeleteModalState extends State<TaskDeleteModal> {
  bool _saving = false;
  String? _error;
  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final message = await widget.api.deleteFarmTask('${widget.task[r'$id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 600 ||
        Theme.of(context).platform == TargetPlatform.android;
    TextStyle text(double size, {FontWeight weight = FontWeight.normal}) =>
        AppTypography.font(
            fontSize: size, fontWeight: weight, color: colors.onSurface);
    return PopScope(
        canPop: !_saving,
        child: CropVarietyModalFrame(
            mobile: mobile,
            isDark: Theme.of(context).brightness == Brightness.dark,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xff15803d)]),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Delete farm task',
                              style: text(16, weight: FontWeight.bold)),
                          Text('Administrator action', style: text(12))
                        ])),
                    IconButton(
                        tooltip: 'Close',
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 16))
                  ])),
              Flexible(
                  child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('${widget.task['title'] ?? 'Task'}',
                                style: text(12, weight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            Text(
                                'This permanently removes the task. Your account and the task details will be recorded in the audit logs.',
                                style: text(12)),
                            if (_error != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Text(_error!,
                                      style: text(12)
                                          .copyWith(color: colors.error))),
                          ]))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed:
                                _saving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: Text('Cancel', style: text(13)))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: FilledButton(
                            onPressed: _saving ? null : _submit,
                            style: FilledButton.styleFrom(
                                backgroundColor: colors.error,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_saving) ...[
                                    const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white)),
                                    const SizedBox(width: 8)
                                  ],
                                  Flexible(
                                      child: Text(
                                          _saving ? 'Deleting…' : 'Delete task',
                                          style: AppTypography.font(
                                              fontSize: 13,
                                              color: Colors.white))),
                                ]))),
                  ])),
            ])));
  }
}
