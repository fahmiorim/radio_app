import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/providers/live_chat_provider.dart';
import 'package:radio_odan_app/screens/chat/chat_screen.dart';
import 'package:radio_odan_app/screens/chat/widget/no_live_placeholder.dart';

class ChatScreenWrapper extends StatefulWidget {
  final int? roomId;
  const ChatScreenWrapper({Key? key, required this.roomId}) : super(key: key);

  // route KEMBALIKAN nilai bila ingin pop dengan result
  static Route<String?> route(int? roomId) => MaterialPageRoute<String?>(
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
    if (widget.roomId != null) {
      _provider = LiveChatProvider(roomId: widget.roomId!);
      // Schedule the initialization for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeProvider();
      });
    } else {
      // If no roomId, mark as initialized to show the placeholder
      _isInitialized = true;
    }
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
    if (widget.roomId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Chat'),
          leading: const BackButton(),
        ),
        body: const NoLivePlaceholder(),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Gagal memuat chat. Silakan coba lagi.'),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<LiveChatProvider>(
        builder: (context, prov, _) {
          // Only show LiveChatScreen if the broadcast is live
          if (prov.isLive) {
            return LiveChatScreen(roomId: widget.roomId!);
          } else {
            // Show the placeholder with a back button
            return Scaffold(
              appBar: AppBar(
                title: const Text('Live Chat'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: const NoLivePlaceholder(),
            );
          }
        },
      ),
    );
  }
}
