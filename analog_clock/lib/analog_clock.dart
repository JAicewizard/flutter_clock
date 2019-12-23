// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateModel();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _minuteTimer?.removeListener(_updateSemantics());
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    _backgroundControler.color = [
      Color.alphaBlend(
          Colors.red.withOpacity(
              _backgroundColorBlend(widget.model.high, widget.model.unit)),
          Colors.blue),
      Color.alphaBlend(
          Colors.red.withOpacity(
              _backgroundColorBlend(widget.model.low, widget.model.unit)),
          Colors.blue),
    ];
  }

  double _backgroundColorBlend(num temp, TemperatureUnit unit) {
    switch (unit) {
      case TemperatureUnit.celsius:
        double b = (temp - 5) / 30; // Range from 5-35C
        if (b <= 0) {
          b = 0;
        } else if (b >= 1) {
          b = 1;
        }
        return b;
      case TemperatureUnit.fahrenheit:
        double b = (temp - 40) / 55; // Range from 5-35C
        if (b <= 0) {
          b = 0;
        } else if (b >= 1) {
          b = 1;
        }
        return b;
    }
  }

  _updateSemantics() {
    final time = DateFormat.Hms().format(DateTime.now());
    SemanticsService.announce(time, TextDirection.ltr);
  }

  @override
  Widget build(BuildContext context) {
    final customTheme = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).copyWith(
            primaryColor: Color(0xFF4285F4),
            highlightColor: Color(0xFF8AB4F8),
            accentColor: Color(0xFF669DF6),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFFD2E3FC),
            highlightColor: Color(0xFF4285F4),
            accentColor: Color(0xFF8AB4F8),
          );
    return Container(
      color: customTheme.backgroundColor,
      child: Center(
        child: SizedBox.expand(
          child: CustomPaint(
            foregroundPainter: HandPainter(
              color: customTheme.primaryColor,
              repaint: FrameNotifier(),
            ),
            painter: BackgroundPainter(controler: _backgroundControler),
          ),
        ),
      ),
    );
  }
}
