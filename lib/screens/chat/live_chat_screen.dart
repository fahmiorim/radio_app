import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/chat_model.dart';
import 'package:radio_odan_app/services/live_chat_socket_service.dart';

class LiveChatScreen extends StatefulWidget {
  final int roomId;

  const LiveChatScreen({super.key, required this.roomId});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  // Controllers and Lists
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<OnlineUser> _onlineUsers = [];

  // State Variables
  bool _isLive = false;
  bool _isLoading = true;
  bool _isLoadingMessages = false;
  bool _isUserScrolledUp = false;
  bool _hasMoreMessages = true;
  bool _isSocketInitialized = false;
  bool _statusSubscribed = false; // <-- cegah double subscribe

  // Counters and Indexes
  int _currentPage = 1;
  final int _messagesPerPage = 20;
  int _firstUnreadIndex = -1;

  // Other
  int? _currentRoomId;
  Timer? _scrollTimer;

  bool _isCurrentUser(String username) {
    // TODO: replace dengan cek user login
    return false;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _currentRoomId = widget.roomId; // <-- pakai roomId dari constructor

    // Set initial loading state
    _isLoading = true;

    // 1) Init socket
    _initializeSocket()
        // 2) Baru cek status live dari server
        .then((_) => _checkLiveStatus())
        .catchError((error) {
          print('❌ Error initializing: $error');
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isLive = false;
          });
        });
  }

  // SCROLL HANDLER (versi tunggal)
  void _handleScroll() {
    // Load older messages saat scroll ke atas (mendekati awal list)
    if (_scrollController.offset <=
            _scrollController.position.minScrollExtent + 200 &&
        !_scrollController.position.outOfRange) {
      _loadOldMessages();
    }

    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 200), () {
      // Jika posisi mendekati bawah, berarti tidak "scrolled up"
      final isScrolledUp =
          _scrollController.offset <
          _scrollController.position.maxScrollExtent - 100;

      if (!mounted) return;
      setState(() {
        _isUserScrolledUp = isScrolledUp;
        if (!isScrolledUp) {
          _firstUnreadIndex = -1;
        }
      });
    });
  }

  Future<void> _loadOldMessages() async {
    if (_isLoadingMessages || !_hasMoreMessages || _currentRoomId == null) {
      return;
    }

    setState(() => _isLoadingMessages = true);

    try {
      final messages = await LiveChatSocketService.I.fetchChatHistory(
        roomId: _currentRoomId!,
        page: _currentPage,
        perPage: _messagesPerPage,
      );

      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;

        if (messages.isEmpty) {
          _hasMoreMessages = false;
          return;
        }

        final newMessages = messages
            .map(
              (msg) => ChatMessage(
                id: msg['id'].toString(),
                username: msg['name'] ?? 'Unknown',
                message: msg['message'] ?? '',
                timestamp: DateTime.parse(msg['timestamp']),
              ),
            )
            .toList();

        // prepend ke atas (older first)
        _messages.insertAll(0, newMessages);
        _currentPage++;
      });
    } catch (e) {
      print('❌ Error loading old messages: $e');
      if (!mounted) return;
      setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _checkLiveStatus() async {
    try {
      print('🔄 Checking live status...');
      final status = await LiveChatSocketService.I.checkLiveStatus();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLive = status['isLive'] == true;

        final liveRoom = status['liveRoom'] as Map<String, dynamic>?;
        if (liveRoom != null && liveRoom['id'] != null) {
          _currentRoomId = liveRoom['id'] as int;

          // Load initial messages saat live
          if (_isLive) {
            _currentPage = 1;
            _hasMoreMessages = true;
            _messages.clear();
            _loadOldMessages();
          }
        } else if (!_isLive) {
          _messages.clear();
        }

        print('✅ Live status: ${_isLive ? 'LIVE' : 'NOT LIVE'}');
      });
    } catch (e) {
      // 404 atau error lain → anggap NOT LIVE, jangan crash
      print('❌ Error checking live status: $e');
      if (!mounted) return;
      setState(() {
        _isLive = false;
        _isLoading = false;
        _messages.clear();
      });
    }
  }

  Future<void> _initializeSocket() async {
    if (_isSocketInitialized) {
      print('ℹ️ Socket already initialized');
      return;
    }

    print('🔌 Menghubungkan ke server WebSocket...');
    await LiveChatSocketService.I.connect();
    print('✅ Terhubung ke WebSocket');

    _isSocketInitialized = true;

    // Subscribe ke channel status **sekali saja**
    if (!_statusSubscribed) {
      print('📡 Berlangganan ke channel status...');
      try {
        await LiveChatSocketService.I.subscribeStatus(
          onUpdated: (roomId, status) {
            final isLive = (status ?? '').toString().toLowerCase() == 'started';
            if (!mounted) return;
            setState(() {
              _isLive = isLive;
              if (!isLive) {
                _messages.clear();
              } else {
                // saat live dimulai, refresh room & history
                _currentRoomId = roomId ?? _currentRoomId;
                _currentPage = 1;
                _hasMoreMessages = true;
                _messages.clear();
                _loadOldMessages();
              }
            });
            print('🔄 Live status updated from socket: $_isLive');
          },
        );
        _statusSubscribed = true;
        print('✅ Status subscription active');
      } catch (e) {
        // Tangkap "Already subscribed…" dan jangan rethrow
        final msg = e.toString();
        if (msg.contains('Already subscribed')) {
          _statusSubscribed = true;
          print('ℹ️ Sudah subscribe, diabaikan.');
        } else {
          print('❌ Gagal subscribe status: $e');
          rethrow;
        }
      }
    }
  }

  void _addMessage(ChatMessage message) {
    if (!mounted) return;

    setState(() {
      _messages.add(message);

      if (!_isUserScrolledUp) {
        _firstUnreadIndex = -1;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else if (_firstUnreadIndex == -1) {
        _firstUnreadIndex = _messages.length - 1;
      }
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
    if (_firstUnreadIndex == -1 || !_scrollController.hasClients) return;

    final offset =
        _scrollController.position.maxScrollExtent -
        (_messages.length - _firstUnreadIndex) * 70;

    _scrollController.animateTo(
      offset.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
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
    final isCurrentUser = _isCurrentUser(message.username);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              child: Text(
                message.username.isNotEmpty
                    ? message.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser) ...[
                  Text(
                    message.username,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? const Color(0xFF1E88E5)
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    message.message,
                    style: const TextStyle(color: Colors.white, fontSize: 14.0),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(color: Colors.grey[500], fontSize: 10.0),
                ),
              ],
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8.0),
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey,
              child: Text('A', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    if (!_isLive) return const SizedBox.shrink();

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

    if (difference.inMinutes < 1) return 'baru saja';
    if (difference.inHours < 1) return '${difference.inMinutes} menit lalu';
    if (difference.inDays < 1) return '${difference.inHours} jam lalu';
    return '${difference.inDays} hari lalu';
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            username: 'Anda',
            message: text,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    } catch (e) {
      print('❌ Error sending message: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim pesan. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Chat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final unreadCount = _firstUnreadIndex == -1
        ? 0
        : _messages.length - _firstUnreadIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLive ? 'Live Chat - ON AIR' : 'Live Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, 'goHome'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt),
            onPressed: () => _showOnlineUsers(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_isLive)
            _buildNotLiveOverlay(context)
          else
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                bottom: 80,
                left: 8,
                right: 8,
                top: 8,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
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
          Positioned(bottom: 0, left: 0, right: 0, child: _buildMessageInput()),
        ],
      ),
    );
  }

  Widget _buildNotLiveOverlay(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFE2C55).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.radio_outlined,
                  size: 64,
                  color: const Color(0xFFFE2C55).withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tidak Ada Siaran Saat Ini',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Siaran belum dimulai atau sedang dalam jeda. Nantikan siaran berikutnya!',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFE2C55), Color(0xFFFF5A5F)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFE2C55).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Aktifkan Notifikasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, 'goHome'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.grey[700]!,
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Kembali ke Beranda',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _scrollTimer?.cancel();

    try {
      LiveChatSocketService.I.disconnect();
    } catch (e) {
      print('Error disconnecting socket: $e');
    }
    super.dispose();
  }
}
