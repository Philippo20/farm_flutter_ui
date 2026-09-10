import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import '../../services/messaging_service.dart';
import '../../core/widgets/message_notification_host.dart';
import '../../core/widgets/notification_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/caretaker_sidebar.dart';
import '../../core/widgets/caretaker_header.dart';
import '../../core/widgets/caretaker_mobile_bottom_nav.dart';
import '../../providers/auth_provider.dart';

/// Chat Screen for Caretaker
/// Communicate with farm owners and managers
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.initialPeerId});
  final String? initialPeerId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedNavIndex = 3;
  String? _selectedChat;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final _messageScrollController = ScrollController();
  final Map<String, String> _drafts = {};
  final Map<String, List<Map<String, dynamic>>> _threads = {};
  bool _unreadOnly = false;

  List<Map<String, dynamic>> get _messages =>
      _threads.putIfAbsent(_selectedChat ?? '', () => []);

  final _api = MessagingService();
  Timer? _poll;
  bool _refreshing = false;
  bool _sending = false;
  bool _loading = true;
  String? _syncError;
  String? _sendError;
  String? _requestId;
  String? _requestText;
  String? _requestPeer;
  bool _openedInitialPeer = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _poll?.cancel();
    if (state != AppLifecycleState.resumed) {
      ref.read(activeMessagePeerProvider.notifier).state = null;
    }
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    }
  }

  String _time(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    return DateFormat(date.year == now.year &&
                date.month == now.month &&
                date.day == now.day
            ? 'HH:mm'
            : 'MMM d')
        .format(date);
  }

  Future<void> _refresh() async {
    if (mounted && _foreground) {
      ref.read(activeMessagePeerProvider.notifier).state =
          ModalRoute.of(context)?.isCurrent == true ? _selectedChat : null;
    }
    if (!mounted ||
        !_foreground ||
        _refreshing ||
        _sending ||
        ModalRoute.of(context)?.isCurrent == false) return;
    _refreshing = true;
    final peer = _selectedChat;
    try {
      final chats = await _api.conversations();
      final messages = peer == null ? null : await _api.messages(peer);
      if (!mounted) return;
      final wasNearEnd = !_messageScrollController.hasClients ||
          _messageScrollController.position.extentAfter < 100;
      setState(() {
        _chats
          ..clear()
          ..addAll(chats.map((chat) => {
                ...chat,
                'avatar': (chat['name'] as String).trim().isEmpty
                    ? '?'
                    : (chat['name'] as String).trim()[0].toUpperCase(),
                'time': _time(chat['updated_at']),
              }));
        if (peer != null && messages != null) {
          _threads[peer] = messages
              .map((message) => {
                    ...message,
                    'time': _time(message['created_at']) +
                        (message['sender'] == 'me'
                            ? (message['read_at'] == '' ? ' · Sent' : ' · Read')
                            : '')
                  })
              .toList();
        }
        if (_selectedChat != null &&
            !_chats.any((chat) => chat['id'] == _selectedChat))
          _selectedChat = null;
        _loading = false;
        _syncError = null;
        if (!_openedInitialPeer) {
          _openedInitialPeer = true;
          if (_chats.any((chat) => chat['id'] == widget.initialPeerId)) {
            _selectedChat = widget.initialPeerId;
          }
        }
      });
      if (peer == _selectedChat &&
          _foreground &&
          messages != null &&
          ModalRoute.of(context)?.isCurrent != false) {
        if (wasNearEnd) _scrollToLatest();
        final unread = messages
            .where((item) => item['sender'] == 'other' && item['read_at'] == '')
            .map((item) => item['id'] as String)
            .toList();
        if (unread.isNotEmpty) await _api.markRead(peer!, unread);
      }
    } catch (error) {
      if (mounted)
        setState(() {
          _syncError = error.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
    } finally {
      _refreshing = false;
      if (mounted && peer != _selectedChat) unawaited(_refresh());
    }
  }

  void _selectChat(String? id) {
    if (_sending) return;
    if (_selectedChat != null)
      _drafts[_selectedChat!] = _messageController.text;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedChat = id;
      _messageController.text = _drafts[id] ?? '';
      if (id != null)
        _chats.firstWhere((chat) => chat['id'] == id)['unread'] = 0;
    });
    _sendError = null;
    _refresh();
    _scrollToLatest();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _messageScrollController.hasClients) {
        _messageScrollController
            .jumpTo(_messageScrollController.position.maxScrollExtent);
      }
    });
  }

  final List<Map<String, dynamic>> _chats = [];

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final peer = _selectedChat;
    if (text.isEmpty || peer == null || _sending) return;
    if (_requestId == null || _requestText != text || _requestPeer != peer) {
      _requestId = List.generate(
          24,
          (_) => Random.secure()
              .nextInt(256)
              .toRadixString(16)
              .padLeft(2, '0')).join();
      _requestText = text;
      _requestPeer = peer;
    }
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final saved = await _api.send(peer, text, _requestId!);
      if (!mounted) return;
      setState(() {
        final thread = _threads.putIfAbsent(peer, () => []);
        if (!thread.any((message) => message['id'] == saved['id']))
          thread
              .add({...saved, 'time': _time(saved['created_at']) + ' · Sent'});
        _drafts.remove(peer);
        _messageController.clear();
        _requestId = null;
      });
      _scrollToLatest();
    } catch (error) {
      if (mounted)
        setState(() =>
            _sendError = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _refresh();
      }
    }
  }

  @override
  void dispose() {
    final activePeer = ref.read(activeMessagePeerProvider.notifier);
    final peer = _selectedChat;
    Future.microtask(() {
      if (activePeer.mounted && activePeer.state == peer)
        activePeer.state = null;
    });
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _api.dispose();
    _messageScrollController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Caretaker';
    final userEmail = authState.user?.email ?? 'caretaker@farmestates.com';
    final userRole = 'Caretaker';

    if (authState.user?.role.displayName.toLowerCase() != 'caretaker') {
      return PopScope(
        canPop: _selectedChat == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _selectChat(null);
        },
        child: Scaffold(
          appBar: AppBar(
              actions: const [NotificationCenter()],
              title: const Text('Messages'),
              leading: BackButton(
                  onPressed: () => _selectedChat == null
                      ? Navigator.of(context).maybePop()
                      : _selectChat(null))),
          body: SafeArea(
              child: Padding(
                  padding: EdgeInsets.all(isMobile ? 0 : 20),
                  child: _buildWorkspace(isDark))),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? CaretakerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
              userName: userName,
              userEmail: userEmail,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar:
          isMobile && MediaQuery.viewInsetsOf(context).bottom == 0
              ? CaretakerMobileBottomNav(
                  selectedIndex: _selectedNavIndex,
                  onItemSelected: (index) =>
                      setState(() => _selectedNavIndex = index),
                )
              : null,
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String userRole) {
    return Row(children: [
      CaretakerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: userRole),
      Expanded(
          child: Column(children: [
        CaretakerHeader(userName: userName, onNotificationTap: () {}),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: _buildWorkspace(isDark))),
      ])),
    ]);
  }

  Widget _buildWorkspace(bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final split = constraints.maxWidth >= 720;
      return DecoratedBox(
        decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? Colors.white10 : AppColors.neutral200)),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: split
                ? Row(children: [
                    SizedBox(
                        width: constraints.maxWidth >= 1000 ? 320 : 280,
                        child: _buildChatListMobile(isDark)),
                    const VerticalDivider(width: 1),
                    Expanded(
                        child: _selectedChat == null
                            ? _buildEmptyChat(isDark)
                            : _buildChatMessages(isDark, showBack: false)),
                  ])
                : _selectedChat == null
                    ? _buildChatListMobile(isDark)
                    : _buildChatMessages(isDark)),
      );
    });
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return PopScope(
      canPop: _selectedChat == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _selectChat(null);
      },
      child: Column(children: [
        if (_selectedChat == null)
          CaretakerHeader(
            userName: userName,
            onNotificationTap: () {},
          ),
        Expanded(
            child: SafeArea(
                bottom: false,
                top: _selectedChat != null,
                child: _buildWorkspace(isDark))),
      ]),
    );
  }

  Widget _buildChatList(bool isDark) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_syncError != null && _chats.isEmpty)
      return _connectionNotice(_syncError!);
    final chats = _chats.where((chat) {
      if (_unreadOnly && (chat['unread'] as int) == 0) return false;
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return (chat['name'] as String).toLowerCase().contains(query) ||
          (chat['lastMessage'] as String).toLowerCase().contains(query);
    }).toList();

    if (chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No conversations match your search.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        final isSelected = _selectedChat == chat['id'];

        return InkWell(
          onTap: () {
            _selectChat(chat['id'] as String);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? AppColors.primary.withOpacity(0.18)
                      : AppColors.primary.withOpacity(0.08))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: AppColors.primary.withOpacity(0.14),
                      child: Text(
                        chat['avatar'] as String,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat['name'] as String,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat['lastMessage'] as String,
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chat['time'] as String,
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    if ((chat['unread'] as int) > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          (chat['unread'] as int).toString(),
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message Center',
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _syncError == null
                          ? 'Farm team messages'
                          : 'Connection interrupted',
                      style: AppTypography.caption.copyWith(
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            ChoiceChip(
                label: const Text('All'),
                showCheckmark: false,
                selected: !_unreadOnly,
                onSelected: (_) => setState(() => _unreadOnly = false)),
            ChoiceChip(
                label: const Text('Unread'),
                showCheckmark: false,
                selected: _unreadOnly,
                onSelected: (_) => setState(() => _unreadOnly = true)),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search conversations',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
              filled: true,
              fillColor:
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListMobile(bool isDark) {
    return Column(
      children: [
        _buildConversationHeader(isDark),
        Expanded(
          child: _buildChatList(isDark),
        ),
      ],
    );
  }

  Widget _buildChatMessages(bool isDark, {bool showBack = true}) {
    final selectedChatData =
        _chats.firstWhere((chat) => chat['id'] == _selectedChat);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.neutral200,
              ),
            ),
          ),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _selectChat(null);
                  },
                ),
              CircleAvatar(
                radius: 23,
                backgroundColor: AppColors.primary.withOpacity(0.14),
                child: Text(
                  selectedChatData['avatar'] as String,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedChatData['name'] as String,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(selectedChatData['role']?.toString() ?? 'Farm team',
                        style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary)),
                  ],
                ),
              ),
              if (!isMobile)
                Text(
                  'Farm team',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (_syncError != null) _connectionNotice(_syncError!),
        // Messages
        Expanded(
          child: Container(
            color:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            child: ListView.builder(
              controller: _messageScrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 36,
                vertical: 24,
              ),
              itemCount: _messages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Conversation history',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  );
                }
                final message = _messages[index - 1];
                final isMe = message['sender'] == 'me';

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 9),
                    constraints: BoxConstraints(
                      maxWidth: isMobile
                          ? (MediaQuery.of(context).size.width - 32) * 0.88
                          : 520,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppColors.primary
                          : (isDark ? AppColors.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      boxShadow: isDark
                          ? null
                          : const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['text'] as String,
                          style: AppTypography.bodyMedium.copyWith(
                            height: 1.35,
                            color: isMe
                                ? Colors.white
                                : (isDark
                                    ? Colors.white
                                    : AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            message['time'] as String,
                            style: AppTypography.caption.copyWith(
                              color: isMe
                                  ? Colors.white.withOpacity(0.7)
                                  : (isDark
                                      ? Colors.white38
                                      : AppColors.textSecondary),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_sendError != null) _connectionNotice(_sendError!, retrySend: true),
        // Message Input
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.neutral200,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  readOnly: _sending,
                  maxLength: 4000,
                  onChanged: (_) => setState(() {}),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Write a message…',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.backgroundDark
                        : AppColors.neutral100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Send message',
                onPressed: _sending || _messageController.text.trim().isEmpty
                    ? null
                    : _sendMessage,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                color: AppColors.primary,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _connectionNotice(String message, {bool retrySend = false}) {
    return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
          TextButton(
              onPressed: _sending
                  ? null
                  : () => retrySend ? _sendMessage() : _refresh(),
              child: const Text('Retry')),
        ]));
  }

  Widget _buildEmptyChat(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Select a chat to start messaging',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark
                  ? Colors.white.withOpacity(0.6)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
