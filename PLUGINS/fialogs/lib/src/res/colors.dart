import 'package:flutter/material.dart';

/// Get the primary color of the application
primaryColor(BuildContext context) => Theme.of(context).primaryColor;

/// Get the dark primary color of the application
primaryColorDark(BuildContext context) => Theme.of(context).primaryColorDark;

/// Get the accent color of the application
accentColor(BuildContext context) => Colors.white;

/// get barrierColor for dialogs
getBarrierColor() => Colors.black.withOpacity(0.5);
