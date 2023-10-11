import 'package:fialogs/fialogs.dart';
import 'package:fialogs/src/functions.dart';
import 'package:fialogs/src/res/shapes.dart';
import 'package:fialogs/src/res/srtings.dart';
import 'package:fialogs/src/res/values.dart';
import 'package:fialogs/src/widgets.dart';
import 'package:flutter/material.dart';

/// Class [SimpleAlertDialog] not allowed to create instance of this class directly
class SimpleAlertDialog extends StatefulWidget {
  final Widget titleWidget;
  final Widget contentWidget;
  final Widget? icon;
  final String? positiveButtonText;
  final String? negativeButtonText;
  final String? neutralButtonText;
  final Function? positiveButtonAction;
  final Function? negativeButtonAction;
  final Function? neutralButtonAction;
  final bool hideNeutralButton;
  final bool confirmationDialog;
  final String? confirmationMessage;

  SimpleAlertDialog(
    this.titleWidget,
    this.contentWidget, {
    this.icon,
    this.positiveButtonText,
    this.positiveButtonAction,
    this.negativeButtonText,
    this.negativeButtonAction,
    this.neutralButtonText,
    this.neutralButtonAction,
    this.hideNeutralButton = false,
    this.confirmationDialog = false,
    this.confirmationMessage,
  });

  @override
  _SimpleAlertDialogState createState() => _SimpleAlertDialogState();
}

class _SimpleAlertDialogState extends State<SimpleAlertDialog> {
  final String _defaultConfirmationMessage =
      StringResources.confirmationMessage;
  final double _dialogRadius = DecimalValue.dialogRadius;
  double _spaceBetweenButtons = DecimalValue.spaceBetweenButtons;
  bool _confirmationDialog = false;
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

  _positiveButton(String text, Function? action) {
    return TextButton(
      onPressed: (!widget.confirmationDialog)
          ? () {
              pop(context);
              if (action != null) action();
            }
          : _confirmationDialog
              ? () {
                  pop(context);
                  if (action != null) action();
                }
              : null,
      child: Text("$text"),
    );
  }

  _negativeButton(String text, Function? action) {
    return TextButton(
      onPressed: () {
        pop(context);
        if (action != null) action();
      },
      child: Text("$text"),
    );
  }

  _cancelButton(String text, Function? action) {
    return TextButton(
      onPressed: () {
        pop(context);
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
          _negativeButton(
              widget.negativeButtonText ?? "", widget.negativeButtonAction),
        sizedBox(widget.negativeButtonAction != null,
            widget.positiveButtonAction != null,
            width: _spaceBetweenButtons),
        if (widget.positiveButtonAction != null)
          _positiveButton(
              widget.positiveButtonText ?? "", widget.positiveButtonAction),
        sizedBox(widget.positiveButtonAction != null,
            (widget.neutralButtonAction != null || !widget.hideNeutralButton),
            width: _spaceBetweenButtons),
        if (!widget.hideNeutralButton)
          _cancelButton(widget.neutralButtonText ?? StringResources.cancel,
              widget.neutralButtonAction),
      ],
    );
  }

  _getTitleWithIcon() {
    if (widget.icon != null) {
      return Row(
        children: [
          if (widget.icon != null) widget.icon!,
          Expanded(
            child: onlyPadding(child: widget.titleWidget, left: 8.0),
          ),
        ],
      );
    } else {
      return symmetricPadding(child: widget.titleWidget, vertical: 8.0);
    }
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
          _getTitleWithIcon(),
          onlyPadding(child: divider(), top: 4.0),
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              child:
                  symmetricPadding(child: widget.contentWidget, vertical: 8.0),
            ),
          ),
          if (widget.confirmationDialog)
            checkBox(
              _confirmationDialog,
              widget.confirmationMessage ?? _defaultConfirmationMessage,
              (checked) {
                setState(() {
                  _confirmationDialog = checked!;
                });
              },
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
