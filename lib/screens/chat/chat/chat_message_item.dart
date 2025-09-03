import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/chat_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final String time;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.time,
  });

  bool get _isPending => message.id.startsWith('temp_');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // batas lebar bubble maks 75% layar
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    // warna bubble
    final Color bubbleColor = isCurrentUser
        ? (isDark
              ? theme.colorScheme.primary.withOpacity(0.85)
              : theme.primaryColor)
        : (isDark ? const Color(0xFF1E1E1E) : Colors.grey[200]!);

    final Color pendingColor = isCurrentUser
        ? bubbleColor.withOpacity(0.65)
        : bubbleColor.withOpacity(0.85);

    final Color textColor = isCurrentUser
        ? Colors.white
        : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87);

    return Semantics(
      label:
          '${isCurrentUser ? "Pesan Anda" : "Pesan dari ${message.username}"} pukul $time',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            // avatar lawan bicara di kiri
            if (!isCurrentUser) ...[
              const SizedBox(width: 4),
              _Avatar(url: message.userAvatar, name: message.username),
              const SizedBox(width: 8),
            ],

            // bubble
            Flexible(
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 4.0,
                      bottom: 2.0,
                      right: 4.0,
                    ),
                    child: Text(
                      isCurrentUser ? 'You' : message.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.0,
                        color: isCurrentUser
                            ? theme.colorScheme.primary.withOpacity(
                                isDark ? 0.85 : 1,
                              )
                            : (isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                    ),
                  ),
                  Material(
                    color: _isPending ? pendingColor : bubbleColor,
                    elevation: 0,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12.0),
                      topRight: const Radius.circular(12.0),
                      bottomLeft: isCurrentUser
                          ? const Radius.circular(12.0)
                          : const Radius.circular(4.0),
                      bottomRight: isCurrentUser
                          ? const Radius.circular(4.0)
                          : const Radius.circular(12.0),
                    ),
                    child: InkWell(
                      // tap lama untuk copy
                      onLongPress: () async {
                        await Clipboard.setData(
                          ClipboardData(text: message.message),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tersalin ke clipboard'),
                              duration: Duration(milliseconds: 900),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12.0),
                        topRight: const Radius.circular(12.0),
                        bottomLeft: isCurrentUser
                            ? const Radius.circular(12.0)
                            : const Radius.circular(4.0),
                        bottomRight: isCurrentUser
                            ? const Radius.circular(4.0)
                            : const Radius.circular(12.0),
                      ),
                      child: Container(
                        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: SelectableText(
                          message.message,
                          enableInteractiveSelection: true,
                          selectionControls: materialTextSelectionControls,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15.0,
                            height: 1.25,
                          ),
                          // jaga kata super panjang (URL) biar tetap wrap
                          // NB: SelectableText udah softWrap secara default
                        ),
                      ),
                    ),
                  ),

                  // waktu + indikator pending
                  Padding(
                    padding: EdgeInsets.only(
                      right: isCurrentUser ? 4.0 : 0,
                      left: isCurrentUser ? 0 : 4.0,
                      top: 2.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                            fontSize: 11.0,
                          ),
                        ),
                        if (_isPending) ...[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCurrentUser
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.grey[300]!
                                          : theme.colorScheme.primary),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // avatar sendiri di kanan
            if (isCurrentUser) ...[
              const SizedBox(width: 4),
              _Avatar(url: message.userAvatar, name: message.username),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  const _Avatar({required this.name, this.url});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    Widget fallback() => CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      child: Text(
        (name.isNotEmpty ? name[0] : '?').toUpperCase(),
        style: const TextStyle(color: Colors.black87),
      ),
    );

    if (!hasUrl) return fallback();

    // Gunakan cache jika tersedia
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url!,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, __) => Container(color: Colors.black12),
          errorWidget: (_, __, ___) => fallback(),
        ),
      ),
    );
  }
}
