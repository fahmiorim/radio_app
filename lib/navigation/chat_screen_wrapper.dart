import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/providers/live_chat_provider.dart';
import 'package:radio_odan_app/screens/chat/chat_screen.dart';
import 'package:radio_odan_app/screens/chat/widget/no_live_placeholder.dart';
import 'package:radio_odan_app/providers/live_status_provider.dart';

class ChatScreenWrapper extends StatefulWidget {
  final int? roomId;
  const ChatScreenWrapper({Key? key, this.roomId}) : super(key: key);

  // route KEMBALIKAN nilai bila ingin pop dengan result
  static Route<String?> route([int? roomId]) => MaterialPageRoute<String?> (
        builder: (_) => ChatScreenWrapper(roomId: roomId),
      );

  @override
  State<ChatScreenWrapper> createState() => _ChatScreenWrapperState();
}

class _ChatScreenWrapperState extends State<ChatScreenWrapper> {
  LiveChatProvider? _provider;
  bool _isInitialized = false;
  bool _hasError = false;
  late final LiveStatusProvider _statusProvider;

  @override
  void initState() {
    super.initState();
    _statusProvider = Provider.of<LiveStatusProvider>(context, listen: false);
    _statusProvider.addListener(_handleStatusChange);
    _handleStatusChange(initial: true);
  }

  void _handleStatusChange({bool initial = false}) {
    final isLive = _statusProvider.isLive;
    final roomId = _statusProvider.roomId;

    if (!isLive || roomId == null) {
      _provider?.shutdown();
      _provider = null;
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
      return;
    }

    if (_provider == null || _provider!.roomId != roomId) {
      _provider?.shutdown();
      _provider = LiveChatProvider(roomId: roomId);
      _isInitialized = false;
      _hasError = false;
      if (initial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeProvider();
        });
      } else {
        _initializeProvider();
      }
    }
  }

  Future<void> _initializeProvider() async {
    if (!mounted || _provider == null) return;

    try {
      await _provider!.init();
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
    _statusProvider.removeListener(_handleStatusChange);
    _provider?.shutdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_statusProvider.isLive || _statusProvider.roomId == null) {
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

    if (!_isInitialized || _provider == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _provider!,
      child: LiveChatScreen(roomId: _statusProvider.roomId!),
    );
  }
}
