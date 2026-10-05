import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_typography.dart';
import '../../services/superadmin_api_service.dart';

/// No authenticated session is issued until the temporary password is replaced.
class FirstPasswordScreen extends StatefulWidget {
  const FirstPasswordScreen(
      {super.key, required this.token, required this.temporaryPassword});
  final String token, temporaryPassword;
  @override
  State<FirstPasswordScreen> createState() => _FirstPasswordScreenState();
}

class _FirstPasswordScreenState extends State<FirstPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _client = http.Client();
  bool _saving = false, _hide = true;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await _client
          .post(
              Uri.parse(
                  '${SuperAdminApiService.baseUrl}/account/first-password'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'token': widget.token,
                'temporary_password': widget.temporaryPassword,
                'password': _password.text
              }))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        String message = 'Unable to change your password. Please try again.';
        try {
          final body = jsonDecode(response.body);
          if (body['detail'] is String) message = body['detail'];
        } catch (_) {}
        throw Exception(message);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
        canPop: !_saving,
        child: Scaffold(
          appBar: AppBar(
              title: Text('Secure your account',
                  style: AppTypography.titleMedium)),
          body: SafeArea(
              child: Center(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Form(
                              key: _form,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Icon(Icons.lock_reset_rounded,
                                        size: 40, color: colors.primary),
                                    const SizedBox(height: 20),
                                    Text('Choose your new password',
                                        style: AppTypography.titleMedium),
                                    const SizedBox(height: 8),
                                    Text(
                                        'You signed in with a temporary password. Replace it before accessing Farm Estates.',
                                        style: AppTypography.bodySmall),
                                    const SizedBox(height: 24),
                                    TextFormField(
                                        controller: _password,
                                        enabled: !_saving,
                                        obscureText: _hide,
                                        enableSuggestions: false,
                                        autocorrect: false,
                                        autofillHints: const [
                                          AutofillHints.newPassword
                                        ],
                                        decoration: InputDecoration(
                                            labelText: 'New password',
                                            border: const OutlineInputBorder(),
                                            suffixIcon: IconButton(
                                                tooltip: _hide
                                                    ? 'Show password'
                                                    : 'Hide password',
                                                onPressed: () => setState(
                                                    () => _hide = !_hide),
                                                icon: Icon(_hide
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                        .visibility_off_outlined))),
                                        validator: (v) => (v ?? '').length < 8
                                            ? 'Use at least 8 characters'
                                            : v == widget.temporaryPassword
                                                ? 'Choose a different password'
                                                : null),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                        controller: _confirm,
                                        enabled: !_saving,
                                        obscureText: _hide,
                                        enableSuggestions: false,
                                        autocorrect: false,
                                        decoration: const InputDecoration(
                                            labelText: 'Confirm new password',
                                            border: OutlineInputBorder()),
                                        validator: (v) => v != _password.text
                                            ? 'Passwords do not match'
                                            : null),
                                    if (_error != null)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 16),
                                          child: Text(_error!,
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                      color: colors.error))),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                        onPressed: _saving ? null : _save,
                                        icon: _saving
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2))
                                            : const Icon(Icons.check, size: 18),
                                        label: Text(_saving
                                            ? 'Updating password...'
                                            : 'Update password')),
                                    TextButton(
                                        onPressed: _saving
                                            ? null
                                            : () =>
                                                Navigator.pop(context, false),
                                        child: const Text('Back to sign in')),
                                  ])))))),
        ));
  }
}
