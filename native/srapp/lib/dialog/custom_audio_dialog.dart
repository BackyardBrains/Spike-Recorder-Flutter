import 'dart:math';

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

double log10(num x) => log(x) / ln10;
// double log10inv(double percentage) => percentage * ln10 / log(x);

Future showCustomAudioDialog(ctx, params) {
  TextEditingController controllerLowFilter = new TextEditingController();
  TextEditingController controllerHighFilter = new TextEditingController();
  controllerLowFilter.text = params["lowFilterValue"];
  controllerHighFilter.text = params["highFilterValue"];
  int sampleRate = int.parse(params["sampleRate"]);
  int halfSampleRate = (sampleRate / 2).floor();
  bool isNotch50 = params["isNotch50"];
  bool isNotch60 = params["isNotch60"];

  int flagChange = 0;

  double _lowerValue = double.parse(params["lowFilterValue"] as String);
  double _highValue = double.parse(params["highFilterValue"] as String);
  print("sampleRate : ");
  print(sampleRate);

  List<double> arrScaleIdx = [];
  List<double> arrScaleValues = [];

  double valueToSlider(val) {
    double maxLog = log10(halfSampleRate);
    double logNow = log10(val);
    return (logNow / maxLog) * halfSampleRate;
  }

  double sliderToValue(val) {
    return valueToSlider(val);
    // double percentageNow = val / halfSampleRate;
    // //log(x) = percentageNow
    // // x = 10 ^ percentageNow
    // num x = pow(10,percentageNow);

    // double maxLog = log10(halfSampleRate);
    // // double logNow = log10inv(val);
    // // print("(logNow/maxLog) * halfSampleRate");
    // // print(val);
    // // print(halfSampleRate);
    // // print(logNow);
    // // print(maxLog);
    // // print((logNow/maxLog) * halfSampleRate);
    // int convertedScaleIdx = (log(x)/maxLog).floor();
    // double result = 0;
    // // if (convertedScaleIdx<4){
    // //   ( arrScaleValues[convertedScaleIdx] + arrScaleValues[convertedScaleIdx+1] * halfSampleRate );
    // // }else{

    // // }
    // print("result");
    // print(result);
    // print(maxLog);
    // return result;
  }

  double translateSliderPosition(val) {
    double result = val;
    if (arrScaleValues.length == 0) return result;

    for (int idx = 0; idx < arrScaleValues.length - 1; idx++) {
      // if (val in [ arrScaleValues[idx] , arrScaleValues[idx+1] ] ){
      if (val >= arrScaleValues[idx] && val < arrScaleValues[idx + 1]) {
        double scaleDifference = arrScaleValues[idx + 1] - arrScaleValues[idx];
        double sliderPositionCapped = val - arrScaleValues[idx];
        double percentangeSliderPositionCapped =
            sliderPositionCapped / scaleDifference;
        //[0.0, 0.0, 5076.658003452795, 10153.31600690559, 15229.974010358383, 20306.63201381118, 22050.0]
        print("arrScaleValues[idx] " + idx.toString());
        print(arrScaleValues[idx]);
        print(arrScaleValues[idx + 1]);
        print(val);
        // print(valueToSlider(val));

        double scaleLabelDifference = arrScaleIdx[idx + 1] - arrScaleIdx[idx];
        double sliderPositionTranslated =
            percentangeSliderPositionCapped * scaleLabelDifference;
        print("scaleLabelDifference[idx] " + idx.toString());
        print(arrScaleIdx[idx]);
        print(arrScaleIdx[idx + 1]);
        print(percentangeSliderPositionCapped);

        result = sliderToValue(arrScaleValues[idx] + sliderPositionTranslated);
        print("result");
        print(result);

        return result;
      }
    }
    return result;
  }

  List<double> initialSliderValue = [_lowerValue, _highValue];

  void textListener() {
    if (flagChange < 0) {
      flagChange++;
      return;
    }
    double tempLowerValue = _lowerValue;
    double tempHighValue = _highValue;
    try {
      _lowerValue = int.tryParse(controllerLowFilter.text)!.toDouble();
    } catch (err) {
      print("err");
      print(err);
      _lowerValue = 0;
      controllerLowFilter.text = tempLowerValue.floor().toString();
    }

    try {
      _highValue = int.tryParse(controllerHighFilter.text)!.toDouble();
    } catch (err) {
      print("err");
      print(err);
      _highValue = 0;
      controllerHighFilter.text = tempHighValue.floor().toString();
    }

    if (_lowerValue > sampleRate) {
      _lowerValue = sampleRate.toDouble();
      controllerLowFilter.text = halfSampleRate.toString();
    } else if (_lowerValue < 0) {
      _lowerValue = 0;
      controllerLowFilter.text = "0";
    }

    if (_highValue > sampleRate) {
      _highValue = sampleRate.toDouble();
      controllerHighFilter.text = halfSampleRate.toString();
    } else if (_highValue < 0) {
      _highValue = 0;
      controllerHighFilter.text = "0";
    }

    if (_highValue < _lowerValue) {
      _highValue = halfSampleRate.toDouble();
      _lowerValue = 0;
    }

    params["lowFilterValue"] = _lowerValue.floor().toString();
    params["highFilterValue"] = _highValue.floor().toString();
    // double logLowerValue = valueToSlider(_lowerValue);
    // initialSliderValue=[ logLowerValue<=0?0:logLowerValue, valueToSlider(_highValue) ];
    double logLowerValue = (_lowerValue);
    initialSliderValue = [logLowerValue <= 0 ? 0 : logLowerValue, (_highValue)];
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
        List<FlutterSliderRangeStep> sliderRangeSteps = [];
        double maxLog = log10(halfSampleRate);
        int exponentialStep = (maxLog).floor();

        print("exponentialStep");
        print(exponentialStep);

        List<FlutterSliderHatchMarkLabel> hatchmarks = [
          FlutterSliderHatchMarkLabel(
            percent: 0,
            label: Text('0', style: TextStyle(fontSize: 10)),
          ),
          // FlutterSliderHatchMarkLabel(percent: 10/halfSampleRate*100, label: Text('10', style:TextStyle(fontSize: 10)),),
          // FlutterSliderHatchMarkLabel(percent: 100/halfSampleRate*100, label: Text('100', style:TextStyle(fontSize: 10) )),
          FlutterSliderHatchMarkLabel(
              percent: 1000 / halfSampleRate * 100,
              label: Text('1000', style: TextStyle(fontSize: 10))),
          FlutterSliderHatchMarkLabel(
              percent: 10000 / halfSampleRate * 100,
              label: Text('10000', style: TextStyle(fontSize: 10))),
          FlutterSliderHatchMarkLabel(
              percent: 100,
              label: Text(halfSampleRate.toString(),
                  style: TextStyle(fontSize: 10))),
        ];

        double prevNow = 0;
        hatchmarks = [
          // FlutterSliderHatchMarkLabel(percent: 0/halfSampleRate*100, label:Text("0",style:TextStyle(fontSize:10)))
        ];
        arrScaleIdx = [];
        arrScaleValues = [];

        arrScaleIdx.add(0);
        arrScaleValues.add(0);
        for (int idx = 0; idx <= exponentialStep; idx++) {
          num labelNow = pow(10, idx);
          double logNow = log10(labelNow);
          double toNow = (logNow / maxLog);
          if (idx == 0) {
            hatchmarks.add(FlutterSliderHatchMarkLabel(
                percent: 1 / halfSampleRate * 100,
                label:
                    Text(labelNow.toString(), style: TextStyle(fontSize: 10))));
            double myStep = toNow * halfSampleRate;
            print("myStep0");
            print(myStep);
            // sliderRangeSteps.add(
            //   FlutterSliderRangeStep(from:0, to: toNow, step:myStep>10?10:myStep.floorToDouble())
            // );
            arrScaleIdx.add(labelNow.toDouble());
            arrScaleValues.add(0.0 * halfSampleRate);
          } else {
            hatchmarks.add(FlutterSliderHatchMarkLabel(
                percent: toNow * 100,
                label:
                    Text(labelNow.toString(), style: TextStyle(fontSize: 10))));

            double myStep = (toNow - prevNow) * halfSampleRate;
            print("myStep");
            print(myStep);
            // sliderRangeSteps.add(
            //   FlutterSliderRangeStep(from:prevNow, to: toNow, step:myStep>10?10:myStep.floorToDouble())
            // );
            arrScaleIdx.add(labelNow.toDouble());
            arrScaleValues.add(toNow * halfSampleRate);
          }
          // arrScaleValues.add( halfSampleRate.toDouble() );
          print("labelNow");
          print(labelNow);
          print(toNow);
          prevNow = toNow;
        }
        arrScaleValues.add(halfSampleRate.toDouble());

        print("arrScaleValues");
        print(arrScaleValues);

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
                    Expanded(flex: 2, child: Text("Low")),
                    Expanded(flex: 6, child: Container()),
                    Expanded(flex: 2, child: Text("High"))
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: TextField(
                          controller: controllerLowFilter,
                          onChanged: (str) {
                            params["controllerLowFilter"] = str;
                            setState(() {});
                          },
                        )),
                    Expanded(
                      flex: 6,
                      child: Center(
                          child:
                              Text("Set band-pass filter cutoff frequencies")),
                    ),
                    Expanded(
                        flex: 2,
                        child: TextField(
                          controller: controllerHighFilter,
                          onChanged: (str) {
                            params["controllerHighFilter"] = str;
                            setState(() {});
                          },
                        ))
                  ],
                ),

                //SLIDER
                Container(
                  height: 100,
                  child: FlutterSlider(
                    rangeSlider: true,
                    values: initialSliderValue,
                    max: sampleRate / 2,
                    min: 0,
                    minimumDistance: 0,
                    step: FlutterSliderStep(
                      step: 1, // default
                      isPercentRange:
                          true, // ranges are percents, 0% to 20% and so on... . default is true
                      rangeList: sliderRangeSteps,
                    ),
                    tooltip: FlutterSliderTooltip(
                        textStyle:
                            TextStyle(fontSize: 17, color: Colors.transparent),
                        boxStyle: FlutterSliderTooltipBox(
                            decoration:
                                BoxDecoration(color: Colors.transparent))),
                    trackBar: FlutterSliderTrackBar(
                      inactiveTrackBar: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black12,
                        border: Border.all(width: 3, color: Colors.green),
                      ),
                      activeTrackBar: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.green.withOpacity(0.5)),
                    ),
                    handler: FlutterSliderHandler(
                      child: Icon(
                        Icons.view_headline,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                    rightHandler: FlutterSliderHandler(
                      child: Icon(
                        Icons.view_headline,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                    handlerAnimation: FlutterSliderHandlerAnimation(
                        curve: Curves.elasticOut,
                        reverseCurve: Curves.bounceIn,
                        duration: Duration(milliseconds: 500),
                        scale: 1.5),
                    hatchMark: FlutterSliderHatchMark(
                      labelsDistanceFromTrackBar: 50,
                      density: 1, // means 50 lines, from 0 to 100 percent
                      smallDensity: 4,
                      displayLines: false,
                      labels: hatchmarks,
                    ),
                    onDragging: (handlerIndex, lowerValue, upperValue) {
                      // _lowerValue = (translateSliderPosition(lowerValue));
                      // _highValue = (translateSliderPosition(upperValue));
                      _lowerValue = lowerValue;
                      _highValue = upperValue;
                      // print("_lowerValue");
                      // print(_lowerValue);
                      // print(_highValue);
                      // if(handlerIndex == 0)
                      //     print(" Left handler ");

                      params["lowFilterValue"] = _lowerValue.floor().toString();
                      params["highFilterValue"] = _highValue.floor().toString();
                      // flagChange = -2;

                      controllerHighFilter.text = _highValue.floor().toString();
                      controllerLowFilter.text = _lowerValue.floor().toString();

                      // setState(() {});
                    },
                  ),
                ),

                // Notch FILTER
                Container(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("Attenuate frequency (notch filter): "),
                    Container(
                      child: Row(children: [
                        Checkbox(
                          checkColor: Colors.white,
                          // fillColor: MaterialStateProperty.resolveWith(getColor),

                          value: isNotch50,
                          onChanged: (bool? value) {
                            setState(() {
                              isNotch50 = value!;
                              params['isNotch50'] = isNotch50;
                            });
                          },
                        ),
                        Text("50Hz")
                      ]),
                    ),
                    Container(
                      child: Row(children: [
                        Checkbox(
                          checkColor: Colors.white,
                          // fillColor: MaterialStateProperty.resolveWith(getColor),
                          value: isNotch60,
                          onChanged: (bool? value) {
                            setState(() {
                              isNotch60 = value!;
                              params['isNotch60'] = isNotch60;
                            });
                          },
                        ),
                        Text("60Hz")
                      ]),
                    ),
                  ],
                )),

                // Row(
                //   children: [
                //     Text("Attenuate frequency (Notch Filter)"),
                //     Text("50Hz"),
                //     Checkbox(
                //         value: params["notchFilter50"],
                //         onChanged: (flag) {
                //           params["notchFilter50"] = !params["notchFilter50"];
                //           setState(() {});
                //         }),
                //     Text("60Hz"),
                //     Checkbox(
                //         value: params["notchFilter60"],
                //         onChanged: (flag) {
                //           params["notchFilter60"] = !params["notchFilter60"];
                //           setState(() {});
                //         }),
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
                Text("version 1.3.1"),

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
