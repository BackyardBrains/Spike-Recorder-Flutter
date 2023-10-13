import 'package:fialogs/src/data/simple_item.dart';
import 'package:fialogs/src/functions.dart';
import 'package:fialogs/src/res/srtings.dart';
import 'package:flutter/material.dart';

class MultiSelectionScreen extends StatefulWidget {
  final Widget titleWidget;
  final List<SimpleItem> items;
  final Set<SimpleItem>? selectedItems;
  final bool showSubTitle;
  final String? selectAllText;
  final String? unSelectAllText;

  const MultiSelectionScreen({
    required this.titleWidget,
    required this.items,
    this.selectedItems,
    this.selectAllText,
    this.unSelectAllText,
    this.showSubTitle = false,
  });

  @override
  _MultiSelectionScreenState createState() => _MultiSelectionScreenState();
}

class _MultiSelectionScreenState extends State<MultiSelectionScreen> {
  final TrackingScrollController _trackingScrollController =
      new TrackingScrollController();

  var _searchFieldController = TextEditingController();
  var _searchFieldFocusNode = FocusNode();
  bool _showSearchField = false;
  List<SimpleItem>? _filteredDataSet;
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
    return Scaffold(
      body: CustomScrollView(
        controller: _trackingScrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            title:
                _showSearchField ? _getSearchBarWidget() : widget.titleWidget,
            actions: [
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
                      _filteredDataSet?.forEach((item) => item.checked = true);
                      _selectedItems?.addAll(_filteredDataSet!);
                    });
                  } else if (option == 2) {
                    // un select all
                    setState(() {
                      _filteredDataSet?.forEach((item) => item.checked = false);
                      _selectedItems?.clear();
                    });
                  }
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                var simpleItem = _filteredDataSet?.elementAt(index);
                return CheckboxListTile(
                  value: _selectedItems?.contains(simpleItem),
                  onChanged: (checked) {
                    setState(() {
                      simpleItem?.checked = checked!;
                    });
                    if (simpleItem?.checked ?? false) {
                      _selectedItems?.add(simpleItem!);
                    } else {
                      _selectedItems?.remove(simpleItem);
                    }
                  },
                  title: Text("${simpleItem!.title}"),
                  subtitle: widget.showSubTitle
                      ? Text("${simpleItem.subTitle}")
                      : null,
                );
              },
              childCount: _filteredDataSet?.length,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: 64),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () {
          pop(context, _selectedItems);
        },
      ),
    );
  }

  _getSearchBarWidget() {
    return TextField(
      controller: _searchFieldController,
      focusNode: _searchFieldFocusNode,
      onChanged: (query) {
        if (query != null && query.isNotEmpty) {
          setState(() {
            _filteredDataSet = widget.items
                .where((item) => item.title
                    .toLowerCase()
                    .contains(_searchFieldController.text.toLowerCase()))
                .toList();
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
            radius: 12,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.clear, size: 16),
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
    );
  }
}
