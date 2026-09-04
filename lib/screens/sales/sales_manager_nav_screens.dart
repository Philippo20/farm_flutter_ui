import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/sales_manager_screen_shell.dart';
import '../../core/widgets/sales_personnel_screen_shell.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

class SalesOffTakersScreen extends ConsumerStatefulWidget {
  final bool forSalesPersonnel;

  const SalesOffTakersScreen({
    super.key,
    this.forSalesPersonnel = false,
  });

  @override
  ConsumerState<SalesOffTakersScreen> createState() =>
      _SalesOffTakersScreenState();
}

class _SalesOffTakersScreenState extends ConsumerState<SalesOffTakersScreen> {
  final _api = SuperAdminApiService();
  List<Map<String, dynamic>> _offTakers = const [];
  List<Map<String, dynamic>> _updateRequests = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.getOffTakers();
      List<Map<String, dynamic>> requests = const [];
      try {
        requests = await _api.getOffTakerUpdateRequests();
      } catch (_) {
        // Buyer records remain usable if the optional approval feed is down.
      }
      if (!mounted) return;
      setState(() {
        _offTakers = items;
        _updateRequests = requests;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _reviewUpdate(
      Map<String, dynamic> request, String status) async {
    final user = ref.read(authProvider).user;
    try {
      await _api.reviewOffTakerUpdate(
        id: '${request['\$id'] ?? request['id'] ?? ''}',
        status: status,
        reviewedById: user?.id ?? '',
        reviewedByName: user?.name ?? 'Sales Manager',
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  List<Map<String, String>> _buildReviewChanges(
    Map<String, dynamic>? current,
    Map<String, dynamic> proposed,
    String Function(String) label,
  ) {
    const ignoredKeys = {'\$id', '\$createdAt', '\$updatedAt'};

    String display(Object? value) {
      if (value == null || '$value'.trim().isEmpty || value == 'null') {
        return 'Not set';
      }
      return '$value';
    }

    return proposed.entries
        .where((entry) => !ignoredKeys.contains(entry.key))
        .where((entry) {
          final oldValue = '${current?[entry.key] ?? ''}'.trim();
          final newValue = '${entry.value ?? ''}'.trim();
          return oldValue != newValue;
        })
        .map((entry) => {
              'label': label(entry.key),
              'oldValue': display(current?[entry.key]),
              'newValue': display(entry.value),
            })
        .toList();
  }

  Future<void> _showRequestDetails(
      Map<String, dynamic> request, Map<String, dynamic>? offTaker) async {
    if (MediaQuery.sizeOf(context).width < 600) {
      await _showRequestDetailsSheet(request, offTaker);
      return;
    }
    Map<String, dynamic> proposal = const {};
    try {
      final decoded = jsonDecode('${request['proposed_data'] ?? '{}'}');
      if (decoded is Map) proposal = Map<String, dynamic>.from(decoded);
    } catch (_) {
      proposal = const {};
    }

    String label(String key) => key
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');

    final changes = _buildReviewChanges(offTaker, proposal, label);
    var reviewing = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fact_check_outlined,
                          color: AppColors.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text('Review Off-Taker Update',
                            style: AppTypography.h5
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.lg),
                  Text('${offTaker?['name'] ?? 'Off-taker'}',
                      style: AppTypography.h6
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                      'Requested by ${request['requested_by_name'] ?? 'Sales Personnel'}',
                      style: AppTypography.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  _ReviewInfoBlock(
                    title: 'Reason for update',
                    value: '${request['reason'] ?? 'No reason provided'}',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Changed fields',
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.sm),
                  if (changes.isEmpty)
                    const _ReviewInfoBlock(
                      title: 'No differences detected',
                      value: 'The submitted values match the current record.',
                    )
                  else
                    ...changes
                        .map((change) => _ReviewChangeRow(change: change)),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: reviewing
                              ? null
                              : () async {
                                  setDialogState(() => reviewing = true);
                                  await _reviewUpdate(request, 'Rejected');
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                },
                          icon: reviewing
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.close, size: 17),
                          label: Text(reviewing ? 'Processing...' : 'Reject'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: reviewing
                              ? null
                              : () async {
                                  setDialogState(() => reviewing = true);
                                  await _reviewUpdate(request, 'Approved');
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                },
                          icon: reviewing
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check, size: 17),
                          label: Text(reviewing ? 'Processing...' : 'Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRequestDetailsSheet(
      Map<String, dynamic> request, Map<String, dynamic>? offTaker) async {
    Map<String, dynamic> proposal = const {};
    try {
      final decoded = jsonDecode('${request['proposed_data'] ?? '{}'}');
      if (decoded is Map) proposal = Map<String, dynamic>.from(decoded);
    } catch (_) {
      proposal = const {};
    }

    String label(String key) => key
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');

    final changes = _buildReviewChanges(offTaker, proposal, label);
    var reviewing = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.86,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(Icons.fact_check_outlined,
                          color: AppColors.warning),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Review change request',
                              style: AppTypography.h6
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text('Compare details before deciding',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${offTaker?['name'] ?? 'Off-taker'}',
                          style: AppTypography.h5
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                          'Requested by ${request['requested_by_name'] ?? 'Sales Personnel'}',
                          style: AppTypography.bodySmall),
                      const SizedBox(height: AppSpacing.md),
                      _ReviewInfoBlock(
                        title: 'Reason for update',
                        value: '${request['reason'] ?? 'No reason provided'}',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Changed fields',
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.sm),
                      if (changes.isEmpty)
                        const _ReviewInfoBlock(
                          title: 'No differences detected',
                          value:
                              'The submitted values match the current record.',
                        )
                      else
                        ...changes
                            .map((change) => _ReviewChangeRow(change: change)),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: reviewing
                              ? null
                              : () async {
                                  setSheetState(() => reviewing = true);
                                  await _reviewUpdate(request, 'Rejected');
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                },
                          icon: reviewing
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.close, size: 17),
                          label: Text(reviewing ? 'Processing...' : 'Reject'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: reviewing
                              ? null
                              : () async {
                                  setSheetState(() => reviewing = true);
                                  await _reviewUpdate(request, 'Approved');
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                },
                          icon: reviewing
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check, size: 17),
                          label: Text(reviewing ? 'Processing...' : 'Approve'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteOffTaker(Map<String, dynamic> item) async {
    final name = '${item['name'] ?? 'this off-taker'}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete off-taker?'),
        content:
            Text('This will permanently remove $name from the buyer list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline, size: 17),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteOffTaker('${item['\$id'] ?? item['id'] ?? ''}');
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _openAddForm({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: '${existing?['name'] ?? ''}');
    final type =
        TextEditingController(text: '${existing?['business_type'] ?? ''}');
    final contact =
        TextEditingController(text: '${existing?['contact_person'] ?? ''}');
    final phone = TextEditingController(text: '${existing?['phone'] ?? ''}');
    final email = TextEditingController(text: '${existing?['email'] ?? ''}');
    final location =
        TextEditingController(text: '${existing?['location'] ?? ''}');
    final notes = TextEditingController(text: '${existing?['notes'] ?? ''}');
    final reason = TextEditingController();
    var status = '${existing?['status'] ?? 'Active'}';
    var saving = false;
    String? formError;

    void disposeControllers() {
      name.dispose();
      type.dispose();
      contact.dispose();
      phone.dispose();
      email.dispose();
      location.dispose();
      notes.dispose();
      reason.dispose();
    }

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setModalState) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              height: MediaQuery.of(context).size.height * 0.86,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 24,
                      offset: Offset(0, 12)),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.75),
                            ]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.business_outlined,
                              size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isEdit ? 'Edit Off-Taker' : 'New Off-Taker',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : AppColors.textPrimary)),
                              Text(
                                  isEdit
                                      ? widget.forSalesPersonnel
                                          ? 'Submit changes for manager approval'
                                          : 'Update the buyer business record'
                                      : 'Create a separate buyer business record',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white38
                                          : AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: saving
                              ? null
                              : () => Navigator.pop(dialogContext, false),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 16,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white38
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _formField(
                              context,
                              name,
                              'Business name',
                              Icons.business_outlined,
                              required: true,
                            ),
                            _fieldPair(
                              context,
                              _formField(
                                context,
                                type,
                                'Business type',
                                Icons.category_outlined,
                              ),
                              _formField(
                                context,
                                contact,
                                'Contact person',
                                Icons.person_outline_rounded,
                              ),
                            ),
                            _fieldPair(
                              context,
                              _formField(
                                context,
                                phone,
                                'Phone number',
                                Icons.phone_outlined,
                                keyboard: TextInputType.phone,
                              ),
                              _formField(
                                context,
                                email,
                                'Email',
                                Icons.email_outlined,
                                keyboard: TextInputType.emailAddress,
                              ),
                            ),
                            _formField(
                              context,
                              location,
                              'Location',
                              Icons.location_on_outlined,
                            ),
                            _formField(
                              context,
                              notes,
                              'Notes',
                              Icons.notes_outlined,
                              maxLines: 3,
                            ),
                            if (isEdit && widget.forSalesPersonnel)
                              _formField(
                                context,
                                reason,
                                'Reason for update',
                                Icons.info_outline_rounded,
                                required: true,
                                maxLines: 3,
                              ),
                            _dialogLabel('Relationship status', context),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: status,
                              isExpanded: true,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                              dropdownColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.surfaceDark
                                  : Colors.white,
                              decoration: _dialogInputDecoration(context),
                              items: const ['Active', 'Prospect', 'Inactive']
                                  .map((item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(item),
                                      ))
                                  .toList(),
                              onChanged: (value) => setModalState(
                                () => status = value ?? 'Active',
                              ),
                            ),
                            if (formError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  formError!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving
                                ? null
                                : () => Navigator.pop(dialogContext, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              side: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.08)),
                            ),
                            child: Text('Cancel',
                                style: GoogleFonts.inter(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    if (!(formKey.currentState?.validate() ??
                                        false)) return;
                                    setModalState(() => saving = true);
                                    final userId =
                                        ref.read(authProvider).user?.id ?? '';
                                    final user = ref.read(authProvider).user;
                                    final payload = <String, dynamic>{
                                      'name': name.text,
                                      'business_type': type.text,
                                      'contact_person': contact.text,
                                      'phone': phone.text,
                                      'email': email.text,
                                      'location': location.text,
                                      'notes': notes.text,
                                      'status': status,
                                      'created_by': userId,
                                    };
                                    final requestReason = reason.text.trim();
                                    try {
                                      if (isEdit && widget.forSalesPersonnel) {
                                        await _api.requestOffTakerUpdate(data: {
                                          'off_taker_id':
                                              '${existing?['\$id'] ?? existing?['id'] ?? ''}',
                                          'proposed_data': jsonEncode(payload),
                                          'reason': requestReason,
                                          'requested_by_id': userId,
                                          'requested_by_name': user?.name ?? '',
                                        });
                                      } else if (isEdit) {
                                        await _api.updateOffTaker(
                                          id: '${existing?['\$id'] ?? existing?['id'] ?? ''}',
                                          data: payload,
                                        );
                                      } else {
                                        await _api.createOffTaker(
                                            data: payload);
                                      }
                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext, true);
                                      }
                                    } catch (error) {
                                      setModalState(() {
                                        saving = false;
                                        formError = error.toString();
                                      });
                                    }
                                  },
                            icon: saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              saving
                                  ? 'Saving...'
                                  : isEdit && widget.forSalesPersonnel
                                      ? 'Submit for Approval'
                                      : isEdit
                                          ? 'Update Off-Taker'
                                          : 'Save Off-Taker',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (saved == true) await _load();
    } finally {
      // Let the dialog route finish its final rebuild before disposing the
      // controllers still attached to its TextFormFields.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        disposeControllers();
      });
    }
  }

  Widget _formField(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dialogLabel(label, context),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white : AppColors.textPrimary),
            decoration: _dialogInputDecoration(context, icon: icon),
            validator: required
                ? (value) => value == null || value.trim().isEmpty
                    ? '$label is required'
                    : null
                : null,
          ),
        ],
      ),
    );
  }

  Widget _fieldPair(BuildContext context, Widget first, Widget second) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    if (!isDesktop) {
      return Column(
        children: [first, second],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
      ],
    );
  }

  Widget _dialogLabel(String label, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white54 : AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _dialogInputDecoration(BuildContext context,
      {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: 'Enter ${icon == Icons.notes_outlined ? 'notes' : 'value'}',
      hintStyle: GoogleFonts.inter(
          fontSize: 12,
          color: isDark ? Colors.white24 : AppColors.textSecondary),
      prefixIcon: icon == null
          ? null
          : Icon(icon,
              size: 16,
              color: isDark ? Colors.white24 : AppColors.textSecondary),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _offTakers
        .where(
            (item) => '${item['status'] ?? 'Active'}'.toLowerCase() == 'active')
        .length;
    final cards = _offTakers.map<Map<String, Object>>((item) {
      final status = '${item['status'] ?? 'Active'}';
      final color = status == 'Active'
          ? AppColors.success
          : status == 'Prospect'
              ? AppColors.primary
              : AppColors.warning;
      return {
        'title': '${item['name'] ?? 'Unnamed off-taker'}',
        'subtitle':
            '${item['business_type'] ?? 'Business'} | ${item['location'] ?? 'Location not set'}',
        'metric': '${item['contact_person'] ?? item['phone'] ?? 'No contact'}',
        'status': status,
        'color': color,
      };
    }).toList();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Hero(
          title: 'Off-Taker Management',
          subtitle:
              'Manage separate buyer accounts, relationship status, and sales contacts.',
          icon: Icons.people_outlined,
          colors: const [Color(0xFF1D4ED8), Color(0xFF0F766E)],
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _openAddForm,
            icon: const Icon(Icons.person_add_alt_outlined),
            label: const Text('Add Off-Taker'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _KpiCard(
                data: _KpiData(
                    'Active off-takers',
                    '$active',
                    'Separate business records',
                    Icons.people_outlined,
                    AppColors.primary)),
            _KpiCard(
                data: _KpiData(
                    'Total accounts',
                    '${_offTakers.length}',
                    'Registered buyers',
                    Icons.account_balance_wallet_outlined,
                    AppColors.success)),
            _KpiCard(
                data: _KpiData(
                    'Prospects',
                    '${_offTakers.where((item) => item['status'] == 'Prospect').length}',
                    'Potential accounts',
                    Icons.autorenew_outlined,
                    AppColors.warning)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (!widget.forSalesPersonnel &&
            _updateRequests.any((item) => item['status'] == 'Pending')) ...[
          Text('Pending Change Requests',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),
          ..._updateRequests
              .where((item) => item['status'] == 'Pending')
              .map((request) {
            final offTaker =
                _offTakers.cast<Map<String, dynamic>?>().firstWhere(
                      (item) =>
                          '${item?['\$id'] ?? item?['id'] ?? ''}' ==
                          '${request['off_taker_id'] ?? ''}',
                      orElse: () => null,
                    );
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.warning.withOpacity(0.35)),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: InkWell(
                  onTap: () => _showRequestDetails(request, offTaker),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${offTaker?['name'] ?? 'Off-taker update'}',
                            style: AppTypography.h6
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                            'Requested by ${request['requested_by_name'] ?? 'Sales personnel'}',
                            style: AppTypography.bodySmall),
                        const SizedBox(height: 6),
                        Text(
                            'Reason: ${request['reason'] ?? 'No reason provided'}',
                            style: AppTypography.bodySmall),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _reviewUpdate(request, 'Rejected'),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () =>
                                    _reviewUpdate(request, 'Approved'),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
        ],
        Text('Buyer Accounts',
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.md),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Text('Could not load off-takers. Please retry from the dashboard.',
              style: AppTypography.bodyMedium)
        else if (cards.isEmpty)
          const _EmptySalesState(
              label: 'No off-takers have been registered yet.')
        else
          _ResponsiveGrid(
              itemCount: cards.length,
              itemBuilder: (index) => _OffTakerCard(
                    item: _offTakers[index],
                    isSalesPersonnel: widget.forSalesPersonnel,
                    hasPendingUpdate: _updateRequests.any(
                      (request) =>
                          request['status'] == 'Pending' &&
                          '${request['off_taker_id'] ?? ''}' ==
                              '${_offTakers[index]['\$id'] ?? _offTakers[index]['id'] ?? ''}',
                    ),
                    onEdit: () => _openAddForm(existing: _offTakers[index]),
                    onDelete: () => _deleteOffTaker(_offTakers[index]),
                  )),
      ],
    );

    if (widget.forSalesPersonnel) {
      return SalesPersonnelScreenShell(selectedIndex: 2, child: content);
    }
    return SalesManagerScreenShell(selectedIndex: 1, child: content);
  }
}

class _EmptySalesState extends StatelessWidget {
  final String label;

  const _EmptySalesState({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(child: Text(label)),
      );
}

class _ReviewChangeRow extends StatelessWidget {
  final Map<String, String> change;

  const _ReviewChangeRow({required this.change});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warning = isDark ? Colors.amber.shade300 : AppColors.warning;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: warning.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: warning.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(change['label'] ?? 'Changed field',
              style: AppTypography.bodySmall
                  .copyWith(color: warning, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(change['oldValue'] ?? 'Not set',
                    style: AppTypography.bodyMedium.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child:
                    Icon(Icons.arrow_forward_rounded, size: 18, color: warning),
              ),
              Expanded(
                child: Text(change['newValue'] ?? 'Not set',
                    style: AppTypography.bodyMedium.copyWith(
                        color: textColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewInfoBlock extends StatelessWidget {
  final String title;
  final String value;

  const _ReviewInfoBlock({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value,
              style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _OffTakerCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSalesPersonnel;
  final bool hasPendingUpdate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OffTakerCard({
    required this.item,
    required this.isSalesPersonnel,
    required this.hasPendingUpdate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = '${item['status'] ?? 'Active'}';
    final statusColor = status == 'Active'
        ? AppColors.success
        : status == 'Prospect'
            ? AppColors.primary
            : AppColors.warning;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryColor = isDark ? Colors.white70 : AppColors.textSecondary;

    Widget detail(IconData icon, String value) {
      if (value.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: secondaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(color: secondaryColor),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: statusColor.withOpacity(isDark ? 0.3 : 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(icon: Icons.business_outlined, color: statusColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['name'] ?? 'Unnamed off-taker'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h6.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item['business_type'] ?? 'Business type not set'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall
                          .copyWith(color: secondaryColor),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: status, color: statusColor),
              if (hasPendingUpdate)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_top_rounded,
                          size: 13, color: AppColors.warning),
                      SizedBox(width: 4),
                      Text('Pending',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          detail(Icons.person_outline, '${item['contact_person'] ?? ''}'),
          detail(Icons.phone_outlined, '${item['phone'] ?? ''}'),
          detail(Icons.email_outlined, '${item['email'] ?? ''}'),
          detail(Icons.location_on_outlined, '${item['location'] ?? ''}'),
          const Spacer(),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(isSalesPersonnel ? 'Request Update' : 'Edit'),
                ),
              ),
              if (!isSalesPersonnel) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete off-taker',
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class SalesPerformanceScreen extends StatelessWidget {
  const SalesPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SalesManagerDataPage(
        kind: _SalesManagerPageKind.performance,
        selectedIndex: 2,
      );
}

class SalesDeliveriesScreen extends ConsumerStatefulWidget {
  const SalesDeliveriesScreen({super.key});

  @override
  ConsumerState<SalesDeliveriesScreen> createState() =>
      _SalesDeliveriesScreenState();
}

class _SalesDeliveriesScreenState extends ConsumerState<SalesDeliveriesScreen> {
  final _api = SuperAdminApiService();
  List<Map<String, dynamic>> _sales = const [];
  List<Map<String, dynamic>> _offTakers = const [];
  List<Map<String, dynamic>> _fulfillments = const [];
  List<Map<String, dynamic>> _pricing = const [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _status = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _text(Map<String, dynamic> item, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    return fallback;
  }

  double _number(Map<String, dynamic> item, List<String> keys) =>
      double.tryParse(_text(item, keys).replaceAll(',', '')) ?? 0;

  int _packs(Map<String, dynamic> item, List<String> keys) =>
      _number(item, keys).round().clamp(0, 1 << 31);

  String _id(Map<String, dynamic> item) =>
      _text(item, [r'$id', 'id', 'fulfillment_id']);

  String _batch(Map<String, dynamic> item) =>
      _text(item, ['batch_number', 'batch_id']);

  bool _matchesBatch(
    Map<String, dynamic> sale,
    Map<String, dynamic> fulfillment,
  ) {
    final saleFulfillment = _text(sale, ['fulfillment_id']).toLowerCase();
    if (saleFulfillment.isNotEmpty &&
        saleFulfillment == _id(fulfillment).toLowerCase()) {
      return true;
    }
    return _batch(sale).toLowerCase() == _batch(fulfillment).toLowerCase();
  }

  int _allocatedPacks(Map<String, dynamic> fulfillment,
      {String excludeSaleId = ''}) {
    return _sales.where((sale) {
      if (_id(sale) == excludeSaleId) return false;
      if (_text(sale, ['status']).toLowerCase() == 'cancelled') return false;
      return _matchesBatch(sale, fulfillment);
    }).fold<int>(
      0,
      (sum, sale) => sum + _packs(sale, ['package_count']),
    );
  }

  int _totalPacks(Map<String, dynamic> fulfillment) {
    final recorded = _packs(fulfillment, ['total_package_count']);
    if (recorded > 0) return recorded;
    final unit = _number(fulfillment, ['packaging_weight']);
    return unit <= 0
        ? 0
        : (_number(fulfillment, ['total_packaged_weight']) / unit).round();
  }

  int _availablePacks(Map<String, dynamic> fulfillment) =>
      (_totalPacks(fulfillment) - _allocatedPacks(fulfillment))
          .clamp(0, 1 << 31);

  List<Map<String, dynamic>> get _releasedBatches {
    final batches = _fulfillments.where((item) {
      return _text(item, ['status']).toLowerCase() == 'sent to sales' &&
          _text(item, ['quality_status']).toLowerCase() == 'approved';
    }).toList();
    batches.sort((a, b) => _batch(a).compareTo(_batch(b)));
    return batches;
  }

  List<Map<String, dynamic>> get _activeOffTakers => _offTakers
      .where((item) =>
          _text(item, ['status'], fallback: 'Active').toLowerCase() == 'active')
      .toList();

  List<Map<String, dynamic>> get _filteredSales {
    final query = _search.trim().toLowerCase();
    final records = _sales.where((sale) {
      final statusMatches = _status == 'All' ||
          _text(sale, ['status'], fallback: 'Pending') == _status;
      final queryMatches = query.isEmpty ||
          [
            _batch(sale),
            _text(sale, ['buyer_name']),
            _text(sale, ['crop_variety']),
            _text(sale, ['package_type']),
          ].any((value) => value.toLowerCase().contains(query));
      return statusMatches && queryMatches;
    }).toList();
    records.sort((a, b) => _deliveryDate(b).compareTo(_deliveryDate(a)));
    return records;
  }

  DateTime _deliveryDate(Map<String, dynamic> item) =>
      DateTime.tryParse(
          _text(item, ['scheduled_for', 'delivered_at', r'$createdAt'])) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  String _dateLabel(Map<String, dynamic> item) {
    final date = _deliveryDate(item).toLocal();
    if (date.year == 1970) return 'Not scheduled';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await Future.wait<List<Map<String, dynamic>>>([
        _api.getSales(),
        _api.getOffTakers(),
        _api.getFulfillments(),
        _api.getPricing(),
      ]);
      if (!mounted) return;
      setState(() {
        _sales = result[0];
        _offTakers = result[1];
        _fulfillments = result[2];
        _pricing = result[3];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _openEditor({
    Map<String, dynamic>? fulfillment,
    Map<String, dynamic>? sale,
  }) async {
    final modal = _SalesDeliveryEditor(
      api: _api,
      batches: _releasedBatches,
      offTakers: _activeOffTakers,
      sales: _sales,
      pricing: _pricing,
      initialFulfillment: fulfillment,
      sale: sale,
      currentUserId: ref.read(authProvider).user?.id ?? 'sales-manager',
      currentUserName: ref.read(authProvider).user?.name ?? 'Sales Manager',
    );
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final changed = mobile
        ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => modal,
          )
        : await showDialog<bool>(context: context, builder: (_) => modal);
    if (changed == true) await _load();
  }

  Future<void> _delete(Map<String, dynamic> sale) async {
    var deleting = false;
    String? modalError;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final content = StatefulBuilder(builder: (dialogContext, setModalState) {
      return Material(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(20),
          bottom: Radius.circular(mobile ? 0 : 20),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Delete Delivery',
                        style: AppTypography.titleMedium),
                  ),
                  IconButton(
                    onPressed:
                        deleting ? null : () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ]),
                const SizedBox(height: 16),
                Text(
                  'Delete the ${_batch(sale)} allocation for ${_text(sale, [
                        'buyer_name'
                      ], fallback: 'this off-taker')}? The allocated packs will become available again.',
                  style: AppTypography.bodyMedium,
                ),
                if (modalError != null) ...[
                  const SizedBox(height: 12),
                  _SalesDeliveryError(message: modalError!),
                ],
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          deleting ? null : () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: deleting
                          ? null
                          : () async {
                              setModalState(() => deleting = true);
                              try {
                                await _api.deleteSale(_id(sale));
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext, true);
                                }
                              } catch (error) {
                                setModalState(() {
                                  deleting = false;
                                  modalError = error.toString();
                                });
                              }
                            },
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error),
                      icon: deleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.delete_outline, size: 18),
                      label: Text(deleting ? 'Deleting...' : 'Delete'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      );
    });
    final changed = mobile
        ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => content,
          )
        : await showDialog<bool>(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: content,
              ),
            ),
          );
    if (changed == true) await _load();
  }

  Widget _responsiveCards(
    List<Widget> cards, {
    double desktopWidth = 340,
  }) {
    return LayoutBuilder(builder: (_, constraints) {
      final width = constraints.maxWidth < 600
          ? constraints.maxWidth
          : constraints.maxWidth < 1000
              ? (constraints.maxWidth - AppSpacing.md) / 2
              : desktopWidth;
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children:
            cards.map((card) => SizedBox(width: width, child: card)).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pending = _sales
        .where(
            (item) => _text(item, ['status'], fallback: 'Pending') == 'Pending')
        .length;
    final delivered =
        _sales.where((item) => _text(item, ['status']) == 'Delivered').length;
    final availablePacks = _releasedBatches.fold<int>(
      0,
      (sum, item) => sum + _availablePacks(item),
    );

    return SalesManagerScreenShell(
      selectedIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SalesDeliveryHero(onCreate: () => _openEditor()),
          const SizedBox(height: AppSpacing.lg),
          if (_loading)
            const AdminDataSkeleton(rowCount: 5)
          else if (_error != null)
            _SalesDeliveryLoadError(message: _error!, onRetry: _load)
          else ...[
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _KpiCard(
                  data: _KpiData(
                      'Available packs',
                      '$availablePacks',
                      '${_releasedBatches.length} QA-approved batches',
                      Icons.inventory_2_outlined,
                      AppColors.primary),
                ),
                _KpiCard(
                  data: _KpiData(
                      'Scheduled',
                      '$pending',
                      'Awaiting delivery completion',
                      Icons.schedule_outlined,
                      AppColors.warning),
                ),
                _KpiCard(
                  data: _KpiData(
                      'Delivered',
                      '$delivered',
                      '${_sales.length} total delivery records',
                      Icons.task_alt_outlined,
                      AppColors.success),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SalesSectionHeader(
              icon: Icons.verified_outlined,
              title: 'QA-Approved Batch Inventory',
              subtitle: 'Allocate available packs to an active off-taker.',
              trailing: Text('$availablePacks packs available',
                  style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_releasedBatches.isEmpty)
              const _SalesDeliveryEmpty(
                icon: Icons.inventory_2_outlined,
                title: 'No batches released by QA',
                message:
                    'Approved packaging batches will appear here automatically.',
              )
            else
              _responsiveCards(
                _releasedBatches
                    .map((batch) => _SalesBatchAllocationCard(
                          batch: batch,
                          totalPacks: _totalPacks(batch),
                          allocatedPacks: _allocatedPacks(batch),
                          availablePacks: _availablePacks(batch),
                          onAllocate: _availablePacks(batch) > 0
                              ? () => _openEditor(fulfillment: batch)
                              : null,
                        ))
                    .toList(),
              ),
            const SizedBox(height: AppSpacing.xl),
            _SalesSectionHeader(
              icon: Icons.local_shipping_outlined,
              title: 'Delivery Records',
              subtitle: 'Track allocations, payment state, and completion.',
              trailing: IconButton(
                tooltip: 'Refresh deliveries',
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(builder: (_, constraints) {
              final filters = ['All', 'Pending', 'Delivered', 'Cancelled'];
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width:
                        constraints.maxWidth < 600 ? constraints.maxWidth : 320,
                    child: TextField(
                      onChanged: (value) => setState(() => _search = value),
                      decoration: InputDecoration(
                        hintText: 'Search batch, off-taker or crop...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: dark
                            ? Colors.white.withValues(alpha: .04)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color:
                                  dark ? Colors.white10 : AppColors.neutral200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color:
                                  dark ? Colors.white10 : AppColors.neutral200),
                        ),
                      ),
                    ),
                  ),
                  ...filters.map((filter) => ChoiceChip(
                        label: Text(filter),
                        selected: _status == filter,
                        onSelected: (_) => setState(() => _status = filter),
                      )),
                ],
              );
            }),
            const SizedBox(height: AppSpacing.md),
            if (_filteredSales.isEmpty)
              const _SalesDeliveryEmpty(
                icon: Icons.local_shipping_outlined,
                title: 'No delivery records found',
                message: 'Allocate a QA-approved batch to create a delivery.',
              )
            else
              _responsiveCards(
                _filteredSales
                    .map((sale) => _SalesDeliveryRecordCard(
                          sale: sale,
                          dateLabel: _dateLabel(sale),
                          onEdit: () => _openEditor(sale: sale),
                          onDelete: () => _delete(sale),
                        ))
                    .toList(),
              ),
          ],
        ],
      ),
    );
  }
}

class _SalesDeliveryHero extends StatelessWidget {
  const _SalesDeliveryHero({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? AppSpacing.md : AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF334155), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _icon(),
                const SizedBox(height: 14),
                _copy(),
                const SizedBox(height: 18),
                _action(),
              ],
            )
          : Row(
              children: [
                _icon(),
                const SizedBox(width: 16),
                Expanded(child: _copy()),
                const SizedBox(width: 20),
                _action(),
              ],
            ),
    );
  }

  Widget _icon() => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.local_shipping_outlined,
            color: Colors.white, size: 26),
      );

  Widget _copy() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sales Delivery Control',
              style: AppTypography.h4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 5),
          Text(
            'Allocate QA-approved packs to off-takers and control every delivery through completion.',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: .76),
            ),
          ),
        ],
      );

  Widget _action() => FilledButton.icon(
        onPressed: onCreate,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1D4ED8),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.add_circle_outline, size: 19),
        label: const Text('Allocate Delivery'),
      );
}

class _SalesSectionHeader extends StatelessWidget {
  const _SalesSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final iconTile = Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: AppColors.primary, size: 19),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTypography.titleMedium.copyWith(
              color: dark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            )),
        Text(subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: dark ? Colors.white60 : AppColors.textSecondary,
            )),
      ],
    );
    return LayoutBuilder(builder: (_, constraints) {
      if (constraints.maxWidth < 480) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              iconTile,
              const SizedBox(width: 11),
              Expanded(child: copy),
            ]),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: trailing),
          ],
        );
      }
      return Row(children: [
        iconTile,
        const SizedBox(width: 11),
        Expanded(child: copy),
        const SizedBox(width: 10),
        trailing,
      ]);
    });
  }
}

class _SalesDeliveryMetric extends StatelessWidget {
  const _SalesDeliveryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: dark ? Colors.white54 : AppColors.textSecondary,
            )),
        const SizedBox(height: 3),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

class _SalesBatchAllocationCard extends StatelessWidget {
  const _SalesBatchAllocationCard({
    required this.batch,
    required this.totalPacks,
    required this.allocatedPacks,
    required this.availablePacks,
    required this.onAllocate,
  });

  final Map<String, dynamic> batch;
  final int totalPacks;
  final int allocatedPacks;
  final int availablePacks;
  final VoidCallback? onAllocate;

  String _value(List<String> keys, [String fallback = 'Not set']) {
    for (final key in keys) {
      final value = batch[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    return fallback;
  }

  double _number(String key) => double.tryParse('${batch[key] ?? 0}') ?? 0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final unitWeight = _number('packaging_weight');
    final progress = totalPacks == 0 ? 0.0 : allocatedPacks / totalPacks;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: availablePacks > 0
              ? AppColors.primary.withValues(alpha: .18)
              : (dark ? Colors.white10 : AppColors.neutral200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _IconBox(icon: Icons.qr_code_2_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_value(['batch_number']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    '${_value(['plant_variety', 'plant_type'])} | ${_value([
                          'farm_name'
                        ], 'Farm')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                        color: dark ? Colors.white60 : AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            _StatusBadge(
              label: availablePacks > 0 ? 'Available' : 'Allocated',
              color: availablePacks > 0
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(
                child: _SalesDeliveryMetric(
                    label: 'Available', value: '$availablePacks packs')),
            Expanded(
                child: _SalesDeliveryMetric(
                    label: 'Weight',
                    value:
                        '${(availablePacks * unitWeight).toStringAsFixed(2)} kg')),
            Expanded(
                child: _SalesDeliveryMetric(
                    label: 'Package', value: _value(['packaging_type']))),
          ]),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress.clamp(0, 1),
              backgroundColor: dark ? Colors.white10 : AppColors.neutral200,
              color: availablePacks > 0 ? AppColors.primary : AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAllocate,
              icon: Icon(
                  onAllocate == null
                      ? Icons.check_circle_outline
                      : Icons.local_shipping_outlined,
                  size: 18),
              label: Text(onAllocate == null
                  ? 'No packs available'
                  : 'Allocate to Off-taker'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesDeliveryRecordCard extends StatelessWidget {
  const _SalesDeliveryRecordCard({
    required this.sale,
    required this.dateLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> sale;
  final String dateLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _value(List<String> keys, [String fallback = 'Not set']) {
    for (final key in keys) {
      final value = sale[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final status = _value(['status'], 'Pending');
    final color = status == 'Delivered'
        ? AppColors.success
        : status == 'Cancelled'
            ? AppColors.error
            : AppColors.warning;
    final weight = double.tryParse(_value(['quantity_delivered'], '0')) ?? 0;
    final amount = double.tryParse(_value(['total_amount'], '0')) ?? 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: dark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: color.withValues(alpha: .18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _IconBox(icon: Icons.local_shipping_outlined, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_value(['buyer_name'], 'Off-taker'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text(
                          '${_value([
                                'batch_number',
                                'batch_id'
                              ])} | $dateLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                              color: dark
                                  ? Colors.white60
                                  : AppColors.textSecondary)),
                    ],
                  ),
                ),
                _StatusBadge(label: status, color: color),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(
                    child: _SalesDeliveryMetric(
                        label: 'Packs', value: _value(['package_count'], '0'))),
                Expanded(
                    child: _SalesDeliveryMetric(
                        label: 'Weight',
                        value: '${weight.toStringAsFixed(2)} kg')),
                Expanded(
                    child: _SalesDeliveryMetric(
                        label: 'Amount',
                        value: 'GHS ${amount.toStringAsFixed(2)}')),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(
                  child: Text(
                    '${_value(['crop_variety'], 'Crop')} | ${_value([
                          'package_type'
                        ], 'Package')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                        color: dark ? Colors.white60 : AppColors.textSecondary),
                  ),
                ),
                IconButton(
                  tooltip: 'Edit delivery',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),
                IconButton(
                  tooltip: 'Delete delivery',
                  onPressed: onDelete,
                  color: AppColors.error,
                  icon: const Icon(Icons.delete_outline, size: 19),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesDeliveryEditor extends StatefulWidget {
  const _SalesDeliveryEditor({
    required this.api,
    required this.batches,
    required this.offTakers,
    required this.sales,
    required this.pricing,
    required this.currentUserId,
    required this.currentUserName,
    this.initialFulfillment,
    this.sale,
  });

  final SuperAdminApiService api;
  final List<Map<String, dynamic>> batches;
  final List<Map<String, dynamic>> offTakers;
  final List<Map<String, dynamic>> sales;
  final List<Map<String, dynamic>> pricing;
  final String currentUserId;
  final String currentUserName;
  final Map<String, dynamic>? initialFulfillment;
  final Map<String, dynamic>? sale;

  @override
  State<_SalesDeliveryEditor> createState() => _SalesDeliveryEditorState();
}

class _SalesDeliveryEditorState extends State<_SalesDeliveryEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _packsController;
  late final TextEditingController _addressController;
  late final TextEditingController _receiptController;
  late final TextEditingController _notesController;
  String? _batchId;
  String? _offTakerId;
  String? _pricingId;
  String _priceTier = 'Regular';
  String _paymentMode = 'Bank Transfer';
  String _status = 'Pending';
  bool _paid = false;
  bool _saving = false;
  String? _error;
  late DateTime _scheduledDate;

  bool get _editing => widget.sale != null;

  String _id(Map<String, dynamic> item) =>
      '${item[r'$id'] ?? item['id'] ?? item['fulfillment_id'] ?? ''}'.trim();

  String _text(Map<String, dynamic>? item, List<String> keys,
      [String fallback = '']) {
    if (item == null) return fallback;
    for (final key in keys) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    return fallback;
  }

  double _number(Map<String, dynamic>? item, List<String> keys) =>
      double.tryParse(_text(item, keys, '0')) ?? 0;

  Map<String, dynamic>? get _selectedBatch {
    for (final item in widget.batches) {
      if (_id(item) == _batchId) return item;
    }
    return null;
  }

  Map<String, dynamic>? get _selectedOffTaker {
    for (final item in widget.offTakers) {
      if (_id(item) == _offTakerId) return item;
    }
    return null;
  }

  String _catalogKey(dynamic value) =>
      value.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

  bool _priceMatchesBatch(
    Map<String, dynamic> pricing,
    Map<String, dynamic> batch,
  ) {
    if (_text(pricing, ['pricing_type']).toLowerCase() != 'hub_sale' ||
        _text(pricing, ['status'], 'Active').toLowerCase() != 'active') {
      return false;
    }
    final variety = _catalogKey(_text(batch, ['plant_variety', 'plant_type']));
    final pricedVariety = _catalogKey(_text(pricing, ['crop_variety']));
    final package = _catalogKey(_text(batch, ['packaging_type']));
    final pricedPackage = _catalogKey(_text(pricing, ['packaging']));
    return variety.isNotEmpty &&
        variety == pricedVariety &&
        package.isNotEmpty &&
        pricedPackage.isNotEmpty &&
        (package == pricedPackage ||
            package.contains(pricedPackage) ||
            pricedPackage.contains(package));
  }

  List<Map<String, dynamic>> get _matchingPrices {
    final batch = _selectedBatch;
    if (batch == null) return const [];
    return widget.pricing
        .where((price) => _priceMatchesBatch(price, batch))
        .toList();
  }

  Map<String, dynamic>? get _selectedPricing {
    for (final price in _matchingPrices) {
      if (_id(price) == _pricingId) return price;
    }
    return null;
  }

  double get _unitPrice => _number(
        _selectedPricing,
        [_priceTier == 'Bulk' ? 'bulk_price' : 'regular_price'],
      );

  double get _totalAmount => _requestedPacks * _unitPrice;

  void _selectDefaultPrice({String? preferredId}) {
    final prices = _matchingPrices;
    if (preferredId != null &&
        prices.any((price) => _id(price) == preferredId)) {
      _pricingId = preferredId;
    } else {
      _pricingId = prices.isEmpty ? null : _id(prices.first);
    }
  }

  int _totalPacks(Map<String, dynamic> batch) {
    final count = _number(batch, ['total_package_count']).round();
    if (count > 0) return count;
    final unit = _number(batch, ['packaging_weight']);
    return unit <= 0
        ? 0
        : (_number(batch, ['total_packaged_weight']) / unit).round();
  }

  bool _sameBatch(Map<String, dynamic> sale, Map<String, dynamic> batch) {
    final fulfillmentId = _text(sale, ['fulfillment_id']).toLowerCase();
    if (fulfillmentId.isNotEmpty && fulfillmentId == _id(batch).toLowerCase()) {
      return true;
    }
    return _text(sale, ['batch_number', 'batch_id']).toLowerCase() ==
        _text(batch, ['batch_number']).toLowerCase();
  }

  int get _availablePacks {
    final batch = _selectedBatch;
    if (batch == null) return 0;
    final currentId = widget.sale == null ? '' : _id(widget.sale!);
    final allocated = widget.sales.where((sale) {
      if (_id(sale) == currentId) return false;
      if (_text(sale, ['status']).toLowerCase() == 'cancelled') return false;
      return _sameBatch(sale, batch);
    }).fold<int>(
      0,
      (sum, sale) => sum + _number(sale, ['package_count']).round(),
    );
    return (_totalPacks(batch) - allocated).clamp(0, 1 << 31);
  }

  double get _unitWeight => _number(_selectedBatch, ['packaging_weight']);
  int get _requestedPacks => int.tryParse(_packsController.text.trim()) ?? 0;
  double get _allocatedWeight => _requestedPacks * _unitWeight;

  @override
  void initState() {
    super.initState();
    final sale = widget.sale;
    Map<String, dynamic>? initial = widget.initialFulfillment;
    if (sale != null) {
      for (final batch in widget.batches) {
        if (_sameBatch(sale, batch)) {
          initial = batch;
          break;
        }
      }
    }
    _batchId = initial == null ? null : _id(initial);
    final buyerId = _text(sale, ['off_taker_id', 'buyer_id']);
    _offTakerId =
        widget.offTakers.any((item) => _id(item) == buyerId) ? buyerId : null;
    _packsController =
        TextEditingController(text: _text(sale, ['package_count'], ''));
    _addressController =
        TextEditingController(text: _text(sale, ['delivery_address'], ''));
    _receiptController =
        TextEditingController(text: _text(sale, ['receipt_number'], ''));
    _notesController =
        TextEditingController(text: _text(sale, ['delivery_notes'], ''));
    _paymentMode = _text(sale, ['payment_mode'], 'Bank Transfer');
    _status = _text(sale, ['status'], 'Pending');
    _priceTier = _text(sale, ['price_tier'], 'Regular');
    if (!const ['Regular', 'Bulk'].contains(_priceTier)) {
      _priceTier = 'Regular';
    }
    _selectDefaultPrice(preferredId: _text(sale, ['pricing_id']));
    if (!const ['Bank Transfer', 'Mobile Money', 'Cash', 'Credit']
        .contains(_paymentMode)) {
      _paymentMode = 'Bank Transfer';
    }
    if (!const ['Pending', 'Delivered', 'Cancelled'].contains(_status)) {
      _status = 'Pending';
    }
    _paid = sale?['paid'] == true;
    _scheduledDate = DateTime.tryParse(_text(sale, ['scheduled_for'])) ??
        DateTime.tryParse(_text(sale, ['delivered_at'])) ??
        DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _packsController.dispose();
    _addressController.dispose();
    _receiptController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected != null && mounted) {
      setState(() => _scheduledDate = selected);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final batch = _selectedBatch;
    final buyer = _selectedOffTaker;
    if (batch == null || buyer == null) {
      setState(
          () => _error = 'Select a QA-approved batch and an active off-taker.');
      return;
    }
    final pricing = _selectedPricing;
    if (pricing == null || _unitPrice <= 0) {
      setState(() => _error =
          'Configure and select an active Hub sale price for this crop variety and package.');
      return;
    }
    if (_requestedPacks > _availablePacks) {
      setState(() =>
          _error = 'Only $_availablePacks packs are available for allocation.');
      return;
    }
    setState(() => _saving = true);
    final dateTime = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      12,
    );
    final date = dateTime.toIso8601String().split('T').first;
    final payload = <String, dynamic>{
      'batch_id': _id(batch),
      'batch_number': _text(batch, ['batch_number']),
      'fulfillment_id': _id(batch),
      'buyer_id': _id(buyer),
      'off_taker_id': _id(buyer),
      'buyer_name': _text(buyer, ['name'], 'Off-taker'),
      'delivered_by': widget.currentUserName,
      'delivered_at': dateTime.toIso8601String(),
      'scheduled_for': dateTime.toIso8601String(),
      'quantity_delivered': _allocatedWeight,
      'package_count': _requestedPacks,
      'pricing_id': _id(pricing),
      'price_tier': _priceTier,
      'unit_price': _unitPrice,
      'total_amount': _totalAmount,
      'paid': _paid,
      'payment_mode': _paymentMode,
      'receipt_image': _text(widget.sale, ['receipt_image']),
      'receipt_number': _receiptController.text.trim(),
      'payment_date': date,
      'created_by': _editing
          ? _text(widget.sale, ['created_by'], widget.currentUserId)
          : widget.currentUserId,
      'created_by_role': 'sales_manager',
      'status': _status,
      'delivery_address': _addressController.text.trim(),
      'delivery_notes': _notesController.text.trim(),
    };
    try {
      if (_editing) {
        await widget.api.updateSale(_id(widget.sale!), payload);
      } else {
        await widget.api.createSale(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor:
          dark ? Colors.white.withValues(alpha: .04) : AppColors.neutral50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: dark ? Colors.white10 : AppColors.neutral200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = Material(
      color: dark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(20),
        bottom: Radius.circular(mobile ? 0 : 20),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.sizeOf(context).height * (mobile ? .95 : .9),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mobile) ...[
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: dark ? Colors.white24 : AppColors.neutral300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_shipping_outlined,
                      color: AppColors.primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_editing ? 'Update Delivery' : 'Allocate Delivery',
                          style: AppTypography.titleLarge
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text('Assign verified packs to an off-taker',
                          style: AppTypography.bodySmall.copyWith(
                              color: dark
                                  ? Colors.white60
                                  : AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ]),
            ),
            Divider(
                height: 1, color: dark ? Colors.white10 : AppColors.neutral200),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(builder: (_, constraints) {
                    final fieldWidth = constraints.maxWidth < 620
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 14) / 2;
                    Widget sized(Widget child, {bool full = false}) => SizedBox(
                          width: full ? constraints.maxWidth : fieldWidth,
                          child: child,
                        );
                    return Wrap(
                      spacing: 14,
                      runSpacing: 16,
                      children: [
                        if (widget.batches.isEmpty)
                          sized(
                              const _SalesDeliveryError(
                                  message:
                                      'No QA-approved batch is available for allocation.'),
                              full: true),
                        if (widget.offTakers.isEmpty)
                          sized(
                              const _SalesDeliveryError(
                                  message:
                                      'Create or activate an off-taker before scheduling a delivery.'),
                              full: true),
                        if (_error != null)
                          sized(_SalesDeliveryError(message: _error!),
                              full: true),
                        sized(DropdownButtonFormField<String>(
                          initialValue: _batchId,
                          isExpanded: true,
                          decoration: _decoration(
                              'QA-approved batch', Icons.qr_code_2_rounded),
                          items: widget.batches
                              .map((batch) => DropdownMenuItem(
                                    value: _id(batch),
                                    child: Text(
                                      '${_text(batch, [
                                            'batch_number'
                                          ])} - ${_text(batch, [
                                            'plant_variety',
                                            'plant_type'
                                          ])}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() {
                                    _batchId = value;
                                    _packsController.clear();
                                    _selectDefaultPrice();
                                  }),
                          validator: (value) => value == null
                              ? 'Select a batch released by QA.'
                              : null,
                        )),
                        sized(DropdownButtonFormField<String>(
                          initialValue: _offTakerId,
                          isExpanded: true,
                          decoration:
                              _decoration('Off-taker', Icons.business_outlined),
                          items: widget.offTakers
                              .map((buyer) => DropdownMenuItem(
                                    value: _id(buyer),
                                    child: Text(
                                        _text(buyer, ['name'], 'Off-taker'),
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() {
                                    _offTakerId = value;
                                    final buyer = _selectedOffTaker;
                                    if (buyer != null) {
                                      _addressController.text =
                                          _text(buyer, ['location']);
                                    }
                                  }),
                          validator: (value) => value == null
                              ? 'Select an active off-taker.'
                              : null,
                        )),
                        if (_selectedBatch != null)
                          sized(
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: .07),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: .16)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.inventory_2_outlined,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '$_availablePacks packs available\n${_unitWeight.toStringAsFixed(3)} kg per pack',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ),
                                ]),
                              ),
                              full: true),
                        if (_selectedBatch != null && _matchingPrices.isEmpty)
                          sized(
                            const _SalesDeliveryError(
                              message:
                                  'No active Hub sale price matches this crop variety and package. Add one from Sales Pricing first.',
                            ),
                            full: true,
                          ),
                        sized(DropdownButtonFormField<String>(
                          key: ValueKey('pricing-$_batchId-$_pricingId'),
                          initialValue: _pricingId,
                          isExpanded: true,
                          decoration: _decoration(
                              'Sales pricing', Icons.price_change_outlined),
                          items: _matchingPrices
                              .map((price) => DropdownMenuItem(
                                    value: _id(price),
                                    child: Text(
                                      '${_text(price, [
                                            'crop_variety'
                                          ])} - ${_text(price, ['packaging'])}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _pricingId = value),
                          validator: (value) => value == null
                              ? 'Select the approved price for these packs.'
                              : null,
                        )),
                        sized(DropdownButtonFormField<String>(
                          initialValue: _priceTier,
                          decoration: _decoration(
                              'Price tier', Icons.local_offer_outlined),
                          items: const ['Regular', 'Bulk']
                              .map((tier) => DropdownMenuItem(
                                  value: tier, child: Text(tier)))
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _priceTier = value!),
                        )),
                        sized(TextFormField(
                          controller: _packsController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: _decoration(
                              'Number of packs', Icons.inventory_2_outlined,
                              hint: 'e.g. 120'),
                          validator: (value) {
                            final count = int.tryParse(value?.trim() ?? '');
                            if (count == null || count <= 0) {
                              return 'Enter at least one pack.';
                            }
                            if (count > _availablePacks) {
                              return 'Maximum available is $_availablePacks.';
                            }
                            return null;
                          },
                        )),
                        sized(InputDecorator(
                          decoration: _decoration(
                              'Calculated weight', Icons.scale_outlined),
                          child:
                              Text('${_allocatedWeight.toStringAsFixed(2)} kg'),
                        )),
                        sized(InputDecorator(
                          decoration: _decoration(
                              'Price per pack', Icons.sell_outlined),
                          child: Text('GHS ${_unitPrice.toStringAsFixed(2)}'),
                        )),
                        sized(
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: .22),
                              ),
                            ),
                            child: Row(children: [
                              const Icon(Icons.calculate_outlined,
                                  color: AppColors.success),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Calculated total',
                                        style: AppTypography.bodySmall),
                                    Text(
                                      '$_requestedPacks packs x GHS ${_unitPrice.toStringAsFixed(2)} = GHS ${_totalAmount.toStringAsFixed(2)}',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                          full: true,
                        ),
                        sized(InkWell(
                          onTap: _saving ? null : _pickDate,
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: _decoration('Scheduled date',
                                Icons.calendar_today_outlined),
                            child: Text(
                                '${_scheduledDate.day.toString().padLeft(2, '0')}/${_scheduledDate.month.toString().padLeft(2, '0')}/${_scheduledDate.year}'),
                          ),
                        )),
                        sized(DropdownButtonFormField<String>(
                          initialValue: _paymentMode,
                          decoration: _decoration('Payment mode',
                              Icons.account_balance_wallet_outlined),
                          items: const [
                            'Bank Transfer',
                            'Mobile Money',
                            'Cash',
                            'Credit',
                          ]
                              .map((item) => DropdownMenuItem(
                                  value: item, child: Text(item)))
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) =>
                                  setState(() => _paymentMode = value!),
                        )),
                        sized(DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: _decoration(
                              'Delivery status', Icons.flag_outlined),
                          items: const ['Pending', 'Delivered', 'Cancelled']
                              .map((item) => DropdownMenuItem(
                                  value: item, child: Text(item)))
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _status = value!),
                        )),
                        sized(TextFormField(
                          controller: _receiptController,
                          decoration: _decoration('Receipt / reference',
                              Icons.receipt_long_outlined,
                              hint: 'Optional'),
                        )),
                        sized(
                            TextFormField(
                              controller: _addressController,
                              decoration: _decoration('Delivery address',
                                  Icons.location_on_outlined),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Enter the delivery address.'
                                      : null,
                            ),
                            full: true),
                        sized(
                            TextFormField(
                              controller: _notesController,
                              minLines: 3,
                              maxLines: 5,
                              decoration: _decoration(
                                  'Delivery notes', Icons.notes_outlined,
                                  hint:
                                      'Handoff instructions or buyer requirements'),
                            ),
                            full: true),
                        sized(
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Payment received'),
                              subtitle: const Text(
                                  'Mark only after payment has been confirmed.'),
                              value: _paid,
                              onChanged: _saving
                                  ? null
                                  : (value) => setState(() => _paid = value),
                            ),
                            full: true),
                      ],
                    );
                  }),
                ),
              ),
            ),
            Divider(
                height: 1, color: dark ? Colors.white10 : AppColors.neutral200),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(_editing
                            ? Icons.save_outlined
                            : Icons.add_circle_outline),
                    label: Text(_saving
                        ? 'Saving...'
                        : _editing
                            ? 'Save Changes'
                            : 'Create Delivery'),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
    return mobile
        ? Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: content,
          )
        : Dialog(backgroundColor: Colors.transparent, child: content);
  }
}

class _SalesDeliveryError extends StatelessWidget {
  const _SalesDeliveryError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.error.withValues(alpha: .24)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 19),
          const SizedBox(width: 9),
          Expanded(
              child: Text(message,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.error))),
        ]),
      );
}

class _SalesDeliveryLoadError extends StatelessWidget {
  const _SalesDeliveryLoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _SalesDeliveryEmpty(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load sales deliveries',
        message: message,
        action: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      );
}

class _SalesDeliveryEmpty extends StatelessWidget {
  const _SalesDeliveryEmpty({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: dark ? Colors.white10 : AppColors.neutral200),
      ),
      child: Column(children: [
        Icon(icon, size: 34, color: AppColors.textSecondary),
        const SizedBox(height: 10),
        Text(title,
            textAlign: TextAlign.center,
            style:
                AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
                color: dark ? Colors.white60 : AppColors.textSecondary)),
        if (action != null) ...[
          const SizedBox(height: 14),
          action!,
        ],
      ]),
    );
  }
}

class SalesFinancialScreen extends StatelessWidget {
  const SalesFinancialScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SalesManagerDataPage(
        kind: _SalesManagerPageKind.financial,
        selectedIndex: 5,
      );
}

class SalesReportsScreen extends StatelessWidget {
  const SalesReportsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SalesManagerDataPage(
        kind: _SalesManagerPageKind.reports,
        selectedIndex: 6,
      );
}

enum _SalesManagerPageKind { performance, deliveries, financial, reports }

class _SalesManagerDataPage extends ConsumerStatefulWidget {
  final _SalesManagerPageKind kind;
  final int selectedIndex;

  const _SalesManagerDataPage({
    required this.kind,
    required this.selectedIndex,
  });

  @override
  ConsumerState<_SalesManagerDataPage> createState() =>
      _SalesManagerDataPageState();
}

class _SalesManagerDataPageState extends ConsumerState<_SalesManagerDataPage> {
  final _api = SuperAdminApiService();
  List<Map<String, dynamic>> _sales = const [];
  List<Map<String, dynamic>> _offTakers = const [];
  List<Map<String, dynamic>> _fulfillments = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait<List<Map<String, dynamic>>>([
        _api.getSales(),
        _api.getOffTakers(),
        _api.getFulfillments(),
      ]);
      if (!mounted) return;
      setState(() {
        _sales = result[0];
        _offTakers = result[1];
        _fulfillments = result[2];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  String _text(Map<String, dynamic> item, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  double _number(Map<String, dynamic> item, List<String> keys) {
    final value = _text(item, keys);
    return double.tryParse(value.replaceAll(',', '')) ?? 0;
  }

  bool _isPaid(Map<String, dynamic> item) {
    final value = item['paid'];
    if (value is bool) return value;
    return '${value ?? ''}'.toLowerCase() == 'true';
  }

  String _status(Map<String, dynamic> item) =>
      _text(item, ['status'], fallback: 'Pending');

  DateTime _date(Map<String, dynamic> item) {
    final value = _text(item, [
      'delivered_at',
      'payment_date',
      'created_at',
      r'$createdAt',
    ]);
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _money(double value) => 'GHS ${value.toStringAsFixed(2)}';

  List<Map<String, dynamic>> get _validSales => _sales
      .where((sale) => _status(sale).toLowerCase() != 'cancelled')
      .toList();

  List<Map<String, dynamic>> get _releasedFulfillments {
    final records = _fulfillments.where((record) {
      final status = _text(record, ['status']).toLowerCase();
      final qualityStatus = _text(record, ['quality_status']).toLowerCase();
      return status == 'sent to sales' && qualityStatus == 'approved';
    }).toList();
    records.sort((a, b) {
      final bDate = DateTime.tryParse(_text(b, [
            'sent_to_sales_date_time',
            'quality_decided_at',
            r'$updatedAt'
          ])) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final aDate = DateTime.tryParse(_text(a, [
            'sent_to_sales_date_time',
            'quality_decided_at',
            r'$updatedAt'
          ])) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return records;
  }

  bool _hasSaleForBatch(Map<String, dynamic> fulfillment) {
    final batch = _text(fulfillment, ['batch_number']).toLowerCase();
    if (batch.isEmpty) return false;
    return _sales.any((sale) =>
        _text(sale, ['batch_id', 'batch_number']).toLowerCase() == batch);
  }

  List<Map<String, Object>> _recordCards() {
    final records = [..._validSales]
      ..sort((a, b) => _date(b).compareTo(_date(a)));
    final salesCards = records.map<Map<String, Object>>((sale) {
      final status = _status(sale);
      final statusLower = status.toLowerCase();
      final color = statusLower == 'delivered'
          ? AppColors.success
          : statusLower == 'cancelled'
              ? AppColors.warning
              : AppColors.primary;
      final buyer = _text(sale, ['buyer_name', 'buyer_id', 'off_taker_id'],
          fallback: 'Unnamed buyer');
      final batch = _text(sale, ['batch_id'], fallback: 'Batch not set');
      final amount = _number(sale, ['total_amount', 'amount', 'total']);
      return {
        'title': buyer,
        'subtitle':
            '$batch | ${_text(sale, ['payment_mode'], fallback: 'Sale')}',
        'metric': _money(amount),
        'status': status,
        'color': color,
      };
    }).toList();
    if (widget.kind != _SalesManagerPageKind.deliveries) {
      return salesCards.take(6).toList();
    }
    final intakeCards = _releasedFulfillments.map<Map<String, Object>>((item) {
      final saleRecorded = _hasSaleForBatch(item);
      return {
        'title': _text(item, ['batch_number'], fallback: 'Unassigned batch'),
        'subtitle': '${_text(item, [
              'plant_variety',
              'crop_variety',
              'plant_type'
            ], fallback: 'Crop variety')} | ${_text(item, ['farm_name'], fallback: 'Farm')}',
        'metric': '${_number(item, [
              'total_package_count'
            ]).toStringAsFixed(0)} packs | ${_number(item, [
              'total_packaged_weight'
            ]).toStringAsFixed(1)} kg',
        'status': saleRecorded ? 'Sale recorded' : 'QA approved',
        'color': saleRecorded ? AppColors.success : AppColors.primary,
      };
    }).toList();
    return [...intakeCards, ...salesCards].take(10).toList();
  }

  List<_KpiData> _kpis() {
    final sales = _validSales;
    final revenue = sales.fold<double>(
      0,
      (sum, sale) => sum + _number(sale, ['total_amount', 'amount', 'total']),
    );
    final collected = sales.where(_isPaid).fold<double>(
          0,
          (sum, sale) =>
              sum + _number(sale, ['total_amount', 'amount', 'total']),
        );
    final delivered = sales
        .where((sale) => _status(sale).toLowerCase() == 'delivered')
        .length;
    final pending =
        sales.where((sale) => _status(sale).toLowerCase() == 'pending').length;
    final activeBuyers = _offTakers
        .where((buyer) =>
            _text(buyer, ['status'], fallback: 'Active').toLowerCase() ==
            'active')
        .length;
    final paidRate = revenue == 0 ? 0 : (collected / revenue * 100).round();
    switch (widget.kind) {
      case _SalesManagerPageKind.performance:
        return [
          _KpiData('Revenue', _money(revenue), '${sales.length} recorded sales',
              Icons.payments_outlined, AppColors.success),
          _KpiData('Paid rate', '$paidRate%', 'Based on paid sales',
              Icons.track_changes_outlined, AppColors.primary),
          _KpiData('Active buyers', '$activeBuyers', 'Off-taker accounts',
              Icons.handshake_outlined, AppColors.warning),
        ];
      case _SalesManagerPageKind.deliveries:
        final ready = _releasedFulfillments
            .where((record) => !_hasSaleForBatch(record))
            .length;
        return [
          _KpiData(
              'From QA',
              '${_releasedFulfillments.length}',
              '$ready ready for allocation',
              Icons.verified_outlined,
              AppColors.primary),
          _KpiData('Pending', '$pending', 'Sales awaiting delivery',
              Icons.local_shipping_outlined, AppColors.warning),
          _KpiData('Delivered', '$delivered', 'Recorded sales',
              Icons.task_alt_outlined, AppColors.success),
        ];
      case _SalesManagerPageKind.financial:
        return [
          _KpiData('Revenue', _money(revenue), 'From recorded sales',
              Icons.payments_outlined, AppColors.success),
          _KpiData('Receivables', _money(revenue - collected), 'Unpaid sales',
              Icons.receipt_long_outlined, AppColors.warning),
          _KpiData('Collected', _money(collected), 'Paid sales',
              Icons.account_balance_outlined, AppColors.primary),
        ];
      case _SalesManagerPageKind.reports:
        return [
          _KpiData('Sales records', '${sales.length}', 'Available to report',
              Icons.assessment_outlined, AppColors.primary),
          _KpiData('Buyers covered', '$activeBuyers', 'Active off-takers',
              Icons.people_outline, AppColors.success),
          _KpiData(
              'Unpaid records',
              '${sales.where((sale) => !_isPaid(sale)).length}',
              'Require collection follow-up',
              Icons.report_problem_outlined,
              AppColors.warning),
        ];
    }
  }

  _SalesPage _page(
      {required List<_KpiData> kpis,
      required List<Map<String, Object>> cards}) {
    switch (widget.kind) {
      case _SalesManagerPageKind.performance:
        return _SalesPage(
          selectedIndex: widget.selectedIndex,
          title: 'Sales Performance',
          subtitle:
              'Track revenue, buyer activity, and recorded sales performance.',
          icon: Icons.trending_up_outlined,
          colors: const [Color(0xFF166534), Color(0xFF0F766E)],
          kpis: kpis,
          sectionTitle: 'Recent Sales Performance',
          cards: cards,
        );
      case _SalesManagerPageKind.deliveries:
        return _SalesPage(
          selectedIndex: widget.selectedIndex,
          title: 'Sales Deliveries',
          subtitle:
              'Receive QA-approved batches and track their buyer delivery commitments.',
          icon: Icons.local_shipping_outlined,
          colors: const [Color(0xFF334155), Color(0xFF1D4ED8)],
          kpis: kpis,
          sectionTitle: 'QA Batch Intake & Delivery Records',
          cards: cards,
        );
      case _SalesManagerPageKind.financial:
        return _SalesPage(
          selectedIndex: widget.selectedIndex,
          title: 'Sales Financials',
          subtitle: 'Monitor recorded revenue, collections, and unpaid sales.',
          icon: Icons.account_balance_wallet_outlined,
          colors: const [Color(0xFF7C2D12), Color(0xFFEA580C)],
          kpis: kpis,
          sectionTitle: 'Financial Records',
          cards: cards,
        );
      case _SalesManagerPageKind.reports:
        return _SalesPage(
          selectedIndex: widget.selectedIndex,
          title: 'Sales Reports',
          subtitle:
              'Review reportable sales, buyer coverage, and collection follow-up.',
          icon: Icons.assessment_outlined,
          colors: const [Color(0xFF1E3A8A), Color(0xFF0F766E)],
          kpis: kpis,
          sectionTitle: 'Recent Report Data',
          cards: cards,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shellChild = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load sales data.'),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _page(kpis: _kpis(), cards: _recordCards());

    if (!_loading && _error == null) return shellChild;
    return SalesManagerScreenShell(
      selectedIndex: widget.selectedIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Hero(
            title: widget.kind == _SalesManagerPageKind.performance
                ? 'Sales Performance'
                : widget.kind == _SalesManagerPageKind.deliveries
                    ? 'Sales Deliveries'
                    : widget.kind == _SalesManagerPageKind.financial
                        ? 'Sales Financials'
                        : 'Sales Reports',
            subtitle: 'Loading live sales data from the backend.',
            icon: Icons.analytics_outlined,
            colors: const [Color(0xFF334155), Color(0xFF1D4ED8)],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(height: 240, child: shellChild),
        ],
      ),
    );
  }
}

class SalesManagerSettingsScreen extends StatelessWidget {
  const SalesManagerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SalesManagerScreenShell(
      selectedIndex: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Hero(
            title: 'Sales Settings',
            subtitle:
                'Manage buyer alerts, approval limits, revenue targets, and delivery notification rules.',
            icon: Icons.settings_outlined,
            colors: [Color(0xFF334155), Color(0xFF475569)],
          ),
          SizedBox(height: AppSpacing.lg),
          _SettingsPanel(),
        ],
      ),
    );
  }
}

class _SalesPage extends StatelessWidget {
  final int selectedIndex;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final List<_KpiData> kpis;
  final String sectionTitle;
  final List<Map<String, Object>> cards;

  const _SalesPage({
    required this.selectedIndex,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.kpis,
    required this.sectionTitle,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SalesManagerScreenShell(
      selectedIndex: selectedIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Hero(title: title, subtitle: subtitle, icon: icon, colors: colors),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: kpis.map((kpi) => _KpiCard(data: kpi)).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            sectionTitle,
            style: AppTypography.h5.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ResponsiveGrid(
            itemCount: cards.length,
            itemBuilder: (index) => _SalesCard(item: cards[index]),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const _Hero({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 24 : 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.88),
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

class _ResponsiveGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  const _ResponsiveGrid({
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final columns = constraints.maxWidth >= 820 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: isMobile ? 310 : 260,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) => itemBuilder(index),
        );
      },
    );
  }
}

class _SalesCard extends StatelessWidget {
  final Map<String, Object> item;

  const _SalesCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = item['color']! as Color;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.surfaceDark : Colors.white,
            color.withOpacity(isDark ? 0.08 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(isDark ? 0.28 : 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: Icons.business_center_outlined, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']! as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h6.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['subtitle']! as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: item['status']! as String, color: color),
            ],
          ),
          const Spacer(),
          _MetricPill(
            label: 'Metric',
            value: item['metric']! as String,
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiData(this.title, this.value, this.subtitle, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width =
        MediaQuery.of(context).size.width < 600 ? double.infinity : 230.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: data.color.withOpacity(isDark ? 0.26 : 0.16)),
      ),
      child: Row(
        children: [
          _IconBox(icon: data.icon, color: data.color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MutedText(data.title),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: AppTypography.h5.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                _MutedText(data.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SettingRow(
          title: 'Buyer renewal alerts',
          subtitle: 'Notify when off-taker contracts are nearing renewal.',
          icon: Icons.notifications_active_outlined,
          enabled: true,
        ),
        _SettingRow(
          title: 'Revenue approval threshold',
          subtitle: 'Require manager review for large credit sales.',
          icon: Icons.verified_user_outlined,
          enabled: true,
        ),
        _SettingRow(
          title: 'Auto-export sales reports',
          subtitle: 'Generate sales summaries at close of day.',
          icon: Icons.file_download_outlined,
          enabled: false,
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;

  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          _IconBox(icon: icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                _MutedText(subtitle),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: (_) {}),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MutedText(label),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 136),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  final String text;

  const _MutedText(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption.copyWith(
        color: isDark ? Colors.white60 : AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
