import 'package:flutter/material.dart';

List<DropdownMenuItem<double>> getStrokeWidth(params) {
  List<double> options = params["strokeOptions"];
  return options.map((option) {
    return DropdownMenuItem<double>(
      value: option,
      child: Text(option.toString()),
    );
  }).toList();
}

List<DropdownMenuItem<int>> getChannels(params) {
  int maxSerialChannels = params["maxSerialChannels"] as int;
  int minSerialChannels = params["minSerialChannels"] as int;
  List<int> channels = List<int>.generate(
      maxSerialChannels - minSerialChannels + 1, (index) => 0);
  print(maxSerialChannels.toString() + " @@@@ " + minSerialChannels.toString());

  for (int i = 0; i <= maxSerialChannels - minSerialChannels; i++) {
    channels[i] = i + minSerialChannels;
  }
  return channels.map((channel) {
    return DropdownMenuItem<int>(
      value: channel,
      child: Text(channel.toString()),
    );
  }).toList();
}

List<DropdownMenuItem<int>> getColorDropDown() {
  // List<Color> colors = [Colors.black, Color(0xFF1ed400), Color(0xFFffff00), Color(0xFF20b4aa), Color(0xFFdc0000), Color(0xFFdcdcdc),Color(0xFFff3800),];
  // List<Color> colors = [Color(0xFF1ed400), Color(0xFFffff00), Color(0xFF20b4aa), Color(0xFFdc0000), Color(0xFFdcdcdc),Color(0xFFff3800),];
  List<Color> colors = [
    Color(0xFF1ed400),
    Color(0xFFff0035),
    Color(0xFFffff00),
    Color(0xFF20b4aa),
    Color(0xFFdcdcdc),
    Color(0xFFff3800),
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

Future showCustomSerialDialog(ctx, params) {
  TextEditingController controllerLowFilter = new TextEditingController();
  TextEditingController controllerHighFilter = new TextEditingController();
  controllerLowFilter.text = params["lowFilterValue"];
  controllerHighFilter.text = params["highFilterValue"];

  return showDialog(
    barrierDismissible: false,
    context: ctx,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        // title: Text('Serial'),
        content: SizedBox(
          width: double.maxFinite, //  <------- Use SizedBox to limit width
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
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
                      value: params["defaultSerialColor1"],
                      onChanged: (d) {
                        params["defaultSerialColor1"] = d;
                        setState(() {});
                      },
                      items: getColorDropDown(),
                    ),
                    Text("Channel 1")
                  ],
                ),

                if (params["channelCount"] >= 2) ...{
                  Row(
                    children: [
                      DropdownButton<int>(
                        value: params["defaultSerialColor2"],
                        onChanged: (d) {
                          params["defaultSerialColor2"] = d;
                          setState(() {});
                        },
                        items: getColorDropDown(),
                      ),
                      Text("Channel 2")
                    ],
                  ),
                },

                if (params["channelCount"] >= 3) ...{
                  Row(
                    children: [
                      DropdownButton<int>(
                        value: params["defaultSerialColor3"],
                        onChanged: (d) {
                          params["defaultSerialColor3"] = d;
                          setState(() {});
                        },
                        items: getColorDropDown(),
                      ),
                      Text("Channel 3")
                    ],
                  ),
                },

                if (params["channelCount"] >= 4) ...{
                  Row(
                    children: [
                      DropdownButton<int>(
                        value: params["defaultSerialColor4"],
                        onChanged: (d) {
                          params["defaultSerialColor4"] = d;
                          setState(() {});
                        },
                        items: getColorDropDown(),
                      ),
                      Text("Channel 4")
                    ],
                  ),
                },

                if (params["channelCount"] >= 5) ...{
                  Row(
                    children: [
                      DropdownButton<int>(
                        value: params["defaultSerialColor5"],
                        onChanged: (d) {
                          params["defaultSerialColor5"] = d;
                          setState(() {});
                        },
                        items: getColorDropDown(),
                      ),
                      Text("Channel 5")
                    ],
                  ),
                },

                if (params["channelCount"] >= 6) ...{
                  Row(
                    children: [
                      DropdownButton<int>(
                        value: params["defaultSerialColor6"],
                        onChanged: (d) {
                          params["defaultSerialColor6"] = d;
                          setState(() {});
                        },
                        items: getColorDropDown(),
                      ),
                      Text("Channel 6")
                    ],
                  ),
                },

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

                if (params['displayChannelCount'] != null) ...{
                  Row(
                    children: [
                      Text("Channel Count :"),
                      DropdownButton<int>(
                        value: params["channelCount"],
                        onChanged: (d) {
                          params["channelCount"] = d;
                          int channel = d as int;
                          for (int i = 0; i < channel; i++) {
                            params["flagDisplay" + (i + 1).toString()] = 1;
                          }
                          setState(() {});
                        },
                        items: getChannels(params),
                      ),
                    ],
                  ),
                },

                Row(
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
                    // ElevatedButton(
                    //   onPressed: (){
                    //     params['enableDeviceLegacy'] = true;
                    //     Navigator.of(context).pop( params );
                    //   },
                    //   child: Text("Enable")
                    // ),
                  ],
                ),

                // if (params['deviceType']=='hid')...{
                //   Row(
                //     children: [
                //       Text("Update Firmware "),
                //       ElevatedButton(
                //         onPressed: (){
                //           params['deviceType'] = 'hid';
                //           params['commandType'] = 'update';
                //           Navigator.of(context).pop( params );
                //         },
                //         child: Text("Connect")
                //       ),

                //     ],
                //   ),
                // }
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
