// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// [CustomPainter] that draws a clock hand.
class TimePainter extends CustomPainter {
  TimePainter(
      {@required this.secondHandColour,
      @required this.hourArcColour,
      @required this.backgroundControler,
      Listenable repaint})
      : assert(secondHandColour != null),
        assert(hourArcColour != null),
        super(repaint: repaint);

  final Color secondHandColour;
  final Color hourArcColour;
  final BackgroundControler backgroundControler;

  @override
  void paint(Canvas canvas, Size size) {
    double radius = _calcRadius(size);
    Offset center = Offset(size.width / 2, size.height / 2);
    DateTime time = DateTime.now();

    final Paint secondHandPaint = Paint()..color = secondHandColour;
    final Paint hourArcPaint = Paint()..color = hourArcColour;
    final Paint clearPaint = Paint()..color = backgroundControler.color;

    final double hourFraction = (time.hour * 60 + time.minute) / 1440;
    final double hourArcStart = hourFraction <= 0.5
        ? -math.pi / 2
        : 4 * math.pi * (hourFraction - 0.625);
    final double hourArcEnd = hourFraction <= 0.5
        ? 4 * math.pi * (hourFraction - 0.125)
        : 3 * math.pi / 2;

    final double secondHandWidth =
        (time.minute * 60 + time.second) * 2 * math.pi / 3600;
    final double secondHandCenter =
        (time.second * 1000 + time.millisecond) * 2 * math.pi / 60000 -
            math.pi / 2;

    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
        rect, hourArcStart, hourArcEnd - hourArcStart, true, hourArcPaint);

    canvas.drawArc(
        rect.deflate(radius * 0.2),
        secondHandCenter - (secondHandWidth / 2),
        secondHandWidth,
        true,
        secondHandPaint);

    canvas.drawCircle(rect.deflate(radius * 0.8).center,
        rect.deflate(radius * 0.8).width / 2, clearPaint);

    canvas.drawArc(rect.deflate(radius * 0.8), hourArcStart,
        hourArcEnd - hourArcStart, true, hourArcPaint);

    hourArcPaint.blendMode = BlendMode.multiply;
    canvas.drawArc(
        rect, hourArcStart, hourArcEnd - hourArcStart, true, hourArcPaint);
  }

  double _calcRadius(Size size) {
    bool isXLimmiting = size.aspectRatio < 1;
    if (isXLimmiting) {
      return (size.width * 0.8 / 2);
    } else {
      return (size.height * 0.8 / 2);
    }
  }

  @override
  bool shouldRepaint(TimePainter oldDelegate) =>
      oldDelegate.secondHandColour == secondHandColour &&
      oldDelegate.hourArcColour == hourArcColour &&
      oldDelegate.backgroundControler == backgroundControler;
}

/// [CustomPainter] that paints the background gradient.`
class BackgroundPainter extends CustomPainter {
  BackgroundPainter({@required this.controler}) : super(repaint: controler);

  final BackgroundControler controler;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect =
        Rect.fromPoints(Offset(0, 0), Offset(size.width, size.height));
    final Paint paint = Paint()..color = controler.color;

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) =>
      oldDelegate.controler != controler;
}

class BackgroundControler extends ChangeNotifier {
  Color _colorBefore;
  Color _colorAfter;

  DateTime _animationStart;
  Ticker _ticker;

  BackgroundControler() {
    _ticker = Ticker(_tick);
  }

  Color get color {
    if (_animationStart == null) {
      return _colorAfter;
    }
    Duration dif = DateTime.now().difference(_animationStart);
    double dt = dif.inMilliseconds / 1000;
    if (dt < 0 || dt > 1) {
      _animationStart = null;
      _ticker.stop();
      return _colorAfter;
    }
    return Color.alphaBlend(
        _colorAfter.withOpacity(Curves.easeInOut.transform(dt)), _colorBefore);
  }

  set color(Color newColor) {
    _colorBefore = color;
    _colorAfter = newColor;
    if (_colorBefore == null) {
      notifyListeners(); //to update the background painter for the first frame
      return;
    }

    _ticker.stop();
    _animationStart = DateTime.now();
    _ticker.start();
  }

  _tick(Duration d) {
    notifyListeners();
  }

  @override
  dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
