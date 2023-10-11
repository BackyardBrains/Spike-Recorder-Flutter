import 'package:fialogs/src/data/simple_item.dart';
import 'package:fialogs/src/functions.dart';
import 'package:fialogs/src/res/shapes.dart';
import 'package:fialogs/src/res/values.dart';
import 'package:fialogs/src/widgets.dart';
import 'package:flutter/material.dart';

class RadioListDialog extends StatefulWidget {
  final Widget? titleWidget;
  final Set<SimpleItem> items;
  final SimpleItem? selectedItem;
  final Function(SimpleItem) onItemClick;
  final bool hideTitleDivider;
  final bool itemDivider;
  final bool hideSubTitle;

  const RadioListDialog({
    required this.items,
    required this.onItemClick,
    this.titleWidget,
    this.selectedItem,
    this.hideTitleDivider = true,
    this.itemDivider = true,
    this.hideSubTitle = true,
  });

  @override
  _RadioListDialogState createState() => _RadioListDialogState();
}

class _RadioListDialogState extends State<RadioListDialog> {
  final double _dialogRadius = DecimalValue.dialogRadius;
  double _screenWidth = 0;
  int _radioGroupId = 0;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.selectedItem != null) {
      setState(() {
        _radioGroupId = widget.selectedItem!.id;
      });
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

  _defaultList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        var simpleItem = widget.items.elementAt(index);
        return RadioListTile<int>(
          value: simpleItem.id,
          groupValue: _radioGroupId,
          onChanged: (value) {
            setState(() {
              _radioGroupId = value!;
            });
            widget.onItemClick(simpleItem);
            pop(context);
          },
          title: Text("${simpleItem.title}"),
          subtitle: widget.hideSubTitle ? null : Text("${simpleItem.subTitle}"),
        );
      },
    );
  }

  _defaultListWithDivider() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        var simpleItem = widget.items.elementAt(index);
        return RadioListTile<int>(
          value: simpleItem.id,
          groupValue: _radioGroupId,
          onChanged: (value) {
            setState(() {
              _radioGroupId = value!;
            });
            widget.onItemClick(simpleItem);
            pop(context);
          },
          title: Text("${simpleItem.title}"),
          subtitle: widget.hideSubTitle ? null : Text("${simpleItem.subTitle}"),
        );
      },
      separatorBuilder: (context, index) => Divider(),
    );
  }

  _defaultOptions() {
    if (widget.items.length == 0) return emptyWidget();
    return widget.itemDivider ? _defaultListWithDivider() : _defaultList();
  }

  _content() {
    return Container(
      width: getDialogWidth(_screenWidth),
      padding:
          const EdgeInsets.only(left: 16.0, top: 8.0, right: 16.0, bottom: 8.0),
      decoration: new BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: widget.titleWidget,
          ),
          onlyPadding(child: divider(), top: 4.0),
          Flexible(
            fit: FlexFit.loose,
            child: _defaultOptions(),
          ),
        ],
      ),
    );
  }
}
