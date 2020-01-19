// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'drawn_hand.dart';
import 'notifiers.dart';

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  MinuteTimer _minuteTimer = MinuteTimer();
  BackgroundControler _backgroundControler = BackgroundControler();

  @override
  initState() {
    super.initState();
    _minuteTimer.addListener(_updateSemantics);
  }

  @override
  dispose() {
    _minuteTimer.removeListener(_updateSemantics);
    super.dispose();
  }

  _updateSemantics() {
    final time = DateFormat.Hms().format(DateTime.now());
    SemanticsService.announce(time, TextDirection.ltr);
  }

  set brightness(Brightness brightness) {
    _backgroundControler.color =
        brightness != Brightness.light ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    brightness = Theme.of(context).brightness;
    return CustomPaint(
      foregroundPainter: TimePainter(
          secondHandColour: Colors.yellowAccent[400].withOpacity(0.8),
          hourArcColour: Colors.blue.withOpacity(0.7),
          repaint: FrameNotifier(),
          backgroundControler: _backgroundControler),
      painter: BackgroundPainter(controler: _backgroundControler),
    );
  }
}
