import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/superadmin_api_service.dart';

bool showAndroidDownload(
        {required bool web, required TargetPlatform platform}) =>
    web ||
    {TargetPlatform.windows, TargetPlatform.macOS, TargetPlatform.linux}
        .contains(platform);

Uri androidApkUri({required bool web, required Uri browserBase}) {
  const override = String.fromEnvironment('ANDROID_APK_URL');
  if (override.isNotEmpty) return Uri.parse(override);
  final base =
      web ? browserBase : Uri.parse('${SuperAdminApiService.uiBaseUrl}/');
  return base.resolve('/downloads/farm-estates.apk');
}

class AndroidDownloadButton extends StatelessWidget {
  const AndroidDownloadButton({super.key});
  @override
  Widget build(BuildContext context) {
    if (!showAndroidDownload(web: kIsWeb, platform: defaultTargetPlatform))
      return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Download Android APK',
      constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
      padding: const EdgeInsets.all(8),
      icon: const Icon(Icons.android_rounded, size: 21),
      onPressed: () async {
        try {
          final uri = androidApkUri(web: kIsWeb, browserBase: Uri.base);
          if (!{'http', 'https'}.contains(uri.scheme) ||
              !await launchUrl(uri,
                  mode: LaunchMode.externalApplication,
                  webOnlyWindowName: '_self')) {
            throw StateError('Download unavailable');
          }
        } catch (_) {
          if (context.mounted)
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Unable to open the Android download. Please try again.')));
        }
      },
    );
  }
}
