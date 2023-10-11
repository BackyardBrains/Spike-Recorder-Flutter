# fialogs  
  
## Simple Flutter Dialog  
  
### Table of Content  
  
- Alert Dialog
- Confirmation Dialog
- Single Input Dialog
- Progress Dialog
- Custom Dialog


# Alert Dialog 

### Custom Alert Dialog

```
customAlertDialog(
	context,
	Text("Dialog Title"),
	Text("Display message"),
	titleIcon: Icon(Icons.person),
	positiveButtonText: "OK",
	positiveButtonAction: () {},
	negativeButtonText: "OK",
	negativeButtonAction: () {},
	neutralButtonText: "OK",
	neutralButtonAction: () {},
	hideNeutralButton: false,
	closeOnBackPress: false,
	confirmationDialog: false,
	confirmationMessage: "",
);
```

### Alert Dialog

```
alertDialog(
	context,
	"Dialog Title",
	"Display message",
	positiveButtonText: "OK",
	positiveButtonAction: () {},
	negativeButtonText: "OK",
	negativeButtonAction: () {},
	neutralButtonText: "OK",
	neutralButtonAction: () {},
	hideNeutralButton: false,
	closeOnBackPress: false,
);
```

### Success Dialog

```
successDialog(
	context,
	"Dialog Title",
	"Display message",
	positiveButtonText: "OK",
	positiveButtonAction: () {},
	negativeButtonText: "OK",
	negativeButtonAction: () {},
	neutralButtonText: "OK",
	neutralButtonAction: () {},
	hideNeutralButton: false,
	closeOnBackPress: false,
);
```

### Error Dialog

```
errorDialog(
	context,
	"Dialog Title",
	"Display message",
	positiveButtonText: "OK",
	positiveButtonAction: () {},
	negativeButtonText: "OK",
	negativeButtonAction: () {},
	neutralButtonText: "OK",
	neutralButtonAction: () {},
	hideNeutralButton: false,
	closeOnBackPress: false,
);
```

### Warning Dialog

```
warningDialog(
	context,
	"Dialog Title",
	"Display message",
	positiveButtonText: "OK",
	positiveButtonAction: () {},
	negativeButtonText: "OK",
	negativeButtonAction: () {},
	neutralButtonText: "OK",
	neutralButtonAction: () {},
	hideNeutralButton: false,
	closeOnBackPress: false,
);
```

### Info Dialog

```
infoDialog(
	context,
	"Dialog Title",
	"Display message",
	positiveButtonText: "OK",
	positiveButtonAction: () {},
	negativeButtonText: "OK",
	negativeButtonAction: () {},
	neutralButtonText: "OK",
	neutralButtonAction: () {},
	hideNeutralButton: false,
	closeOnBackPress: false,
);
```

# Confirmation Dialog

### Custom Confirmation Dialog

```
customAlertDialog(
	context,
	Text("Dialog Title"),
	Text("Display message"),
	titleIcon: Icon(Icons.person),
	positiveButtonText: "OK",
	positiveButtonAction: () {},
	negativeButtonText: "OK",
	negativeButtonAction: () {},
	neutralButtonText: "OK",
	neutralButtonAction: () {},
	hideNeutralButton: false,
	closeOnBackPress: false,
	confirmationDialog: true,
	confirmationMessage: "Confirmation text message",
);
```

### Confirmation Dialog

```
confirmationDialog(
	context,
	"Dialog Title",
	"Display message",
	positiveButtonText: "OK",
	positiveButtonAction: () {},
	negativeButtonText: "OK",
	negativeButtonAction: () {},
	neutralButtonText: "OK",
	neutralButtonAction: () {},
	hideNeutralButton: false,
	closeOnBackPress: false,
	confirmationDialog: true,
	confirmationMessage: "Please select this check box for confirmation",
);
```

# Single Input Dialog

### Simple Text Field Input Dialog

```
customSingleInputDialog(  
	context,  
	Text("Single Input Dialog"),  
	DialogTextField(  
		fieldLabel: "Input Field",  
		obscureText: false,  
		textInputType: TextInputType.text,   
		validator: (value) {  
			if (value.isEmpty) return "Required!";  
			return null;  
		},  
		onEditingComplete: (value) {  
			print(value);  
		}  
	),  
	positiveButtonText: "Yes",  
	positiveButtonAction: (value) {  
		print(value);  
	},  
	negativeButtonText: "No",  
	negativeButtonAction: () {},  
	hideNeutralButton: false,  
	closeOnBackPress: true,  
);
```

### Simple Text Field Input Dialog

```
singleInputDialog(  
	context,  
	"Single Input Dialog",  
	DialogTextField(  
		fieldLabel: "Input Field",  
		obscureText: false,  
		textInputType: TextInputType.text,   
		validator: (value) {  
			if (value.isEmpty) return "Required!";  
			return null;  
		},  
		onEditingComplete: (value) {  
			print(value);  
		}  
	),  
	positiveButtonText: "Yes",  
	positiveButtonAction: (value) {  
		print(value);  
	},  
	negativeButtonText: "No",  
	negativeButtonAction: () {},  
	hideNeutralButton: false,  
	closeOnBackPress: true,  
);
```

### Password Field Input Dialog

```
singleInputDialog(  
	context,  
	"Single Input Dialog",  
	DialogTextField(  
		fieldLabel: "Password Field",  
		obscureText: true,  
		textInputType: TextInputType.text,   
		validator: (value) {  
			if (value.isEmpty) return "Required!";  
			return null;  
		},  
		onEditingComplete: (value) {  
			print(value);  
		}  
	),  
	positiveButtonText: "Yes",  
	positiveButtonAction: (value) {  
		print(value);  
	},  
	negativeButtonText: "No",  
	negativeButtonAction: () {},  
	hideNeutralButton: false,  
	closeOnBackPress: true,  
);
```

### Multi Line Text Field Input Dialog

```
singleInputDialog(  
	context,  
	"Single Input Dialog",  
	DialogTextField(  
		fieldLabel: "Remarks",  
		textInputType: TextInputType.multiline,   
		minLines: 3,
		maxLines: 5,
		validator: (value) {  
			if (value.isEmpty) return "Required!";  
			return null;  
		},  
		onEditingComplete: (value) {  
			print(value);  
		}  
	),  
	positiveButtonText: "Yes",  
	positiveButtonAction: (value) {  
		print(value);  
	},  
	negativeButtonText: "No",  
	negativeButtonAction: () {},  
	hideNeutralButton: false,  
	closeOnBackPress: true,  
);
```

# Progress Dialog

### Circular Progress Dialog (Infinite)

```
progressDialog(  
	context,   
	titleWidget: Text("Connecting", style: dialogTitleStyle(context),),  
	progressDialogType: ProgressDialogType.CIRCULAR,  
	contentWidget: Text(  
		"Connecting to Server, Please wait, this will take some time...",  
		textAlign: TextAlign.justify,  
		style: dialogContentStyle(context),  
	),  
	positiveButtonText: "Yes",  
	positiveButtonAction: () {},  
	negativeButtonText: "No",  
	negativeButtonAction: () {},  
	hideNeutralButton: true,  
	closeOnBackPress: true,   
);
```

### Linear Progress Dialog (Infinite)

```
progressDialog(  
	context,   
	titleWidget: Text("Connecting", style: dialogTitleStyle(context),),  
	progressDialogType: ProgressDialogType.LINEAR,  
	contentWidget: Text(  
		"Connecting to Server, Please wait, this will take some time...",  
		textAlign: TextAlign.justify,  
		style: dialogContentStyle(context),  
	),  
	positiveButtonText: "Yes",  
	positiveButtonAction: () {},  
	negativeButtonText: "No",  
	negativeButtonAction: () {},  
	hideNeutralButton: true,  
	closeOnBackPress: true,   
);
```

# Progress Dialog With Value Update

### Setup for Progress Value Update

Add this to your **MyApp** build function

```
import 'package:provider/provider.dart';
```

```
MultiProvider(  
	providers: [  
		ChangeNotifierProvider(create: (context) => ProgressModel()),  
	]
	child: MaterialApp( ... ),
);
```

#### Like this
```
// MyApp class build function return like this
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
				home: MyHomePage(title: 'Fialogs Demo Home Page'),  
			),  
		);  
	}
}
```

#### Update Progress Value

Update progress model value from where you call the progress dialog function

```
updateProgress() async {  
	var model = context.read<ProgressModel>();  
	model.setValue(0.0);  
	for(var i = 0.00; i <= 1.00; i = i + 0.01) {  
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
```

### Progress Dialog Function should called from ChangeNotifierProvider

```
Scaffold(  
	appBar: AppBar(  
		title: Text(widget.title),  
	),  
	body: ChangeNotifierProvider(  
		create: (context) => ProgressModel(),
		child: Column(
			children: <Widget>[ ... ],
		),
	),
);
```


### Circular Progress Dialog

```
progressDialog(  
	context,  
	displayValue: true,  
	autoCloseOnCompletion: true,  
	titleWidget: Text("Connecting", style: dialogTitleStyle(context),),  
	progressDialogType: ProgressDialogType.CIRCULAR,  
	contentWidget: Text(  
		"Connecting to Server, Please wait, this will take some time...",  
		textAlign: TextAlign.justify,  
		style: dialogContentStyle(context),  
	),  
	positiveButtonText: "Yes",  
	positiveButtonAction: () {},  
	negativeButtonText: "No",  
	negativeButtonAction: () {},  
	hideNeutralButton: true,  
	closeOnBackPress: false,  
);  
updateProgress(); // this function defined above
```

### Linear Progress Dialog

```
progressDialog(  
	context,  
	displayValue: true,  
	autoCloseOnCompletion: true,  
	titleWidget: Text("Connecting", style: dialogTitleStyle(context),),  
	progressDialogType: ProgressDialogType.LINEAR,  
	contentWidget: Text(  
		"Connecting to Server, Please wait, this will take some time...",  
		textAlign: TextAlign.justify,  
		style: dialogContentStyle(context),  
	),  
	positiveButtonText: "Yes",  
	positiveButtonAction: () {},  
	negativeButtonText: "No",  
	negativeButtonAction: () {},  
	hideNeutralButton: true,  
	closeOnBackPress: false,  
);  
updateProgress(); // this function defined above
```

# Custom Dialog

```
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
	positiveButtonAction: () {},  
	negativeButtonText: "Not Okay",  
	negativeButtonAction: () {},  
	neutralButtonAction: () {  
	  Navigator.pop(context);  
	},  
	hideNeutralButton: true,  
	closeOnBackPress: true,  
);
```
