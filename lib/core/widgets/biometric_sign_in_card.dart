import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/biometric_sign_in_service.dart';
import '../theme/app_typography.dart';

class BiometricSignInCard extends ConsumerStatefulWidget {
  const BiometricSignInCard({super.key});
  @override
  ConsumerState<BiometricSignInCard> createState() =>
      _BiometricSignInCardState();
}

class _BiometricSignInCardState extends ConsumerState<BiometricSignInCard> {
  BiometricSignInStatus _status = const BiometricSignInStatus();
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await ref.read(biometricSignInProvider).status();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _disable() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(biometricSignInProvider).disable();
      if (mounted) await _load();
    } on PlatformException {
      if (mounted) {
        setState(
            () => _error = 'Unable to remove fingerprint sign-in. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null || (!_status.available && !_status.enabled)) {
      return const SizedBox.shrink();
    }
    final enabled = _status.enabled &&
        _status.email?.toLowerCase() == user.email.toLowerCase();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.fingerprint_rounded, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Fingerprint sign-in',
                    style: AppTypography.titleSmall))
          ]),
          const SizedBox(height: 8),
          Text(
              enabled
                  ? 'Enabled for your account on this phone. Your account password is still required after a password change.'
                  : 'To enable faster sign-in, choose “Enable fingerprint sign-in on this phone” next time you sign in with your password.',
              style: AppTypography.bodySmall),
          if (enabled) ...[
            const SizedBox(height: 10),
            TextButton.icon(
                onPressed: _busy ? null : _disable,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.remove_circle_outline_rounded, size: 16),
                label: Text(_busy ? 'Removing…' : 'Remove from this phone'),
                style:
                    TextButton.styleFrom(textStyle: AppTypography.labelLarge)),
          ],
          if (_error != null)
            Text(_error!,
                style: AppTypography.bodySmall.copyWith(color: colors.error)),
        ]),
      ),
    );
  }
}
