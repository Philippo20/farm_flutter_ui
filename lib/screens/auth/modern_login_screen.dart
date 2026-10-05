import 'first_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../core/config/demo_accounts.dart';

/// Modern login screen with role-based authentication
class ModernLoginScreen extends ConsumerStatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  ConsumerState<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends ConsumerState<ModernLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (ref.read(authProvider).isLoading ||
        !_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Use auth provider to login
    final success =
        await ref.read(authProvider.notifier).login(email, password);

    if (!mounted) return;

    final authService = ref.read(authServiceProvider);
    final challenge = authService.passwordChangeToken;
    if (challenge != null) {
      final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (_) => FirstPasswordScreen(
              token: challenge, temporaryPassword: password)));
      authService.passwordChangeToken = null;
      if (!mounted) return;
      _passwordController.clear();
      ref.read(authProvider.notifier).clearError();
      if (changed == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Password changed. Sign in with your new password.')));
      }
      return;
    }
    if (success) {
      TextInput.finishAutofillContext();
      // Get the appropriate dashboard route
      final route = ref.read(authProvider.notifier).getDashboardRoute();

      // Navigate to dashboard
      Navigator.of(context).pushReplacementNamed(route);
    }
    // Error is handled by the auth provider state
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final muted = dark ? Colors.white70 : AppColors.textSecondary;
    final border = dark ? Colors.white12 : AppColors.neutral200;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor:
          dark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final padding = mobile ? 20.0 : 32.0;
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(padding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - padding * 2)
                      .clamp(0, double.infinity)),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.agriculture_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Farm Estates',
                                    style: AppTypography.titleMedium
                                        .copyWith(color: foreground)),
                                const SizedBox(height: 2),
                                Text('Management platform',
                                    style: AppTypography.bodySmall
                                        .copyWith(color: muted)),
                              ])),
                        ]),
                        const SizedBox(height: 24),
                        Container(
                          padding: EdgeInsets.all(mobile ? 20 : 28),
                          decoration: BoxDecoration(
                            color: dark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: border),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: dark ? .12 : .03),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          child: AutofillGroup(
                              child: Form(
                            key: _formKey,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Welcome back',
                                      style: AppTypography.titleLarge
                                          .copyWith(color: foreground)),
                                  const SizedBox(height: 8),
                                  Text('Sign in to your Farm Estates account.',
                                      style: AppTypography.bodyMedium
                                          .copyWith(color: muted)),
                                  const SizedBox(height: 24),
                                  _label('Email address', foreground),
                                  TextFormField(
                                    key: const ValueKey('login-email'),
                                    controller: _emailController,
                                    enabled: !auth.isLoading,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                      AutofillHints.email
                                    ],
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    style: AppTypography.bodyMedium
                                        .copyWith(color: foreground),
                                    decoration: _decoration('name@example.com',
                                        Icons.mail_outline_rounded, dark),
                                    validator: (value) {
                                      final email = value?.trim() ?? '';
                                      if (email.isEmpty) {
                                        return 'Enter your email address';
                                      }
                                      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                          .hasMatch(email)) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  _label('Password', foreground),
                                  TextFormField(
                                    key: const ValueKey('login-password'),
                                    controller: _passwordController,
                                    enabled: !auth.isLoading,
                                    obscureText: _obscurePassword,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    autofillHints: const [
                                      AutofillHints.password
                                    ],
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _login(),
                                    style: AppTypography.bodyMedium
                                        .copyWith(color: foreground),
                                    decoration: _decoration(
                                            'Enter your password',
                                            Icons.lock_outline_rounded,
                                            dark)
                                        .copyWith(
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                        onPressed: auth.isLoading
                                            ? null
                                            : () => setState(() =>
                                                _obscurePassword =
                                                    !_obscurePassword),
                                        icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 20),
                                      ),
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Enter your password'
                                            : null,
                                  ),
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: auth.isLoading
                                            ? null
                                            : () => Navigator.pushNamed(
                                                context, '/forgot-password',
                                                arguments: _emailController.text
                                                    .trim()),
                                        style: TextButton.styleFrom(
                                            textStyle:
                                                AppTypography.labelLarge),
                                        child: const Text('Forgot password?'),
                                      )),
                                  if (auth.error != null &&
                                      ref
                                              .read(authServiceProvider)
                                              .passwordChangeToken ==
                                          null) ...[
                                    Semantics(
                                        liveRegion: true,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                              color: colors.errorContainer,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                    Icons.error_outline_rounded,
                                                    size: 18,
                                                    color: colors
                                                        .onErrorContainer),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                    child: Text(auth.error!,
                                                        style: AppTypography
                                                            .bodySmall
                                                            .copyWith(
                                                                color: colors
                                                                    .onErrorContainer))),
                                              ]),
                                        )),
                                    const SizedBox(height: 16),
                                  ],
                                  FilledButton(
                                    onPressed: auth.isLoading ? null : _login,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(48),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      textStyle: AppTypography.labelLarge,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (auth.isLoading) ...[
                                            const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2)),
                                            const SizedBox(width: 10),
                                          ],
                                          Flexible(
                                              child: Text(auth.isLoading
                                                  ? 'Signing in...'
                                                  : 'Sign in')),
                                        ]),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                      'New account? Use the temporary password sent to your email.',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodySmall
                                          .copyWith(color: muted)),
                                ]),
                          )),
                        ),
                        const SizedBox(height: 16),
                        Material(
                            color: Colors.transparent,
                            child: ExpansionTile(
                              key: const PageStorageKey('login-demo-accounts'),
                              tilePadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              shape: const Border(),
                              collapsedShape: const Border(),
                              title: Text('Demo accounts',
                                  style: AppTypography.bodySmall
                                      .copyWith(color: muted)),
                              children: DemoAccounts.all
                                  .map((account) => ListTile(
                                        leading: const Icon(
                                            Icons.person_outline_rounded,
                                            size: 20),
                                        title: Text(account.displayName,
                                            style: AppTypography.bodyMedium
                                                .copyWith(color: foreground)),
                                        subtitle: Text(account.email,
                                            style: AppTypography.bodySmall
                                                .copyWith(color: muted)),
                                        trailing: const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18),
                                        onTap: auth.isLoading
                                            ? null
                                            : () {
                                                _emailController.text =
                                                    account.email;
                                                _passwordController.text =
                                                    account.password;
                                                _login();
                                              },
                                      ))
                                  .toList(),
                            )),
                      ]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _label(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child:
            Text(text, style: AppTypography.labelLarge.copyWith(color: color)),
      );

  InputDecoration _decoration(String hint, IconData icon, bool dark) {
    final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: dark ? Colors.white12 : AppColors.neutral200));
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium
          .copyWith(color: dark ? Colors.white54 : AppColors.textSecondary),
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor:
          dark ? Colors.white.withValues(alpha: .04) : AppColors.neutral50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorMaxLines: 3,
    );
  }
}
