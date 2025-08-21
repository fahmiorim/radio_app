import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../../models/chat_model.dart';
import '../../data/dummy_chat.dart'; // Import the data file

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<OnlineUser> _onlineUsers = [];
  final Random _random = Random();

  int _firstUnreadIndex = -1;
  bool _isUserScrolledUp = false;
  Timer? _scrollTimer;
  Timer? _chatSimulationTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _simulateLiveChat();
  }

  void _handleScroll() {
    if (_scrollTimer != null) {
      _scrollTimer!.cancel();
    }

    _scrollTimer = Timer(const Duration(milliseconds: 200), () {
      final isScrolledUp =
          _scrollController.position.pixels <
          _scrollController.position.maxScrollExtent - 100;

      setState(() {
        _isUserScrolledUp = isScrolledUp;

        // Mark all as read if scrolled to bottom
        if (!isScrolledUp) {
          _firstUnreadIndex = -1;
        }
      });
    });
  }

  void _simulateLiveChat() {
    // User join every 3-8 seconds
    _chatSimulationTimer = Timer.periodic(
      Duration(seconds: 3 + _random.nextInt(5)),
      (timer) => _addRandomUserJoin(),
    );

    // Random messages every 2-5 seconds
    _chatSimulationTimer = Timer.periodic(
      Duration(seconds: 2 + _random.nextInt(3)),
      (timer) => _addRandomMessage(),
    );
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);

      if (!_isUserScrolledUp) {
        // If at bottom, auto-scroll to new message
        _firstUnreadIndex = -1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else if (_firstUnreadIndex == -1) {
        // If scrolled up and this is first unread message
        _firstUnreadIndex = _messages.length - 1;
      }
    });
  }

  void _scrollToUnreadMessages() {
    if (_firstUnreadIndex == -1 || !_scrollController.hasClients) return;

    // Scroll to position above first unread message
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent -
          (_messages.length - _firstUnreadIndex) *
              70, // Estimate 70px per message
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _addRandomUserJoin() {
    final username = ChatData.getRandomUsername(_random);

    _addMessage(
      ChatMessage(
        id: 'join-${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        message: 'telah bergabung ke chat',
        timestamp: DateTime.now(),
        isSystemMessage: true,
        isJoinNotification: true,
      ),
    );

    // Add to online users
    setState(() {
      _onlineUsers.add(
        OnlineUser(username: username, joinTime: DateTime.now()),
      );
    });
  }

  void _addRandomMessage() {
    final username = ChatData.getRandomUsername(_random);
    final message = ChatData.getRandomMessage(_random);

    _addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    _addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: 'Anda',
        message: _messageController.text,
        timestamp: DateTime.now(),
      ),
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _firstUnreadIndex == -1
        ? 0
        : _messages.length - _firstUnreadIndex;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, 'goHome');
          },
        ),
        title: const Text('Live Chat'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt),
            onPressed: () {
              _showOnlineUsers(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 80, left: 8, right: 8),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              // Show unread divider only when scrolled up
              if (_isUserScrolledUp && index == _firstUnreadIndex) {
                return Column(
                  children: [
                    _buildUnreadMessagesLabel(unreadCount),
                    _buildChatItem(_messages[index]),
                  ],
                );
              }
              return _buildChatItem(_messages[index]);
            },
          ),

          // Show "X new messages" button only when scrolled up
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
                        color: Colors.black.withValues(alpha: 0.2),
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

          Positioned(bottom: 0, left: 0, right: 0, child: _buildMessageInput()),
        ],
      ),
    );
  }

  Widget _buildUnreadMessagesLabel(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[900]!.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count pesan belum dibaca',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(ChatMessage message) {
    if (message.isJoinNotification) {
      return _buildJoinNotification(message);
    }
    return _buildChatMessage(message);
  }

  Widget _buildChatMessage(ChatMessage message) {
    final isMe = message.username == 'Anda';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[800],
              child: Text(
                message.username.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),

          const SizedBox(width: 8),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[800] : Colors.grey[800],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    message.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinNotification(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFFE2C55),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${message.username} ${message.message}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFE2C55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showOnlineUsers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
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
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _onlineUsers.length,
                  itemBuilder: (context, index) {
                    final user = _onlineUsers[index];
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
                        'Bergabung ${_formatTime(user.joinTime)}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${difference.inDays} hari lalu';
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _chatSimulationTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
