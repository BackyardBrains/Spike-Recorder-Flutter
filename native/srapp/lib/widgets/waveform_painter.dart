import 'package:flutter/material.dart';

import '../core/models/waveform_data_model.dart';

class WaveformPainter extends CustomPainter {
  final WaveformData data;
  final int startingFrame;
  final double zoomLevel;
  Paint painter = new Paint();
  final Color color;
  final double strokeWidth;

  WaveformPainter(this.data,
      {this.strokeWidth = 1.0,
      this.startingFrame = 0,
      this.zoomLevel = 1,
      this.color = Colors.blue}) {
    painter = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data == null) {
      return;
    }
    // print("size.height");
    // print(size.height);
    final path =
        data.path(size, fromFrame: startingFrame, zoomLevel: zoomLevel);
    canvas.drawPath(path, painter);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    if (oldDelegate.data != data) {
      // debugPrint("Redrawing");
      return true;
    }
    return false;
  }
}
