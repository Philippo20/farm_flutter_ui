import 'package:flutter/material.dart';
import '../../services/email_settings_service.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';

class EmailSettingsCard extends StatefulWidget {
  const EmailSettingsCard({super.key, this.service});
  final EmailSettingsService? service;
  @override
  State<EmailSettingsCard> createState() => _EmailSettingsCardState();
}

class _EmailSettingsCardState extends State<EmailSettingsCard> {
  late final _api = widget.service ?? EmailSettingsService();
  final _form = GlobalKey<FormState>();
  final _fields = {
    for (final key in [
      'host',
      'port',
      'username',
      'password',
      'sender_name',
      'sender_email',
      'reply_to',
      'recipient'
    ])
      key: TextEditingController()
  };
  Map<String, dynamic> _config = {};
  bool _loading = true, _busy = false, _hidden = true, _dirty = false;
  String? _error, _notice;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _apply(Map<String, dynamic> config) {
    _config = config;
    for (final entry in _fields.entries) {
      if (entry.key != 'recipient') {
        entry.value.text =
            entry.key == 'password' ? '' : '${config[entry.key] ?? ''}';
      }
    }
    _dirty = false;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.load();
      if (mounted) setState(() => _apply(data));
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final data = await _api.save({
        ..._config,
        for (final entry in _fields.entries)
          if (entry.key != 'recipient') entry.key: entry.value.text.trim(),
        'password': _fields['password']!.text,
        'port': int.parse(_fields['port']!.text),
      });
      if (mounted) {
        setState(() {
          _apply(data);
          _notice = 'Email settings saved';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() async {
    final recipient = _fields['recipient']!.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(recipient)) {
      setState(() => _error = 'Enter a valid test recipient email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final result = await _api.sendTest(recipient);
      if (mounted) setState(() => _notice = result);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _change(String key, dynamic value) => setState(() {
        _config[key] = value;
        _dirty = true;
        _notice = null;
      });
  Widget _field(String key, String label,
      {bool required = false, TextInputType? keyboard}) {
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppTypography.label.copyWith(color: colors.onSurfaceVariant)),
      const SizedBox(height: 6),
      TextFormField(
        controller: _fields[key],
        enabled: !_busy,
        obscureText: key == 'password' && _hidden,
        style: AppTypography.bodySmall,
        keyboardType: keyboard,
        onChanged: (_) {
          if (key != 'recipient') {
            setState(() {
              _dirty = true;
              _notice = null;
            });
          }
        },
        validator: (value) {
          if (required && (value ?? '').trim().isEmpty) return 'Required';
          if (key == 'port') {
            final port = int.tryParse(value ?? '');
            if (port == null || port < 1 || port > 65535) {
              return 'Use a port from 1–65535';
            }
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: key == 'password' && _config['password_configured'] == true
              ? 'Leave blank to keep saved password'
              : null,
          hintStyle: AppTypography.bodySmall,
          suffixIcon: key == 'password'
              ? IconButton(
                  tooltip: _hidden ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _hidden = !_hidden),
                  icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18))
              : null,
          filled: true,
          fillColor: colors.surfaceContainerLow,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.outlineVariant)),
        ),
      ),
    ]);
  }

  Widget _toggle(String key, String label, String subtitle) => Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTypography.labelLarge),
          const SizedBox(height: 3),
          Text(subtitle,
              style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant))
        ])),
        Switch.adaptive(
            value: _config[key] == true,
            onChanged: _busy ? null : (value) => _change(key, value)),
      ]);
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.mark_email_read_outlined,
                color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
                child: Text('Email Settings', style: AppTypography.titleSmall))
          ]),
          const SizedBox(height: 6),
          Text(
              'Configure platform SMTP delivery and email preferences. Save this section separately.',
              style: AppTypography.bodySmall
                  .copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_config.isEmpty) ...[
            Text(_error ?? 'Email settings unavailable',
                style: AppTypography.bodySmall),
            TextButton(onPressed: _load, child: const Text('Retry'))
          ] else ...[
            _toggle('enabled', 'SMTP delivery',
                'Enable the configured SMTP service for platform emails.'),
            const SizedBox(height: 16),
            Form(
                key: _form,
                child: LayoutBuilder(builder: (context, box) {
                  final width = box.maxWidth >= 560
                      ? (box.maxWidth - 12) / 2
                      : box.maxWidth;
                  final fields = [
                    _field('host', 'SMTP host',
                        required: _config['enabled'] == true),
                    _field('port', 'Port',
                        required: true, keyboard: TextInputType.number),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Connection security',
                              style: AppTypography.label),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                              initialValue:
                                  '${_config['security'] ?? 'starttls'}',
                              isExpanded: true,
                              style: AppTypography.bodySmall
                                  .copyWith(color: colors.onSurface),
                              items: const [
                                DropdownMenuItem(
                                    value: 'starttls',
                                    child: Text('STARTTLS (usually 587)')),
                                DropdownMenuItem(
                                    value: 'ssl',
                                    child: Text('SSL / TLS (usually 465)'))
                              ],
                              onChanged: _busy
                                  ? null
                                  : (value) => _change('security', value))
                        ]),
                    _field('username', 'SMTP username'),
                    _field('password', 'SMTP password'),
                    _field('sender_name', 'Sender name'),
                    _field('sender_email', 'Sender email',
                        required: _config['enabled'] == true,
                        keyboard: TextInputType.emailAddress),
                    _field('reply_to', 'Reply-to email (optional)',
                        keyboard: TextInputType.emailAddress),
                  ];
                  return Wrap(
                      spacing: 12,
                      runSpacing: 14,
                      children: fields
                          .map((field) => SizedBox(width: width, child: field))
                          .toList());
                })),
            const SizedBox(height: 18),
            Text('Email preferences', style: AppTypography.titleSmall),
            const SizedBox(height: 10),
            _toggle('farm_alerts', 'Farm alerts',
                'Farm operations and monitoring emails.'),
            _toggle('workflow_alerts', 'Workflow alerts',
                'Deliveries, requests, and task updates.'),
            _toggle('account_alerts', 'Account alerts',
                'Platform account notification emails.'),
            const SizedBox(height: 8),
            Text(
                'Verification and password-reset emails are managed by Appwrite. These preferences apply to the platform SMTP service.',
                style: AppTypography.bodySmall
                    .copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!,
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.error))),
            if (_notice != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_notice!,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.primary))),
            FilledButton.icon(
                onPressed: _busy || !_dirty ? null : _save,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_busy ? 'Please wait...' : 'Save email settings'),
                style: FilledButton.styleFrom(
                    textStyle: AppTypography.labelLarge)),
            const SizedBox(height: 18),
            _field('recipient', 'Test recipient',
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 10),
            OutlinedButton.icon(
                onPressed: _busy || _dirty ? null : _test,
                icon: const Icon(Icons.send_outlined, size: 16),
                label: const Text('Send test email'),
                style: OutlinedButton.styleFrom(
                    textStyle: AppTypography.labelLarge)),
            Text(
                _dirty
                    ? 'Save your changes before testing.'
                    : 'Sends one email using the saved configuration.',
                style: AppTypography.bodySmall
                    .copyWith(color: colors.onSurfaceVariant)),
          ],
        ]));
  }
}
