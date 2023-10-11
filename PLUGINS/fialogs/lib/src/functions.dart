import 'package:flutter/material.dart';

Future<T?> push<T extends Object>(BuildContext context, Widget route) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (c) => route,
    ),
  );
}

pop<T extends Object>(BuildContext context, [T? result]) {
  var canPop = Navigator.canPop(context);
  assert(canPop, "Unable to pop the (initial) route");
  Navigator.of(context).pop<T>(result);
}

Future<T?> replace<T extends Object>(BuildContext context, Widget route) {
  return Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (c) => route,
    ),
  );
}

getDialogPopUpAnimationDuration() => Duration(milliseconds: 300);

getDialogAnimation(Animation<double> a1, Animation<double> a2, Widget widget) {
  return Transform.scale(
    scale: a1.value,
    child: Opacity(
      opacity: a1.value,
      child: widget,
    ),
  );
}
