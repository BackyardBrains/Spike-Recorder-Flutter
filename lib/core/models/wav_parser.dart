// import 'dart:io';

import 'dart:typed_data';

enum WavFormat { WAVE, OTHER }
enum Encoding { PCM, OTHER }
enum System { MONO, STEREO }

/// Returns the lesser of two numbers.
///
/// ```dart
/// import 'dart:io';
/// import 'package:wav/wav.dart';
/// main() async {
///   final wav = WavReader();
///   await wav.open(file: File('oishii.wav'));
///   print(wav.chunkID);
///   print(wav.chunkSize);
///   ///final WavFormat format;
///   print(wav.format);
///   print(wav.subChunk1ID);
///   print(wav.subChunk1Size);
///   print(wav.encoding);
///   /// final Encoding encoding;
///   print(wav.numChannels);
///   print(wav.sampleRate);
///   print(wav.blockAlign);
///   print(wav.bitsPerSample);
///   print(wav.subChunk2ID);
///   print(wav.subChunk2Size);
///   print(wav.bytesPerSample);
///   print(wav.sampleCount);
///   print(wav.audioLength);
///   print(wav.readSamples());
/// }
/// ```

class WavReader {
  String chunkID = "";
  int chunkSize = 1;
  WavFormat format = WavFormat.WAVE;
  String rawFormat = "fmt";
  String subChunk1ID = "";
  int subChunk1Size = 1; 
  int rawEncoding = 1;
  Encoding encoding = Encoding.OTHER;
  int numChannels = 1;
  int sampleRate = 1;
  int blockAlign = 1;
  int bitsPerSample = 1;
  String subChunk2ID = "";
  int subChunk2Size = 1;
  double bytesPerSample = 0;
  int sampleCount = 1;
  double audioLength = 0;
  System system = System.STEREO;
  Uint8List bytes = Uint8List(1);
  final List<int> _samples = [];
  Map<int, List<int>> channels = new Map<int, List<int>>();
  
  // WavReader();

  List<int> readSamples() => _samples;

  Uint8List readBytes(Uint8List pbytes, int count){
    // count=count*2;
    var read=bytes.getRange(0, count).toList();
    bytes = bytes.sublist(count);
    // print("bytes.length");
    // print(bytes.length);
    // bytes.removeRange(0, count);
    return Uint8List.fromList(read);
  }

  void open({required Uint8List pbytes}) async {
    bytes = pbytes;
    // final data = await File(path).open();
    final chunkIDBytes = readBytes(bytes,4); //1
    chunkID = String.fromCharCodes(chunkIDBytes);
    // assert(chunkID == 'RIFF');
    final chunkSizeBytes = readBytes(bytes,4);//2
    chunkSize = chunkSizeBytes.buffer.asByteData().getUint8(0);
    final formatBytes = readBytes(bytes,4);//3
    final formatStr = String.fromCharCodes(formatBytes);
    // assert(formatStr == 'WAVE');
    format = getFormat(formatStr);
    final subChunk1IDBytes = readBytes(bytes,4);//4
    subChunk1ID = String.fromCharCodes(subChunk1IDBytes);
    // assert(subChunk1ID == 'fmt ');
    final subChunk1SizeBytes = readBytes(bytes,4);//5
    subChunk1Size = subChunk1SizeBytes.buffer.asByteData().getUint8(0);
    final encodingBytes = readBytes(bytes,2);//6
    final encodingInt = encodingBytes.buffer.asByteData().getUint8(0);
    encoding = getEncoding(encodingInt);
    //  print(encoding); //assert 1 == PCM Format: assumed PCM

    final numChannelsBytes = readBytes(bytes,2);//7
    numChannels = numChannelsBytes.buffer.asByteData().getInt8(0);
    system = getSystem(numChannels);
    // print("numChannels"); //'1 == Mono, 2 == Stereo: assumed Mono'
    // print(numChannels); //'1 == Mono, 2 == Stereo: assumed Mono'

    final sampleRateBytes = readBytes(bytes,4);//8
    // print("sampleRateBytes");
    // print(sampleRateBytes);
    sampleRate = sampleRateBytes.buffer.asByteData().getUint16(0,Endian.little);
    // print("sampleRate");
    // print(sampleRate);

    final byteRateBytes = readBytes(bytes,4);//9
    final byteRate = byteRateBytes.buffer.asByteData().getUint8(0);

    final blockAlignBytes = readBytes(bytes,2);//10
    blockAlign = blockAlignBytes.buffer.asByteData().getUint8(0);
    // print("blockAlign");
    // print(blockAlign);

    final bitsPerSampleBytes = readBytes(bytes,2);//11
    bitsPerSample = bitsPerSampleBytes.buffer.asByteData().getUint8(0);
    // print("bitsPerSample");
    // print(bitsPerSample);

    var subChunk2IDBytes = readBytes(bytes,4);//12
    subChunk2ID = String.fromCharCodes(subChunk2IDBytes);
    // assert(subChunk2ID == 'data');
    // print("subChunk2ID");
    // print(subChunk2ID);

    final subChunk2SizeBytes = readBytes(bytes,4);//13
    // subChunk2Size = subChunk2SizeBytes.buffer.asByteData().getInt16(0,Endian.little);
    subChunk2Size = subChunk2SizeBytes.buffer.asByteData().getUint32(0,Endian.little);
    bytesPerSample = bitsPerSample / 8;
    // assert(subChunk2Size % bytesPerSample == 0);
    sampleCount = (subChunk2Size / bytesPerSample).round();
    // print(subChunk2Size.toString() +" -  "+ bytesPerSample.toString());
    // print(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      // var byte = readBytes(bytes,4);
      // var sample = byte.buffer.asByteData().getInt16(0,Endian.little);
      var factor = (numChannels == 1) ? 2 : 4;
      // var byte = readBytes( bytes, (blockAlign/2).floor() );
      var byte = readBytes( bytes, factor );
      // var sample = byte.buffer.asByteData().getInt16(0, Endian.little);
      // print(byte);

      var sample = byte.buffer.asByteData().getInt16(0, Endian.little);
      _samples.add(sample);
      
      int channel = i % numChannels;
      if (channels[channel] == null){
        channels[channel] = [];
        channels[channel]!.add(sample);
      }else{
        channels[channel]!.add(sample);
      }

    }
    // print("channels end");
    // print(channels);

    // assert(chunkSize ==
    //         formatStr.length +
    //             subChunk1ID.length +
    //             subChunk1Size +
    //             4 + //Full size of subchunk 1
    //             subChunk2ID.length +
    //             subChunk2Size +
    //             4 //Full size of subchunk 2

    //     );
    // assert(subChunk1Size ==
    //         2 + // audio_format
    //             2 + // num_channels
    //             4 + // sample_rate
    //             4 + // byte_rate
    //             2 + // block_align
    //             2 // bits_per_sample
    //     );

    // assert(byteRate == sampleRate * numChannels * bytesPerSample);
    // assert(blockAlign == numChannels * bytesPerSample);
    // assert(subChunk2Size == _samples.length * bytesPerSample);
    audioLength = (_samples.length / sampleRate / numChannels);
  }

  static WavFormat getFormat(String formatStr) {
    switch (formatStr) {
      case 'WAVE':
        return WavFormat.WAVE;
        break;
      default:
        return WavFormat.OTHER;
    }
  }

  static Encoding getEncoding(int encodingInt) {
    switch (encodingInt) {
      case 1:
        return Encoding.PCM;
        break;
      default:
        return Encoding.OTHER;
    }
  }

  static System getSystem(int numChannels) {
    switch (numChannels) {
      case 1:
        return System.MONO;
        break;
      case 2:
        return System.STEREO;
        break;
      default:
        return System.MONO;
    }
  }
}