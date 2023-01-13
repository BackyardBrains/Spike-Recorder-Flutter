import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class WaveformData {
  int version=1;
  // number of channels (only mono files are currently supported)
  int channels=1;
  // original sample rate
  int sampleRate=128;
  // indicates how many original samples have been analyzed per frame. 256 samples -> frame of min/max
  int sampleSize=16;
  // bit depth of the data
  int bits=128;
  // the number of frames contained in the data
  int length=1;
  // data is in frames with min and max values for each sampled data point.
  List<double> data = [];
  List<double> _scaledData = [];

  WaveformData({
    required this.version,
    required this.channels,
    required this.sampleRate,
    required this.sampleSize,
    required this.bits,
    required this.length,
    required this.data,
  });

  List<double> scaledData() {
    if (!_isDataScaled()) {
      _scaleData();
    }
    return _scaledData;
  }

  factory WaveformData.fromJson(String str) => WaveformData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory WaveformData.fromMap(Map<String, dynamic> json) => new WaveformData(
        version: json["version"] == null ? null : json["version"],
        channels: json["channels"] == null ? null : json["channels"],
        sampleRate: json["sample_rate"] == null ? null : json["sample_rate"],
        sampleSize: json["samples_per_pixel"] == null ? null : json["samples_per_pixel"],
        bits: json["bits"] == null ? null : json["bits"],
        length: json["length"] == null ? null : json["length"],
        data: json["data"] == null ? [] : List<double>.from(json["data"].map((x) => x)),
      );

  Map<String, dynamic> toMap() => {
        "version": version == null ? null : version,
        "channels": channels == null ? null : channels,
        "sample_rate": sampleRate == null ? null : sampleRate,
        "samples_per_pixel": sampleSize == null ? null : sampleSize,
        "bits": bits == null ? null : bits,
        "length": length == null ? null : length,
        "data": data == null ? null : new List<dynamic>.from(data.map((x) => x)),
      };

  // get the frame position at a specific percent of the waveform. Can use a 0-1 or 0-100 range.
  int frameIdxFromPercent(double percent) {
    if (percent == null) {
      return 0;
    }

    // if the scale is 0-1.0
    if (percent < 0.0) {
      percent = 0.0;
    } else if (percent > 100.0) {
      percent = 100.0;
    }

    if (percent > 0.0 && percent < 1.0) {
      return ((data.length.toDouble() / 2) * percent).floor();
    }

    int idx = ((data.length.toDouble() / 2) * (percent / 100)).floor();
    final maxIdx = (data.length.toDouble() / 2 * 0.98).floor();
    if (idx > maxIdx) {
      idx = maxIdx;
    }
    return idx;
  }

  Path path(Size size, {zoomLevel = 1.0, int fromFrame = 0}) {
    if (!_isDataScaled()) {
      _scaleData();
    }

    if (zoomLevel == null || zoomLevel < 1.0) {
      zoomLevel = 1.0;
    } else if (zoomLevel > 100.0) {
      zoomLevel = 100.0;
    }

    if (zoomLevel == 1.0 && fromFrame == 0) {
      return _path(_scaledData, size);
    }

    // buffer so we can't start too far in the waveform, 90% max
    if (fromFrame * 2 > (data.length * 0.98).floor()) {
      debugPrint("from frame is too far at $fromFrame");
      fromFrame = ((data.length / 2) * 0.98).floor();
    }

    int endFrame = (fromFrame * 2 + ((_scaledData.length - fromFrame * 2) * (1.0 - (zoomLevel / 100)))).floor();

    return _path(_scaledData.sublist(fromFrame * 2, endFrame), size);
  }

  Path _path(List<double> samples, Size size) {
    final middle = size.height / 2;
    print("middle");
    print(middle);
    var i = 0;

    List<Offset> minPoints = [];
    List<Offset> maxPoints = [];

    final t = size.width / samples.length;
    // var t = 1.toDouble();
    //STEVANUS
    // for (var _i = 0, _len = samples.length; _i < _len; _i++) {
    //   var d = samples[_i];
    //   if (_i % 2 != 0) { // == 1
    //     minPoints.add(Offset(t * i, middle - middle * d));
    //   } else {
    //     maxPoints.add(Offset(t * i, middle - middle * d));
    //   }

    //   i++;
    // }

    // print("minPoints");
    // print(minPoints);
    // print("maxPoints");
    // print(maxPoints);

    // STEVANUS

    final path = Path();
    path.moveTo(0, middle);
    // maxPoints.forEach((o) => path.lineTo(o.dx, o.dy));
    // //// back to zero
    // path.lineTo(size.width, middle);
    // // // draw the minimums backwards so we can fill the shape when done.
    // minPoints.reversed.forEach((o) => path.lineTo(o.dx, middle - (middle - o.dy)));

    for (; i < samples.length; i++) {
      final x = t * i;
      final y = samples[i];
      // print(y);
      if (i == samples.length - 1) {
        path.lineTo(x, 0);
      } else {  
        if (middle<350){
          // print("enter this");
          path.lineTo(x, y/70);
        }else{
          path.lineTo(x, y);
        }
      }
    }
    // final alignPosition = (size.height)/2;

    //Shifts the path along y-axis by amount of [alignPosition]
    final shiftedPath = path.shift(Offset(0, middle));

    // canvas.drawPath(shiftedPath, paint);


    // path.close();
    return shiftedPath;
  }

  bool _isDataScaled() {
    return _scaledData != null && _scaledData.length == data.length;
  }

  // scale the data from int values to float
  // TODO: consider adding a normalization option
  _scaleData() {
    _scaledData = [...data];
    return;
    final max = pow(2, bits - 1).toDouble();
    
    final dataSize = data.length;
    _scaledData = List.generate(dataSize, (index) => 0.0);
    for (var i = 0; i < dataSize; i++) {
      _scaledData[i] = data[i].toDouble() / max;
      if (_scaledData[i] > 1.0) {
        _scaledData[i] = 1.0;
      }
      if (_scaledData[i] < -1.0) {
        _scaledData[i] = -1.0;
      }
    }
  }
}
