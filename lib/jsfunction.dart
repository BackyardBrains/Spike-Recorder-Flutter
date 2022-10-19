

// @JS()
// library callable_function;

// import 'package:js/js.dart';

// /// Allows assigning a function to be callable from `window.jsToDart()`
// @JS('jsToDart')
// external set _jsToDart(void Function() f);

// /// Allows calling the assigned function from Dart as well.
// @JS()
// external void jsToDart();

// void _someDartFunction() {
//   print('Hello from Dart!');
// }


// void setJSCallbackFunction() {
//   _jsToDart = allowInterop(_someDartFunction);
//   // JavaScript code may now call `functionName()` or `window.functionName()`.
// }


// @JS()
// library native_communicator;

// import 'package:js/js.dart';
// @JS('nativeCommunicator')
// class NativeCommunicator{

//  @JS('postMessage')
//  external static set _postMessage(void Function(String text) f);
// }
// // No need to do this as 'allowInterop()' will do the necessary.
// //
// // @JS()
// // external static void postMessage();
// //
// // }

// void setJSCallbackFunction(void Function(String text) postMessageFunction) {
//  NativeCommunicator._postMessage = allowInterop(postMessageFunction);
// }