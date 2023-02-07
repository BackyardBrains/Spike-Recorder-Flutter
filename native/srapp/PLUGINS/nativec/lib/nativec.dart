import 'dart:io';
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



typedef create_notch_pass_filters_func = ffi.Double Function(
    ffi.Int16, ffi.Int16, ffi.Double, ffi.Double, ffi.Double);
typedef CreateNotchPassFilterProcess = double Function(
    int, int, double, double, double);
typedef init_notch_pass_filters_func = ffi.Double Function(
    ffi.Int16, ffi.Int16, ffi.Double, ffi.Double, ffi.Double);
typedef InitNotchPassFilterProcess = double Function(int, int, double, double, double);
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
  late GainFilterProcess _gainFilterProcess;
  late ReturnGainFilterProcess _returnGainFilterProcess;
  late SetNotchProcess _setNotchProcess;
  late ApplyLowPassFilterProcess _applyLowPassFilterProcess;
  late ApplyHighPassFilterProcess _applyHighPassFilterProcess;
  late ApplyNotchPassFilterProcess _applyNotchPassFilterProcess;
  late InitLowPassFilterProcess _initLowPassFilterProcess;
  late InitHighPassFilterProcess _initHighPassFilterProcess;
  late InitNotchPassFilterProcess _initNotchPassFilterProcess;

  // late CreateStruct createStructFn;
  // late GetInfo getInfoFn;

  static int totalBytes = 1024 * 8;
  static ffi.Pointer<ffi.Int16> _data = allocate<ffi.Int16>(
      count: totalBytes, sizeOfType: ffi.sizeOf<ffi.Int16>());
  late Int16List _bytes;

  Future<String?> getPlatformVersion() {
    //https://docs.flutter.dev/development/platform-integration/macos/c-interop
    return NativecPlatform.instance.getPlatformVersion();
  }

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

    _gainFilterProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<gain_filter_func>>('GainFilter')
        .asFunction();
    _returnGainFilterProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<return_gain_filter_func>>('ReturnGainFilter')
        .asFunction();
    _setNotchProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<set_notch_func>>('setNotch')
        .asFunction();

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

  double setNotchFilter(isNotch50,isNotch60){
    return _setNotchProcess(isNotch50,isNotch60);
  }
  double createNotchPassFilter(isNotch50, channelCount, sampleRate, cutOff, q) {
    return _createNotchPassFilterProcess(isNotch50, channelCount, sampleRate, cutOff, q);
  }

  double initNotchPassFilter(isNotch50, channelCount, sampleRate, cutOff, q) {
    return _initNotchPassFilterProcess(isNotch50, channelCount, sampleRate, cutOff, q);
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
}
