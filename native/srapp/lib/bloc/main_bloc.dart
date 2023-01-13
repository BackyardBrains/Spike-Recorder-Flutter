import 'dart:async';

class MainBloc {
  StreamController<String> deviceStatusController =
      new StreamController<String>.broadcast();
  Stream<String> get deviceStatusStream => deviceStatusController.stream;
  Function(String) get changeDeviceStatus => deviceStatusController.sink.add;
}

var mainBloc = new MainBloc();
