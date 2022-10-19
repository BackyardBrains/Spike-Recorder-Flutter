import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:count_stepper/count_stepper.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fialogs/fialogs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flash/flash.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart' as WavForm;
import 'package:localstorage/localstorage.dart';
import 'package:micsound/mainoldbloc/mainold_bloc.dart';
import 'package:micsound/ui/dialog/custom_audio_dialog.dart';
import 'package:micsound/ui/dialog/custom_serial_dialog.dart';
import 'package:micsound/ui/dialog/feedback_dialog.dart';
import 'package:micsound/ui/widgets/canvas_scroll_behavior.dart';
import 'package:micsound/utils/debouncers.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'core/models/wav_parser.dart';
import 'core/models/waveform_data_model.dart';
import 'firebase_config.dart';
import 'jsfunction.dart';
import 'dart:js' as js;
import 'dart:typed_data';
// import 'package:flutter_fps/flutter_fps.dart';
// import 'package:fps_widget/fps_widget.dart';

import 'ui/widgets/waveform_painter.dart';
import 'workers/sample_service.dart';
// import 'src/c_strings.dart';
// import 'src/proxy_ffi.dart';
// import 'src/generated.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:http/http.dart' as https;

// 10s - 27 seconds delay

const String _basePath = 'assets';
final LocalStorage storage = new LocalStorage('tutorial_app');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseConfig.platformOptions);
  // await initFfi();
  // DynamicLibrary dynLib = openOpus();
  // FunctionsAndGlobals opusLibinfo = FunctionsAndGlobals(dynLib);
  // String version = fromCString(opusLibinfo.opus_get_version_string());
  // print("VERSION "+version.toString());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
      

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // showPerformanceOverlay: true,
      title: 'Spike Recorder for Web',
      localizationsDelegates: const [
        FormBuilderLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: FormBuilderLocalizations.delegate.supportedLocales,

      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Spike Recorder for Web'),

      // home: const FPSWidget(
      //   child: MyHomePage(title: 'Spike Recorder for Web')
      // ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);
  Future<void> _sendAnalyticsEvent(eventName, params) async {
    await analytics.logEvent(
      name: eventName,
      parameters : params,
      // parameters: <String, dynamic>{
      //   'string': 'string',
      //   'int': 42,
      //   'long': 12345678910,
      //   'double': 42.0,
      //   // Only strings and numbers (ints & doubles) are supported for GA custom event parameters:
      //   // https://developers.google.com/analytics/devguides/collection/analyticsjs/custom-dims-mets#overview
      //   'bool': true.toString(),
      //   'items': [itemCreator()]
      // },
    );
  }


  String versionNumber = '1.2.1';
  int isOpeningFile = 0;
  int _counter = 0;

  int extraChannels = 0;
  int minChannels = 0;
  int maxChannels = 0;

  int localChannel = 1;

  double prevY = 0.0;

  List<double> channelGains=[10000,10000,10000,10000,10000,10000];
  
  int minIndexSerial = 1;
  int maxIndexSerial = 25;

  int minIndexHid = 1;
  int maxIndexHid = 15;

  int minIndexAudio = 1;
  int maxIndexAudio = 20;

  List<double> listIndexSerial=[5,5,5,5,5,5];
  List<double> listIndexHid = [7,7,7,7,7,7];
  List<double> listIndexAudio = [9,9];

  List<double> listChannelSerial = [500,600,700,800,900,1000,1100,1200,1300,1400,1500,1600,1700,1800,1900,2000,  4000,8000,12000,16000,20000,  25000,30000,40000,80000,200000 ];
  List<double> listChannelHid = [0.5,0.75,1,5,20,70,250,500,550,600,650,700, 800,900,1000];
  List<double> listChannelAudio = [100,300,700,1000,2000,6000,7000,8000,9000,10000,   11000, 14000,20000,22000,30000,33000,40000,47000,55000,70000];
  
  List<double> levelMedian=[-1,-1,-1,-1,-1,-1];
  List<double> initialLevelMedian=[0,0,0 ,0,0,0];

  List<double> chartData=[];
  List<List<double>> channelsData = [];

  var horizontalDiff = 0;

  num timeScale = 10000; //10ms to 10 seconds
  num curTimeScaleBar = 1000; //10ms to 10 seconds
  num curSkipCounts = 256;
  num curFps = 30;
  int sampleRate = 44100;
  List<double> arrDataMax = []; //10 seconds
  List<double>arrData = [];// current

  int capacity = 1;
  int capacityMin = 1;
  int capacityMax = 1;

  int isPlaying = 0;
  int isRecording = 0;
  int deviceType = 0; // 0 - audio | 1 - serial

  DateTime startRecordingTime = DateTime.now();
  DateTime currentRecordingTime = DateTime.now();
  Duration duration = Duration(hours: 0);
  String labelDuration = "";

  double startPosition = 1.0;
  double zoomLevel = 1.0;

  late WaveformData sampleData = WaveformData(version: 1, channels: 1, sampleRate: 44100, sampleSize: 1, bits: 1, length: 1034, data: [] );
  late List<WaveformData> channels;

  bool isLocal = false;

  List<_ChartData> chartLiveData=[];

  ChartSeriesController? _chartSeriesController;

  double maxAxis=441;

  double curLevel = 0;
  List<int> lblTimescale = [10,40,80,160,320,625,1250,2500,5000,10000];
  List<int> arrTimescale = [10000,5000,2500,1250,625,320,160,80,40,10];

  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = <TargetFocus>[];
  // GlobalKey keyTutorial = GlobalKey();
  GlobalKey keyTutorialNavigation = GlobalKey();
  GlobalKey keyTutorialAudio = GlobalKey();
  GlobalKey keyTutorialAudioLevel = GlobalKey();
  GlobalKey keyTutorialAudioGainPlus = GlobalKey();
  GlobalKey keyTutorialAudioGainMinus = GlobalKey();
  GlobalKey keyTutorialSerial = GlobalKey();
  GlobalKey keyTutorialHid = GlobalKey();
  GlobalKey keyTutorialSetting = GlobalKey();
  GlobalKey keyTutorialTimescale = GlobalKey();
  GlobalKey keyTutorialEnd = GlobalKey();

  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};


  //const arrTimeScale = [0.1,1, 10,50, 100,500, 1000,5000,10000];
  //const arrTimeScaleBar = [0.00001,0.0001, 0.001,0.005,  0.01,0.05, 0.1,0.5,1];
  // List<double> arrScaleBar = [ 
  //   600000,
  //   546000,492000,  438000,384000,  330000,276000,  222000,168000,  114000,60000, 
    
  //   54600,49200,  43800,38400,  33000,27600,  22200,16800, 11400,6000, 
  //   5520,5040,  4560,4080,  3600,3120,  2640,2160,  1680,1200, 
  //   1140,1080, 1020,960,  900,840,  780,720,  660,600, 
    
  //   552,504,  456,408,  360,312,  264,216, 168,120, 
  //   114,108,  102,96,  90,84,  78,72,  66,60, 
    
  //   552,50.4,  45.6,40.8,  36,31.2,  26.4,21.6,  16.8,12, 
  //   11.4,10.8,  10.2,9.6,  9.0,8.4,  7.8,7.2,  6.6,6

  // ];

  // [ 600000,
  // 546000,492000,  438000,384000,  330000,276000,  222000,168000,  114000,60000, 
  // 54600,49200,  43800,38400,  33000,27600,  22200,16800, 11400,6000, 
  // 5520,5040,  4560,4080,  3600,3120,  2640,2160,  1680,1200, 
  // 1140,1080, 1020,960,  900,840,  780,720,  660,600, 
  // 552,504,  456,408,  360,312,  264,216, 168,120, 
  // 114,108,  102,96,  90,84,  78,72,  66,60, 
  // 552,50.4,  45.6,40.8,  36,31.2,  26.4,21.6,  16.8,12, 
  // 11.4,10.8,  10.2,9.6,  9.0,8.4,  7.8,7.2,  6.6,6 ];

  List<double> arrScaleBar = [ 
    0.1,
    0.1098901099,0.1219512195,0.1369863014,0.15625,0.1818181818,0.2173913043,0.2702702703,0.3571428571,0.5263157895,1,
    1.098901099,1.219512195,1.369863014,1.5625,1.818181818,2.173913043,2.702702703,3.571428571,5.263157895,10,
    10.86956522,11.9047619,13.15789474,14.70588235,16.66666667,19.23076923,22.72727273,27.77777778,35.71428571,50,
    52.63157895,55.55555556,58.82352941,62.5,66.66666667,71.42857143,76.92307692,83.33333333,90.90909091,100,
    108.6956522,119.047619,131.5789474,147.0588235,166.6666667,192.3076923,227.2727273,277.7777778,357.1428571,500,
    526.3157895,555.5555556,588.2352941,625,666.6666667,714.2857143,769.2307692,833.3333333,909.0909091,1000,
    1086.956522,1190.47619,1315.789474,1470.588235,1666.666667,1923.076923,2272.727273,2777.777778,3571.428571,5000,
    5263.157895,5555.555556,5882.352941,6250,6666.666667,7142.857143,7692.307692,8333.333333,9090.909091,10000,    
    // 6,6.6,  7.2,7.8,  8.4,9,  9.6,10.2,  10.8,11.4, 
    // 12,16.8,  21.6,26.4,  31.2,36,  40.8,45.6,  50.4,552, 
    // 60,66, 72,78, 84,90, 96,102, 108,114, 
    // 120,168, 216,264, 312,360, 408,456, 504,552, 
    // 600,660,  720,780,  840,900,  960,1020,  1080,1140, 
    // 1200,1680, 2160,2640, 3120,3600, 4080,4560, 5040,5520, 
    // 6000,11400, 16800,22200, 27600,33000, 38400,43800, 49200,54600, 
    // 60000,114000, 168000,222000, 276000,330000, 384000,438000, 492000,546000, 
    // 600000            

    // 6,8.4,10.8,  13.2,15.6,18,  20.4,22.8,25.2,  27.6,
    // 60,84,108,  132,156,180,  204,228,252,  276,
    // 600,840,1080,  1320,1560,1800,  2040,2280,2520,  2760,
    // 3000,3300,3600,  3900,4200,4500,  4800,5100,5400,  5700,
    // 6000,8400,10800,  13200,15600,18000,  20400,22800,25200,  27600,
    // 30000,33000,36000,  39000,42000,45000,  48000,51000,54000,  57000,
    // 60000,84000,108000,  132000,156000,180000,  204000,228000,252000,  276000,
    // 300000,330000,360000,  390000,420000,450000,  480000,510000,540000,  570000,
    // 600000        
  ];


  // List<double> arrScaleBar
  // = [  10,
  // 8, 6.4, 5.12, 4.096, 3.2768,   2.62144,2.097,1.6776,1.34208,10,
  // 8, 6.4, 5.12, 4.096, 3.2768,   2.62144,2.097,1.6776,1.34208,10,
  // 8, 6.4, 5.12, 4.096, 3.2768,   2.62144,2.097,1.6776,1.34208,10,
  // 8, 6.4, 5.12, 4.096, 3.2768,   2.62144,2.097,1.6776,1.34208,10,
  // 8, 6.4, 5.12, 4.096, 3.2768,   2.62144,2.097,1.6776,1.34208,10,
  // 8, 6.4, 5.12, 4.096, 3.2768,   2.62144,2.097,1.6776,1.34208,10,
  // 8, 6.4, 5.12, 4.096, 3.2768,   2.62144,2.097,1.6776,1.34208,10,
  // 8, 6.4, 5.12, 4.096, 3.2768,   2.62144,2.097,1.6776,1.34208,10 ];
  // List<double> arrScaleBar = [  10,
  //   1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  //   1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  //   1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  //   1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  //   1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  //   1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  //   1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  //   1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  // ];


  
  final SIZE_LOGS2 = 10;
  final NUMBER_OF_SEGMENTS = 60;
  final SEGMENT_SIZE = 44100;
  int SIZE = 0;

  List<int> arrCounts = [ 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384 ];
  ScaleUpdateDetails scaleDetails = ScaleUpdateDetails();
  late DragDownDetails dragDownDetails;
  late DragUpdateDetails dragDetails;
  late DragUpdateDetails dragHorizontalDetails;
  int levelScale = 0;
  int maxCountPerLevel = 0;
  int timeScaleBar = 80;
  double scaleBarWidth = 2.0;

  String isTutored = '';
  int tutorialStep = 0;

  int stepperValue = 1;
  var settingParams = {
    "channelCount" : -1,
    "maxAudioChannels" : 2,
    "maxSerialChannels" : 6,
    "initialMaxSerialChannels" : 6,
    "muteSpeakers" : true,
    "lowFilterValue" : "0",
    "highFilterValue" : "1000",
    "notchFilter50" : false,
    "notchFilter60" : false,
    "defaultMicrophoneLeftColor" : 0,
    "defaultMicrophoneRightColor" : 1,
    "defaultSerialColor1" : 0,
    "defaultSerialColor2" : 1,
    "defaultSerialColor3" : 2,
    "defaultSerialColor4" : 3,
    "defaultSerialColor5" : 4,
    "defaultSerialColor6" : 5,

    "flagDisplay1" : 1,
    "flagDisplay2" : 0,
    "flagDisplay3" : 0,
    "flagDisplay4" : 0,
    "flagDisplay5" : 0,
    "flagDisplay6" : 0,

    "strokeWidth" : 1.25,
    "strokeOptions" : [1,1.25,1.5,1.75,2],
    "enableDeviceLegacy": false
  };

  List<Color> audioChannelColors = [ Color(0xFF10ff00), Color(0xFFff0035), Color(0xFFe1ff4b), Color(0xFFff8755), Color(0xFF6bf063),Color(0xFF00c0c9),];
  // List<Color> audioChannelColors = [Colors.black, Color(0xFF10ff00), Color(0xFFff0035), Color(0xFFe1ff4b), Color(0xFFff8755), Color(0xFF6bf063),Color(0xFF00c0c9),];
  // List<Color> serialChannelColors = [Colors.black, Color(0xFF1ed400), Color(0xFFffff00), Color(0xFF20b4aa), Color(0xFFdc0000), Color(0xFFdcdcdc),Color(0xFFff3800),];
  // List<Color> serialChannelColors = [Colors.black, Color(0xFF1ed400), Color(0xFFff0035),Color(0xFFffff00), Color(0xFF20b4aa), Color(0xFFdcdcdc),Color(0xFFff3800),];
  List<Color> serialChannelColors = [ Color(0xFF1ed400), Color(0xFFff0035),Color(0xFFffff00), Color(0xFF20b4aa), Color(0xFFdcdcdc),Color(0xFFff3800),];
  List<Color> channelsColor = [Colors.green, Color(0xFFff0035), Colors.green, Colors.green, Colors.green, Colors.green];

  FocusNode keyboardFocusNode = FocusNode(debugLabel:"Keyboard Label");

  String prevKey = "";

  int deviceTypeInt = 0;


  List<double> eventMarkersPosition = [];
  List<int> eventMarkersNumber = [];
  
  double topRecordingBar = 0;
  
  bool isZooming = false;
  
  String globalChromeVersion = "";
  
  double horizontalDragX = 0;
  
  double horizontalDragXFix = 0;
  
  String strMaxTime = '';
  
  String strMinTime = '';
  
  double maxTime = 0;
  
  Debouncer debouncer = Debouncer(milliseconds: 3);
  Debouncer debouncerPlayback = Debouncer(milliseconds: 300);

  bool isLoadingFile = false;

  bool isShowingResetButton = true;

  bool isShowingTimebar = true;
  
  bool initFPS = true;
  
  Positioned feedbackButton = new Positioned(child:Container());
  Positioned openFileButton = new Positioned(child:Container());
  Positioned lastPositionButton = new Positioned(child:Container());
  Positioned settingDialogButton = new Positioned(child:Container());
  
  
  // Fps myFps = new Fps();
  


  void singleWorker() async {
    final w = SampleService();

    const sampleTaskDuration = 500;
    const taskCount = 10;

    print('running 2 x $taskCount tasks with a single worker...');

    final workerFutures = <Future>[];
    final workerSw = Stopwatch()..start();
    for (var i = 1; i <= taskCount; i++) {
      workerFutures.add(Future(() => w.cpu(milliseconds: sampleTaskDuration)));
      workerFutures.add(w.io(milliseconds: sampleTaskDuration));
    }
    var data = await Future.wait(workerFutures);
    print("data");
    print(data);
    workerSw.stop();

    print('running 2 x $taskCount tasks with a single worker... completed in ${workerSw.elapsed}',);    
  }

  void workerPool() async {
//  final pool = SampleWorkerPool(
//       entryPoints['sample'],
//       ConcurrencySettings(
//         minWorkers: 1,
//         maxWorkers: 3,
//         maxParallel: 5,
//       ));
//   await pool.start();

//   expect(pool.stats.where((s) => !s.isStopped).length == 1,
//       'the pool should have one worker alive');

//   logger.log('running 2 x $taskCount tasks with a worker pool...');

//   final poolFutures = <Future>[];
//   final poolSw = Stopwatch()..start();
//   for (var i = 1; i <= taskCount; i++) {
//     poolFutures.add(pool.cpu(milliseconds: sampleTaskDuration));
//     poolFutures.add(pool.io(milliseconds: sampleTaskDuration));
//   }
//   await Future.wait(poolFutures);
//   poolSw.stop();

//   logger.log(
//       'running 2 x $taskCount tasks with a worker pool... completed in ${poolSw.elapsed}',
//       replaceLastLine: true);

//   expect(poolSw.elapsedMicroseconds < workerSw.elapsedMicroseconds,
//       'pool should complete faster than worker');

//   pool.stop();
//   expect(pool.stats.where((s) => !s.isStopped).isEmpty,
//       'the pool should have no worker alive');   
  }  

  changeMaxAxis(){
    if (timeScale == 10){
      maxAxis = (sampleRate * timeScale / 1000);
    }else
    if (timeScale == 2008){
      maxAxis = (sampleRate * 0.02);
    }else
    if (timeScale == 6004){
      maxAxis = (sampleRate * 0.04);
    }else
    if (timeScale == 8002){
      maxAxis = (sampleRate * 0.06);
    }else{
      maxAxis = (sampleRate * 0.08);
    }
    maxAxis=maxAxis/2;

  }
  List<double> parameter = [];

  // callbackSetEventKeyPress( params ){
  //   // arrTransfer.push( sabDrawingState[DRAW_STATE.EVENT_COUNTER] );
  //   // arrTransfer.push( sabDrawingState[DRAW_STATE.EVENT_NUMBER] );
  //   // arrTransfer.push( sabDrawingState[DRAW_STATE.EVENT_POSITION] );
  //   // arrTransfer.push( sabDrawingState[DRAW_STATE.DIVIDER] );
  //   // arrTransfer.push( sabDrawingState[DRAW_STATE.SKIP_COUNTS] );
  //   // arrTransfer.push( sabDrawingState[DRAW_STATE.TIME_SCALE] );      
  //   // arrTransfer.push( sabDrawingState[DRAW_STATE.SAMPLE_RATE] );

  // }
  drawEventMarkers(params){
    eventMarkersNumber = params[0];
    eventMarkersPosition = params[1];
  }
  
  changeTimeBarStatus(params){
    isShowingTimebar = params[0];
  }

  double calculateTimeToBar(double curTimeBar, double horizontalDragXFix, double maxTime) {
    return  curTimeBar*horizontalDragXFix / maxTime;
  }

  drawElapsedTime(params){
    isShowingTimebar = false;
    double curTimeBar = params[0];
    if (curTimeBar >= maxTime){
      curTimeBar = maxTime;
    }
    
    horizontalDragX = calculateTimeToBar(curTimeBar, horizontalDragXFix, maxTime);
    strMinTime = getStrMinTime(horizontalDragX, horizontalDragXFix, maxTime);
    setState((){});
  }

  resetToAudio(){
    deviceType = 0;
    deviceTypeInt = 0;
    setState(() { });
  }
  
  changePlaybackButton(params){
    if (params[0] == 0){ // isOpening File?
    }else{
      isPlaying = params[1]; // 1 - play, 2 - stop 
    }
  }

  callAlert(text){
    showFlash(
        context: context,
        persistent: false,
        duration: Duration(seconds: 3),
        builder: (_, controller) {
          return Flash(
            controller: controller,
            // margin: margin,
            behavior: FlashBehavior.fixed,
            position: FlashPosition.bottom,
            borderRadius: BorderRadius.circular(8.0),
            borderColor: Colors.blue,
            boxShadows: kElevationToShadow[8],
            backgroundGradient: RadialGradient(
              colors: [Colors.amber, Colors.black87],
              center: Alignment.topLeft,
              radius: 2,
            ),
            onTap: () => controller.dismiss(),
            forwardAnimationCurve: Curves.easeInCirc,
            reverseAnimationCurve: Curves.bounceIn,
            child: DefaultTextStyle(
              style: TextStyle(color: Colors.white),
              child: FlashBar(
                title: Text(text[0]),
                content: Text(text[1]),
                indicatorColor: Colors.red,
                icon: Icon(Icons.info_outline),
                primaryAction: TextButton(
                  onPressed: () => controller.dismiss(),
                  child: Text('Okay'),
                ),
              ),
            ),
          );
        },
      ).then((_) {
      });    
  }

  Map<String, dynamic> _readWebBrowserInfo(WebBrowserInfo data) {
    return <String, dynamic>{
      'browserName': describeEnum(data.browserName),
      'appCodeName': data.appCodeName,
      'appName': data.appName,
      'appVersion': data.appVersion,
      'deviceMemory': data.deviceMemory,
      'language': data.language,
      'languages': data.languages,
      'platform': data.platform,
      'product': data.product,
      'productSub': data.productSub,
      'userAgent': data.userAgent,
      'vendor': data.vendor,
      'vendorSub': data.vendorSub,
      'hardwareConcurrency': data.hardwareConcurrency,
      'maxTouchPoints': data.maxTouchPoints,
    };
  }

  callbackHorizontalDiff(params){
    horizontalDiff = params[0];
    if (horizontalDiff == 0){
      isZooming = false;
    }
    setState((){});
  }

  callbackGetChromeVersion(params){
    print("callbackGetChromeVersion");
    print(params[0]);
    print(params[1]);
    print(params[2]);
    print(params[3]);
    globalChromeVersion = params[0].toString()+"."+params[1].toString()+"."+params[2].toString()+"."+params[3].toString();
    print(globalChromeVersion);
  }

  callbackSetRecording( params ){
    isRecording = params[0];
    if (isRecording == 0){
      topRecordingBar = 0;//0;

    }else{
      startRecordingTime = DateTime.now();
      topRecordingBar = 50;
    }

    setState(() { });
  }
  changeResetPlayback( params ){
    isShowingResetButton = params[0];
    horizontalDragX = MediaQuery.of(context).size.width - 100 - 20;
    horizontalDragXFix = MediaQuery.of(context).size.width - 100 - 20;

    setState((){});
  }

  callbackOpeningFile( params ){
    isLoadingFile = params[0];
    setState((){});
  }

  callbackIsOpeningWavFile( params ){
    isOpeningFile = params[0];
    setState((){});
  }

  callbackOpenWavFile( wav ){
    horizontalDiff = 0;
    strMinTime = "00:00 000";
    isLocal = false;
    isLoadingFile = false;
    isShowingResetButton = true;

    isOpeningFile = 1;
    timeScaleBar = 80;
    horizontalDragX = MediaQuery.of(context).size.width - 100 - 20;
    horizontalDragXFix = MediaQuery.of(context).size.width - 100 - 20;

      // wav.fmt.numChannels,
      // wav.fmt.sampleRate,
      // wav.fmt.bitsPerSample,    
    channels = [];
    final numChannels = wav[0];
    sampleRate = wav[1];
    final bitsPerSample = wav[2];
    final audioLength = wav[3];
    // final samples = wav[4];
    localChannel = numChannels;
    final strColors = wav[4];
    final strNames = wav[5];
    
    maxTime = wav[10].length/sampleRate;
    if (maxTime > 3600){
      final lastDecimals = (maxTime - maxTime.floor()).toStringAsFixed(3).replaceFirst("0.","");
      strMaxTime = ( (maxTime / 3600).floor() % (3600 * 24) ).toString().padLeft(2,"0") + ":" + ( (maxTime / 60).floor() % 3600 ).toString().padLeft(2,"0") + ":" + (maxTime.floor() % 60).toString().padLeft(2,"0") + " " + lastDecimals;

    }else{
      final lastDecimals = (maxTime - maxTime.floor()).toStringAsFixed(3).replaceFirst("0.","");
      strMaxTime = ( (maxTime / 60).floor() % 3600 ).toString().padLeft(2,"0") + ":" + (maxTime.floor() % 60).toString().padLeft(2,"0") + " " + lastDecimals;
    }
    strMinTime = strMaxTime;

    if (strNames.indexOf("AUDIO") > -1){
      deviceType = 0;
      channelGains = [10000,10000,10000,10000,10000,10000];
      listIndexSerial=[5,5,5,5,5,5];
      listIndexHid = [7,7,7,7,7,7];
      listIndexAudio = [9,9];

      minChannels = 1;
      maxChannels = 2;
      for (int i=1; i <= 6 ; i++){
        settingParams["flagDisplay"+i.toString()] = 0;
      }
      for (int i=1; i <= numChannels ; i++){
        settingParams["flagDisplay"+i.toString()] = 1;
      }

      var arrColors = strColors.split(";");
      var leftChannel = int.parse(arrColors[0]);
      channelsColor[0] = audioChannelColors[leftChannel];
      settingParams['defaultMicrophoneLeftColor'] = leftChannel;
      if (numChannels > 1){
        var rightChannel = int.parse(arrColors[1]);
        channelsColor[1] = audioChannelColors[rightChannel];
        settingParams['defaultMicrophoneRightColor'] = rightChannel;
      }
      setState((){});
    }else{
      channelGains = [10000,10000,10000,10000,10000,10000];
      listIndexSerial=[5,5,5,5,5,5];
      listIndexHid = [7,7,7,7,7,7];
      listIndexAudio = [9,9];

      final minChannels = wav[7];
      final maxChannels = wav[8];
      if ( strNames.toUpperCase().indexOf("HID") > -1 ){
        deviceType = 2;
      }else{
        deviceType = 1;
      }
      
      for (int i=1; i <= 6 ; i++){
        settingParams["flagDisplay"+i.toString()] = 0;
      }
      for (int i=1; i <= numChannels ; i++){
        settingParams["flagDisplay"+i.toString()] = 1;
      }

      var arrColors = strColors.split(";");
      for (int i = 0; i < arrColors.length - 1 ; i++){
        int channelColor = int.parse(arrColors[i]);
        channelsColor[i] = serialChannelColors[channelColor];
      }
      // var leftChannel = int.parse(arrColors[0]);
      // channelsColor[0] = audioChannelColors[leftChannel];
      // settingParams['defaultMicrophoneLeftColor'] = leftChannel;
      // if (numChannels > 1){
      //   var rightChannel = int.parse(arrColors[1]);
      //   channelsColor[1] = audioChannelColors[rightChannel];
      //   settingParams['defaultMicrophoneRightColor'] = rightChannel;
      // }
      setState((){});

    }

    print("READ wav");
    print(numChannels);
    print(sampleRate);
    print(bitsPerSample);
    print(audioLength);
    print(strNames);
    print(settingParams);
    // print(samples);

    // final audioLength = (samples.length / sampleRate / numChannels);
    for (var i = 0 ; i < numChannels ; i++){
      // print(i*audioLength);
      // print( (i+1)*audioLength );
      // channels.add( WaveformData(version: 1, channels: numChannels, sampleRate: sampleRate, sampleSize: 16, bits: bitsPerSample, length: audioLength, data: samples.sublist(i*audioLength,(i+1)*audioLength) ) );
      var samples = wav[10+i].cast<double>();

      channels.add( WaveformData(version: 1, channels: numChannels, sampleRate: sampleRate, sampleSize: 16, bits: bitsPerSample, length: samples.length, data: samples ) );
    }
    setState(() {
      
    });
    _sendAnalyticsEvent("opened_file", {
      "isFileOpened" : 1
    });

  }

  callbackGetDeviceInfo( params ){
    // extra_channels,max min, channels
    print("callback params");
    print(params);
    extraChannels = params[0];
    minChannels = params[1];
    maxChannels = params[2];
    settingParams["channelCount"] = minChannels;

    if (extraChannels != 0){
      for (int i=1; i <= maxChannels ; i++){
        settingParams["flagDisplay"+i.toString()] = 1;
        channelsColor[i-1] = serialChannelColors[i-1];
      }

    }else{
      for (int i=1; i <= minChannels ; i++){
        settingParams["flagDisplay"+i.toString()] = 1;
        channelsColor[i-1] = serialChannelColors[i-1];
      }
      
    }
    js.context.callMethod('setFlagChannelDisplay', [settingParams["flagDisplay1"],settingParams["flagDisplay2"],settingParams["flagDisplay3"],settingParams["flagDisplay4"],settingParams["flagDisplay5"],settingParams["flagDisplay6"] ]);
    setState((){});
  }

  callbackAudioInit( params ) {
    deviceType = params[0];
    isPlaying = params[1];
    // startRecordingTime = (DateTime.now());
    channelGains = [10000,10000,10000,10000,10000,10000];
    listIndexSerial=[5,5,5,5,5,5];
    listIndexHid = [7,7,7,7,7,7];
    listIndexAudio = [9,9];
    
    settingParams["flagDisplay1"] = 1;
    settingParams["flagDisplay2"] = 0;
    settingParams["defaultMicrophoneLeftColor"] = 0;
    settingParams["defaultMicrophoneRightColor"] = 1;
    channelsColor[0]=audioChannelColors[0];
    channelsColor[1]=audioChannelColors[1];
    // print("channelsColor[0] : "+channelsColor[0].toString());
    // print("channelsColor[1] : "+channelsColor[1].toString());
    
    js.context.callMethod('setFlagChannelDisplay', [settingParams["flagDisplay1"],settingParams["flagDisplay2"],settingParams["flagDisplay3"],settingParams["flagDisplay4"],settingParams["flagDisplay5"],settingParams["flagDisplay6"] ]);    
    // if (initFPS){
    //   initFPS = false;
    //   Fps.instance.start();
    //   Fps.instance.addFpsCallback((FpsInfo fpsInfo) async {
    //     // print("fpsInfo.fps");
    //     // print(fpsInfo.fps);
    //     if (curFps == fpsInfo.fps){
    //       return;
    //     }
    //     curFps = fpsInfo.fps;
    //     int incSkip = 0;
    //     if (curFps < 30){

    //     }else
    //     if (curFps <15){
    //       incSkip++;
    //     }

    //     // if (curFps <15){
    //     //   incSkip++;
    //     // }
    //     if (!isFeedback)
    //       ( await js.context.callMethod('setFps', [ curFps, incSkip ]) );
    //   });

    // }

    setState((){});
  }

  //https://firebase.google.com/docs/reference/cpp/group/parameter-names
  callbackErrorLog( params ){
    _sendAnalyticsEvent( params[0], { "parameters" : params[1] } );
  }
  
  callbackSerialInit( params ) async {
    deviceType = params[0];
    isPlaying = params[1];
    // startRecordingTime = (DateTime.now());
    listIndexSerial=[5,5,5,5,5,5];
    listIndexHid = [7,7,7,7,7,7];
    listIndexAudio = [9,9];

    if (deviceType == 2){
      channelGains = [500,500,500,500,500,500];
      _sendAnalyticsEvent("button_hid_connected", {
        "device" : "HID",
        "deviceType" : deviceType,
        "isStartingHid" : 1,
        "isStartingAudio" : 0
      });

    }else
    if (deviceType == 1){
      channelGains = [1000,1000,1000,1000,1000,1000];
      _sendAnalyticsEvent("button_serial_connected", {
        "device" : "Serial",
        "deviceType" : deviceType,
        "isStartingSerial" : 1,
        "isStartingAudio" : 0
      });
    }else{

    }
    // await js.context.callMethod('setFlagChannelDisplay', [settingParams["flagDisplay1"],settingParams["flagDisplay2"],settingParams["flagDisplay3"],settingParams["flagDisplay4"],settingParams["flagDisplay5"],settingParams["flagDisplay6"] ]);
    setState((){});
  }

  js2Dart( params ) {
    //Hashmap can't be processed
    // 2 variable cant be processed
    // 2 arrayed variable can't
    // print("JS2Dart");
    // print(params);
    // var params = content.value;
    // chartData = js.JsArray.from(params[0]).toList().cast<double>();
    // if (isPlaying == 2){
    //   return;
    // }
    if (isFeedback){ return; }
    
    int len = params.length-1;
    if (channelsData.length != len){
      channelsData= [];
      for (int i=0;i<len;i++){
        chartData = (params[i]).toList().cast<double>();
        channelsData.add(chartData);
      }
    }else{
      for (int i=0;i<len;i++){
        chartData = (params[i]).toList().cast<double>();
        channelsData[i]=(chartData);
      }
    }
    eventMarkersNumber = params[len][0];
    eventMarkersPosition = params[len][1];


    // double width = MediaQuery.of(context).size.width;

    // sampleData = WaveformData(version: 1, channels: 1, sampleRate: 44100, sampleSize: 1, bits: 1, length: 1034, data: [-23254,16644,-30935,20205,-16593,16930,-11736,13287,-18606,13789,-10566,13918,-13824,14620,-11527,8676,-12231,15098,-11159,9512,-12696,14081,-10952,11740,-12275,11320,-10848,9477,-14906,17874,-11615,12593,-13266,11521,-16097,12726,-11027,11909,-13936,12957,-12427,13551,-13273,12631,-12068,12180,-16960,10204,-11003,15350,-9547,7862,-11642,9156,-12916,11414,-12254,12014,-10904,10699,-19290,17371,-18661,14840,-10483,7772,-12001,14139,-11743,12346,-8817,7486,-13723,12268,-12806,11932,-10766,9278,-14363,10833,-10968,10201,-7769,11178,-9181,10532,-11108,10264,-9397,9859,-10956,8993,-10164,9633,-9415,11935,-9315,7894,-11991,8480,-10056,9279,-11766,10108,-8676,9179,-6572,6416,-10415,8478,-9494,10295,-10625,10694,-12682,10206,-7907,7254,-8939,6862,-7444,7746,-9598,10933,-8451,7638,-9671,10051,-11103,8560,-8351,8265,-7618,10012,-9122,6387,-8906,6005,-7509,6537,-10554,8008,-9442,7675,-7059,5806,-8574,5545,-6884,6272,-8838,7777,-7123,6712,-6712,7930,-7544,7704,-7624,7634,-7423,9566,-10375,7497,-7437,6828,-8448,7644,-7928,7369,-5000,6147,-5130,6864,-8465,7033,-6381,5755,-6005,4566,-4916,5251,-5549,4577,-8633,8432,-5557,5441,-7610,6335,-6404,8627,-6402,5347,-6471,5600,-5128,5529,-6062,5212,-7089,4902,-4649,4729,-5128,4554,-5152,4176,-5765,3603,-5866,4989,-3389,4127,-5480,4420,-6319,5139,-4871,4421,-3887,5301,-5045,3809,-5203,3625,-4372,4901,-5183,4618,-5778,4335,-3816,3887,-4553,5277,-4152,3205,-3674,3579,-3696,3572,-3956,5101,-4741,5534,-5473,3850,-4049,3141,-4748,3341,-3427,4422,-4851,3985,-4356,4846,-3412,4368,-3631,4046,-3406,2807,-3376,4007,-3634,3886,-3689,3219,-2725,2106,-3044,3071,-3348,3085,-3919,3154,-4708,3611,-3795,3468,-2688,4142,-3358,2785,-3194,3590,-2778,2962,-2843,3011,-3312,3016,-3596,2896,-2266,2318,-2694,2653,-2403,2834,-2194,1972,-2739,2152,-2862,1949,-2803,3438,-2871,2196,-1829,2132,-2549,2528,-2377,1562,-2152,2535,-2630,2717,-2292,1672,-2840,2415,-2307,2046,-1984,1766,-2259,2241,-1898,1693,-1497,1362,-1639,1986,-1748,2077,-1815,1743,-1906,1791,-1610,1541,-1629,1726,-1522,1478,-1665,1841,-1872,1383,-2102,1654,-2218,1754,-1710,1342,-1383,1168,-1351,1371,-1122,1323,-1633,1467,-1011,1221,-1144,1533,-1512,2114,-1038,687,-1687,1691,-1081,1380,-1671,1373,-1489,957,-1635,1308,-1142,975,-1216,1315,-1038,1183,-1632,1497,-1265,1182,-896,1011,-1273,965,-946,1027,-913,983,-1194,1121,-1206,1065,-1218,1070,-745,883,-997,1082,-1454,1274,-1188,1147,-1228,1031,-720,767,-1287,1075,-663,727,-607,903,-961,1347,-779,761,-1336,1049,-892,861,-1114,1363,-942,1068,-1154,1125,-784,924,-774,822,-905,860,-825,854,-551,509,-566,597,-932,739,-776,868,-665,638,-466,647,-541,667,-887,873,-891,812,-570,803,-762,716,-542,788,-618,941,-577,681,-648,883,-778,705,-820,880,-749,699,-738,903,-875,1091,-745,747,-576,528,-611,641,-548,630,-501,454,-625,517,-436,377,-573,589,-486,487,-462,458,-310,323,-376,477,-498,675,-342,454,-653,618,-550,454,-549,409,-492,659,-621,678,-499,447,-414,508,-419,354,-446,379,-609,568,-740,599,-542,456,-491,398,-374,365,-425,472,-446,421,-460,460,-586,529,-387,404,-599,548,-464,411,-410,369,-300,253,-454,444,-369,369,-441,374,-244,314,-467,428,-410,400,-310,450,-508,382,-373,414,-300,368,-364,374,-439,356,-440,472,-351,332,-429,348,-291,308,-336,318,-386,338,-350,364,-276,329,-326,314,-311,308,-263,286,-279,357,-283,349,-260,284,-317,300,-252,224,-230,204,-293,288,-300,399,-221,297,-404,372,-297,161,-178,270,-257,317,-270,253,-325,305,-257,225,-388,326,-220,211,-240,239,-277,307,-267,301,-331,327,-171,297,-270,316,-226,217,-338,319,-273,326,-224,232,-282,230,-239,216,-279,244,-235,229,-392,327,-333,275,-246,217,-253,215,-258,247,-169,213,-239,252,-212,217,-304,303,-204,199,-160,202,-284,244,-264,355,-254,207,-209,181,-147,204,-245,222,-200,195,-199,239,-294,238,-200,210,-152,167,-182,183,-261,152,-175,167,-276,284,-225,173,-208,187,-210,206,-213,212,-176,169,-202,183,-131,143,-187,170,-217,231,-202,209,-215,194,-214,227,-270,232,-283,332,-124,181,-193,202,-291,294,-170,176,-203,267,-204,174,-202,183,-160,205,-155,159,-270,259,-132,144,-159,195,-221,201,-169,189,-212,216,-146,143,-158,171,-193,179,-154,178,-211,158,-148,149,-148,176,-194,175,-143,150,-177,193,-170,146,-142,136,-153,157,-166,153,-203,181,-154,185,-164,152,-161,149,-122,145,-169,113,-187,140,-210,188,-149,163,-134,118,-157,220,-78,90,-124,157,-142,94,-188,143,-100,88,-130,108,-180,171,-130,100,-128,169,-168,141,-136,152,-144,116,-90,98,-144,151,-109,106,-145,155,-62,118,-137,165,-173,156,-160,144,-87,86,-136,161,-119,178,-113,106,-85,99,-99,98,-84,71,-148,105,-135,115,-92,105,-100,78,-87,87,-84,84,-95,118,-79,84,-101,113,-93,98,-124,86,-105,99,-111,104,-99,119,-101,100,-98,106,-127,101,-96,86,-86,107,-104,99,-67,72,-92,99,-99,98,-101,135,-122,89,-111,124,-85,75,-113,122,-84,99,-82,83,-134,116,-55,71,-104,63,-90,89,-95,86,-80,74,-80,119,-100,78,-97,94,-82,76,-118,104,-139,157,-123,132,-99,96,-100,76,-80,92,-91,96,-80,72,-83,92,-93,79,-72,70,-55,49,-69,60,-72,65,-89,72,-98,62,-84,78,-60,70,-90,83,-83,80,-98,78,-82,62,-88,72,-73,87,-57,66,-96,87,-71,63,-75,64,-47,56,-92,50,-74,80,-48,64,-116,84,-63,70,-69,59,-73,71,-91,91,-62,58,-74,62,-65,62,-49,60,-50,51,-92,71,-103,80,-91,92,-56,58,-56,51,-75,75,-68,83,-69,74,-66,84,-80,71,-75,72,-60,46,-73,68,-46,50,-71,60,-39,48,-68,56,-69,77,-60,50,-71,66,-69,77,-64,74,-71,62,-69,51,-43,40,-44,52,-63,70,-53,50,-58,62,-76,79,-71,83,-65,65,-47,46,-82,86,-45,40,-27,35,-55,41,-37,33,-48,58,-50,50,-48,35,-34,35,-56,51,-49,48,-53,55,-73,55,-50,46,-35,37,-42,60,-37,27,-49,64,-65,39,-41,49,-54,56,-49,54,-41,37,-47,60,-33,50,-47,32,-44,39,-53,53,-46,35,-44,47,-34,39,-37,31,-53,50,-41,53,-42,48,-42,42,-33,30,-41,50,-61,43,-35,29,-54,48,-38,44,-35,27,-50,41,-50,30,-54,48,-41,45,-29,25,-34,27,-43,39,-44,41,-24,25,-29,35,-36,28,-35,38,-34,34,-41,26,-29,22,-37,34,-55,54,-35,35,-27,28,-45,34,-38,29,-39,48,-34,33,-47,40,-25,27,-35,25,-32,34,-32,41,-44,44,-34,21,-33,33,-39,40,-27,29,-38,49,-33,37,-28,29,-28,27,-26,27,-30,31,-28,23,-20,23,-32,34,-20,25,-21,20,-29,26,-31,26,-35,28,-28,31,-29,24,-21,14,-32,32,-25,23,-35,34,-27,25,-27,24,-19,19,-27,31,-36,22,-21,14,-31,36,-30,29,-32,29,-26,31,-31,27,-27,23,-17,12,-37,26,-27,15,-23,24,-21,22,-14,19,-26,19,-15,18,-29,27,-25,23,-18,18,-18,23,-21,21,-18,17,-29,24,-19,19,-24,15,-21,18,-19,16,-25,26,-17,17,-16,20,-15,17,-16,15,-22,15,-18,18,-19,21,-21,18,-21,15,-22,17,-22,17,-19,25,-25,22,-22,17,-18,19,-14,13,-17,17,-15,14,-22,22,-16,15,-25,19,-28,32,-15,18,-15,21,-19,21,-16,14,-16,17,-21,18,-16,15,-14,12,-14,15,-16,22,-22,27,-19,16,-25,19,-20,20,-22,19,-16,11,-12,11,-18,15,-22,18,-11,12,-18,15,-14,12,-18,13,-15,13,-16,12,-14,11,-13,11,-18,15,-14,12,-18,16,-12,12,-14,15,-23,17,-13,14,-13,12,-13,12,-13,11,-16,14,-11,10,-13,14,-16,16,-19,17,-15,17,-15,9,-10,12,-11,7,-15,11,-12,9,-13,14,-13,12,-15,12,-17,16,-12,11,-12,14,-13,14,-10,10,-13,11,-12,11,-14,11,-13,14,-13,11,-13,10,-17,14,-15,11,-8,8,-15,16,-16,11,-12,10,-11,10,-12,14,-9,8,-11,11,-18,15,-12,8,-8,10,-12,11,-9,7,-10,9,-12,11,-11,11,-9,7,-10,10,-9,9,-11,9,-9,9,-12,8,-9,9,-9,6,-11,10,-11,8,-9,8,-9,9,-12,13,-11,9,-14,14,-12,12,-12,9,-10,10,-11,12,-15,10,-11,7,-11,10,-11,11,-12,8,-11,10,-10,12,-12,10,-10,7,-8,7,-5,4,-7,5,-12,11,-10,9,-9,7,-9,7,-8,7,-10,10,-12,10,-10,9,-8,8,-8,6,-14,9,-8,6,-11,9,-7,6,-6,7,-12,11,-12,10,-10,8,-8,6,-9,8,-7,6,-8,5,-10,6,-8,7,-11,8,-6,5,-6,7,-7,4,-7,9,-5,4,-5,3,-7,4,-8,9,-8,6,-6,5,-5,5,-7,6,-7,6,-5,5,-8,7,-8,8,-4,5,-10,6,-5,3,-5,4,-5,4,-5,5,-8,4,-6,4,-6,6,-5,3,-8,6,-7,6,-7,5,-5,5,-7,6,-8,7,-5,3,-8,7,-5,5,-7,6,-8,5,-8,6,-5,4,-6,7,-6,5,-6,5,-5,4,-4,4,-5,5,-7,5,-6,6,-5,4,-4,3,-7,5,-5,3,-6,6,-6,6,-6,6,-5,4,-7,6,-8,6,-7,5,-6,6,-5,3,-4,4,-5,5,-4,4,-6,4,-5,6,-7,5,-3,3,-5,4,-5,4,-5,3,-5,3,-4,3,-4,4,-5,4,-5,4,-4,3,-3,3,-4,3,-5,5,-7,5,-5,5,-5,5,-4,3,-5,3,-4,3,-3,3,-3,2,-3,2,-5,5,-4,3,-5,4,-4,3,-4,3,-3,2,-3,3,-4,2,-5,4,-5,2,-4,2,-5,3,-4,3,-4,3,-2,1,-3,2,-3,2,-5,4,-4,2,-4,3,-5,3,-3,3,-4,2,-3,3,-3,2,-5,3,-2,2,-6,4,-5,4,-3,2,-5,4,-3,2,-3,2,-4,3,-4,4,-4,2,-4,2,-2,2,-3,2,-4,2,-4,4,-3,2,-3,2,-2,1,-2,2,-3,2,-3,3,-3,2,-2,2,-3,2,-3,2,-3,2,-3,3,-3,2,-3,2,-3,2,-2,1,-2,3,-3,1,-2,2,-4,3,-3,2,-3,3,-3,2,-3,2,-2,1,-2,1,-3,2,-2,2,-2,1,-3,1,-2,1,-3,2,-2,1,-2,1,-2,1,-3,2,-3,2,-4,3,-3,2,-3,2,-3,2,-2,1,-3,1,-2,2,-2,2,-2,1,-3,1,-3,2,-2,1,-3,1,-3,1,-3,1,-2,1,-2,1,-3,1,-3,2,-2,1,-2,1,-2,0,-2,1] );
    
    // waveData.push(sampleData);
    currentRecordingTime = DateTime.now();
    duration = currentRecordingTime.difference(startRecordingTime);
    // labelDuration = ( (duration.inHours) ).toString()+":"+( (duration.inMinutes) ).toString()+":"+(duration.inSeconds % 60).toString();
    labelDuration = ( (duration.inHours) ).toString().padLeft(2,'0')+":"+( (duration.inMinutes % 60) ).toString().padLeft(2,'0')+":"+(duration.inSeconds % 60).toString().padLeft(2,'0')+"."+(duration.inMilliseconds % 1000).toString().padLeft(3,'0');

    setState(() {
      
    });
  

  }

  showTutorial(){
    initTargets();

    tutorialCoachMark = TutorialCoachMark(
      context,
      targets: targets,
      colorShadow: Colors.lightBlue,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.7,
      onFinish: () {
        if (tutorialStep < 6) return;
        print("finish");
        isPlaying = 1;
        js.context.callMethod('recordAudio', ['Flutter is calling upon JavaScript!']);

        storage.setItem('isTutored', '1');
        isTutored = '1';
        
        setState(() {        
        });


      },
      onClickTarget: (target) {
        // print('onClickTarget: $target');
        tutorialStep++;
        setState(() { });
      },
      onClickOverlay: (target) {
        // print('onClickOverlay: $target');
      },
      onSkip: () {
        // print("skip");
        // isPlaying = 1;
        // js.context.callMethod('recordAudio', ['Flutter is calling upon JavaScript!']);
        // setState(() {        
        // });
        tutorialStep = 7;
        print("SKIPPED");
        isPlaying = 1;
        js.context.callMethod('recordAudio', ['Flutter is calling upon JavaScript!']);

        storage.setItem('isTutored', '1');
        isTutored = '1';
        
        setState(() {        
        });

      },
    )..show();     
  }

  getCachedWidget(){
    // if (feedbackButton != null){
    {
      feedbackButton = Positioned(
        key : keyTutorialEnd,
        top:10,
        right:80,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(50, 50),
            shape : const CircleBorder(),
            shadowColor: Colors.blue,
            primary: Colors.white,
            onPrimary: Colors.green,
            onSurface: Colors.red,
          ),
          child: const Icon(Icons.question_answer_rounded, color: Color(0xFF800000),),
          onPressed: (){
            isFeedback = true;
            _sendAnalyticsEvent("button_feedback", {
              "deviceType" : deviceType,
              "isStarting" : 1,
              "isStartingAudio" : 0
            });

            setState(() {});
            // showFeedbackDialog(context, settingParams).then((params){

            // });
          },
        ),
      );
    }
    // if (openFileButton != null) {
    {
      openFileButton =         
        // // HIDE FOR NOW!
        // // OPEN FILE
        Positioned(
          top:10,
          right:10,
          child:ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(50, 50),
              shape : const CircleBorder(),
              shadowColor: Colors.blue,
              primary: Colors.white,
              onPrimary: Colors.green,
              onSurface: Colors.red,
            ),
            
            onPressed: () async {
              js.context.callMethod('openReadWavFile', ["openReadWavFile"]);
              _sendAnalyticsEvent("button_open_file", {
                "isOpeningFile" : 1
              });
              // FilePickerResult? result = await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions: ["wav"]);

              // if (result != null) {
              //   isLocal = true;
              //   Uint8List fileBytes = result.files.first.bytes!;
              //   String fileName = result.files.first.name;
              //   WavReader wavReader = WavReader();
              //   (wavReader).open(pbytes: fileBytes);
              //   // WavReader wav = wavReader;
                
              //   // chartData = fileBytes.toList().cast<double>();
              //   // chartData = wavReader.readSamples().cast<double>();
              //   // sampleData = WaveformData(version: 1, channels: wavReader.numChannels, sampleRate: wavReader.sampleRate, sampleSize: 64, bits: wavReader.bitsPerSample, length: wavReader.audioLength.toInt(), data: wavReader.readSamples().cast<double>() );
              //   channels = [];
              //   try{
              //     // print("wavReader.channels.length");
              //     // print(wavReader.channels.length);
              //     for (int i =0;i<wavReader.channels.length;i++){
              //       // print("wavReader.channels[i]");
              //       // print(wavReader.channels[i]);
              //       // print(wavReader.channels[i]!.cast<double>());
              //       var samples = wavReader.channels[i]!.cast<double>();
              //       // print("samples");
              //       // print(samples);
              //       channels.add( WaveformData(version: 1, channels: wavReader.numChannels, sampleRate: wavReader.sampleRate, sampleSize: 16, bits: wavReader.bitsPerSample, length: wavReader.audioLength.toInt(), data: samples ) );
              //       // print(channels[i]);
              //     }

              //   }catch(err){
              //     print("err");
              //     print(err);
              //   }


              //   // print("chartData.length");
              //   // print(chartData.length);
              //   // sampleData = WaveformData(version: 1, channels: 1, sampleRate: this.sampleRate, sampleSize: 128, bits: 16, length: fileBytes.length, data: List.from(fileBytes) );
              //   // print(fileBytes.toList());
              //   // sampleData = WaveformData.fromJson('{"version":2,"channels":1,"sample_rate":44100,"samples_per_pixel":64,"bits":16,"length":1034,"data":[-23254,16644,-30935,20205,-16593,16930,-11736,13287,-18606,13789,-10566,13918,-13824,14620,-11527,8676,-12231,15098,-11159,9512,-12696,14081,-10952,11740,-12275,11320,-10848,9477,-14906,17874,-11615,12593,-13266,11521,-16097,12726,-11027,11909,-13936,12957,-12427,13551,-13273,12631,-12068,12180,-16960,10204,-11003,15350,-9547,7862,-11642,9156,-12916,11414,-12254,12014,-10904,10699,-19290,17371,-18661,14840,-10483,7772,-12001,14139,-11743,12346,-8817,7486,-13723,12268,-12806,11932,-10766,9278,-14363,10833,-10968,10201,-7769,11178,-9181,10532,-11108,10264,-9397,9859,-10956,8993,-10164,9633,-9415,11935,-9315,7894,-11991,8480,-10056,9279,-11766,10108,-8676,9179,-6572,6416,-10415,8478,-9494,10295,-10625,10694,-12682,10206,-7907,7254,-8939,6862,-7444,7746,-9598,10933,-8451,7638,-9671,10051,-11103,8560,-8351,8265,-7618,10012,-9122,6387,-8906,6005,-7509,6537,-10554,8008,-9442,7675,-7059,5806,-8574,5545,-6884,6272,-8838,7777,-7123,6712,-6712,7930,-7544,7704,-7624,7634,-7423,9566,-10375,7497,-7437,6828,-8448,7644,-7928,7369,-5000,6147,-5130,6864,-8465,7033,-6381,5755,-6005,4566,-4916,5251,-5549,4577,-8633,8432,-5557,5441,-7610,6335,-6404,8627,-6402,5347,-6471,5600,-5128,5529,-6062,5212,-7089,4902,-4649,4729,-5128,4554,-5152,4176,-5765,3603,-5866,4989,-3389,4127,-5480,4420,-6319,5139,-4871,4421,-3887,5301,-5045,3809,-5203,3625,-4372,4901,-5183,4618,-5778,4335,-3816,3887,-4553,5277,-4152,3205,-3674,3579,-3696,3572,-3956,5101,-4741,5534,-5473,3850,-4049,3141,-4748,3341,-3427,4422,-4851,3985,-4356,4846,-3412,4368,-3631,4046,-3406,2807,-3376,4007,-3634,3886,-3689,3219,-2725,2106,-3044,3071,-3348,3085,-3919,3154,-4708,3611,-3795,3468,-2688,4142,-3358,2785,-3194,3590,-2778,2962,-2843,3011,-3312,3016,-3596,2896,-2266,2318,-2694,2653,-2403,2834,-2194,1972,-2739,2152,-2862,1949,-2803,3438,-2871,2196,-1829,2132,-2549,2528,-2377,1562,-2152,2535,-2630,2717,-2292,1672,-2840,2415,-2307,2046,-1984,1766,-2259,2241,-1898,1693,-1497,1362,-1639,1986,-1748,2077,-1815,1743,-1906,1791,-1610,1541,-1629,1726,-1522,1478,-1665,1841,-1872,1383,-2102,1654,-2218,1754,-1710,1342,-1383,1168,-1351,1371,-1122,1323,-1633,1467,-1011,1221,-1144,1533,-1512,2114,-1038,687,-1687,1691,-1081,1380,-1671,1373,-1489,957,-1635,1308,-1142,975,-1216,1315,-1038,1183,-1632,1497,-1265,1182,-896,1011,-1273,965,-946,1027,-913,983,-1194,1121,-1206,1065,-1218,1070,-745,883,-997,1082,-1454,1274,-1188,1147,-1228,1031,-720,767,-1287,1075,-663,727,-607,903,-961,1347,-779,761,-1336,1049,-892,861,-1114,1363,-942,1068,-1154,1125,-784,924,-774,822,-905,860,-825,854,-551,509,-566,597,-932,739,-776,868,-665,638,-466,647,-541,667,-887,873,-891,812,-570,803,-762,716,-542,788,-618,941,-577,681,-648,883,-778,705,-820,880,-749,699,-738,903,-875,1091,-745,747,-576,528,-611,641,-548,630,-501,454,-625,517,-436,377,-573,589,-486,487,-462,458,-310,323,-376,477,-498,675,-342,454,-653,618,-550,454,-549,409,-492,659,-621,678,-499,447,-414,508,-419,354,-446,379,-609,568,-740,599,-542,456,-491,398,-374,365,-425,472,-446,421,-460,460,-586,529,-387,404,-599,548,-464,411,-410,369,-300,253,-454,444,-369,369,-441,374,-244,314,-467,428,-410,400,-310,450,-508,382,-373,414,-300,368,-364,374,-439,356,-440,472,-351,332,-429,348,-291,308,-336,318,-386,338,-350,364,-276,329,-326,314,-311,308,-263,286,-279,357,-283,349,-260,284,-317,300,-252,224,-230,204,-293,288,-300,399,-221,297,-404,372,-297,161,-178,270,-257,317,-270,253,-325,305,-257,225,-388,326,-220,211,-240,239,-277,307,-267,301,-331,327,-171,297,-270,316,-226,217,-338,319,-273,326,-224,232,-282,230,-239,216,-279,244,-235,229,-392,327,-333,275,-246,217,-253,215,-258,247,-169,213,-239,252,-212,217,-304,303,-204,199,-160,202,-284,244,-264,355,-254,207,-209,181,-147,204,-245,222,-200,195,-199,239,-294,238,-200,210,-152,167,-182,183,-261,152,-175,167,-276,284,-225,173,-208,187,-210,206,-213,212,-176,169,-202,183,-131,143,-187,170,-217,231,-202,209,-215,194,-214,227,-270,232,-283,332,-124,181,-193,202,-291,294,-170,176,-203,267,-204,174,-202,183,-160,205,-155,159,-270,259,-132,144,-159,195,-221,201,-169,189,-212,216,-146,143,-158,171,-193,179,-154,178,-211,158,-148,149,-148,176,-194,175,-143,150,-177,193,-170,146,-142,136,-153,157,-166,153,-203,181,-154,185,-164,152,-161,149,-122,145,-169,113,-187,140,-210,188,-149,163,-134,118,-157,220,-78,90,-124,157,-142,94,-188,143,-100,88,-130,108,-180,171,-130,100,-128,169,-168,141,-136,152,-144,116,-90,98,-144,151,-109,106,-145,155,-62,118,-137,165,-173,156,-160,144,-87,86,-136,161,-119,178,-113,106,-85,99,-99,98,-84,71,-148,105,-135,115,-92,105,-100,78,-87,87,-84,84,-95,118,-79,84,-101,113,-93,98,-124,86,-105,99,-111,104,-99,119,-101,100,-98,106,-127,101,-96,86,-86,107,-104,99,-67,72,-92,99,-99,98,-101,135,-122,89,-111,124,-85,75,-113,122,-84,99,-82,83,-134,116,-55,71,-104,63,-90,89,-95,86,-80,74,-80,119,-100,78,-97,94,-82,76,-118,104,-139,157,-123,132,-99,96,-100,76,-80,92,-91,96,-80,72,-83,92,-93,79,-72,70,-55,49,-69,60,-72,65,-89,72,-98,62,-84,78,-60,70,-90,83,-83,80,-98,78,-82,62,-88,72,-73,87,-57,66,-96,87,-71,63,-75,64,-47,56,-92,50,-74,80,-48,64,-116,84,-63,70,-69,59,-73,71,-91,91,-62,58,-74,62,-65,62,-49,60,-50,51,-92,71,-103,80,-91,92,-56,58,-56,51,-75,75,-68,83,-69,74,-66,84,-80,71,-75,72,-60,46,-73,68,-46,50,-71,60,-39,48,-68,56,-69,77,-60,50,-71,66,-69,77,-64,74,-71,62,-69,51,-43,40,-44,52,-63,70,-53,50,-58,62,-76,79,-71,83,-65,65,-47,46,-82,86,-45,40,-27,35,-55,41,-37,33,-48,58,-50,50,-48,35,-34,35,-56,51,-49,48,-53,55,-73,55,-50,46,-35,37,-42,60,-37,27,-49,64,-65,39,-41,49,-54,56,-49,54,-41,37,-47,60,-33,50,-47,32,-44,39,-53,53,-46,35,-44,47,-34,39,-37,31,-53,50,-41,53,-42,48,-42,42,-33,30,-41,50,-61,43,-35,29,-54,48,-38,44,-35,27,-50,41,-50,30,-54,48,-41,45,-29,25,-34,27,-43,39,-44,41,-24,25,-29,35,-36,28,-35,38,-34,34,-41,26,-29,22,-37,34,-55,54,-35,35,-27,28,-45,34,-38,29,-39,48,-34,33,-47,40,-25,27,-35,25,-32,34,-32,41,-44,44,-34,21,-33,33,-39,40,-27,29,-38,49,-33,37,-28,29,-28,27,-26,27,-30,31,-28,23,-20,23,-32,34,-20,25,-21,20,-29,26,-31,26,-35,28,-28,31,-29,24,-21,14,-32,32,-25,23,-35,34,-27,25,-27,24,-19,19,-27,31,-36,22,-21,14,-31,36,-30,29,-32,29,-26,31,-31,27,-27,23,-17,12,-37,26,-27,15,-23,24,-21,22,-14,19,-26,19,-15,18,-29,27,-25,23,-18,18,-18,23,-21,21,-18,17,-29,24,-19,19,-24,15,-21,18,-19,16,-25,26,-17,17,-16,20,-15,17,-16,15,-22,15,-18,18,-19,21,-21,18,-21,15,-22,17,-22,17,-19,25,-25,22,-22,17,-18,19,-14,13,-17,17,-15,14,-22,22,-16,15,-25,19,-28,32,-15,18,-15,21,-19,21,-16,14,-16,17,-21,18,-16,15,-14,12,-14,15,-16,22,-22,27,-19,16,-25,19,-20,20,-22,19,-16,11,-12,11,-18,15,-22,18,-11,12,-18,15,-14,12,-18,13,-15,13,-16,12,-14,11,-13,11,-18,15,-14,12,-18,16,-12,12,-14,15,-23,17,-13,14,-13,12,-13,12,-13,11,-16,14,-11,10,-13,14,-16,16,-19,17,-15,17,-15,9,-10,12,-11,7,-15,11,-12,9,-13,14,-13,12,-15,12,-17,16,-12,11,-12,14,-13,14,-10,10,-13,11,-12,11,-14,11,-13,14,-13,11,-13,10,-17,14,-15,11,-8,8,-15,16,-16,11,-12,10,-11,10,-12,14,-9,8,-11,11,-18,15,-12,8,-8,10,-12,11,-9,7,-10,9,-12,11,-11,11,-9,7,-10,10,-9,9,-11,9,-9,9,-12,8,-9,9,-9,6,-11,10,-11,8,-9,8,-9,9,-12,13,-11,9,-14,14,-12,12,-12,9,-10,10,-11,12,-15,10,-11,7,-11,10,-11,11,-12,8,-11,10,-10,12,-12,10,-10,7,-8,7,-5,4,-7,5,-12,11,-10,9,-9,7,-9,7,-8,7,-10,10,-12,10,-10,9,-8,8,-8,6,-14,9,-8,6,-11,9,-7,6,-6,7,-12,11,-12,10,-10,8,-8,6,-9,8,-7,6,-8,5,-10,6,-8,7,-11,8,-6,5,-6,7,-7,4,-7,9,-5,4,-5,3,-7,4,-8,9,-8,6,-6,5,-5,5,-7,6,-7,6,-5,5,-8,7,-8,8,-4,5,-10,6,-5,3,-5,4,-5,4,-5,5,-8,4,-6,4,-6,6,-5,3,-8,6,-7,6,-7,5,-5,5,-7,6,-8,7,-5,3,-8,7,-5,5,-7,6,-8,5,-8,6,-5,4,-6,7,-6,5,-6,5,-5,4,-4,4,-5,5,-7,5,-6,6,-5,4,-4,3,-7,5,-5,3,-6,6,-6,6,-6,6,-5,4,-7,6,-8,6,-7,5,-6,6,-5,3,-4,4,-5,5,-4,4,-6,4,-5,6,-7,5,-3,3,-5,4,-5,4,-5,3,-5,3,-4,3,-4,4,-5,4,-5,4,-4,3,-3,3,-4,3,-5,5,-7,5,-5,5,-5,5,-4,3,-5,3,-4,3,-3,3,-3,2,-3,2,-5,5,-4,3,-5,4,-4,3,-4,3,-3,2,-3,3,-4,2,-5,4,-5,2,-4,2,-5,3,-4,3,-4,3,-2,1,-3,2,-3,2,-5,4,-4,2,-4,3,-5,3,-3,3,-4,2,-3,3,-3,2,-5,3,-2,2,-6,4,-5,4,-3,2,-5,4,-3,2,-3,2,-4,3,-4,4,-4,2,-4,2,-2,2,-3,2,-4,2,-4,4,-3,2,-3,2,-2,1,-2,2,-3,2,-3,3,-3,2,-2,2,-3,2,-3,2,-3,2,-3,3,-3,2,-3,2,-3,2,-2,1,-2,3,-3,1,-2,2,-4,3,-3,2,-3,3,-3,2,-3,2,-2,1,-2,1,-3,2,-2,2,-2,1,-3,1,-2,1,-3,2,-2,1,-2,1,-2,1,-3,2,-3,2,-4,3,-3,2,-3,2,-3,2,-2,1,-3,1,-2,2,-2,2,-2,1,-3,1,-3,2,-2,1,-3,1,-3,1,-3,1,-2,1,-2,1,-3,1,-3,2,-2,1,-2,1,-2,0,-2,1]}');
                
              //   currentRecordingTime = DateTime.now();
              //   duration = currentRecordingTime.difference(startRecordingTime);
              //   labelDuration = ( (duration.inHours) ).toString()+":"+( (duration.inMinutes) ).toString()+":"+(duration.inSeconds % 60).toString();

              //   setState(() {
                  
              //   });
                
              // }          

            },
            child: const Icon(Icons.menu, color: Color(0xFF800000),),
          ),
        );
    }

    // if (lastPositionButton != null){
    // if ()
    // {
    // }

    // if (settingDialogButton != null){
    {
      settingDialogButton = Positioned(
        top:10,
        left:10,
        child:Container(
          key: keyTutorialSetting,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(50, 50),
              shape : const CircleBorder(),
              shadowColor: Colors.blue,

              primary: Colors.white,
              onPrimary: Colors.green,
              onSurface: Colors.red,
            ),
            child: Icon(Icons.settings, color: Color(0xFF800000),),
            onPressed: () {  

              if (deviceType == 0){
                _sendAnalyticsEvent("button_setting", {
                  "device":"Audio",
                  "deviceType":deviceType,
                });
                bool enableDeviceLegacy = settingParams["enableDeviceLegacy"] as bool;
                showCustomAudioDialog(context, settingParams).then((params){
                  try{
                    print("params");
                    print(params);
                    if (params == null) return;

                    settingParams = params;

                    if (params["enableDeviceLegacy"] != enableDeviceLegacy){
                      _sendAnalyticsEvent("enable_legacy_device", {"isEnableDeviceLegacy" : params["enableDeviceLegacy"]});
                    }
                    

                    channelsColor[0] = audioChannelColors[settingParams["defaultMicrophoneLeftColor"] as int];
                    channelsColor[1] = audioChannelColors[settingParams["defaultMicrophoneRightColor"] as int];
                    print("channelsColor[1] : "+channelsColor[1].toString());
                    // need to check again
                    if (channelsColor[1] != Color(0xff000000)){
                      var data = {
                        "channelCount":2,
                      };

                      js.context.callMethod('changeChannel', [json.encode(data)]);
                    }
                    

                    setState(() { });
                  }catch(err){
                    print("err 123");
                    print(err);
                  }
                });
              }else{
                if (deviceType == 1){
                  _sendAnalyticsEvent("button_setting", {
                    "device":"Serial",
                    "deviceType":deviceType,
                  });
                }else{
                  _sendAnalyticsEvent("button_setting", {
                    "device":"HID",
                    "deviceType":deviceType,
                  });
                }

                int prevChannelCount = settingParams["channelCount"] as int;
                if (prevChannelCount == -1){
                  settingParams['channelCount'] = 1;
                }else{
                  settingParams['channelCount'] = prevChannelCount;
                }
                
                if (extraChannels == 0){
                  settingParams["minSerialChannels"] = minChannels;
                  settingParams["maxSerialChannels"] = maxChannels;
                }else{
                  settingParams["minSerialChannels"] = minChannels;
                  settingParams["maxSerialChannels"] = extraChannels;
                }
                print("settingParams");
                print(minChannels);
                print(maxChannels);
                print(settingParams);
                if (deviceTypeInt == 2){
                  settingParams['deviceType'] = 'hid';
                  if (extraChannels == 0){
                    settingParams['channelCount'] = minChannels;
                  }else{
                    settingParams['channelCount'] = maxChannels;
                  }

                }else{
                  settingParams.remove('deviceType');
                }

                if (settingParams['maxSerialChannels'] as int > 5){
                  settingParams['displayChannelCount'] = true;
                }

                bool enableDeviceLegacy = settingParams["enableDeviceLegacy"] as bool;
                showCustomSerialDialog(context, settingParams).then((params){
                  // check with previous data
                  try{
                    settingParams.remove('displayChannelCount');

                    int val = params["channelCount"];
                    if (val != prevChannelCount){
                      var data = {
                        "channelCount":val,
                      };

                      js.context.callMethod('changeSerialChannel', [json.encode(data)]);
                    }

                    print(val.toString()+" @@ "+settingParams["channelCount"].toString());
                    if (params["enableDeviceLegacy"] != enableDeviceLegacy){
                      _sendAnalyticsEvent("enable_legacy_device", {"isEnableDeviceLegacy" : params["enableDeviceLegacy"]});
                    }

                    if (params['commandType'] == 'update'){
                      params.remove('commandType');
                      js.context.callMethod('updateFirmware', ['hid']);
                      setState(() {
                        
                      });
                      return;
                    }
                    if (params['deviceType'] == 'hid'){
                      deviceType = 2;
                      deviceTypeInt = 2;
                    }else{
                      deviceType = 1;
                      deviceTypeInt = 1;
                    }

                    // if (params['deviceType'] == 'hid'){
                    //   params.remove('deviceType');
                    //   deviceType = 1;
                    //   isPlaying = 1;
                    //   startRecordingTime = (DateTime.now());
                    //   channelGains = [1000,1000,1000,1000,1000,1000];
                    //   js.context.callMethod('recordHid', ['Flutter is calling upon JavaScript!']);

                    //   if (params['commandType'] == 'update'){
                    //     params.remove('commandType');
                    //     js.context.callMethod('updateFirmware', ['hid']);
                    //   }


                    //   setState(() {
                        
                    //   });
                    //   return;

                    // }

                    settingParams = params;

                    channelsColor[0] = serialChannelColors[settingParams["defaultSerialColor1"] as int];
                    if (settingParams["channelCount"] as int >= 2) channelsColor[1] = serialChannelColors[settingParams["defaultSerialColor2"] as int];
                    if (settingParams["channelCount"] as int >= 3) channelsColor[2] = serialChannelColors[settingParams["defaultSerialColor3"] as int];
                    if (settingParams["channelCount"] as int >= 4) channelsColor[3] = serialChannelColors[settingParams["defaultSerialColor4"] as int];
                    if (settingParams["channelCount"] as int >= 5) channelsColor[4] = serialChannelColors[settingParams["defaultSerialColor5"] as int];
                    if (settingParams["channelCount"] as int >= 6) channelsColor[5] = serialChannelColors[settingParams["defaultSerialColor6"] as int];

                    js.context.callMethod('setFlagChannelDisplay', [settingParams["flagDisplay1"],settingParams["flagDisplay2"],settingParams["flagDisplay3"],settingParams["flagDisplay4"],settingParams["flagDisplay5"],settingParams["flagDisplay6"] ]);
                    setState(() { });

                  }catch(err){
                    print("err 12356");
                    print(err);
                  }
                });                  
              }


            },

          ),
        ),
      );
      
    }
  }

  @override
  void initState(){
    super.initState();
    getCachedWidget();
    
    // js.context.callMethod('getChromeVersion', ["getChromeVersion"]);

    Future.delayed(const Duration(seconds: 0), () async {
      _deviceData = <String, dynamic>{};

      horizontalDragX = MediaQuery.of(context).size.width - 100 -20;
      
      if (kIsWeb) {
        _deviceData = _readWebBrowserInfo(await deviceInfoPlugin.webBrowserInfo);
        // print("_deviceData");
        // print(_deviceData);
      //         'deviceMemory': data.deviceMemory,
      // 'hardwareConcurrency': data.hardwareConcurrency,
      // 'maxTouchPoints': data.maxTouchPoints,

        String details = "_UserAgent : " + _deviceData['userAgent'].toString()+"_Memory : " + _deviceData['deviceMemory'].toString() + "_Concurrency:" + _deviceData['hardwareConcurrency'].toString()+ "_TouchPoints : " + _deviceData['maxTouchPoints'].toString() ;
        print("details");
        print(details);
        ( await js.context.callMethod('setDeviceInfo', [ _deviceData['platform'].toString(), versionNumber.toString() , _deviceData['appVersion'].toString(), details ]) );
      }
      await analytics.logAppOpen();

      // ( await js.context.callMethod('getChromeVersion', ["getChromeVersion"]) );
      // print (str);
      // globalChromeVersion = str;

    });

   
    // arrScaleBar = List.from(arrScaleBar.reversed);
    // print(arrScaleBar);
    // [6, 6.6, 7.2, 7.8, 8.4, 9, 9.6, 10.2, 10.8, 11.4, 12, 16.8, 21.6, 26.4, 31.2, 36, 40.8, 45.6, 50.4, 552, 60, 66, 72, 78, 84, 90, 96, 102, 108, 114, 120, 168, 216, 264, 312, 360, 408, 456, 504, 552, 600, 660, 720, 780, 840, 900, 960, 1020, 1080, 1140, 1200, 1680, 2160, 2640, 3120, 3600, 4080, 4560, 5040, 5520, 6000, 11400, 16800, 22200, 27600, 33000, 38400, 43800, 49200, 54600, 60000, 114000, 168000, 222000, 276000, 330000, 384000, 438000, 492000, 546000, 600000]
    const arrTimeScale = [0.1,1, 10,50, 100,500, 1000,5000,10000];
    int transformScale = (timeScaleBar / 10).floor();
    // scaleBarWidth = MediaQuery.of(context).size.width / arrTimeScale[transformScale] * arrScaleBar[timeScaleBar]/600 ;
    scaleBarWidth = MediaQuery.of(context).size.width / (arrScaleBar[timeScaleBar]) * arrTimeScale[transformScale]/10;
    // print("arrScaleBar[timeScaleBar]");
    // print(arrScaleBar[timeScaleBar]);
    // print("arrTimeScale[transformScale]/10");
    // print(arrTimeScale[transformScale]/10);
    
    SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
    // Uint8List list = new Uint8List(256);
    js.context['changeSampleRate'] = ( params ){
      sampleRate = params[0];
      curSkipCounts = params[1];
      curLevel = params[2];
      // frequency 1000 milisecond 44100 hz
      //frequency 10 ms = 441 hz
      // capacityMin = (sampleRate/timeScale).floor();
      // capacityMax = sampleRate*10;
      // capacity = capacityMin;

      // changeMaxAxis();

    };
    int idx= 0;
    int len= 0;
    
    
    capacityMin = (sampleRate/timeScale).floor();
    capacity = capacityMin;
    
    // sampleData = WaveformData(version: 1, channels: 1, sampleRate: 128, sampleSize: 128, bits: 1, length: 0, data: []);
    sampleData = WaveformData(version: 1, channels: 1, sampleRate: 44100, sampleSize: 1, bits: 16, length: 0, data: [-23254,16644,-30935,20205,-16593,16930,-11736,13287,-18606,13789,-10566,13918,-13824,14620,-11527,8676,-12231,15098,-11159,9512,-12696,14081,-10952,11740,-12275,11320,-10848,9477,-14906,17874,-11615,12593,-13266,11521,-16097,12726,-11027,11909,-13936,12957,-12427,13551,-13273,12631,-12068,12180,-16960,10204,-11003,15350,-9547,7862,-11642,9156,-12916,11414,-12254,12014,-10904,10699,-19290,17371,-18661,14840,-10483,7772,-12001,14139,-11743,12346,-8817,7486,-13723,12268,-12806,11932,-10766,9278,-14363,10833,-10968,10201,-7769,11178,-9181,10532,-11108,10264,-9397,9859,-10956,8993,-10164,9633,-9415,11935,-9315,7894,-11991,8480,-10056,9279,-11766,10108,-8676,9179,-6572,6416,-10415,8478,-9494,10295,-10625,10694,-12682,10206,-7907,7254,-8939,6862,-7444,7746,-9598,10933,-8451,7638,-9671,10051,-11103,8560,-8351,8265,-7618,10012,-9122,6387,-8906,6005,-7509,6537,-10554,8008,-9442,7675,-7059,5806,-8574,5545,-6884,6272,-8838,7777,-7123,6712,-6712,7930,-7544,7704,-7624,7634,-7423,9566,-10375,7497,-7437,6828,-8448,7644,-7928,7369,-5000,6147,-5130,6864,-8465,7033,-6381,5755,-6005,4566,-4916,5251,-5549,4577,-8633,8432,-5557,5441,-7610,6335,-6404,8627,-6402,5347,-6471,5600,-5128,5529,-6062,5212,-7089,4902,-4649,4729,-5128,4554,-5152,4176,-5765,3603,-5866,4989,-3389,4127,-5480,4420,-6319,5139,-4871,4421,-3887,5301,-5045,3809,-5203,3625,-4372,4901,-5183,4618,-5778,4335,-3816,3887,-4553,5277,-4152,3205,-3674,3579,-3696,3572,-3956,5101,-4741,5534,-5473,3850,-4049,3141,-4748,3341,-3427,4422,-4851,3985,-4356,4846,-3412,4368,-3631,4046,-3406,2807,-3376,4007,-3634,3886,-3689,3219,-2725,2106,-3044,3071,-3348,3085,-3919,3154,-4708,3611,-3795,3468,-2688,4142,-3358,2785,-3194,3590,-2778,2962,-2843,3011,-3312,3016,-3596,2896,-2266,2318,-2694,2653,-2403,2834,-2194,1972,-2739,2152,-2862,1949,-2803,3438,-2871,2196,-1829,2132,-2549,2528,-2377,1562,-2152,2535,-2630,2717,-2292,1672,-2840,2415,-2307,2046,-1984,1766,-2259,2241,-1898,1693,-1497,1362,-1639,1986,-1748,2077,-1815,1743,-1906,1791,-1610,1541,-1629,1726,-1522,1478,-1665,1841,-1872,1383,-2102,1654,-2218,1754,-1710,1342,-1383,1168,-1351,1371,-1122,1323,-1633,1467,-1011,1221,-1144,1533,-1512,2114,-1038,687,-1687,1691,-1081,1380,-1671,1373,-1489,957,-1635,1308,-1142,975,-1216,1315,-1038,1183,-1632,1497,-1265,1182,-896,1011,-1273,965,-946,1027,-913,983,-1194,1121,-1206,1065,-1218,1070,-745,883,-997,1082,-1454,1274,-1188,1147,-1228,1031,-720,767,-1287,1075,-663,727,-607,903,-961,1347,-779,761,-1336,1049,-892,861,-1114,1363,-942,1068,-1154,1125,-784,924,-774,822,-905,860,-825,854,-551,509,-566,597,-932,739,-776,868,-665,638,-466,647,-541,667,-887,873,-891,812,-570,803,-762,716,-542,788,-618,941,-577,681,-648,883,-778,705,-820,880,-749,699,-738,903,-875,1091,-745,747,-576,528,-611,641,-548,630,-501,454,-625,517,-436,377,-573,589,-486,487,-462,458,-310,323,-376,477,-498,675,-342,454,-653,618,-550,454,-549,409,-492,659,-621,678,-499,447,-414,508,-419,354,-446,379,-609,568,-740,599,-542,456,-491,398,-374,365,-425,472,-446,421,-460,460,-586,529,-387,404,-599,548,-464,411,-410,369,-300,253,-454,444,-369,369,-441,374,-244,314,-467,428,-410,400,-310,450,-508,382,-373,414,-300,368,-364,374,-439,356,-440,472,-351,332,-429,348,-291,308,-336,318,-386,338,-350,364,-276,329,-326,314,-311,308,-263,286,-279,357,-283,349,-260,284,-317,300,-252,224,-230,204,-293,288,-300,399,-221,297,-404,372,-297,161,-178,270,-257,317,-270,253,-325,305,-257,225,-388,326,-220,211,-240,239,-277,307,-267,301,-331,327,-171,297,-270,316,-226,217,-338,319,-273,326,-224,232,-282,230,-239,216,-279,244,-235,229,-392,327,-333,275,-246,217,-253,215,-258,247,-169,213,-239,252,-212,217,-304,303,-204,199,-160,202,-284,244,-264,355,-254,207,-209,181,-147,204,-245,222,-200,195,-199,239,-294,238,-200,210,-152,167,-182,183,-261,152,-175,167,-276,284,-225,173,-208,187,-210,206,-213,212,-176,169,-202,183,-131,143,-187,170,-217,231,-202,209,-215,194,-214,227,-270,232,-283,332,-124,181,-193,202,-291,294,-170,176,-203,267,-204,174,-202,183,-160,205,-155,159,-270,259,-132,144,-159,195,-221,201,-169,189,-212,216,-146,143,-158,171,-193,179,-154,178,-211,158,-148,149,-148,176,-194,175,-143,150,-177,193,-170,146,-142,136,-153,157,-166,153,-203,181,-154,185,-164,152,-161,149,-122,145,-169,113,-187,140,-210,188,-149,163,-134,118,-157,220,-78,90,-124,157,-142,94,-188,143,-100,88,-130,108,-180,171,-130,100,-128,169,-168,141,-136,152,-144,116,-90,98,-144,151,-109,106,-145,155,-62,118,-137,165,-173,156,-160,144,-87,86,-136,161,-119,178,-113,106,-85,99,-99,98,-84,71,-148,105,-135,115,-92,105,-100,78,-87,87,-84,84,-95,118,-79,84,-101,113,-93,98,-124,86,-105,99,-111,104,-99,119,-101,100,-98,106,-127,101,-96,86,-86,107,-104,99,-67,72,-92,99,-99,98,-101,135,-122,89,-111,124,-85,75,-113,122,-84,99,-82,83,-134,116,-55,71,-104,63,-90,89,-95,86,-80,74,-80,119,-100,78,-97,94,-82,76,-118,104,-139,157,-123,132,-99,96,-100,76,-80,92,-91,96,-80,72,-83,92,-93,79,-72,70,-55,49,-69,60,-72,65,-89,72,-98,62,-84,78,-60,70,-90,83,-83,80,-98,78,-82,62,-88,72,-73,87,-57,66,-96,87,-71,63,-75,64,-47,56,-92,50,-74,80,-48,64,-116,84,-63,70,-69,59,-73,71,-91,91,-62,58,-74,62,-65,62,-49,60,-50,51,-92,71,-103,80,-91,92,-56,58,-56,51,-75,75,-68,83,-69,74,-66,84,-80,71,-75,72,-60,46,-73,68,-46,50,-71,60,-39,48,-68,56,-69,77,-60,50,-71,66,-69,77,-64,74,-71,62,-69,51,-43,40,-44,52,-63,70,-53,50,-58,62,-76,79,-71,83,-65,65,-47,46,-82,86,-45,40,-27,35,-55,41,-37,33,-48,58,-50,50,-48,35,-34,35,-56,51,-49,48,-53,55,-73,55,-50,46,-35,37,-42,60,-37,27,-49,64,-65,39,-41,49,-54,56,-49,54,-41,37,-47,60,-33,50,-47,32,-44,39,-53,53,-46,35,-44,47,-34,39,-37,31,-53,50,-41,53,-42,48,-42,42,-33,30,-41,50,-61,43,-35,29,-54,48,-38,44,-35,27,-50,41,-50,30,-54,48,-41,45,-29,25,-34,27,-43,39,-44,41,-24,25,-29,35,-36,28,-35,38,-34,34,-41,26,-29,22,-37,34,-55,54,-35,35,-27,28,-45,34,-38,29,-39,48,-34,33,-47,40,-25,27,-35,25,-32,34,-32,41,-44,44,-34,21,-33,33,-39,40,-27,29,-38,49,-33,37,-28,29,-28,27,-26,27,-30,31,-28,23,-20,23,-32,34,-20,25,-21,20,-29,26,-31,26,-35,28,-28,31,-29,24,-21,14,-32,32,-25,23,-35,34,-27,25,-27,24,-19,19,-27,31,-36,22,-21,14,-31,36,-30,29,-32,29,-26,31,-31,27,-27,23,-17,12,-37,26,-27,15,-23,24,-21,22,-14,19,-26,19,-15,18,-29,27,-25,23,-18,18,-18,23,-21,21,-18,17,-29,24,-19,19,-24,15,-21,18,-19,16,-25,26,-17,17,-16,20,-15,17,-16,15,-22,15,-18,18,-19,21,-21,18,-21,15,-22,17,-22,17,-19,25,-25,22,-22,17,-18,19,-14,13,-17,17,-15,14,-22,22,-16,15,-25,19,-28,32,-15,18,-15,21,-19,21,-16,14,-16,17,-21,18,-16,15,-14,12,-14,15,-16,22,-22,27,-19,16,-25,19,-20,20,-22,19,-16,11,-12,11,-18,15,-22,18,-11,12,-18,15,-14,12,-18,13,-15,13,-16,12,-14,11,-13,11,-18,15,-14,12,-18,16,-12,12,-14,15,-23,17,-13,14,-13,12,-13,12,-13,11,-16,14,-11,10,-13,14,-16,16,-19,17,-15,17,-15,9,-10,12,-11,7,-15,11,-12,9,-13,14,-13,12,-15,12,-17,16,-12,11,-12,14,-13,14,-10,10,-13,11,-12,11,-14,11,-13,14,-13,11,-13,10,-17,14,-15,11,-8,8,-15,16,-16,11,-12,10,-11,10,-12,14,-9,8,-11,11,-18,15,-12,8,-8,10,-12,11,-9,7,-10,9,-12,11,-11,11,-9,7,-10,10,-9,9,-11,9,-9,9,-12,8,-9,9,-9,6,-11,10,-11,8,-9,8,-9,9,-12,13,-11,9,-14,14,-12,12,-12,9,-10,10,-11,12,-15,10,-11,7,-11,10,-11,11,-12,8,-11,10,-10,12,-12,10,-10,7,-8,7,-5,4,-7,5,-12,11,-10,9,-9,7,-9,7,-8,7,-10,10,-12,10,-10,9,-8,8,-8,6,-14,9,-8,6,-11,9,-7,6,-6,7,-12,11,-12,10,-10,8,-8,6,-9,8,-7,6,-8,5,-10,6,-8,7,-11,8,-6,5,-6,7,-7,4,-7,9,-5,4,-5,3,-7,4,-8,9,-8,6,-6,5,-5,5,-7,6,-7,6,-5,5,-8,7,-8,8,-4,5,-10,6,-5,3,-5,4,-5,4,-5,5,-8,4,-6,4,-6,6,-5,3,-8,6,-7,6,-7,5,-5,5,-7,6,-8,7,-5,3,-8,7,-5,5,-7,6,-8,5,-8,6,-5,4,-6,7,-6,5,-6,5,-5,4,-4,4,-5,5,-7,5,-6,6,-5,4,-4,3,-7,5,-5,3,-6,6,-6,6,-6,6,-5,4,-7,6,-8,6,-7,5,-6,6,-5,3,-4,4,-5,5,-4,4,-6,4,-5,6,-7,5,-3,3,-5,4,-5,4,-5,3,-5,3,-4,3,-4,4,-5,4,-5,4,-4,3,-3,3,-4,3,-5,5,-7,5,-5,5,-5,5,-4,3,-5,3,-4,3,-3,3,-3,2,-3,2,-5,5,-4,3,-5,4,-4,3,-4,3,-3,2,-3,3,-4,2,-5,4,-5,2,-4,2,-5,3,-4,3,-4,3,-2,1,-3,2,-3,2,-5,4,-4,2,-4,3,-5,3,-3,3,-4,2,-3,3,-3,2,-5,3,-2,2,-6,4,-5,4,-3,2,-5,4,-3,2,-3,2,-4,3,-4,4,-4,2,-4,2,-2,2,-3,2,-4,2,-4,4,-3,2,-3,2,-2,1,-2,2,-3,2,-3,3,-3,2,-2,2,-3,2,-3,2,-3,2,-3,3,-3,2,-3,2,-3,2,-2,1,-2,3,-3,1,-2,2,-4,3,-3,2,-3,3,-3,2,-3,2,-2,1,-2,1,-3,2,-2,2,-2,1,-3,1,-2,1,-3,2,-2,1,-2,1,-2,1,-3,2,-3,2,-4,3,-3,2,-3,2,-3,2,-2,1,-3,1,-2,2,-2,2,-2,1,-3,1,-3,2,-2,1,-3,1,-3,1,-3,1,-2,1,-2,1,-3,1,-3,2,-2,1,-2,1,-2,0,-2,1]);
    // sampleData = WaveformData.fromJson('{"version":2,"channels":1,"sample_rate":44100,"samples_per_pixel":64,"bits":16,"length":1034,"data":[-23254,16644,-30935,20205,-16593,16930,-11736,13287,-18606,13789,-10566,13918,-13824,14620,-11527,8676,-12231,15098,-11159,9512,-12696,14081,-10952,11740,-12275,11320,-10848,9477,-14906,17874,-11615,12593,-13266,11521,-16097,12726,-11027,11909,-13936,12957,-12427,13551,-13273,12631,-12068,12180,-16960,10204,-11003,15350,-9547,7862,-11642,9156,-12916,11414,-12254,12014,-10904,10699,-19290,17371,-18661,14840,-10483,7772,-12001,14139,-11743,12346,-8817,7486,-13723,12268,-12806,11932,-10766,9278,-14363,10833,-10968,10201,-7769,11178,-9181,10532,-11108,10264,-9397,9859,-10956,8993,-10164,9633,-9415,11935,-9315,7894,-11991,8480,-10056,9279,-11766,10108,-8676,9179,-6572,6416,-10415,8478,-9494,10295,-10625,10694,-12682,10206,-7907,7254,-8939,6862,-7444,7746,-9598,10933,-8451,7638,-9671,10051,-11103,8560,-8351,8265,-7618,10012,-9122,6387,-8906,6005,-7509,6537,-10554,8008,-9442,7675,-7059,5806,-8574,5545,-6884,6272,-8838,7777,-7123,6712,-6712,7930,-7544,7704,-7624,7634,-7423,9566,-10375,7497,-7437,6828,-8448,7644,-7928,7369,-5000,6147,-5130,6864,-8465,7033,-6381,5755,-6005,4566,-4916,5251,-5549,4577,-8633,8432,-5557,5441,-7610,6335,-6404,8627,-6402,5347,-6471,5600,-5128,5529,-6062,5212,-7089,4902,-4649,4729,-5128,4554,-5152,4176,-5765,3603,-5866,4989,-3389,4127,-5480,4420,-6319,5139,-4871,4421,-3887,5301,-5045,3809,-5203,3625,-4372,4901,-5183,4618,-5778,4335,-3816,3887,-4553,5277,-4152,3205,-3674,3579,-3696,3572,-3956,5101,-4741,5534,-5473,3850,-4049,3141,-4748,3341,-3427,4422,-4851,3985,-4356,4846,-3412,4368,-3631,4046,-3406,2807,-3376,4007,-3634,3886,-3689,3219,-2725,2106,-3044,3071,-3348,3085,-3919,3154,-4708,3611,-3795,3468,-2688,4142,-3358,2785,-3194,3590,-2778,2962,-2843,3011,-3312,3016,-3596,2896,-2266,2318,-2694,2653,-2403,2834,-2194,1972,-2739,2152,-2862,1949,-2803,3438,-2871,2196,-1829,2132,-2549,2528,-2377,1562,-2152,2535,-2630,2717,-2292,1672,-2840,2415,-2307,2046,-1984,1766,-2259,2241,-1898,1693,-1497,1362,-1639,1986,-1748,2077,-1815,1743,-1906,1791,-1610,1541,-1629,1726,-1522,1478,-1665,1841,-1872,1383,-2102,1654,-2218,1754,-1710,1342,-1383,1168,-1351,1371,-1122,1323,-1633,1467,-1011,1221,-1144,1533,-1512,2114,-1038,687,-1687,1691,-1081,1380,-1671,1373,-1489,957,-1635,1308,-1142,975,-1216,1315,-1038,1183,-1632,1497,-1265,1182,-896,1011,-1273,965,-946,1027,-913,983,-1194,1121,-1206,1065,-1218,1070,-745,883,-997,1082,-1454,1274,-1188,1147,-1228,1031,-720,767,-1287,1075,-663,727,-607,903,-961,1347,-779,761,-1336,1049,-892,861,-1114,1363,-942,1068,-1154,1125,-784,924,-774,822,-905,860,-825,854,-551,509,-566,597,-932,739,-776,868,-665,638,-466,647,-541,667,-887,873,-891,812,-570,803,-762,716,-542,788,-618,941,-577,681,-648,883,-778,705,-820,880,-749,699,-738,903,-875,1091,-745,747,-576,528,-611,641,-548,630,-501,454,-625,517,-436,377,-573,589,-486,487,-462,458,-310,323,-376,477,-498,675,-342,454,-653,618,-550,454,-549,409,-492,659,-621,678,-499,447,-414,508,-419,354,-446,379,-609,568,-740,599,-542,456,-491,398,-374,365,-425,472,-446,421,-460,460,-586,529,-387,404,-599,548,-464,411,-410,369,-300,253,-454,444,-369,369,-441,374,-244,314,-467,428,-410,400,-310,450,-508,382,-373,414,-300,368,-364,374,-439,356,-440,472,-351,332,-429,348,-291,308,-336,318,-386,338,-350,364,-276,329,-326,314,-311,308,-263,286,-279,357,-283,349,-260,284,-317,300,-252,224,-230,204,-293,288,-300,399,-221,297,-404,372,-297,161,-178,270,-257,317,-270,253,-325,305,-257,225,-388,326,-220,211,-240,239,-277,307,-267,301,-331,327,-171,297,-270,316,-226,217,-338,319,-273,326,-224,232,-282,230,-239,216,-279,244,-235,229,-392,327,-333,275,-246,217,-253,215,-258,247,-169,213,-239,252,-212,217,-304,303,-204,199,-160,202,-284,244,-264,355,-254,207,-209,181,-147,204,-245,222,-200,195,-199,239,-294,238,-200,210,-152,167,-182,183,-261,152,-175,167,-276,284,-225,173,-208,187,-210,206,-213,212,-176,169,-202,183,-131,143,-187,170,-217,231,-202,209,-215,194,-214,227,-270,232,-283,332,-124,181,-193,202,-291,294,-170,176,-203,267,-204,174,-202,183,-160,205,-155,159,-270,259,-132,144,-159,195,-221,201,-169,189,-212,216,-146,143,-158,171,-193,179,-154,178,-211,158,-148,149,-148,176,-194,175,-143,150,-177,193,-170,146,-142,136,-153,157,-166,153,-203,181,-154,185,-164,152,-161,149,-122,145,-169,113,-187,140,-210,188,-149,163,-134,118,-157,220,-78,90,-124,157,-142,94,-188,143,-100,88,-130,108,-180,171,-130,100,-128,169,-168,141,-136,152,-144,116,-90,98,-144,151,-109,106,-145,155,-62,118,-137,165,-173,156,-160,144,-87,86,-136,161,-119,178,-113,106,-85,99,-99,98,-84,71,-148,105,-135,115,-92,105,-100,78,-87,87,-84,84,-95,118,-79,84,-101,113,-93,98,-124,86,-105,99,-111,104,-99,119,-101,100,-98,106,-127,101,-96,86,-86,107,-104,99,-67,72,-92,99,-99,98,-101,135,-122,89,-111,124,-85,75,-113,122,-84,99,-82,83,-134,116,-55,71,-104,63,-90,89,-95,86,-80,74,-80,119,-100,78,-97,94,-82,76,-118,104,-139,157,-123,132,-99,96,-100,76,-80,92,-91,96,-80,72,-83,92,-93,79,-72,70,-55,49,-69,60,-72,65,-89,72,-98,62,-84,78,-60,70,-90,83,-83,80,-98,78,-82,62,-88,72,-73,87,-57,66,-96,87,-71,63,-75,64,-47,56,-92,50,-74,80,-48,64,-116,84,-63,70,-69,59,-73,71,-91,91,-62,58,-74,62,-65,62,-49,60,-50,51,-92,71,-103,80,-91,92,-56,58,-56,51,-75,75,-68,83,-69,74,-66,84,-80,71,-75,72,-60,46,-73,68,-46,50,-71,60,-39,48,-68,56,-69,77,-60,50,-71,66,-69,77,-64,74,-71,62,-69,51,-43,40,-44,52,-63,70,-53,50,-58,62,-76,79,-71,83,-65,65,-47,46,-82,86,-45,40,-27,35,-55,41,-37,33,-48,58,-50,50,-48,35,-34,35,-56,51,-49,48,-53,55,-73,55,-50,46,-35,37,-42,60,-37,27,-49,64,-65,39,-41,49,-54,56,-49,54,-41,37,-47,60,-33,50,-47,32,-44,39,-53,53,-46,35,-44,47,-34,39,-37,31,-53,50,-41,53,-42,48,-42,42,-33,30,-41,50,-61,43,-35,29,-54,48,-38,44,-35,27,-50,41,-50,30,-54,48,-41,45,-29,25,-34,27,-43,39,-44,41,-24,25,-29,35,-36,28,-35,38,-34,34,-41,26,-29,22,-37,34,-55,54,-35,35,-27,28,-45,34,-38,29,-39,48,-34,33,-47,40,-25,27,-35,25,-32,34,-32,41,-44,44,-34,21,-33,33,-39,40,-27,29,-38,49,-33,37,-28,29,-28,27,-26,27,-30,31,-28,23,-20,23,-32,34,-20,25,-21,20,-29,26,-31,26,-35,28,-28,31,-29,24,-21,14,-32,32,-25,23,-35,34,-27,25,-27,24,-19,19,-27,31,-36,22,-21,14,-31,36,-30,29,-32,29,-26,31,-31,27,-27,23,-17,12,-37,26,-27,15,-23,24,-21,22,-14,19,-26,19,-15,18,-29,27,-25,23,-18,18,-18,23,-21,21,-18,17,-29,24,-19,19,-24,15,-21,18,-19,16,-25,26,-17,17,-16,20,-15,17,-16,15,-22,15,-18,18,-19,21,-21,18,-21,15,-22,17,-22,17,-19,25,-25,22,-22,17,-18,19,-14,13,-17,17,-15,14,-22,22,-16,15,-25,19,-28,32,-15,18,-15,21,-19,21,-16,14,-16,17,-21,18,-16,15,-14,12,-14,15,-16,22,-22,27,-19,16,-25,19,-20,20,-22,19,-16,11,-12,11,-18,15,-22,18,-11,12,-18,15,-14,12,-18,13,-15,13,-16,12,-14,11,-13,11,-18,15,-14,12,-18,16,-12,12,-14,15,-23,17,-13,14,-13,12,-13,12,-13,11,-16,14,-11,10,-13,14,-16,16,-19,17,-15,17,-15,9,-10,12,-11,7,-15,11,-12,9,-13,14,-13,12,-15,12,-17,16,-12,11,-12,14,-13,14,-10,10,-13,11,-12,11,-14,11,-13,14,-13,11,-13,10,-17,14,-15,11,-8,8,-15,16,-16,11,-12,10,-11,10,-12,14,-9,8,-11,11,-18,15,-12,8,-8,10,-12,11,-9,7,-10,9,-12,11,-11,11,-9,7,-10,10,-9,9,-11,9,-9,9,-12,8,-9,9,-9,6,-11,10,-11,8,-9,8,-9,9,-12,13,-11,9,-14,14,-12,12,-12,9,-10,10,-11,12,-15,10,-11,7,-11,10,-11,11,-12,8,-11,10,-10,12,-12,10,-10,7,-8,7,-5,4,-7,5,-12,11,-10,9,-9,7,-9,7,-8,7,-10,10,-12,10,-10,9,-8,8,-8,6,-14,9,-8,6,-11,9,-7,6,-6,7,-12,11,-12,10,-10,8,-8,6,-9,8,-7,6,-8,5,-10,6,-8,7,-11,8,-6,5,-6,7,-7,4,-7,9,-5,4,-5,3,-7,4,-8,9,-8,6,-6,5,-5,5,-7,6,-7,6,-5,5,-8,7,-8,8,-4,5,-10,6,-5,3,-5,4,-5,4,-5,5,-8,4,-6,4,-6,6,-5,3,-8,6,-7,6,-7,5,-5,5,-7,6,-8,7,-5,3,-8,7,-5,5,-7,6,-8,5,-8,6,-5,4,-6,7,-6,5,-6,5,-5,4,-4,4,-5,5,-7,5,-6,6,-5,4,-4,3,-7,5,-5,3,-6,6,-6,6,-6,6,-5,4,-7,6,-8,6,-7,5,-6,6,-5,3,-4,4,-5,5,-4,4,-6,4,-5,6,-7,5,-3,3,-5,4,-5,4,-5,3,-5,3,-4,3,-4,4,-5,4,-5,4,-4,3,-3,3,-4,3,-5,5,-7,5,-5,5,-5,5,-4,3,-5,3,-4,3,-3,3,-3,2,-3,2,-5,5,-4,3,-5,4,-4,3,-4,3,-3,2,-3,3,-4,2,-5,4,-5,2,-4,2,-5,3,-4,3,-4,3,-2,1,-3,2,-3,2,-5,4,-4,2,-4,3,-5,3,-3,3,-4,2,-3,3,-3,2,-5,3,-2,2,-6,4,-5,4,-3,2,-5,4,-3,2,-3,2,-4,3,-4,4,-4,2,-4,2,-2,2,-3,2,-4,2,-4,4,-3,2,-3,2,-2,1,-2,2,-3,2,-3,3,-3,2,-2,2,-3,2,-3,2,-3,2,-3,3,-3,2,-3,2,-3,2,-2,1,-2,3,-3,1,-2,2,-4,3,-3,2,-3,3,-3,2,-3,2,-2,1,-2,1,-3,2,-2,2,-2,1,-3,1,-2,1,-3,2,-2,1,-2,1,-2,1,-3,2,-3,2,-4,3,-3,2,-3,2,-3,2,-2,1,-3,1,-2,2,-2,2,-2,1,-3,1,-3,2,-2,1,-3,1,-3,1,-3,1,-2,1,-2,1,-3,1,-3,2,-2,1,-2,1,-2,0,-2,1]}');    
    js.context['jsToDart'] = js2Dart;
    js.context['callbackErrorLog'] = callbackErrorLog;
    js.context['callbackSerialInit'] = callbackSerialInit;
    js.context['callbackAudioInit'] = callbackAudioInit;
    js.context['callbackGetDeviceInfo'] = callbackGetDeviceInfo;
    js.context['callbackOpenWavFile'] = callbackOpenWavFile;
    js.context['callbackOpeningFile'] = callbackOpeningFile;
    js.context['callbackIsOpeningWavFile'] = callbackIsOpeningWavFile;
    js.context['changeResetPlayback'] = changeResetPlayback;
    js.context['resetToAudio'] = resetToAudio;
    js.context['drawEventMarkers'] = drawEventMarkers;
    js.context['drawElapsedTime'] = drawElapsedTime;
    js.context['changeTimeBarStatus'] = changeTimeBarStatus;
    js.context['callbackSetRecording'] = callbackSetRecording;
    js.context['callbackGetChromeVersion'] = callbackGetChromeVersion;
    js.context['callbackHorizontalDiff'] = callbackHorizontalDiff;
    js.context['callAlert'] = callAlert;
    
    js.context['changePlaybackButton'] = changePlaybackButton;
    // chartData = [];

    chartData = [0.00014653186372015625, 0.00016304542077705264];
    storage.ready.then((flag){
      isTutored = storage.getItem('isTutored') == null ? '0':'1';
      // print(storage.getItem('isTutored'));
      // print(storage.getItem('isTutored') != null);
      print("isTutored : " + isTutored.toString());
      print("isTutored? : " + (isTutored.toString() != '0').toString() );
      // isTutored = '0';
      if ( isTutored == '1'){
        Future.delayed(const Duration(seconds: 2), (){
          isPlaying = 1;
          js.context.callMethod('recordAudio', ['Flutter is calling upon JavaScript!']);
          setState(() {        
          });
        });
      }else{
        // storage.setItem('isTutored', '1');
        // tutorialCoachMark.show();
        Future.delayed(const Duration(seconds: 1), (){
          showTutorial();
        });
      }
      
      setState((){});

    });

  }

  void initTargets(){
    targets.clear();
    targets.add(
      TargetFocus(
        identify: "keyTutorialNavigation",
        keyTarget: keyTutorialNavigation,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                  ],
                ),
              );
            },
          ),
        ],
      ),    
    );

    targets.add(
      TargetFocus(
        identify: "keyTutorialAudio",
        keyTarget: keyTutorialAudio,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return Container(
                margin: EdgeInsets.only(top:50),
                child: Text( "", style: TextStyle(color: Colors.white) )
              );
            },
          ),
        ],
      ),    
    );    


  // GlobalKey keyTutorialSerial = GlobalKey();
  // GlobalKey keyTutorialHid = GlobalKey();
  // GlobalKey keyTutorialSetting = GlobalKey();
  // GlobalKey keyTutorialTimescale = GlobalKey();

    targets.add(
      TargetFocus(
        identify: "keyTutorialSerial",
        keyTarget: keyTutorialSerial,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                children: [
                  // Text( "To start, make sure the device is connected, so it can be listed here when clicked", style: TextStyle(fontSize:15, color: Colors.white) ),
                  Text( "To start, make sure your recording device is connected to your computer. If it is, it will show up in the USB connection list", style: TextStyle(fontSize:15, color: Colors.white) ),
                  Text( "Click the USB button and find your device. If you don’t know which one it is, disconnect the device and click it again. The one that disappeared is your device!", style: TextStyle(fontSize:15, color: Colors.white) ),
                  Text( "Click the USB button to proceed.", style: TextStyle(fontSize:12, color: Colors.white) )
                ]
              );
            },
          ),
        ],
      ),    
    );    

    // targets.add(
    //   TargetFocus(
    //     identify: "keyTutorialHid",
    //     keyTarget: keyTutorialHid,
    //     alignSkip: Alignment.bottomLeft,
    //     contents: [
    //       TargetContent(
    //         align: ContentAlign.bottom,
    //         builder: (context, controller) {
    //           return Column(
    //             children: [
    //               Text( "To start, make sure your recording device is connected to your computer. If it is, it will show up in the Pro connection list", style: TextStyle(fontSize:15, color: Colors.white) ),
    //               Text( "Click the PRO button and find your device. If you don’t know which one it is, disconnect the device and click it again. The one that disappeared is your device!", style: TextStyle(fontSize:15, color: Colors.white) ),
    //               Text( "Click the PRO button to proceed.", style: TextStyle(fontSize:12, color: Colors.white) )
    //             ]
    //           );
    //         },
    //       ),
    //     ],
    //   ),    
    // );

    targets.add(
      TargetFocus(
        identify: "keyTutorialSetting",
        keyTarget: keyTutorialSetting,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                children: [
                  Text( "Open settings to change the number of channels, line thickness and color of the graph.", style: TextStyle(fontSize:15, color: Colors.white) ),
                  Text( "Press the settings button to continue.", style: TextStyle(fontSize:12, color: Colors.white) )
                ]
              );

              // return Container(
              //   child: Text( "The setting page may differ, according current device sampled", style: TextStyle(color: Colors.white) )
              // );
            },
          ),
        ],
      ),    
    );   

    targets.add(
      TargetFocus(
        identify: "keyTutorialTimescale",
        keyTarget: keyTutorialTimescale,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Padding(
                padding: const EdgeInsets.only(top:50.0,left:100, right:100, bottom:20,),
                child: Column(
                  children: [
                    Text( "Time Scale", style: TextStyle(fontWeight:FontWeight.bold,fontSize:17, color: Colors.white) ),
                    Text( "Use your trackpad or mouse wheel to adjust the time scale. You can also adjust it by dragging up and down and releasing.", style: TextStyle(fontSize:12, color: Colors.white) ),
                    SizedBox(height: 10),
                    Text( "Click on the time scale to proceed", style: TextStyle(fontSize:12, color: Colors.white) ),                    
                  ],
                ),
              );
            },
          ),
        ],
      ),    
    ); 





    targets.add(
      TargetFocus(
        identify: "keyTutorialEnd",
        keyTarget: keyTutorialEnd,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Padding(
                padding: const EdgeInsets.only(top:50.0,left:100, right:100, bottom:20,),
                child: Column(
                  children: [
                    Text( "That's All", style: TextStyle(fontWeight:FontWeight.bold,fontSize:17, color: Colors.white) ),
                    Text( "Thank you for following the tutorial, we hope that you will enjoy using the app!", style: TextStyle(fontSize:12, color: Colors.white) ),
                    // SizedBox(height: 10),
                    // Text( "Note:", style: TextStyle(fontSize:12, color: Colors.white) ),
                    // Text( "Recording data and event keypress is still in progress", style: TextStyle(fontSize:12, color: Colors.white) ),
                    SizedBox(height: 10),
                    Text( "Your feedback is highly appreciated, please send us comment or report a bug by clicking the icon above.", style: TextStyle(fontSize:12, color: Colors.white) ),
                  ],
                ),
              );
            },
          ),
        ],
      ),    
    );           
  }

  getNearestPower(d){
    for (var i = 1;i<100;i++){
      var power = pow(2,i);
      if (d==power){
        return i;
      }else
      if (d>power){
        var nextPower = pow(2,i+1);
        if (d == nextPower){
          return i+1;
        }else
        if (d < nextPower){
          return i;
        }
      }
    }
  }

  List<Widget> getDataWidgets(){
    const shapeLevelHeight = 35;
    int _channelActive = -1;
    // List<int> channelsTop = [];
    for (var c = 0; c < channelsData.length; c++) {
      initialLevelMedian[c] = (c * MediaQuery.of(context).size.height/channelsData.length) + MediaQuery.of(context).size.height/channelsData.length / 2;
      // channelsTop.add(c * MediaQuery.of(context).size.height/channelsData.length);
      int channelNumber = c + 1;
      if (settingParams["flagDisplay"+channelNumber.toString()] == 1 && _channelActive == -1){
        _channelActive = c;
      }
      // print( "CHANNEL : "+_channelActive.toString() + " : "+c.toString()+" _ "+ settingParams["flagDisplay"+channelNumber.toString()].toString() );
    }
    // print("getDataWidgets "+channelGains[0].toString());

    // print("levelMedian : ");
    // print(levelMedian);
    List<Widget> dataWidgets = <Widget>[
                // Text( (!isLocal && sampleData.data.length>0).toString() + sampleData.data.length.toString(), style:TextStyle(color: Colors.white) ),
      if (!isLocal && channelsData.length>0)...{

        Positioned(
          top:0,
          left:0,
          child:settingParams["flagDisplay1"]==0?Container():WavForm.PolygonWaveform( 
            // inactiveColor: Colors.green,
            inactiveColor: channelsColor[0],
            activeColor: Colors.transparent,
            maxDuration: const Duration(days: 1),
            elapsedDuration: const Duration(hours: 0),
            samples: channelsData[0],
            channelIdx: 0,
            channelActive: _channelActive,
            // channelTop: top,
            height: MediaQuery.of(context).size.height/channelsData.length,
            width:  MediaQuery.of(context).size.width, 
            gain: channelGains[0],
            levelMedian : levelMedian[0] == -1? initialLevelMedian[0] : levelMedian[0],
            strokeWidth: settingParams["strokeWidth"] as double,
            eventMarkersNumber : eventMarkersNumber,
            eventMarkersPosition : eventMarkersPosition,
          ),
        ),
        if (channelsData.length>=2)...{

          Positioned(
            // top:MediaQuery.of(context).size.height/channelsData.length,
            top:0,
            left:0,
            child:settingParams["flagDisplay2"]==0?Container():WavForm.PolygonWaveform( 
              // inactiveColor: Colors.green,
              inactiveColor: channelsColor[1],
              activeColor: Colors.transparent,
              maxDuration: const Duration(days: 1),
              elapsedDuration: const Duration(hours: 0),
              samples: channelsData[1],
              channelIdx: 1,
              channelActive: _channelActive,
              // channelTop: top,

              height: MediaQuery.of(context).size.height/channelsData.length,
              width:  MediaQuery.of(context).size.width, 
              gain: channelGains[1],
              levelMedian : levelMedian[1] == -1? initialLevelMedian[1] : levelMedian[1],
              strokeWidth: settingParams["strokeWidth"] as double,
              eventMarkersNumber : eventMarkersNumber,
              eventMarkersPosition : eventMarkersPosition,
            ),
          ),

        },

        if (channelsData.length>=3)...{
                            
          Positioned(
            // top:2*MediaQuery.of(context).size.height/channelsData.length,
            top:0,
            left:0,
            child:Container(
              // color: Colors.red,
              padding: EdgeInsets.only(top:10),
              child:settingParams["flagDisplay3"]==0?Container():WavForm.PolygonWaveform( 
                // inactiveColor: Colors.green,
                inactiveColor: channelsColor[2],
                activeColor: Colors.transparent,
                maxDuration: Duration(days: 1),
                elapsedDuration: Duration(hours: 0),
                samples: channelsData[2],
                channelIdx: 2,
                channelActive: _channelActive,
                // channelTop: top,

                height: MediaQuery.of(context).size.height/channelsData.length,
                width:  MediaQuery.of(context).size.width, 
                gain: channelGains[2],
                levelMedian : (levelMedian[2] == -1? initialLevelMedian[2] : levelMedian[2])*0.985,
                strokeWidth: settingParams["strokeWidth"] as double,
                eventMarkersNumber : eventMarkersNumber,
                eventMarkersPosition : eventMarkersPosition,


              ),
            ),
          ),
        },

        if (channelsData.length>=4)...{
          
          Positioned(
            // top:3*MediaQuery.of(context).size.height/channelsData.length,
            top:0,
            left:0,
            child:settingParams["flagDisplay4"]==0?Container():WavForm.PolygonWaveform( 
              // inactiveColor: Colors.green,
              inactiveColor: channelsColor[3],
              activeColor: Colors.transparent,
              maxDuration: Duration(days: 1),
              elapsedDuration: Duration(hours: 0),
              samples: channelsData[3],
              channelIdx: 3,
              channelActive: _channelActive,
              // channelTop: top,

              height: MediaQuery.of(context).size.height/channelsData.length,
              width:  MediaQuery.of(context).size.width, 
              gain: channelGains[3],
              levelMedian : levelMedian[3] == -1? initialLevelMedian[3] : levelMedian[3],
              strokeWidth: settingParams["strokeWidth"] as double,
              eventMarkersNumber : eventMarkersNumber,
              eventMarkersPosition : eventMarkersPosition,


            ),
          ),

        },                

        if (channelsData.length>=5)...{
          
          Positioned(
            // top:4*MediaQuery.of(context).size.height/channelsData.length,
            top:0,
            left:0,
            child:settingParams["flagDisplay5"]==0?Container():WavForm.PolygonWaveform( 
              // inactiveColor: Colors.green,
              inactiveColor: channelsColor[4],
              activeColor: Colors.transparent,
              maxDuration: Duration(days: 1),
              elapsedDuration: Duration(hours: 0),
              samples: channelsData[4],
              channelIdx: 4,
              channelActive: _channelActive,
              // channelTop: top,

              height: MediaQuery.of(context).size.height/channelsData.length,
              width:  MediaQuery.of(context).size.width, 
              gain: channelGains[4],
              levelMedian : levelMedian[4] == -1? initialLevelMedian[4] : levelMedian[4],
              strokeWidth: settingParams["strokeWidth"] as double,
              eventMarkersNumber : eventMarkersNumber,
              eventMarkersPosition : eventMarkersPosition,


            ),
          ),

        },                
        if (channelsData.length>=6)...{

          Positioned(
            // top:5*MediaQuery.of(context).size.height/channelsData.length,
            top:0,
            left:0,
            child:settingParams["flagDisplay6"]==0?Container():WavForm.PolygonWaveform( 
              // inactiveColor: Colors.green,
              inactiveColor: channelsColor[5],
              activeColor: Colors.transparent,
              maxDuration: Duration(days: 1),
              elapsedDuration: Duration(hours: 0),
              samples: channelsData[5],
              channelIdx: 5,
              channelActive: _channelActive,
              // channelTop: top,

              height: MediaQuery.of(context).size.height/channelsData.length,
              width:  MediaQuery.of(context).size.width, 
              gain: channelGains[5],
              levelMedian : levelMedian[5] == -1? initialLevelMedian[5] : levelMedian[5],
              strokeWidth: settingParams["strokeWidth"] as double,
              eventMarkersNumber : eventMarkersNumber,
              eventMarkersPosition : eventMarkersPosition,


            ),
          ),

        },                

      },
      

      // Positioned(
      //   top:0,
      //   left:0,
      //   width: MediaQuery.of(context).size.width,
      //   height: 60,
      //   child: Container(
      //     width: MediaQuery.of(context).size.width,
      //     height: 60,
      //     color: Colors.black,
      //   ),
      // ),
      Positioned(
        top:0,
        left:0,
        width:50,
        height: MediaQuery.of(context).size.height,
        child: Container(
          width:50,
          height: MediaQuery.of(context).size.height,
          color: Colors.black,
        ),
      ),

      // Container(
      //     child: Row(
      //       children: <Widget>[
      //         CustomPaint(
      //           size: Size(
      //             MediaQuery.of(context).size.width,
      //             MediaQuery.of(context).size.height,
      //           ),
      //           foregroundPainter: WaveformPainter(
      //             sampleData,
      //             zoomLevel: zoomLevel,
      //             startingFrame: sampleData.frameIdxFromPercent(startPosition),
      //             // color: Color(0xff3994DB),
      //             color: Colors.green,
      //           ),
      //         ),
      //       ],
      //     ),
      //   )

      // SfCartesianChart(
      //   plotAreaBorderWidth: 0,

      //   primaryXAxis:
      //       NumericAxis(
      //         borderColor: Colors.black,
      //         minimum: 0,

      //         labelStyle: TextStyle(color:Colors.black),
      //         isVisible: false,

      //         maximum: maxAxis,
      //         // interval: 1,
      //         axisLine: const AxisLine(width: 0,color: Colors.black),
      //         majorGridLines: const MajorGridLines(width: 0,color: Colors.black)
      //       ),
      //   primaryYAxis: NumericAxis(
      //       borderColor: Colors.black,
      //       minimum: -1,

      //       borderWidth: 0,
      //       axisBorderType: AxisBorderType.withoutTopAndBottom,
      //       labelStyle: TextStyle(color:Colors.black),
      //       isVisible: false,

      //       maximum: 10,
      //       // interval: 1,
      //       axisLine: const AxisLine(width: 0,color: Colors.black),
      //       majorTickLines: const MajorTickLines(size: 0,color: Colors.black)),

      //   series: <LineSeries<_ChartData, int>>[
      //     LineSeries<_ChartData, int>(
      //       onRendererCreated: (ChartSeriesController controller) {
      //         _chartSeriesController = controller;
      //       },
      //       dataSource: chartLiveData,
      //       color: Colors.green,
      //       xValueMapper: (_ChartData sales, _) => sales.country,
      //       yValueMapper: (_ChartData sales, _) => sales.sales,
      //       animationDuration: 0,
      //     )
      // ])           
      // :
      // Container(),

      // Positioned(
      //   top:140,
      //   right:50,
      //   child:ElevatedButton(
      //     onPressed: (){
      //       deviceType = 1;
      //       isPlaying = 1;
      //       startRecordingTime = (DateTime.now());
      //       channelGains = [1000,1000,1000,1000,1000,1000];
      //       js.context.callMethod('recordHid', ['Flutter is calling upon JavaScript!']);
      //       setState(() {
              
      //       });
      //     },
      //     child: Icon(Icons.fiber_manual_record_rounded, ),
      //   ),
      // ),

      // Positioned(
      //   top:70,
      //   right:50,
      //   child:ElevatedButton(
      //     onPressed: (){
      //       deviceType = 1;
      //       isPlaying = 1;
      //       startRecordingTime = (DateTime.now());
      //       channelGains = [1000,1000,1000,1000,1000,1000];
      //       js.context.callMethod('recordSerial', ['Flutter is calling upon JavaScript!']);
      //       setState(() {
              
      //       });
      //     },
      //     child: Icon(Icons.fiber_manual_record_rounded),
      //   ),
      // ),

      // if (!isLocal)...{
        // Positioned(
        //   top:80,
        //   left:0,
        //   child:Container(
        //     // width:300,
        //     // height:150,
        //     color:Colors.red,
        //     child:CountStepper(

        //       iconColor: Theme.of(context).primaryColor,
        //       max:2,
        //       min:1, 
        //       defaultValue : stepperValue,
        //       onPressed:(val){
        //         var data = {
        //           "channelCount":val,
        //         };

        //         js.context.callMethod('changeChannel', [json.encode(data)]);
        //         setState(() {
        //           stepperValue = val;
        //         });
        //       }
        //     ),
        //   ),
        // ),
      // SERIAL
      //   Positioned(
      //     top:150,
      //     left:0,
      //     child:Container(
      //       // width:300,
      //       // height:150,
      //       color:Colors.red,
      //       child:CountStepper(

      //         iconColor: Theme.of(context).primaryColor,
      //         max:6,
      //         min:1, 
      //         defaultValue : stepperValue,
      //         onPressed:(val){
      //           var data = {
      //             "channelCount":val,
      //           };

      //           js.context.callMethod('changeSerialChannel', [json.encode(data)]);
      //           setState(() {
      //             stepperValue = val;
      //           });
      //         }
      //       ),
      //     ),
      //   ),

      //   Positioned(
      //     top:220,
      //     left:0,
      //     child:Container(
      //       // width:300,
      //       // height:150,
      //       color:Colors.red,
      //       child:CountStepper(

      //         iconColor: Theme.of(context).primaryColor,
      //         max:4,
      //         min:1, 
      //         defaultValue : stepperValue,
      //         onPressed:(val){
      //           var data = {
      //             "channelCount":val,
      //           };

      //           js.context.callMethod('changeHidChannel', [json.encode(data)]);
      //           setState(() {
      //             stepperValue = val;
      //           });
      //         }
      //       ),
      //     ),
      //   ),

      // },

      // Positioned(
      //   bottom: 10,
      //   left: MediaQuery.of(context).size.width/3,
      //   child: Center(
      //     child: Container(
      //       width: MediaQuery.of(context).size.width/4,
      //       height:20,
      //       child: Text(timeScale.toString()+"ms", style: TextStyle(color: Colors.white),)
      //     ),
      //   ),
      // ),

      Positioned(
        bottom: 170,
        right: 50,
        child: Center(
          child: Text(curTimeScaleBar == 1000 ? "1s" : curTimeScaleBar == 500 ? "0.5s"  : curTimeScaleBar.toString()+"ms", style: TextStyle(color: Colors.white),)
          // child: Container(
          //   width: MediaQuery.of(context).size.width/5,
          //   height:15,
          //   child: Text(curTimeScaleBar.toString()+"ms", style: TextStyle(color: Colors.white),)
          // ),
        ),
      ),


      Positioned(
        key: keyTutorialTimescale,
        bottom: 200,
        right: 50,
        child: Container(
          width: scaleBarWidth,
          height:1,
          color: Colors.white,
          // child: Text(scaleBarWidth.toString(), style: TextStyle(color: Colors.red),)
        ),
      ),

      //TOP RED BANNER


      // !isLocal?
      //   Container()
      //   :
        // Positioned(
        //   top:10,
        //   left:50,
        //   child:Container(
        //     width:150,
        //     color: Colors.red,
        //     child: CupertinoSlider(
        //       value:zoomLevel,
        //       min: 1,
        //       max: 100,
        //       divisions: 40,
        //       onChanged: (newZoomLevel){
        //         setState(() => zoomLevel = newZoomLevel);
        //       },
        //     ),
        //   ),
        // ),

      // !isLocal?
      //   Container()
      //   :

        // Positioned(
        //   top:10,
        //   left:50,
        //   child:Container(
        //     width:150,
        //     color: Colors.red,
        //     child: Slider(
        //       value:curLevel,
        //       divisions: 9,
        //       // label: "$curLevel",
        //       onChanged: (_curLevel){
        //         curLevel = _curLevel;
        //         int lvl = ( curLevel * 10 ).floor();
        //         if (curLevel == 1){
        //           lvl = 9;
        //         }

        //         timeScale = arrTimescale[lvl];
        //         int dataTimeScale = lblTimescale[lvl];
        //         js.context.callMethod('refreshAudioSetting', [dataTimeScale]);
        //         setState(() {
                  
        //         });

        //       },
        //     ),
        //   ),
        // ),


      // !isLocal?
      //   Container()
      //   :
      //   // WavForm.PolygonWaveform( 
      //   //   maxDuration: Duration(days: 1),
      //   //   elapsedDuration: Duration(hours: 0),
      //   //   samples: chartData,
      //   //   height: MediaQuery.of(context).size.height,
      //   //   width:  MediaQuery.of(context).size.width, 
      //   // )              
      //   CustomPaint(
      //     size: Size(
      //       MediaQuery.of(context).size.width,
      //       MediaQuery.of(context).size.height,
      //     ),
      //     foregroundPainter: WaveformPainter(
      //       sampleData,
      //       zoomLevel: zoomLevel,
      //       startingFrame: sampleData.frameIdxFromPercent(startPosition),
      //       color: Color(0xff3994DB),
      //     ),
      //   ),


    ];    
  

 
    List<Widget> widgetsChannelGainLevel = [];
    for (var c = 0; c < channelsData.length; c++) {
      widgetsChannelGainLevel.add(
        Positioned(
          // top : levelMedian[c] == -1?(c * MediaQuery.of(context).size.height/channelsData.length) + MediaQuery.of(context).size.height/channelsData.length / 2 - shapeLevelHeight : levelMedian[c],
          top : levelMedian[c] == -1 ? initialLevelMedian[c] - shapeLevelHeight : levelMedian[c] - shapeLevelHeight,
          left: 10,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: (){
              if (c>-1){
                if (isRecording<10){
                  settingParams["flagDisplay"+(c+1).toString()] = settingParams["flagDisplay"+(c+1).toString()] == 0 ? 1 : 0;
                  js.context.callMethod('setFlagChannelDisplay', [settingParams["flagDisplay1"],settingParams["flagDisplay2"],settingParams["flagDisplay3"],settingParams["flagDisplay4"],settingParams["flagDisplay5"],settingParams["flagDisplay6"] ]);
                }
                _sendAnalyticsEvent("button_level_marker", {
                  "deviceType" : deviceType,
                  "channel" : c,
                  "gains" : channelGains[c],
                });

                // settingParams["flagDisplay"+(c+1).toString()] = 1;
                setState(() { });
              }
            },
            onVerticalDragUpdate: (dragUpdateVerticalDetails){
              levelMedian[c] = dragUpdateVerticalDetails.globalPosition.dy;
              // print("isPlaying");
              // print(isPlaying);
              if (isPlaying == 2){
                setState(() { });
              }
              // print("123 levelMedian : ");
              // print(levelMedian);


              // print("dragUpdateVerticalDetails");
              // print(dragUpdateVerticalDetails.localPosition);
              // print(dragUpdateVerticalDetails.globalPosition);
              // setState(() {
                
              // });
            },
            child : Container(
              // color:Colors.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                  GestureDetector(
                    onTap: () {
                      //Increase Gain
                      if (deviceType == 0){
                        // if (channelGains[c] - 200 > 0){
                        //   channelGains[c]-=200;
                        // }
                        double idx = listIndexAudio[c];
                        if (idx - 1 > minIndexAudio){
                          idx--;
                          listIndexAudio[c]= idx;
                          channelGains[c] = listChannelAudio[idx.toInt()];
                        }
                        _sendAnalyticsEvent("button_gain_inc", {
                          "device" : "Audio",
                          "deviceType" : deviceType,
                          "channel" : c,
                          "gains" : channelGains[c],
                        });

                      }else
                      if (deviceType == 2){
                        // if (channelGains[c] - 50 > 50){
                        //   channelGains[c] -= 50;
                        // }
                        double idx = listIndexHid[c];
                        if (idx - 1 > minIndexHid){
                          idx--;
                          listIndexHid[c]= idx;
                          channelGains[c] = listChannelHid[idx.toInt()];
                        }
                        _sendAnalyticsEvent("button_gain_inc", {
                          "device" : "HID",
                          "deviceType" : deviceType,
                          "channel" : c,
                          "gains" : channelGains[c],
                        });


                      }else{
                        double idx = listIndexSerial[c];
                        if (idx - 1 > minIndexSerial){
                          idx--;
                          listIndexSerial[c]= idx;
                          
                          channelGains[c] = listChannelSerial[idx.toInt()];
                        }
                        _sendAnalyticsEvent("button_gain_inc", {
                          "device" : "Serial",
                          "deviceType" : deviceType,
                          "channel" : c,
                          "gains" : channelGains[c],
                        });



                        // if (channelGains[c] - 100 > 200){
                        //   channelGains[c]-=100;
                        // }
                      }
                      // print("deviceType --");
                      // print(channelGains);
                      // print(listIndexSerial);
                      // print(deviceType);

                      setState((){});
                    },

                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child : Icon(Icons.add, color: Colors.black,size:17),
                    ),

                    // style: ElevatedButton.styleFrom(
                    //   fixedSize: Size(10, 10),
                    //   shape: CircleBorder(),
                    //   padding: EdgeInsets.all(3),
                    //   primary: Colors.blue,
                    //   onPrimary: Colors.black,
                    // ),
                  ),


                  // Icon(Icons.arrow_circle_right_rounded, color: Colors.white,),
                  Transform.rotate(
                    angle: 90 * pi /180,
                    // child: settingParams["flagDisplay"+(c+1).toString()] == 0? Icon(Icons.water_drop_outlined ,color: audioChannelColors[c],size: 37,):Icon(Icons.water_drop_rounded,color: channelsColor[c],size: 37,),
                    child: settingParams["flagDisplay"+(c+1).toString()] == 0? Icon(Icons.water_drop_outlined ,color: channelsColor[c],size: 37,):Icon(Icons.water_drop_rounded,color: channelsColor[c],size: 37,),
                  ),

                  // ElevatedButton(
                  //   onLongPress: (() {

                  //   }),
                  //   onPressed: () {},
                  //   child: Icon(Icons.arrow_back, color: Colors.white),
                  //   style: ElevatedButton.styleFrom(
                  //     fixedSize: Size(30, 30),
                  //     shape: CircleBorder(),
                  //     padding: EdgeInsets.all(20),
                  //     primary: Colors.blue,
                  //     onPrimary: Colors.black,
                  //   ),
                  // ),

                  
                  GestureDetector(
                    onTap: () {
                      //Increase Gain
                      if (deviceType == 0){
                        // if (channelGains[c] + 200 < 20000){
                        //   channelGains[c]+=200;
                        // }
                        double idx = listIndexAudio[c];
                        if (idx + 1 < maxIndexAudio){
                          idx++;
                          listIndexAudio[c]= idx;
                          channelGains[c] = listChannelAudio[idx.toInt()];
                        }
                        _sendAnalyticsEvent("button_gain_dec", {
                          "device" : "Audio",
                          "deviceType" : deviceType,
                          "channel" : c,
                          "gains" : channelGains[c],
                        });

                      }else
                      if (deviceType == 2){
                        // if (channelGains[c] + 50 < 1000){
                        //   channelGains[c]+=50;
                        // }
                        double idx = listIndexHid[c];
                        if (idx + 1 < maxIndexHid){
                          idx++;
                          listIndexHid[c]= idx;

                          channelGains[c] = listChannelHid[idx.toInt()];
                        }
                        _sendAnalyticsEvent("button_gain_dec", {
                          "device" : "HID",
                          "deviceType" : deviceType,
                          "channel" : c,
                          "gains" : channelGains[c],
                        });


                      }else{
                        // if (channelGains[c] + 100 < 1800){
                        //   channelGains[c]+=100;
                        // }
                        double idx = listIndexSerial[c];
                        if (idx + 1 < maxIndexSerial){
                          idx++;
                          listIndexSerial[c]= idx;
                          channelGains[c] = listChannelSerial[idx.toInt()];
                        }
                        _sendAnalyticsEvent("button_gain_dec", {
                          "device" : "Serial",
                          "deviceType" : deviceType,
                          "channel" : c,
                          "gains" : channelGains[c],
                        });

                      }
                      print("deviceType ++");
                      // print(channelGains);
                      // print(channelsData);
                      print(deviceType);
                      print(channelGains);
                      print(listIndexSerial);

                      setState((){});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),   
                      child: Icon(Icons.remove, color: Colors.black, size:17),
                    ),
                    // style: ElevatedButton.styleFrom(
                    //   fixedSize: Size(10, 10),
                    //   shape: CircleBorder(),
                    //   padding: EdgeInsets.all(3),
                    //   primary: Colors.blue,
                    //   onPrimary: Colors.black,
                    // ),
                  ),

                ],
              ),
            )
          ),
        )
      );
    }
    dataWidgets.addAll(widgetsChannelGainLevel);
    if (isLocal){
      if (channels.length>0){
        dataWidgets.add(
          Positioned(
            top : 0,
            left : 0,
            child : Container(
              color: Colors.black,
              child: CustomPaint(
                size: Size(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height/localChannel,
                ),
                foregroundPainter: WaveformPainter(
                  // sampleData,
                  channels[0],
                  zoomLevel: zoomLevel,
                  startingFrame: channels[0].frameIdxFromPercent(startPosition),
                  color: Color(0xff3994DB),
                ),
              ),
            ),
          )
        );
      }

      if (channels.length>1){
        dataWidgets.add(
          Positioned(
            top:MediaQuery.of(context).size.height/localChannel,
            left: 0,
            child : Container(
              color: Colors.black,
              child: CustomPaint(
                size: Size(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height/localChannel,
                ),
                foregroundPainter: WaveformPainter(
                  channels[1],
                  zoomLevel: zoomLevel,
                  startingFrame: channels[1].frameIdxFromPercent(startPosition),
                  color: Color(0xff990000), 
                ),
              ),
            ),

          )
        );
      }

      dataWidgets.add(  
        Positioned(
          top:70,
          right:50,
          child:Container(
            width:150,
            color: Colors.red,
            child: CupertinoSlider(
              value:zoomLevel,
              min: 1,
              max: 100,
              divisions: 40,
              onChangeEnd: (newZoomLevel){
                setState(() => zoomLevel = newZoomLevel);
              },
              onChanged: (double value) {  },              
            ),
          ),
        ),
      );
      dataWidgets.add(
        Positioned(
          top:120,
          right:50,
          child:Container(
            width:250,
            color: Colors.green,
            child: CupertinoSlider(
              value:startPosition,
              min: 1,
              max: 95,
              divisions: 42,
              onChangeEnd: (newstartPosition) {
                setState(() => startPosition = newstartPosition);
              }, 
              onChanged: (double value) {  },                    
            ),
          ),
        )
      );     
    }
    
    // Putting Toolbar Button
    // // FILE RECORD

    if (isOpeningFile==1){
      // strMinTime = "00:00 000";
      dataWidgets.add(
        Positioned(
          left:50,
          bottom : 70,
          child: Text( strMinTime, textAlign: TextAlign.left, style:TextStyle(color: Colors.white)),
        )
      );
      dataWidgets.add(
        Positioned(
          right:50,
          bottom : 70,
          child: Container(
            width:150,
            child: Text( strMaxTime, textAlign: TextAlign.right, style:TextStyle(color: Colors.white))
          ),
        )
      );


      // ScrollBar When Opening File
      if (isPlaying == 2){
        dataWidgets.add(
          Positioned(
            left: 0,
            bottom:100,
            child: GestureDetector(
              onTapDown :(onTapDownDetails){
                horizontalDragX = onTapDownDetails.localPosition.dx - 50;
                if (horizontalDragX <0){
                  horizontalDragX = 0;
                }
                if (horizontalDragX > MediaQuery.of(context).size.width - 100 - 20){
                  horizontalDragX = MediaQuery.of(context).size.width - 100 -20;
                }

                strMinTime = getStrMinTime(horizontalDragX, horizontalDragXFix, maxTime);
                setState((){});

                debouncer.run((){
                  js.context.callMethod('setScrollValue', [horizontalDragX, horizontalDragXFix]);
                });
              },
              onHorizontalDragUpdate: (dragUpdateHorizontalDetails){
                horizontalDragX = dragUpdateHorizontalDetails.globalPosition.dx-50;
                if (horizontalDragX < 0){
                  horizontalDragX = 0;
                }
                if (horizontalDragX > MediaQuery.of(context).size.width - 100 - 20){
                  horizontalDragX = MediaQuery.of(context).size.width - 100 -20;
                }

                strMinTime = getStrMinTime(horizontalDragX, horizontalDragXFix, maxTime);
                setState((){});

                debouncer.run((){

                  js.context.callMethod('setScrollValue', [horizontalDragX, horizontalDragXFix]);

                });
              },          



              child: Container(
                color: const Color(0xFF505050),
                margin: const EdgeInsets.only(left:50, right : 50),
                width:MediaQuery.of(context).size.width - 100,
                height: 20,
                child : Stack(
                  children: [
                    Positioned(
                      left: horizontalDragX,
                      child: Container(
                        // color: Colors.green,
                        color: const Color(0xFF808080),
                        width:20,
                        height:20,
                      ),
                    )
                  ],
                )
              ),
            ),
          )
        );
      }  
      
    }

    if ( isOpeningFile == 1 ){
    }else{

      dataWidgets.add(

      Positioned(
        top:10,
        right:160,
        child:ElevatedButton(
          style: ElevatedButton.styleFrom(
          // style: ButtonStyle(
            fixedSize: const Size(50, 50),
            shape : const CircleBorder(),
            shadowColor: Colors.blue,

            primary: Colors.white,
            onPrimary: Colors.green,
            onSurface: Colors.red,
            // backgroundColor: getColor(Colors.blueGrey, Colors.blueGrey),
            // overlayColor: getColor(Colors.white60, Colors.white70)
          ),
          
          onPressed: (){
            bool flag = false;
            for (int c = 0; c< 6; c++){
              if (settingParams["flagDisplay"+c.toString()] == '1'){
                flag = true;
              }
            }
            if (flag){
              infoDialog(
                context,
                "Warning",
                "To start recording, please activate a channel first.",
                positiveButtonText: "OK",
                positiveButtonAction: () {},

                negativeButtonText: "",
                negativeButtonAction: null,

                hideNeutralButton: true,
                closeOnBackPress: false,
              );    

            }
            // startRecordingTime = DateTime.now();
            // currentRecordingTime = DateTime.now();
            // duration = currentRecordingTime.difference(startRecordingTime);
            // labelDuration = ( (duration.inHours) ).toString()+":"+( (duration.inMinutes) ).toString()+":"+(duration.inSeconds % 60).toString();
            if (deviceType == 0){
              if (isRecording < 10){
                // isRecording = 10;
                _sendAnalyticsEvent("button_stop_rec", {
                  "deviceType":deviceType,
                  "device" : "Audio",
                });
              }else{
                isRecording = 0;
                _sendAnalyticsEvent("button_start_rec", {
                  "deviceType":deviceType,
                  "device" : "Audio",
                });

              }
              print("flagDisplay12");
              print(settingParams);
              print(settingParams["flagDisplay1"]);
              print(settingParams["flagDisplay2"]);
              js.context.callMethod('fileRecordAudio', [ settingParams["flagDisplay1"] as int,settingParams["flagDisplay2"] as int, settingParams["defaultMicrophoneLeftColor"] as int, settingParams['defaultMicrophoneRightColor'] as int ]);

            }else
            if (deviceType == 1){
              if (isRecording < 10){
                // isRecording = 11;
                _sendAnalyticsEvent("button_start_rec", {
                  "deviceType":deviceType,
                  "device" : "Serial",
                });
              }else{
                isRecording = 0;
                _sendAnalyticsEvent("button_stop_rec", {
                  "deviceType":deviceType,
                  "device" : "Serial",
                });

              }
              js.context.callMethod('fileRecordSerial', [ settingParams["flagDisplay1"],settingParams["flagDisplay2"],settingParams["flagDisplay3"],settingParams["flagDisplay4"],settingParams["flagDisplay5"],settingParams["flagDisplay6"],  settingParams['defaultSerialColor1'] as int,  settingParams['defaultSerialColor2'] as int,  settingParams['defaultSerialColor3'] as int,  settingParams['defaultSerialColor4'] as int,  settingParams['defaultSerialColor5'] as int,  settingParams['defaultSerialColor6'] as int ]);
            }else
            if (deviceType == 2){
              if (isRecording < 10){
                // isRecording = 12;
                _sendAnalyticsEvent("button_start_rec", {
                  "deviceType":deviceType,
                  "device" : "Audio",
                });
              }else{
                isRecording = 0;
                _sendAnalyticsEvent("button_stop_rec", {
                  "deviceType":deviceType,
                  "device" : "Hid",
                });

              }
              js.context.callMethod('fileRecordSerial', [ settingParams["flagDisplay1"],settingParams["flagDisplay2"],settingParams["flagDisplay3"],settingParams["flagDisplay4"],settingParams["flagDisplay5"],settingParams["flagDisplay6"],  settingParams['defaultSerialColor1'] as int,  settingParams['defaultSerialColor2'] as int,  settingParams['defaultSerialColor3'] as int,  settingParams['defaultSerialColor4'] as int,  settingParams['defaultSerialColor5'] as int,  settingParams['defaultSerialColor6'] as int ]);
            }
            // isPlaying = 1;
            // deviceType = 0;
            // startRecordingTime = (DateTime.now());
            // channelGains = [10000,10000,10000,10000,10000,10000];
            // js.context.callMethod('recordAudio', ['Flutter is calling upon JavaScript!']);
            // setState(() {
              
            // });
          },
          child: const Icon(Icons.fiber_manual_record_rounded, color: Color(0xFF800000),),
        ),
      ),
    );  
    }

    if ( isRecording == 0 ){
      dataWidgets.add(
        feedbackButton
      );
    // }
    
    // if ( isRecording == 0 ){
      dataWidgets.add(
        openFileButton
      );
    }

    if ( isRecording > 0 || isOpeningFile == 1){
    }else{
      dataWidgets.add(

        // Positioned(
        //   top:10,
        //   right:230,
        //   child: Container(
        //     width:100,
        //     color: Colors.white,
        //     child: CupertinoSlider(
        //       value:timeScale.toDouble(),
        //       min: 10,
        //       max: 10000,
        //       divisions: 5,
        //       onChanged: (newScale){
        //         timeScale = newScale.toInt();
        //         changeMaxAxis();
        //         zoomLevel = (newScale/10000).ceil().toDouble();
        //         startPosition = 70;
        //         // js.context.callMethod('refreshAudioSetting', [timeScale]);
        //         // capacity = (sampleRate/timeScale).floor();
        //         setState(() {
                  
        //         });

        //       },
        //     ),
        //   ),
        // ),
        settingDialogButton
      );
    }

    if ( isRecording > 0 || isOpeningFile == 1){
    }else{
    // if ( isRecording == 0 ){
      dataWidgets.add(
          Positioned(
            top:10,
            left:80,
            child:Container(
              key:keyTutorialSerial,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(50, 50),
                  shape : const CircleBorder(),
                  shadowColor: Colors.blue,

                  primary: Colors.white,
                  onPrimary: Colors.green,
                  onSurface: Colors.red,
                ),
                child:Transform.rotate(
                  angle: 90 * pi /180,
                  child: Icon(Icons.usb_rounded, color: deviceType == 1 && isPlaying ==1 ? Colors.amber.shade900 : Color(0xFF800000),),
                ),
              
                onPressed: () {  
                  if (deviceType == 0 || deviceType == 2){
                    deviceTypeInt = 1;
                    deviceType = 1;
                    js.context.callMethod('recordSerial', ['Flutter is calling upon JavaScript!']);
                    setState(() {
                      
                    });
                    _sendAnalyticsEvent("button_serial", {
                      "deviceType" : deviceType,
                      "isStartingSerial" : 1,
                      "isStartingAudio" : 0
                    });

                  } else {
                  // if (deviceType == 1){
                  
                    deviceTypeInt = 0;
                    deviceType = 0;
                    js.context.callMethod('recordAudio', ['Flutter is calling upon JavaScript!']);
                    setState(() {
                      
                    });
                    _sendAnalyticsEvent("button_serial", {
                      "deviceType" : deviceType,
                      "isStartingSerial" : 0,
                      "isStartingAudio" : 1
                    });

                  }


                },

              ),
            ),
          ),      
      );
    }
    if ( isRecording > 0 || isOpeningFile == 1){
    }else{
    // if ( isRecording == 0 ){
      dataWidgets.add(
          !( (settingParams["enableDeviceLegacy"]) as bool ) ?
          Container()
          :
          Positioned(
            key:keyTutorialHid,          
            top:10,
            left:150,
            child:Stack(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(50, 50),
                    shape : const CircleBorder(),
                    shadowColor: Colors.blue,

                    primary: Colors.white,
                    onPrimary: Colors.green,
                    onSurface: Colors.red,
                  ),
                  
                  child: Transform.rotate(
                    angle: 90 * pi /180,
                    child: Icon(Icons.usb_outlined, color: deviceType == 2 && isPlaying ==1 ? Colors.yellow : Color(0xFF800000),),
                  ),
                
                  onPressed: () {  

                    if (deviceType == 0 || deviceType == 1){
                      deviceTypeInt = 2;
                      deviceType = 2;
                      js.context.callMethod('recordHid', ['Flutter is calling upon JavaScript!']);
                      setState(() {
                        
                      });
                    } else {
                    // if (deviceType == 1){
                    
                      deviceTypeInt = 0;
                      deviceType = 0;
                      js.context.callMethod('recordAudio', ['Flutter is calling upon JavaScript!']);
                      setState(() {
                        
                      });

                    }
                  },
                ),
                Positioned(
                  bottom:0,
                  right:12,
                  child: GestureDetector(
                    onTap:(){
                      if (deviceType == 0 || deviceType == 1){
                        deviceTypeInt = 2;
                        deviceType = 2;
                        js.context.callMethod('recordHid', ['Flutter is calling upon JavaScript!']);
                        setState(() {
                          
                        });
                        _sendAnalyticsEvent("button_hid", {
                          "deviceType" : deviceType,
                          "isStartingHid" : 1,
                          "isStartingAudio" : 0
                        });

                      } else {
                      // if (deviceType == 1){
                      
                        deviceTypeInt = 0;
                        deviceType = 0;
                        js.context.callMethod('recordAudio', ['Flutter is calling upon JavaScript!']);
                        setState(() {
                          
                        });
                        _sendAnalyticsEvent("button_hid", {
                          "deviceType" : deviceType,
                          "isStartingHid" : 0,
                          "isStartingAudio" : 1
                        });

                      }

                    },
                    child : Text("  PRO", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize:15) ,),
                  ),
                  
                ),            
              ]
            ),
          ),      
      );
    }

    if (isPlaying == 2 || isZooming){
      lastPositionButton = Positioned(
        bottom: 20,
        left: MediaQuery.of(context).size.width/2 + 70,
        child: Container(
          width: 60,
          height:40,

          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
            // style: ButtonStyle(
              fixedSize: const Size(50, 50),
              shape : const CircleBorder(),
              shadowColor: Colors.blue,

              primary: Colors.white,
              onPrimary: Colors.green,
              onSurface: Colors.red,
              // backgroundColor: getColor(Colors.blueGrey, Colors.blueGrey),
              // overlayColor: getColor(Colors.white60, Colors.white70)
            ),

            child: Icon(Icons.arrow_right_alt_rounded, color: Color(0xFF800000),),
            // onPressed:  null,
            onPressed:  (){

              if (isPlaying==2){
                horizontalDiff = 0;
                isPlaying = 1;
                // if (deviceType == 0){
                  if (isOpeningFile == 0){
                    js.context.callMethod('pauseResume', [3]);
                    _sendAnalyticsEvent("return_play",{"openingFile":0, "previous_playing":0, "deviceType": deviceType});
                  }else{
                    isOpeningFile = 1;
                    js.context.callMethod('playData', [3]);
                    _sendAnalyticsEvent("return_play",{"openingFile":1, "previous_playing":0, "deviceType": deviceType});
                  }
                // }else{

                // }
              }else
              if (isPlaying == 1 ){
                horizontalDiff = 0;
                if (isOpeningFile == 0){
                  js.context.callMethod('pauseResume', [3]);
                  _sendAnalyticsEvent("return_play",{"openingFile":0, "previous_playing":1, "deviceType": deviceType});
                }else{
                  isOpeningFile = 1;
                  js.context.callMethod('playData', [3]);
                  _sendAnalyticsEvent("return_play",{"openingFile":1, "previous_playing":1, "deviceType": deviceType});
                }

              }

              setState(() {
              });
            },
          ),
        )

      );

      dataWidgets.add(
        lastPositionButton
      );

    }

    if (isOpeningFile == 1 && isShowingResetButton){
      dataWidgets.add(
        Positioned(
          bottom: 20,
          left : MediaQuery.of(context).size.width/2 - 70,
          child: Container(
            width: 55,
            height:35,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(30, 30),
                shape : const CircleBorder(),
                shadowColor: Colors.blue,

                primary: Colors.white,
                onPrimary: Colors.green,
                onSurface: Colors.red,
              ),

              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),                
                child: const Icon(Icons.refresh, color: Color(0xFF800000)),
              ),

              onPressed:  (){
                js.context.callMethod('resetPlayback', [1]);

                setState(() {
                });
                _sendAnalyticsEvent("button_reset_playback", {
                  "isOpeningFile" : 1,
                  "deviceType" : deviceType,
                });
                
              },
            )

          ),
        )
      );
    }

    if ( isRecording == 0 ){
      dataWidgets.add(
        Positioned(
          bottom: 20,
          left: MediaQuery.of(context).size.width/2,
          child: Center(
            child: Container(
              width: 60,
              height:40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                // style: ButtonStyle(
                  fixedSize: const Size(50, 50),
                  shape : const CircleBorder(),
                  shadowColor: Colors.blue,

                  primary: Colors.white,
                  onPrimary: Colors.green,
                  onSurface: Colors.red,
                  // backgroundColor: getColor(Colors.blueGrey, Colors.blueGrey),
                  // overlayColor: getColor(Colors.white60, Colors.white70)
                ),

                child: 
                  isPlaying == 1 ?
                    Icon(Icons.pause, color: Color(0xFF800000))
                  :
                    Icon(Icons.play_arrow, color: Color(0xFF800000),),
                    

                // onPressed:  null,
                onPressed:  (){

                  // if (isPlaying==1){
                  //   return;
                  // }else
                  print("isOpeningFile");
                  print(isOpeningFile);
                  if (isOpeningFile == 0){
                    if (isPlaying == 1){
                      debouncerPlayback.run(() {
                        js.context.callMethod('pauseResume', [1]);
                        isPlaying = 2;
                        setState((){});
                        _sendAnalyticsEvent("button_play",{"isOpeningFile":0,"isPlaying":2, "deviceType": deviceType});
                      });

                    }else{
                      debouncerPlayback.run(() {
                        js.context.callMethod('pauseResume', [2]);
                        isPlaying = 1;
                        setState((){});
                        _sendAnalyticsEvent("button_play",{"isOpeningFile":0,"isPlaying":1, "deviceType": deviceType});
                      });
                    }
                  }else{
                    if (isPlaying == 1){
                      debouncerPlayback.run(() {
                        js.context.callMethod('playData', [2]);
                        isPlaying = 2;
                        setState((){});
                        _sendAnalyticsEvent("button_play",{"isOpeningFile":1,"isPlaying":2, "deviceType": deviceType});
                      });
                    }else{
                      debouncerPlayback.run(() {
                        js.context.callMethod('playData', [1]);
                        isPlaying = 1;
                        setState((){});
                        _sendAnalyticsEvent("button_play",{"isOpeningFile":1,"isPlaying":1, "deviceType": deviceType});

                      });
                    }
                  }

                  setState(() {
                  });
                },
              )
            ),
          ),
        )
      );
    }
    // END adding TOOLBAR Button  


    if (isTutored == '0' && tutorialStep == 1){
      double tempMedian = ( MediaQuery.of(context).size.height/2 / 2 );

      dataWidgets.insert(
        0,
        Positioned(
          key : keyTutorialAudio,
          top : tempMedian - 20,
          left: 170,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children:[
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child : Icon(
                      Icons.add, 
                      // key: keyTutorialAudioGainPlus,
                      color: Colors.black,
                      size:17
                    ),
                  ),
                  SizedBox(width:10),
                  Text( 'Increase Gain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color:Colors.white) ),
                ]
              ),
              Text( 'To increase the signal gain click on plus sign', style: TextStyle( fontSize: 12, color:Colors.white) ),
              SizedBox(
                height:10,
              ),
              Row(
                children: [
                  Transform.rotate(
                    angle: 90 * pi /180,
                    child:  Icon(
                      Icons.water_drop_outlined,
                      // key: keyTutorialAudioLevel,
                      color: Colors.green
                    ),
                  ),
                  SizedBox(width:10),
                  Text( 'Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color:Colors.white) ),
                ],
              ),
              // Text( 'This is the median of the sample data', style: TextStyle( fontSize: 12, color:Colors.white) ),
              Text( 'This is the origin (y=0) point of the signal channel. ', style: TextStyle( fontSize: 12, color:Colors.white) ),
              Text( 'Click this button to toggle the channel on/off and ', style: TextStyle( fontSize: 12, color:Colors.white) ),
              Text( 'drag it to move the channel up or down. ', style: TextStyle( fontSize: 12, color:Colors.white) ),


              SizedBox(
                height:10,
              ),
              Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),   
                    child: Icon(
                      Icons.remove, 
                      // key: keyTutorialAudioGainMinus,
                      color: Colors.black, 
                      size:17
                    ),
                  ),
                  SizedBox(width:10),
                  Text( 'Decrease Gain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color:Colors.white) ),
                ],
              ),
              Text( 'To decrease the signal gain click on minus sign', style: TextStyle( fontSize: 12, color:Colors.white) ),
              SizedBox(
                height:50,
              ),

              Text( 'Click here to continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color:Colors.white) ),

            ]
          ),
        ),
      );

    }

    if (isTutored == '0' && tutorialStep == 0){
      dataWidgets.insert(
        0,
        Positioned(
          top: MediaQuery.of(context).size.height/2,
          left: MediaQuery.of(context).size.width/2-100,
          child: Container(
            width : 150,
            height: 200,
            child: Column(
              key : keyTutorialNavigation,                 
              children: [
                Image.asset('assets/sr_icon.png',width: 128, height:128),
                const Text( "Welcome to Spike Recorder Web Edition", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color:Colors.white), textAlign: TextAlign.center, ),
                // const Text( "Click the brain icon! You will start to understand your brain", style: TextStyle(fontSize:12, color:Colors.white), textAlign: TextAlign.center, )
                // const Text( "Click the brain icon to start your journey into neuroscience", style: TextStyle(fontSize:12, color:Colors.white), textAlign: TextAlign.center, )
                const Text( "Click the brain icon to start your neuroscience journey!", style: TextStyle(fontSize:12, color:Colors.white), textAlign: TextAlign.center, )
                
              ],
            ),
          )
        )
      );
    }


    // if (isTutored == '0' && tutorialStep == 6){
    //   dataWidgets.insert(
    //     0,
    //     Positioned(
    //       top: MediaQuery.of(context).size.height/2,
    //       left: MediaQuery.of(context).size.width/2-100,
    //       child: Container(
    //         key: keyTutorialEnd
    //       )
    //     )
    //   );
    // }

    return dataWidgets;
  }


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
    var mapPost = new Map<String,String>.from(mapValue);

    // mapPost['chromeVersion'] = globalChromeVersion;
    _deviceData.forEach((key, value) {
      mapPost[key] = value;
    });
    mapPost["level"] = curLevel.toString();
    mapPost["skipCounts"] = curSkipCounts.toString();
    mapPost["sampleRate"] = sampleRate.toString();
    // mapPost["fps"] = curFps.toString();
    mapPost["deviceWidth"] = MediaQuery.of(context).size.width.toString();

    print("mapPos t");
    print(mapPost);

    var response = https.post(url, body: json.encode(mapPost));
    // print('Response status: ${response.statusCode}');
    // print('Response body: ${response.body}');  
    _sendAnalyticsEvent("feedback_sent", {
      "deviceType":deviceType,
      "feedbackSent": 1
    });
    infoDialog(
      context,
      "Feedback Saved",
      "Thank you so much for your feedback, we will process the feedback to make the app better",
      positiveButtonText: "OK",
      positiveButtonAction: () {
        isFeedback = false;
        setState((){});
      },

      negativeButtonText: "",
      negativeButtonAction: (){
        isFeedback = false;
        setState((){});
      },

      hideNeutralButton: true,
      closeOnBackPress: false,
    );    
  }

  Widget getFeedbackWidget(){
    print("globalChromeVersion");
    print(globalChromeVersion);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormBuilder(
        key: _formKey,
        // enabled: false,
        onChanged: () {
          // _formKey.currentState!.save();
          // debugPrint(_formKey.currentState!.value.toString());
        },
        // initialValue: {
        //   'chromeversion': globalChromeVersion
        // },              

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
            // FormBuilderTextField(
            //   autovalidateMode: AutovalidateMode.always,
            //   readOnly: true,
            //   name: 'chromeversion',
            //   decoration: InputDecoration(
            //     labelText: 'Chrome Version',
            //   ),
            //   validator: FormBuilderValidators.compose([
            //     FormBuilderValidators.required(),
            //   ]),
            //   initialValue: globalChromeVersion,
            //   textInputAction: TextInputAction.next,
            // ),          
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


  Widget getMainWidget(){
    // return Stack(
    //     children: getDataWidgets(),
    // );
    // final ScrollController canvasController = ScrollController();
    // canvasController.addListener((){
    //   print(canvasController.initialScrollOffset);
    //   print(canvasController.offset);
    // });
    // return ScrollConfiguration(      
    //   behavior: CanvasScrollBehavior(),
    //   child: ListView(
    //     children:[
    //       Stack(
    //         children: getDataWidgets(),
    //       )
    //     ]
    //   ),
    // );
    return Listener(
      onPointerSignal: (PointerSignalEvent dragDetails) {
        if (dragDetails is PointerScrollEvent) {
          int direction = 0;
          const arrTimeScale = [0.1,1, 10,50, 100,500, 1000,5000,10000];

          // print('x: ${event.position.dx}, y: ${event.position.dy}');
          // print('scroll delta: ${dragDetails.delta}');
          // print('scroll delta: ${dragDetails.scrollDelta}');
          // print('scroll delta: ${dragDetails.kind}');
          // print('scroll delta: ${dragDetails.localDelta}');
          // print('scroll delta: ${dragDetails.device}');
          // print('scroll delta: ${dragDetails.buttons}');
          // print('scroll delta: ${dragDetails.position}');
          if (dragDetails.kind != PointerDeviceKind.mouse){
            return;
          }

          if (dragDetails.scrollDelta.dx == 0.0 && dragDetails.scrollDelta.dy == 0.0){
            return;
          }else
          // if (dragDetails.scrollDelta.dy<-5 && dragDetails.scrollDelta.dy>-20 && dragDetails.scrollDelta.dy % 4 == 0){
          if (dragDetails.scrollDelta.dy<0 && dragDetails.scrollDelta.dy>-500){
            prevY = dragDetails.scrollDelta.dy;
            //down
            direction = -1;

            // if (prevY != dragDetails.scrollDelta.dy){
              // prevY = dragDetails.scrollDelta.dy;
            // }else{
            //   return;
            // }
          // if (dragDetails.scrollDelta.dy > 20.0){ // y0 is more bigger than y1 direction DOWN, scale both side
            if (timeScaleBar-1 < 10){
            }else{
              timeScaleBar--;
            }

          }else
          // if (dragDetails.scrollDelta.dy < -20){ // direction UP
          // if (dragDetails.scrollDelta.dy>5 && dragDetails.scrollDelta.dy<20 && dragDetails.scrollDelta.dy % 4 == 0){
          if (dragDetails.scrollDelta.dy>0 && dragDetails.scrollDelta.dy<500){
            direction = 1;
            prevY = dragDetails.scrollDelta.dy;
            // if (prevY != dragDetails.scrollDelta.dy){
            //   prevY = dragDetails.scrollDelta.dy;
            // }else{
            //   return;
            // }
            // const arrTimeScale = [0.1,1,10,50,100,500,1000,5000,10000];
            if (timeScaleBar + 1 > 80){

            }else{
              timeScaleBar++;
            }
          }
          // scaleBarWidth = MediaQuery.of(context).size.width / pow(2, (arrTimeScale.length * 5 / timeScaleBar).floor() );
          int transformScale = (timeScaleBar / 10).floor();
          // int transformScaleCeil = (timeScaleBar / 10).ceil();
          // if (direction == 1){
          //   transformScaleCeil = transformScale;
          // }
          // print("transformScale : "+transformScale.toString()+timeScaleBar.toString());
          //const arrTimeScale = [0.1,1, 10,50, 100,500, 1000,5000,10000];
          //  List<double> arrScaleBar = [ 600000, ... , 6.6, 6];
          // 1ms ~ 0.0010pxl
          // timescalebar is the division before changing to another time period
          // List<double> arrScaleBar = [ 
          //   6,6.6,  7.2,7.8,  8.4,9,  9.6,10.2,  10.8,11.4, 
          //   12,16.8,  21.6,26.4,  31.2,36,  40.8,45.6,  50.4,552, 
          //   60,66, 72,78, 84,90, 96,102, 108,114, 
          //   120,168, 216,264, 312,360, 408,456, 504,552, 
          //   600,660,  720,780,  840,900,  960,1020,  1080,1140, 
          //   1200,1680, 2160,2640, 3120,3600, 4080,4560, 5040,5520, 
          //   6000,11400, 16800,22200, 27600,33000, 38400,43800, 49200,54600, 
          //   60000,114000, 168000,222000, 276000,330000, 384000,438000, 492000,546000, 
          //   600000            
          // ];

          // List<double> arrScaleBar = [ 
          //   6,8.4,10.8,  13.2,15.6,18,  20.4,22.8,25.2,  27.6,
          //   60,84,108,  132,156,180,  204,228,252,  276,
          //   600,840,1080,  1320,1560,1800,  2040,2280,2520,  2760,
          //   3000,3300,3600,  3900,4200,4500,  4800,5100,5400,  5700,
          //   6000,8400,10800,  13200,15600,18000,  20400,22800,25200,  27600,
          //   30000,33000,36000,  39000,42000,45000,  48000,51000,54000,  57000,
          //   60000,84000,108000,  132000,156000,180000,  204000,228000,252000,  276000,
          //   300000,330000,360000,  390000,420000,450000,  480000,510000,540000,  570000,
          //   600000            
          // ];

          // 100ms last
          // TIME_DART : 1409 _ 600 _ 100
          // level :  -1 timeScaleBar :  100 levelScale :  40 arrTimescale[ transformedScale ] | DIVIDER :  600

          // const arrScaleBar = [ 
          //   600000,
          //   546000,492000,  438000,384000,  330000,276000,  222000,168000,  114000,60000, 
          //   54600,49200,  43800,38400,  33000,27600,  22200,16800, 11400,6000, 
          //   5520,5040,  4560,4080,  3600,3120,  2640,2160,  1680,1200, 
          //   1140,1080, 1020,960,  900,840,  780,720,  660,600,            
          //   552,504,  456,408,  360,312,  264,216, 168,120, 
          //   114,108,  102,96,  90,84,  78,72,  66,60, 
          //   552,50.4,  45.6,40.8,  36,31.2,  26.4,21.6,  16.8,12, 
          //   11.4,10.8,  10.2,9.6,  9.0,8.4,  7.8,7.2,  6.6,6 ];

          

          scaleBarWidth = MediaQuery.of(context).size.width / (arrScaleBar[timeScaleBar]) * arrTimeScale[transformScale]/10;
          curTimeScaleBar = (arrTimeScale[transformScale]/10);
          // print("Scalebar Width : " + scaleBarWidth.toString() + " @@ TimeScalebar " +timeScaleBar.toString() + " __ arrScaleBar[]" + arrScaleBar[timeScaleBar].toString()+ " _ arrTimeScale "+arrTimeScale[transformScale].toString());
          // print("WIDTH : " + MediaQuery.of(context).size.width.toString() + " @@ " +(arrScaleBar[timeScaleBar]).toString() + " __ " + (arrTimeScale[transformScale]/10).toString() );

          // print(data);
          // print(dragDetails.localPosition.dx);
          // print(dragDetails.position.dx);
          var data = {
            "timeScaleBar":arrTimeScale[ transformScale ],// label in UI
            "levelScale":timeScaleBar, //scrollIdx
            "posX" : dragDetails.localPosition.dx,
            "direction" : direction
          };
            // js.context.callMethod('setZoomPosition', [1, dragHorizontalDetails.globalPosition.dx, prevY]);

          if (timeScaleBar == -1){
            timeScale = 1;
          }else{
            timeScale = arrTimeScale[ transformScale ];
          }
          js.context.callMethod('setZoomLevel', [json.encode(data)]);
          if ( timeScale == 10000 ){
            horizontalDiff = 0;
            isZooming = false;
          }else{
            if (horizontalDiff > 0){
              isZooming = true;
            }else{
              isZooming = false;
            }
          }


          setState(() {
            
          });


        }
      },
      child: (isRecording > 9 && topRecordingBar > 0)?
        Column(
          children: [
            Container(
              color: const Color(0xFF5b0303),
              width: MediaQuery.of(context).size.width,
              height:topRecordingBar,
              child: Center(
                child : Text("Recording   "+labelDuration, style:const TextStyle(color:Colors.white,fontWeight: FontWeight.bold))
              ),
            ),
            Container(
              color: Colors.black,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height-topRecordingBar,
              child: Stack(
                children: getDataWidgets()
              ),
            ),
          ]
        )
        :
        Container(
          color: Colors.black,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height-topRecordingBar,
          child: Stack(
            children: getDataWidgets()
          ),
        ),

    );
  }

  @override
  Widget build(BuildContext context) {

    // Iterable<Widget> widgetsChannelGainLevel = widgetsChannelGainLevelList
    // final ScrollController canvasController = ScrollController();
    // canvasController.addListener((){
    //   print(canvasController.initialScrollOffset);
    //   print(canvasController.);
    // })
    if (!isFeedback)
      FocusScope.of(context).requestFocus(keyboardFocusNode);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (DragUpdateDetails details){
          dragDetails = details;
        },
        onVerticalDragEnd: (DragEndDetails dragEndDetails){
          const arrTimeScale = [0.1,1,10,50,100,500,1000,5000,10000];
          int direction = 0;

          // print("dragDetails.delta");
          // print(dragDetails.delta);
          if (dragDetails.delta.dx == 0.0 && dragDetails.delta.dy == 0.0){
            return;
          }else
          if (dragDetails.delta.dy > 0.0){ // y0 is more bigger than y1 direction DOWN, scale both side
            direction = -1;
            if (timeScaleBar-1 < 0){
            }else{
              timeScaleBar--;
            }
            // var scale = (dragDetails.delta.dy / MediaQuery.of(context).size.height ).abs();

            // if ( timeScaleBar/2 < 2 ){
            //   if (levelScale < 4){
            //     levelScale++;
            //     // print("> 0 down? (log(2) * MediaQuery.of(context).size.width/2).floor()");
            //     // print((log(2) * MediaQuery.of(context).size.width/2).floor());
            //     int d = ( MediaQuery.of(context).size.width/2 ).floor();
            //     double res = getNearestPower(d);
            //     timeScaleBar = res;
            //   }else{

            //   }
            // }else{
            //   // timeScaleBar = min(2, (timeScaleBar / 2).floor().toDouble() );
            //   timeScaleBar = timeScaleBar / 2;
            // }
          }else
          if (dragDetails.delta.dy < 0){ // direction UP
            direction = 1;
            if (timeScaleBar + 1 > 80){

            }else{
              timeScaleBar++;
            }
            // var scale = (dragDetails.delta.dy / MediaQuery.of(context).size.height ).abs();

            // if (timeScaleBar * 2 > MediaQuery.of(context).size.width / 2 ){
            //   if (levelScale>0){
            //     levelScale--;
            //     print("< 0 down?  (log(2) * MediaQuery.of(context).size.width/2).floor()");
            //     int d = ( MediaQuery.of(context).size.width/2 ).floor();
            //     // double res = (log( d )/log(2)).floor().toDouble();
            //     double res = getNearestPower(d);
            //     timeScaleBar = res;

            //   }else{

            //   }
            // }else{
            //   timeScaleBar = timeScaleBar * 2;
            // }
          }


          // BEFORE CHANGING
          // int transformScale = (timeScaleBar / 10).floor();
          // // print("transformScale : "+transformScale.toString()+timeScaleBar.toString());
          // // scaleBarWidth = MediaQuery.of(context).size.width / arrScaleBar[timeScaleBar] ;
          // scaleBarWidth = MediaQuery.of(context).size.width / arrTimeScale[transformScale] * arrScaleBar[timeScaleBar]/600 ;
          // curTimeScaleBar = (arrTimeScale[transformScale]/10);
          // // print(data);

          // var data = {
          //   "timeScaleBar":arrTimeScale[ transformScale ],// label in UI
          //   "levelScale":timeScaleBar, //scrollIdx
          // };

          int transformScale = (timeScaleBar / 10).floor();


          scaleBarWidth = MediaQuery.of(context).size.width / (arrScaleBar[timeScaleBar]) * arrTimeScale[transformScale]/10;
          curTimeScaleBar = (arrTimeScale[transformScale]/10);
          // print("Scalebar Width : " + scaleBarWidth.toString() + " @@ TimeScalebar " +timeScaleBar.toString() + " __ arrScaleBar[]" + arrScaleBar[timeScaleBar].toString()+ " _ arrTimeScale "+arrTimeScale[transformScale].toString());
          // print("WIDTH : " + MediaQuery.of(context).size.width.toString() + " @@ " +(arrScaleBar[timeScaleBar]).toString() + " __ " + (arrTimeScale[transformScale]/10).toString() );

          // print(data);

          var data = {
            "timeScaleBar":arrTimeScale[ transformScale ],// label in UI
            "levelScale":timeScaleBar, //scrollIdx
            "posX" : dragDetails.localPosition.dx,
            "direction" : direction

          };


          if (timeScaleBar == -1){
            timeScale = 1;
          }else{
            timeScale = arrTimeScale[ transformScale ];
          }            
          // scaleBarWidth = MediaQuery.of(context).size.width / pow(2, 6-timeScaleBar);
          // // print(data);
          // const arrTimeScale = [0.1,1,10,50,100,500,1000,5000,10000];

          // var data = {
          //   "timeScaleBar":arrTimeScale[timeScaleBar],
          //   "levelScale":timeScaleBar,
          // };

          // if (timeScaleBar == -1){
          //   timeScale = 1;
          // }else{
          //   timeScale = arrTimeScale[timeScaleBar];
          // }
          js.context.callMethod('setZoomLevel', [json.encode(data)]);

          // print("scaleBarWidth");
          // print(scaleBarWidth);
          // print(timeScaleBar);
          setState(() {
            
          });
        },
        // behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (DragUpdateDetails details){
          dragHorizontalDetails = details;
        },
        onHorizontalDragDown: (DragDownDetails details){
          dragDownDetails = details;
        },
        onHorizontalDragEnd: (DragEndDetails dragEndDetails){
          if ( isOpeningFile == 1 && isPlaying == 2 ){
            if (dragHorizontalDetails.delta.dx == 0.0 && dragHorizontalDetails.delta.dy == 0.0){
              return;
            }else{
              // const NUMBER_OF_SEGMENTS = 60;
              // final SEGMENT_SIZE = sampleRate;
              // final SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;

              // const arrTimeScale = [0.1,1, 10,50, 100,500, 1000,5000,10000];
              // int transformScale = (timeScaleBar / 10).floor();
              // var timeScale = arrTimeScale[transformScale];
                          
              // int curLevel = calculateLevel(timeScale, sampleRate);
              // // FIND DRAG DISTANCE compared with current segment, current segment compare with SIZE circular buffer, change the scrollValue call setScrollValue
              // if (curLevel == -1){
              //   final skipCounts = 1;
                
              // }else{
              //   double divider = NUMBER_OF_SEGMENTS * 1000 / timeScale;
              //   int singleSegment = (SIZE / divider).floor();
              //   var samplesPerPixel = singleSegment / MediaQuery.of(context).size.width;
              //   var arrCounts = [ 4, 8, 16, 32, 64, 128, 256 ];
              //   final skipCounts = arrCounts[curLevel];

              //   horizontalDragX = dragHorizontalDetails.delta.dx - 50;
              //   if (horizontalDragX <0){
              //     horizontalDragX = 0;
              //   }
              //   if (horizontalDragX > MediaQuery.of(context).size.width - 100 - 20){
              //     horizontalDragX = MediaQuery.of(context).size.width - 100 - 20;
              //   }
              //   js.context.callMethod('setScrollValue', [horizontalDragX, horizontalDragXFix]);
              // }
              
              if (dragHorizontalDetails.delta.dx > 0.0){ // x0 is more bigger than x1 ; Hand Swipe direction LEFT, 
                print("SLIDE RIGHT");
                print(dragDownDetails.localPosition.dx);
                js.context.callMethod('setScrollDrag', [1, dragHorizontalDetails.delta.dx, dragDownDetails.localPosition.dx, horizontalDragX, horizontalDragXFix]);

              }else
              if (dragHorizontalDetails.delta.dx < 0.0){ // x1 is more bigger than x0 ; Hand Swipe direction RIGHT, 
                print("SLIDE LEFT");
                print(dragDownDetails.localPosition.dx);
                js.context.callMethod('setScrollDrag', [-1, dragHorizontalDetails.delta.dx, dragDownDetails.localPosition.dx, horizontalDragX, horizontalDragXFix]);
              }
            }


          }
        },
        child: RawKeyboardListener(
          onKey: (key){
            if (isFeedback) return;

            if ( key.character==null ){
              prevKey="~";              
            //   if ( prevKey.codeUnitAt(0) >= 48 && prevKey.codeUnitAt(0) <= 57 ){
            //     js.context.callMethod('setEventKeypress',[prevKey]);
            //     prevKey="~";
            //   }
            }else{
              if ( key.character.toString().codeUnitAt(0) >= 48 && key.character.toString().codeUnitAt(0) <= 57 ){
                if (prevKey != key.character.toString()){
                  prevKey = key.character.toString();
                  js.context.callMethod('setEventKeypress',[prevKey]);
                }
              }
            }
          },
          focusNode: keyboardFocusNode,
          child: isLoadingFile ? 
              getLoadingWidget(context)
            : ( isFeedback ? getFeedbackWidget() : getMainWidget() ),
        ),
        // child :NotificationListener<UserScrollNotification>(
        //   onNotification: (notification) {
        //     final ScrollDirection direction = notification.direction;
        //     setState(() {
        //       if (direction == ScrollDirection.reverse) {
        //         // _visible = false;
        //       } else if (direction == ScrollDirection.forward) {
        //         // _visible = true;
        //       }
        //     });
        //     return true;
        //   }, child: ListView(
        //     children: [
        //       getMainWidget()
        //     ],
        //   ),

        // ),

        // child: ScrollConfiguration(
        //   behavior: CanvasScrollBehavior(),
        //   child : ListView(
        //     controller: canvasController,
        //     children: [
        //       getMainWidget()
        //     ],
        //   ),
        // )
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     FilePickerResult? result = await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions: ["wav"]);

      //     if (result != null) {
      //       isLocal = true;
      //       Uint8List fileBytes = result.files.first.bytes!;
      //       String fileName = result.files.first.name;
      //       WavReader wavReader = WavReader();
      //       (wavReader).open(pbytes: fileBytes);
      //       // WavReader wav = wavReader;
            
      //       // chartData = fileBytes.toList().cast<double>();
      //       // chartData = wavReader.readSamples().cast<double>();
      //       // sampleData = WaveformData(version: 1, channels: wavReader.numChannels, sampleRate: wavReader.sampleRate, sampleSize: 64, bits: wavReader.bitsPerSample, length: wavReader.audioLength.toInt(), data: wavReader.readSamples().cast<double>() );
      //       channels = [];
      //       try{
      //         // print("wavReader.channels.length");
      //         // print(wavReader.channels.length);
      //         for (int i =0;i<wavReader.channels.length;i++){
      //           // print("wavReader.channels[i]");
      //           // print(wavReader.channels[i]);
      //           // print(wavReader.channels[i]!.cast<double>());
      //           var samples = wavReader.channels[i]!.cast<double>();
      //           // print("samples");
      //           // print(samples);
      //           channels.add( WaveformData(version: 1, channels: wavReader.numChannels, sampleRate: wavReader.sampleRate, sampleSize: 16, bits: wavReader.bitsPerSample, length: wavReader.audioLength.toInt(), data: samples ) );
      //           // print(channels[i]);
      //         }

      //       }catch(err){
      //         print("err");
      //         print(err);
      //       }


      //       // print("chartData.length");
      //       // print(chartData.length);
      //       // sampleData = WaveformData(version: 1, channels: 1, sampleRate: this.sampleRate, sampleSize: 128, bits: 16, length: fileBytes.length, data: List.from(fileBytes) );
      //       // print(fileBytes.toList());
      //       // sampleData = WaveformData.fromJson('{"version":2,"channels":1,"sample_rate":44100,"samples_per_pixel":64,"bits":16,"length":1034,"data":[-23254,16644,-30935,20205,-16593,16930,-11736,13287,-18606,13789,-10566,13918,-13824,14620,-11527,8676,-12231,15098,-11159,9512,-12696,14081,-10952,11740,-12275,11320,-10848,9477,-14906,17874,-11615,12593,-13266,11521,-16097,12726,-11027,11909,-13936,12957,-12427,13551,-13273,12631,-12068,12180,-16960,10204,-11003,15350,-9547,7862,-11642,9156,-12916,11414,-12254,12014,-10904,10699,-19290,17371,-18661,14840,-10483,7772,-12001,14139,-11743,12346,-8817,7486,-13723,12268,-12806,11932,-10766,9278,-14363,10833,-10968,10201,-7769,11178,-9181,10532,-11108,10264,-9397,9859,-10956,8993,-10164,9633,-9415,11935,-9315,7894,-11991,8480,-10056,9279,-11766,10108,-8676,9179,-6572,6416,-10415,8478,-9494,10295,-10625,10694,-12682,10206,-7907,7254,-8939,6862,-7444,7746,-9598,10933,-8451,7638,-9671,10051,-11103,8560,-8351,8265,-7618,10012,-9122,6387,-8906,6005,-7509,6537,-10554,8008,-9442,7675,-7059,5806,-8574,5545,-6884,6272,-8838,7777,-7123,6712,-6712,7930,-7544,7704,-7624,7634,-7423,9566,-10375,7497,-7437,6828,-8448,7644,-7928,7369,-5000,6147,-5130,6864,-8465,7033,-6381,5755,-6005,4566,-4916,5251,-5549,4577,-8633,8432,-5557,5441,-7610,6335,-6404,8627,-6402,5347,-6471,5600,-5128,5529,-6062,5212,-7089,4902,-4649,4729,-5128,4554,-5152,4176,-5765,3603,-5866,4989,-3389,4127,-5480,4420,-6319,5139,-4871,4421,-3887,5301,-5045,3809,-5203,3625,-4372,4901,-5183,4618,-5778,4335,-3816,3887,-4553,5277,-4152,3205,-3674,3579,-3696,3572,-3956,5101,-4741,5534,-5473,3850,-4049,3141,-4748,3341,-3427,4422,-4851,3985,-4356,4846,-3412,4368,-3631,4046,-3406,2807,-3376,4007,-3634,3886,-3689,3219,-2725,2106,-3044,3071,-3348,3085,-3919,3154,-4708,3611,-3795,3468,-2688,4142,-3358,2785,-3194,3590,-2778,2962,-2843,3011,-3312,3016,-3596,2896,-2266,2318,-2694,2653,-2403,2834,-2194,1972,-2739,2152,-2862,1949,-2803,3438,-2871,2196,-1829,2132,-2549,2528,-2377,1562,-2152,2535,-2630,2717,-2292,1672,-2840,2415,-2307,2046,-1984,1766,-2259,2241,-1898,1693,-1497,1362,-1639,1986,-1748,2077,-1815,1743,-1906,1791,-1610,1541,-1629,1726,-1522,1478,-1665,1841,-1872,1383,-2102,1654,-2218,1754,-1710,1342,-1383,1168,-1351,1371,-1122,1323,-1633,1467,-1011,1221,-1144,1533,-1512,2114,-1038,687,-1687,1691,-1081,1380,-1671,1373,-1489,957,-1635,1308,-1142,975,-1216,1315,-1038,1183,-1632,1497,-1265,1182,-896,1011,-1273,965,-946,1027,-913,983,-1194,1121,-1206,1065,-1218,1070,-745,883,-997,1082,-1454,1274,-1188,1147,-1228,1031,-720,767,-1287,1075,-663,727,-607,903,-961,1347,-779,761,-1336,1049,-892,861,-1114,1363,-942,1068,-1154,1125,-784,924,-774,822,-905,860,-825,854,-551,509,-566,597,-932,739,-776,868,-665,638,-466,647,-541,667,-887,873,-891,812,-570,803,-762,716,-542,788,-618,941,-577,681,-648,883,-778,705,-820,880,-749,699,-738,903,-875,1091,-745,747,-576,528,-611,641,-548,630,-501,454,-625,517,-436,377,-573,589,-486,487,-462,458,-310,323,-376,477,-498,675,-342,454,-653,618,-550,454,-549,409,-492,659,-621,678,-499,447,-414,508,-419,354,-446,379,-609,568,-740,599,-542,456,-491,398,-374,365,-425,472,-446,421,-460,460,-586,529,-387,404,-599,548,-464,411,-410,369,-300,253,-454,444,-369,369,-441,374,-244,314,-467,428,-410,400,-310,450,-508,382,-373,414,-300,368,-364,374,-439,356,-440,472,-351,332,-429,348,-291,308,-336,318,-386,338,-350,364,-276,329,-326,314,-311,308,-263,286,-279,357,-283,349,-260,284,-317,300,-252,224,-230,204,-293,288,-300,399,-221,297,-404,372,-297,161,-178,270,-257,317,-270,253,-325,305,-257,225,-388,326,-220,211,-240,239,-277,307,-267,301,-331,327,-171,297,-270,316,-226,217,-338,319,-273,326,-224,232,-282,230,-239,216,-279,244,-235,229,-392,327,-333,275,-246,217,-253,215,-258,247,-169,213,-239,252,-212,217,-304,303,-204,199,-160,202,-284,244,-264,355,-254,207,-209,181,-147,204,-245,222,-200,195,-199,239,-294,238,-200,210,-152,167,-182,183,-261,152,-175,167,-276,284,-225,173,-208,187,-210,206,-213,212,-176,169,-202,183,-131,143,-187,170,-217,231,-202,209,-215,194,-214,227,-270,232,-283,332,-124,181,-193,202,-291,294,-170,176,-203,267,-204,174,-202,183,-160,205,-155,159,-270,259,-132,144,-159,195,-221,201,-169,189,-212,216,-146,143,-158,171,-193,179,-154,178,-211,158,-148,149,-148,176,-194,175,-143,150,-177,193,-170,146,-142,136,-153,157,-166,153,-203,181,-154,185,-164,152,-161,149,-122,145,-169,113,-187,140,-210,188,-149,163,-134,118,-157,220,-78,90,-124,157,-142,94,-188,143,-100,88,-130,108,-180,171,-130,100,-128,169,-168,141,-136,152,-144,116,-90,98,-144,151,-109,106,-145,155,-62,118,-137,165,-173,156,-160,144,-87,86,-136,161,-119,178,-113,106,-85,99,-99,98,-84,71,-148,105,-135,115,-92,105,-100,78,-87,87,-84,84,-95,118,-79,84,-101,113,-93,98,-124,86,-105,99,-111,104,-99,119,-101,100,-98,106,-127,101,-96,86,-86,107,-104,99,-67,72,-92,99,-99,98,-101,135,-122,89,-111,124,-85,75,-113,122,-84,99,-82,83,-134,116,-55,71,-104,63,-90,89,-95,86,-80,74,-80,119,-100,78,-97,94,-82,76,-118,104,-139,157,-123,132,-99,96,-100,76,-80,92,-91,96,-80,72,-83,92,-93,79,-72,70,-55,49,-69,60,-72,65,-89,72,-98,62,-84,78,-60,70,-90,83,-83,80,-98,78,-82,62,-88,72,-73,87,-57,66,-96,87,-71,63,-75,64,-47,56,-92,50,-74,80,-48,64,-116,84,-63,70,-69,59,-73,71,-91,91,-62,58,-74,62,-65,62,-49,60,-50,51,-92,71,-103,80,-91,92,-56,58,-56,51,-75,75,-68,83,-69,74,-66,84,-80,71,-75,72,-60,46,-73,68,-46,50,-71,60,-39,48,-68,56,-69,77,-60,50,-71,66,-69,77,-64,74,-71,62,-69,51,-43,40,-44,52,-63,70,-53,50,-58,62,-76,79,-71,83,-65,65,-47,46,-82,86,-45,40,-27,35,-55,41,-37,33,-48,58,-50,50,-48,35,-34,35,-56,51,-49,48,-53,55,-73,55,-50,46,-35,37,-42,60,-37,27,-49,64,-65,39,-41,49,-54,56,-49,54,-41,37,-47,60,-33,50,-47,32,-44,39,-53,53,-46,35,-44,47,-34,39,-37,31,-53,50,-41,53,-42,48,-42,42,-33,30,-41,50,-61,43,-35,29,-54,48,-38,44,-35,27,-50,41,-50,30,-54,48,-41,45,-29,25,-34,27,-43,39,-44,41,-24,25,-29,35,-36,28,-35,38,-34,34,-41,26,-29,22,-37,34,-55,54,-35,35,-27,28,-45,34,-38,29,-39,48,-34,33,-47,40,-25,27,-35,25,-32,34,-32,41,-44,44,-34,21,-33,33,-39,40,-27,29,-38,49,-33,37,-28,29,-28,27,-26,27,-30,31,-28,23,-20,23,-32,34,-20,25,-21,20,-29,26,-31,26,-35,28,-28,31,-29,24,-21,14,-32,32,-25,23,-35,34,-27,25,-27,24,-19,19,-27,31,-36,22,-21,14,-31,36,-30,29,-32,29,-26,31,-31,27,-27,23,-17,12,-37,26,-27,15,-23,24,-21,22,-14,19,-26,19,-15,18,-29,27,-25,23,-18,18,-18,23,-21,21,-18,17,-29,24,-19,19,-24,15,-21,18,-19,16,-25,26,-17,17,-16,20,-15,17,-16,15,-22,15,-18,18,-19,21,-21,18,-21,15,-22,17,-22,17,-19,25,-25,22,-22,17,-18,19,-14,13,-17,17,-15,14,-22,22,-16,15,-25,19,-28,32,-15,18,-15,21,-19,21,-16,14,-16,17,-21,18,-16,15,-14,12,-14,15,-16,22,-22,27,-19,16,-25,19,-20,20,-22,19,-16,11,-12,11,-18,15,-22,18,-11,12,-18,15,-14,12,-18,13,-15,13,-16,12,-14,11,-13,11,-18,15,-14,12,-18,16,-12,12,-14,15,-23,17,-13,14,-13,12,-13,12,-13,11,-16,14,-11,10,-13,14,-16,16,-19,17,-15,17,-15,9,-10,12,-11,7,-15,11,-12,9,-13,14,-13,12,-15,12,-17,16,-12,11,-12,14,-13,14,-10,10,-13,11,-12,11,-14,11,-13,14,-13,11,-13,10,-17,14,-15,11,-8,8,-15,16,-16,11,-12,10,-11,10,-12,14,-9,8,-11,11,-18,15,-12,8,-8,10,-12,11,-9,7,-10,9,-12,11,-11,11,-9,7,-10,10,-9,9,-11,9,-9,9,-12,8,-9,9,-9,6,-11,10,-11,8,-9,8,-9,9,-12,13,-11,9,-14,14,-12,12,-12,9,-10,10,-11,12,-15,10,-11,7,-11,10,-11,11,-12,8,-11,10,-10,12,-12,10,-10,7,-8,7,-5,4,-7,5,-12,11,-10,9,-9,7,-9,7,-8,7,-10,10,-12,10,-10,9,-8,8,-8,6,-14,9,-8,6,-11,9,-7,6,-6,7,-12,11,-12,10,-10,8,-8,6,-9,8,-7,6,-8,5,-10,6,-8,7,-11,8,-6,5,-6,7,-7,4,-7,9,-5,4,-5,3,-7,4,-8,9,-8,6,-6,5,-5,5,-7,6,-7,6,-5,5,-8,7,-8,8,-4,5,-10,6,-5,3,-5,4,-5,4,-5,5,-8,4,-6,4,-6,6,-5,3,-8,6,-7,6,-7,5,-5,5,-7,6,-8,7,-5,3,-8,7,-5,5,-7,6,-8,5,-8,6,-5,4,-6,7,-6,5,-6,5,-5,4,-4,4,-5,5,-7,5,-6,6,-5,4,-4,3,-7,5,-5,3,-6,6,-6,6,-6,6,-5,4,-7,6,-8,6,-7,5,-6,6,-5,3,-4,4,-5,5,-4,4,-6,4,-5,6,-7,5,-3,3,-5,4,-5,4,-5,3,-5,3,-4,3,-4,4,-5,4,-5,4,-4,3,-3,3,-4,3,-5,5,-7,5,-5,5,-5,5,-4,3,-5,3,-4,3,-3,3,-3,2,-3,2,-5,5,-4,3,-5,4,-4,3,-4,3,-3,2,-3,3,-4,2,-5,4,-5,2,-4,2,-5,3,-4,3,-4,3,-2,1,-3,2,-3,2,-5,4,-4,2,-4,3,-5,3,-3,3,-4,2,-3,3,-3,2,-5,3,-2,2,-6,4,-5,4,-3,2,-5,4,-3,2,-3,2,-4,3,-4,4,-4,2,-4,2,-2,2,-3,2,-4,2,-4,4,-3,2,-3,2,-2,1,-2,2,-3,2,-3,3,-3,2,-2,2,-3,2,-3,2,-3,2,-3,3,-3,2,-3,2,-3,2,-2,1,-2,3,-3,1,-2,2,-4,3,-3,2,-3,3,-3,2,-3,2,-2,1,-2,1,-3,2,-2,2,-2,1,-3,1,-2,1,-3,2,-2,1,-2,1,-2,1,-3,2,-3,2,-4,3,-3,2,-3,2,-3,2,-2,1,-3,1,-2,2,-2,2,-2,1,-3,1,-3,2,-2,1,-3,1,-3,1,-3,1,-2,1,-2,1,-3,1,-3,2,-2,1,-2,1,-2,0,-2,1]}');
            
      //       currentRecordingTime = DateTime.now();
      //       duration = currentRecordingTime.difference(startRecordingTime);
      //       labelDuration = ( (duration.inHours) ).toString()+":"+( (duration.inMinutes) ).toString()+":"+(duration.inSeconds % 60).toString();

      //       setState(() {
              
      //       });
            
      //     }          
      //   },
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  MaterialStateProperty<Color> getColor(Color color, Color colorPressed){
    final getColor = (Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)){
        return colorPressed;
      }else{
        return color;
      }
    };

    return MaterialStateProperty.resolveWith(getColor);
  }

  calculateLevel(timescale, sampleRate){
    final rawPocket = timescale * sampleRate / MediaQuery.of(context).size.width /1000;
    var currentLevel = 6;
    var i = arrCounts.length-2;
    if ((rawPocket).floor() < 4 ){
      currentLevel = -1;
    }else{
      for ( ; i>=0; i--){
        if (arrCounts[i+1] >= rawPocket && arrCounts[i]< rawPocket){
          currentLevel = i;
        }
      }
    }

    return currentLevel;
  }

  String getStrMinTime(horizontalDragX, horizontalDragXFix, maxTime){
    String strMinTime = '';
    double minTime = horizontalDragX/horizontalDragXFix * maxTime;
    // print("minTime");
    // print(minTime);
    if (minTime > 3600){
      final lastDecimals = (minTime - minTime.floor()).toStringAsFixed(3).replaceFirst("0.","");
      strMinTime = ( (minTime / 3600).floor() % (3600 * 24) ).toString().padLeft(2,"0") + ":" + ( (minTime / 60).floor() % 3600 ).toString().padLeft(2,"0") + ":" + (minTime.floor() % 60).toString().padLeft(2,"0") + " " + lastDecimals;
    }else{
      final lastDecimals = (minTime - minTime.floor()).toStringAsFixed(3).replaceFirst("0.","");
      strMinTime = ( (minTime / 60).floor() % 3600 ).toString().padLeft(2,"0") + ":" + (minTime.floor() % 60).toString().padLeft(2,"0") + " " + lastDecimals;
    }
    // print("minTime");
    // print(strMinTime);
    return strMinTime;

  }

  getLoadingWidget(BuildContext context) {
    return Container(
      color: const Color(0x77CCCCFF),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height:10),
          Text("Loading file..."),
        ],
      ),
    );
  }


}


/// Private calss for storing the chart series data points.
class _ChartData {
  _ChartData(this.country, this.sales);
  final int country;
  final num sales;
}