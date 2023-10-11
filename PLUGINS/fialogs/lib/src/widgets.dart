import 'package:fialogs/src/res/srtings.dart';
import 'package:flutter/material.dart';

/// Get the divider widget [thickness] of 1.0
divider({double thickness = 1.0, double height = 5.0}) {
  return Divider(
    thickness: thickness,
    height: height,
  );
}

/// Checkbox with text message
///
/// value of checkbox [checked] (true, false)
/// [text] message follow by the checkbox
/// [onChange] function onChange(value) to track the checkbox true false value
checkBox(bool checked, String text, Function(bool?)? onChange) {
  return Row(
    children: [
      Padding(
        padding: const EdgeInsets.only(right: 4.0, top: 4.0, bottom: 4.0),
        child: SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(value: checked, onChanged: onChange)),
      ),
      Expanded(child: Text("$text")),
    ],
  );
}

/// SizedBox widget according to condition
sizedBox(bool firstButton, bool lastButton, {double width = 8.0}) {
  return SizedBox(width: firstButton && lastButton ? width : 0.0);
}

/// Dialog content padding
dialogContentPadding() =>
    const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0, bottom: 8.0);

/// symmetricPadding function with @required [child] widget
symmetricPadding(
    {required Widget child, double vertical = 0.0, double horizontal = 0.0}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal),
    child: child,
  );
}

/// onlyPadding function with @required [child] widget
onlyPadding(
    {required Widget child, top = 0.0, right = 0.0, bottom = 0.0, left = 0.0}) {
  return Padding(
    padding:
        EdgeInsets.only(top: top, right: right, bottom: bottom, left: left),
    child: child,
  );
}

/// Padding function with @required [child] widget
padding({required Widget child, padding = 0.0}) {
  return Padding(
    padding: EdgeInsets.all(padding),
    child: child,
  );
}

/// Success icon
successIcon() {
  return CircleAvatar(
    backgroundColor: Colors.teal[400],
    radius: 16,
    child: Icon(
      Icons.check,
      color: Colors.white,
    ),
  );
}

/// Success icon
errorIcon() {
  return CircleAvatar(
    backgroundColor: Colors.red[300],
    radius: 16,
    child: Icon(
      Icons.clear,
      color: Colors.white,
    ),
  );
}

/// Success icon
warningIcon() {
  return CircleAvatar(
    backgroundColor: Colors.orange[300],
    radius: 16,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Icon(
        Icons.warning,
        color: Colors.white,
        size: 20.0,
      ),
    ),
  );
}

/// Success icon
infoIcon() {
  return CircleAvatar(
    backgroundColor: Colors.grey,
    radius: 16,
    child: Icon(
      Icons.info_outline,
      color: Colors.white,
    ),
  );
}

/// Success icon
confirmIcon() {
  return CircleAvatar(
    backgroundColor: Colors.orange[300],
    radius: 16,
    child: Icon(
      Icons.help_outline,
      color: Colors.white,
    ),
  );
}

/// empty widget
emptyWidget(
    {Color? imageBackgroundColor,
    Widget? emptyImageWidget,
    Widget? emptyTextWidget}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(height: 32),
      emptyImageWidget != null
          ? emptyImageWidget
          : CircleAvatar(
              backgroundColor: imageBackgroundColor ?? Colors.orange[300],
              radius: 50,
              child: Icon(Icons.error, size: 64, color: Colors.white),
            ),
      SizedBox(height: 16),
      emptyTextWidget != null
          ? emptyTextWidget
          : Text(
              StringResources.emptyCollection,
              textAlign: TextAlign.center,
            ),
      SizedBox(height: 32),
    ],
  );
}

/// retry widget
retryWidget(
    {Color? imageBackgroundColor,
    Widget? emptyImageWidget,
    Widget? emptyTextWidget,
    String? retryButtonText,
    void Function()? retry}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(height: 32),
      emptyImageWidget != null
          ? emptyImageWidget
          : CircleAvatar(
              backgroundColor: imageBackgroundColor ?? Colors.redAccent,
              radius: 50,
              child: Icon(Icons.report, size: 64, color: Colors.white),
            ),
      SizedBox(height: 16),
      emptyTextWidget != null
          ? emptyTextWidget
          : Text(
              StringResources.somethingWentWrongTryAgain,
              textAlign: TextAlign.center,
            ),
      if (retry != null) ...[
        SizedBox(height: 32),
        OutlinedButton.icon(
          icon: Icon(Icons.settings_backup_restore),
          label: Text("${retryButtonText ?? StringResources.tryAgain}"),
          onPressed: retry,
        ),
      ],
      SizedBox(height: 32),
    ],
  );
}
