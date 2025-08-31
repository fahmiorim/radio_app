import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/live_chat_provider.dart';
import '../../providers/user_provider.dart';
import 'chat/chat_message_item.dart';
import 'chat/message_input_field.dart';
import 'chat/unread_messages_label.dart';
import 'chat/no_live_placeholder.dart';

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
    final userId = context.read<UserProvider>().user?.id;
    if (userId != null) {
      context.read<LiveChatProvider>().setCurrentUserId(userId);
    }
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

    try {
      await prov.send(text);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOnlineUsers(BuildContext context, LiveChatProvider prov) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
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
                const Text(
                  'User Online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: prov.onlineUsers.length,
                    itemBuilder: (context, index) {
                      final user = prov.onlineUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          child: Text(
                            user.username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          user.username,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Bergabung ${prov.formatTime(user.joinTime)}',
                          style: TextStyle(color: Colors.grey[400]),
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
    // Provider dibuat di atas (ChangeNotifierProvider), jadi tidak perlu init di sini
    return WillPopScope(
      onWillPop: () async {
        await context.read<LiveChatProvider>().shutdown();
        return true;
      },
      child: Consumer<LiveChatProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Live Chat')),
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
            appBar: AppBar(
              title: Text(prov.isLive ? 'Live Chat - ON AIR' : 'Live Chat'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
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
                if (!prov.isLive)
                  const NoLivePlaceholder()
                else
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
                          color: Colors.blue[800],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$unreadCount pesan baru',
                          style: const TextStyle(
                            color: Colors.white,
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

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _messageController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }
}
