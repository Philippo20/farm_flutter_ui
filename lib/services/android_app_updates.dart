import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'superadmin_api_service.dart';

enum AppUpdatePhase {
  available,
  downloading,
  verifying,
  ready,
  permission,
  installing,
  failed
}

class AndroidRelease {
  const AndroidRelease(
      {required this.build,
      required this.version,
      required this.packageName,
      required this.url,
      required this.sha256,
      required this.bytes,
      required this.notes});
  final int build, bytes;
  final String version, packageName, sha256, notes;
  final Uri url;

  factory AndroidRelease.parse(Map<String, dynamic> json, Uri source) {
    final build = json['buildNumber'];
    final bytes = json['sizeBytes'];
    final hash = '${json['sha256'] ?? ''}'.toLowerCase();
    final url = source.resolve('${json['apkUrl'] ?? ''}');
    if (build is! int ||
        build <= 0 ||
        bytes is! int ||
        bytes <= 0 ||
        bytes > 300 * 1024 * 1024 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
        source.scheme != 'https' ||
        url.origin != source.origin ||
        url.userInfo.isNotEmpty ||
        !url.path.startsWith('/downloads/') ||
        !url.path.endsWith('.apk') ||
        '${json['packageName'] ?? ''}'.isEmpty ||
        '${json['version'] ?? ''}'.isEmpty) {
      throw const FormatException('Invalid Android release metadata');
    }
    return AndroidRelease(
        build: build,
        version: '${json['version']}',
        packageName: '${json['packageName']}',
        url: url.replace(queryParameters: {...url.queryParameters, 'v': hash}),
        sha256: hash,
        bytes: bytes,
        notes: '${json['releaseNotes'] ?? ''}');
  }
}

/// Independent of API connectivity and user role; native DownloadManager survives
/// app suspension. Only explicit user actions start a download or installer.
class AndroidAppUpdates extends ChangeNotifier {
  AndroidAppUpdates(
      {http.Client? client, MethodChannel? channel, Uri? manifestUrl})
      : _client = client ?? http.Client(),
        _channel = channel ?? const MethodChannel('farmestates/app_updates'),
        _manifest = manifestUrl ??
            Uri.parse(
                '${SuperAdminApiService.uiBaseUrl}/downloads/android-release.json');
  final http.Client _client;
  final MethodChannel _channel;
  final Uri _manifest;
  AndroidRelease? release;
  AppUpdatePhase phase = AppUpdatePhase.available;
  double? progress;
  String? error;
  String currentVersion = '';
  bool busy = false, _disposed = false, _checking = false, _polling = false;
  bool _awaitingPermission = false;
  Timer? _timer;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> check() async {
    if (_disposed ||
        _checking ||
        busy ||
        phase == AppUpdatePhase.downloading ||
        phase == AppUpdatePhase.verifying) return false;
    _checking = true;
    try {
      final installed =
          await _channel.invokeMapMethod<String, dynamic>('installedVersion');
      final response = await _client.get(
          _manifest.replace(queryParameters: {
            't': '${DateTime.now().millisecondsSinceEpoch}',
          }),
          headers: {
            'Cache-Control': 'no-cache'
          }).timeout(const Duration(seconds: 12));
      if (_disposed ||
          response.statusCode != 200 ||
          response.bodyBytes.length > 32768) return false;
      final candidate = AndroidRelease.parse(
          Map<String, dynamic>.from(jsonDecode(response.body) as Map),
          _manifest);
      if (candidate.packageName != installed?['packageName'] ||
          candidate.build <= (installed?['buildNumber'] as int? ?? 0)) {
        release = null;
        return false;
      }
      release = candidate;
      currentVersion =
          '${installed?['version']} (${installed?['buildNumber']})';
      phase = AppUpdatePhase.available;
      error = null;
      final state =
          await _channel.invokeMapMethod<String, dynamic>('downloadState');
      if (_disposed) return false;
      if (state?['buildNumber'] == candidate.build &&
          state?['sha256'] == candidate.sha256) {
        await _applyDownloadState(state!);
      }
      _changed();
      return true;
    } catch (_) {
      // An unavailable optional update feed must never interrupt login or work.
      return false;
    } finally {
      _checking = false;
    }
  }

  Future<void> download() async {
    final update = release;
    if (update == null ||
        busy ||
        _disposed ||
        phase == AppUpdatePhase.downloading) return;
    busy = true;
    error = null;
    _changed();
    try {
      final state =
          await _channel.invokeMapMethod<String, dynamic>('startDownload', {
        'url': update.url.toString(),
        'sha256': update.sha256,
        'buildNumber': update.build,
        'sizeBytes': update.bytes,
      });
      if (!_disposed) await _applyDownloadState(state ?? {});
    } catch (_) {
      phase = AppUpdatePhase.failed;
      error =
          'The update could not be downloaded. Please check your connection and try again.';
    } finally {
      busy = false;
      _changed();
    }
  }

  void _startPolling() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_polling || _disposed) return;
    _polling = true;
    try {
      final state =
          await _channel.invokeMapMethod<String, dynamic>('downloadState');
      if (!_disposed) await _applyDownloadState(state ?? {});
    } catch (_) {
      _timer?.cancel();
      _timer = null;
      phase = AppUpdatePhase.failed;
      error = 'Unable to read download progress. Please try again.';
      _changed();
    } finally {
      _polling = false;
    }
  }

  Future<void> _applyDownloadState(Map<String, dynamic> state) async {
    final status = state['status'];
    if (status == 'complete') {
      _timer?.cancel();
      _timer = null;
      phase = AppUpdatePhase.verifying;
      progress = 1;
      _changed();
      try {
        await _channel.invokeMethod<void>('verifyDownload');
        if (_disposed) return;
        phase = AppUpdatePhase.ready;
      } catch (_) {
        phase = AppUpdatePhase.failed;
        error =
            'The downloaded update did not pass verification. Please download it again.';
      }
    } else if (status == 'failed' || status == 'missing') {
      _timer?.cancel();
      _timer = null;
      phase = AppUpdatePhase.failed;
      error = 'The download was interrupted. Please try again.';
    } else if (status == 'running' ||
        status == 'pending' ||
        status == 'paused') {
      phase = AppUpdatePhase.downloading;
      final total = state['totalBytes'] as num? ?? 0;
      final received = state['receivedBytes'] as num? ?? 0;
      progress = total > 0 ? (received / total).clamp(0.0, 1.0) : null;
      error = status == 'paused'
          ? 'Download paused. Android will resume it when the connection is available.'
          : null;
      _startPolling();
    }
    _changed();
  }

  Future<void> install() async {
    if (_disposed ||
        busy ||
        !{
          AppUpdatePhase.ready,
          AppUpdatePhase.installing,
          AppUpdatePhase.permission
        }.contains(phase)) return;
    busy = true;
    error = null;
    _changed();
    try {
      final result = await _channel.invokeMethod<String>('installDownload');
      phase = result == 'permission'
          ? AppUpdatePhase.permission
          : AppUpdatePhase.installing;
    } on PlatformException catch (failure) {
      phase = failure.code == 'invalid_update'
          ? AppUpdatePhase.failed
          : AppUpdatePhase.ready;
      error = failure.code == 'invalid_update'
          ? 'The update could not be verified. Please download it again.'
          : 'Unable to open the installer. Please try again.';
    } catch (_) {
      phase = AppUpdatePhase.ready;
      error = 'Unable to open the installer. Please try again.';
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> allowInstallation() async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _changed();
    try {
      _awaitingPermission = true;
      await _channel.invokeMethod<void>('allowInstallation');
    } catch (_) {
      _awaitingPermission = false;
      error =
          'Open Android settings and allow Farm Estates to install updates.';
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> resumed() async {
    if (!_awaitingPermission || _disposed) return;
    _awaitingPermission = false;
    if (await _channel.invokeMethod<bool>('canInstall') == true) {
      await install();
    } else {
      error =
          'Installation permission was not enabled. You can allow it and try again.';
      _changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}
