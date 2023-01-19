
import 'dart:io';
import 'dart:typed_data';

import 'package:nativec/allocation.dart';

import 'nativec_platform_interface.dart';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

typedef gain_filter_func = ffi.Double Function(
  ffi.Double ,
  ffi.Double ,
);
typedef GainFilterProcess = double Function(
  double ,
  double ,
);

class MyStruct extends ffi.Struct {
  external ffi.Pointer<Utf8> info;
}
typedef CreateStruct = MyStruct Function();
typedef GetInfo = ffi.Pointer<Utf8> Function(ffi.Pointer<MyStruct>);


typedef return_gain_filter_func = ffi.Double Function(ffi.Double);
typedef ReturnGainFilterProcess = double Function(double);

typedef create_low_pass_filters_func = ffi.Double Function(ffi.Double,ffi.Double,ffi.Double,ffi.Pointer<ffi.Int16>, ffi.Uint32);
typedef CreateLowPassFilterProcess = double Function(double,double,double,ffi.Pointer<ffi.Int16>,int);

// Low Pass filter sample https://www.youtube.com/watch?v=X8JD8hHkBMc
class Nativec {
  final ffi.DynamicLibrary nativeLrsLib = Platform.isAndroid
      ? ffi.DynamicLibrary.open("libnative_nativec.so")
      : ffi.DynamicLibrary.process();    
  late CreateLowPassFilterProcess _createLowPassFilterProcess;
  late GainFilterProcess _gainFilterProcess;
  late ReturnGainFilterProcess _returnGainFilterProcess;
  
  late CreateStruct createStructFn;
  late GetInfo getInfoFn;

  static int totalBytes = 1000;
  static ffi.Pointer<ffi.Int16> _data  = allocate<ffi.Int16>(count: totalBytes);
  late Int16List _bytes;

  Future<String?> getPlatformVersion() {
    //https://docs.flutter.dev/development/platform-integration/macos/c-interop
    return NativecPlatform.instance.getPlatformVersion();
  }

  Nativec(){
    _createLowPassFilterProcess = nativeLrsLib.lookup<ffi.NativeFunction<create_low_pass_filters_func>>('createLowPassFilter')
          .asFunction();    
    _gainFilterProcess = nativeLrsLib.lookup<ffi.NativeFunction<gain_filter_func>>('GainFilter')
          .asFunction();    
    _returnGainFilterProcess = nativeLrsLib.lookup<ffi.NativeFunction<return_gain_filter_func>>('ReturnGainFilter')
        .asFunction();


		if (_data == null) {
			// _data = allocate<ffi.Int16>(count: totalBytes);
    }
    // int byteCount = Nativec.totalBytes;
    _bytes = _data.asTypedList(Nativec.totalBytes);
    _bytes.fillRange(0, 100, 33);

    createStructFn =
        nativeLrsLib.lookupFunction<CreateStruct, CreateStruct>('CreateStruct');
    getInfoFn = nativeLrsLib.lookupFunction<GetInfo, GetInfo>('GetInfo');        

    var dartMyStruct = createStructFn();
    // var myStructPtr = malloc<MyStruct>()..ref = dartMyStruct;
    var myStructPtr = malloc<MyStruct>();
    String hello = 'hello123';
    dartMyStruct.info = hello.toNativeUtf8();


    

    // It's a pointer, so we can pass by reference.
    final result = getInfoFn(myStructPtr);
    print("result.toDartString()");
    // print(result.toDartString());    
    // List<int> data = List<int>.generate(100, (index) => index);
    
    
    int totalBytes = 1000;
    (_createLowPassFilterProcess(44100.0, 44100.0/2, 0.5, _data, totalBytes));    
    print(_data.asTypedList(totalBytes));
		if (_data != null) {
			free(_data);
		}    
  }

  double gain(a, b){
    double multipliedSample = _gainFilterProcess(a, b);
    // print("multipliedSample");
    // print(multipliedSample);

    return multipliedSample;


    // print("RESULT ");
    // print(_returnGainFilterProcess(1));
  
  }

  double lowpassFilter(sampleRate, highCutOff, q, _data, totalBytes){
    double multipliedSample = _createLowPassFilterProcess(sampleRate, highCutOff, q, _data,totalBytes);
    // print("multipliedSample");
    // print(multipliedSample);

    return multipliedSample;


    // print("RESULT ");
    // print(_returnGainFilterProcess(1));
  
  }  
}
