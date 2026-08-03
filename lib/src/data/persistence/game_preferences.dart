import 'package:hive_flutter/hive_flutter.dart';

class GamePreferences {
  static const String _boxName = 'game_preferences';
  static const String _selectedSkinKey = 'selectedSkinId';
  static const String _highScoreKey = 'highScore';
  static const String _coinsKey = 'coins';

  static late Box _box;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static String get selectedSkinId => _box.get(_selectedSkinKey, defaultValue: 'default') as String;

  static int get highScore => _box.get(_highScoreKey, defaultValue: 0) as int;

  static int get coins => _box.get(_coinsKey, defaultValue: 0) as int;

  static Future<void> setSelectedSkinId(String value) async {
    await _box.put(_selectedSkinKey, value);
  }

  static Future<void> setHighScore(int value) async {
    await _box.put(_highScoreKey, value);
  }

  static Future<void> addCoins(int value) async {
    await _box.put(_coinsKey, coins + value);
  }
}
