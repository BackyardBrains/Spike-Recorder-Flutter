
// import 'package:audioplayers/audioplayers.dart';
// List<AudioPlayer> players =
//     List.generate(4, (_) => AudioPlayer()..setReleaseMode(ReleaseMode.stop));
// int selectedPlayerIdx = 0;

// AudioPlayer get selectedPlayer => players[selectedPlayerIdx];

import 'dart:js' as js;

class TwoNums {
  final int a;
  final int b;
  TwoNums(this.a, this.b);

  int add() {
    return a + b;
  }
}

int _add(int a, int b) {
  return TwoNums(a, b).add();
}

main(){
  var i = 5567;
  print(i*1000000);
  js.context['myHyperSuperMegaFunction'] = _add;
  print(js.context);
  // setExport('add', allowInterop(_add));
  return i;
}

enveloping(){
  return [1,2,3];
}
