import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class MinuteTimer extends ChangeNotifier {
  Timer _timer;

  MinuteTimer() {
    _onTick();
  }

  @override
  dispose() {
    _timer.cancel();
    super.dispose();
  }

  _onTick() {
    DateTime _now = DateTime.now();
    _timer = Timer(
      Duration(minutes: 1) - Duration(seconds: _now.second),
      _onTick,
    );
    notifyListeners();
  }
}

class FrameNotifier extends ChangeNotifier {
  Ticker ticker;

  FrameNotifier() {
    this.ticker = Ticker(_onTick)..start();
  }

  _onTick(Duration d) {
    notifyListeners();
  }
}
