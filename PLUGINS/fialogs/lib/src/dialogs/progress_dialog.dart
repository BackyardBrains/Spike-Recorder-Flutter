import 'package:fialogs/fialogs.dart';
import 'package:fialogs/src/functions.dart';
import 'package:fialogs/src/props/progress_dialog_type.dart';
import 'package:fialogs/src/res/shapes.dart';
import 'package:fialogs/src/res/srtings.dart';
import 'package:fialogs/src/res/values.dart';
import 'package:fialogs/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Class [ProgressDialog] not allowed to create instance of this class directly
class ProgressDialog extends StatefulWidget {
  final ProgressDialogType progressDialogType;
  final bool displayValue;
  final bool autoCloseOnCompletion;
  final Widget? titleWidget;
  final Widget? contentWidget;
  final Widget? icon;
  final String? positiveButtonText;
  final String? negativeButtonText;
  final String? neutralButtonText;
  final Function? positiveButtonAction;
  final Function? negativeButtonAction;
  final Function? neutralButtonAction;
  final bool hideNeutralButton;
  final bool hideTitleDivider;
  final Color? backgroundColor;
  final Animation<Color>? valueColor;
  final double? circularStrokeWidth;
  final double? linearMinHeight;

  ProgressDialog({
    this.progressDialogType = ProgressDialogType.CIRCULAR,
    this.displayValue = false,
    this.autoCloseOnCompletion = false,
    this.titleWidget,
    this.contentWidget,
    this.icon,
    this.positiveButtonText,
    this.positiveButtonAction,
    this.negativeButtonText,
    this.negativeButtonAction,
    this.neutralButtonText,
    this.neutralButtonAction,
    this.hideNeutralButton = true,
    this.hideTitleDivider = true,
    this.backgroundColor,
    this.valueColor,
    this.circularStrokeWidth,
    this.linearMinHeight,
  });

  @override
  _ProgressDialogState createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<ProgressDialog> {
  final double _dialogRadius = DecimalValue.dialogRadius;
  double _spaceBetweenButtons = DecimalValue.spaceBetweenButtons;
  double _screenWidth = 0;
  var _autoCloseDuration = Duration(milliseconds: 500);

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
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
      onPressed: () {
        if (action != null) action();
        pop(context);
      },
      child: Text("$text"),
    );
  }

  _negativeButton(String text, Function? action) {
    return TextButton(
      onPressed: () {
        if (action != null) action();
        pop(context);
      },
      child: Text("$text"),
    );
  }

  _cancelButton(String text, Function? action) {
    return TextButton(
      onPressed: () {
        if (action != null) action();
        pop(context);
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

  _autoClose(int value) {
    if (widget.autoCloseOnCompletion && value >= 100) {
      Future.delayed(_autoCloseDuration, () {
        pop(context);
      });
    }
  }

  _circularProgress() {
    return Column(
      children: [
        if (widget.titleWidget != null) SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: widget.contentWidget == null
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: <Widget>[
            widget.displayValue != null && widget.displayValue
                ? Consumer<ProgressModel>(
                    builder: (context, model, child) {
                      _autoClose(model.getPercentage());
                      return Container(
                        margin: EdgeInsets.all(8),
                        child: Stack(
                          children: [
                            CircularProgressIndicator(
                              value: model.getValue(),
                              valueColor: widget.valueColor,
                              backgroundColor: widget.backgroundColor,
                              strokeWidth: widget.circularStrokeWidth ?? 4.0,
                            ),
                            // if (widget.value != null)
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: Text("${model.getPercentage()}%"),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Container(
                    margin: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      valueColor: widget.valueColor,
                      backgroundColor: widget.backgroundColor,
                      strokeWidth: widget.circularStrokeWidth ?? 4.0,
                    ),
                  ),
            if (widget.contentWidget != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: widget.contentWidget,
                ),
              ),
          ],
        ),
      ],
    );
  }

  _linearProgress() {
    return Column(
      children: [
        if (widget.contentWidget != null)
          Padding(
            padding: EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                bottom: 16.0,
                top: widget.titleWidget == null ? 0.0 : 8.0),
            child: widget.contentWidget,
          ),
        widget.displayValue != null && widget.displayValue
            ? Consumer<ProgressModel>(
                builder: (context, model, child) {
                  _autoClose(model.getPercentage());
                  return Container(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              top: widget.titleWidget == null ? 0.0 : 8.0),
                          child: LinearProgressIndicator(
                            value: model.getValue(),
                            valueColor: widget.valueColor,
                            backgroundColor: widget.backgroundColor,
                            minHeight: widget.linearMinHeight,
                          ),
                        ),
                        // if (widget.value != null)
                        Text(
                          "${model.getPercentage()}%",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              )
            : Padding(
                padding: EdgeInsets.only(
                    top: widget.titleWidget == null ? 0.0 : 8.0),
                child: LinearProgressIndicator(
                  valueColor: widget.valueColor,
                  backgroundColor: widget.backgroundColor,
                  minHeight: widget.linearMinHeight,
                ),
              ),
      ],
    );
  }

  _buildProgress() {
    switch (widget.progressDialogType) {
      case ProgressDialogType.CIRCULAR:
        return _circularProgress();
        break;
      case ProgressDialogType.LINEAR:
        return _linearProgress();
        break;
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
          ..._getTitleWithIcon(),
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              child: _buildProgress(),
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
