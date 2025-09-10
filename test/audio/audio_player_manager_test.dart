import 'package:flutter_test/flutter_test.dart';

import 'package:radio_odan_app/audio/audio_player_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AudioPlayerManager provides singleton instance', () {
    final a = AudioPlayerManager.instance;
    final b = AudioPlayerManager.instance;
    expect(identical(a, b), isTrue);
  });
}

