import 'dart:async';
import 'package:flutter/foundation.dart';
import 'apple_price.dart';

class ApplePriceTicker {
  ApplePriceTicker._() : _startTime = DateTime.now();

  static final ApplePriceTicker instance = ApplePriceTicker._();

  ValueNotifier<int>? _priceNotifier;
  final DateTime _startTime;
  Timer? _timer;
  int _activeListeners = 0;

  void attach() {
    _activeListeners++;
    if (_activeListeners == 1) {
      _priceNotifier ??= ValueNotifier<int>(_currentPrice());
      _startTimer();
      _updatePrice();
    }
  }

  void detach() {
    if (_activeListeners == 0) {
      return;
    }
    _activeListeners--;
    if (_activeListeners == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updatePrice());
  }

  void _updatePrice() {
    final elapsed =
        DateTime.now().difference(_startTime).inMilliseconds / 1000.0;
    final newPrice = applePrice(elapsed);
    final notifier = _priceNotifier;
    if (notifier != null && notifier.value != newPrice) {
      notifier.value = newPrice;
    }
  }

  int _currentPrice() {
    final elapsed =
        DateTime.now().difference(_startTime).inMilliseconds / 1000.0;
    return applePrice(elapsed);
  }

  ValueListenable<int>? get price => _priceNotifier;
}
