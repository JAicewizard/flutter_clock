// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/scheduler.dart';

/// [CustomPainter] that draws a clock hand.
class HandPainter extends CustomPainter {
  static const int semicircleLenth = 720;

  HandPainter({@required this.color, Listenable repaint})
      : assert(color != null),
        super(repaint: repaint);
  final Color color;

  List<Offset> secondsArcPoints;
  double _radius = -1;

  @override
  void paint(Canvas canvas, Size size) {
    double newRadius = _calcRadius(size);
    Offset center = Offset(size.width / 2, size.height / 2);
    if (newRadius != _radius || _radius == -1) {
      _radius = newRadius;
      secondsArcPoints = calcPoints(center);
    }

    DateTime time = DateTime.now();

    int handWidth = (time.hour * 24 + time.minute) * 2 * semicircleLenth ~/ 720;
    double circleSize = (time.minute * 60 + time.second) / 3600;
    int handOffset =
        (time.second * 1000 + time.millisecond) * 2 * semicircleLenth ~/ 60000;

    //canvas.drawPath(makeHand(handOffset, handWidth, center), firstPaint());

    Rect rect = Rect.fromCircle(center: center, radius: _radius);
    double radCenter = handOffset / (2 * semicircleLenth) * 2 * math.pi;
    double radWidtg = handWidth / (2 * semicircleLenth) * 2 * math.pi;
    print(radWidtg);
    canvas.drawArc(
        rect, radCenter - (radWidtg / 2), radWidtg, true, firstPaint());

    canvas.drawCircle(center, circleSize * _radius, firstPaint());
  }

  Path makeHand(int offset, int width, Offset center) {
    int start = offset - width ~/ 2;
    if (start < 0) {
      start += 2 * semicircleLenth;
    }
    Path path = Path()
      ..addPolygon(
          secondsArcPoints.sublist(start, start + width)..add(center), true);
    return path;
  }

  Paint firstPaint() {
    Paint paint = Paint();
    paint.color = color;
    paint.isAntiAlias = true;
    paint.style = PaintingStyle.fill;
    return paint;
  }

  double _calcRadius(Size size) {
    bool isXLimmiting = size.aspectRatio < 1;
    if (isXLimmiting) {
      return (size.width * 0.8 / 2);
    } else {
      return (size.height * 0.8 / 2);
    }
  }

  List<Offset> calcPoints(Offset center) {
    double dt = math.pi / semicircleLenth;
    return List<Offset>.generate(
        semicircleLenth * 4,
        (n) => Offset((math.sin(n * dt)), (-math.cos(n * dt)))
            .scale(_radius, _radius)
            .translate(center.dx, center.dy),
        growable: false);
  }

  @override
  bool shouldRepaint(HandPainter oldDelegate) {
    return true;
  }
}

/// [CustomPainter] that the background gradient.
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
        0.0,
        1.0,
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
    double dt = dif.inMilliseconds / 10000;
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
    double dt = dif.inMilliseconds / 10000;
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

    _topColorBefore = _topColorAfter;
    _topColorAfter = colors[0];

    _bottomColorBefore = _bottomColorAfter;
    _bottomColorAfter = colors[1];
    if (_topColorBefore == null || _bottomColorBefore == null) {
      return;
    }
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
