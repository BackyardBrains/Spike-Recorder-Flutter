import 'package:fialogs/src/data/simple_item.dart';
import 'package:fialogs/src/functions.dart';
import 'package:fialogs/src/res/srtings.dart';
import 'package:flutter/material.dart';

class SingleSelectionScreen extends StatefulWidget {
  final Widget titleWidget;
  final List<SimpleItem> items;
  final bool showSubTitle;

  SingleSelectionScreen({
    required this.titleWidget,
    required this.items,
    this.showSubTitle = false,
  });

  @override
  _SingleSelectionScreenState createState() => _SingleSelectionScreenState();
}

class _SingleSelectionScreenState extends State<SingleSelectionScreen> {
  final TrackingScrollController _trackingScrollController =
      new TrackingScrollController();

  var _searchFieldController = TextEditingController();
  var _searchFieldFocusNode = FocusNode();
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
    return Material(
      child: CustomScrollView(
        controller: _trackingScrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            title:
                _showSearchField ? _getSearchBarWidget() : widget.titleWidget,
            actions: _showSearchField
                ? null
                : [
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
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                var item = _filteredDataList![index];
                return ListTile(
                  onTap: () {
                    pop(context, item);
                  },
                  title: Text("${item.title}"),
                  subtitle:
                      widget.showSubTitle ? Text("${item.subTitle}") : null,
                );
              },
              childCount: _filteredDataList?.length,
            ),
          ),
        ],
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
            radius: 12,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.clear, size: 16),
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
    );
  }
}
