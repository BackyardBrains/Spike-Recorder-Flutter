
/* ---------------------------------------------------
Old Data Below

--------------------------------------------------- */

const REDRAW_TIMEOUT = 500;
const MAX_MARKERS = 200;
const AUDIO_CHANNEL_MAX = 2;
let deviceType = "serial";
let reportId = "";
let port;
let sabDraw;
let idxDraw;
let realTimeLevel;
let CHANNEL_COUNT_FIX = 2;
let SERIAL_CHANNEL_COUNT_FIX = 6;
let DISPLAY_CHANNEL_COUNT_FIX = 1;
let sbwNode;

let sabEvents;
let sabEventPositionResult;


let isInitHidChannel = true;

let os;
let versionNumber;
let userAgent;
let deviceDetail;

let maxStaticTime = 100000000000;
let curStaticTime = 100000000000;

//FILE
let isResetPlayback = false;
let wav;
let openedWavSampleLength = 0;
let fileHandle;
let openWavFileHandle;
let sampleRateFix = 10000;
let timeScaleBar = 10000;
let levelScale = 80;
let startHeadWavPos;
let endTailWavPos;
let audioSourceEnded;
let isReset = 0;
let isEnded = false;
let isPlaybackStart = true;
let isPlayingWav = false;
let sumInitialPlaybackTime = 0;

let curTimeDivision = 0;
let prefixTimeSeconds = 0;
let curTimeSeconds = 0;
let currentDataPosition = 0;
let incSkip = 0;


let isRecordingParam = 0;
// let draw_states = [];
let WASM;
const importObject = {
  imports: {
    gain(v,arg) {
      console.log(arg);
    },
  },
};

// const memory = new WebAssembly.Memory({
//   initial: 10,
//   maximum: 100,
// });

// WebAssembly.instantiateStreaming(fetch("build/web/a.out.wasm",{
//   headers:{
//     'Content-Type':'Content-Type: application/wasm'
//   }
// }), {
//   js: { mem: memory },
// }).then((obj) => {
//   // const summands = new Uint32Array(memory.buffer);
//   // for (let i = 0; i < 10; i++) {
//   //   summands[i] = i;
//   // }
//   // const sum = obj.instance.exports.accumulate(0, 10);
//   console.log(obj);
// });
// fetch("build/web/a.out.wasm")
//   .then((response) => response.arrayBuffer())
//   .then((bytes) => WebAssembly.instantiate(bytes, importObject))
//   .then((result) => {
//     console.log("WASM.multiply(10,99)");
//     WASM = result.instance.exports;
//     console.log(WASM.multiply(10,99));
//   })
//   .catch((err)=>{
//     console.log("err");
//     console.log(err);
//   });

let extraChannel = 0;
const arrCounts = [ 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048 ];
// const arrTimescale = [ 600000,60000, 6000, 1200, 600, 120, 60, 12, 6 ];
// List<int> arrTimescale = [10000,5000,2500,1250,625,320,160,80,40,10];
let arrTimescale;
// let arrTimescale = [ 
//   // 600000, 600000, 600000, 600000, 600000,
//   // 492000, 384000, 276000, 168000, 60000, 
//   600000 * 10,
//   546000 * 10,492000 * 10,  438000 * 10,384000 * 10,  330000 * 10,276000 * 10,  222000 * 10,168000 * 10,  114000 * 10,60000 * 10, //0.001ms
//   // 465000, 330000 , 195000, 60000, 
//   54600 * 10,49200 * 10,  43800 * 10,38400 * 10,  33000 * 10,27600 * 10,  22200 * 10,16800 * 10, 11400 * 10,6000 * 10, //0.1ms
//   5520 * 10,5040 * 10, 4560 * 10,4080 * 10,  3600 * 10,3120 * 10,  2640 * 10,2160 * 10,  1680 * 10,1200 * 10, //1ms
//   1140 * 10,1080 * 10, 1020 * 10,960 * 10,  900 * 10,840 * 10,  780 * 10,720 * 10,  660 * 10,600 * 10, //10ms
  
//   552 * 10,504 * 10,  456 * 10,408 * 10,  360 * 10,312 * 10,  264 * 10,216 * 10, 168 * 10,120 * 10, //50ms
//   114 * 10,108 * 10,  102 * 10,96 * 10,  90 * 10,84 * 10,  78 * 10,72 * 10,  66 * 10,60 * 10, //100ms
  
//   55.2 * 10,50.4 * 10,  45.6 * 10,40.8 * 10,  36 * 10,31.2 * 10,  26.4 * 10,21.6 * 10,  16.8 * 10, 12 * 10,  // 500s
//   11.4 * 10,10.8 * 10,  10.2 * 10,9.6 * 10,  9.0 * 10,8.4 * 10,  7.8 * 10,7.2 * 10,  6.6 * 10,6 * 10 ]; // 1s

let myTimeScale = [];
let factor = 0;
let factors =[1,2,10,20,100,1000,10000,100000];
let targets = [6,12,60,120,600,1200,6000,60000,600000];
let idx = 0;
for (let idxBar = 0 ; idxBar < 81 ; idxBar++){
  const myIdx = Math.floor( idx / 10 );
  if (idxBar % 10 == 0){
    factor = 0;
  }
  const range = targets[myIdx+1] - targets[myIdx];
  // myTimeScale.push( Math.round(range *100 * (1+factor/10 * factors[myIdx]) )/10 );
  let res = (targets[myIdx] + (range * factor / 10)) * 10;
  if (isNaN (res)) res = targets[myIdx] * 10;

  myTimeScale.push( res );
  factor++;
  idx++;
}
arrTimescale =  myTimeScale.reverse();
// console.log("myTimeScale : ", idx, factor, myTimeScale);
// console.log("myTimeScaleReal : ", arrTimescale.reverse());

// let arrScaleBar = [ 
//   0.1,
//   0.1098901099,0.1219512195,0.1369863014,0.15625,0.1818181818,0.2173913043,0.2702702703,0.3571428571,0.5263157895,1,
//   1.098901099,1.219512195,1.369863014,1.5625,1.818181818,2.173913043,2.702702703,3.571428571,5.263157895,10,
//   10.86956522,11.9047619,13.15789474,14.70588235,16.66666667,19.23076923,22.72727273,27.77777778,35.71428571,50,
//   52.63157895,55.55555556,58.82352941,62.5,66.66666667,71.42857143,76.92307692,83.33333333,90.90909091,100,
//   108.6956522,119.047619,131.5789474,147.0588235,166.6666667,192.3076923,227.2727273,277.7777778,357.1428571,500,
//   526.3157895,555.5555556,588.2352941,625,666.6666667,714.2857143,769.2307692,833.3333333,909.0909091,1000,
//   1086.956522,1190.47619,1315.789474,1470.588235,1666.666667,1923.076923,2272.727273,2777.777778,3571.428571,5000,
//   5263.157895,5555.555556,5882.352941,6250,6666.666667,7142.857143,7692.307692,8333.333333,9090.909091,10000];

// let myArrScaleBar = [];
// // let mytargets = [0.6,6,60, 300,600,3000, 6000,30000,60000];
// const circularBuffersTime = 6000 * 10;
// for (let idxBar = 0 ; idxBar < 81 ; idxBar++){
//   // const divIdx = Math.floor( idxBar / 10 );
//   // myTimeScale.push( Math.round(range *100 * (1+factor/10 * factors[myIdx]) )/10 );

//   let res = circularBuffersTime / (arrTimescale[idxBar]/10);
//   // if (isNaN (res)) res = targets[divIdx] * 10;

//   myArrScaleBar.push( res );
// }

// console.log("My Arr Scale Bar : ", myArrScaleBar, arrScaleBar);

var AudioContext = window.AudioContext || window.webkitAudioContext;
var ac = new AudioContext();

let isPlaying = 0;

async function pauseResume(flag){
  console.log("flag");
  console.log(flag);
  let sabDrawingState = new Int32Array(sabDraw.draw_states[0]);
  console.log( "Events ", new Uint16Array(sabDraw.eventPosition) );
  // sabDrawingState[DRAW_STATE.IS_LOG] = 3;
  

  if (flag == 1){
    try{
      await ac.suspend();
    }catch(err){
      window.callbackErrorLog( ["error_general", "Audio Context - Pausing Error"] );
      console.log("pause audio error " , err);
    }
    try{
      isPlaying = 2;
      sbwNode.pauseResumeProcessor(isPlaying);
    }catch(err){
      window.callbackErrorLog( ["error_general", deviceType + " Pausing - Resume Error"] );
      console.log("pause audio error " , err);
    }
  }else
  if (flag == 2 || flag == 3){
    try{
      await ac.resume();
    }catch(err){
      window.callbackErrorLog( ["error_general", "Audio - Resume Error"] );
      console.log("resume audio error " , err);
    }
    try{
      isPlaying = 1;
      sbwNode.pauseResumeProcessor(isPlaying);
    }catch(err){
      window.callbackErrorLog( ["error_general", deviceType + " Serial - Resume Error"] );
      console.log("pause audio error " , err);
    }

    if (flag == 3){
      let sabDrawingState = new Int32Array(sabDraw.draw_states[0]);
      sabDrawingState[DRAW_STATE.CURRENT_START] = 0;
      window.callbackHorizontalDiff( [ 0 ]);
      // console.log("ARROW RIGHT");
    }

  }


}

let sampleRate;

let channel = new MessageChannel();
let audioChannel = new MessageChannel();
let channelSetting = new MessageChannel();
let channelWasmWorkerResult = new MessageChannel();
let channelSignalWorkerResult = new MessageChannel();
let source;

let signalWorker = undefined;
let fileWorker = undefined;
let wavFileReaderWorker = undefined;

let sequentialSignalWorker = undefined;
let sequentialFileWorker = undefined;


const SERIAL_WRITE_CONFIG = {
  bytesPerState: Uint32Array.BYTES_PER_ELEMENT,
  bytesPerSample: Uint8Array.BYTES_PER_ELEMENT,
};

const SERIAL_WRITE_STATE = {
  'HEAD_IDX' : 0,
  'TAIL_IDX' : 1,
};
let sabSerialWriteData;


const CONFIG = {
  bytesPerSample: Int32Array.BYTES_PER_ELEMENT,
  bytesPerState: Int32Array.BYTES_PER_ELEMENT,
  bytesPerPosition: Uint32Array.BYTES_PER_ELEMENT,
};

const PLAYBACK_STATE = {
  'SCROLL_VALUE': 0,
  'DRAG_VALUE': 1,
};

const DRAW_STATE = {
  'LEVEL': 0,
  'DIVIDER': 1,
  'SKIP_COUNTS':2,
  'SURFACE_WIDTH':3,
  'TIME_SCALE':4,
  'SAMPLE_RATE':5,
  'HEAD_IDX':6,
  'TAIL_IDX':7,
  'CHANNEL_COUNTS':8,
  'CURRENT_HEAD' : 9,
  'CURRENT_START' : 10,
  'IS_FULL' : 11,
  'IS_LOG' : 12,
  'EXTRA_CHANNELS' : 13,
  'MAX_SAMPLING_RATE' : 14,
  'MIN_CHANNELS' : 15,
  'MAX_CHANNELS' : 16,
  'SAMPLING_RATE_1' : 17,
  'SAMPLING_RATE_2' : 18,
  'SAMPLING_RATE_3' : 19,
  'SAMPLING_RATE_4' : 20,
  'SAMPLING_RATE_5' : 21,
  'SAMPLING_RATE_6' : 22,

  'EVENT_FLAG' : 25,
  'EVENT_NUMBER' : 26,
  'EVENT_POSITION' : 27,
  'EVENT_COUNTER' : 28,
  //to filter array of events
  'EVENT_HEAD' : 29,
  'EVENT_TAIL' : 30,

  'DIRECT_LOAD_FILE' : 40,
  'HORIZONTAL_DRAG' : 41,
  'HORIZONTAL_SCROLL_VALUE' : 42,

  'WRITING_FILE_STATUS' : 50,
  'IS_LOW_PASS_FILTER' : 51,
  'IS_HIGH_PASS_FILTER' : 52,
  'LOW_PASS_FILTER' : 53,
  'HIGH_PASS_FILTER' : 54,
  'IS_THRESHOLDING' : 55,
  'AVERAGE_SNAPSHOT_THRESHOLDING' : 56,
  'VALUE_THRESHOLDING' : 57,
  'SELECTED_CHANNEL_THRESHOLDING' : 58,

};

const WRITE_CONFIG = {
  bytesPerState : Int32Array.BYTES_PER_ELEMENT,
  state_length : 10,
};
const WRITE_STATE = {
  'WRITE_CHANNEL_COUNT':0,
  'IS_RECORDING':1,
  'PROCESSED_COUNT':2,
};

let sabWriteState;
if (window.SharedArrayBuffer){
  sabWriteState = new SharedArrayBuffer(WRITE_CONFIG.state_length * WRITE_CONFIG.bytesPerState);
}



function refreshAudioSetting(setting){
  channelSetting.port1.postMessage(setting);
}

function calculateLevel(timescale){
  let rawPocket = timescale * sampleRate / window.innerWidth /1000;
  let currentLevel = arrCounts.length - 1;
  let i = arrCounts.length-2;
  if (Math.floor(rawPocket) < 4 ){
    currentLevel = -1;
  }else{
    for ( ; i>=0; i--){
      if (arrCounts[i+1] >= rawPocket && arrCounts[i]< rawPocket){
        currentLevel = i + 1;
      }
    }
    currentLevel = currentLevel + incSkip;
    if (currentLevel > arrCounts.length - 1){
      currentLevel = arrCounts.length - 1;
    }
  }

  return currentLevel;
}

async function setEventKeypress(key){
  if ( key.charCodeAt(0) >= 48 && key.charCodeAt(0) <= 57){
    let sabDrawingState = new Int32Array(sabDraw.draw_states[0]);
    sabDrawingState[DRAW_STATE.EVENT_FLAG] = 1;
    sabDrawingState[DRAW_STATE.EVENT_NUMBER] = key;
    console.log("function setEventKeypress " + key);
  }
}

function initializeDrawState(channelCount, currentLevel, divider, sampleRate){
  let draw_states = [];
  for (let c = 0; c < channelCount; c++){
    // console.log("currentLevel : ",currentLevel);
    let draw_state = new Int32Array(sabDraw.draw_states[c]);
    draw_state[DRAW_STATE.LEVEL] = currentLevel;
    draw_state[DRAW_STATE.SKIP_COUNTS] = arrCounts[currentLevel];
    draw_state[DRAW_STATE.DIVIDER] = divider;
    draw_state[DRAW_STATE.SAMPLE_RATE] = sampleRate;
    draw_state[DRAW_STATE.CHANNEL_COUNTS] = 2;
    draw_state[DRAW_STATE.SURFACE_WIDTH] = window.innerWidth;
    draw_state[DRAW_STATE.IS_LOW_PASS_FILTER] = 0;
    draw_state[DRAW_STATE.IS_HIGH_PASS_FILTER] = 0;
    draw_states.push(draw_state);
  }
  return draw_states;
}

function initializeSabDraw(){
  if (sabDraw){
    // changing from serial to hid gives draw_states to 12
    delete sabDraw;
  }
  sabDraw = {
    channelCount : CHANNEL_COUNT_FIX,
    playback_states : [
      new SharedArrayBuffer(CONFIG.bytesPerPosition * 20)            
    ],
    channelDisplays : new SharedArrayBuffer(CONFIG.bytesPerPosition * 10),
    draw_states : [
      new SharedArrayBuffer(CONFIG.bytesPerState * 90),
      new SharedArrayBuffer(CONFIG.bytesPerState * 90),
      new SharedArrayBuffer(CONFIG.bytesPerState * 90),
      new SharedArrayBuffer(CONFIG.bytesPerState * 90),
      new SharedArrayBuffer(CONFIG.bytesPerState * 90),
      new SharedArrayBuffer(CONFIG.bytesPerState * 90),
    ],
    levels : [
      new SharedArrayBuffer( 180000 * 2 ),
      new SharedArrayBuffer( 180000 * 2 ),
      new SharedArrayBuffer( 200000 * 20 ),
      new SharedArrayBuffer( 200000 * 20 ),
      new SharedArrayBuffer( 200000 * 20 ),
      new SharedArrayBuffer( 200000 * 20 ),
    ],
    events : new SharedArrayBuffer(MAX_MARKERS * Uint8Array.BYTES_PER_ELEMENT),
    eventPosition : new SharedArrayBuffer( MAX_MARKERS * Uint32Array.BYTES_PER_ELEMENT ),
    eventPositionResult : new SharedArrayBuffer( MAX_MARKERS * Float32Array.BYTES_PER_ELEMENT ),
    eventsCounter : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT ),
  };
}


async function setScrollValue(scrollValue, scrollBarWidth){
  curTimeDivision = scrollValue / scrollBarWidth;
  const NUMBER_OF_SEGMENTS = 60;
  const SEGMENT_SIZE = sampleRate;
  let SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
  const SIZE_LOGS2 = 10;
  let size = SIZE;
  size/=2;
  let envelopeSizes = [];
  let i = 0;
  for (;i<SIZE_LOGS2;i++){
      const sz = Math.floor(size);
      envelopeSizes[i] = sz;
      size/=2;
  }      
  SIZE = SIZE /6;

  let sabDrawingState = new Int32Array(sabDraw.draw_states[0]);
  let skipCounts = sabDrawingState[DRAW_STATE.SKIP_COUNTS];
  let level = sabDrawingState[DRAW_STATE.LEVEL];
  let divider = sabDrawingState[DRAW_STATE.DIVIDER] / 10;

  const singleSegment = envelopeSizes[level];
  let currentPercentageDataPosition = Math.floor(openedWavSampleLength * curTimeDivision );
  currentDataPosition = currentPercentageDataPosition;
  curTimeSeconds = currentDataPosition / sampleRate;
  sumInitialPlaybackTime = curTimeSeconds;
  window.drawElapsedTime([curTimeSeconds]);

  //small data | head is below envelopeSizes[level] | sample below single segment
  let startPos = currentPercentageDataPosition - Math.floor(SIZE);
  let endPos = currentPercentageDataPosition;
  if (startPos < 0) startPos = 0;



  // still at the same range, do not load?
  if (startPos >= startHeadWavPos && endPos <= endTailWavPos) {
      startHeadWavPos = startPos;
      endTailWavPos = endPos;
      let playbackState = new Uint32Array(sabDraw.playback_states[0]);
      playbackState[PLAYBACK_STATE.DRAG_VALUE] = 0;  
  
      const numberOfChannels = DISPLAY_CHANNEL_COUNT_FIX;
      if (deviceType == 'audio'){
        sbwNode.clearBuffer(sabDraw);
        if (startPos < 0) {
          startPos = 0;
          await sbwNode.loadAudioBuffer(wav,openFileMarkers, sampleRate, sabDraw,numberOfChannels, startPos, endPos);
        }else{
          await sbwNode.loadAudioBuffer(wav,openFileMarkers, sampleRate, sabDraw,numberOfChannels, startPos, endPos);
        }
      }else{
        sbwNode.clearBuffer(sabDraw);
        if (startPos < 0) {
          startPos = 0;
          await sbwNode.loadSerialBuffer(wav,openFileMarkers, sampleRate, sabDraw,numberOfChannels, startPos, endPos);
        }else{
          await sbwNode.loadSerialBuffer(wav,openFileMarkers, sampleRate, sabDraw,numberOfChannels, startPos, endPos);
        }
      }      
    // }
  
  }else{
    startHeadWavPos = startPos;
    endTailWavPos = endPos;
    let playbackState = new Uint32Array(sabDraw.playback_states[0]);
    playbackState[PLAYBACK_STATE.DRAG_VALUE] = 0;  

    const numberOfChannels = DISPLAY_CHANNEL_COUNT_FIX;
    if (deviceType == 'audio'){
      sbwNode.clearBuffer(sabDraw);
      if (startPos < 0) {
        startPos = 0;
        await sbwNode.loadAudioBuffer(wav,openFileMarkers, sampleRate, sabDraw,numberOfChannels, startPos, endPos);
      }else{
        await sbwNode.loadAudioBuffer(wav,openFileMarkers, sampleRate, sabDraw,numberOfChannels, startPos, endPos);
      }
    }else{
      sbwNode.clearBuffer(sabDraw);
      if (startPos < 0) {
        startPos = 0;
        await sbwNode.loadAudioBuffer(wav,openFileMarkers, sampleRate, sabDraw,numberOfChannels, startPos, endPos);
      }else{
        await sbwNode.loadSerialBuffer(wav,openFileMarkers, sampleRate, sabDraw,numberOfChannels, startPos, endPos);
      }
    }
  }

  // 1 percentage difference
  // openedWavSampleLength - samples per channel
  // get current percentage,
  // get current scale in headwith current skipcount etc
  // save it in state
  sbwNode.redraw();
}

async function setScrollDrag(slideType, deltaX, globalX, scrollValue, scrollBarWidth){
  if (sabDraw === undefined){
    return;
  }

  const NUMBER_OF_SEGMENTS = 60;
  const SEGMENT_SIZE = sampleRate;
  let SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
  const SIZE_LOGS2 = 10;

  let size = SIZE;
  size/=2;
  let envelopeSizes = [];
  let i = 0;
  for (;i<SIZE_LOGS2;i++){
      const sz = Math.floor(size);
      envelopeSizes[i] = size;
      size/=2;
  }      
  SIZE = SIZE /6;

  let sabDrawingState = new Int32Array(sabDraw.draw_states[0]);
  let skipCounts = sabDrawingState[DRAW_STATE.SKIP_COUNTS];
  let level = sabDrawingState[DRAW_STATE.LEVEL];


  // 1. percentage of the scrub, 
  // 2. multiply to get the starting time DART
  // 3. 

  let initialPosition;
  console.log("globalX, deltaX : ", globalX, deltaX);
  if (level == -1){
    skipCounts = 1;
    initialPosition = differentInScreenPosition(globalX+deltaX, "first : ", level,skipCounts, SIZE);
  }else{
    initialPosition = differentInScreenPosition(globalX+deltaX, "first : ", level,skipCounts, envelopeSizes[level])
  }

  let endingPosition;
  if (level == -1){
    skipCounts = 1;
    endingPosition = differentInScreenPosition(globalX, "first : ", level,skipCounts, SIZE);
  }else{
    endingPosition = differentInScreenPosition(globalX, "first : ", level,skipCounts, envelopeSizes[level])
  }

  console.log("initialPosition : ", initialPosition, endingPosition, envelopeSizes[level]);

  if (envelopeSizes[level] - initialPosition>0 && endingPosition<envelopeSizes[level]){
    let diffPosition;
    if (deviceType == 'audio'){
      if (level == -1){
        diffPosition = Math.floor( ( endingPosition - initialPosition ) / 1 ) ;
      }else{
        diffPosition = Math.floor( ( endingPosition - initialPosition ) ) ;
      }

    }else{
      if (deviceType == 'serial'){
        if (level == -1){
          diffPosition = Math.floor( ( endingPosition - initialPosition ) /1 ) ;
        }else{
          diffPosition = Math.floor( ( endingPosition - initialPosition ) ) ;
        }
      }else{
        if (level == -1){
          diffPosition = Math.floor( ( endingPosition - initialPosition ) /2 ) ;
        }else{
          diffPosition = Math.floor( ( endingPosition - initialPosition ) /2 ) ;
        }
  
      }

    }

    let sabDrawingState = new Int32Array(sabDraw.draw_states[0]);
    sabDrawingState[DRAW_STATE.HORIZONTAL_DRAG] = diffPosition;
  
    console.log("diffPosition : ", diffPosition);
    sbwNode.redraw();
  }
}

function differentInScreenPosition(posX, part, level, skipCounts, envelopeSize){
  let sabDrawingState = new Int32Array(sabDraw.draw_states[0]);
  
  let divider = sabDrawingState[DRAW_STATE.DIVIDER] / 10;

  let head = Math.floor( sabDrawingState[DRAW_STATE.CURRENT_HEAD] ) ;
  const prevSegment = Math.floor( envelopeSize / divider );

  const samplesPerPixel = prevSegment / window.innerWidth;
  let division = 2;
  if (level == -1){
    division = 1;
  }
  const elementLength = Math.floor( (window.innerWidth - posX) * samplesPerPixel / division * skipCounts); 

  let curStart = head - Math.floor(elementLength);
  console.log("22 prev Segment ",prevSegment, "Samples per pixel : ", samplesPerPixel, "Skip Counts : ", skipCounts,"Element Length ", elementLength,"cur Start", curStart, "head : ", head, "Envelope Size : ", envelopeSize);

  return curStart; 
}

function screenPositionToElementPosition(posX, part, level, skipCounts, envelopeSize){
  let sabDrawingState = new Int32Array(sabDraw.draw_states[0]);
  
  let divider = sabDrawingState[DRAW_STATE.DIVIDER] / 10;
  // const subArrMaxSize = SIZE / divider;

  let head = Math.floor( sabDrawingState[DRAW_STATE.CURRENT_HEAD] ) ;
  const prevSegment = Math.floor( envelopeSize / divider );

  const samplesPerPixel = prevSegment / window.innerWidth;
  let division = 2;
  if (level == -1){
    division = 1;
  }
  const elementLength = Math.floor( (window.innerWidth - posX) * samplesPerPixel / division * skipCounts); 

  let curStart = head - Math.floor(elementLength);
  // console.log("prev Segment : ", prevSegment, "Samples per pixel : ", samplesPerPixel, "Skip Counts : ", skipCounts, "Element Length ", elementLength, "cur Start : ", curStart, "head : ", head, "Envelope Size : ", envelopeSize);
  if (curStart < 0){
    curStart = 0;
  }
  // console.log(part + " DistanceX : ", distanceX, skipCounts, divider);

  return curStart;

}


async function setZoomLevel(data) {
  if (sabDraw === undefined){
    return;
  }

  const row = JSON.parse(data);
  let sabDrawingState = new Int32Array(sabDraw.draw_states[0]);
  let skipCounts = sabDrawingState[DRAW_STATE.SKIP_COUNTS];
  let level = sabDrawingState[DRAW_STATE.LEVEL];

  console.log("isPlaying : ", isPlaying, " isPlayingWav: ", isPlayingWav, "isOpeningFie : " , isOpeningFile);
  if ( (isPlaying != 2 && isOpeningFile == 0) || (isPlayingWav && isPlaying == 2 ) ){
    const curLevel = calculateLevel(row["timeScaleBar"]);
    timeScaleBar = row["timeScaleBar"];
    realTimeLevel = curLevel;
    const transformedScale = Math.floor( row['levelScale'] );
    levelScale = Math.floor( row['levelScale'] );
    if (curLevel == -1){
      sabDrawingState[DRAW_STATE.SKIP_COUNTS] = 1;
      sabDrawingState[DRAW_STATE.LEVEL] = -1;
    }else{
      sabDrawingState[DRAW_STATE.SKIP_COUNTS] = arrCounts[curLevel];
      sabDrawingState[DRAW_STATE.LEVEL] = curLevel;
    }
  
    sabDrawingState[DRAW_STATE.DIVIDER] = arrTimescale[ transformedScale ]; // 0 - 40  
    sabDrawingState[DRAW_STATE.SURFACE_WIDTH] = window.innerWidth;
    skipCounts = sabDrawingState[DRAW_STATE.SKIP_COUNTS];
    level = sabDrawingState[DRAW_STATE.LEVEL];    

    sbwNode.redraw();
    return;
  }

  const NUMBER_OF_SEGMENTS = 60;
  const SEGMENT_SIZE = sampleRate;
  const SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
  const SIZE_LOGS2 = 10;


  let size = SIZE;
  size/=2;
  let envelopeSizes = [];
  let i = 0;
  for (;i<SIZE_LOGS2;i++){
      const sz = Math.floor(size);
      envelopeSizes[i] = size;
      size/=2;
  }      



  let initialPosition;
  if (level == -1){
    skipCounts = 1;
    initialPosition = screenPositionToElementPosition(row["posX"], "first : ", level,skipCounts, SIZE);
  }else{
    initialPosition = screenPositionToElementPosition(row["posX"], "first : ", level,skipCounts, envelopeSizes[level])
  }
  const initialLength = envelopeSizes[level];
  // console.log("INITIAL ", row["timeScaleBar"]);

  const curLevel = calculateLevel(row["timeScaleBar"]);
  timeScaleBar = row["timeScaleBar"];
  realTimeLevel = curLevel;

  const transformedScale = Math.floor( row['levelScale'] );
  levelScale = Math.floor( row['levelScale'] );  
  if (curLevel == -1){
    sabDrawingState[DRAW_STATE.SKIP_COUNTS] = 1;
    sabDrawingState[DRAW_STATE.LEVEL] = -1;
  }else{
    sabDrawingState[DRAW_STATE.SKIP_COUNTS] = arrCounts[curLevel];
    sabDrawingState[DRAW_STATE.LEVEL] = curLevel;
  }

  sabDrawingState[DRAW_STATE.DIVIDER] = arrTimescale[ transformedScale ]; // 0 - 40  
  sabDrawingState[DRAW_STATE.SURFACE_WIDTH] = window.innerWidth;
  {
    skipCounts = sabDrawingState[DRAW_STATE.SKIP_COUNTS];
    level = sabDrawingState[DRAW_STATE.LEVEL];
    
    let divider = sabDrawingState[DRAW_STATE.DIVIDER] / 10;
    // console.log("divider : ",divider);
    if (divider == 6){
      sabDrawingState[DRAW_STATE.CURRENT_START] = 0;
    }
    // const subArrMaxSize = Math.floor ( SIZE / divider );
  
    let endingPosition;
    if (level == -1){
      endingPosition = screenPositionToElementPosition(row["posX"], "second : ", level, skipCounts,SIZE);
    }else{
      endingPosition = screenPositionToElementPosition(row["posX"], "second : ", level, skipCounts,envelopeSizes[level]);
    }

    // const endingLength = envelopeSizes[level];
    
    let diffPosition;
    if (deviceType == 'audio'){
      if (level == -1){
        diffPosition = Math.floor( ( endingPosition - initialPosition ) / 1 ) ;
      }else{
        diffPosition = Math.floor( ( endingPosition - initialPosition ) ) ;
      }

    }else{
      if (deviceType == 'serial'){
        if (level == -1){
          diffPosition = Math.floor( ( endingPosition - initialPosition ) /1 ) ;
        }else{
          diffPosition = Math.floor( ( endingPosition - initialPosition ) ) ;
        }
      }else{
        if (isOpeningFile == 1){
          if (level == -1){
            diffPosition = Math.floor( ( endingPosition - initialPosition ) /1 ) ;
          }else{
            diffPosition = Math.floor( ( endingPosition - initialPosition ) /1 ) ;
          }  

        }else{
          if (level == -1){
            diffPosition = Math.floor( ( endingPosition - initialPosition ) /2 ) ;
          }else{
            diffPosition = Math.floor( ( endingPosition - initialPosition ) /2 ) ;
          }  
        }
  
      }

    }
    // if (row["direction"] == 1){ // UP
  
    // }else{ //DOWN
  
    // }
    
      
    let head = sabDrawingState[DRAW_STATE.CURRENT_HEAD];
    // const distanceX = (window.innerWidth - posX) * skipCounts;
    let curStart = head + diffPosition/2;
    sabDrawingState[DRAW_STATE.CURRENT_START] += Math.floor( diffPosition);
    // console.log("curStart : ",curStart, head, initialPosition, endingPosition,  diffPosition, sabDrawingState[DRAW_STATE.CURRENT_START]);  
  }

  try{
    if (isPlaying == 2)
      sbwNode.redraw();
    window.callbackHorizontalDiff( [ sabDrawingState[DRAW_STATE.CURRENT_START] ] );
  }catch(err){
    console.log("err");
    console.log(err);
  }


  return;
}


function utf8ToHex(str) {
  return Array.from(str).map(c => 
    c.charCodeAt(0) < 128 ? c.charCodeAt(0).toString(16).toUpperCase().padStart(2,'0') : 
    encodeURIComponent(c).replace(/\%/g,'').toUpperCase().padStart(2,'0')
  ).join(' ');
}

async function changeHidChannel(pChannel){
  // let deviceType = "serial";
  const channelParam = JSON.parse(pChannel);
  
  DISPLAY_CHANNEL_COUNT_FIX = channelParam.channelCount;

  console.log("CHANGE hid c:"+channelParam.channelCount+";", port);
  
  if (isInitHidChannel){
    isInitHidChannel = false;
    let currentLevel = calculateLevel(timeScaleBar);
    const strData = "3F 3E " + utf8ToHex("c:"+channelParam.channelCount+";\n").toString();
    // console.log("3F 3E "+data);
    // console.log(typeof utf8ToHex("c:"+channelParam.channelCount+";\n"));
    let data = parseHexArray(strData);  
    let reportData = new Uint8Array(data.buffer).slice(1);


    switch (channelParam.channelCount){
      case 2:
        // sampleRate = sampleRateFix;
      break;
      case 3:
        // sampleRate = sampleRateFix  / 2;
        await port.sendReport(reportId, reportData);
      
      break;      
      case 4:
        // sampleRate = sampleRateFix  / 2;
        await port.sendReport(reportId, reportData);    
      break;      
    }

    return;
  }
  

  // draw_states = [];
  sbwNode.clearBuffer(sabDraw);

  for (let c = 0; c < channelParam.channelCount; c++){
    let draw_state = new Int32Array(sabDraw.draw_states[c]);
    let minChannel = draw_state[DRAW_STATE.MIN_CHANNELS];
    if (channelParam.channelCount > minChannel){
      draw_state[DRAW_STATE.SAMPLE_RATE] = draw_state[DRAW_STATE.SAMPLING_RATE_1 + ( channelParam.channelCount- 1) ];
    }else{
      draw_state[DRAW_STATE.SAMPLE_RATE] = draw_state[DRAW_STATE.SAMPLING_RATE_1 + ( minChannel- 1) ];
    }

    
    draw_state[DRAW_STATE.CHANNEL_COUNTS] = channelParam.channelCount;  
  }
}

async function updateFirmware(deviceType){
  const data = asciiToUint8Array("update:;\n");
  if (deviceType == 'hid'){
    const strData = "3F 3E " + utf8ToHex(data).toString();
    let rData = parseHexArray(strData);  
    let reportData = new Uint8Array(rData.buffer).slice(1);
  
    console.log(reportId, data);    
    await port.sendReport(reportId, rData);
  }else{
    let sabSerialWriteDataState = new Int32Array(sabSerialWriteData.serialWriteState);
    let sabSerialWriteDataMessage = new Uint8Array(sabSerialWriteData.serialWriteMessage);
    sabSerialWriteDataState[SERIAL_WRITE_STATE.TAIL_IDX] = data.length;
    sabSerialWriteDataMessage.set(data,0);
  }
}



async function getHidDeviceInfo(){
  let data = parseHexArray("3F 3E 62 6F 61 72 64 3A 3B 5C 6E");  
  let reportData = new Uint8Array(data.buffer).slice(1);

  await port.sendReport(reportId, reportData);

}

async function getDeviceInfo(){
  const data = asciiToUint8Array("c:1;\n");
  let sabSerialWriteDataState = new Int32Array(sabSerialWriteData.serialWriteState);
  let sabSerialWriteDataMessage = new Uint8Array(sabSerialWriteData.serialWriteMessage);
  sabSerialWriteDataState[SERIAL_WRITE_STATE.TAIL_IDX] = data.length;
  sabSerialWriteDataMessage.set(data,0);  
}

async function changeSerialChannel(pChannel){
  let deviceType = "serial";
  const channelParam = JSON.parse(pChannel);
  
  DISPLAY_CHANNEL_COUNT_FIX = channelParam.channelCount;

  console.log("c:"+channelParam.channelCount+";", port);
  
  let currentLevel = calculateLevel(timeScaleBar);
  
  for (let c = 0; c < channelParam.channelCount; c++){
    let draw_state = new Int32Array(sabDraw.draw_states[0]);
    let minChannel = draw_state[DRAW_STATE.MIN_CHANNELS];
    draw_state[DRAW_STATE.SAMPLE_RATE] = draw_state[DRAW_STATE.SAMPLING_RATE_1 + (DISPLAY_CHANNEL_COUNT_FIX - minChannel) ];
    draw_state[DRAW_STATE.SURFACE_WIDTH] = window.innerWidth;

    sampleRate = draw_state[DRAW_STATE.SAMPLE_RATE];
    draw_state[DRAW_STATE.CHANNEL_COUNTS] = channelParam.channelCount;  
  }

  const data = asciiToUint8Array("c:"+channelParam.channelCount+";\n");
  let sabSerialWriteDataState = new Int32Array(sabSerialWriteData.serialWriteState);
  let sabSerialWriteDataMessage = new Uint8Array(sabSerialWriteData.serialWriteMessage);
  sabSerialWriteDataState[SERIAL_WRITE_STATE.TAIL_IDX] = data.length;
  sabSerialWriteDataMessage.set(data,0);
  
  sbwNode.clearBuffer(sabDraw);
}


async function changeChannel(pChannel){
  const channelParam = JSON.parse(pChannel);
  DISPLAY_CHANNEL_COUNT_FIX = channelParam.channelCount;
  try{
    for (let c = 0; c < CHANNEL_COUNT_FIX; c++){
      let draw_state = new Int32Array(sabDraw.draw_states[c]);
      draw_state[DRAW_STATE.CHANNEL_COUNTS] = DISPLAY_CHANNEL_COUNT_FIX;
      draw_state[DRAW_STATE.SURFACE_WIDTH] = window.innerWidth;
  
    }  
  }catch(err){
    console.log("err");
    console.log(err);
  }
}


async function startRecording(){
  const newDate = (new Date());
  const newFileName = "BYB_Recording_"+newDate.getFullYear()+"-"+newDate.getMonth()+"-"+newDate.getDate()+"_"+newDate.getHours()+"."+newDate.getMinutes()+"."+newDate.getSeconds();
  //2022-03-18_15.36.04
  const options = {
    excludeAcceptAllOption:true,
    suggestedName: newFileName,
    types: [
      {
        description: 'Spike-Recorder',
        accept: {
          'application/zip': ['.byb'],
        },
      },
    ],
  };
  const fileHandle = await window.showSaveFilePicker(options);
  return fileHandle;
}

async function fileRecordAudio(flagDisplay1, flagDisplay2, color1, color2){
  if (window.showSaveFilePicker === undefined){
    alert("Sorry your browser doesn't support recording to file");
    return;
  }
  
  let writeState = new Int32Array(sabWriteState);
  console.log("fileHandle", fileHandle,"color1 : ",color1,"color2 : ",color2,);
  if (fileHandle !== undefined){
    console.log("WRITE_STATE.IS_RECORDING",writeState[WRITE_STATE.IS_RECORDING]);
    writeState[WRITE_STATE.IS_RECORDING] = 0;
    console.log("WRITE_STATE.IS_RECORDING",writeState[WRITE_STATE.IS_RECORDING]);
    window.callbackSetRecording([0]);
    window.callAlert(["File saved", "Congratulations, your file has been saved!"]);  
    setTimeout(()=>{
      fileHandle = undefined;
    },1000)
    isRecordingParam = 0;
    return;
  }
  writeState[WRITE_STATE.IS_RECORDING] = 1;
  if (color1 === undefined){
    color1 = 1;
  }
  if (color2 === undefined){
    color2 = 2;
  }

  let recordingChannels = 1;
  if (deviceType == 'audio' && flagDisplay2==1){
    recordingChannels = 2;
  }


  fileHandle = await startRecording();
  console.log("fileHandle loaded ? ", fileHandle);
  if (fileHandle == undefined){
    window.callbackSetRecording([0]);
    callbackSetRecording = 0;    
  }else{
    try{
      window.callbackSetRecording([10]);
      isRecordingParam = 10;  
    }catch(err){
      console.log("ERR ",err);
    }
  }
  console.log("FILEH WORKER POST MESSAGE ", recordingChannels);
  if (fileWorker !== undefined){
    fileWorker.postMessage({
      "command" : "connect",
      "deviceType" : deviceType,
      "fileHandle" : fileHandle,
      // "channelCount" : DISPLAY_CHANNEL_COUNT_FIX,
      "channelCount" : AUDIO_CHANNEL_MAX,//recordingChannels,
      "sampleRate" : sampleRate,
      "sabWriteState" : sabWriteState,
      "color1" : color1,
      "color2" : color2,
      "os" :os,
      "versionNumber" :versionNumber,
      "userAgent" :deviceDetail,
      "deviceDetail" :deviceDetail,
      
    });
  
  }
  return;

}

function destroyWorkers(){
  try{ sequentialSignalWorker.terminate(); sequentialSignalWorker = undefined; }catch(err){console.log(err);}
  try{ sequentialFileWorker.terminate(); sequentialFileWorker = undefined; }catch(err){console.log(err);}

  try{ sbwNode.closeProcessor(); }catch(err){console.log("CLOSE PROCESSOR : ",err);}
  try{ sbwNode.terminateAll(); }catch(err){console.log("TERMINATE ALL : ",err);}
  try{ delete sbwNode }catch(err){console.log(err);}
}

//https://webrtc.github.io/samples/src/content/devices/input-output/
async function recordAudio(text){
  window.callbackIsOpeningWavFile([0]);

  try{
    try{
      if (port!==undefined){
        port.oninputreport = null;
      }
    }catch(err){
      console.log("record Serial initial ",err);
    }

    let currentLevel = calculateLevel(10000);
    console.log("currentLevel : ", currentLevel);
    DISPLAY_CHANNEL_COUNT_FIX = 2;
    CHANNEL_COUNT_FIX = 2;

    if (window.innerWidth < window.innerHeight){
      incSkip = 1;
    }

    if (sbwNode !== undefined && deviceType == "serial"){
      try{
        // if (isPrevOpeningFile == 0)
          sbwNode.closeProcessor();
      }catch(err){
        console.log(err);
      }
    }else
    if (sbwNode !== undefined && deviceType == "audio"){
      if (isPrevOpeningFile == 1){
        isPrevOpeningFile = 0;
      }else{
        return;

      }
    }

    // alert("123");

    if (signalWorker === undefined){
      signalWorker = new Worker('build/web//SignalThread.js');
    }else{
      try{ signalWorker.terminate(); signalWorker = undefined; }catch(err){console.log(err);}
      signalWorker = new Worker('build/web/SignalThread.js');
    }

    if (fileWorker === undefined){
      fileWorker = new Worker('build/web//FileThread.js')
    }else{
      try{ 
        fileWorker.terminate(); 
        fileWorker = undefined; 
        fileWorker = new Worker('build/web/FileThread.js');
      }catch(err){console.log(err);}
    }
    
    try{ sequentialSignalWorker.terminate(); sequentialSignalWorker = undefined; }catch(err){console.log(err);}
    try{ sequentialFileWorker.terminate(); sequentialFileWorker = undefined; }catch(err){console.log(err);}

    try{ sbwNode.closeProcessor(); }catch(err){console.log("CLOSE PROCESSOR : ",err);}
    try{ sbwNode.terminateAll(); }catch(err){console.log("TERMINATE ALL : ",err);}
    try{ delete sbwNode }catch(err){console.log(err);}

    try{
      delete ac;
      ac = new AudioContext();
    }catch(err){
      console.log(err);
    }



    deviceType = "audio";
    
    console.log("2");
    const len = arrTimescale.length;
    const divider = arrTimescale[len-1];
    isPlaying = 1;
    window.callbackAudioInit([0,1]);

    const mediaStream = await navigator.mediaDevices.getUserMedia({
      audio: true,
    });
    source = new MediaStreamAudioSourceNode(ac, { mediaStream });
  
    const {default: SharedBufferWorkletNode} = await import('./SharedWorkletNode.js');
    await ac.audioWorklet.addModule('build/web/shared-buffer-worklet-processor.js');
    sampleRate = ac.sampleRate;
    if (window.SharedArrayBuffer){
      incSkip = 0;
      currentLevel = calculateLevel(10000);
      window.changeSampleRate( [sampleRate,currentLevel, arrCounts[currentLevel] ]);
      console.log("3 Sample Rate : "+sampleRate );
      initializeSabDraw();      

      let draw_states = initializeDrawState(CHANNEL_COUNT_FIX, currentLevel,divider, sampleRate);
      let flagChannelDisplays = new Uint32Array(sabDraw.channelDisplays);
      flagChannelDisplays[0] = 1;

      sabEvents = (new Uint8Array(sabDraw.events));
      sabEventPositionResult = (new Float32Array(sabDraw.eventPositionResult));

      realTimeLevel = currentLevel;
      console.log("5");

      function repaint(timestamp){
          try{
            let ctr = new Uint8Array(sabDraw.eventsCounter)[0];
            let eventMarkers = [
              sabEvents.subarray(0,ctr),
              sabEventPositionResult.subarray(0,ctr),
            ];

            let content = [];
            for (let c = 0; c < DISPLAY_CHANNEL_COUNT_FIX; c++){
              const temp = new Int16Array(sabDraw.levels[c]);
              const arr = temp.subarray(draw_states[c][DRAW_STATE.HEAD_IDX],draw_states[c][DRAW_STATE.TAIL_IDX]);
              content[c]=arr;
            }
            content.push(
              eventMarkers
            );
            window.jsToDart(content);
            // console.log(content);
            if (deviceType == 'audio'){
              window.requestAnimationFrame(repaint);
            }
              
          }catch(exc){
            // window.callbackErrorLog( ["error_repaint", "Repaint Audio Error"] );
            console.log("exc");
            console.log(exc);
          }
      }
      
      window.requestAnimationFrame(repaint);    
    }  

    console.log("10");
    signalWorker.postMessage({
      command:"setUp",
      type: 'audio',
      drawSurfaceWidth : window.innerWidth,
      sabDraw:sabDraw,
      channelCount:CHANNEL_COUNT_FIX,
      arrCounts : arrCounts,
      sampleRate : sampleRate
    }); 
    
    sbwNode = new SharedBufferWorkletNode(ac,{
      worker:{
        channelCount : 2,
        signalWorker:signalWorker,
        fileWorker:fileWorker,
        sabDraw : sabDraw,
        sampleRate: sampleRate,
        arrCounts : arrCounts,
      }  
    }); //ADD OPTIONS HERE : level, channelCount
    
    source.connect(sbwNode);
    await ac.suspend();



    sbwNode.onInitialized = async () => {
      await ac.resume();
      console.log("sbwnode initialized");
    };
  
    sbwNode.onError = (errorData) => {
      logger.post('[ERROR] ' + errorData.detail);
    };
    isPrevOpeningFile = 0;

  }catch(err){
    console.log("err");
    console.log(err);
  }
};


async function fileRecordSerial(flagDisplay1, flagDisplay2, flagDisplay3, flagDisplay4, flagDisplay5, flagDisplay6, color1, color2, color3, color4, color5, color6){
      
  if (window.showSaveFilePicker === undefined){
    alert("Sorry your browser doesn't support recording to file");
    return;
  }
  
  let writeState = new Int32Array(sabWriteState);
  console.log("fileHandle", fileHandle);
  if (fileHandle !== undefined){
    console.log("WRITE_STATE.IS_RECORDING",writeState[WRITE_STATE.IS_RECORDING]);
    writeState[WRITE_STATE.IS_RECORDING] = 0;
    console.log("WRITE_STATE.IS_RECORDING",writeState[WRITE_STATE.IS_RECORDING]);

    // fileHandle = undefined;
    window.callbackSetRecording([0]);
    window.callAlert(["File saved", "Congratulations, your file has been saved!"]);  

    setTimeout(()=>{
      fileHandle = undefined;
    },1000)
    isRecordingParam = 0;    

    return;
  }
  writeState[WRITE_STATE.IS_RECORDING] = 1;


  fileHandle = await startRecording();
  if (fileHandle == undefined){
    window.callbackSetRecording([0]);
    isRecordingParam = 0;
  }else{
    if (deviceType == 'hid'){
      window.callbackSetRecording([12]);
      isRecordingParam = 12;
    }else
    if (deviceType == 'serial'){
      window.callbackSetRecording([11]);
      isRecordingParam = 11;
    }else{
      window.callbackSetRecording([10]);
      isRecordingParam = 10;
    }
  }
  console.log("FILEHANDLE , sample rate", userAgent, sampleRate, fileHandle);
  options = {
    "command" : "connect",
    "deviceType" : deviceType,
    "fileHandle" : fileHandle,
    "channelCount" : DISPLAY_CHANNEL_COUNT_FIX,
    "sampleRate" : sampleRate,
    "sabWriteState" : sabWriteState,
    "sabDraw" : sabDraw,
    "productId" : sbwNode.deviceId,
    "flag1" : flagDisplay1,
    "flag2" : flagDisplay2,
    "flag3" : flagDisplay3,
    "flag4" : flagDisplay4,
    "flag5" : flagDisplay5,
    "flag6" : flagDisplay6,

    "color1" : color1,
    "color2" : color2,
    "color3" : color3,
    "color4" : color4,
    "color5" : color5,
    "color6" : color6,
    'deviceType' : deviceType,

    "os" :os,
    "versionNumber" : versionNumber,
    "userAgent" :deviceDetail,
    "deviceDetail" :deviceDetail,
  };
  sequentialFileWorker.postMessage(options);
  console.log("options : ", options, sequentialFileWorker);
  return;

}

async function recordSerial(text){
  let deviceInfo;
  window.callbackIsOpeningWavFile([0]);

  try{
    try{
      if (port!==undefined){
        port.oninputreport = null;
        port.close();
      }
    }catch(err){
      console.log("record Serial initial ",err);
    } 

    try{
      port = await navigator.serial.requestPort();
      port.addEventListener('connect', (event) => {
        console.log(event.target, " connected ");
      });
      port.addEventListener('disconnect', (event) => {
        // alert("disconnect")
        console.log(event.target, " disconnected ");
        window.resetToAudio();
        recordAudio();
      });

    }catch(err){
      console.log("No Port Selected : ",err);
      window.resetToAudio();
      recordAudio(text);
      return;
    }
    if (port == undefined) {
      window.resetToAudio();
      return;
    }else{
      const productId = port.getInfo().usbProductId;
      const vendorId = port.getInfo().usbVendorId;
      const deviceId = productId + "_" + vendorId;
      deviceInfo = DEVICE_PRODUCT[deviceId];
      deviceInfo.productId = deviceId;
    }
    if (sbwNode !== undefined && deviceType == "audio"){
    }else
    if (sbwNode !== undefined && deviceType == "serial"){
      return;
    }

    try{ signalWorker.terminate(); signalWorker = undefined; }catch(err){console.log(err);}
    try{ fileWorker.terminate(); fileWorker = undefined; }catch(err){console.log(err);}
    
    try{ sequentialSignalWorker.terminate(); sequentialSignalWorker = undefined; }catch(err){console.log(err);}
    try{ sequentialFileWorker.terminate(); sequentialFileWorker = undefined; }catch(err){console.log(err);}

    sequentialSignalWorker = new Worker('build/web/SignalThread.js')
    sequentialFileWorker = new Worker('build/web/FileThread.js')
    
    try{ sbwNode.closeProcessor(); }catch(err){console.log(err);}
    try{ sbwNode.terminateAll(); }catch(err){console.log(err);}
    try{ delete sbwNode }catch(err){console.log(err);}

    deviceType = 'serial';

    CHANNEL_COUNT_FIX = 1;
    window.callbackSerialInit([1,1]);
    
  
    sampleRate = deviceInfo.maxSamplingRate;
    
    timeScaleBar = 10000;
    incSkip = 0;
    let currentLevel = calculateLevel(timeScaleBar);
    // let currentLevel = -1;
    window.changeSampleRate( [sampleRate,currentLevel, arrCounts[currentLevel] ]);

    console.log("2");
    const len = arrTimescale.length;
    const divider = arrTimescale[len-1];

    console.log("12");
    const {default: SequentialSharedBufferWorkletNode} = await import('./SerialSharedWorkletNode.js');

    if (window.SharedArrayBuffer){
      console.log("3");
      sabSerialWriteData = {
        serialWriteState : new SharedArrayBuffer(SERIAL_WRITE_CONFIG.bytesPerState * 10),
        serialWriteMessage : new SharedArrayBuffer(SERIAL_WRITE_CONFIG.bytesPerSample * 1024)
      };
      initializeSabDraw();

      console.log("4");

      let draw_states = initializeDrawState(SERIAL_CHANNEL_COUNT_FIX, currentLevel, divider, sampleRate);
      let flagChannelDisplays = new Uint32Array(sabDraw.channelDisplays);
      flagChannelDisplays[0] = 1;
      // for (let c = 0; c < SERIAL_CHANNEL_COUNT_FIX; c++){
      //   let draw_state = new Int32Array(sabDraw.draw_states[c]);
      //   draw_state[DRAW_STATE.LEVEL] = currentLevel;
      //   draw_state[DRAW_STATE.SKIP_COUNTS] = arrCounts[currentLevel];
      //   draw_state[DRAW_STATE.DIVIDER] = divider;
      //   draw_state[DRAW_STATE.SAMPLE_RATE] = sampleRate;
      //   draw_state[DRAW_STATE.CHANNEL_COUNTS] = 1;
      //   draw_state[DRAW_STATE.SURFACE_WIDTH] = window.innerWidth;
      //   draw_states.push(draw_state);
  
      // }
      realTimeLevel = currentLevel;
      console.log("5");
      sabEvents = (new Uint8Array(sabDraw.events));
      sabEventPositionResult = (new Float32Array(sabDraw.eventPositionResult));

      function repaint(timestamp){
          try{
            // console.log("TIME ", (new Date()).getTime() );
            let ctr = new Uint8Array(sabDraw.eventsCounter)[0];
            let eventMarkers = [
              sabEvents.subarray(0,ctr),
              sabEventPositionResult.subarray(0,ctr),
            ];

            if ( draw_states[0][DRAW_STATE.SAMPLE_RATE] != sampleRateFix ){
              console.log("CHANGING SAMPLE RATE!!!")
              sampleRateFix = draw_states[0][DRAW_STATE.SAMPLE_RATE];
              sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE]
              const curLevel = calculateLevel(timeScaleBar);    
              const sabDrawingState = draw_states[0];
              if (curLevel == -1){
                sabDrawingState[DRAW_STATE.SKIP_COUNTS] = 1;
                sabDrawingState[DRAW_STATE.LEVEL] = -1;
              }else{
                sabDrawingState[DRAW_STATE.SKIP_COUNTS] = arrCounts[curLevel];
                sabDrawingState[DRAW_STATE.LEVEL] = curLevel;
              }
              
        
            }

            if (extraChannel !== draw_states[0][DRAW_STATE.EXTRA_CHANNELS] && isRecordingParam == 0){
              extraChannel = draw_states[0][DRAW_STATE.EXTRA_CHANNELS];
              var data = {
                "channelCount" : draw_states[0][DRAW_STATE.CHANNEL_COUNTS],
              };
              console.log("channelCount LL :",data);
              changeSerialChannel( JSON.stringify(data) );
              window.callbackGetDeviceInfo([ extraChannel, draw_states[0][DRAW_STATE.MIN_CHANNELS], draw_states[0][DRAW_STATE.MAX_CHANNELS] ])
            }

            let content = [];

            for (let c = 0; c < DISPLAY_CHANNEL_COUNT_FIX; c++){
              const temp = new Int16Array(sabDraw.levels[c]);
              const arr = temp.subarray(0,draw_states[c][DRAW_STATE.TAIL_IDX]);
              content[c]=arr;
            }
            content.push(
              eventMarkers
            );
            window.jsToDart(content);  
            // console.log("content : ",content[0].length);
            if (deviceType == 'serial')
              window.requestAnimationFrame(repaint);
              
          }catch(exc){
            console.log("exc");
            console.log(exc);
            if (deviceType == 'serial'){
              window.callbackErrorLog( ["error_repaint", "Repaint Serial Error"] );
              window.requestAnimationFrame(repaint);
            }
          }
      }
      
      window.requestAnimationFrame(repaint);    
    }  
    console.log("10");
    sequentialSignalWorker.postMessage({
      command:"setUp",
      type: 'serial',
      drawSurfaceWidth : window.innerWidth,
      sabDraw:sabDraw,
      channelCount:1,
      arrCounts : arrCounts,
      sampleRate : sampleRate,
    });
    console.log("11");    

    
    console.log("13");
    sbwNode = new SequentialSharedBufferWorkletNode(ac,
      {
        worker:{
          channelCount : 1,
          signalWorker:sequentialSignalWorker,
          fileWorker:sequentialFileWorker,
          sabDraw : sabDraw,
          sabSerialWriteData : sabSerialWriteData,
          sampleRate : sampleRate,
          arrCounts : arrCounts,
          deviceType : 'serial'

        }
      }
    ); //ADD OPTIONS HERE : level, channelCount
    




    sbwNode.onInitialized = async () => {
      console.log("sbwnode initialized");
    };
  
    sbwNode.onError = (errorData) => {
      logger.post('[ERROR] ' + errorData.detail);
    };
  
    // need to determine the device type
    setTimeout(()=>{
      getDeviceInfo();
      let timerChannels = setInterval(()=>{
        //send to dart, EXTRA_CHANNELS, max, min channels, //sample rates
        let sabDrawState = new Int32Array(sabDraw.draw_states[0]);
        // 
        console.log("CALLBACK GET DEVICE INFO ", sabDrawState[DRAW_STATE.EXTRA_CHANNELS], sabDrawState[DRAW_STATE.MIN_CHANNELS], sabDrawState[DRAW_STATE.MAX_CHANNELS]);
        // This will help when the expansion board is preattached, it will give many channels first  
        if (sabDrawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
          DISPLAY_CHANNEL_COUNT_FIX = sabDrawState[DRAW_STATE.MIN_CHANNELS];
        }else{
          DISPLAY_CHANNEL_COUNT_FIX = sabDrawState[DRAW_STATE.MAX_CHANNELS];
        }
        sabDrawState[DRAW_STATE.CHANNEL_COUNTS] = DISPLAY_CHANNEL_COUNT_FIX;
        if ( sabDrawState[DRAW_STATE.EXTRA_CHANNELS] == 0 && sabDrawState[DRAW_STATE.MIN_CHANNELS] == 0 && sabDrawState[DRAW_STATE.MAX_CHANNELS] == 0){
        }else{
          window.callbackGetDeviceInfo([ sabDrawState[DRAW_STATE.EXTRA_CHANNELS], sabDrawState[DRAW_STATE.MIN_CHANNELS], sabDrawState[DRAW_STATE.MAX_CHANNELS] ])
          clearInterval(timerChannels);

        }
      },1500);
  
    },1);

  }catch(err){
    console.log("err");
    console.log(err);
  }
};

const parseHexArray = text => {
  // Remove non-hex characters.
  text = text.replace(/[^0-9a-fA-F]/g, '');
  if (text.length % 2)
    return null;

  // Parse each character pair as a hex byte value.
  let u8 = new Uint8Array(text.length / 2);
  for (let i = 0; i < text.length; i += 2)
    u8[i / 2] = parseInt(text.substr(i, 2), 16);

  return new DataView(u8.buffer);
};

async function onInputReportHID(event){
  if (sbwNode !== undefined){
    if (isPlaying <= 1){
      sbwNode.processHidData(event);
    }
  }
}

async function recordHid(text){
  let deviceInfo;
  window.callbackIsOpeningWavFile([0]);
  
  try{
    try{
      if (port!==undefined){
        port.oninputreport = null;
      }
    }catch(err){
      console.log("record Serial initial ",err);
    }

    try{
      port = (await navigator.hid.requestDevice({filters: [{vendorId:0x2E73}]}))[0];    

    }catch(err){
      console.log("No Port Selected : ",err);
      window.resetToAudio();
      recordAudio(text);
      return;
    }

    console.log(port);
    if (port == undefined) {
      window.resetToAudio();
      return;
    } else {
      if (port.opened){
        port.close();
      }
    }

    try{
      navigator.hid.ondisconnect = (e) => { 
        window.resetToAudio();
        recordAudio(text);  
      };
    }catch(err){
      console.log("Err", err);
    }


    const strDevice = port.productId + "_" + port.vendorId;
    deviceInfo = DEVICE_PRODUCT[strDevice];
    deviceInfo.productId = strDevice;
   
    if (sbwNode !== undefined && deviceType == "audio"){
      // sbwNode.closeAudioProcessor();
      // return;
    }else
    if (sbwNode !== undefined && deviceType == "hid"){
      return;
    }

    try{ signalWorker.terminate(); signalWorker = undefined; }catch(err){console.log(err);}
    try{ fileWorker.terminate(); fileWorker = undefined; }catch(err){console.log(err);}
    
    if (sequentialSignalWorker === undefined){
      // sequentialSignalWorker = new Worker('build/web/SignalThread.js')
    }else {
      try{ sequentialSignalWorker.terminate(); sequentialSignalWorker = undefined; }catch(err){console.log(err);}
    }


    try{ sequentialFileWorker.terminate(); sequentialFileWorker = undefined; }catch(err){console.log(err);}

    sequentialSignalWorker = new Worker('build/web/SignalThread.js')
    sequentialFileWorker = new Worker('build/web/FileThread.js');

    
    try{ sbwNode.closeProcessor(); }catch(err){console.log(err);}
    try{ sbwNode.terminateAll(); }catch(err){console.log(err);}
    try{ delete sbwNode }catch(err){console.log(err);}

    deviceType = 'hid';

    CHANNEL_COUNT_FIX = 1;

    window.callbackSerialInit([2,1]);

    await port.open().catch(console.error);
    let data = parseHexArray("3F 3E 73 74 61 72 74 3A 3B 0A 00 00 B4 81 00 01 24 00 00 00 03 00 01 00 C0 2B 58 00 DC C8 74 00 00 00 00 00 04 00 01 00 04 00 00 00 0D 03 4C 00 34 2C 58 00 00 00 00 00 00 00 00 00 00 00 AC");
  
    reportId = data.getUint8(0);
    let reportData = new Uint8Array(data.buffer).slice(1);

    console.log(reportId, reportData);    
    await port.sendReport(reportId, reportData);
    
    sampleRate = deviceInfo.maxSamplingRate;
    
    timeScaleBar = 10000;
    let currentLevel = calculateLevel(timeScaleBar);
    // let currentLevel = -1;

    const len = arrTimescale.length;
    const divider = arrTimescale[len-1];

    const {default: SequentialSharedBufferWorkletNode} = await import('./SerialSharedWorkletNode.js');

    if (window.SharedArrayBuffer){
      console.log("3");
      sabSerialWriteData = {
        serialWriteState : new SharedArrayBuffer(SERIAL_WRITE_CONFIG.bytesPerState * 10),
        serialWriteMessage : new SharedArrayBuffer(SERIAL_WRITE_CONFIG.bytesPerSample * 1024)
      };

      initializeSabDraw();

      // if (sabDraw){
      //   // changing from serial to hid gives draw_states to 12
      //   delete sabDraw;
      // }
      // sabDraw = {
      //   channelCount : CHANNEL_COUNT_FIX,
      //   playback_states : [
      //     new SharedArrayBuffer(CONFIG.bytesPerPosition * 20)            
      //   ],
      //   channelDisplays :
      //     new SharedArrayBuffer(CONFIG.bytesPerPosition * 10),
        

      //   draw_states : [
      //     new SharedArrayBuffer(CONFIG.bytesPerSample * 70),
      //     new SharedArrayBuffer(CONFIG.bytesPerSample * 70),
      //     new SharedArrayBuffer(CONFIG.bytesPerSample * 70),
      //     new SharedArrayBuffer(CONFIG.bytesPerSample * 70),
      //     new SharedArrayBuffer(CONFIG.bytesPerSample * 70),
      //     new SharedArrayBuffer(CONFIG.bytesPerSample * 70),
      //   ],
      //   levels : [
      //     new SharedArrayBuffer( 200000 * 20 ),
      //     new SharedArrayBuffer( 200000 * 20 ),
      //     new SharedArrayBuffer( 200000 * 20 ),
      //     new SharedArrayBuffer( 200000 * 20 ),
      //     new SharedArrayBuffer( 200000 * 20 ),
      //     new SharedArrayBuffer( 200000 * 20 ),
      //   ],

      //   events : new SharedArrayBuffer(MAX_MARKERS * Uint8Array.BYTES_PER_ELEMENT),        
      //   eventPosition : new SharedArrayBuffer( MAX_MARKERS * Uint32Array.BYTES_PER_ELEMENT ),
      //   eventPositionResult : new SharedArrayBuffer( MAX_MARKERS * Float32Array.BYTES_PER_ELEMENT ),
      //   eventsCounter : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT ),

      // };

      console.log("4");
      let flagChannelDisplays = new Uint32Array(sabDraw.channelDisplays);
      flagChannelDisplays[0] = 1;

      let draw_states = initializeDrawState(SERIAL_CHANNEL_COUNT_FIX, currentLeve, divider, sampleRate);
      // for (let c = 0; c < SERIAL_CHANNEL_COUNT_FIX; c++){
      //   let draw_state = new Int32Array(sabDraw.draw_states[c]);
      //   draw_state[DRAW_STATE.LEVEL] = currentLevel;
      //   draw_state[DRAW_STATE.SKIP_COUNTS] = arrCounts[currentLevel];
      //   draw_state[DRAW_STATE.DIVIDER] = divider;
      //   draw_state[DRAW_STATE.SAMPLE_RATE] = sampleRate;
      //   draw_state[DRAW_STATE.CHANNEL_COUNTS] = 1;
      //   draw_state[DRAW_STATE.SURFACE_WIDTH] = window.innerWidth;
        
      //   draw_states.push(draw_state);
  
      // }
      realTimeLevel = currentLevel;
      console.log("5");
      sabEvents = (new Uint8Array(sabDraw.events));
      sabEventPositionResult = (new Float32Array(sabDraw.eventPositionResult));

      function repaint(timestamp){
          try{
            let ctr = new Uint8Array(sabDraw.eventsCounter)[0];
            let eventMarkers = [
              sabEvents.subarray(0,ctr),
              sabEventPositionResult.subarray(0,ctr),
            ];
          
            let content = [];
            if (extraChannel !== draw_states[0][DRAW_STATE.EXTRA_CHANNELS]){
              extraChannel = draw_states[0][DRAW_STATE.EXTRA_CHANNELS];
              var data = {
                "channelCount" : draw_states[0][DRAW_STATE.CHANNEL_COUNTS],
              };
              changeHidChannel( JSON.stringify(data) );
              window.callbackGetDeviceInfo([ extraChannel, draw_states[0][DRAW_STATE.MIN_CHANNELS], draw_states[0][DRAW_STATE.MAX_CHANNELS] ])
            }

            if ( draw_states[0][DRAW_STATE.SAMPLE_RATE] != sampleRateFix ){
              sampleRateFix = draw_states[0][DRAW_STATE.SAMPLE_RATE];
              sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE]
              console.log("CHANGING SAMPLE RATE!!! ",sampleRate);
              const curLevel = calculateLevel(timeScaleBar);    
              const sabDrawingState = draw_states[0];
              if (curLevel == -1){
                sabDrawingState[DRAW_STATE.SKIP_COUNTS] = 1;
                sabDrawingState[DRAW_STATE.LEVEL] = -1;
              }else{
                sabDrawingState[DRAW_STATE.SKIP_COUNTS] = arrCounts[curLevel];
                sabDrawingState[DRAW_STATE.LEVEL] = curLevel;
              }
              
        
            }

            for (let c = 0; c < DISPLAY_CHANNEL_COUNT_FIX; c++){
              const temp = new Int16Array(sabDraw.levels[c]);
              const arr = temp.subarray(0,draw_states[c][DRAW_STATE.TAIL_IDX]);
              // console.log("DRAW BUFFER ", c, draw_states[c][DRAW_STATE.TAIL_IDX]);
              content[c]=arr;
            }
            content.push(
              eventMarkers
            );

            window.jsToDart(content);  
            if (deviceType == "hid")
              window.requestAnimationFrame(repaint);
              
          }catch(exc){
            console.log("exc !!!");
            console.log(exc);
            if (deviceType == 'hid'){
              window.callbackErrorLog( ["error_repaint", "Repaint Hid Error"] );
              window.requestAnimationFrame(repaint);
            }
          }
      }
      
      window.requestAnimationFrame(repaint);    
    }  
    console.log("10");
    
    sequentialSignalWorker.postMessage({
      command:"setUp",
      type: 'serial',
      drawSurfaceWidth : window.innerWidth,
      sabDraw:sabDraw,
      channelCount:1,
      arrCounts : arrCounts,
      sampleRate : sampleRate,
    });
    console.log("11");    

    
    console.log("13");
    sbwNode = new SequentialSharedBufferWorkletNode(ac,
      {
        worker:{
          channelCount : 1,
          signalWorker:sequentialSignalWorker,
          fileWorker:sequentialFileWorker,
          sabDraw : sabDraw,
          sabSerialWriteData : sabSerialWriteData,
          deviceType : 'hid',
          reportId : reportId,
          strDevice : strDevice,
          sampleRate : sampleRate,
          arrCounts : arrCounts,


        }
      }
    ); //ADD OPTIONS HERE : level, channelCount
    




    sbwNode.onInitialized = async () => {
      console.log("sbwnode initialized");
    };
  
    sbwNode.onError = (errorData) => {
      logger.post('[ERROR] ' + errorData.detail);
    };
    port.oninputreport = onInputReportHID;
  
    setTimeout(()=>{
      // getHidDeviceInfo();
      let timerChannels = setInterval(()=>{
        //send to dart, EXTRA_CHANNELS, max, min channels, //sample rates
        let sabDrawState = new Int32Array(sabDraw.draw_states[0]);
        // 
        console.log("CALLBACK GET DEVICE INFO ", sabDrawState[DRAW_STATE.EXTRA_CHANNELS], sabDrawState[DRAW_STATE.MIN_CHANNELS], sabDrawState[DRAW_STATE.MAX_CHANNELS]);
        // This will help when the expansion board is preattached, it will give many channels first  
        if (sabDrawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
          DISPLAY_CHANNEL_COUNT_FIX = sabDrawState[DRAW_STATE.MIN_CHANNELS];
        }else{
          DISPLAY_CHANNEL_COUNT_FIX = sabDrawState[DRAW_STATE.MAX_CHANNELS];
        }
        sabDrawState[DRAW_STATE.CHANNEL_COUNTS] = DISPLAY_CHANNEL_COUNT_FIX;
        if ( sabDrawState[DRAW_STATE.EXTRA_CHANNELS] == 0 && sabDrawState[DRAW_STATE.MIN_CHANNELS] == 0 && sabDrawState[DRAW_STATE.MAX_CHANNELS] == 0){
        }else{
          window.callbackGetDeviceInfo([ sabDrawState[DRAW_STATE.EXTRA_CHANNELS], sabDrawState[DRAW_STATE.MIN_CHANNELS], sabDrawState[DRAW_STATE.MAX_CHANNELS] ])
          clearInterval(timerChannels);

        }
      },1500);
  
    },1000);

  }catch(err){
    console.log("err");
    console.log(err);
  }

};



window.onbeforeunload = function() {
  // wasmWorker.terminate();
  fileWorker.terminate();
  signalWorker.terminate();
  channel.port1.close();
  channel.port2.close();

  channelSetting.port1.close();
  channelSetting.port2.close();

  channelWasmWorkerResult.port1.close();
  channelWasmWorkerResult.port2.close();

  return undefined;
}      


function asciiToUint8Array(str){
  console.log("ASCII",str);
  var chars = [];
  for (var i = 0; i < str.length; ++i){
    chars.push(str.charCodeAt(i));/*from  w  ww. j  a  v  a  2s.c o  m*/
  }
  return new Uint8Array(chars);
}

function closePlaybackScreen(playbackDeviceType){
  isPrevOpeningFile = 1;
  if (playbackDeviceType == "audio"){

  }else
  if (playbackDeviceType == "serial"){


  }else{

  }
  try{
    sbwNode.clearBuffer(sabDraw);
  }catch(err){
    console.log("CLEAR BUFFER : ",err);
  }

  
}



const startWavIdx = 10;
let openFileAudioOptions;
var audioReplayCtx;
let audioBuf;
let audioNode;
let audioSource;
let isOpeningFile = 0
let isPrevOpeningFile = 0;
let currentPlayTime = 0;

let openFileMarkers;
let openFileChannels;

window.stopData = async function(){
  audioReplayCtx.suspend();
}


window.resetPlayback = async function(parameter){
  sumInitialPlaybackTime = 0;
  isPlayingWav = true;      

  currentDataPosition = 0;
  audioNode.disconnect();
  try{
    audioSource.stop(0);
  }catch(Err){
    console.log(Err);
  }
  delete audioSource;
  window.changeResetPlayback([false]);
  window.changePlaybackButton([isOpeningFile,1]);

  processWav(0, openedWavSampleLength, false, true, timeScaleBar);
}


window.playData = async function(isPlaying){
  console.log("PLAY DATA", deviceType, isPlaying, timeScaleBar);
  let playbackState = new Uint32Array(sabDraw.playback_states[0]);
  playbackState[PLAYBACK_STATE.DRAG_VALUE] = 0;  
  currentPlayTime = 0;
  let sampleRate = audioReplayCtx.sampleRate;
  const channels = openFileChannels;
    
  if (deviceType == 'audio'){
    if (isPlaying == 1){
      if (isPlayingWav) return;
      isPlayingWav = true;      
      // CHANGE BUTTONS
      window.changeResetPlayback([true]);
      window.changeTimeBarStatus([false]);
      console.log("CLEAR AUDIO");
      sbwNode.clearBuffer(sabDraw);

      // setTimeout(()=>{
      processWav(currentDataPosition, openedWavSampleLength, false, false, timeScaleBar);
      window.drawElapsedTime([audioReplayCtx.currentTime + sumInitialPlaybackTime]);
      window.changePlaybackButton([isOpeningFile,1]);
  
      // },1700);

    }else
    if (isPlaying == 2){
      // UPDATE currentDataPosition
      // audioReplayCtx will be instantiated everytime, so get the played time only
      if (audioReplayCtx.state === 'suspended'){
        await audioReplayCtx.resume();

      }else{
        await audioReplayCtx.suspend();

      }
      isResetPlayback = false;

      const previousAudioPosition = audioReplayCtx.currentTime * sampleRate;
      currentDataPosition += previousAudioPosition;
      curTimeSeconds = currentDataPosition / sampleRate;
      // sumInitialPlaybackTime += audioReplayCtx.currentTime;
      sumInitialPlaybackTime = curTimeSeconds;
      window.drawElapsedTime([sumInitialPlaybackTime]);
      console.log("STOP TIME ", curTimeSeconds, sumInitialPlaybackTime);


      // Draw first to get current head
      // sbwNode.redraw();
      // let draw_state = new Int32Array(sabDraw.draw_states[0]);
      // currentDataPosition = draw_state[DRAW_STATE.CURRENT_HEAD];

      endTailWavPos= currentDataPosition;
      startHeadWavPos = currentDataPosition - (sampleRate * 10);
      if (startHeadWavPos < 0){
        startHeadWavPos = 0;
      }

      // window.drawElapsedTime([currentDataPosition]);
      isPlayingWav = false;      

      window.changeTimeBarStatus([true]);
      // console.log(audioReplayCtx.currentTime);
      currentPlayTime = audioReplayCtx.currentTime;
      
      await sbwNode.clearBuffer(sabDraw);

      await sbwNode.loadAudioBuffer(wav,openFileMarkers,sampleRate,sabDraw,channels, startHeadWavPos, currentDataPosition);

      sbwNode.redraw();
      setTimeout(()=>{
        sbwNode.redraw();

      },REDRAW_TIMEOUT);
    
    }else
    if (isPlaying == 3){
      isPlayingWav = false;      
      // console.log("AUDIO ", isPlaying);
      isOpeningFile = 0;
      isPlaying = 1;
    
      let sabDrawingState = new Int32Array(sabDraw.draw_states[0]);
      sabDrawingState[DRAW_STATE.HORIZONTAL_DRAG] = 0;

      closePlaybackScreen("audio");
      // window.callbackAudioInit();
      recordAudio("reinit");
    }


  }else{
    console.log("IS PLAYING : ", isPlaying);
    sampleRate = wav[1];
    if (isPlaying == 1){

      isPlayingWav = true;      
      // CHANGE BUTTONS
      window.changeResetPlayback([true]);
      window.changeTimeBarStatus([false]);
      console.log("CLEAR Serial ", sampleRate);
      sbwNode.clearBuffer(sabDraw);


      // setTimeout(()=>{
        // alert(currentDataPosition);
        processWav(currentDataPosition, openedWavSampleLength, false, false, timeScaleBar);
        window.drawElapsedTime([audioReplayCtx.currentTime + sumInitialPlaybackTime]);
        window.changePlaybackButton([isOpeningFile,1]);        
      // },300);

      
      // isPlayingWav = true;
      // const channels = openFileChannels;
      // window.changeResetPlayback([true]);
      // window.changeTimeBarStatus([false]);
  
  
      // // sampleRate = audioReplayCtx.sampleRate;
      // console.log("CLEAR SERIAL");

      // if (audioReplayCtx.state === 'suspended' && !isPlaybackStart){
      //   // alert("resume");
      //   audioReplayCtx.resume();
      //   isPlaying = 2;
      //   return;

      // }else{
      //   isPlaybackStart = false;
      //   // audioReplayCtx.suspend();
      //   // alert("suspemd");
      //   sbwNode.clearBuffer();
      //   sbwNode.loadMarkers([],openFileMarkers, sampleRate, sabDraw,channels);
      // }

      // // sbwNode.clearBuffer();
      // // sbwNode.loadMarkers([],openFileMarkers, sampleRate, sabDraw,channels);
      // // audioReplayCtx.start();

      // console.log("CLEAR BUFFER1 ", (new Int32Array(sabDraw.draw_states[0])) [DRAW_STATE.DIRECT_LOAD_FILE]);
      // (new Int32Array(sabDraw.draw_states[0])) [DRAW_STATE.DIRECT_LOAD_FILE] = 0;

      // sbwNode.redraw();

      // audioSource = audioReplayCtx.createBufferSource();
      // audioSource.buffer = audioBuf;
      // audioNode = audioSource.connect(sbwNode);
      // audioNode.connect(audioReplayCtx.destination);

      // audioSource.addEventListener('ended', function(time){
      //   isPlayingWav = false;
      //   audioReplayCtx.suspend();
      //   for (let c = 0; c < CHANNEL_COUNT_FIX; c++){
      //     let draw_state = new Int32Array(sabDraw.draw_states[c]);
      //     draw_state[DRAW_STATE.DIRECT_LOAD_FILE] = 1;        
      //   }
      //   window.changePlaybackButton([isOpeningFile?1:0,2]);
      //   isPlaying = 2;
      //   window.changeTimeBarStatus([true]);

      //   sbwNode.redraw();
      //   console.log(" sumInitialPlaybackTime ");
      //   sumInitialPlaybackTime = 0;
      //   isPlaybackStart = true;
      //   // processWav();
      //   // window.drawElapsedTime([1000000000]);
      //   // setTimeout(()=>{
      //   // },1000);


      // });

      // audioReplayCtx.resume();
      // audioSource.start(0,currentPlayTime);   
  
      // window.changePlaybackButton([isOpeningFile?1:0,1]);
    }else
    if (isPlaying == 2){//SUSPEND PLAYING SOUND

      
      if (audioReplayCtx.state === 'suspended'){
        audioReplayCtx.resume();

      }else{
        audioReplayCtx.suspend();
      }
    
      isResetPlayback = false;

      const previousAudioPosition = audioReplayCtx.currentTime * sampleRate;
      // alert("CURRENT "+currentDataPosition+" : "+previousAudioPosition);

      currentDataPosition += previousAudioPosition;
      curTimeSeconds = currentDataPosition / sampleRate;
      sumInitialPlaybackTime = curTimeSeconds;
      window.drawElapsedTime([sumInitialPlaybackTime]);


      endTailWavPos= currentDataPosition;
      startHeadWavPos = currentDataPosition - (sampleRate * 10);
      if (startHeadWavPos < 0){
        startHeadWavPos = 0;
      }

      isPlayingWav = false;      

      window.changeTimeBarStatus([true]);
      currentPlayTime = audioReplayCtx.currentTime;
      
      await sbwNode.clearBuffer(sabDraw);
      await sbwNode.loadSerialBuffer(wav,openFileMarkers,sampleRate,sabDraw,channels, startHeadWavPos, endTailWavPos);
      sbwNode.redraw();


        setTimeout(()=>{
          sbwNode.redraw();
  
        },REDRAW_TIMEOUT);      
  

      // audioSource.stop();
      // audioSource.diconnect(audioReplayCtx.destination);
    }else
    if (isPlaying == 3){
      isPlayingWav = false;
      isOpeningFile = 0;
      isPlaying = 1;
      closePlaybackScreen("serial");
      // window.callbackAudioInit([0,1]);

      recordAudio("reinit");
    }
  }

};


async function processWav(startTime = -1, endTime = -1, loadBuffer = true, autoplay=false, timeScale = 10000){
  // sumInitialPlaybackTime = 0;
  if (fileWorker === undefined){
    fileWorker = new Worker('build/web/file.worker.js')
  }else{
    try{ fileWorker.terminate(); fileWorker = undefined; }catch(err){console.log(err);}
  }
  
  try{ sequentialSignalWorker.terminate(); sequentialSignalWorker = undefined; }catch(err){console.log(err);}
  try{ sequentialFileWorker.terminate(); sequentialFileWorker = undefined; }catch(err){console.log(err);}

  try{ sbwNode.closeProcessor(); }catch(err){console.log("CLOSE PROCESSOR : ",err);}
  try{ sbwNode.terminateAll(); }catch(err){console.log("TERMINATE ALL : ",err);}
  try{ delete sbwNode }catch(err){console.log(err);}


  // mapWav;
  console.log("mapWav ",wav);
  let tempSampleRate = wav[1];
  sampleRate = tempSampleRate;
  if (tempSampleRate<3000) tempSampleRate *= 2;
  // https://stackoverflow.com/questions/27598270/resample-audio-buffer-from-44100-to-16000

  openFileAudioOptions = {
    sampleRate : tempSampleRate,
    latencyHint: 'playback',
    sinkId: "default"
  };

  // window.callbackOpenWavFile( wav );
  isOpeningFile = 1;
  isPrevOpeningFile = 0;
  if (loadBuffer){
    window.changePlaybackButton([isOpeningFile,2]); // 2 - stop status | but play icon will be shown
  }
  await ac.suspend();
  if (audioReplayCtx !== undefined){
    try{
      await audioReplayCtx.close();
    }catch(err){
      console.log("Close Audio context", err);
      window.callbackErrorLog( ["error_general", "Error Closing Audio"] );
    }
    try{
      delete audioReplayCtx;
    }catch(err){
      console.log("Delete Audio Context", err);
      window.callbackErrorLog( ["error_general", "Error Deleting Audio Replay Context"] );
    }

    
  }
  audioReplayCtx = new AudioContext(openFileAudioOptions);    
  await audioReplayCtx.suspend();
  isPlaybackStart = true;
  openFileChannels = wav[0];
  const channels = openFileChannels;

  const frameCount = wav[startWavIdx+0].length;
  const strColors = wav[4];
  const strNames = wav[5];
  openFileMarkers = wav[6];
  // openedWavSampleLength = wav[startWavIdx+0].length / channels;
  openedWavSampleLength = wav[startWavIdx+0].length;
  if (endTime == -1){
    endTime = openedWavSampleLength;
  }
  if (startTime == -1){
    startTime = openedWavSampleLength - (10 * sampleRate);
    if (startTime < 0){
      startTime = 0;
      curStaticTime = maxStaticTime;
    }else{
      startTime = 0;
      // endTime = startTime + Math.floor(10 * sampleRate /4);
      endTime = Math.floor(10 * sampleRate /2);
      curStaticTime = endTime / sampleRate;
      console.log("curStaticTime : ",endTime, sampleRate, curStaticTime);
    }
  }
  if (endTime == openedWavSampleLength && startTime == openedWavSampleLength){
    sbwNode.clearBuffer(sabDraw);
    startTime = 0;
    endTime = openedWavSampleLength;
    sumInitialPlaybackTime = 0;
    currentDataPosition = 0;
  }
  



  DISPLAY_CHANNEL_COUNT_FIX = channels;
  if ( strNames.indexOf('AUDIO') > -1 ){
    deviceType = 'audio';
  }else
  if ( strNames.toLowerCase().indexOf('serial') > -1 ){
    deviceType = 'serial';
  }else
  if ( strNames.toLowerCase().indexOf('hid') > -1 ){
    deviceType = 'hid';
  }


  console.log("BUFFER : ",channels, frameCount, sampleRate);
  console.log("SAMPLE RATE PLAYBACK ", sampleRate);
  const len = arrTimescale.length;
  let divider = arrTimescale[len-1];
  if (timeScale != 10000){
    divider = arrTimescale[levelScale];
  }
  window.changeTimeBarStatus([true]);

  if (deviceType == 'audio'){
    // await audioReplayCtx.audioWorklet.addModule('build/web/playback-shared-buffer-worklet-processor.js');
    await audioReplayCtx.audioWorklet.addModule('build/web/shared-buffer-worklet-processor.js');
    // const {default: SharedBufferWorkletNode} = await import('./shared-buffer-worklet-node.js');
    const {default: SharedBufferWorkletNode} = await import('./SharedWorkletNode.js');

    if (signalWorker === undefined){
      // signalWorker = new Worker('build/web/playback.signal.worker.js');
      signalWorker = new Worker('build/web/SignalThread.js');
    }else{
      try{ 
        signalWorker.terminate(); signalWorker = undefined; 
        // signalWorker = new Worker('build/web/playback.signal.worker.js');
        signalWorker = new Worker('build/web/SignalThread.js');
      }catch(err){console.log(err);}
    }

    if (window.SharedArrayBuffer){
      currentLevel = calculateLevel(timeScale);
      console.log("3 Sample Rate : "+sampleRate, currentLevel, timeScale );

      if (sabDraw){
        // changing from serial to hid gives draw_states to 12
        delete sabDraw;
      }
      sabDraw = {
        channelCount : CHANNEL_COUNT_FIX,
        playback_states : [
          new SharedArrayBuffer(CONFIG.bytesPerPosition * 20)            
        ],
        channelDisplays :
          new SharedArrayBuffer(CONFIG.bytesPerPosition * 10),
        

        draw_states : [
          new SharedArrayBuffer(CONFIG.bytesPerState * 70),
          new SharedArrayBuffer(CONFIG.bytesPerState * 70),
        ],
        levels : [
          new SharedArrayBuffer( 180000 * 2 ),
          new SharedArrayBuffer( 180000 * 2 ),
        ],
        events : new SharedArrayBuffer(MAX_MARKERS * Uint8Array.BYTES_PER_ELEMENT),
        eventPosition : new SharedArrayBuffer( MAX_MARKERS * Uint32Array.BYTES_PER_ELEMENT ),
        eventPositionResult : new SharedArrayBuffer( MAX_MARKERS * Float32Array.BYTES_PER_ELEMENT ),
        eventsCounter : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT ),
    
      };

      let draw_states = [];
      for (let c = 0; c < CHANNEL_COUNT_FIX; c++){
        let draw_state = new Int32Array(sabDraw.draw_states[c]);
        draw_state[DRAW_STATE.LEVEL] = currentLevel;
        draw_state[DRAW_STATE.SKIP_COUNTS] = currentLevel <= -1 ? 1 : arrCounts[currentLevel];
        draw_state[DRAW_STATE.DIVIDER] = divider;
        draw_state[DRAW_STATE.SAMPLE_RATE] = sampleRate;
        draw_state[DRAW_STATE.CHANNEL_COUNTS] = channels;
        draw_state[DRAW_STATE.DIRECT_LOAD_FILE] = 1;
        draw_state[DRAW_STATE.SURFACE_WIDTH] = window.innerWidth;        
        draw_states.push(draw_state);
  
      }
      realTimeLevel = currentLevel;
      sabEvents = (new Uint8Array(sabDraw.events));
      sabEventPositionResult = (new Float32Array(sabDraw.eventPositionResult));

      function repaint(timestamp){
        try{
          let ctr = new Uint8Array(sabDraw.eventsCounter)[0];
          let eventMarkers = [
            sabEvents.subarray(0,ctr),
            sabEventPositionResult.subarray(0,ctr),
          ];
          // window.drawEventMarkers(eventMarkers);
          // console.log(audioReplayCtx.currentTime);
          if (isPlayingWav){
            let playbackTime = [
              audioReplayCtx.currentTime + sumInitialPlaybackTime
              // curTimeSeconds
            ];
            if (startTime == -1 && endTime == -1){
              window.drawElapsedTime([curStaticTime]);
            }else{
              window.drawElapsedTime(playbackTime);
            }
          }

          let content = [];
          for (let c = 0; c < DISPLAY_CHANNEL_COUNT_FIX; c++){
            const temp = new Int16Array(sabDraw.levels[c]);
            // console.log("draw_states[0][DRAW_STATE.TAIL_IDX]",draw_states[0][DRAW_STATE.TAIL_IDX]);
            // const arr = temp.subarray(0,draw_states[c][DRAW_STATE.TAIL_IDX]);
            const arr = temp.subarray(draw_states[c][DRAW_STATE.HEAD_IDX],draw_states[c][DRAW_STATE.TAIL_IDX]);
            content[c]=arr;
          }
          content.push(
            eventMarkers
          );

          window.jsToDart(content);  
          if (deviceType == 'audio')
            window.requestAnimationFrame(repaint);
            
        }catch(exc){
          console.log("exc");
          console.log(exc);
          window.callbackErrorLog( ["error_general", "Error Repaint Loaded File"] );

        }
      }
      
      
      signalWorker.postMessage({
        command:"setUp",
        type: 'audio',
        drawSurfaceWidth : window.innerWidth,
        sabDraw:sabDraw,
        channelCount:channels,
        arrCounts : arrCounts,
        sampleRate: sampleRate,
        // sabDraw:sabDraw,
      });
        
      window.requestAnimationFrame(repaint);    
    }  

    sbwNode = new SharedBufferWorkletNode(audioReplayCtx,{
      worker:{
        channelCount : channels,
        signalWorker:signalWorker,
        fileWorker:fileWorker,
        sabDraw : sabDraw,
        sampleRate: sampleRate,
        arrCounts : arrCounts,
        action : 'playback',
        directAction : 'directLoad',
        directSamplesLength : wav[10].length,
      }
    }); //ADD OPTIONS HERE : level, channelCount

    try{
      audioBuf = audioReplayCtx.createBuffer(channels, openedWavSampleLength-startTime, tempSampleRate);      
    }catch(err){
      console.log("Error Audio Replay : ",err);
      console.log(openFileAudioOptions);
    }
    for (let c = 0; c < channels ; c++){
      let curBuf = audioBuf.getChannelData(c);
      const tempWav = int16ToFloat32(wav[startWavIdx+c],startTime,endTime);
      curBuf.set(tempWav,0);
    }
    
    // console.log(frameCount, curBuf);

    audioSource = audioReplayCtx.createBufferSource();
    audioSource.buffer = audioBuf;


    // audioSource.addEventListener('ended', function(time){
    //   audioReplayCtx.suspend();
    //   for (let c = 0; c < CHANNEL_COUNT_FIX; c++){
    //     let draw_state = new Int32Array(sabDraw.draw_states[c]);
    //     draw_state[DRAW_STATE.DIRECT_LOAD_FILE] = 1;        
    //   }
    //   isPlaying = 2;
    //   window.changePlaybackButton([isOpeningFile,2]);
    //   sbwNode.redraw();

    // });


    
    try{
      if (audioSourceEnded !== undefined){
        audioSource.removeEventListener('ended', audioSourceEnded);
      }
    }catch(err){
      console.log(err);
    }


    audioSourceEnded = function (time){
      isPlayingWav = false;
      startHeadWavPos = 0;
      currentDataPosition = 0;
      audioReplayCtx.suspend();
      for (let c = 0; c < CHANNEL_COUNT_FIX; c++){
        let draw_state = new Int32Array(sabDraw.draw_states[c]);
        draw_state[DRAW_STATE.DIRECT_LOAD_FILE] = 1;        
      }
      window.changePlaybackButton([isOpeningFile,2]);
      // processWav(openedWavSampleLength - (10 * sampleRate), openedWavSampleLength, true, false, timeScaleBar);
      
      isPlaying = 2;
      isReset = 0;
      isEnded = true;
      window.changeTimeBarStatus([true]);
      sbwNode.redraw();
      setTimeout(()=>{
        sbwNode.redraw();
        console.log(" sumInitialPlaybackTime 4");
        sumInitialPlaybackTime = 0;
        isPlaybackStart = true;  
        isResetPlayback = false;
      },REDRAW_TIMEOUT);

      // processWav();
      console.log("AUDIO SOURCE ENDEDDDD");
      window.drawElapsedTime([ openedWavSampleLength/sampleRate ]);
      window.callbackErrorLog( ["play_end", "End Playing Data"] );
      
    }
    audioSource.addEventListener('ended', audioSourceEnded);


  

    sampleRate = audioReplayCtx.sampleRate;
        
    audioNode = audioSource.connect(sbwNode);

    sbwNode.onInitialized = async () => {
      // await ac.resume();
      if (!loadBuffer){
        startHeadWavPos = startTime;
        endTailWavPos = endTime;

        (new Int32Array(sabDraw.draw_states[0])) [DRAW_STATE.DIRECT_LOAD_FILE] = 0;
        if (deviceType == 'audio'){
          (new Int32Array(sabDraw.draw_states[1])) [DRAW_STATE.DIRECT_LOAD_FILE] = 0;  
        }


        // populate previous data first
        const currentDataPosition = startTime;
        const screenFullSamples = (sampleRate * 10);
        await sbwNode.loadMarkers([],openFileMarkers, sampleRate, sabDraw,channels);
        if (currentDataPosition >= screenFullSamples){
          console.log(' currentDataPosition >= screenFullSamples ');
          // const startAudioPos = currentDataPosition;
          const startAudioPos = 0;
          const startBufferPos = currentDataPosition - screenFullSamples;
          // Load previous buffer
          // setTimeout(async ()=>{
            await sbwNode.loadAudioBuffer(wav,openFileMarkers, sampleRate, sabDraw,channels, startBufferPos, currentDataPosition, startAudioPos);
            sbwNode.redraw();
            setTimeout(()=>{
              sbwNode.redraw();
            }, REDRAW_TIMEOUT);
  
  
          // }, REDRAW_TIMEOUT/2);
        }else{
          // Load previous buffer
          let startBufferPos = currentDataPosition - screenFullSamples;
          if (startBufferPos < 0){
            startBufferPos = 0;
          }

          if (currentDataPosition - startBufferPos > 0){
            const startAudioPos = 0;

            // await sbwNode.loadAudioBuffer(wav,openFileMarkers, sampleRate, sabDraw,channels, startBufferPos, currentDataPosition, startAudioPos);
            // sbwNode.redraw();
            // setTimeout(()=>{
            //   sbwNode.redraw();
            // }, REDRAW_TIMEOUT);
            await sbwNode.loadAudioBuffer(wav,openFileMarkers, sampleRate, sabDraw,channels, startBufferPos, currentDataPosition, startAudioPos);
            setTimeout(async ()=>{
              sbwNode.redraw();
              setTimeout(()=>{
                sbwNode.redraw();
              }, REDRAW_TIMEOUT);
            }, REDRAW_TIMEOUT/2);
  
          }

        }

    
        audioNode = audioSource.connect(sbwNode);
        audioNode.connect(audioReplayCtx.destination);
    
        audioSource.start(0);
        await audioReplayCtx.resume();
      
      }else
      if (deviceType == 'audio'){ //initial loading audio
        console.log("CLEAR AUDIO");
        // window.callbackGetDeviceInfo([ 0, channels, channels ])
        sbwNode.clearBuffer(sabDraw);

        const NUMBER_OF_SEGMENTS = 60;
        const SEGMENT_SIZE = sampleRate;
        const SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE / 6;
      

        // sbwNode.loadMarkers([],openFileMarkers, sampleRate, sabDraw,channels);
        let level = calculateLevel(timeScale);

        // let startPos = openedWavSampleLength - SIZE;
        // let endPos = openedWavSampleLength;
        let startPos = startTime;
        let endPos = endTime;

        if (startPos < 0) startPos = 0;

        startHeadWavPos = startPos;
        endTailWavPos = endPos;

        

        await sbwNode.loadAudioBuffer(wav,openFileMarkers, sampleRate, sabDraw,channels, startPos, endPos);
        isPlaying = 2;
        isResetPlayback = false;
        if (autoplay)
          window.playData(1);

        // source.playbackRate.value = 5;

        // audioNode.connect(audioReplayCtx.destination);
        // audioSource.start();
      }else{//for serial see below section

      }
      
      console.log("sbwnode initialized");
    };

  }else{
    // await audioReplayCtx.audioWorklet.addModule('build/web/playback-sequential-shared-buffer-worklet-processor.js');
    await audioReplayCtx.audioWorklet.addModule('build/web/playback-sequential-shared-buffer-worklet-processor.js');
    // const {default: SequentialSharedBufferWorkletNode} = await import('./SerialSharedWorkletNode.js');
    const {default: SequentialSharedBufferWorkletNode} = await import('./SerialSharedWorkletNode.js');

    if (deviceType == 'hid'){
      window.callbackSerialInit([2,2]);
    }else{
      window.callbackSerialInit([1,2]);

    }

    if (sequentialSignalWorker === undefined){
      sequentialSignalWorker = new Worker('build/web/playback.sequential.signal.worker.js')
      // sequentialSignalWorker = new Worker('build/web/SignalThread.js')
    }else{
      try{ 
        sequentialSignalWorker.terminate(); sequentialSignalWorker = undefined; 
        sequentialSignalWorker = new Worker('build/web/playback.sequential.signal.worker.js')
        // sequentialSignalWorker = new Worker('build/web/SignalThread.js')

      }catch(err){console.log(err);}
    }    
    sequentialFileWorker = new Worker('build/web/sequential.file.worker.js')

    if (window.SharedArrayBuffer){
      console.log("3");
      currentLevel = calculateLevel(timeScale);

      sabSerialWriteData = {
        serialWriteState : new SharedArrayBuffer(SERIAL_WRITE_CONFIG.bytesPerState * 10),
        serialWriteMessage : new SharedArrayBuffer(SERIAL_WRITE_CONFIG.bytesPerSample * 1024)
      };
      if (sabDraw){
        delete sabDraw;
      }

      sabDraw = {
        channelCount : CHANNEL_COUNT_FIX,
        playback_states : [
          new SharedArrayBuffer(CONFIG.bytesPerPosition * 20)            
        ],
        channelDisplays :
          new SharedArrayBuffer(CONFIG.bytesPerPosition * 10),
        

        draw_states : [
          new SharedArrayBuffer(CONFIG.bytesPerSample * 70),
          new SharedArrayBuffer(CONFIG.bytesPerSample * 70),
          new SharedArrayBuffer(CONFIG.bytesPerSample * 70),
          new SharedArrayBuffer(CONFIG.bytesPerSample * 70),
          new SharedArrayBuffer(CONFIG.bytesPerSample * 70),
          new SharedArrayBuffer(CONFIG.bytesPerSample * 70),
        ],
        levels : [
          new SharedArrayBuffer( 200000 * 20 ),
          new SharedArrayBuffer( 200000 * 20 ),
          new SharedArrayBuffer( 200000 * 20 ),
          new SharedArrayBuffer( 200000 * 20 ),
          new SharedArrayBuffer( 200000 * 20 ),
          new SharedArrayBuffer( 200000 * 20 ),
        ],
        events : new SharedArrayBuffer(MAX_MARKERS * Uint8Array.BYTES_PER_ELEMENT),
        eventPosition : new SharedArrayBuffer( MAX_MARKERS * Uint32Array.BYTES_PER_ELEMENT ),
        eventPositionResult : new SharedArrayBuffer( MAX_MARKERS * Float32Array.BYTES_PER_ELEMENT ),
        eventsCounter : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT ),

      };

      console.log("4");
      let draw_states = [];
      for (let c = 0; c < SERIAL_CHANNEL_COUNT_FIX; c++){
        let draw_state = new Int32Array(sabDraw.draw_states[c]);
        draw_state[DRAW_STATE.LEVEL] = currentLevel;
        draw_state[DRAW_STATE.SKIP_COUNTS] = currentLevel <= -1 ? 1 : arrCounts[currentLevel];
        draw_state[DRAW_STATE.DIVIDER] = divider;
        draw_state[DRAW_STATE.SAMPLE_RATE] = sampleRate;
        draw_state[DRAW_STATE.CHANNEL_COUNTS] = channels;
        draw_state[DRAW_STATE.SURFACE_WIDTH] = window.innerWidth;        
        draw_states.push(draw_state);
  
      }
      realTimeLevel = currentLevel;
      console.log("5");

      sabEvents = (new Uint8Array(sabDraw.events));
      sabEventPositionResult = (new Float32Array(sabDraw.eventPositionResult));

      function repaint(timestamp){
          try{
            // console.log("TIME ", (new Date()).getTime() );
            let ctr = new Uint8Array(sabDraw.eventsCounter)[0];
            let eventMarkers = [
              sabEvents.subarray(0,ctr),
              sabEventPositionResult.subarray(0,ctr),
            ];
            // window.drawEventMarkers(eventMarkers);
            if (isPlayingWav){
              let playbackTime = [
                // audioReplayCtx.currentTime - sumInitialPlaybackTime
                audioReplayCtx.currentTime + sumInitialPlaybackTime
                // curTimeSeconds
              ];
              if (startTime == -1 && endTime == -1){
                window.drawElapsedTime([curStaticTime]);
              }else{
                window.drawElapsedTime(playbackTime);
              }
              // console.log("audioReplayCtx.currentTime + sumInitialPlaybackTime : ", audioReplayCtx.currentTime, sumInitialPlaybackTime, typeof playbackTime[0]);
            }
  
    
            let content = [];

            for (let c = 0; c < DISPLAY_CHANNEL_COUNT_FIX; c++){
              const temp = new Int16Array(sabDraw.levels[c]);
              const arr = temp.subarray(0,draw_states[c][DRAW_STATE.TAIL_IDX]);
              // console.log("DRAW BUFFER ", c, draw_states[c][DRAW_STATE.TAIL_IDX]);
              content[c]=arr;
            }
            content.push(
              eventMarkers
            );

            // console.log("6", "DISPLAY CHANNEL COUNT FIX ", DISPLAY_CHANNEL_COUNT_FIX, content.length, content[content.length-1]);
            // console.log("content : ",content);
            window.jsToDart(content);  
            // if (deviceType == 'serial')
              window.requestAnimationFrame(repaint);
              
          }catch(exc){
            console.log("exc");
            console.log(exc);
            // if (deviceType == 'serial')
              window.requestAnimationFrame(repaint);
          }
      }
      
      window.requestAnimationFrame(repaint);    
    }  
    console.log("10");
    sequentialSignalWorker.postMessage({
      command:"setUp",
      type: 'serial',
      drawSurfaceWidth : window.innerWidth,
      sabDraw:sabDraw,
      channelCount:channels,
      arrCounts : arrCounts,
      sampleRate : tempSampleRate,
    });
    const deviceId = strNames.split("@")[0];
    let sequentialOptions = {
      worker:{
        channelCount : channels,
        signalWorker:sequentialSignalWorker,
        fileWorker:fileWorker,
        sabDraw : sabDraw,
        sabSerialWriteData : sabSerialWriteData,
        arrCounts : arrCounts,        
        sampleRate: sampleRate,
        curSampleRate : wav[1],
        action : 'playback',
        directAction : 'directLoad',
        directSamplesLength : wav[10].length,
        reportId : reportId,
        strDevice : '',//deviceId,
        onInitialized : async ()=>{
          // if (deviceType == 'audio'){
          if (!loadBuffer){
            startHeadWavPos = startTime;
            endTailWavPos = endTime;
            window.changePlaybackButton([isOpeningFile,1]);
    
            // populate previous data first
            let _currentDataPosition = startTime;
            const screenFullSamples = (sampleRate * 10);
            if (_currentDataPosition >= screenFullSamples){
              console.log(' _currentDataPosition >= screenFullSamples ');
              const startBufferPos = _currentDataPosition - screenFullSamples;
              
              // await sbwNode.loadSerialBuffer(wav,openFileMarkers, sampleRate, sabDraw,channels, startBufferPos, _currentDataPosition);
              // sbwNode.redraw();
              // setTimeout(()=>{
              //   sbwNode.redraw();
              // }, REDRAW_TIMEOUT);

              setTimeout(async()=>{
                await sbwNode.loadSerialBuffer(wav,openFileMarkers, sampleRate, sabDraw,channels, startBufferPos, _currentDataPosition);
                sbwNode.redraw();
                setTimeout(()=>{
                  sbwNode.redraw();
                }, REDRAW_TIMEOUT);
      
      
              }, REDRAW_TIMEOUT/2);
    
        
            }else{
              // Load previous buffer
              let startBufferPos = _currentDataPosition - screenFullSamples;
              if (startBufferPos < 0){
                startBufferPos = 0;
              }
    
              if (_currentDataPosition - startBufferPos > 0){    
                // await sbwNode.loadSerialBuffer(wav,openFileMarkers, sampleRate, sabDraw,channels, startBufferPos, _currentDataPosition);
                // sbwNode.redraw();
                // setTimeout(()=>{
                //   sbwNode.redraw();
                // }, REDRAW_TIMEOUT);
                setTimeout(async ()=>{
                  await sbwNode.loadSerialBuffer(wav,openFileMarkers, sampleRate, sabDraw,channels, startBufferPos, _currentDataPosition);
                  sbwNode.redraw();
                  setTimeout(()=>{
                    sbwNode.redraw();
                  }, REDRAW_TIMEOUT);
        
        
                }, REDRAW_TIMEOUT/2);
  
              }
            }

            /* DISTINCTIVE */
            if (sampleRate>=3000){
              audioBuf = audioReplayCtx.createBuffer(channels, endTime-startTime, tempSampleRate);                            
              // audioBuf = audioReplayCtx.createBuffer(channels, frameCount, tempSampleRate);
              await sbwNode.loadMarkers([],openFileMarkers, sampleRate, sabDraw,channels);

              for (let c = 0; c < channels ; c++){
                let curBuf = audioBuf.getChannelData(c);
                // const tempWav = int16ToFloat32(wav[startWavIdx+c],0,wav[startWavIdx+c].length);
                const tempWav = int16ToFloat32(wav[startWavIdx+c],startTime,endTime);
                curBuf.set(tempWav,0);
              }
        
              for (let c = 0; c < 1; c++){
                let draw_state = new Int32Array(sabDraw.draw_states[c]);
                draw_state[DRAW_STATE.DIRECT_LOAD_FILE] = 1;
              }
            }else
            if (sampleRate < 3000){
              await sbwNode.loadMarkers([],openFileMarkers, sampleRate, sabDraw,channels, 1);
              // createBuffer(5, 4294962482, 4000)
              audioBuf = audioReplayCtx.createBuffer(channels, (endTime-startTime)*2, tempSampleRate);                            
              // audioBuf = audioReplayCtx.createBuffer(channels, Math.floor(frameCount * 2 ), tempSampleRate);

              for (let c = 0; c < channels ; c++){
                let curBuf = audioBuf.getChannelData(c);
                console.log("BUFFER PER CHANNEL ", curBuf.length);
                let curBufIdx = 0;
                // const tempWav = int16ToFloat32(wav[startWavIdx+c],0,wav[startWavIdx+c].length);
                const tempWav = int16ToFloat32(wav[startWavIdx+c],startTime,endTime);

                for (let j = 1; j < tempWav.length ; j++){
                  curBuf[curBufIdx++] = tempWav[j-1];
                  curBuf[curBufIdx++] = 0.5* (tempWav[j-1] + tempWav[j]);
                  // if (j % 2 == 0){
                  //   const idxNow = j-1;
                  //   const idxPrev = j-2;
                  //   curBuf[curBufIdx++] = ( (tempWav[idxNow] + tempWav[idxPrev]) / 2 );
                  //   curBuf[curBufIdx++] = tempWav[idxNow];
                  // }else{
                  //   curBuf[curBufIdx++] = tempWav[j-1];
                  // }
                }
                curBuf[curBufIdx++] = tempWav[tempWav.length-1];
                // curBuf.set(tempWav,0);
                for (let c = 0; c < 1; c++){
                  let draw_state = new Int32Array(sabDraw.draw_states[c]);
                  draw_state[DRAW_STATE.DIRECT_LOAD_FILE] = 1;
                }

              }

              // playback serial with removed resamples data
              // await audioReplayCtx.audioWorklet.addModule('build/web/playback-shared-buffer-worklet-processor.js');
              await audioReplayCtx.audioWorklet.addModule('build/web/shared-buffer-worklet-processor.js');

            }else{
              // playback serial with full samples
              // await audioReplayCtx.audioWorklet.addModule('build/web/playback-shared-buffer-worklet-processor.js');
              await audioReplayCtx.audioWorklet.addModule('build/web/shared-buffer-worklet-processor.js');

            }
            (new Int32Array(sabDraw.draw_states[0])) [DRAW_STATE.DIRECT_LOAD_FILE] = 0;

            audioSource = audioReplayCtx.createBufferSource();
            audioSource.buffer = audioBuf;
            audioNode = audioSource.connect(sbwNode);
            audioNode.connect(audioReplayCtx.destination);
          
            try{
              if (audioSourceEnded !== undefined){
                audioSource.removeEventListener('ended', audioSourceEnded);
              }
            }catch(err){
              console.log(err);
            }
        
        
            audioSourceEnded = async function (time){
              currentDataPosition = 0;
              startHeadWavPos = 0;
              isPlayingWav = false;
              audioReplayCtx.suspend();
              for (let c = 0; c < CHANNEL_COUNT_FIX; c++){
                let draw_state = new Int32Array(sabDraw.draw_states[c]);
                draw_state[DRAW_STATE.DIRECT_LOAD_FILE] = 1;        
              }
              window.changePlaybackButton([isOpeningFile,2]);
              isPlaying = 2;
              isReset = 0;
              isEnded = true;
              window.changeTimeBarStatus([true]);
              // if (sampleRate < 3000){
              {
                let startBufferPos = endTailWavPos - screenFullSamples;
                if (startBufferPos < 0){
                  startBufferPos = 0;
                }
                startTime = 0;
                currentDataPosition = 0;
                startHeadWavPos = 0;
  
                // need to change into processWav
                // await sbwNode.loadSerialBuffer(wav,openFileMarkers, sampleRate, sabDraw,channels, startBufferPos, endTailWavPos);
                await processWav(0,endTailWavPos,true,false, timeScaleBar);
              }

              sbwNode.redraw();
              setTimeout(()=>{
                sbwNode.redraw();
              }, REDRAW_TIMEOUT);
              console.log(" sumInitialPlaybackTime 5");
              sumInitialPlaybackTime = 0;
              isPlaybackStart = true;
              isResetPlayback = false;

              window.drawElapsedTime([ openedWavSampleLength/sampleRate ]);
              window.callbackErrorLog( ["play_end", "End Playing Data"] );

              // processWav();
              // window.drawElapsedTime([1000000000]);
            }
            audioSource.addEventListener('ended', audioSourceEnded);
        

                
        
            // audioNode = audioSource.connect(sbwNode);
            // audioNode.connect(audioReplayCtx.destination);
        
            audioSource.start(0);
            await audioReplayCtx.resume();            
          }else{              
            console.log("CLEAR SERIAL");
            sbwNode.clearBuffer(sabDraw);
            // sbwNode.loadMarkers([],openFileMarkers, sampleRate, sabDraw,channels);
            const NUMBER_OF_SEGMENTS = 60;
            const SEGMENT_SIZE = sampleRate;
            const SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE / 6;
          
                let level = calculateLevel(timeScale);
  
            // let startPos = openedWavSampleLength - SIZE;
            // let endPos = openedWavSampleLength;
            let startPos = startTime;
            let endPos = endTime;
  
            if (startPos < 0) startPos = 0;
  
            startHeadWavPos = startPos;
            endTailWavPos = endPos;
            if (!loadBuffer){
              startHeadWavPos = startTime;
              endTailWavPos = endTime;
            }else{
              await sbwNode.loadSerialBuffer(wav,openFileMarkers, sampleRate, sabDraw,channels, startPos, endPos);
            }
      
            isPlaying = 2;
            // https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode
            //button click
            // CLEAR BUFFER FIRST
            // source.start();
            
            // source.connect(audioReplayCtx.destination);


            if (sampleRate>=3000){
              audioBuf = audioReplayCtx.createBuffer(channels, endTime-startTime, tempSampleRate);              
              // audioBuf = audioReplayCtx.createBuffer(channels, frameCount, tempSampleRate);

              for (let c = 0; c < channels ; c++){
                let curBuf = audioBuf.getChannelData(c);
                // const tempWav = int16ToFloat32(wav[startWavIdx+c],0,wav[startWavIdx+c].length);
                const tempWav = int16ToFloat32(wav[startWavIdx+c],startTime,endTime);
                curBuf.set(tempWav,0);
              }
        
              // audioSource = audioReplayCtx.createBufferSource();
              // audioSource.buffer = audioBuf;
          
          
              // audioSource.addEventListener('ended', function(time){
              for (let c = 0; c < 1; c++){
                let draw_state = new Int32Array(sabDraw.draw_states[c]);
                draw_state[DRAW_STATE.DIRECT_LOAD_FILE] = 1;
              }
              //   isPlaying = 2;
              //   window.changePlaybackButton([isOpeningFile,2]);
              //   sbwNode.redraw();
        
              // });            
              // sampleRate = audioReplayCtx.sampleRate;
                  
              // audioNode = audioSource.connect(sbwNode);
        
            }else
            if (sampleRate < 3000){
              audioBuf = audioReplayCtx.createBuffer(channels, Math.floor( (endTime-startTime) * 2), tempSampleRate);

              for (let c = 0; c < channels ; c++){
                let curBuf = audioBuf.getChannelData(c);
                let curBufIdx = 0;
                // const tempWav = int16ToFloat32(wav[startWavIdx+c],0,wav[startWavIdx+c].length);
                const tempWav = int16ToFloat32(wav[startWavIdx+c],startTime,endTime);

                for (let j = 1; j < tempWav.length ; j++){
                  curBuf[curBufIdx++] = tempWav[j-1];
                  curBuf[curBufIdx++] = 0.5* (tempWav[j-1] + tempWav[j]);                  

                  // if (j % 2 == 0){
                  //   const idxNow = j-1;
                  //   const idxPrev = j-2;
                  //   curBuf[curBufIdx++] = ( (tempWav[idxNow] + tempWav[idxPrev]) / 2 );
                  //   curBuf[curBufIdx++] = tempWav[idxNow];
                  // }else{
                  //   curBuf[curBufIdx++] = tempWav[j-1];
                  // }
                }
                curBuf[curBufIdx++] = tempWav[tempWav.length-1];
                // curBuf.set(tempWav,0);
                for (let c = 0; c < 1; c++){
                  let draw_state = new Int32Array(sabDraw.draw_states[c]);
                  draw_state[DRAW_STATE.DIRECT_LOAD_FILE] = 1;
                }

              }

              // const TARGET_SAMPLE_RATE = tempSampleRate;
              // for (let c = 0; c < channels ; c++){
              //   // const offlineCtx = new OfflineAudioContext(1,
              //   //                                        wav[startWavIdx+c].length,
              //   //                                        TARGET_SAMPLE_RATE);
              //   // const offlineSource = offlineCtx.createBufferSource();
              //   // const resampleBuf = offlineCtx.createBuffer(channels, frameCount, sampleRate);
              //   // const curResampleBuf = resampleBuf.getChannelData(c);
              //   // const tempResampleWav = int16ToFloat32(wav[startWavIdx+c],0,wav[startWavIdx+c].length);
              //   // curResampleBuf.set(tempResampleWav,0);
            
              //   // offlineSource.buffer = offlineSource;
              //   // offlineSource.connect(offlineCtx.destination);
              //   // offlineSource.start();
              //   // const resample = await offlineCtx.startRendering();
                                       


              //   // const source = audioReplayCtx.createBufferSource();
              //   // source.buffer = audioBuf;
            
              //   // const curBuf = audioBuf.getChannelData(0);
              //   // const tempWav = int16ToFloat32(resample,0,resample.length);
              //   // curBuf.set(tempWav,0);
            
              //   // source.addEventListener('ended', function(time){
              //   //   isPlaying = 2;
              //   // });
                              
              //   // source.connect(audioReplayCtx.destination);

              // }
          

              
              // Play it from the beginning.
              // offlineCtx.startRendering().then((resampled) => {
              //   // `resampled` contains an AudioBuffer resampled at 16000Hz.
              //   // use resampled.getChannelData(x) to get an Float32Array for channel x.
            
              // });              
              // playback serial with removed resamples data
              // await audioReplayCtx.audioWorklet.addModule('build/web/playback-shared-buffer-worklet-processor.js');
              await audioReplayCtx.audioWorklet.addModule('build/web/shared-buffer-worklet-processor.js');

            }else{
              // playback serial with full samples
              // await audioReplayCtx.audioWorklet.addModule('build/web/playback-shared-buffer-worklet-processor.js');
              await audioReplayCtx.audioWorklet.addModule('build/web/shared-buffer-worklet-processor.js');

            }

            audioSource = audioReplayCtx.createBufferSource();
            audioSource.buffer = audioBuf;
            audioNode = audioSource.connect(sbwNode);
            audioNode.connect(audioReplayCtx.destination);
          
            try{
              if (audioSourceEnded !== undefined){
                audioSource.removeEventListener('ended', audioSourceEnded);
              }
            }catch(err){
              console.log(err);
            }
        
        
            audioSourceEnded = async function (time){
              startHeadWavPos = 0;
              currentDataPosition = 0;
              isPlayingWav = false;
              audioReplayCtx.suspend();
              for (let c = 0; c < CHANNEL_COUNT_FIX; c++){
                let draw_state = new Int32Array(sabDraw.draw_states[c]);
                draw_state[DRAW_STATE.DIRECT_LOAD_FILE] = 1;        
              }
              window.changePlaybackButton([isOpeningFile,2]);
              isPlaying = 2;
              isReset = 0;
              isEnded = true;
              window.changeTimeBarStatus([true]);
              sumInitialPlaybackTime = 0;
              // if (sampleRate < 3000){
              {
                let startBufferPos = endTailWavPos - screenFullSamples;
                if (startBufferPos < 0){
                  startBufferPos = 0;
                }
      
                // await sbwNode.loadSerialBuffer(wav,openFileMarkers, sampleRate, sabDraw,channels, startBufferPos, endTailWavPos);
                await processWav(0,endTailWavPos,true,false, timeScaleBar);
                  
              }

              sbwNode.redraw();
              setTimeout(()=>{
                sbwNode.redraw();
              }, REDRAW_TIMEOUT);
              console.log(" sumInitialPlaybackTime 5");
              isPlaybackStart = true;
              isResetPlayback = false;
              

              window.drawElapsedTime([ openedWavSampleLength/sampleRate ]);
              window.callbackErrorLog( ["play_end", "End Playing Data"] );

              // processWav();
              // window.drawElapsedTime([1000000000]);
            }
            audioSource.addEventListener('ended', audioSourceEnded);    

            isResetPlayback = false;
            if (autoplay)
              window.playData(1);
    
          }

          
          console.log("sbwnode initialized");
      
        }
    
      }
    };
    if (deviceType == 'hid'){
      sequentialOptions["worker"]["deviceType"] = deviceType;
    }

    
    sbwNode = new SequentialSharedBufferWorkletNode(audioReplayCtx,sequentialOptions); //ADD OPTIONS HERE : level, channelCount
  }

  // console.log("mapWav[10].length : ", mapWav[10].length);


  sbwNode.onError = (errorData) => {
    logger.post('[ERROR] ' + errorData.detail);
  };

  
      // audioNode.connect(audioReplayCtx.destination);
  //button click
  // CLEAR BUFFER FIRST
  // source.start();
  
  // source.connect(audioReplayCtx.destination);

  // load all data



  await ac.suspend();
  
  
  // if (deviceType == 'audio')
  // fill the current audio shared array buffer with the samples for each channel
  // if isOpeningFile then change is playing : 11 - playing with sound ; 12 - stop ; 13 - return, isOpeningFile = false -> default to 12 - stop
  // change isOpeningFile
  // if is playing with sound, periodically insert data to shared array buffer
  // when stopped fill in all data

  wavFileReaderWorker.terminate();  
  const curTime = currentDataPosition / sampleRate;
  if (startTime == -1 && endTime == -1){
    window.drawElapsedTime([curStaticTime]);    
  }else{
    window.drawElapsedTime([curTime]);    
  }

  if (loadBuffer){
    setTimeout(()=>{
      sbwNode.redraw();
    },1500);

  }


}

window.openReadWavFile = async function(){
  levelScale = 80;
  if (window.showOpenFilePicker === undefined){
    alert("Sorry your browser doesn't support recording to file");
    return;
  }
  currentPlayTime = 0;

  const options = {
    multiple: false,
    types: [
      {
        description: 'Spike-Recorder',
        accept: {
          // 'audio/wav': ['.wav'],
          // 'text/plain': ['.txt'],
          'application/zip': ['.byb'],
        },
      },
    ],
  };
  const files = await window.showOpenFilePicker(options);
  console.log(files);
  openWavFileHandle = files[0];
  if (openWavFileHandle == null) return;
  
  try{
    sbwNode.clearBuffer(sabDraw);
  }catch(err){
    console.log("CLEAR BUFFER : ",err);
  }

  window.callbackOpeningFile([true]);

  try{
    wavFileReaderWorker.terminate();
  }catch(err){
    console.log("TERMINATE");
  }

  wavFileReaderWorker = new Worker('build/web/readwavfile.worker.js');
  let openReadChannel = new MessageChannel();

  wavFileReaderWorker.postMessage({
    command: "setConfig",
    deviceType : deviceType,
    wavFileHandle : openWavFileHandle,
    port : openReadChannel.port1
  }, [openReadChannel.port1]);

  openReadChannel.port2.onmessage = async (rawWav) =>{
    wav = rawWav.data;
    curTimeDivision = 0;
    prefixTimeSeconds = 0;
    curTimeSeconds = 0;

    window.changeResetPlayback([true]);
    window.changeTimeBarStatus([true]);
  
    
    await window.callbackOpenWavFile( wav );

    processWav();
    setTimeout(()=>{
      window.drawElapsedTime([curStaticTime]);
    }, 700);
    



  };
}


function int16ToFloat32(inputArray, startIndex, endIndex) {
  let len = endIndex-startIndex;
  var output = new Float32Array(len);
  for (var i = 0; i < len; i++) {
      var int = inputArray[startIndex + i];
      // If the high bit is on, then it is a negative number, and actually counts backwards.
      var float = (int >= 0x8000) ? -(0x10000 - int) / 0x8000 : int / 0x7FFF;
      output[i] = float;
  }
  return output;
}


function floatTo16Bit(inputArray, startIndex){
  var output = new Uint16Array(inputArray.length-startIndex);
  for (var i = 0; i < inputArray.length; i++){
      var s = Math.max(-1, Math.min(1, inputArray[i]));
      output[i-startIndex] = s < 0 ? s * 0x8000 : s * 0x7FFF;
  }
  return output;
}
async function setDeviceInfo( platform, version, appVersion, ua ){
  os = platform;
  versionNumber = version;
  userAgent = appVersion;
  deviceDetail = ua;

}


async function getChromeVersion(text) {
  var pieces = navigator.userAgent.match(/Chrom(?:e|ium)\/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/);
  if (pieces == null || pieces.length != 5) {
      return undefined;
  }
  pieces = pieces.map(piece => parseInt(piece, 10));
  const strVersion = pieces[1]+"."+pieces[2]+"."+pieces[3]+"."+pieces[4];
  console.log(strVersion);
  window.callbackGetChromeVersion([ 
    parseInt(pieces[1]), 
    parseInt(pieces[2]), 
    parseInt(pieces[3]), 
    parseInt(pieces[4]), 
  ]);
  return strVersion;
}


async function setFps(fps, _incSkip){
  if (!sabDraw) return;
  // myFps = parseInt(params[0] + "");
  // incSkip = parseInt(params[1] + "");
  myFps = fps;
  incSkip = _incSkip;
  let sabDrawingState = new Int32Array(sabDraw.draw_states[0]);
  const prevLevel = sabDrawingState[DRAW_STATE.LEVEL];
  let curLevel = calculateLevel(timeScaleBar);
  console.log("myFps : ",myFps,arrCounts[curLevel]);
  if (curLevel != prevLevel){
    sabDrawingState[DRAW_STATE.SKIP_COUNTS] = arrCounts[curLevel];
    sabDrawingState[DRAW_STATE.LEVEL] = curLevel;  
  }

}




const DEVICE_PRODUCT = {
  '1_11891' : { //Muscle SpikerBox Pro
    "deviceIdx" : 1,
    "maxSamplingRate" : 10000,
    "minChannels" : 2,
    "maxChannels" : 4,
    "channels" : [2,3,4],
    "sampleRates" : [10000,10000,5000,5000],
  },
  '2_11891' : { // Neuron SpikerBox Pro
    "deviceIdx" : 6,
    "maxSamplingRate" : 10000,
    "minChannels" : 2,
    "maxChannels" : 4,
    "channels" : [2,3,4],
    "sampleRates" : [10000,10000,5000,5000],
  },
  '24597_1027' : { // Heart & brain spiker box
    "deviceIdx" : 5,
    "maxSamplingRate" : 10000,
    "minChannels" : 1,
    "maxChannels" : 1,
    "channels" : [1],
    "sampleRates" : [10000],
    "baudRate" : 222222,
  },
  '32822_9025' : { // Plant SpikerBox
    "deviceIdx" : 2,
    "maxSamplingRate" : 10000,
    "minChannels" : 1,
    "maxChannels" : 1,
    "channels" : [1],
    "sampleRates" : [10000],
    "baudRate" : 222222,
  },
  // 67 : { // Human-Human-Interface 
  //   "maxSamplingRate" : 10000,
  //   "minChannels" : 1,
  //   "maxChannels" : 1,
  //   "channels" : [1],
  //   "sampleRates" : [10000],
  // },
  // '24597_1027' : { //Human-Human-Interface (second generation, under development)
  //   "maxSamplingRate" : 10000,
  //   "minChannels" : 1,
  //   "maxChannels" : 1,
  //   "channels" : [1],
  //   "sampleRates" : [10000],
  //   "baudRate" : 500000,
  // },
  //'67_10755'
  '67_1204' : { //Muscle SpikerShield
    "deviceIdx" : 4,
    "maxSamplingRate" : 10000,
    "minChannels" : 1,
    "maxChannels" : 6,
    "channels" : [1,2,3,4,5,6],
    "sampleRates" : [10000,5000,3333,2500,2000,1666],
    "baudRate" : 222222,    
  },
  '67_1240' : { //Muscle SpikerShield
    "deviceIdx" : 4,
    "maxSamplingRate" : 10000,
    "minChannels" : 1,
    "maxChannels" : 6,
    "channels" : [1,2,3,4,5,6],
    "sampleRates" : [10000,5000,3333,2500,2000,1666],
    "baudRate" : 222222,    
  },
  '67_1240' : { //Muscle SpikerShield
    "deviceIdx" : 4,
    "maxSamplingRate" : 10000,
    "minChannels" : 1,
    "maxChannels" : 6,
    "channels" : [1,2,3,4,5,6],
    "sampleRates" : [10000,5000,3333,2500,2000,1666],
    "baudRate" : 222222,    
  },
  '67_1659' : { //Muscle SpikerShield
    "deviceIdx" : 4,
    "maxSamplingRate" : 10000,
    "minChannels" : 1,
    "maxChannels" : 6,
    "channels" : [1,2,3,4,5,6],
    "sampleRates" : [10000,5000,3333,2500,2000,1666],
    "baudRate" : 222222,    
  },
  '67_17224' : { //Muscle SpikerShield
    "deviceIdx" : 4,
    "maxSamplingRate" : 10000,
    "minChannels" : 1,
    "maxChannels" : 6,
    "channels" : [1,2,3,4,5,6],
    "sampleRates" : [10000,5000,3333,2500,2000,1666],
    "baudRate" : 222222,    
  },
  '67_6790' : { //Muscle SpikerShield
    "deviceIdx" : 4,
    "maxSamplingRate" : 10000,
    "minChannels" : 1,
    "maxChannels" : 6,
    "channels" : [1,2,3,4,5,6],
    "sampleRates" : [10000,5000,3333,2500,2000,1666],
    "baudRate" : 222222,    
  },
  '67_1027' : { //Muscle SpikerShield
    "deviceIdx" : 4,
    "maxSamplingRate" : 10000,
    "minChannels" : 1,
    "maxChannels" : 6,
    "channels" : [1,2,3,4,5,6],
    "sampleRates" : [10000,5000,3333,2500,2000,1666],
    "baudRate" : 222222,    
  },
  '67_9114' : { //Muscle SpikerShield
    "deviceIdx" : 4,
    "maxSamplingRate" : 10000,
    "minChannels" : 1,
    "maxChannels" : 6,
    "channels" : [1,2,3,4,5,6],
    "sampleRates" : [10000,5000,3333,2500,2000,1666],
    "baudRate" : 222222,    
  },
  '67_6991' : { //Muscle SpikerShield
    "deviceIdx" : 4,
    "maxSamplingRate" : 10000,
    "minChannels" : 1,
    "maxChannels" : 6,
    "channels" : [1,2,3,4,5,6],
    "sampleRates" : [10000,5000,3333,2500,2000,1666],
    "baudRate" : 222222,    
  },
  '67_9025' : { //Muscle SpikerShield
    "deviceIdx" : 4,
    "maxSamplingRate" : 10000,
    "minChannels" : 1,
    "maxChannels" : 6,
    "channels" : [1,2,3,4,5,6],
    "sampleRates" : [10000,5000,3333,2500,2000,1666],
    "baudRate" : 222222,    
  },

  '67_10755' : { //Muscle SpikerShield
    "deviceIdx" : 4,
    "maxSamplingRate" : 10000,
    "minChannels" : 1,
    "maxChannels" : 6,
    "channels" : [1,2,3,4,5,6],
    "sampleRates" : [10000,5000,3333,2500,2000,1666],
    "baudRate" : 222222,    
  },
  '4_11891' : { //Human SpikerBox
    "deviceIdx" : 9,
    "maxSamplingRate" : 5000,
    "minChannels" : 2,
    "maxChannels" : 4,
    "channels" : [2,3,4],
    "sampleRates" : [5000, 5000,5000,5000],
    "baudRate" : 222222,
  },

};


var t
var prevWidth;
window.onresize = () => {
    // resizing(this, this.innerWidth, this.innerHeight) //1
    if (prevWidth == this.innerWidth){
      return;
    }
    prevWidth = this.innerWidth;
    // if (typeof t == 'undefined') resStarted() //2
    clearTimeout(t); t = setTimeout(() => { t = undefined; resEnded() }, 500) //3
}

function resEnded(){
  try{
    if (sabDraw === undefined) return;
    let sabDrawingState = new Int32Array(sabDraw.draw_states[0]);
    sabDrawingState[DRAW_STATE.SURFACE_WIDTH] = this.innerWidth;
    let currentLevel = sabDrawingState[DRAW_STATE.LEVEL] = calculateLevel(timeScaleBar);
    sabDrawingState[DRAW_STATE.SKIP_COUNTS] = arrCounts[currentLevel];
  
  }catch(err){

  }

}
window.setFlagChannelDisplay = function(flagDisplay1,flagDisplay2,flagDisplay3,flagDisplay4,flagDisplay5,flagDisplay6){
  if (sabDraw === undefined) return;
  let flagChannelDisplays = new Uint32Array(sabDraw.channelDisplays);
  flagChannelDisplays[0] = flagDisplay1;
  flagChannelDisplays[1] = flagDisplay2;
  flagChannelDisplays[2] = flagDisplay3;
  flagChannelDisplays[3] = flagDisplay4;
  flagChannelDisplays[4] = flagDisplay5;
  flagChannelDisplays[5] = flagDisplay6;
  // for (let i = 0; i < flagDisplays.length; i++){
  //   flagChannelDisplays[i] = flagDisplays[i];
  // }
  console.log("flagChannelDisplays L: ", flagChannelDisplays);
}

window.changeFilter = function(channelCount, isLowPass, lowPassFilter, isHighPass, highPassFilter){
  for (let c = 0; c < channelCount; c++){
    let draw_state = new Int32Array(sabDraw.draw_states[c]);
    draw_state[DRAW_STATE.LOW_PASS_FILTER] = lowPassFilter;
    draw_state[DRAW_STATE.HIGH_PASS_FILTER] = highPassFilter;
    draw_state[DRAW_STATE.IS_LOW_PASS_FILTER] = isLowPass?2:0;
    draw_state[DRAW_STATE.IS_HIGH_PASS_FILTER] = isHighPass?2:0;
  }
 
}


window.setThresholding = function(selectedChannel, isThresholding, averageSnapshotThresholding, valueThresholding){
  for (let c = 0; c < SERIAL_CHANNEL_COUNT_FIX; c++){
    let draw_state = new Int32Array(sabDraw.draw_states[c]);
    console.log('selectedChannel : ',c, selectedChannel, c == selectedChannel, valueThresholding, averageSnapshotThresholding, isThresholding);
    if (c == selectedChannel){
      draw_state[DRAW_STATE.VALUE_THRESHOLDING] = Math.floor(valueThresholding);
      draw_state[DRAW_STATE.AVERAGE_SNAPSHOT_THRESHOLDING] = Math.floor(averageSnapshotThresholding);
      draw_state[DRAW_STATE.IS_THRESHOLDING] = isThresholding;  
      draw_state[DRAW_STATE.SELECTED_CHANNEL_THRESHOLDING] = selectedChannel;  
    }else{
      draw_state[DRAW_STATE.VALUE_THRESHOLDING] = 0;
      draw_state[DRAW_STATE.AVERAGE_SNAPSHOT_THRESHOLDING] = 0;
      draw_state[DRAW_STATE.IS_THRESHOLDING] = 0;  
      draw_state[DRAW_STATE.SELECTED_CHANNEL_THRESHOLDING] = -1;  
    }
  }
 
}