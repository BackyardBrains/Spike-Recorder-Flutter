import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

List<DropdownMenuItem<double>> getStrokeWidth(params) {
  print("getStrokeWidth");
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

  return showDialog(
    barrierDismissible: false,
    context: ctx,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        // title: Text('Orders'),
        content: SizedBox(
          width: double.maxFinite, //  <------- Use SizedBox to limit width
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () {
                    // Navigator.pop(context);
                    Navigator.of(context).pop(params);
                  },
                  child: const Icon(Icons.close),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                      onTap: () {
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

              // Row(
              //   children: [
              //     Expanded(
              //       flex:2,
              //       child:Text("Low")
              //     ),
              //     Expanded(
              //       flex:6,
              //       child:Container()
              //     ),
              //     Expanded(
              //       flex:2,
              //       child:Text("High")
              //     )
              //   ],
              // ),

              // Row(
              //   children: [
              //     Expanded(
              //       flex:2,
              //       child:TextField(
              //         controller: controllerLowFilter,
              //         onChanged: (str){
              //           params["controllerLowFilter"] = str;
              //           setState((){});

              //         },
              //       )
              //     ),
              //     Expanded(
              //       flex:6,
              //       child:Text("Set band-pass filter cutoff frequencies"),
              //     ),
              //     Expanded(
              //       flex:2,
              //       child:TextField(
              //         controller: controllerHighFilter,
              //         onChanged: (str){
              //           params["controllerHighFilter"] = str;
              //           setState((){});

              //         },
              //       )
              //     )
              //   ],
              // ),

              //SLIDER

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
      ),
    ),
  );
}
