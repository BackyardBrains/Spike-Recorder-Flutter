import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:inject_js/inject_js.dart' as Js;

import 'package:web_ffi/web_ffi.dart';
import 'package:web_ffi/web_ffi_modules.dart';
const String _basePath = 'assets';
Module? _module;

Future<void> initFfi() async {
  // Only initalize if there is no module yet
  if (_module == null) {
    Memory.init();

    // If your generated code would contain something that
    // extends Opaque, you would register it here
    // registerOpaqueType<MyOpaque>();

    // Inject the JavaScript into our page
    await Js.importLibrary('$_basePath/libopus.js');

    // Load the WebAssembly binaries from assets
    String path = '$_basePath/libopus.wasm';
    print("inject1 "+path);
    print(await rootBundle.load(path));

    Uint8List wasmBinaries = (await rootBundle.load(path)).buffer.asUint8List();

    // After we loaded the wasm binaries and injected the js code
    // into our webpage, we obtain a module

    _module = await EmscriptenModule.compile(wasmBinaries, 'libopus');
  }
}

DynamicLibrary openByb() {
  Module? m = _module;
  if (m != null) {
    return new DynamicLibrary.fromModule(m);
  } else {
    throw new StateError('You can not open opus before calling initFfi()!');
  }
}