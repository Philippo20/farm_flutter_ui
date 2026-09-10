import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../screens/caretaker/chat_screen.dart';
import '../../services/messaging_service.dart';
import '../models/notification/notification_model.dart';
import '../providers/notification_provider.dart';

final messageNavigatorKey = GlobalKey<NavigatorState>();
final messageScaffoldKey = GlobalKey<ScaffoldMessengerState>();
final activeMessagePeerProvider = StateProvider<String?>((ref) => null);
final messageNotificationUserProvider = Provider<String?>(
    (ref) => ref.watch(authProvider.select((state) => state.user?.id)));

/// One session-scoped poller for every role, independent of the visible header.
class MessageNotificationHost extends ConsumerStatefulWidget {
  const MessageNotificationHost({super.key, required this.child, this.service});
  final Widget child;
  final MessagingService? service;
  @override
  ConsumerState<MessageNotificationHost> createState() =>
      _MessageNotificationHostState();
}

class _MessageNotificationHostState
    extends ConsumerState<MessageNotificationHost> with WidgetsBindingObserver {
  static const _android = MethodChannel('farmestates/message_notifications');
  late final _api = widget.service ?? MessagingService();
  Timer? _timer;
  String? _user;
  int _session = 0;
  bool _busy = false;
  bool _baseline = false;
  final _seen = <String>{};
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    messageNavigatorKey.currentState?.push(MaterialPageRoute<void>(
      builder: (_) => ChatScreen(initialPeerId: peer),
    ));
  }

  void _bind(String? user) {
    if (_user == user) return;
    _user = user;
    _session++;
    _timer?.cancel();
    _seen.clear();
    _baseline = false;
    ref.read(notificationProvider.notifier).clearAll();
    if (_isAndroid) _android.invokeMethod<void>('clear').ignore();
    if (user == null) return;
    if (_isAndroid) {
      _android.invokeMethod<void>('requestPermission').ignore();
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
    if (state == AppLifecycleState.resumed && _user != null) {
      unawaited(_refresh());
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    }
  }

  Future<void> _refresh() async {
    if (_busy || _user == null) return;
    _busy = true;
    final session = _session;
    try {
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
                  'messageId': row['message_id']
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
      if (_baseline && fresh.isNotEmpty) {
        final latest = fresh.first;
        final peer = latest.metadata!['peerId'] as String;
        if (_isAndroid) {
          // A single notification per conversation; new arrivals replace it.
          final peers = <String>{};
          for (final item in fresh) {
            if (!mounted || session != _session) return;
            final id = item.metadata!['peerId'] as String;
            if (!peers.add(id)) continue;
            await _android.invokeMethod<void>('show', {
              'peerId': id,
              'recipientId': _user,
              'title': item.title,
              'body': 'You have a new message',
            });
          }
        } else {
          messageScaffoldKey.currentState?.showSnackBar(SnackBar(
            content: Text('New message from ${latest.title}'),
            action: SnackBarAction(
                label: 'Open',
                onPressed: () {
                  if (session == _session) _open(peer);
                }),
          ));
        }
      }
      if (_isAndroid) {
        final unreadPeers = items
            .where((item) => !item.isRead)
            .map((item) => item.metadata!['peerId'])
            .toSet();
        for (final peer
            in items.map((item) => item.metadata!['peerId']).toSet()) {
          if (!mounted || session != _session) return;
          if (!unreadPeers.contains(peer) || peer == active) {
            await _android.invokeMethod<void>('dismiss', {'peerId': peer});
          }
        }
      }
      if (!mounted || session != _session) return;
      _seen.addAll(items.map((item) => item.id));
      _baseline = true;
    } catch (_) {
      // Keep the last successful inbox; reconnect automatically on the next tick.
    } finally {
      _busy = false;
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
    WidgetsBinding.instance.removeObserver(this);
    if (_isAndroid) _android.setMethodCallHandler(null);
    super.dispose();
  }
}
