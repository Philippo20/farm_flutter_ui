import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../services/password_recovery_service.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen(
      {super.key,
      this.initialEmail = '',
      this.reset = false,
      this.userId = '',
      this.secret = '',
      this.service});
  final String initialEmail, userId, secret;
  final bool reset;
  final PasswordRecoveryService? service;
  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  late final _service = widget.service ?? PasswordRecoveryService();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController(), _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false, _done = false, _hidden = true;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    if (widget.service == null) _service.close();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.reset) {
        await _service.reset(widget.userId, widget.secret, _password.text);
      } else {
        await _service.request(_email.text.trim());
      }
      if (mounted) setState(() => _done = true);
    } catch (error) {
      if (mounted)
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final invalidLink =
        widget.reset && (widget.userId.isEmpty || widget.secret.isEmpty);
    Widget field(String label, TextEditingController controller,
            {bool password = false, bool confirm = false}) =>
        Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: AppTypography.label
                      .copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 6),
              TextFormField(
                controller: controller,
                enabled: !_busy,
                obscureText: password && _hidden,
                style: AppTypography.bodyMedium,
                keyboardType: password
                    ? TextInputType.visiblePassword
                    : TextInputType.emailAddress,
                autofillHints: password
                    ? const [AutofillHints.newPassword]
                    : const [AutofillHints.email],
                autocorrect: false,
                enableSuggestions: !password,
                decoration: InputDecoration(
                    prefixIcon: Icon(
                        password ? Icons.lock_outline : Icons.mail_outline,
                        size: 18),
                    suffixIcon: password && !confirm
                        ? IconButton(
                            tooltip:
                                _hidden ? 'Show password' : 'Hide password',
                            onPressed: () => setState(() => _hidden = !_hidden),
                            icon: Icon(
                                _hidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18))
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
                validator: (value) {
                  if ((value ?? '').isEmpty) return 'Required';
                  if (!password &&
                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch(value!.trim()))
                    return 'Enter a valid email address';
                  if (password && value!.length < 8)
                    return 'Use at least 8 characters';
                  if (confirm && value != _password.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),
            ]));
    return Scaffold(
        body: SafeArea(
            child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: (box.maxHeight - 48)
                                  .clamp(0, double.infinity)),
                          child: Center(
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 440),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: colors.outlineVariant)),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                      color: AppColors.primary
                                                          .withValues(
                                                              alpha: .12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12)),
                                                  child: Icon(
                                                      _done
                                                          ? Icons
                                                              .check_circle_outline
                                                          : Icons.lock_reset,
                                                      color: AppColors.primary,
                                                      size: 28))),
                                          const SizedBox(height: 20),
                                          Text(
                                              _done
                                                  ? (widget.reset
                                                      ? 'Password updated'
                                                      : 'Check your email')
                                                  : (widget.reset
                                                      ? 'Reset your password'
                                                      : 'Forgot your password?'),
                                              style: AppTypography.titleLarge),
                                          const SizedBox(height: 10),
                                          Text(
                                              _done
                                                  ? (widget.reset
                                                      ? 'You can now sign in with your new password.'
                                                      : 'If an account exists for this email, you’ll receive a password-reset link. Check your inbox and spam folder.')
                                                  : (invalidLink
                                                      ? 'This reset link is incomplete. Request a new link to continue.'
                                                      : (widget.reset
                                                          ? 'Choose a new password for your account.'
                                                          : 'Enter your account email and we’ll send you a reset link.')),
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                      color: colors
                                                          .onSurfaceVariant)),
                                          const SizedBox(height: 24),
                                          if (!_done && !invalidLink)
                                            Form(
                                                key: _form,
                                                child: Column(children: [
                                                  if (!widget.reset)
                                                    field(
                                                        'Email address', _email)
                                                  else ...[
                                                    field('New password',
                                                        _password,
                                                        password: true),
                                                    field('Confirm password',
                                                        _confirm,
                                                        password: true,
                                                        confirm: true)
                                                  ],
                                                ])),
                                          if (_error != null)
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 16),
                                                child: Text(_error!,
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                            color:
                                                                colors.error))),
                                          if (!_done && !invalidLink)
                                            FilledButton(
                                                onPressed:
                                                    _busy ? null : _submit,
                                                style: FilledButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 14),
                                                    textStyle: AppTypography
                                                        .labelLarge),
                                                child: _busy
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth: 2))
                                                    : Text(widget.reset
                                                        ? 'Update password'
                                                        : 'Send reset link')),
                                          if (invalidLink)
                                            FilledButton(
                                                onPressed: () => Navigator
                                                    .pushReplacementNamed(
                                                        context,
                                                        '/forgot-password'),
                                                child: const Text(
                                                    'Request new link')),
                                          const SizedBox(height: 12),
                                          TextButton(
                                              onPressed: _busy
                                                  ? null
                                                  : () => Navigator
                                                      .pushNamedAndRemoveUntil(
                                                          context,
                                                          '/login',
                                                          (_) => false),
                                              child: const Text(
                                                  'Back to sign in')),
                                        ]),
                                  )))),
                    ))));
  }
}
