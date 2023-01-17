
import 'dart:io';

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


// Low Pass filter sample https://www.youtube.com/watch?v=X8JD8hHkBMc
class Nativec {
  final ffi.DynamicLibrary nativeLrsLib = Platform.isAndroid
      ? ffi.DynamicLibrary.open("libnative_nativec.so")
      : ffi.DynamicLibrary.process();    
  late GainFilterProcess _gainFilterProcess;
  late ReturnGainFilterProcess _returnGainFilterProcess;
  
  late CreateStruct createStructFn;
  late GetInfo getInfoFn;

  Future<String?> getPlatformVersion() {
    //https://docs.flutter.dev/development/platform-integration/macos/c-interop
    return NativecPlatform.instance.getPlatformVersion();
  }

  Nativec(){
    _gainFilterProcess = nativeLrsLib.lookup<ffi.NativeFunction<gain_filter_func>>('GainFilter')
          .asFunction();    
    _returnGainFilterProcess = nativeLrsLib.lookup<ffi.NativeFunction<return_gain_filter_func>>('ReturnGainFilter')
        .asFunction();

    createStructFn =
        nativeLrsLib.lookupFunction<CreateStruct, CreateStruct>('CreateStruct');
    getInfoFn = nativeLrsLib.lookupFunction<GetInfo, GetInfo>('GetInfo');        

    // var dartMyStruct = createStructFn();
    // // var myStructPtr = malloc<MyStruct>()..ref = dartMyStruct;
    // var myStructPtr = malloc<MyStruct>();
    // String hello = 'hello123';
    // dartMyStruct.info = hello.toNativeUtf8();

    // // It's a pointer, so we can pass by reference.
    // final result = getInfoFn(myStructPtr);
    // print("result.toDartString()");
    // print(result.toDartString());    
  }

  double gain(a, b){
    double multipliedSample = _gainFilterProcess(a, b);
    // print("multipliedSample");
    // print(multipliedSample);

    return multipliedSample;


    // print("RESULT ");
    // print(_returnGainFilterProcess(1));
  
  }
}
