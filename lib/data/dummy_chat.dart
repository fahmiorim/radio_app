import 'dart:math';

class ChatData {
  static const List<String> randomUsernames = [
    'user_123',
    'flutter_lover',
    'dart_master',
    'coding_guy',
    'music_fan',
    'radio_listener',
    'Agung_surya',
  ];

  static const List<String> randomMessages = [
    'Halo semua!',
    'Apa kabar?',
    'Ini keren banget!',
    'Saya baru join',
    'Bagus nih',
    '👍👍👍',
    'Apo can ni....',
  ];

  static String getRandomUsername(Random random) {
    return randomUsernames[random.nextInt(randomUsernames.length)];
  }

  static String getRandomMessage(Random random) {
    return randomMessages[random.nextInt(randomMessages.length)];
  }
}
