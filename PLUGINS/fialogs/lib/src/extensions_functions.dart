import 'package:flutter/material.dart';

/// TextEditingController extension functions
extension TextEditingControllerExtension on TextEditingController {
  selectAllOnFocus(FocusNode node) {
    node.addListener(() {
      if (node.hasFocus) {
        this.selection =
            TextSelection(baseOffset: 0, extentOffset: this.text.trim().length);
      }
    });
  }

  String getText({String defaultText = ""}) {
    String value = this.text.trim();
    return value.isEmpty ? defaultText : value;
  }

  int getInt({int defaultInteger = 0}) {
    String value = this.text.trim();
    return value.isEmpty
        ? defaultInteger
        : int.tryParse(value) ?? defaultInteger;
  }

  double getDouble({double defaultDouble = 0.0}) {
    String value = this.text.trim();
    return value.isEmpty
        ? defaultDouble
        : double.tryParse(value) ?? defaultDouble;
  }
}

extension NavigatorExtension on State {
  Future<T?> push<T extends Object>(Widget route) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => route,
      ),
    );
  }

  Future<T?> replace<T extends Object>(Widget route) {
    return Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (c) => route,
      ),
    );
  }

  pop<T extends Object>([T? result]) {
    var canPop = Navigator.canPop(context);
    assert(canPop, "Unable to pop the (initial) route");
    Navigator.of(context).pop<T>(result);
  }

  mustPop<T extends Object>([T? result]) {
    Navigator.of(context).pop<T>(result);
  }
}
