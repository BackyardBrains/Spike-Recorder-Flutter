import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:nativec/allocation.dart';

import 'nativec_platform_interface.dart';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

typedef gain_filter_func = ffi.Double Function(
  ffi.Double,
  ffi.Double,
);
typedef GainFilterProcess = double Function(
  double,
  double,
);

class MyStruct extends ffi.Struct {
  external ffi.Pointer<Utf8> info;
}

// typedef CreateStruct = MyStruct Function();
// typedef GetInfo = ffi.Pointer<Utf8> Function(ffi.Pointer<MyStruct>);

typedef return_gain_filter_func = ffi.Double Function(ffi.Double);
typedef ReturnGainFilterProcess = double Function(double);
typedef set_notch_func = ffi.Double Function(ffi.Int16, ffi.Int16);
typedef SetNotchProcess = double Function(int, int);

typedef create_low_pass_filters_func = ffi.Double Function(
    ffi.Int16, ffi.Double, ffi.Double, ffi.Double);
typedef CreateLowPassFilterProcess = double Function(
    int, double, double, double);
typedef init_low_pass_filters_func = ffi.Double Function(
    ffi.Int16, ffi.Double, ffi.Double, ffi.Double);
typedef InitLowPassFilterProcess = double Function(int, double, double, double);
typedef apply_low_pass_filters_func = ffi.Double Function(
    ffi.Int16, ffi.Pointer<ffi.Int16>, ffi.Uint32);
typedef ApplyLowPassFilterProcess = double Function(
    int, ffi.Pointer<ffi.Int16>, int);

typedef create_high_pass_filters_func = ffi.Double Function(
    ffi.Int, ffi.Double, ffi.Double, ffi.Double);
typedef CreateHighPassFilterProcess = double Function(
    int, double, double, double);
typedef init_high_pass_filters_func = ffi.Double Function(
    ffi.Int, ffi.Double, ffi.Double, ffi.Double);
typedef InitHighPassFilterProcess = double Function(
    int, double, double, double);
typedef apply_high_pass_filters_func = ffi.Double Function(
    ffi.Int16, ffi.Pointer<ffi.Int16>, ffi.Uint32);
typedef ApplyHighPassFilterProcess = double Function(
    int, ffi.Pointer<ffi.Int16>, int);

typedef create_threshold_func = ffi.Double Function(
    ffi.Int, ffi.Uint32, ffi.Int16, ffi.Int16);
typedef CreateThresholdProcess = double Function(int, int, int, int);
typedef init_threshold_func = ffi.Double Function(
    ffi.Int, ffi.Double, ffi.Double, ffi.Double);
typedef InitThresholdProcess = double Function(int, double, double, double);


typedef set_trigger_type_func = ffi.Double Function(ffi.Int, ffi.Int);
typedef SetTriggerTypeProcess = double Function(int, int);


typedef get_threshold_hit_func = ffi.Int Function();
typedef GetThresholdHitProcess = int Function();

typedef set_threshold_parameters_func = ffi.Double Function(
    ffi.Int, ffi.Int, ffi.Double, ffi.Double, ffi.Int);
typedef SetThresholdParametersProcess = double Function(
    int, int, double, double, int);
typedef get_samples_threshold_func = ffi.Double Function(
    ffi.Int, ffi.Pointer<ffi.Int16>, ffi.Int, ffi.Double, ffi.Int, ffi.Int);
typedef GetSamplesThresholdProcess = double Function(
    int, ffi.Pointer<ffi.Int16>, int, double, int, int);

typedef append_samples_threshold_func = ffi.Double Function(
    ffi.Int16,
    ffi.Int16,
    ffi.Int16,
    ffi.Pointer<ffi.Int16>,
    ffi.Uint32,
    ffi.Double,
    ffi.Int32,
    ffi.Uint32,
    ffi.Pointer<ffi.Int16>,
    ffi.Pointer<ffi.Int16>, 
    ffi.Int16
    );
typedef AppendSamplesThresholdProcess = double Function(
    int, int, int, ffi.Pointer<ffi.Int16>, int, double, int, int,ffi.Pointer<ffi.Int16>,ffi.Pointer<ffi.Int16>, int);

typedef set_threshold_dart_port_func = ffi.Double Function(ffi.Int64);
typedef SetThresholdDartPortFunc = double Function(int);

typedef create_notch_pass_filters_func = ffi.Double Function(
    ffi.Int16, ffi.Int16, ffi.Double, ffi.Double, ffi.Double);
typedef CreateNotchPassFilterProcess = double Function(
    int, int, double, double, double);
typedef init_notch_pass_filters_func = ffi.Double Function(
    ffi.Int16, ffi.Int16, ffi.Double, ffi.Double, ffi.Double);
typedef InitNotchPassFilterProcess = double Function(
    int, int, double, double, double);
typedef apply_notch_pass_filters_func = ffi.Double Function(
    ffi.Int16, ffi.Int16, ffi.Pointer<ffi.Int16>, ffi.Uint32);
typedef ApplyNotchPassFilterProcess = double Function(
    int, int, ffi.Pointer<ffi.Int16>, int);

// Low Pass filter sample https://www.youtube.com/watch?v=X8JD8hHkBMc
class Nativec {
  ffi.DynamicLibrary nativeLrsLib = Platform.isAndroid
      ? ffi.DynamicLibrary.open("libnative_nativec.so")
      : (Platform.isWindows)
          ? ffi.DynamicLibrary.open("nativec_plugin.dll")
          : ffi.DynamicLibrary.process();
  late CreateLowPassFilterProcess _createLowPassFilterProcess;
  late CreateHighPassFilterProcess _createHighPassFilterProcess;
  late CreateNotchPassFilterProcess _createNotchPassFilterProcess;
  late CreateThresholdProcess _createThresholdProcess;

  late GainFilterProcess _gainFilterProcess;
  late ReturnGainFilterProcess _returnGainFilterProcess;
  late SetNotchProcess _setNotchProcess;

  late ApplyLowPassFilterProcess _applyLowPassFilterProcess;
  late ApplyHighPassFilterProcess _applyHighPassFilterProcess;
  late ApplyNotchPassFilterProcess _applyNotchPassFilterProcess;
  late AppendSamplesThresholdProcess _appendSamplesThresholdProcess;

  late InitLowPassFilterProcess _initLowPassFilterProcess;
  late InitHighPassFilterProcess _initHighPassFilterProcess;
  late InitNotchPassFilterProcess _initNotchPassFilterProcess;
  late InitThresholdProcess _initThresholdProcess;
  late SetThresholdParametersProcess _setThresholdParametersProcess;
  late GetSamplesThresholdProcess _getSamplesThresholdProcess;
  late GetThresholdHitProcess _getThresholdHitProcess;
  late SetThresholdDartPortFunc _setThresholdDartPortFunc;
  late SetTriggerTypeProcess _setTriggerTypeProcess;

  // C++ to Dart
  // late final registerCallback1 = nativeLrsLib.lookupFunction<
  //       ffi.Void Function(ffi.Int64 sendPort,
  //           ffi.Pointer<ffi.NativeFunction<ffi.IntPtr Function(ffi.IntPtr)>> functionPointer),
  //       void Function(int sendPort,
  //           ffi.Pointer<ffi.NativeFunction<ffi.IntPtr Function(ffi.IntPtr)>> functionPointer)>(
  //   'RegisterMyCallbackBlocking');
  // int callback1(int a) {
  //   print("Dart:     callback1($a).");
  //   // numCallbacks1++;
  //   return a + 3;
  // }

  // late callback1FP;
  // late CreateStruct createStructFn;
  // late GetInfo getInfoFn;

  static int totalBytes = 1024 * 8;
  static int timeSpan = 10;
  static int totalThresholdBytes = (timeSpan * 44100);
  static int totalEventIndicesBytes = 300;
  static int totalEventsBytes = 300;
  static ffi.Pointer<ffi.Int16> _data = allocate<ffi.Int16>(
      count: totalBytes, sizeOfType: ffi.sizeOf<ffi.Int16>());
  static ffi.Pointer<ffi.Int16> _dataThreshold = allocate<ffi.Int16>(
      count: totalThresholdBytes, sizeOfType: ffi.sizeOf<ffi.Int16>());

  static ffi.Pointer<ffi.Int16> _dataEventIndices = allocate<ffi.Int16>(
      count: totalEventIndicesBytes, sizeOfType: ffi.sizeOf<ffi.Int16>());
  static ffi.Pointer<ffi.Int16> _dataEvents = allocate<ffi.Int16>(
      count: totalEventsBytes, sizeOfType: ffi.sizeOf<ffi.Int16>());

  late Int16List _bytes;
  late Int16List _thresholdBytes;
  late Int16List _thresholdEventIndices;
  late Int16List _thresholdEvents;

  late ReceivePort thresholdPublication;

  Future<String?> getPlatformVersion() {
    //https://docs.flutter.dev/development/platform-integration/macos/c-interop
    return NativecPlatform.instance.getPlatformVersion();
  }

  static ffi.Pointer<ffi.Void>? cookie;

  Nativec() {
    print("nativeLrsLib");
    print(nativeLrsLib);
    _createLowPassFilterProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<create_low_pass_filters_func>>(
            'createLowPassFilter')
        .asFunction();
    _createHighPassFilterProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<create_high_pass_filters_func>>(
            'createHighPassFilter')
        .asFunction();
    _createNotchPassFilterProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<create_notch_pass_filters_func>>(
            'createNotchPassFilter')
        .asFunction();

    _createThresholdProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<create_threshold_func>>(
            'createThresholdProcess')
        .asFunction();

    _initLowPassFilterProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<init_low_pass_filters_func>>(
            'initLowPassFilter')
        .asFunction();
    _initHighPassFilterProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<init_high_pass_filters_func>>(
            'initHighPassFilter')
        .asFunction();
    _initNotchPassFilterProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<init_notch_pass_filters_func>>(
            'initNotchPassFilter')
        .asFunction();
    _initThresholdProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<init_threshold_func>>('initThresholdProcess')
        .asFunction();
    _setThresholdParametersProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<set_threshold_parameters_func>>(
            'setThresholdParametersProcess')
        .asFunction();
    _getSamplesThresholdProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<get_samples_threshold_func>>(
            'getSamplesThresholdProcess')
        .asFunction();

    _getThresholdHitProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<get_threshold_hit_func>>(
            'getThresholdHitProcess')
        .asFunction();

    _applyLowPassFilterProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<apply_low_pass_filters_func>>(
            'applyLowPassFilter')
        .asFunction();
    _applyHighPassFilterProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<apply_high_pass_filters_func>>(
            'applyHighPassFilter')
        .asFunction();
    _applyNotchPassFilterProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<apply_notch_pass_filters_func>>(
            'applyNotchPassFilter')
        .asFunction();
    _appendSamplesThresholdProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<append_samples_threshold_func>>(
            'appendSamplesThresholdProcess')
        .asFunction();

    _gainFilterProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<gain_filter_func>>('GainFilter')
        .asFunction();
    _returnGainFilterProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<return_gain_filter_func>>('ReturnGainFilter')
        .asFunction();
    _setNotchProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<set_notch_func>>('setNotch')
        .asFunction();

    _setTriggerTypeProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<set_trigger_type_func>>(
            'setTriggerTypeProcess')
        .asFunction();

    // C++ to Flutter
    // final initializeApi = nativeLrsLib.lookupFunction<
    //     ffi.IntPtr Function(ffi.Pointer<ffi.Void>),
    //     int Function(ffi.Pointer<ffi.Void>)>("InitDartApiDL");
    // final SetThresholdDartPortFunc _setDartPort = nativeLrsLib
    //     .lookup<ffi.NativeFunction<set_threshold_dart_port_func>>(
    //         "set_dart_port")
    //     .asFunction();

    // cookie = _Dart_InitializeApiDL(ffi.NativeApi.initializeApiDLData);
    // initializeApi(ffi.NativeApi.initializeApiDLData);
    // thresholdPublication = ReceivePort()
    //   ..listen((message) {
    //     // TODO: processing messages from C++ code
    //     // print("PRINT C++ MESSAGE : ");
    //     // print(message);
    //   });
    // _setDartPort(thresholdPublication.sendPort.nativePort);

    // // Pass NativePort value (int) to C++ code
    // print("pub.sendPort.nativePort");
    // print(pub.sendPort.nativePort);
    // Future.delayed(Duration(seconds: 5), () {
    //   _applyThresholdProcess(1, _data, 2);
    // });

    // final interactiveCppRequests = ReceivePort()..listen((message){});
    // final int nativePort = interactiveCppRequests.sendPort.nativePort;
    // callback1FP = ffi.Pointer.fromFunction<ffi.IntPtr Function(ffi.IntPtr)>(callback1, 0);
    // registerCallback1(nativePort, callback1FP);

    if (_data == null) {
      // _data = allocate<ffi.Int16>(count: totalBytes);
    }
    // int byteCount = Nativec.totalBytes;
    _bytes = _data.asTypedList(Nativec.totalBytes);
    // _bytes.fillRange(0, Nativec.totalBytes, 55);

    // createStructFn =
    //     nativeLrsLib.lookupFunction<CreateStruct, CreateStruct>('CreateStruct');
    // getInfoFn = nativeLrsLib.lookupFunction<GetInfo, GetInfo>('GetInfo');

    // var dartMyStruct = createStructFn();
    // var myStructPtr = malloc<MyStruct>()..ref = dartMyStruct;
    // var myStructPtr = malloc<MyStruct>();
    // String hello = 'hello123';
    // dartMyStruct.info = hello.toNativeUtf8();

    // It's a pointer, so we can pass by reference.
    // final result = getInfoFn(myStructPtr);
    // print("result.toDartString()");
    // print(result.toDartString());
    // List<int> data = List<int>.generate(100, (index) => index);

    // int totalBytes = 1000;
    // (_createLowPassFilterProcess(44100.0, 30.0, 0.5, _data, totalBytes));
    // print(_data.asTypedList(totalBytes));
    // if (_data != null) {
    // 	free(_data);
    // }
  }

  double gain(a, b) {
    double multipliedSample = _gainFilterProcess(a, b);
    // print("multipliedSample");
    // print(multipliedSample);

    return multipliedSample;

    // print("RESULT ");
    // print(_returnGainFilterProcess(1));
  }

  double setNotchFilter(isNotch50, isNotch60) {
    return _setNotchProcess(isNotch50, isNotch60);
  }

  double createNotchPassFilter(isNotch50, channelCount, sampleRate, cutOff, q) {
    return _createNotchPassFilterProcess(
        isNotch50, channelCount, sampleRate, cutOff, q);
  }

  double initNotchPassFilter(isNotch50, channelCount, sampleRate, cutOff, q) {
    return _initNotchPassFilterProcess(
        isNotch50, channelCount, sampleRate, cutOff, q);
  }

  List<int> notchPassFilter(isNotch50, channelIdx, List<int> data, totalBytes) {
    _bytes.fillRange(0, totalBytes, 0);
    int len = data.length;
    for (int i = 0; i < len; i++) {
      _bytes[i] = data[i];
    }

    var lowPassValue =
        _applyLowPassFilterProcess(channelIdx, _data, totalBytes);
    data = _bytes.sublist(0, totalBytes);
    return data;
  }

  double createLowPassFilter(channelCount, sampleRate, cutOff, q) {
    return _createLowPassFilterProcess(channelCount, sampleRate, cutOff, q);
  }

  double initLowPassFilter(channelCount, sampleRate, cutOff, q) {
    return _initLowPassFilterProcess(channelCount, sampleRate, cutOff, q);
  }

  List<int> lowPassFilter(channelIdx, List<int> data, totalBytes) {
    // _data  = allocate<ffi.Int16>(count: totalBytes, sizeOfType: ffi.sizeOf<ffi.Int16>());
    // _bytes = _data.asTypedList(totalBytes);
    _bytes.fillRange(0, totalBytes, 0);
    int len = data.length;
    for (int i = 0; i < len; i++) {
      _bytes[i] = data[i];
    }

    // data = _bytes.sublist(0, totalBytes);
    // print(_data.asTypedList(totalBytes));
    var lowPassValue =
        _applyLowPassFilterProcess(channelIdx, _data, totalBytes);
    if (lowPassValue != -1) {
      print("lowPassValue");
      print(lowPassValue);
    }
    data = _bytes.sublist(0, totalBytes);
    // data = _bytes.sublist(0, totalBytes);

    // _data.asTypedList(totalBytes);
    // print("multipliedSample");
    // print(multipliedSample);

    // return List<int>.from(_data.asTypedList(totalBytes));
    return data;

    // print("RESULT ");
    // print(_returnGainFilterProcess(1));
  }

  void createHighPassFilter(channelCount, sampleRate, cutOff, q) {
    _createHighPassFilterProcess(channelCount, sampleRate, cutOff, q);
  }

  double initHighPassFilter(channelCount, sampleRate, cutOff, q) {
    return _initHighPassFilterProcess(channelCount, sampleRate, cutOff, q);
  }

  List<int> highPassFilter(channelIdx, List<int> data, totalBytes) {
    _bytes.fillRange(0, totalBytes, 0);
    int len = data.length;
    for (int i = 0; i < len; i++) {
      _bytes[i] = data[i];
    }

    _applyHighPassFilterProcess(channelIdx, _data, totalBytes);
    data = _bytes.sublist(0, totalBytes);
    // print("multipliedSample");
    // print(multipliedSample);

    // return List<int>.from(_data.asTypedList(totalBytes));
    return data;

    // print("RESULT ");
    // print(_returnGainFilterProcess(1));
  }

  void createThresholdProcess(
      channelCount, sampleRate, threshold, averagedSampleCount, dataThreshold) {
    Nativec.totalThresholdBytes = (timeSpan * sampleRate).floor();
    _dataThreshold = dataThreshold;
    _thresholdBytes = _dataThreshold.asTypedList(Nativec.totalThresholdBytes);
    _thresholdEventIndices = _dataEventIndices.asTypedList(Nativec.totalEventIndicesBytes);
    _thresholdEvents = _dataEvents.asTypedList(Nativec.totalEventsBytes);
    // _thresholdBytes.fillRange(0, Nativec.totalThresholdBytes, 0);

    _createThresholdProcess(
        channelCount, sampleRate, threshold, averagedSampleCount);
  }

  double initThresholdProcess(channelCount, sampleRate, cutOff, q) {
    return _initHighPassFilterProcess(channelCount, sampleRate, cutOff, q);
  }

  double setThresholdParametersProcess(
      channelCount, forceLevel, sampleRate, divider, current_start) {
    return _setThresholdParametersProcess(channelCount, forceLevel,
        sampleRate.toDouble(), divider.toDouble(), current_start.floor());
  }

  double appendSamplesThresholdProcess(averagedSampleCount, threshold,
      channelIdx, samples, sampleCount, divider, currentStart, sampleNeeded, eventIndices, events, eventCount) {
    _thresholdBytes.fillRange(0, Nativec.totalThresholdBytes, 0);
    _thresholdEventIndices.fillRange(0, Nativec.totalEventIndicesBytes, 0);
    _thresholdEvents.fillRange(0, Nativec.totalEventsBytes, 0);
    // int len = samples.length;
    // int len = sampleCount;
    // print(len);
    // for (int i = 0; i < len; i++) {
    //   _thresholdBytes[i] = samples[i];
    // }
    _thresholdBytes.setAll(0, samples);
    _thresholdEventIndices.setAll(0, eventIndices);
    _thresholdEvents.setAll(0, events);

    // for (int i = 0; i < Nativec.totalThresholdBytes; i++) {
    //   _thresholdBytes[i] = i;
    // }

    // print('processedSample');
    double processedSample = _appendSamplesThresholdProcess(
        averagedSampleCount,
        threshold,
        channelIdx,
        _dataThreshold,
        sampleCount,
        divider.toDouble(),
        currentStart.floor(),
        sampleNeeded, 
        _dataEventIndices, _dataEvents, eventCount);
    // print(processedSample);
    return processedSample;
    // print(_thresholdBytes.length);
    // refBytes.setAll(0,_thresholdBytes);
    // return 0;
  }

  double getSamplesThresholdProcess(
      channelIdx, forceLevel, divider, currentStart, sampleNeeded) {
    _thresholdBytes.fillRange(0, Nativec.totalThresholdBytes, 0);
    double processedSample = _getSamplesThresholdProcess(
        channelIdx,
        _dataThreshold,
        forceLevel.floor(),
        divider.toDouble(),
        currentStart,
        sampleNeeded);
    // print(processedSample);
    return processedSample;
  }

  int getThresholdHitProcess(){
    return _getThresholdHitProcess();
  }
  void setTriggerTypeProcess(int channelIdx,int type){
    _setTriggerTypeProcess(channelIdx, type);
  }
}
