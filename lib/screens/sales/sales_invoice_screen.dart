import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/browser_print.dart';
import '../../services/superadmin_api_service.dart';

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({super.key, required this.saleId});

  final String saleId;

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  final _api = SuperAdminApiService();
  Map<String, dynamic>? _sale;
  String? _error;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.saleId.trim().isEmpty) {
      setState(() => _error = 'This invoice link is missing its reference.');
      return;
    }
    try {
      final sale = await _api.getSale(widget.saleId);
      if (!mounted) return;
      setState(() => _sale = sale);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  String _text(List<String> keys, [String fallback = '-']) {
    final sale = _sale;
    if (sale == null) return fallback;
    for (final key in keys) {
      final value = '${sale[key] ?? ''}'.trim();
      if (value.isNotEmpty && value != 'null') return value;
    }
    return fallback;
  }

  double _number(String key) => double.tryParse(_text([key], '0')) ?? 0;

  String _date(String key) {
    final parsed = DateTime.tryParse(_text([key], ''))?.toLocal();
    if (parsed == null) return '-';
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  Future<void> _printInvoice() async {
    if (!canPrintBrowserPage || _printing) return;
    setState(() => _printing = true);
    await WidgetsBinding.instance.endOfFrame;
    printA4BrowserPage();
    if (mounted) setState(() => _printing = false);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = _printing
        ? Colors.white
        : dark
            ? AppColors.backgroundDark
            : const Color(0xFFF1F5F2);
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: _error != null
            ? _InvoiceError(
                message: _error!,
                onRetry: () {
                  setState(() => _error = null);
                  _load();
                })
            : _sale == null
                ? const Center(child: CircularProgressIndicator())
                : SelectionArea(
                    child: SingleChildScrollView(
                      padding: _printing
                          ? EdgeInsets.zero
                          : const EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: _printing ? 794 : 920,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!_printing) ...[
                                _toolbar(context),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              _invoiceSheet(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _toolbar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Delivery Invoice',
            style:
                AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton.icon(
          onPressed: canPrintBrowserPage ? _printInvoice : null,
          icon: const Icon(Icons.print_outlined, size: 18),
          label: const Text('Print'),
        ),
      ],
    );
  }

  Widget _invoiceSheet(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : Colors.white;
    final secondary = dark ? Colors.white60 : AppColors.textSecondary;
    final thirdParty = _text(['delivery_type'], 'internal') == 'third_party';
    final packageCount = _number('package_count').round();
    final unitPrice = _number('unit_price');
    final total = _number('total_amount');
    final weight = _number('quantity_delivered');

    return Container(
      padding: EdgeInsets.all(
        _printing
            ? 32
            : MediaQuery.sizeOf(context).width < 600
                ? 20
                : 40,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(_printing ? 0 : 6),
        boxShadow: _printing
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? .22 : .08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: AppSpacing.md,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FARM ESTATES LTD',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      )),
                  Text('Packaged produce delivery invoice',
                      style:
                          AppTypography.bodySmall.copyWith(color: secondary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('INVOICE',
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      )),
                  Text(_text(['invoice_number', 'receipt_number']),
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text('Generated ${_date('invoice_generated_at')}',
                      style:
                          AppTypography.bodySmall.copyWith(color: secondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 3, thickness: 3, color: AppColors.primary),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 48,
            runSpacing: AppSpacing.lg,
            children: [
              SizedBox(
                width: 340,
                child: _InfoGroup(
                  label: 'DELIVER TO',
                  title: _text(['buyer_name'], 'Off-taker'),
                  lines: [
                    _text(['delivery_address'])
                  ],
                ),
              ),
              SizedBox(
                width: 380,
                child: _InfoGroup(
                  label: 'DELIVERY ASSIGNMENT',
                  title: _text(['sales_person_name'], 'Sales Personnel'),
                  lines: [
                    thirdParty ? 'Third-party delivery' : 'Internal fleet',
                    'Provider: ${_text(['delivery_provider'], 'Farm Estates')}',
                    'Driver: ${_text(['delivery_agent_name'], 'Unassigned')}',
                    'Plate / vehicle: ${_text([
                          'delivery_plate_number',
                          'delivery_vehicle'
                        ], 'Pending')}',
                    'Scheduled: ${_date('scheduled_for')}',
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_printing)
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.3),
                1: FlexColumnWidth(1.4),
                2: FlexColumnWidth(.8),
                3: FlexColumnWidth(1.1),
                4: FlexColumnWidth(1.2),
              },
              children: _invoiceTableRows(
                packageCount: packageCount,
                unitPrice: unitPrice,
                total: total,
                weight: weight,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 790,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.3),
                    1: FlexColumnWidth(1.4),
                    2: FlexColumnWidth(.8),
                    3: FlexColumnWidth(1.1),
                    4: FlexColumnWidth(1.2),
                  },
                  children: _invoiceTableRows(
                    packageCount: packageCount,
                    unitPrice: unitPrice,
                    total: total,
                    weight: weight,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 330,
              child: Column(
                children: [
                  _totalRow('Subtotal', total),
                  const Divider(thickness: 2),
                  _totalRow('Total', total, strong: true),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Payment: ${_text([
                            'payment_mode'
                          ])} | ${_sale?['paid'] == true ? 'Paid' : 'Payment due'}',
                      style: AppTypography.bodySmall.copyWith(color: secondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: .04)
                  : AppColors.neutral100,
              border: const Border(
                  left: BorderSide(color: AppColors.primary, width: 4)),
            ),
            child: Text(
              'Handover instructions\n${_text([
                    'delivery_notes'
                  ], 'Inspect the packs, sign this invoice, and return the signed copy to Farm Estates Ltd.')}',
              style: AppTypography.bodySmall.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 68),
          const Row(
            children: [
              Expanded(
                  child: _SignatureLine(
                      label: 'Off-taker name, signature and date')),
              SizedBox(width: 44),
              Expanded(
                  child: _SignatureLine(
                      label: 'Sales Personnel / Driver signature and date')),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'This document confirms physical handover only when signed by the receiving off-taker.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: secondary),
          ),
        ],
      ),
    );
  }

  List<TableRow> _invoiceTableRows({
    required int packageCount,
    required double unitPrice,
    required double total,
    required double weight,
  }) {
    return [
      _tableRow(
        const [
          'Batch / Product',
          'Package',
          'Packs',
          'Unit price',
          'Amount',
        ],
        header: true,
      ),
      _tableRow([
        '${_text(['batch_number', 'batch_id'])}\n${_text([
              'crop_variety'
            ])} | ${weight.toStringAsFixed(2)} kg',
        '${_text(['package_type'])}\n${_text(['price_tier'], 'Regular')} price',
        '$packageCount',
        'GHS ${unitPrice.toStringAsFixed(2)}',
        'GHS ${total.toStringAsFixed(2)}',
      ]),
    ];
  }

  TableRow _tableRow(List<String> values, {bool header = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: header ? AppColors.primary.withValues(alpha: .1) : null,
        border: const Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      children: values
          .map((value) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                child: Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: header ? FontWeight.w600 : FontWeight.w400,
                    color: header ? AppColors.primaryDark : null,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _totalRow(String label, double amount, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
              )),
          Text('GHS ${amount.toStringAsFixed(2)}',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

class _InfoGroup extends StatelessWidget {
  const _InfoGroup(
      {required this.label, required this.title, required this.lines});

  final String label;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).brightness == Brightness.dark
        ? Colors.white60
        : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.bodySmall.copyWith(
              color: secondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            )),
        const SizedBox(height: 6),
        Text(title,
            style:
                AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ...lines.map((line) => Text(
              line,
              style: AppTypography.bodySmall.copyWith(color: secondary),
            )),
      ],
    );
  }
}

class _SignatureLine extends StatelessWidget {
  const _SignatureLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.textPrimary)),
      ),
      child: Text(label, style: AppTypography.bodySmall),
    );
  }
}

class _InvoiceError extends StatelessWidget {
  const _InvoiceError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 44, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Invoice unavailable', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center, style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
