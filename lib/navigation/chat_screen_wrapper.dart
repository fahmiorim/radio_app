import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/providers/live_chat_provider.dart';
import 'package:radio_odan_app/screens/chat/chat_screen.dart';

class ChatScreenWrapper extends StatefulWidget {
  final int roomId;
  const ChatScreenWrapper({Key? key, required this.roomId}) : super(key: key);

  // route KEMBALIKAN nilai bila ingin pop dengan result
  static Route<String?> route(int roomId) => MaterialPageRoute<String?>(
    builder: (_) => ChatScreenWrapper(roomId: roomId),
  );

  @override
  State<ChatScreenWrapper> createState() => _ChatScreenWrapperState();
}

class _ChatScreenWrapperState extends State<ChatScreenWrapper> {
  late final LiveChatProvider _provider;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _provider = LiveChatProvider(roomId: widget.roomId);
    // Schedule the initialization for the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  Future<void> _initializeProvider() async {
    if (!mounted) return;
    
    try {
      await _provider.init();
      if (!mounted) return;
      
      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _hasError = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat obrolan')),
        );
      }
    }
  }

  @override
  void dispose() {
    _provider.shutdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LiveChatProvider>.value(
      value: _provider,
      child: Builder(
        builder: (context) {
          if (_hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Gagal memuat obrolan'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initializeProvider,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          if (!_isInitialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          return LiveChatScreen(roomId: widget.roomId);
        },
      ),
    );
  }
}
