import 'package:flutter/material.dart';

/// Get the rounded rectangle border of [radius] default is 16.0
roundedRectangleBorder({radius = 16.0}) => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

/// outline border
outlineBorder(BuildContext context, Color color,
        {double width = 1.0, double radius = 16.0}) =>
    RoundedRectangleBorder(
      side: BorderSide(color: color, width: width, style: BorderStyle.solid),
      borderRadius: BorderRadius.circular(radius),
    );
