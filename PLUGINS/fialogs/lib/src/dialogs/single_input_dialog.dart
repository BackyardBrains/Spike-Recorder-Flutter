import 'package:fialogs/src/extensions_functions.dart';
import 'package:fialogs/src/functions.dart';
import 'package:fialogs/src/props/dialog_text_field.dart';
import 'package:fialogs/src/res/shapes.dart';
import 'package:fialogs/src/res/srtings.dart';
import 'package:fialogs/src/res/values.dart';
import 'package:fialogs/src/widgets.dart';
import 'package:flutter/material.dart';

class SingleInputDialog extends StatefulWidget {
  final Widget? icon;
  final Widget titleWidget;
  final DialogTextField dialogTextField;
  final String? positiveButtonText;
  final String? negativeButtonText;
  final String? neutralButtonText;
  final Function(String)? positiveButtonAction;
  final Function? negativeButtonAction;
  final Function? neutralButtonAction;
  final bool hideNeutralButton;

  SingleInputDialog(
    this.icon,
    this.titleWidget,
    this.dialogTextField, {
    this.positiveButtonText,
    this.positiveButtonAction,
    this.negativeButtonText,
    this.negativeButtonAction,
    this.neutralButtonText,
    this.neutralButtonAction,
    this.hideNeutralButton = false,
  });

  @override
  _SingleInputDialogState createState() => _SingleInputDialogState();
}

class _SingleInputDialogState extends State<SingleInputDialog> {
  GlobalKey<FormState> _inputFormKey = new GlobalKey<FormState>();
  bool _passwordField = false;

  var _singleInputFieldController = TextEditingController();
  var _singleInputFieldFocusNode = FocusNode();

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
  void initState() {
    super.initState();
    setState(() {
      _passwordField = widget.dialogTextField.obscureText;
    });

    Future.delayed(Duration(milliseconds: 500), () {
      if (widget.dialogTextField.valueAutoSelected) {
        if (widget.dialogTextField.value != null &&
            widget.dialogTextField.value!.trim().isNotEmpty) {
          setState(() {
            _singleInputFieldController.text =
                widget.dialogTextField.value!.trim();
            _singleInputFieldController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: this.widget.dialogTextField.value!.trim().length);
          });
        }
      } else {
        if (widget.dialogTextField.value != null &&
            widget.dialogTextField.value!.trim().isNotEmpty) {
          setState(() {
            _singleInputFieldController.text =
                widget.dialogTextField.value!.trim();
            _singleInputFieldController.selection = TextSelection.fromPosition(
                TextPosition(offset: _singleInputFieldController.text.length));
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      shape: roundedRectangleBorder(radius: _dialogRadius),
      child: _content(),
    );
  }

  _performPositiveAction(Function(String)? action) {
    if (action != null) action(_singleInputFieldController.getText());
    pop(context);
  }

  _positiveActionButton(String text, Function(String)? action) {
    return TextButton(
      onPressed: () {
        if (widget.dialogTextField.validator != null) {
          if (_inputFormKey.currentState!.validate()) {
            _performPositiveAction(action);
          }
        } else {
          _performPositiveAction(action);
        }
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
          _positiveActionButton(
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
          widget.icon!,
          Expanded(
            child: onlyPadding(child: widget.titleWidget, left: 8.0),
          ),
        ],
      );
    } else {
      return symmetricPadding(child: widget.titleWidget, vertical: 8.0);
    }
  }

  _performOnEditingCompleteAction() {
    if (widget.dialogTextField.onEditingComplete != null) {
      widget.dialogTextField
          .onEditingComplete!(_singleInputFieldController.getText());
    }
    pop(context);
  }

  _onEditingComplete() {
    if (widget.dialogTextField.validator != null) {
      if (_inputFormKey.currentState!.validate()) {
        _performOnEditingCompleteAction();
      }
    } else {
      _performOnEditingCompleteAction();
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
              child: Form(
                key: _inputFormKey,
                child: symmetricPadding(
                  child: TextFormField(
                    autofocus: true,
                    obscureText: _passwordField,
                    maxLines: widget.dialogTextField.maxLines,
                    minLines: widget.dialogTextField.minLines,
                    controller: _singleInputFieldController,
                    focusNode: _singleInputFieldFocusNode,
                    keyboardType: widget.dialogTextField.textInputType,
                    textInputAction: TextInputAction.done,
                    textCapitalization:
                        widget.dialogTextField.textCapitalization ??
                            TextCapitalization.none,
                    textAlign: widget.dialogTextField.textAlign,
                    style: widget.dialogTextField.textStyle,
                    onEditingComplete: _onEditingComplete,
                    onChanged: widget.dialogTextField.onChanged,
                    validator: widget.dialogTextField.validator,
                    decoration: InputDecoration(
                      labelText: widget.dialogTextField.label,
                      hintText: widget.dialogTextField.hint,
                      errorText: null,
                      prefixIcon: widget.dialogTextField.prefixIcon,
                      helperText: widget.dialogTextField.helperText,
                      border: widget.dialogTextField.inputBorder,
                      suffixIcon: (widget.dialogTextField.obscureText)
                          ? Container(
                              margin: EdgeInsets.only(top: 16.0),
                              child: IconButton(
                                alignment: Alignment.centerRight,
                                icon: Icon(
                                  _passwordField
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _passwordField = !_passwordField;
                                  });
                                },
                              ),
                            )
                          : null,
                    ),
                  ),
                  vertical:
                      widget.dialogTextField.inputBorder != null ? 16.0 : 8.0,
                ),
              ),
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
