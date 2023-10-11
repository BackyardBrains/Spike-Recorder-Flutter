import 'package:fialogs/src/res/shapes.dart';
import 'package:fialogs/src/res/srtings.dart';
import 'package:fialogs/src/res/values.dart';
import 'package:fialogs/src/widgets.dart';
import 'package:flutter/material.dart';

class CustomDialog extends StatefulWidget {
  final Widget contentWidget;
  final Widget? titleWidget;
  final Widget? icon;
  final String? positiveButtonText;
  final String? negativeButtonText;
  final String? neutralButtonText;
  final Function? positiveButtonAction;
  final Function? negativeButtonAction;
  final Function? neutralButtonAction;
  final bool hideNeutralButton;
  final bool hideTitleDivider;

  CustomDialog({
    required this.contentWidget,
    this.titleWidget,
    this.icon,
    this.positiveButtonText,
    this.positiveButtonAction,
    this.negativeButtonText,
    this.negativeButtonAction,
    this.neutralButtonText,
    this.neutralButtonAction,
    this.hideNeutralButton = false,
    this.hideTitleDivider = false,
  });

  @override
  _CustomDialogState createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  final double _dialogRadius = DecimalValue.dialogRadius;
  double _spaceBetweenButtons = DecimalValue.spaceBetweenButtons;
  double _screenWidth = 0;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      shape: roundedRectangleBorder(radius: _dialogRadius),
      child: _content(),
    );
  }

  _positiveActionButton(String text, Function? action) {
    return TextButton(
      onPressed: () {
        if (action != null) action();
      },
      child: Text("$text"),
    );
  }

  _actionButton(String text, Function? action) {
    return TextButton(
      onPressed: () {
        if (action != null) action();
      },
      child: Text("$text"),
    );
  }

  _buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.negativeButtonAction != null)
          _actionButton(
              widget.negativeButtonText ?? "", widget.negativeButtonAction),
        sizedBox(widget.negativeButtonAction != null,
            widget.positiveButtonAction != null,
            width: _spaceBetweenButtons),
        if (widget.positiveButtonAction != null)
          _positiveActionButton(
              widget.positiveButtonText ?? "", widget.positiveButtonAction),
        sizedBox(widget.positiveButtonAction != null,
            (widget.neutralButtonAction != null || !widget.hideNeutralButton),
            width: _spaceBetweenButtons),
        if (!widget.hideNeutralButton)
          _actionButton(widget.neutralButtonText ?? StringResources.cancel,
              widget.neutralButtonAction),
      ],
    );
  }

  _getTitleWithIcon() {
    if (widget.icon != null && widget.titleWidget != null) {
      return <Widget>[
        Row(
          children: [
            if (widget.icon != null) widget.icon!,
            Expanded(
              child: onlyPadding(child: widget.titleWidget!, left: 8.0),
            ),
          ],
        ),
        if (!widget.hideTitleDivider) onlyPadding(child: divider(), top: 4.0)
      ];
    } else if (widget.titleWidget != null) {
      return <Widget>[
        symmetricPadding(child: widget.titleWidget!, vertical: 8.0),
        if (!widget.hideTitleDivider) onlyPadding(child: divider(), top: 4.0),
      ];
    }
    return <Widget>[SizedBox()];
  }

  _content() {
    return Container(
      width: getDialogWidth(_screenWidth),
      padding: dialogContentPadding(),
      decoration: new BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._getTitleWithIcon(),
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              child: widget.contentWidget,
            ),
          ),
          SizedBox(
            height: 8.0,
          ),
          _buttons(),
        ],
      ),
    );
  }
}
