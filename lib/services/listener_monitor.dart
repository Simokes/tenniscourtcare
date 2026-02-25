import 'package:flutter/foundation.dart';

class ListenerMonitor {
  static final ListenerMonitor _instance = ListenerMonitor._internal();
  factory ListenerMonitor() => _instance;
  ListenerMonitor._internal();

  final Map<String, int> _activeListeners = {};

  void registerListener(String name) {
    _activeListeners[name] = (_activeListeners[name] ?? 0) + 1;
    _logActiveListeners();
  }

  void unregisterListener(String name) {
    if (_activeListeners.containsKey(name)) {
      _activeListeners[name] = (_activeListeners[name]! - 1);
      if (_activeListeners[name]! <= 0) {
        _activeListeners.remove(name);
      }
    }
    _logActiveListeners();
  }

  int getActiveListenerCount() {
    return _activeListeners.values.fold(0, (sum, count) => sum + count);
  }

  void _logActiveListeners() {
    if (kDebugMode) {
      final total = getActiveListenerCount();
      print('ListenerMonitor: Active Listeners: $total');
      _activeListeners.forEach((key, value) {
        print('  - $key: $value');
      });
    }
  }
}
