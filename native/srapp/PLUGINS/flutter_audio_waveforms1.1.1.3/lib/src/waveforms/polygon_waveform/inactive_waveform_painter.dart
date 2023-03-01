import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/src/core/waveform_painters_ab.dart';
import 'package:flutter_audio_waveforms/src/util/waveform_alignment.dart';
import 'package:flutter_audio_waveforms/src/waveforms/polygon_waveform/polygon_waveform.dart';

///InActiveWaveformPainter for the [PolygonWaveform]
class PolygonInActiveWaveformPainter extends InActiveWaveformPainter {
  // ignore: public_member_api_docs
  final int channelIdx;
  final int channelActive;
  final double gain;
  final double levelMedian;
  final double strokeWidth;
  final List<int> eventMarkersNumber;
  final List<double> eventMarkersPosition;

  double prevMax =0;
  double curMax = 0;

  List<TextPainter> textPainters = [];
  late Paint mypaint;

  PolygonInActiveWaveformPainter({
    Color color = Colors.white,
    Gradient? gradient,
    required List<double> samples,
    required WaveformAlignment waveformAlignment,
    required PaintingStyle style,
    required double sampleWidth,
    this.channelIdx = 0,
    this.channelActive = 1,
    this.gain = 1000,
    this.levelMedian = -1,
    this.strokeWidth = 0.5,
    this.eventMarkersNumber = const [],
    this.eventMarkersPosition = const [],
  }) : super(
          samples: samples,
          color: color,
          gradient: gradient,
          waveformAlignment: waveformAlignment,
          sampleWidth: sampleWidth,
          style: style,
        ) {
    mypaint = Paint()
      ..style = style
      ..isAntiAlias = false
      ..shader = null
      ..color = color
      ..strokeWidth = this.strokeWidth;

    for (int i = 0; i < 10; i++) {
      final strMarkerNumber = " " + i.toString() + " ";
      final TextSpan span = new TextSpan(
        style: new TextStyle(
            color: Colors.black, backgroundColor: MARKER_COLORS[i]),
        text: strMarkerNumber,
      );
      final TextPainter tp = new TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr);
      tp.layout();
      textPainters.add(tp);
    }
  }

  @override
  bool shouldRepaint(PolygonInActiveWaveformPainter oldDelegate) {
    if (oldDelegate.gain != gain ||
        oldDelegate.samples != samples ||
        oldDelegate.levelMedian != levelMedian ||
        oldDelegate.eventMarkersPosition != eventMarkersPosition) {
      return true;
    }
    return false;
  }

  /// Style of the waveform
  int sign = 1;
  // https://groups.google.com/g/flutter-dev/c/Za4M3U_MaAo?pli=1
  // Performance textPainter vs Paragraph https://stackoverflow.com/questions/51640388/flutter-textpainter-vs-paragraph-for-drawing-book-page
  @override
  void paint(Canvas canvas, Size size) {
    try {
      // ..shader = gradient?.createShader(
      //   Rect.fromLTWH(0, 0, size.width, size.height),
      // );

      final path = Path();
      int i = 0;
      for (; i < samples.length - 1; i++) {
        final x = sampleWidth * i;
        // final y = samples[i]/10000; //
        final y = samples[i] / (gain/100);
        // print(y);
        // if (i == samples.length - 1) {
        //   path.lineTo(x, y);
        //   path.moveTo(x, y);
        // } else {
        path.lineTo(x, y);
        // if (y>0)print(y);
        // }
        // curMax = y;
        // if (curMax > prevMax){
        //   prevMax = curMax;
        //   // print(curMax);
        //   // print(prevMax);
        //   print(samples[i]);
        // }
      }
      // print('gain');
      // print(gain);
      //END TAIL
      final sLen = samples.length - 1;
      final x = sampleWidth * sLen;
      final y = samples[sLen] / gain;
      path.moveTo(x, y);
      path.lineTo(x, y);
      path.moveTo(x, y);
      // EVENT KEY PRESS
      //path.moveTo(x, y)
      // final xx = x;
      // final yy = -285.0; //negative Up, positive Down
      // path.moveTo(xx, yy);
      // path.lineTo(0, yy);
      // path.moveTo(x, y);

      //Gets the [alignPosition] depending on [waveformAlignment]
      // final alignPosition = waveformAlignment.getAlignPosition(size.height);

      // final alignPosition = levelMedian;
      //Shifts the path along y-axis by amount of [alignPosition]
      final shiftedPath = path.shift(Offset(0, levelMedian));
      canvas.drawPath(shiftedPath, mypaint);
      // print(shiftedPath);

      // final offsetLeft = new Offset(0, 2);
      // final offsetRight = new Offset(x, 2);
      // canvas.drawLine(offsetLeft, offsetRight, mypaint);

      // print("Channels : " + channelIdx.toString() + "_ "+ channelActive.toString());
      if (eventMarkersPosition.length > 0 && channelIdx == channelActive) {
        // int n = eventMarkersPosition.length - 1;
        // for ( i = n; i >= 0  ; i--){
        // print("Level Median " + levelMedian.toString());

        int n = eventMarkersPosition.length;
        double prevX = -1;
        double counterStacked = 10;
        double evY = 0;
        if (channelIdx == 2) {
          evY = -50;
        }

        for (i = 0; i < n; i++) {
          if (eventMarkersPosition[i] == 0) {
            continue;
          }

          // final evX = eventMarkersPosition[i] * sampleWidth;
          final evX = eventMarkersPosition[i];

          // final linePath = Path();
          // linePath.moveTo(evX, 0);
          // linePath.lineTo(evX, 900);
          // sign = sign * -1;

          // canvas.drawPath(linePath, MARKER_PAINT[ eventMarkersNumber[i] ]);

          // final linePath = Path();
          final offset1 = new Offset(evX, evY);
          final offset2 = new Offset(evX, 2900);
          // final offset2 = new Offset(evX, size.height * 2);
          // linePath.lineTo(evX, 900);
          // sign = sign * -1;

          canvas.drawLine(
            offset1,
            offset2,
            MARKER_PAINT[eventMarkersNumber[i]],
          );

          // final strMarkerNumber = " "+eventMarkersNumber[i].toString()+" ";
          // final TextSpan span = new TextSpan(style: new TextStyle(color: Colors.black,backgroundColor: MARKER_COLORS[ eventMarkersNumber[i] ] ), text: strMarkerNumber, );
          // final TextPainter tp = new TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
          // tp.layout();
          final TextPainter tp = textPainters[eventMarkersNumber[i]];
          if (i > 0 && evX - 20 <= prevX) {
            counterStacked += 30;
          } else {
            counterStacked = 100;
          }
          prevX = evX;
          tp.paint(canvas, new Offset(evX - 3, counterStacked));
        }
      }
    } catch (err) {
      print("errx");
      print(err);
    }
  }
}

List<Color> MARKER_COLORS = [
  Color.fromARGB(255, 216, 180, 231),
  Color.fromARGB(255, 176, 229, 124),
  Color.fromARGB(255, 255, 80, 0), //orange
  Color.fromARGB(255, 255, 236, 148),
  Color.fromARGB(255, 255, 174, 174),
  Color.fromARGB(255, 180, 216, 231),
  Color.fromARGB(255, 193, 218, 214),
  Color.fromARGB(255, 172, 209, 233),
  Color.fromARGB(255, 174, 255, 174),
  Color.fromARGB(255, 255, 236, 255),
];
List<Paint> MARKER_PAINT = [
  Paint()
    ..style = PaintingStyle.stroke
    ..color = MARKER_COLORS[0]
    ..strokeWidth = 1,
  Paint()
    ..style = PaintingStyle.stroke
    ..color = MARKER_COLORS[1]
    ..strokeWidth = 1,
  Paint()
    ..style = PaintingStyle.stroke
    ..color = MARKER_COLORS[2]
    ..strokeWidth = 1,
  Paint()
    ..style = PaintingStyle.stroke
    ..color = MARKER_COLORS[3]
    ..strokeWidth = 1,
  Paint()
    ..style = PaintingStyle.stroke
    ..color = MARKER_COLORS[4]
    ..strokeWidth = 1,
  Paint()
    ..style = PaintingStyle.stroke
    ..color = MARKER_COLORS[5]
    ..strokeWidth = 1,
  Paint()
    ..style = PaintingStyle.stroke
    ..color = MARKER_COLORS[6]
    ..strokeWidth = 1,
  Paint()
    ..style = PaintingStyle.stroke
    ..color = MARKER_COLORS[7]
    ..strokeWidth = 1,
  Paint()
    ..style = PaintingStyle.stroke
    ..color = MARKER_COLORS[8]
    ..strokeWidth = 1,
  Paint()
    ..style = PaintingStyle.stroke
    ..color = MARKER_COLORS[9]
    ..strokeWidth = 1,
];
