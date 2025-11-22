import 'package:flutter/foundation.dart';

class InventoryManager {
  static final ValueNotifier<Map<String, int>> _countsNotifier =
      ValueNotifier<Map<String, int>>({});
  static bool _initialized = false;

  static ValueListenable<Map<String, int>> get listenable => _countsNotifier;

  static Map<String, int> get counts => _countsNotifier.value;

  static bool get isInitialized => _initialized;

  static void initializeIfEmpty(Map<String, int> initialCounts) {
    if (_initialized && _countsNotifier.value.isNotEmpty) {
      return;
    }
    _countsNotifier.value = Map<String, int>.from(initialCounts);
    _initialized = true;
  }

  static void addItem(String id, int amount) {
    if (amount == 0) return;
    if (!_initialized) {
      _initialized = true;
    }
    final updated = Map<String, int>.from(_countsNotifier.value);
    updated[id] = (updated[id] ?? 0) + amount;
    if ((updated[id] ?? 0) <= 0) {
      updated.remove(id);
    }
    _countsNotifier.value = updated;
  }

  static bool spendItem(String id, int amount) {
    final current = counts[id] ?? 0;
    if (current < amount) {
      return false;
    }
    addItem(id, -amount);
    return true;
  }
}
