import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/providers/live_chat_provider.dart';
import 'package:radio_odan_app/screens/chat/chat_screen.dart';

class ChatScreenWrapper extends StatefulWidget {
  final int roomId;
  const ChatScreenWrapper({Key? key, required this.roomId}) : super(key: key);

  @override
  State<ChatScreenWrapper> createState() => _ChatScreenWrapperState();
}

class _ChatScreenWrapperState extends State<ChatScreenWrapper> {
  late final LiveChatProvider _provider;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _provider = LiveChatProvider(roomId: widget.roomId);

    // 🔸 Hindari notify/setState saat build -> jalankan setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _provider.init();
        if (mounted) setState(() => _ready = true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal memuat obrolan')));
      }
    });
  }

  @override
  void dispose() {
    // 🔸 Tutup semua subscription + koneksi socket dengan rapi
    _provider.shutdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider, // pakai provider yang kita pegang sendiri
      child: _ready
          ? LiveChatScreen(roomId: widget.roomId)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
