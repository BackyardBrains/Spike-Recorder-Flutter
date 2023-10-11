import 'package:fialogs/fialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProgressModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Fialogs Demo',
        theme: lightTheme(),
        // theme: darkTheme(),
        home: MyHomePage(title: 'Fialogs Demo Home Page'),
      ),
    );
  }

  lightTheme() => ThemeData.light().copyWith(
        primaryColor: Colors.teal,
        primaryColorDark: Colors.teal[700],
        accentColor: customColor,
        // Colors.pink[600],
        toggleableActiveColor: customColor,
        // Colors.pink[400],
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );

  darkTheme() => ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        primaryColorDark: Colors.teal[700],
        accentColor: customColor,
        // Colors.pink[600],
        toggleableActiveColor: customColor,
        // Colors.pink[400],
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );

  // 0xFF6200EE
  final Map<int, Color> primaryColorCode = {
    50: Color.fromRGBO(98, 0, 238, .1),
    100: Color.fromRGBO(98, 0, 238, .2),
    200: Color.fromRGBO(98, 0, 238, .3),
    300: Color.fromRGBO(98, 0, 238, .4),
    400: Color.fromRGBO(98, 0, 238, .5),
    500: Color.fromRGBO(98, 0, 238, .6),
    600: Color.fromRGBO(98, 0, 238, .7),
    700: Color.fromRGBO(98, 0, 238, .8),
    800: Color.fromRGBO(98, 0, 238, .9),
    900: Color.fromRGBO(98, 0, 238, 1),
  };

  // 0xFF3700B3
  final Map<int, Color> primary2DarkColorCode = {
    50: Color.fromRGBO(55, 0, 179, .1),
    100: Color.fromRGBO(55, 0, 179, .2),
    200: Color.fromRGBO(55, 0, 179, .3),
    300: Color.fromRGBO(55, 0, 179, .4),
    400: Color.fromRGBO(55, 0, 179, .5),
    500: Color.fromRGBO(55, 0, 179, .6),
    600: Color.fromRGBO(55, 0, 179, .7),
    700: Color.fromRGBO(55, 0, 179, .8),
    800: Color.fromRGBO(55, 0, 179, .9),
    900: Color.fromRGBO(55, 0, 179, 1),
  };

  // 0xFF344955
  final Map<int, Color> primary2ColorCode = {
    50: Color.fromRGBO(52, 73, 85, .1),
    100: Color.fromRGBO(52, 73, 85, .2),
    200: Color.fromRGBO(52, 73, 85, .3),
    300: Color.fromRGBO(52, 73, 85, .4),
    400: Color.fromRGBO(52, 73, 85, .5),
    500: Color.fromRGBO(52, 73, 85, .6),
    600: Color.fromRGBO(52, 73, 85, .7),
    700: Color.fromRGBO(52, 73, 85, .8),
    800: Color.fromRGBO(52, 73, 85, .9),
    900: Color.fromRGBO(52, 73, 85, 1),
  };

  // 0xFF232F34
  static final Map<int, Color> primaryDarkColorCode = {
    50: Color.fromRGBO(35, 47, 52, .1),
    100: Color.fromRGBO(35, 47, 52, .2),
    200: Color.fromRGBO(35, 47, 52, .3),
    300: Color.fromRGBO(35, 47, 52, .4),
    400: Color.fromRGBO(35, 47, 52, .5),
    500: Color.fromRGBO(35, 47, 52, .6),
    600: Color.fromRGBO(35, 47, 52, .7),
    700: Color.fromRGBO(35, 47, 52, .8),
    800: Color.fromRGBO(35, 47, 52, .9),
    900: Color.fromRGBO(35, 47, 52, 1),
  };

  // 0xFF4A6572
  static final Map<int, Color> primaryLightColorCode = {
    50: Color.fromRGBO(74, 101, 114, .1),
    100: Color.fromRGBO(74, 101, 114, .2),
    200: Color.fromRGBO(74, 101, 114, .3),
    300: Color.fromRGBO(74, 101, 114, .4),
    400: Color.fromRGBO(74, 101, 114, .5),
    500: Color.fromRGBO(74, 101, 114, .6),
    600: Color.fromRGBO(74, 101, 114, .7),
    700: Color.fromRGBO(74, 101, 114, .8),
    800: Color.fromRGBO(74, 101, 114, .9),
    900: Color.fromRGBO(74, 101, 114, 1),
  };

  // 0xFFF9AA33
  static final Map<int, Color> accentColorCode = {
    50: Color.fromRGBO(249, 170, 51, .1),
    100: Color.fromRGBO(249, 170, 51, .2),
    200: Color.fromRGBO(249, 170, 51, .3),
    300: Color.fromRGBO(249, 170, 51, .4),
    400: Color.fromRGBO(249, 170, 51, .5),
    500: Color.fromRGBO(249, 170, 51, .6),
    600: Color.fromRGBO(249, 170, 51, .7),
    700: Color.fromRGBO(249, 170, 51, .8),
    800: Color.fromRGBO(249, 170, 51, .9),
    900: Color.fromRGBO(249, 170, 51, 1),
  };

  // 0xFF03DAC5
  static final Map<int, Color> accent2ColorCode = {
    50: Color.fromRGBO(3, 217, 197, .1),
    100: Color.fromRGBO(3, 217, 197, .2),
    200: Color.fromRGBO(3, 217, 197, .3),
    300: Color.fromRGBO(3, 217, 197, .4),
    400: Color.fromRGBO(3, 217, 197, .5),
    500: Color.fromRGBO(3, 217, 197, .6),
    600: Color.fromRGBO(3, 217, 197, .7),
    700: Color.fromRGBO(3, 217, 197, .8),
    800: Color.fromRGBO(3, 217, 197, .9),
    900: Color.fromRGBO(3, 217, 197, 1),
  };

  // 0xFFFD5523
  static final Map<int, Color> accent3ColorCode = {
    50: Color.fromRGBO(253, 85, 35, .1),
    100: Color.fromRGBO(253, 85, 35, .2),
    200: Color.fromRGBO(253, 85, 35, .3),
    300: Color.fromRGBO(253, 85, 35, .4),
    400: Color.fromRGBO(253, 85, 35, .5),
    500: Color.fromRGBO(253, 85, 35, .6),
    600: Color.fromRGBO(253, 85, 35, .7),
    700: Color.fromRGBO(253, 85, 35, .8),
    800: Color.fromRGBO(253, 85, 35, .9),
    900: Color.fromRGBO(253, 85, 35, 1),
  };

  // 0xFFF4511E
  static final Map<int, Color> accent4ColorCode = {
    50: Color.fromRGBO(244, 81, 30, .1),
    100: Color.fromRGBO(244, 81, 30, .2),
    200: Color.fromRGBO(244, 81, 30, .3),
    300: Color.fromRGBO(244, 81, 30, .4),
    400: Color.fromRGBO(244, 81, 30, .5),
    500: Color.fromRGBO(244, 81, 30, .6),
    600: Color.fromRGBO(244, 81, 30, .7),
    700: Color.fromRGBO(244, 81, 30, .8),
    800: Color.fromRGBO(244, 81, 30, .9),
    900: Color.fromRGBO(244, 81, 30, 1),
  };

  // 0xFF880E4F
  static final Map<int, Color> color = {
    50: Color.fromRGBO(136, 14, 79, .1),
    100: Color.fromRGBO(136, 14, 79, .2),
    200: Color.fromRGBO(136, 14, 79, .3),
    300: Color.fromRGBO(136, 14, 79, .4),
    400: Color.fromRGBO(136, 14, 79, .5),
    500: Color.fromRGBO(136, 14, 79, .6),
    600: Color.fromRGBO(136, 14, 79, .7),
    700: Color.fromRGBO(136, 14, 79, .8),
    800: Color.fromRGBO(136, 14, 79, .9),
    900: Color.fromRGBO(136, 14, 79, 1),
  };

  static final MaterialColor customColor = MaterialColor(0xFFF9AA33, accentColorCode);
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final String _alertDialog = "Alert Dialog";
  static final String _successDialog = "Success Dialog";
  static final String _errorDialog = "Error Dialog";
  static final String _warningDialog = "Warning Dialog";
  static final String _infoDialog = "Info Dialog";
  static final String _confirmDialog = "Confirmation Dialog";
  static final String _singleInputDialog = "Single Input Dialog";
  static final String _customDialog = "Custom Dialog";
  static final String _progressDialog = "Progress Dialog";
  static final String _optionsDialog = "Options Dialog";
  static final String _radioListDialog = "Radio List Dialog";
  static final String _singleSelectionDialog = "Single Selection Dialog";
  static final String _multiSelectionDialog = "Multi Selection Dialog";
  static final String _singleSelectionScreen = "Single Selection Screen";
  static final String _multiSelectionScreen = "Multi Selection Screen";

  static final String _simpleField = "Simple Field";
  static final String _passwordField = "Password Field";
  static final String _multiLineField = "Multiline Text Field (Remarks)";

  static final String _short = "Short Text";
  static final String _medium = "Medium Text";
  static final String _long = "Long Text";

  static final String _circular = "Circular";
  static final String _linear = "Linear";

  List<String> _dialogList = <String>[
    _alertDialog,
    _successDialog,
    _errorDialog,
    _warningDialog,
    _infoDialog,
    _confirmDialog,
    _singleInputDialog,
    _progressDialog,
    _customDialog,
    _optionsDialog,
    _radioListDialog,
    _singleSelectionDialog,
    _multiSelectionDialog,
    _singleSelectionScreen,
    _multiSelectionScreen,
  ];

  List<String> _inputDialogList = <String>[
    _simpleField,
    _passwordField,
    _multiLineField,
  ];

  List<String> _textLengthList = <String>[
    _short,
    _medium,
    _long,
  ];

  List<String> _progressDialogList = <String>[
    _circular,
    _linear,
  ];

  List<SimpleItem> _options = <SimpleItem>[
    SimpleItem(id: 1, title: "Option One"),
    SimpleItem(id: 2, title: "Option Two"),
    SimpleItem(id: 3, title: "Option Three"),
    SimpleItem(id: 4, title: "Option Four"),
    SimpleItem(id: 5, title: "Option Five"),
    SimpleItem(id: 6, title: "Option Six"),
    SimpleItem(id: 7, title: "Option Seven"),
    SimpleItem(id: 8, title: "Option Eight"),
    SimpleItem(id: 9, title: "Option Nine"),
    SimpleItem(id: 10, title: "Option Ten"),
    SimpleItem(id: 11, title: "Option Eleven"),
    SimpleItem(id: 12, title: "Option Twelve"),
    SimpleItem(id: 13, title: "Option Thirteen"),
    SimpleItem(id: 14, title: "Option Fourteen"),
    SimpleItem(id: 15, title: "Option Fifteen"),
  ];

  List<SimpleItem> _optionsShort = <SimpleItem>[
    SimpleItem(id: 1, title: "Option One"),
    SimpleItem(id: 2, title: "Option Two"),
    SimpleItem(id: 3, title: "Option Three"),
    SimpleItem(id: 4, title: "Option Four"),
    SimpleItem(id: 5, title: "Option Five"),
  ];

  Set<SimpleItem> _selectedItems = Set();
  SimpleItem _selectedItem;

  var _dialogType = _alertDialog;
  var _textLength = _short;
  var _inputDialogType = _simpleField;
  var _progressDialogType = _circular;

  var _displayProgress = false;
  var _negativeBtn = false;
  var _positiveBtn = false;
  var _cancelBtn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ChangeNotifierProvider(
        create: (context) => ProgressModel(),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<String>(
                      hint: Text("Dialog Type"),
                      value: _dialogType,
                      onChanged: (String item) {
                        setState(() {
                          _dialogType = item;
                        });
                      },
                      items: _dialogList.map((String item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text("$item"),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              if (!(_dialogType == _singleInputDialog ||
                  _dialogType == _customDialog ||
                  _dialogType == _progressDialog ||
                  _dialogType == _optionsDialog))
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<String>(
                        hint: Text("Text Length"),
                        value: _textLength,
                        onChanged: (String item) {
                          setState(() {
                            _textLength = item;
                          });
                        },
                        items: _textLengthList.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text("$item"),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              if (_dialogType == _singleInputDialog)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<String>(
                        hint: Text("Input Dialog Type"),
                        value: _inputDialogType,
                        onChanged: (String item) {
                          setState(() {
                            _inputDialogType = item;
                          });
                        },
                        items: _inputDialogList.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text("$item"),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              if (_dialogType == _progressDialog)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<String>(
                        hint: Text("Progress Type"),
                        value: _progressDialogType,
                        onChanged: (String item) {
                          setState(() {
                            _progressDialogType = item;
                          });
                        },
                        items: _progressDialogList.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text("$item"),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              if (_dialogType == _progressDialog)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: checkBox(_displayProgress, "Display Progress Value", (value) {
                    setState(() {
                      _displayProgress = value;
                    });
                  }),
                ),
              if (_dialogType != _optionsDialog)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: checkBox(_negativeBtn, "Negative Button", (value) {
                    setState(() {
                      _negativeBtn = value;
                    });
                  }),
                ),
              if (_dialogType != _optionsDialog)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: checkBox(_positiveBtn, "Positive Button", (value) {
                    setState(() {
                      _positiveBtn = value;
                    });
                  }),
                ),
              if (_dialogType != _optionsDialog)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: checkBox(_cancelBtn, "Cancel Button", (value) {
                    setState(() {
                      _cancelBtn = value;
                    });
                  }),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: RaisedButton(
                  onPressed: () {
                    _showDialog();
                  },
                  child: Text("Show Dialog"),
                ),
              ),
              SizedBox(
                width: 16.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _showDialog() {
    var pBtn = _positiveBtn ? () {} : null;
    var nBtn = _negativeBtn ? () {} : null;

    var shortText = "Some long dialog content that need to be display in the dialog content area.";
    var mediumText =
        "Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area.";
    var longText =
        "Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area. Some long dialog content that need to be display in the dialog content area.";

    var text = _textLength == _short ? shortText : _textLength == _medium ? mediumText : longText;

    if (_dialogType == _alertDialog) {
      alertDialog(
        context,
        "Alert Dialog",
        text,
        positiveButtonText: "Yes",
        positiveButtonAction: pBtn,
        negativeButtonText: "No",
        negativeButtonAction: nBtn,
        hideNeutralButton: !_cancelBtn,
        closeOnBackPress: true,
      );
    } else if (_dialogType == _successDialog) {
      successDialog(
        context,
        "Success Dialog",
        text,
        positiveButtonText: "Yes",
        positiveButtonAction: pBtn,
        negativeButtonText: "No",
        negativeButtonAction: nBtn,
        hideNeutralButton: !_cancelBtn,
        closeOnBackPress: true,
      );
    } else if (_dialogType == _errorDialog) {
      errorDialog(
        context,
        "Error Dialog",
        text,
        positiveButtonText: "Yes",
        positiveButtonAction: pBtn,
        negativeButtonText: "No",
        negativeButtonAction: nBtn,
        hideNeutralButton: !_cancelBtn,
        closeOnBackPress: true,
      );
    } else if (_dialogType == _warningDialog) {
      warningDialog(
        context,
        "Warning Dialog",
        text,
        positiveButtonText: "Yes",
        positiveButtonAction: pBtn,
        negativeButtonText: "No",
        negativeButtonAction: nBtn,
        hideNeutralButton: !_cancelBtn,
        closeOnBackPress: true,
      );
    } else if (_dialogType == _infoDialog) {
      infoDialog(
        context,
        "Info Dialog",
        text,
        positiveButtonText: "Yes",
        positiveButtonAction: pBtn,
        negativeButtonText: "No",
        negativeButtonAction: nBtn,
        hideNeutralButton: !_cancelBtn,
        closeOnBackPress: true,
      );
    } else if (_dialogType == _confirmDialog) {
      confirmationDialog(
        context,
        "Confirmation Dialog",
        text,
        positiveButtonText: "Yes",
        positiveButtonAction: pBtn,
        negativeButtonText: "No",
        negativeButtonAction: nBtn,
        hideNeutralButton: !_cancelBtn,
        closeOnBackPress: true,
      );
    } else if (_dialogType == _singleInputDialog) {
      singleInputDialog(
        context,
        "Single Input Dialog",
        DialogTextField(
          label: "Input Field",
          // value: "some value",
          // valueAutoSelected: true,
          obscureText: _inputDialogType == _passwordField,
          textInputType: _inputDialogType == _multiLineField ? TextInputType.multiline : TextInputType.text,
          minLines: _inputDialogType == _multiLineField ? 3 : 1,
          maxLines: _inputDialogType == _multiLineField ? 5 : 1,
          validator: (value) {
            if (value.isEmpty) return "Required!";
            return null;
          },
          onEditingComplete: (value) {
            print(value);
          },
        ),
        positiveButtonText: "Yes",
        positiveButtonAction: _positiveBtn
            ? (value) {
                print(value);
              }
            : null,
        negativeButtonText: "No",
        negativeButtonAction: nBtn,
        hideNeutralButton: !_cancelBtn,
        closeOnBackPress: true,
      );
    } else if (_dialogType == _progressDialog) {
      progressDialog(
        context,
        displayValue: _displayProgress,
        autoCloseOnCompletion: true,
        // titleWidget: Text("Connecting", style: dialogTitleStyle(context),),
        progressDialogType: _progressDialogType == _linear ? ProgressDialogType.LINEAR : ProgressDialogType.CIRCULAR,
        contentWidget: Text(
          "Connecting to Server, Please wait, this will take some time...",
          textAlign: TextAlign.justify,
          style: dialogContentStyle(context),
        ),
        positiveButtonText: "Yes",
        positiveButtonAction: pBtn,
        negativeButtonText: "No",
        negativeButtonAction: nBtn,
        hideNeutralButton: !_cancelBtn,
        closeOnBackPress: !_displayProgress,
        hideTitleDivider: false,
      );
      updateProgress();
    } else if (_dialogType == _customDialog) {
      customDialog(
        context,
        title: Text(
          "Custom Dialog",
          style: TextStyle(
            color: Colors.orange,
            fontSize: 32,
          ),
        ),
        content: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: "Input Field"),
            ),
            Divider(),
            Icon(
              Icons.person,
              size: 64,
              color: Colors.deepOrange,
            ),
            Divider(),
            Text(
              "Custom text description for custom dialog",
              style: TextStyle(
                color: Colors.pinkAccent,
                fontSize: 16,
              ),
            ),
          ],
        ),
        positiveButtonText: "Okay",
        positiveButtonAction: _positiveBtn ? () {} : null,
        negativeButtonText: "Not Okay",
        negativeButtonAction: nBtn,
        neutralButtonAction: () {
          Navigator.pop(context);
        },
        hideNeutralButton: !_cancelBtn,
        closeOnBackPress: true,
        hideTitleDivider: true,
      );
    } else if (_dialogType == _optionsDialog) {
      optionsDialog(
        context,
        title: "Select Option",
        simpleItems: _options,
        // simpleItems: [],
        itemBuilder: (context, index, simpleItem) {
          return Card(
            child: ListTile(
              onTap: () {
                print(simpleItem);
                Navigator.pop(context);
              },
              title: Text(simpleItem.title),
            ),
          );
        },
        closeOnBackPress: true,
      );
    } else if (_dialogType == _radioListDialog) {
      radioSelectionDialog(
        context,
        title: "Select Option",
        items: _optionsShort.toSet(),
        selectedItem: _selectedItem,
        onItemClick: (item) {
          setState(() {
            _selectedItem = item;
          });
        },
        hideSubTitle: false,
        closeOnBackPress: true,
      );
    } else if (_dialogType == _singleSelectionDialog) {
      // singleSelectionDialogWithBuilder(
      singleSelectionDialog(
        context,
        title: "Single Selection",
        itemDivider: false,
        items: _options,
        onItemClick: (simpleItem) {
          print(simpleItem);
          Navigator.push(context, null);
          // push(null);
        },
        // itemBuilder: (context, index, item, queryText) {
        //   return ListTile(
        //     onTap: () {
        //       print(item);
        //       Navigator.pop(context);
        //     },
        //     title: Text(item.title),
        //   );
        // },
      );
    } else if (_dialogType == _multiSelectionDialog) {
      multiSelectionDialog(
        context,
        title: "Multi Selection",
        items: _options.toSet(),
        selectedItems: _selectedItems,
        onSubmit: (selectedItems) {
          print(selectedItems);
          setState(() {
            _selectedItems = selectedItems;
          });
        },
      );
    } else if (_dialogType == _singleSelectionScreen) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SingleSelectionScreen(
            items: _options,
            titleWidget: Text("Single Selection"),
          ),
        ),
      ).then(
        (item) {
          if (item != null && item is SimpleItem) {
            print(item);
          }
        },
      );
    } else if (_dialogType == _multiSelectionScreen) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiSelectionScreen(
            items: _options,
            selectedItems: _selectedItems,
            titleWidget: Text("Multi Selection"),
          ),
        ),
      ).then(
        (selectedItems) {
          if (selectedItems != null && selectedItems is Set<SimpleItem>) {
            print(selectedItems);
          }
        },
      );
    }
  }

  updateProgress() async {
    var model = context.read<ProgressModel>();
    model.setValue(0.0);
    for (var i = 0.00; i <= 1.00; i = i + 0.01) {
      await Future.delayed(Duration(milliseconds: 100), () {
        var model = context.read<ProgressModel>();
        if (i > 0.99) {
          model.setValue(1.0);
        } else {
          model.setValue(i);
        }
      });
    }
  }
}
