import 'package:fialogs/src/data/simple_item.dart';
import 'package:fialogs/src/res/shapes.dart';
import 'package:fialogs/src/res/values.dart';
import 'package:fialogs/src/widgets.dart';
import 'package:flutter/material.dart';

/// Class [OptionDialog] not allowed to create instance of this class directly
class OptionDialog extends StatelessWidget {
  final double _dialogRadius = DecimalValue.dialogRadius;
  final Widget? titleWidget;
  final Widget? icon;
  final bool hideTitleDivider;
  final List<SimpleItem> items;
  final Widget Function(BuildContext, int, SimpleItem) itemBuilder;

  OptionDialog({
    required this.items,
    required this.itemBuilder,
    this.titleWidget,
    this.icon,
    this.hideTitleDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      shape: roundedRectangleBorder(radius: _dialogRadius),
      child: _content(context, screenWidth),
    );
  }

  _options() {
    if (items.length == 0) return emptyWidget();
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        var simpleItem = items[index];
        return itemBuilder(context, index, simpleItem);
      },
    );
  }

  _getTitleWithIcon() {
    if (icon != null && titleWidget != null) {
      return <Widget>[
        Row(
          children: [
            if (icon != null) icon!,
            Expanded(
              child: onlyPadding(child: titleWidget!, left: 8.0),
            ),
          ],
        ),
        if (!hideTitleDivider) onlyPadding(child: divider(), top: 4.0)
      ];
    } else if (titleWidget != null) {
      return <Widget>[
        symmetricPadding(child: titleWidget!, vertical: 8.0),
        if (!hideTitleDivider) onlyPadding(child: divider(), top: 4.0),
      ];
    }
    return <Widget>[SizedBox()];
  }

  _content(BuildContext context, double width) {
    return Container(
      width: getDialogWidth(width),
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
            child: _options(),
          ),
        ],
      ),
    );
  }
}
