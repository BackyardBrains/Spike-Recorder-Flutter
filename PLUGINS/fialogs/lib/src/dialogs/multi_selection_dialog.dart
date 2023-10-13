import 'package:fialogs/fialogs.dart';
import 'package:fialogs/src/data/simple_item.dart';
import 'package:fialogs/src/functions.dart';
import 'package:fialogs/src/res/shapes.dart';
import 'package:fialogs/src/res/srtings.dart';
import 'package:fialogs/src/res/values.dart';
import 'package:flutter/material.dart';

class MultiSelectionDialog extends StatefulWidget {
  final Widget titleWidget;
  final Set<SimpleItem> items;
  final Set<SimpleItem>? selectedItems;
  final Function(Set<SimpleItem>) onSubmit;
  final bool hideTitleDivider;
  final bool itemDivider;
  final bool hideSubTitle;
  final String? submitButtonText;
  final String? selectAllText;
  final String? unSelectAllText;

  MultiSelectionDialog({
    required this.titleWidget,
    required this.items,
    required this.onSubmit,
    this.selectedItems,
    this.hideTitleDivider = true,
    this.itemDivider = false,
    this.hideSubTitle = true,
    this.submitButtonText,
    this.selectAllText,
    this.unSelectAllText,
  });

  @override
  _MultiSelectionDialogState createState() => _MultiSelectionDialogState();
}

class _MultiSelectionDialogState extends State<MultiSelectionDialog> {
  final double _dialogRadius = DecimalValue.dialogRadius;
  double _screenWidth = 0;

  var _searchFieldController = TextEditingController();
  var _searchFieldFocusNode = FocusNode();
  bool _showSearchField = false;
  Set<SimpleItem>? _filteredDataSet = Set();
  Set<SimpleItem>? _selectedItems = Set();

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _filteredDataSet = widget.items;
    if (widget.selectedItems != null) {
      _selectedItems = widget.selectedItems;
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

  _getSearchBarWidget() {
    return Expanded(
      child: TextField(
        controller: _searchFieldController,
        focusNode: _searchFieldFocusNode,
        onChanged: (query) {
          if (query.isNotEmpty) {
            setState(() {
              _filteredDataSet = widget.items
                  .where((item) => item.title
                      .toLowerCase()
                      .contains(_searchFieldController.text.toLowerCase()))
                  .toSet();
            });
          } else {
            setState(() {
              _filteredDataSet = widget.items;
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
                _filteredDataSet = widget.items;
                _searchFieldController.clear();
                _showSearchField = !_showSearchField;
              });
            },
          ),
        ),
      ),
    );
  }

  _defaultList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _filteredDataSet?.length,
      itemBuilder: (context, index) {
        var simpleItem = _filteredDataSet?.elementAt(index);
        return CheckboxListTile(
          value: _selectedItems?.contains(simpleItem),
          onChanged: (checked) {
            setState(() {
              simpleItem?.checked = checked ?? false;
            });
            if (simpleItem?.checked ?? false) {
              _selectedItems?.add(simpleItem!);
            } else {
              _selectedItems?.remove(simpleItem);
            }
          },
          title: Text("${simpleItem?.title}"),
          subtitle:
              widget.hideSubTitle ? null : Text("${simpleItem?.subTitle}"),
        );
      },
    );
  }

  _defaultListWithDivider() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _filteredDataSet!.length,
      itemBuilder: (context, index) {
        var simpleItem = _filteredDataSet?.elementAt(index);
        return CheckboxListTile(
          value: _selectedItems?.contains(simpleItem),
          onChanged: (checked) {
            setState(() {
              simpleItem!.checked = checked ?? false;
            });
            if (simpleItem!.checked) {
              _selectedItems?.add(simpleItem);
            } else {
              _selectedItems?.remove(simpleItem);
            }
          },
          title: Text("${simpleItem!.title}"),
          subtitle: widget.hideSubTitle ? null : Text("${simpleItem.subTitle}"),
        );
      },
      separatorBuilder: (context, index) => Divider(),
    );
  }

  _defaultOptions() {
    if (_filteredDataSet?.length == 0 && _showSearchField)
      return emptyWidget(emptyTextWidget: Text(StringResources.noResultFound));
    if (_filteredDataSet?.length == 0) return emptyWidget();
    return widget.itemDivider ? _defaultListWithDivider() : _defaultList();
  }

  _buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            widget.onSubmit(_selectedItems!);
            pop(context);
          },
          child: Text(widget.submitButtonText ?? "Done"),
        )
      ],
    );
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
              PopupMenuButton(
                icon: Icon(Icons.more_vert),
                itemBuilder: (_) => <PopupMenuEntry<int>>[
                  PopupMenuItem(
                    value: 1,
                    child: Text(widget.selectAllText ?? "Select All"),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Text(widget.unSelectAllText ?? "Un-Select All"),
                  ),
                ],
                onSelected: (option) {
                  if (option == 1) {
                    // select all
                    setState(() {
                      _filteredDataSet!.forEach((item) => item.checked = true);
                      _selectedItems!.addAll(_filteredDataSet!);
                    });
                  } else if (option == 2) {
                    // un select all
                    setState(() {
                      _filteredDataSet!.forEach((item) => item.checked = false);
                      _selectedItems!.clear();
                    });
                  }
                },
              ),
            ],
          ),
          onlyPadding(child: divider(), top: 4.0),
          Flexible(
            fit: _showSearchField ? FlexFit.tight : FlexFit.loose,
            child: _defaultOptions(),
          ),
          SizedBox(height: 8.0),
          _buttons(),
        ],
      ),
    );
  }
}
