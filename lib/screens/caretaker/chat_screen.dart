import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/caretaker_sidebar.dart';
import '../../core/widgets/caretaker_header.dart';
import '../../providers/auth_provider.dart';

/// Chat Screen for Caretaker
/// Communicate with farm owners and managers
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  int _selectedNavIndex = 3;
  String? _selectedChat;
  final TextEditingController _messageController = TextEditingController();

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
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
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
          child: Row(
            children: [
              // Chat List
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  border: Border(
                    right: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'Chats',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildChatList(isDark),
                    ),
                  ],
                ),
              ),
              // Chat Messages
              Expanded(
                child: _selectedChat != null
                    ? _buildChatMessages(isDark)
                    : _buildEmptyChat(isDark),
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
    return ListView.builder(
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        final isSelected = _selectedChat == chat['id'];

        return InkWell(
          onTap: () {
            setState(() => _selectedChat = chat['id']);
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? AppColors.primary.withOpacity(0.1) : AppColors.primary.withOpacity(0.05))
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral200,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    chat['avatar'] as String,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat['name'] as String,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat['lastMessage'] as String,
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
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
                        color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary,
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

  Widget _buildChatListMobile(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Chats',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        Expanded(
          child: _buildChatList(isDark),
        ),
      ],
    );
  }

  Widget _buildChatMessages(bool isDark) {
    final selectedChatData = _chats.firstWhere((chat) => chat['id'] == _selectedChat);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
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
                backgroundColor: AppColors.primary,
                child: Text(
                  selectedChatData['avatar'] as String,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  selectedChatData['name'] as String,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isMe = message['sender'] == 'me';

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? MediaQuery.of(context).size.width * 0.75 : 400,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary
                        : (isDark ? AppColors.surfaceDark : AppColors.neutral100),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['text'] as String,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isMe ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message['time'] as String,
                        style: AppTypography.caption.copyWith(
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Message Input
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.backgroundDark : AppColors.neutral100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: () {
                  if (_messageController.text.isNotEmpty) {
                    setState(() {
                      _messages.add({
                        'id': 'MSG${_messages.length + 1}',
                        'text': _messageController.text,
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
            color: isDark ? Colors.white.withOpacity(0.3) : AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Select a chat to start messaging',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
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
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
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
                              : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
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
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
