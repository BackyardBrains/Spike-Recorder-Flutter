import 'package:flutter/material.dart';

class ProgressModel extends ChangeNotifier {
  double _value = 0;

  ProgressModel();

  setValue(double value) {
    this._value = value;
    notifyListeners();
  }

  getValue() => this._value;

  getPercentage() => (this.getValue() * 100).toInt();
}
