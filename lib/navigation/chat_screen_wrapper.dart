import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/providers/live_chat_provider.dart';
import 'package:radio_odan_app/providers/live_status_provider.dart';
import 'package:radio_odan_app/screens/chat/chat_screen.dart';
import 'package:radio_odan_app/screens/chat/widget/no_live_placeholder.dart';

class ChatScreenWrapper extends StatefulWidget {
  final int? roomId;
  const ChatScreenWrapper({super.key, this.roomId});

  static Route<String?> route([int? roomId]) => MaterialPageRoute<String?>(
    builder: (_) => ChatScreenWrapper(roomId: roomId),
  );

  @override
  State<ChatScreenWrapper> createState() => _ChatScreenWrapperState();
}

class _ChatScreenWrapperState extends State<ChatScreenWrapper> {
  LiveChatProvider? _provider;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _initInProgress = false;

  @override
  void initState() {
    super.initState();
    // minta status awal sekali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LiveStatusProvider>().refresh();
    });
  }

  Future<void> _ensureProviderForRoom(int roomId) async {
    if (_provider != null && _provider!.roomId == roomId && _isInitialized) {
      return;
    }
    if (_initInProgress) return;
    _initInProgress = true;

    try {
      await _provider?.shutdown();
    } catch (_) {}

    final prov = LiveChatProvider(roomId: roomId);
    setState(() {
      _provider = prov;
      _isInitialized = false;
      _hasError = false;
    });

    try {
      await prov.init();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal memuat obrolan')));
    } finally {
      _initInProgress = false;
    }
  }

  Future<void> _teardownProviderIfAny() async {
    try {
      await _provider?.shutdown();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _provider = null;
      _isInitialized = true;
      _hasError = false;
    });
  }

  @override
  void dispose() {
    _provider?.shutdown(); // fire-and-forget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLive = context.select<LiveStatusProvider, bool>((p) => p.isLive);
    final roomId = context.select<LiveStatusProvider, int?>((p) => p.roomId);

    if (!isLive || roomId == null) {
      if (_provider != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _teardownProviderIfAny(),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Chat'),
          leading: const BackButton(),
        ),
        body: const NoLivePlaceholder(),
      );
    }

    if (_provider == null || _provider!.roomId != roomId || !_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureProviderForRoom(roomId),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

    return ChangeNotifierProvider.value(
      value: _provider!,
      child: LiveChatScreen(roomId: roomId),
    );
  }
}
