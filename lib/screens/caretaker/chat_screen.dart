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
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedNavIndex = 3;
  String? _selectedChat;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _chats = [
    {
      'id': 'CHAT001',
      'name': 'Farm Owner',
      'lastMessage': 'How are the plants doing today?',
      'time': '10:30 AM',
      'unread': 2,
      'avatar': 'O',
    },
    {
      'id': 'CHAT002',
      'name': 'Farm Manager',
      'lastMessage': 'Please confirm the input delivery',
      'time': '9:15 AM',
      'unread': 0,
      'avatar': 'M',
    },
    {
      'id': 'CHAT003',
      'name': 'Technician',
      'lastMessage': 'Equipment maintenance scheduled',
      'time': 'Yesterday',
      'unread': 1,
      'avatar': 'T',
    },
  ];

  final List<Map<String, dynamic>> _messages = [
    {
      'id': 'MSG001',
      'text': 'Hello! How can I help you today?',
      'sender': 'other',
      'time': '10:00 AM',
    },
    {
      'id': 'MSG002',
      'text': 'How are the plants doing today?',
      'sender': 'other',
      'time': '10:30 AM',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Caretaker';
    final userEmail = authState.user?.email ?? 'caretaker@farmestates.com';
    final userRole = 'Caretaker';

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
      bottomNavigationBar: isMobile
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
    return Row(
      children: [
        CaretakerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
        ),
        Expanded(
          child: Column(
            children: [
              CaretakerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 360,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        border: Border(
                          right: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : AppColors.neutral200,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildConversationHeader(isDark),
                          Expanded(
                            child: _buildChatList(isDark),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _selectedChat != null
                          ? _buildChatMessages(isDark)
                          : _buildEmptyChat(isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        CaretakerHeader(
          userName: userName,
          onNotificationTap: () {},
        ),
        Expanded(
          child: _selectedChat != null
              ? _buildChatMessages(isDark)
              : _buildChatListMobile(isDark),
        ),
      ],
    );
  }

  Widget _buildChatList(bool isDark) {
    final chats = _chats.where((chat) {
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
            setState(() => _selectedChat = chat['id']);
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark ? AppColors.surfaceDark : Colors.white,
                            width: 2,
                          ),
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
                      'Messages',
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_chats.length} conversations',
                      style: AppTypography.caption.copyWith(
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'New message',
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
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

  Widget _buildChatMessages(bool isDark) {
    final selectedChatData =
        _chats.firstWhere((chat) => chat['id'] == _selectedChat);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

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
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() => _selectedChat = null);
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
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Active now',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
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
              IconButton(
                tooltip: 'Conversation options',
                icon: const Icon(Icons.more_horiz_rounded),
                onPressed: () {},
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: Container(
            color:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            child: ListView.builder(
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
                            'Today',
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
                          ? MediaQuery.of(context).size.width * 0.78
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
              IconButton(
                tooltip: 'Attach file',
                onPressed: () {},
                icon: const Icon(Icons.attach_file_rounded),
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Write a message to the farm team',
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
                onPressed: () {
                  final text = _messageController.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      _messages.add({
                        'id': 'MSG${_messages.length + 1}',
                        'text': text,
                        'sender': 'me',
                        'time': 'Now',
                      });
                      _messageController.clear();
                    });
                  }
                },
                icon: const Icon(Icons.send),
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

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/caretaker_dashboard'
      },
      {
        'icon': Icons.edit_note_outlined,
        'label': 'Record',
        'index': 1,
        'route': '/record-entry'
      },
      {
        'icon': Icons.check_circle_outline,
        'label': 'Confirm',
        'index': 2,
        'route': '/input-confirmation'
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'Chat',
        'index': 3,
        'route': '/chat'
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Calendar',
        'index': 4,
        'route': '/calendar'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == _selectedNavIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
                        try {
                          Navigator.pushReplacementNamed(context, route);
                        } catch (e) {
                          try {
                            Navigator.pushNamed(context, route);
                          } catch (e2) {
                            debugPrint('Navigation error: $e2');
                          }
                        }
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.textSecondary),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
