import 'package:fialogs/src/data/simple_item.dart';
import 'package:fialogs/src/functions.dart';
import 'package:fialogs/src/res/shapes.dart';
import 'package:fialogs/src/res/srtings.dart';
import 'package:fialogs/src/res/values.dart';
import 'package:fialogs/src/widgets.dart';
import 'package:flutter/material.dart';

class SingleSelectionDialog extends StatefulWidget {
  final Widget titleWidget;
  final List<SimpleItem> items;
  final Widget Function(BuildContext, int, SimpleItem, String)? itemBuilder;
  final Function(SimpleItem) onItemClick;
  final bool hideTitleDivider;
  final bool itemDivider;
  final bool hideSubTitle;

  SingleSelectionDialog({
    required this.titleWidget,
    required this.items,
    this.itemBuilder,
    required this.onItemClick,
    this.hideTitleDivider = false,
    this.itemDivider = false,
    this.hideSubTitle = true,
  });

  @override
  _SingleSelectionDialogState createState() => _SingleSelectionDialogState();
}

class _SingleSelectionDialogState extends State<SingleSelectionDialog> {
  final double _dialogRadius = DecimalValue.dialogRadius;
  double _screenWidth = 0;

  TextEditingController _searchFieldController = TextEditingController();
  FocusNode _searchFieldFocusNode = FocusNode();
  bool _showSearchField = false;
  List<SimpleItem>? _filteredDataList;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _filteredDataList = widget.items;
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      shape: roundedRectangleBorder(radius: _dialogRadius),
      child: _content(),
    );
  }

  _getSearchBarWidget() {
    return Expanded(
      child: TextField(
        controller: _searchFieldController,
        focusNode: _searchFieldFocusNode,
        onChanged: (query) {
          if (query.isNotEmpty) {
            setState(() {
              _filteredDataList = widget.items
                  .where((item) => item.title
                      .toLowerCase()
                      .contains(_searchFieldController.text.toLowerCase()))
                  .toList();
            });
          } else {
            setState(() {
              _filteredDataList = widget.items;
            });
          }
        },
        decoration: InputDecoration(
          hintText: StringResources.searchHint,
          suffixIcon: IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.clear),
            ),
            onPressed: () {
              setState(() {
                _filteredDataList = widget.items;
                _searchFieldController.clear();
                _showSearchField = !_showSearchField;
              });
            },
          ),
        ),
      ),
    );
  }

  _list() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _filteredDataList?.length,
      itemBuilder: (context, index) {
        var simpleItem = _filteredDataList![index];
        return widget.itemBuilder!(
            context, index, simpleItem, _searchFieldController.text);
      },
    );
  }

  _defaultList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _filteredDataList!.length,
      itemBuilder: (context, index) {
        var simpleItem = _filteredDataList![index];
        return InkWell(
          onTap: () {
            widget.onItemClick(simpleItem);
            pop(context);
          },
          child: ListTile(
            title: Text("${simpleItem.title}"),
            subtitle:
                widget.hideSubTitle ? null : Text("${simpleItem.subTitle}"),
          ),
        );
      },
    );
  }

  _listWithDivider() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _filteredDataList!.length,
      itemBuilder: (context, index) {
        var simpleItem = _filteredDataList![index];
        return widget.itemBuilder!(
            context, index, simpleItem, _searchFieldController.text);
      },
      separatorBuilder: (context, index) => Divider(),
    );
  }

  _defaultListWithDivider() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _filteredDataList!.length,
      itemBuilder: (context, index) {
        var simpleItem = _filteredDataList![index];
        return ListTile(
          onTap: () {
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
    if (_filteredDataList!.length == 0 && _showSearchField)
      return emptyWidget(emptyTextWidget: Text(StringResources.noResultFound));
    if (_filteredDataList!.length == 0) return emptyWidget();
    return widget.itemDivider ? _defaultListWithDivider() : _defaultList();
  }

  _options() {
    if (_filteredDataList!.length == 0 && _showSearchField)
      return emptyWidget(emptyTextWidget: Text(StringResources.noResultFound));
    if (_filteredDataList!.length == 0) return emptyWidget();
    assert(widget.itemBuilder != null);
    return widget.itemDivider ? _listWithDivider() : _list();
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
          Row(
            children: [
              !_showSearchField
                  ? Expanded(child: widget.titleWidget)
                  : _getSearchBarWidget(),
              if (!_showSearchField)
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _showSearchField = !_showSearchField;

                      if (_showSearchField) {
                        Future.delayed(Duration(milliseconds: 500), () {
                          if (_showSearchField) {
                            FocusScope.of(context)
                                .requestFocus(_searchFieldFocusNode);
                          }
                        });
                      } else {
                        FocusScope.of(context).requestFocus(FocusNode());
                      }
                    });
                  },
                ),
            ],
          ),
          onlyPadding(child: divider(), top: 4.0),
          Flexible(
            fit: _showSearchField ? FlexFit.tight : FlexFit.loose,
            child: widget.itemBuilder == null ? _defaultOptions() : _options(),
          ),
        ],
      ),
    );
  }
}
