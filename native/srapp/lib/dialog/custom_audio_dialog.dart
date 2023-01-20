import 'package:another_xlider/another_xlider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

List<DropdownMenuItem<double>> getStrokeWidth(params) {
  // print("getStrokeWidth");
  List<double> options =
      params["strokeOptions"]; //.map<double>((val) => val as double).toList();
  return options.map((option) {
    return DropdownMenuItem<double>(
      value: option,
      child: Text(option.toString()),
    );
  }).toList();
}

List<DropdownMenuItem<int>> getColorDropDown() {
  // List<Color> colors = [Colors.black, Color(0xFF10ff00), Color(0xFFff0035), Color(0xFFe1ff4b), Color(0xFFff8755), Color(0xFF6bf063),Color(0xFF00c0c9),];
  List<Color> colors = [
    Color(0xFF10ff00),
    Color(0xFFff0035),
    Color(0xFFe1ff4b),
    Color(0xFFff8755),
    Color(0xFF6bf063),
    Color(0xFF00c0c9),
  ];
  int idx = 0;
  return colors.map((color) {
    return DropdownMenuItem<int>(
      value: idx++,
      child: Container(
        width: 100,
        height: 10,
        color: color,
      ),
    );
  }).toList();
}

Future showCustomAudioDialog(ctx, params) {
  TextEditingController controllerLowFilter = new TextEditingController();
  TextEditingController controllerHighFilter = new TextEditingController();
  controllerLowFilter.text = params["lowFilterValue"];
  controllerHighFilter.text = params["highFilterValue"];
  int sampleRate = int.parse(params["sampleRate"]);
  int halfSampleRate = (sampleRate/2).floor();

  double _lowerValue = double.parse(params["lowFilterValue"] as String);
  double _highValue = double.parse(params["highFilterValue"] as String);
  print("sampleRate : ");
  print(sampleRate);

  List<double> initialSliderValue = [_lowerValue, _highValue];

  void textListener(){
    double tempLowerValue = _lowerValue;
    double tempHighValue = _highValue;
    try{
      _lowerValue = int.tryParse(controllerLowFilter.text)!.toDouble();
    }catch(err){
      print("err");
      print(err);
      _lowerValue = 0;
      controllerLowFilter.text = tempLowerValue.floor().toString();
    }

    try{
      _highValue = int.tryParse(controllerHighFilter.text)!.toDouble();
    }catch(err){
      print("err");
      print(err);
      _highValue = 0;
      controllerHighFilter.text = tempHighValue.floor().toString();
    }


    if (_lowerValue>sampleRate){
      _lowerValue = sampleRate.toDouble();
      controllerLowFilter.text = halfSampleRate.toString();
    }else
    if (_lowerValue<0){
      _lowerValue = 0;
      controllerLowFilter.text = "0";
    }

    if (_highValue>sampleRate){
      _highValue = sampleRate.toDouble();
      controllerHighFilter.text = halfSampleRate.toString();
    }else
    if (_highValue<0){
      _highValue = 0;
      controllerHighFilter.text = "0";
    }


    if (_highValue < _lowerValue){
      _highValue = halfSampleRate.toDouble();
      _lowerValue = 0;
    }

    params["lowFilterValue"] = _lowerValue.floor().toString();
    params["highFilterValue"] = _highValue.floor().toString();
    initialSliderValue=[_lowerValue, _highValue];
    
  }


  return showDialog(
    barrierDismissible: false,
    context: ctx,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        controllerHighFilter.removeListener(textListener);
        controllerLowFilter.removeListener(textListener);        

        controllerHighFilter.addListener(textListener);
        controllerLowFilter.addListener(textListener);        
        return AlertDialog(
        // title: Text('Orders'),
          content: SizedBox(
            width: double.maxFinite, //  <------- Use SizedBox to limit width
            child: ListView(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      // Navigator.pop(context);
                      controllerLowFilter.dispose();
                      controllerHighFilter.dispose();
                      Navigator.of(context).pop(params);
                    },
                    child: const Icon(Icons.close),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                        onTap: () {
                          controllerLowFilter.dispose();
                          controllerHighFilter.dispose();
                          Navigator.of(context).pop(params);
                        },
                        child: Icon(Icons.settings, size: 50)),
                    Text("Config"),
                  ],
                ),
                SizedBox(
                  height: 30,
                ),

                // Row(
                //   children: [
                //     Text("Mute Speakers"),
                //     Checkbox(
                //       value: params["muteSpeakers"],
                //       onChanged: (flag){
                //           params["muteSpeakers"] = params["muteSpeakers"];
                //           setState((){});

                //       }
                //     ),
                //   ],
                // ),

                SizedBox(
                  height: 30,
                ),

                Row(
                  children: [
                    Expanded(
                      flex:2,
                      child:Text("Low")
                    ),
                    Expanded(
                      flex:6,
                      child:Container()
                    ),
                    Expanded(
                      flex:2,
                      child:Text("High")
                    )
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      flex:2,
                      child:TextField(
                        controller: controllerLowFilter,
                        onChanged: (str){
                          params["controllerLowFilter"] = str;
                          setState((){});

                        },
                      )
                    ),
                    Expanded(
                      flex:6,
                      child:Center(child: Text("Set band-pass filter cutoff frequencies")),
                    ),
                    Expanded(
                      flex:2,
                      child:TextField(
                        controller: controllerHighFilter,
                        onChanged: (str){
                          params["controllerHighFilter"] = str;
                          setState((){});

                        },
                      )
                    )
                  ],
                ),

                //SLIDER
                Container(
                  height:100,
                  child: FlutterSlider(
                    rangeSlider: true,
                    values: initialSliderValue,
                    max:sampleRate/2,
                    min:0,
                    minimumDistance:0,

                    tooltip: FlutterSliderTooltip(
                      textStyle: TextStyle(fontSize: 17, color: Colors.transparent),
                      boxStyle: FlutterSliderTooltipBox(
                        decoration: BoxDecoration(
                          color: Colors.transparent
                        )
                      )
                    ),

                    trackBar: FlutterSliderTrackBar(
                      inactiveTrackBar: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black12,
                        border: Border.all(width: 3, color: Colors.green),
                      ),
                      activeTrackBar: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.green.withOpacity(0.5)
                      ),
                    ),                    
                    handler: FlutterSliderHandler(
                      child: Icon(Icons.view_headline, color: Colors.black, size: 24,),
                    ),                    
                    rightHandler: FlutterSliderHandler(
                      child: Icon(Icons.view_headline, color: Colors.black, size: 24,),
                    ),                    
                    handlerAnimation: FlutterSliderHandlerAnimation(
                      curve: Curves.elasticOut,
                      reverseCurve: Curves.bounceIn,
                      duration: Duration(milliseconds: 500),
                      scale: 1.5
                    ),                    
                    hatchMark: FlutterSliderHatchMark(
                      labelsDistanceFromTrackBar:50,
                      density: 1, // means 50 lines, from 0 to 100 percent
                      smallDensity:4,
                      displayLines: true,
                      labels: [
                        FlutterSliderHatchMarkLabel(percent: 0, label: Text('0', style:TextStyle(fontSize: 10)),),
                        // FlutterSliderHatchMarkLabel(percent: 10/halfSampleRate*100, label: Text('10', style:TextStyle(fontSize: 10)),),
                        // FlutterSliderHatchMarkLabel(percent: 100/halfSampleRate*100, label: Text('100', style:TextStyle(fontSize: 10) )),
                        FlutterSliderHatchMarkLabel(percent: 1000/halfSampleRate*100, label: Text('1000', style:TextStyle(fontSize: 10) )),
                        FlutterSliderHatchMarkLabel(percent: 10000/halfSampleRate*100, label: Text('10000', style:TextStyle(fontSize: 10) )),
                        FlutterSliderHatchMarkLabel(percent: 100, label: Text(halfSampleRate.toString(), style:TextStyle(fontSize: 10) )),
                      ],
                    ),

                    onDragging: (handlerIndex, lowerValue, upperValue) {
                      _lowerValue = lowerValue;
                      _highValue = upperValue;
                      // if(handlerIndex == 0)
                      //     print(" Left handler ");

                      params["lowFilterValue"] = _lowerValue.floor().toString();
                      params["highFilterValue"] = _highValue.floor().toString();

                      controllerHighFilter.text = _highValue.floor().toString();
                      controllerLowFilter.text = _lowerValue.floor().toString();

                      // setState(() {});
                    },                  
                  ),
                ),

                // Row(
                //   children: [
                //     Text("Attenuate frequency (Notch Filter)"),
                //     Text("50Hz"),
                //     Checkbox(
                //       value: params["notchFilter50"],
                //       onChanged: (flag){
                //         params["notchFilter50"] = !params["notchFilter50"];
                //         setState((){});
                //       }
                //     ),
                //     Text("60Hz"),
                //     Checkbox(
                //       value: params["notchFilter60"],
                //       onChanged: (flag){
                //         params["notchFilter60"] = !params["notchFilter60"];
                //         setState((){});
                //       }
                //     ),
                //   ],
                // ),

                Row(children: [
                  const Text("Stroke Width : "),
                  DropdownButton<double>(
                    value: params["strokeWidth"],
                    items: getStrokeWidth(params),
                    onChanged: (width) {
                      params["strokeWidth"] = width;
                      setState(() {});
                    },
                  ),
                ]),

                Row(
                  children: [
                    DropdownButton<int>(
                      value: params["defaultMicrophoneLeftColor"],
                      onChanged: (d) {
                        params["defaultMicrophoneLeftColor"] = d;
                        setState(() {});
                      },
                      items: getColorDropDown(),
                    ),
                    params["maxAudioChannels"] == 1
                        ? Text("Default Microphone")
                        : Text("Default Microphone [Left]")
                  ],
                ),

                params["maxAudioChannels"] == 1
                    ? Container()
                    : Row(
                        children: [
                          DropdownButton<int>(
                            value: params["defaultMicrophoneRightColor"],
                            onChanged: (d) {
                              params["defaultMicrophoneRightColor"] = d;
                              setState(() {});
                            },
                            items: getColorDropDown(),
                          ),
                          Text("Default Microphone [Right]")
                        ],
                      ),

                !kIsWeb
                    ? Container()
                    : Row(
                        children: [
                          const Text(
                              "Enable Legacy USB - Neuron Pro, Muscle Pro (Pre-2023) "),
                          Checkbox(
                              value: params['enableDeviceLegacy'],
                              onChanged: (flag) {
                                params['enableDeviceLegacy'] = flag;
                                setState(() {});
                                Navigator.of(context).pop(params);
                              })

                          // Text("Legacy Device "),
                          // ElevatedButton(
                          //   onPressed: (){
                          //     params['enableDeviceLegacy'] = true;
                          //     Navigator.of(context).pop( params );
                          //   },
                          //   child: Text("Enable")
                          // ),
                        ],
                      ),

                SizedBox(
                  height: 70,
                ),
                Text("version 1.2.1"),

                // Text("Select Port"),
                // Row(
                //   children: [
                //     DropdownButton<String>(
                //       onChanged: (d) {},
                //       items: [
                //         DropdownMenuItem(
                //           child:Text("No detected ports"),
                //         ),
                //       ],
                //     ),
                //     ElevatedButton(
                //       child: Text("Connect"),
                //       onPressed: (){

                //       },
                //     )

                //   ],
                // ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
