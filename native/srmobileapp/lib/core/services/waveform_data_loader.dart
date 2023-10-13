import 'package:flutter/services.dart';

import '../models/waveform_data_model.dart';

Future<WaveformData> loadWaveformData(String filename) async {
  final data = await rootBundle.loadString("assets/waveforms/$filename");
  return WaveformData.fromJson(data);
}
