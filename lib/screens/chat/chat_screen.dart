import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:radio_odan_app/providers/live_chat_provider.dart';
import 'package:radio_odan_app/providers/user_provider.dart';
import 'package:radio_odan_app/screens/chat/widget/chat_message_item.dart';
import 'package:radio_odan_app/screens/chat/widget/message_input_field.dart';
import 'package:radio_odan_app/screens/chat/widget/unread_messages_label.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';

class LiveChatScreen extends StatefulWidget {
  final int roomId;
  const LiveChatScreen({super.key, required this.roomId});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isUserScrolledUp = false;
  int _firstUnreadIndex = -1;
  int _lastMessageCount = 0;
  Timer? _scrollTimer;

  bool _isCurrentUser(String username) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final current = user?.name;
    if (current == null) return false;
    return current.toLowerCase() == username.toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    
    // Initialize user in the next frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      final prov = context.read<LiveChatProvider>();
      
      print('🎯 Initializing LiveChatScreen for room ${widget.roomId}');
      print('🎯 Current live status: ${prov.isLive}');
      
      if (user != null) {
        prov.setCurrentUserId(
          user.id,
          name: user.name,
          avatar: user.avatarUrl.isNotEmpty ? user.avatarUrl : null,
        );
        print('👤 User set: ${user.name} (${user.id})');
      } else {
        print('⚠️ No user logged in');
      }
      
      // Add listener for live status changes
      prov.addListener(_onLiveStatusChanged);
    });
  }

  void _handleScroll() {
    final prov = context.read<LiveChatProvider>();

    if (_scrollController.offset <=
            _scrollController.position.minScrollExtent + 200 &&
        !_scrollController.position.outOfRange) {
      prov.loadMore();
    }

    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 200), () {
      final isScrolledUp =
          _scrollController.offset <
          _scrollController.position.maxScrollExtent - 100;

      if (!mounted) return;
      setState(() {
        _isUserScrolledUp = isScrolledUp;
        if (!isScrolledUp) _firstUnreadIndex = -1;
      });
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollToUnreadMessages() {
    final messages = context.read<LiveChatProvider>().messages;
    if (_firstUnreadIndex == -1 || !_scrollController.hasClients) return;

    final offset =
        _scrollController.position.maxScrollExtent -
        (messages.length - _firstUnreadIndex) * 70;

    _scrollController.animateTo(
      offset.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage(LiveChatProvider prov) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final user = context.read<UserProvider>().user;
    final userName = user?.name ?? 'Anda';
    final userAvatar = user?.avatarUrl;

    try {
      await prov.send(text, username: userName, userAvatar: userAvatar);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showOnlineUsers(BuildContext context, LiveChatProvider prov) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pengguna Online',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: prov.onlineUsers.length,
                    itemBuilder: (context, index) {
                      final user = prov.onlineUsers[index];
                      final avatarUrl = user.userAvatar?.trim();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant,
                          child: ClipOval(
                            child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? Image.network(
                                    avatarUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/avatar.png',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/avatar.png',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        title: Text(
                          user.username,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Bergabung ${prov.formatTime(user.joinTime)}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final prov = context.read<LiveChatProvider>();
        await prov.leaveRoom();
        await prov.shutdown();
        return true;
      },
      child: Consumer<LiveChatProvider>(
        builder: (context, prov, _) {
          final colors = Theme.of(context).colorScheme;
          if (prov.isLoading) {
            return Scaffold(
              appBar: CustomAppBar(
                title: 'Live Chat',
                backgroundColor: colors.primary,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final messages = prov.messages;
          if (!_isUserScrolledUp) {
            _firstUnreadIndex = -1;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _scrollToBottom();
            });
          } else if (messages.length > _lastMessageCount &&
              _firstUnreadIndex == -1) {
            _firstUnreadIndex = _lastMessageCount;
          }
          _lastMessageCount = messages.length;

          final unreadCount = _firstUnreadIndex == -1
              ? 0
              : messages.length - _firstUnreadIndex;

          return Scaffold(
            appBar: CustomAppBar(
              title: prov.isLive ? 'Live Chat - ON AIR' : 'Live Chat',
              backgroundColor: colors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  await prov.leaveRoom();
                  await prov.shutdown();
                  if (!mounted) return;
                  Navigator.pop(context, 'goHome');
                },
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.people_alt),
                  onPressed: () => _showOnlineUsers(context, prov),
                ),
              ],
            ),
            body: Stack(
              children: [
                const AppBackground(),
                // The LiveChatScreen should only be shown when isLive is true
                // This is now handled by the ChatScreenWrapper
                // So we can safely assume we're live if we get here
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      bottom: 80,
                      left: 8,
                      right: 8,
                      top: 8,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      if (_isUserScrolledUp && index == _firstUnreadIndex) {
                        return Column(
                          children: [
                            UnreadMessagesLabel(count: unreadCount),
                            ChatMessageItem(
                              message: message,
                              isCurrentUser: _isCurrentUser(message.username),
                              time: prov.formatTime(message.timestamp),
                            ),
                          ],
                        );
                      }
                      return ChatMessageItem(
                        message: message,
                        isCurrentUser: _isCurrentUser(message.username),
                        time: prov.formatTime(message.timestamp),
                      );
                    },
                  ),
                if (_isUserScrolledUp && unreadCount > 0)
                  Positioned(
                    bottom: 80,
                    right: 16,
                    child: GestureDetector(
                      onTap: _scrollToUnreadMessages,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$unreadCount pesan baru',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (prov.isLive)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: MessageInputField(
                      controller: _messageController,
                      onSend: () => _sendMessage(prov),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onLiveStatusChanged() {
    final prov = context.read<LiveChatProvider>();
    print('🔄 Live status changed to: ${prov.isLive}');
    
    if (prov.isLive) {
      // If we just went live, scroll to bottom to show latest messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    
    if (mounted) {
      setState(() {
        // Trigger a rebuild when live status changes
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _messageController.dispose();
    _scrollTimer?.cancel();
    
    // Remove the status change listener
    try {
      final prov = context.read<LiveChatProvider>();
      prov.removeListener(_onLiveStatusChanged);
    } catch (e) {
      print('⚠️ Error removing listener: $e');
    }
    
    super.dispose();
  }
}
