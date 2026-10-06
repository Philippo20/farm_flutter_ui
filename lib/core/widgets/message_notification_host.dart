import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../screens/caretaker/chat_screen.dart';
import '../../services/messaging_service.dart';
import '../../services/local_alerts.dart';
import '../../services/android_push_registration.dart';
import 'notification_center.dart';
import '../models/notification/notification_model.dart';
import '../providers/notification_provider.dart';

final messageNavigatorKey = GlobalKey<NavigatorState>();
final messageScaffoldKey = GlobalKey<ScaffoldMessengerState>();
final activeMessagePeerProvider = StateProvider<String?>((ref) => null);
final messageNotificationUserProvider = Provider<String?>(
    (ref) => ref.watch(authProvider.select((state) => state.user?.id)));

/// One session-scoped poller for every role, independent of the visible header.
class MessageNotificationHost extends ConsumerStatefulWidget {
  const MessageNotificationHost(
      {super.key, required this.child, this.service, this.refreshInbox});
  final Widget child;
  final MessagingService? service;
  final Future<void> Function(String)? refreshInbox;
  @override
  ConsumerState<MessageNotificationHost> createState() =>
      _MessageNotificationHostState();
}

class _MessageNotificationHostState
    extends ConsumerState<MessageNotificationHost> with WidgetsBindingObserver {
  static const _android = MethodChannel('farmestates/message_notifications');
  late final _api = widget.service ?? MessagingService();
  final _push = AndroidPushRegistration();
  Timer? _timer;
  String? _user;
  int _session = 0;
  bool _busy = false;
  bool _baseline = false;
  final _seen = <String>{};
  final _shown = <String>{};
  final _local = LocalAlerts.instance;
  bool _inboxBaseline = false;
  final _seenInbox = <String>{};
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _push.bind(null);
    if (_isAndroid) {
      _android.setMethodCallHandler((call) async {
        if (call.method == 'openMessage' && mounted) {
          final data = Map<String, dynamic>.from(call.arguments as Map);
          if (data['recipientId'] == _user) _open(data['peerId'] as String);
        }
      });
    }
  }

  void _open(String peer) {
    if (_user == null) return;
    if (peer.startsWith('__inbox__:')) {
      final context = messageNavigatorKey.currentState?.overlay?.context;
      if (context != null) showNotificationDialog(context);
      return;
    }
    messageNavigatorKey.currentState?.push(MaterialPageRoute<void>(
      builder: (_) => ChatScreen(initialPeerId: peer),
    ));
  }

  void _bind(String? user) {
    if (_user == user) return;
    _user = user;
    _push.bind(user);
    _session++;
    _timer?.cancel();
    _seen.clear();
    _baseline = false;
    _inboxBaseline = false;
    _seenInbox.clear();
    _shown.clear();
    ref.read(notificationProvider.notifier).clearAll();
    unawaited(_local.clear());
    if (user == null) return;
    if (_isAndroid) {
      unawaited(_local.requestPermission());
      unawaited(_initialMessage(user));
    }
    unawaited(_refresh());
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  Future<void> _initialMessage(String user) async {
    try {
      final data =
          await _android.invokeMapMethod<String, dynamic>('initialMessage');
      if (mounted && _user == user && data?['recipientId'] == user) {
        _open(data!['peerId'] as String);
      }
    } catch (_) {
      // Other platforms do not implement the Android channel.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _timer?.cancel();
    if (_user != null &&
        (state == AppLifecycleState.resumed ||
            (kIsWeb ||
                    const [
                      TargetPlatform.windows,
                      TargetPlatform.linux,
                      TargetPlatform.macOS
                    ].contains(defaultTargetPlatform)) &&
                state != AppLifecycleState.detached)) {
      unawaited(_refresh());
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    }
  }

  Future<void> _refresh() async {
    if (_busy || _user == null) return;
    _busy = true;
    final session = _session;
    unawaited(_push.sync());
    try {
      final delivered = await _push.delivered();
      if (!mounted || session != _session) return;
      _seen.addAll(delivered.where((id) => id.startsWith('message:')));
      final workflowIds = delivered.where((id) => !id.startsWith('message:'));
      _seenInbox.addAll(workflowIds);
      _shown.addAll(workflowIds.map((id) => '__inbox__:$id'));
      final rows = await _api.notifications();
      if (!mounted || session != _session) return;
      final items = rows
          .map((row) => NotificationModel(
                id: row['id'] as String,
                title: row['title'] as String,
                message: row['message'] as String,
                type: NotificationType.message,
                createdAt: DateTime.parse(row['created_at'] as String),
                isRead: row['is_read'] == true,
                metadata: {
                  'peerId': row['peer_id'],
                  'messageId': row['message_id'],
                  'deliveryEnabled': row['delivery_enabled'] != false,
                  'silent': row['silent'] == true
                },
              ))
          .toList();
      ref.read(notificationProvider.notifier).replaceMessages(items);
      final active = ref.read(activeMessagePeerProvider);
      final fresh = items
          .where((item) =>
              !item.isRead &&
              !_seen.contains(item.id) &&
              item.metadata!['peerId'] != active)
          .toList();
      if (_baseline) {
        final peers = <String>{};
        for (final item in fresh) {
          final peer = item.metadata!['peerId'] as String;
          if (peers.add(peer)) await _deliver(peer, item, session);
        }
      }
      final unreadPeers = items
          .where((item) => !item.isRead)
          .map((item) => item.metadata!['peerId'] as String)
          .toSet();
      for (final peer
          in items.map((item) => item.metadata!['peerId'] as String).toSet()) {
        if (!mounted || session != _session) return;
        if (!unreadPeers.contains(peer) || peer == active) {
          await _local.dismiss(peer);
          _shown.remove(peer);
        }
      }
      if (!mounted || session != _session) return;
      _seen.addAll(items.map((item) => item.id));
      _baseline = true;
    } catch (_) {
      // Keep the last successful inbox; reconnect automatically on the next tick.
    } finally {
      if (mounted && session == _session) await _refreshInbox(session);
      _busy = false;
    }
  }

  Future<void> _deliver(String id, NotificationModel item, int session) async {
    if (!mounted || session != _session || _user == null) return;
    if (item.metadata?['deliveryEnabled'] == false) return;
    void open() {
      if (mounted && session == _session) _open(id);
    }

    // Keep private farm, financial and message content out of lock-screen previews.
    final delivered = await _local.show(
        id: id,
        user: _user!,
        title: item.type == NotificationType.message
            ? 'New team message'
            : item.title,
        body: 'Open Farm Estates to view the notification.',
        silent: item.metadata?['silent'] == true,
        onTap: open);
    if (!mounted || session != _session) {
      await _local.dismiss(id);
      return;
    }
    _shown.add(id);
    if (!delivered) {
      messageScaffoldKey.currentState?.showSnackBar(SnackBar(
        content: Text(item.title),
        action: SnackBarAction(label: 'Open', onPressed: open),
      ));
    }
  }

  Future<void> _refreshInbox(int session) async {
    try {
      final user = _user;
      if (user == null) return;
      if (widget.refreshInbox != null) {
        await widget.refreshInbox!(user);
      } else {
        await ref
            .read(notificationProvider.notifier)
            .refreshFromBackend(recipientId: user);
      }
      if (!mounted || session != _session) return;
      final items = ref
          .read(notificationProvider)
          .where((item) => item.type != NotificationType.message)
          .toList();
      for (final item in items) {
        if (!mounted || session != _session) return;
        final id = '__inbox__:${item.id}';
        if (_inboxBaseline && !item.isRead && !_seenInbox.contains(item.id)) {
          await _deliver(id, item, session);
        } else if (item.isRead && _shown.remove(id)) {
          await _local.dismiss(id);
        }
      }
      _seenInbox.addAll(items.map((item) => item.id));
      _inboxBaseline = true;
    } catch (_) {
      // Independent of chat failures; retry after reconnect without replaying alerts.
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(messageNotificationUserProvider);
    if (user != _user) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bind(ref.read(messageNotificationUserProvider));
      });
    }
    return widget.child;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _api.dispose();
    _push.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (_isAndroid) _android.setMethodCallHandler(null);
    super.dispose();
  }
}
