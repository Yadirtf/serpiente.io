import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GamePreferences {
  static const String _boxName = 'game_preferences';
  static const String _selectedSkinKey = 'selectedSkinId';
  static const String _highScoreKey = 'highScore';
  static const String _coinsKey = 'coins';

  static Box? _box;

  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      debugPrint('Error inicializando Hive GamePreferences: $e');
    }
  }

  static String get selectedSkinId =>
      _box?.get(_selectedSkinKey, defaultValue: 'default') as String? ?? 'default';

  static int get highScore =>
      _box?.get(_highScoreKey, defaultValue: 0) as int? ?? 0;

  static int get coins =>
      _box?.get(_coinsKey, defaultValue: 0) as int? ?? 0;

  static Future<void> setSelectedSkinId(String value) async {
    try {
      await _box?.put(_selectedSkinKey, value);
    } catch (_) {}
  }

  static Future<void> setHighScore(int value) async {
    try {
      await _box?.put(_highScoreKey, value);
    } catch (_) {}
  }

  static Future<void> addCoins(int value) async {
    try {
      await _box?.put(_coinsKey, coins + value);
    } catch (_) {}
  }
}
