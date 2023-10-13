import 'package:flutter/material.dart';

/// Get the text title style of the application
dialogTitleStyle(BuildContext context) => Theme.of(context).textTheme.headline6;

/// Get the message content style of the application
dialogContentStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyText2;
