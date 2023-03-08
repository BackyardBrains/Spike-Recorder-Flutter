import 'package:flutter/material.dart';

class DialogTextField {
  final String? label;
  final String? value;
  final String? hint;
  final Function(String)? onChanged;
  final Function(String)? onEditingComplete;
  final bool valueAutoSelected;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int minLines;
  final int maxLines;
  final TextInputType? textInputType;
  final TextCapitalization? textCapitalization;
  final TextAlign textAlign;
  final String? helperText;
  final InputBorder? inputBorder;
  final TextStyle? textStyle;
  final Widget? prefixIcon;

  DialogTextField({
    this.label,
    this.value,
    this.hint,
    this.onChanged,
    this.onEditingComplete,
    this.valueAutoSelected = false,
    this.validator,
    this.obscureText = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.textInputType,
    this.textCapitalization,
    this.textAlign = TextAlign.start,
    this.helperText,
    this.inputBorder,
    this.textStyle,
    this.prefixIcon,
  });
}
