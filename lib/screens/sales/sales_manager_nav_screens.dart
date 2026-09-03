import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
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

class SalesDeliveriesScreen extends StatelessWidget {
  const SalesDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SalesManagerDataPage(
        kind: _SalesManagerPageKind.deliveries,
        selectedIndex: 3,
      );
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
        selectedIndex: 4,
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
              'total_packaged_weight'
            ]).toStringAsFixed(1)} kg available',
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
      selectedIndex: 6,
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
