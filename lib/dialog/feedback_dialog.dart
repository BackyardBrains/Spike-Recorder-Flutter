
import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:http/http.dart' as https;



  bool autoValidate = true;
  bool readOnly = false;
  bool showSegmentedControl = true;
  bool _ageHasError = false;
  bool _genderHasError = false;
  bool isFeedback = false;
  String errorMessage = "";
  final _formKey = GlobalKey<FormBuilderState>();

  void sendFeedbackForm(mapValue) async {
    var url = Uri.parse('https://staging-bybrain.web.app/feedback');
    var response = await https.post(url, body: mapValue);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');  
  }

  Widget getFeedbackWidget(setState){

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormBuilder(
        key: _formKey,
        // enabled: false,
        onChanged: () {
          // _formKey.currentState!.save();
          // debugPrint(_formKey.currentState!.value.toString());
        },
        autovalidateMode: AutovalidateMode.disabled,
        // initialValue: const {
        // },
        skipDisabled: true,
        child: Column(
          children: [
            FormBuilderTextField(
              autovalidateMode: AutovalidateMode.always,
              name: 'Feedback description',
              decoration: InputDecoration(
                labelText: 'Feedback Description',
                suffixIcon: _ageHasError
                    ? const Icon(Icons.error, color: Colors.red)
                    : const Icon(Icons.check, color: Colors.green),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
              // initialValue: '12',
              textInputAction: TextInputAction.next,
            ),          
            FormBuilderTextField(
              autovalidateMode: AutovalidateMode.always,
              name: 'Chrome Version',
              decoration: InputDecoration(
                labelText: 'Chrome Version',
                suffixIcon: _ageHasError
                    ? const Icon(Icons.error, color: Colors.red)
                    : const Icon(Icons.check, color: Colors.green),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
              // initialValue: '12',
              textInputAction: TextInputAction.next,
            ),          
            FormBuilderTextField(
              autovalidateMode: AutovalidateMode.always,
              name: 'Name',
              decoration: InputDecoration(
                labelText: 'Name',
                suffixIcon: _ageHasError
                    ? const Icon(Icons.error, color: Colors.red)
                    : const Icon(Icons.check, color: Colors.green),
              ),
              validator: FormBuilderValidators.compose([
              ]),
              // initialValue: '12',
              textInputAction: TextInputAction.next,
            ),          

            FormBuilderTextField(
              autovalidateMode: AutovalidateMode.always,
              name: 'Email',
              decoration: InputDecoration(
                labelText: 'Email address',
                suffixIcon: _ageHasError
                    ? const Icon(Icons.error, color: Colors.red)
                    : const Icon(Icons.check, color: Colors.green),
              ),
              // valueTransformer: (text) => num.tryParse(text),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.email(errorText : "Please put correct email"),
              ]),
              // initialValue: '12',
              textInputAction: TextInputAction.next,
            ), 

            Text(errorMessage),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      isFeedback = false;
                      setState((){});
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red, // background
                      onPrimary: Colors.white, // foreground
                    ),                  
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),            
                SizedBox(width:30),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.saveAndValidate() ?? false) {
                        debugPrint(_formKey.currentState?.value.toString());
                        errorMessage = "";
                        sendFeedbackForm(_formKey.currentState?.value);
                      } else {
                        debugPrint(_formKey.currentState?.value.toString());
                        errorMessage = "Validation failed";
                      }
                      setState((){});
                    },
                    child: const Text(
                      'Submit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ]
            ),
          ],
        )
      ),
    );    
  }

Future showFeedbackDialog(ctx, params){
  return showDialog(
    context: ctx,
    builder: (context) => StatefulBuilder(
      builder: (context,setState) => AlertDialog(
      // builder: (context) => AlertDialog(
        // title: Text('Orders'),
        content: SizedBox(
          width: double.maxFinite,  //  <------- Use SizedBox to limit width
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: getFeedbackWidget(setState),
          ),
        ),
      ),
    ),
  );  
}
