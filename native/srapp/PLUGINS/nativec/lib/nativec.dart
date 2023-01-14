
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


typedef return_gain_filter_func = ffi.Double Function(ffi.Double);
typedef ReturnGainFilterProcess = double Function(double);


// Low Pass filter sample https://www.youtube.com/watch?v=X8JD8hHkBMc
class Nativec {
  Future<String?> getPlatformVersion() {
    //https://docs.flutter.dev/development/platform-integration/macos/c-interop
    final ffi.DynamicLibrary nativeLrsLib = Platform.isAndroid
        ? ffi.DynamicLibrary.open("libnative_nativec.so")
        : ffi.DynamicLibrary.process();    
    GainFilterProcess _gainFilterProcess = nativeLrsLib.lookup<ffi.NativeFunction<gain_filter_func>>('GainFilter')
        .asFunction();
    double multipliedSample = _gainFilterProcess(10, 3);
    print("multipliedSample");
    print(multipliedSample);

    ReturnGainFilterProcess _returnGainFilterProcess = nativeLrsLib.lookup<ffi.NativeFunction<return_gain_filter_func>>('ReturnGainFilter')
        .asFunction();

    print("RESULT ");
    print(_returnGainFilterProcess(1));

    return NativecPlatform.instance.getPlatformVersion();


  }
}
