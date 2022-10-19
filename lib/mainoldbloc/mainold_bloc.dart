
import 'dart:async';


abstract class BlocBase {
  void dispose();
}


class MainOldBloc extends BlocBase {

  StreamController<List<double>> _streamNotificationPermissionController = StreamController<List<double>>.broadcast();
  Stream<List<double>> get streamNotificationPermission => _streamNotificationPermissionController.stream;
  changeNotificationPermission(flag){
    _streamNotificationPermissionController.sink.add(flag);
  }


  MainOldBloc() {
    //  * Listen to user changes

  }

  @override
  void dispose() {
    _streamNotificationPermissionController.close();
  }
}


MainOldBloc mainOldBloc = new MainOldBloc();