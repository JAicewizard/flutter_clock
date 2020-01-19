// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// [CustomPainter] that draws a clock hand.
class HandPainter extends CustomPainter {
  HandPainter(
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

    Paint secondHandPaint = Paint();
    secondHandPaint.color = secondHandColour;

    Paint hourArcPaint = Paint();
    hourArcPaint.color = hourArcColour;

    Paint clearPaint = Paint();
    clearPaint.color = backgroundControler.bottomColor;

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

    Rect rect = Rect.fromCircle(center: center, radius: radius);

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
  bool shouldRepaint(HandPainter oldDelegate) {
    return true;
  }
}

/// [CustomPainter] that paints the background gradient.
class BackgroundPainter extends CustomPainter {
  final BackgroundControler controler;
  BackgroundPainter({@required this.controler}) : super(repaint: controler);

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromPoints(Offset(0, 0), Offset(size.width, size.height));
    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        controler.topColor,
        controler.bottomColor,
      ],
      stops: [
        0.2,
        0.8,
      ],
    );
    final Paint paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) {
    return true;
  }
}

class BackgroundControler extends ChangeNotifier {
  Color _topColorBefore;
  Color _topColorAfter;
  Color _bottomColorBefore;
  Color _bottomColorAfter;

  DateTime _animationStart;
  Ticker _ticker;

  BackgroundControler() {
    _ticker = Ticker(_tick);
  }

  Color get topColor {
    if (_animationStart == null) {
      return _topColorAfter;
    }
    Duration dif = DateTime.now().difference(_animationStart);
    double dt = dif.inMilliseconds / 1000;
    if (dt < 0 || dt > 1) {
      _animationStart = null;
      _ticker.stop();
      return _topColorAfter;
    }
    return Color.alphaBlend(
        _topColorAfter.withOpacity(Curves.easeInOut.transform(dt)),
        _topColorBefore);
  }

  Color get bottomColor {
    if (_animationStart == null) {
      return _bottomColorAfter;
    }
    Duration dif = DateTime.now().difference(_animationStart);
    double dt = dif.inMilliseconds / 1000;
    if (dt < 0 || dt > 1) {
      _animationStart = null;
      _ticker.stop();
      return _bottomColorAfter;
    }
    return Color.alphaBlend(
        _bottomColorAfter.withOpacity(Curves.easeInOut.transform(dt)),
        _bottomColorBefore);
  }

  set color(List<Color> colors) {
    assert(colors.length == 2);

    _topColorBefore = topColor;
    _topColorAfter = colors[0];

    _bottomColorBefore = bottomColor;
    _bottomColorAfter = colors[1];
    if (_topColorBefore == null || _bottomColorBefore == null) {
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
