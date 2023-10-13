var functions;
importScripts("require.js");
requirejs.config({
    baseUrl: "libraries",
    paths: {
        // functions:"library1"
        // functions:"library"
        functions:"libraries"
        // functions:"a"
    },
    waitSeconds: 20
});
requirejs(["functions"], (_functions) => {
    functions = _functions;
    console.log("functions");
    console.log(functions);
    // // console.log("Add (300,2) : ", _functions.myHyperSuperMegaFunction(300,2));
    // console.log("Multiplications (0.5 * 212) : ",functions.multiply(0.5,212));
});

let tempArray = new Int16Array(30000);

/* General */
let allSharedBuffers;
let deviceType = 'serial';
let deviceIds;
let sabDraw;
let drawState;
let drawStates;
const MAX_EVENT_MARKERS = 200;

/* Audio */
const MAX_FILE_SAMPLES = 1024;
const AUDIO_CHANNEL_MAX = 2;
let currentDataHead = 0;
let filePointerHeadInts;
// let filePointerHeadInt;
// let filePointerFileHeadInts;
// let fileContentDataInt;
// let fileContentTempDataInt;
// let sharedFileContainerInt;
// let sharedFileContainerResultInt;
let sharedFileContainerStatus;
let sharedFileContainerStatusInt;


/* Serial */
const SERIAL_CHANNEL_MAX = 6;
let simulateEvent = 0;

let eventsCounterInt;
let eventsInt;
let eventPositionInt;

let globalPositionCap;
let eventGlobalPositionInt;
let eventGlobalHeaderInt;
// let eventGlobalNumberInt;

let currentDataInt;
let currentTempInt;
let currentDataStartInt;
let currentDataEndInt;
let currentDataLengthInt;

let flagChannelDisplays;


let currentIdxEnd = 0 ;

let isStartRecording = false;
let isStartAudioRecording = false;

let isClearingBuffer = false;
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

 
};
// let currentData = new SharedArrayBuffer(1024 * 8 * CONFIG.bytesPerSample);
// let currentDataInt = new Int16Array(currentData);


const LOG_SCANNING_OF_ARDUINO = 1;
const BOARD_WITH_EVENT_INPUTS = 0;
const BOARD_WITH_ADDITIONAL_INPUTS = 1;
const BOARD_WITH_HAMMER = 4;
const BOARD_WITH_JOYSTICK = 5;
const BOARD_ERG = 9;
const MAX_NUMBER_OF_TIMEOUTS_ON_MAC = 10;
const LOW_BAUD_RATE = 222222;
const HIGH_BAUD_RATE = 500000;
let currentAddOnBoard = BOARD_WITH_ADDITIONAL_INPUTS;


let curChannel = 1;
const SIZE_OF_MESSAGES_BUFFER = 64;
const ESCAPE_SEQUENCE_LENGTH = 6;

let SharedBuffers;
let SharedBuffers2;
var _head = 0;
var _arrHeads = new SharedArrayBuffer( SERIAL_CHANNEL_MAX * Uint32Array.BYTES_PER_ELEMENT );
var _arrHeadsInt = new Uint32Array(_arrHeads);

var _arrIsFull = new SharedArrayBuffer( SERIAL_CHANNEL_MAX * Uint32Array.BYTES_PER_ELEMENT );
var _arrIsFullInt = new Uint32Array(_arrIsFull);

var _arrOffsetHead = new SharedArrayBuffer( SERIAL_CHANNEL_MAX * Uint32Array.BYTES_PER_ELEMENT );
var _arrOffsetHeadInt = new Uint32Array(_arrOffsetHead);

let vm = this;
var arrCounts;
var skipCounts;
var isFull = false;


const batchSizeForSerial = 600;
let numberOfChannels = 6;
let hasEscapeSequence = false;
let hasEndEscapeSequence = false;
let strEscapeSequence = '255-255-1-1-128-255';
let escapeSequence = new Uint8Array(6);
escapeSequence[0] = 255;
escapeSequence[1] = 255;
escapeSequence[2] = 1;
escapeSequence[3] = 1;
escapeSequence[4] = 128;
escapeSequence[5] = 255;

let strEndEscapeSequence = '255-255-1-1-129-255';
let endOfescapeSequence = new Uint8Array(6);
endOfescapeSequence[0] = 255;
endOfescapeSequence[1] = 255;
endOfescapeSequence[2] = 1;
endOfescapeSequence[3] = 1;
endOfescapeSequence[4] = 129;
endOfescapeSequence[5] = 255;


// Indices for the State SAB.
const STATE = {
  // Flag for Atomics.wait() and notify().
  'REQUEST_RENDER': 0,

  // Available frames in Input SAB.
  'IB_FRAMES_AVAILABLE': 1,

  // Read index of Input SAB.
  'IB_READ_INDEX': 2,

  // Write index of Input SAB.
  'IB_WRITE_INDEX': 3,

  // Available frames in Output SAB.
  'OB_FRAMES_AVAILABLE': 4,

  // Read index of Output SAB.
  'OB_READ_INDEX': 5,

  // Write index of Output SAB.
  'OB_WRITE_INDEX': 6,

  // Size of Input and Output SAB.
  'RING_BUFFER_LENGTH': 7,

  // Size of user-supplied processing callback.
  'KERNEL_LENGTH': 8,

  'REQUEST_SIGNAL_REFORM': 9,

  'REQUEST_WRITE_FILE': 10,
  
  'REQUEST_CLOSE_FILE': 11,
  
  //Audio Requirement
  'OPEN_FILE_REDRAW':12,

};

// const AUDIO_CONFIG = {
//   bytesPerState: Int32Array.BYTES_PER_ELEMENT,
//   bytesPerSample: Int16Array.BYTES_PER_ELEMENT,
//   stateBufferLength: 16,
//   ringBufferLength: 4096,
//   kernelLength: 1024,
//   channelCount: 1,
//   waitTimeOut: 25000,
// };


// Worker processor config.
const CONFIG = {
  bytesPerState: Int32Array.BYTES_PER_ELEMENT,
  bytesPerSample: Int16Array.BYTES_PER_ELEMENT,
  rawBytesPerSample: Uint8Array.BYTES_PER_ELEMENT,
  stateBufferLength: 32,
  ringBufferLength: 4096 * 2,
  kernelLength: 4096 / 4,
  channelCount: 1,
  waitTimeOut: 25000,
};

const writeFileCap = CONFIG.ringBufferLength/4;

// Shared states between this worker and AWP.
let States;
let StatesDraw;
let StatesWrite;
var MyConfigs = [];
var MyConfig;

// Shared RingBuffers between this worker and AWP.
let InputRingBuffer;
let OutputRingBuffer;


// PARSING DATA
let SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER = CONFIG.ringBufferLength;

let processedFrame = 0;
// let messagesBuffer = new Uint8Array(SIZE_OF_MESSAGES_BUFFER);
let circularBuffer = new Uint8Array(SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER);
let messagesBuffer = new Uint8Array(CONFIG.ringBufferLength);

let cBufHead = 0;
let cBufTail = 0;

let serialCounter = 0;

let escapeSequenceDetectorIndex = 0;
let weAreInsideEscapeSequence = false;
let messageBufferIndex =0;

_portOpened = true;

/* 
  Preparing the envelopes using Shared Array Buffer

*/
const SIZE_LOGS2 = 10;
const NUMBER_OF_SEGMENTS = 60;

let sabEnvelopes = [];
let sabEnvelopes1 = [];
let sabEnvelopes2 = [];
let sabEnvelopes3 = [];
let sabEnvelopes4 = [];
let sabEnvelopes5 = [];
let sabEnvelopes6 = [];

var envelopes = [];
var envelopes1 = [];
var envelopes2 = [];
var envelopes3 = [];
var envelopes4 = [];
var envelopes5 = [];
var envelopes6 = [];

var envelopeSizes = new Uint32Array(SIZE_LOGS2);
var allEnvelopes = [];
var allSabEnvelopes = [];



let SEGMENT_SIZE = 10000;
let SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;

let size = SIZE;

let allArrMax;
let allArrMaxInt;
// let arrMax = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
// let arrMaxInt = new Int16Array(arrMax);
let arrMax;
let arrMaxInt = new Int16Array(arrMax);

size/=2;
let i = 0;



function createSharedBuffers(idx, maxChannels){
  let map = {
    states:
        new SharedArrayBuffer(CONFIG.stateBufferLength * CONFIG.bytesPerState),
    inputRingBuffer:
        new SharedArrayBuffer(CONFIG.ringBufferLength *
                              CONFIG.bytesPerSample),
    outputRingBuffer:
        new SharedArrayBuffer(CONFIG.ringBufferLength *
                              CONFIG.bytesPerSample),
    statesDraw:
      new SharedArrayBuffer(CONFIG.stateBufferLength * CONFIG.bytesPerState),
    
    statesWrite:
      new SharedArrayBuffer(CONFIG.stateBufferLength * CONFIG.bytesPerState),

                      
  
    sabEnvelopes : allSabEnvelopes[idx],
    arrMax : allArrMax[idx],

    config : new SharedArrayBuffer(CONFIG.bytesPerState * 70),


    deviceId : new SharedArrayBuffer( 2 * Uint16Array.BYTES_PER_ELEMENT),
    maxSampleRate : new SharedArrayBuffer( 1 * Uint16Array.BYTES_PER_ELEMENT),
    minChannels : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT),
    maxChannels : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT),
    sampleRates : new SharedArrayBuffer( maxChannels * Uint16Array.BYTES_PER_ELEMENT),
    channels : new SharedArrayBuffer( maxChannels * Uint8Array.BYTES_PER_ELEMENT),

    // currentData : currentData,
    // currentDataChannel1 : currentDataChannel1,
    // eventGlobalNumber : new SharedArrayBuffer(MAX_EVENT_MARKERS * Uint8Array.BYTES_PER_ELEMENT),
    eventGlobalPosition : new SharedArrayBuffer(MAX_EVENT_MARKERS * Uint32Array.BYTES_PER_ELEMENT),
    eventGlobalHeader : new SharedArrayBuffer(1 * Uint32Array.BYTES_PER_ELEMENT),
    eventsIdx : new SharedArrayBuffer(MAX_EVENT_MARKERS * Uint8Array.BYTES_PER_ELEMENT),
    globalPositionCap : new SharedArrayBuffer(1 * Uint8Array.BYTES_PER_ELEMENT),

    filePointerHead : new SharedArrayBuffer(1 * Uint32Array.BYTES_PER_ELEMENT),
    // filePointerFileHead : new SharedArrayBuffer(maxChannels * Uint32Array.BYTES_PER_ELEMENT),
    // fileContentData : new SharedArrayBuffer(1024 * 2 * CONFIG.bytesPerSample),//bytesPerSample: Int16Array.BYTES_PER_ELEMENT,
    // fileContentTempData : new SharedArrayBuffer(1024 * 2 * CONFIG.bytesPerSample),//bytesPerSample: Int16Array.BYTES_PER_ELEMENT,
    currentData : new SharedArrayBuffer(CONFIG.ringBufferLength * Int16Array.BYTES_PER_ELEMENT),
    currentDataStart : new SharedArrayBuffer(1 * Uint8Array.BYTES_PER_ELEMENT),
    currentDataEnd : new SharedArrayBuffer(1 * Uint32Array.BYTES_PER_ELEMENT),
    currentDataLength : new SharedArrayBuffer(1 * Uint32Array.BYTES_PER_ELEMENT),
  };

  if ( idx == 0 ){
    sharedFileContainerStatus = new SharedArrayBuffer(20 * Int32Array.BYTES_PER_ELEMENT),
    sharedFileContainerStatusInt = new Int32Array(sharedFileContainerStatus);

    if (deviceType == 'audio'){

      _arrHeads = new SharedArrayBuffer( AUDIO_CHANNEL_MAX * Uint32Array.BYTES_PER_ELEMENT );
      _arrHeadsInt = new Uint32Array(_arrHeads);
      _arrIsFull = new SharedArrayBuffer( AUDIO_CHANNEL_MAX * Uint32Array.BYTES_PER_ELEMENT );
      _arrIsFullInt = new Uint32Array(_arrIsFull);      

    }else{
      _arrHeads = new SharedArrayBuffer( SERIAL_CHANNEL_MAX * Uint32Array.BYTES_PER_ELEMENT );
      _arrHeadsInt = new Uint32Array(_arrHeads);
      _arrIsFull = new SharedArrayBuffer( SERIAL_CHANNEL_MAX * Uint32Array.BYTES_PER_ELEMENT );
      _arrIsFullInt = new Uint32Array(_arrIsFull);      
      map['inputRingBuffer'] = new SharedArrayBuffer(CONFIG.ringBufferLength * 1 * CONFIG.rawBytesPerSample);
      map['outputRingBuffer'] = new SharedArrayBuffer(CONFIG.ringBufferLength * 1 * CONFIG.rawBytesPerSample);
    }
    
  }
  map['arrHeads'] =  _arrHeads;
  map['arrIsFull'] =  _arrIsFull;
  map['sharedFileContainerStatus'] =  sharedFileContainerStatus;

  map['arrOffsetHead'] =  _arrOffsetHead;
  // arrHeads : new SharedArrayBuffer(maxChannels * Uint32Array.BYTES_PER_ELEMENT),
  // arrIsFull : new SharedArrayBuffer(maxChannels * Uint32Array.BYTES_PER_ELEMENT),
  return map;
}

function envelopingSamples(_head, sample, _envelopes){
  for (j = 0; j < SIZE_LOGS2; j++){
    const skipCount = skipCounts[j];
    const envelopeSampleIndex = Math.floor( _head / skipCount );
    const interleavedSignalIdx = envelopeSampleIndex * 2; 
    if (_head % skipCount == 0){
      _envelopes[ j ] [interleavedSignalIdx] = sample; //20967 * 2  =40k
      _envelopes[ j ] [interleavedSignalIdx + 1] = sample;
    }else{
      if (sample < _envelopes[ j ] [interleavedSignalIdx]){
        _envelopes[ j ] [interleavedSignalIdx] = sample;
      }
      if (sample > _envelopes[ j ] [interleavedSignalIdx + 1]){
        _envelopes[ j ] [interleavedSignalIdx+1] = sample;
      }
    }
  }
}

function clearBuffer(){
  isClearingBuffer = true;
  console.log("clearBuffer()");
  let CHANNEL_COUNT_FIX = allSharedBuffers.length;  
  


  let c = 0;
  let arrMax;
  let envelopeSamples;
  for (;c < CHANNEL_COUNT_FIX ; c++){
    // const sabcs = this.sabcs[c];
    const sabcs = allSharedBuffers[c];
    const heads = new Uint32Array(sabcs.arrHeads);
    heads.fill(0);
  
    arrMax = new Int16Array(sabcs.arrMax);
    arrMax.fill(0);

    for (let l = 0 ; l < SIZE_LOGS2 ; l++){
      envelopeSamples = new Int16Array(sabcs.sabEnvelopes[l]);
      envelopeSamples.fill(0);
    }
  
  }
  Atomics.notify(StatesDraw, STATE.REQUEST_RENDER, 0);   
}

function executeOneMessage(typeOfMessage,valueOfMessage,offsetin) {

  // if(typeOfMessage == "HWT")
  // {
  //     hardwareType = valueOfMessage;

  //     let found=hardwareType.indexOf("PLANTSS");
  //     if (found>-1)
  //     {
  //         // setDeviceTypeToCurrentPort(ArduinoSerial::plant);
  //     }
  //     else
  //     {
  //         found=hardwareType.indexOf("MUSCLESS");
  //         if (found>-1)
  //         {
  //             // setDeviceTypeToCurrentPort(ArduinoSerial::muscle);
  //         }
  //         else
  //         {
  //             found=hardwareType.indexOf("HEARTSS");
  //             if (found>-1)
  //             {
  //                 // setDeviceTypeToCurrentPort(ArduinoSerial::heart);
  //             }
  //             else
  //             {
  //                 found=hardwareType.indexOf("HBLEOSB");//leonardo heart and brain with one channel only
  //                 if (found>-1)
  //                 {
  //                     // setDeviceTypeToCurrentPort(ArduinoSerial::heartOneChannel);
  //                 }
  //                 else
  //                 {
  //                     found=hardwareType.indexOf("HBSBPRO");//leonardo heart and brain with one channel only
  //                     if (found>-1)
  //                     {
  //                         // setDeviceTypeToCurrentPort(ArduinoSerial::heartPro);
  //                     }
  //                     else
  //                     {
  //                         //NEURONSS
  //                         found=hardwareType.indexOf("NEURONSS");//neuron SpikerBox one channel
  //                         if (found>-1)
  //                         {
  //                             // setDeviceTypeToCurrentPort(ArduinoSerial::neuronOneChannel);
  //                         }
  //                         else
  //                         {
  //                             found=hardwareType.indexOf("MUSCUSB1");
  //                             if (found>-1)
  //                             {
  //                                 // setDeviceTypeToCurrentPort(ArduinoSerial::muscleusb);
  //                             }
  //                             else
  //                             {
  //                                 found=hardwareType.indexOf("HUMANSB");
  //                                 if (found>-1)
  //                                 {
  //                                     // setDeviceTypeToCurrentPort(ArduinoSerial::humansb);
  //                                     // _manager->checkIfFirmwareIsAvailableForBootloader();
  //                                 }
  //                                 else
  //                                 {
  //                                     found=hardwareType.indexOf("HHIBOX");
  //                                     if (found>-1)
  //                                     {
  //                                         // setDeviceTypeToCurrentPort(ArduinoSerial::hhibox);
  //                                     }

  //                                 }

  //                             }
  //                         }
  //                     }
  //                 }
  //             }
  //         }
  //     }
  // }

  // if(!_justScanning)
  // if(true)
  // {
      if(typeOfMessage == "EVNT")
      {
        // try{
          const mkey = valueOfMessage.charCodeAt(0)-48;
          if (sabDraw){
  
              let ctr = drawState[DRAW_STATE.EVENT_COUNTER];
              eventsInt[ctr] = mkey;
              eventPositionInt[ctr] = _arrHeadsInt[0] + offsetin;

              eventGlobalPositionInt[ctr] = globalPositionCap[0] * SIZE + _arrHeadsInt[0];
              // eventsIdxInt[ctr] = drawState[DRAW_STATE.EVENT_NUMBER];
              eventsIdxInt[ctr] = mkey;


              ctr = (ctr + 1) % 200;
              eventsCounterInt[0] = ctr;
              drawState[DRAW_STATE.EVENT_NUMBER] = mkey;
              
              drawState[DRAW_STATE.EVENT_COUNTER] = ctr;    
              drawState[DRAW_STATE.EVENT_POSITION] = _arrHeadsInt[0] + offsetin;
              console.log("_arrHeadsInt[0] : ", _arrHeadsInt[0]);

    
            // drawState[DRAW_STATE.EVENT_FLAG] = 1;
            // drawState[DRAW_STATE.EVENT_NUMBER] = mkey;
          }

        // }catch(err){
        //   console.log("evnt error");
        // }
      }//EVNT
      else

      if(typeOfMessage == "BRD")
      {
          clearBuffer();
          // console.log("EXPANSION BOARDD!!!");
          // Log::msg("Change board type on serial");
          // int newAddOnBoard = (int)((unsigned int)valueOfMessage[0]-48);
          const newAddOnBoard = valueOfMessage.charCodeAt(0)-48;
          // const newAddOnBoard = parseInt(valueOfMessage[0]) - 1;
          console.log("EXPANSION BOARDD!!! ", newAddOnBoard);
          if (newAddOnBoard == 0){

            drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
            drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
            drawState[DRAW_STATE.MAX_CHANNELS] = (new Uint8Array(SharedBuffers.maxChannels) )[0];
  
                  // productId : new SharedArrayBuffer( 1 * Uint16Array.BYTES_PER_ELEMENT),
                  // maxSampleRate : new SharedArrayBuffer( 1 * Uint16Array.BYTES_PER_ELEMENT),
                  // minChannels : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT),
                  // maxChannels : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT),
                  // sampleRates : new SharedArrayBuffer( 6 * Uint16Array.BYTES_PER_ELEMENT),
                  // channels : new SharedArrayBuffer( 6 * Uint8Array.BYTES_PER_ELEMENT),
            currentAddOnBoard = 0;
          }else
          if(newAddOnBoard == BOARD_WITH_ADDITIONAL_INPUTS)
          {
              if(currentAddOnBoard != BOARD_WITH_ADDITIONAL_INPUTS)
              {
                if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
                  drawState[DRAW_STATE.CHANNEL_COUNTS] = 4;
                  drawState[DRAW_STATE.MAX_CHANNELS] =4;  
                  drawState[DRAW_STATE.EXTRA_CHANNELS] = 4;
                  // clearBuffer();
                }else{
                  drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
                  drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
                  // clearBuffer();

                }
                // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 4;

                currentAddOnBoard =newAddOnBoard;
                _shouldRestartDevice = true;

              }

          }
          else if(newAddOnBoard == BOARD_WITH_HAMMER)
          {
              if(currentAddOnBoard != BOARD_WITH_HAMMER)
              {
                console.log("HAMMER : ",drawState[DRAW_STATE.EXTRA_CHANNELS]);
                if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
                  // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
                  drawState[DRAW_STATE.CHANNEL_COUNTS] = 3;
                  drawState[DRAW_STATE.MAX_CHANNELS] = 3;
                  drawState[DRAW_STATE.EXTRA_CHANNELS] = 3;
                  // clearBuffer();
                }else{
                  drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
                  drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
                  // clearBuffer();

                }

                // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;
                currentAddOnBoard =newAddOnBoard;
                _shouldRestartDevice = true;
              }
          }
          else if(newAddOnBoard == BOARD_WITH_JOYSTICK)
          {
              if(currentAddOnBoard != BOARD_WITH_JOYSTICK)
              {
                if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){

                  // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
                  drawState[DRAW_STATE.CHANNEL_COUNTS] = 3;
                  drawState[DRAW_STATE.MAX_CHANNELS] = 3;
                  drawState[DRAW_STATE.EXTRA_CHANNELS] = 3;
                  // clearBuffer();
                }else{
                  drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
                  drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
                  // clearBuffer();
                }
                // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

                currentAddOnBoard =newAddOnBoard;
                _shouldRestartDevice = true;
              }
          }
          else if(newAddOnBoard == BOARD_WITH_EVENT_INPUTS)
          {
              if(currentAddOnBoard != BOARD_WITH_EVENT_INPUTS)
              {
                if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
                  // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
                  drawState[DRAW_STATE.CHANNEL_COUNTS] = 2;
                  drawState[DRAW_STATE.MAX_CHANNELS] = 2;
                  drawState[DRAW_STATE.EXTRA_CHANNELS] = 2;
                  // clearBuffer();
                }else{
                  drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
                  drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
                  // clearBuffer();
                }
                // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

                currentAddOnBoard =newAddOnBoard;
                _shouldRestartDevice = true;

              }
          }
          else if(newAddOnBoard == BOARD_ERG)
          {
              if(currentAddOnBoard != BOARD_ERG)
              {
                if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
                  // drawState[DRAW_STATE.SAMPLE_RATE] = 3000;
                  drawState[DRAW_STATE.CHANNEL_COUNTS] = 3;
                  drawState[DRAW_STATE.MAX_CHANNELS] = 3;
                  drawState[DRAW_STATE.EXTRA_CHANNELS] = 3;
                  // clearBuffer();
                }else{
                  drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
                  drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
                  // clearBuffer();
                }
                // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

                currentAddOnBoard =newAddOnBoard;
                _shouldRestartDevice = true;
              }
          }
          else
          {
              if(DRAW_STATE.CHANNEL_COUNTS != 2)
              {
                if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){

                  // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
                  drawState[DRAW_STATE.CHANNEL_COUNTS] = 2;
                  drawState[DRAW_STATE.MAX_CHANNELS] = 2;
                  drawState[DRAW_STATE.EXTRA_CHANNELS] = 2;
                  // clearBuffer();
                }else{
                  drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
                  drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
                  // clearBuffer();
                }
                // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

                currentAddOnBoard =newAddOnBoard;
                _shouldRestartDevice = true;
              }
          }
          drawState[DRAW_STATE.SAMPLE_RATE] = drawState[DRAW_STATE.SAMPLING_RATE_1 + ( drawState[DRAW_STATE.CHANNEL_COUNTS] - 1) ];
    
      }//BRD

  // }
}



function executeContentOfMessageBuffer(offset){
  let stillProcessing = true;
  let currentPositionInString = 0;
  let message = new Uint8Array(SIZE_OF_MESSAGES_BUFFER);
  // for(let i=0;i<SIZE_OF_MESSAGES_BUFFER;i++)
  // {
  //     message[i] = 0;
  // }
  let endOfMessage = 0;
  let startOfMessage = 0;



  while(stillProcessing)
  {
      if(messagesBuffer[currentPositionInString] == ';'.charCodeAt(0))
      {
          for(let k=0;k<endOfMessage-startOfMessage;k++)
          {
              if( message[k] == ':'.charCodeAt(0) )
              {

                  // std::string typeOfMessage(messa  ge, k);
                  // std::string valueOfMessage(message+k+1, (endOfMessage-startOfMessage)-k-1);
                  const str = String.fromCharCode(...message);
                  const arrStr = str.split(':');
                  const typeOfMessage = arrStr[0];
                  const valueOfMessage = arrStr[1];
                  const offsetMessage = offset;

                  executeOneMessage(typeOfMessage, valueOfMessage, offsetMessage);
                  break;
              }
          }
          startOfMessage = endOfMessage+1;
          currentPositionInString++;
          endOfMessage++;

      }
      else
      {
          message[currentPositionInString-startOfMessage] = messagesBuffer[currentPositionInString];
          currentPositionInString++;
          endOfMessage++;

      }

      if(currentPositionInString>=SIZE_OF_MESSAGES_BUFFER)
      {
          stillProcessing = false;
      }
  }

}
// FUNCTION REMOVAL
// function testEscapeSequence(newByte, offset){
//   if(weAreInsideEscapeSequence)
//   {

//       if(messageBufferIndex>=SIZE_OF_MESSAGES_BUFFER)
//       {
//           weAreInsideEscapeSequence = false; //end of escape sequence
//           executeContentOfMessageBuffer(offset);
//           escapeSequenceDetectorIndex = 0;//prepare for detecting begining of sequence
//       }
//       else if(endOfescapeSequence[escapeSequenceDetectorIndex] == newByte)
//       {
//           escapeSequenceDetectorIndex++;
//           if(escapeSequenceDetectorIndex ==  ESCAPE_SEQUENCE_LENGTH)
//           {
//               weAreInsideEscapeSequence = false; //end of escape sequence
//               executeContentOfMessageBuffer(offset);
//               escapeSequenceDetectorIndex = 0;//prepare for detecting begining of sequence
//           }
//       }
//       else
//       {
//           escapeSequenceDetectorIndex = 0;
//       }

//   }
//   else
//   {
//       if(escapeSequence[escapeSequenceDetectorIndex] == newByte)
//       {
//           escapeSequenceDetectorIndex++;
//           if(escapeSequenceDetectorIndex ==  ESCAPE_SEQUENCE_LENGTH)
//           {
//               weAreInsideEscapeSequence = true; //found escape sequence
//               for(let i=0;i<SIZE_OF_MESSAGES_BUFFER;i++)
//               {
//                   messagesBuffer[i] = 0;
//               }
//               messageBufferIndex = 0;//prepare for receiving message
//               escapeSequenceDetectorIndex = 0;//prepare for detecting end of esc. sequence

//               //rewind writing head and effectively delete escape sequence from data
//               for(let i=0;i<ESCAPE_SEQUENCE_LENGTH;i++)
//               {
//                   cBufHead--;
//                   if(cBufHead<0)
//                   {
//                       cBufHead = CONFIG.ringBufferLength-1;
//                   }
//               }
//           }
//       }
//       else
//       {
//           escapeSequenceDetectorIndex = 0;
//       }
//   }
// }



function frameHasAllBytes(_numberOfChannels){
  let tempTail = cBufTail + 1;
  if(tempTail>= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
  {
      tempTail = 0;
  }
  for(let i=0;i<(_numberOfChannels*2-1);i++)
  {
      let nextByte  = (circularBuffer[tempTail]) & 0xFF;
      if(nextByte > 127)
      {
          // Log::msg("HID frame with less bytes");
          return false;
      }
      tempTail++;
      if(tempTail>= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
      {
          tempTail = 0;
      }
  }
  return true;
}

function checkIfHaveWholeFrame()
{
    let tempTail = cBufTail + 1;
    if(tempTail>= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
    // if(tempTail>= CONFIG.ringBufferLength)
    {
        tempTail = 0;
    }
    while(tempTail!=cBufHead)
    {
        let nextByte  = (circularBuffer[tempTail]) & 0xFF;
        if(nextByte > 127)
        {
            return true;
        }
        tempTail++;
        if(tempTail>= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
        // if(tempTail>= CONFIG.ringBufferLength)
        {
            tempTail = 0;
        }
    }
    return false;
}

function areWeAtTheEndOfFrame()
{
  let tempTail = cBufTail + 1;
  if(tempTail>= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
  // if(tempTail>= CONFIG.ringBufferLength)
  {
      tempTail = 0;
  }
  // let nextByte  = ((uint)(circularBuffer[tempTail])) & 0xFF;
  let nextByte  = (circularBuffer[tempTail]) & 0xFF;
  if(nextByte > 127)
  {
      return true;
  }
  return false;
}
/**
 * Process data in the ring buffer with the user-supplied kernel.
 *
 * NOTE: This assumes that no one will modify the buffer content while it is
 * processed by this method.
 */
 function processSerialKernel() {
  cBufHead = 0;
  cBufTail = 0;
  // obufferIndex = 0;
  circularBuffer.fill(0);
  messageBufferIndex = 0;  
  weAreInsideEscapeSequence = false;
  
  let inputReadIndex = States[STATE.IB_READ_INDEX];
  let outputWriteIndex = States[STATE.OB_WRITE_INDEX];

  // console.log("READ : ", inputReadIndex);

  // if (isNaN(InputRingBuffer[0][inputReadIndex]))
  //   console.error('Found NaN at buffer index: %d', inputReadIndex);
  
  // console.log('Process Kernel');
  StatesWrite[STATE.IB_READ_INDEX] = inputReadIndex;
  let sample;
  // let i = 0;
  let j;
  
  
  let numberOfFrames = 0;
  let obufferIndex = 0;
  let writeInteger = 0;
  let g=0;
  // let enablePrint = false;
  let numberOfZeros = 0;
  let lastWasZero = 0;  

  

  const newDataLength = States[STATE.IB_FRAMES_AVAILABLE];
  // processedFrame = States[STATE.IB_FRAMES_AVAILABLE];
  if (newDataLength<=0) return;
  let buffer = new Uint8Array(newDataLength);
  
  // let d = (new Date()).getTime();
  // console.log( "1", d )
  // if (inputReadIndex + CONFIG.kernelLength <= CONFIG.ringBufferLength){
  if (inputReadIndex + newDataLength <= CONFIG.ringBufferLength){
    // buffer.set(InputRingBuffer[0].subarray(inputReadIndex, inputReadIndex + CONFIG.kernelLength));
    buffer.set(InputRingBuffer[0].subarray(inputReadIndex, inputReadIndex + newDataLength));
  }else{
    let firstPartData = InputRingBuffer[0].subarray(inputReadIndex);
    buffer.set(firstPartData,0);

    // |0|1|2|3|4|5|
    // |x|x|1|2|3|4|
    // |5|6|

    // MOZILLA DOC
    // const uint8 = new Uint8Array([10, 20, 30, 40, 50]);
    // console.log(uint8.subarray(1, 3));
    // expected output: Uint8Array [20, 30]
    
    // const uint8 = new Uint8Array(8);
    // uint8.set([1, 2, 3], 3);
    // expected output: Uint8Array [0, 0, 0, 1, 2, 3, 0, 0]
    

    const remainderLength = newDataLength - firstPartData.length;
    let secondPartData = InputRingBuffer[0].subarray(0,remainderLength);
    // if (secondPartData.length)
    buffer.set(secondPartData,firstPartData.length);
  }


  // console.log( "2", (new Date()).getTime() )
  // let i=0;
  // let bufferLength = CONFIG.kernelLength;
  let bufferLength = buffer.length;
  // if (deviceType == 'hid'){
  //   CONFIG.ringBufferLength = 4096;
  // }

  let loopBufferLength = bufferLength;
  
  // if (deviceType == "hid"){
  //   // loopBufferLength = buffer[1] & 0xFF;
    // console.log("loopBufferLength : ",loopBufferLength);
  //   loopBufferLength += 1;
  // }

  if (drawState){                   
    if (numberOfChannels != drawState[DRAW_STATE.CHANNEL_COUNTS]) {
      numberOfChannels = drawState[DRAW_STATE.CHANNEL_COUNTS];
    }
  }



  for( let i = 0; i < loopBufferLength ; i++)
  {
      if(weAreInsideEscapeSequence)
      {
          messagesBuffer[messageBufferIndex] = buffer[i];
          messageBufferIndex++;
      }
      else
      {
          circularBuffer[cBufHead++] = buffer[i];
           //uint debugMSB  = ((uint)(buffer[i])) & 0xFF;

          if(cBufHead>=SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
          // if(cBufHead>=CONFIG.ringBufferLength)
          {
              cBufHead = 0;
          }
      }

      if (deviceType == "serial"){
        if(buffer[i]==0)
        {
            if(lastWasZero==1)
            {
                numberOfZeros++;
            }
            lastWasZero = 1;
        }
        else
        {
            lastWasZero =0;
        }
        // simulateEvent++;
        // if (simulateEvent > 1000000 && simulateEvent < 10000000 ){
        //   simulateEvent = 10000000;
        //   console.log("ZEROES : ", "7", Math.floor( ((i-(numberOfZeros>0?numberOfZeros+1:0))/2)/numberOfChannels-1));
        //   executeOneMessage("EVNT","7",Math.floor( ((i-(numberOfZeros>0?numberOfZeros+1:0))/2)/numberOfChannels-1))
        // }
        let oBuffHead = {"value":cBufHead};
        functions.testEscapeSequence( buffer[i] & 0xFF,  Math.floor( ((i-(numberOfZeros>0?numberOfZeros+1:0))/2)/numberOfChannels-1),messagesBuffer,weAreInsideEscapeSequence, messageBufferIndex,escapeSequenceDetectorIndex,oBuffHead);
        // const calc = Math.floor( ((i-(numberOfZeros>0?numberOfZeros+1:0))/2)/numberOfChannels-1);
        // testEscapeSequence( buffer[i] & 0xFF,  calc);
        cBufHead = oBuffHead.value;
      }else{
        let oBuffHead = {"value":cBufHead};
        functions.testEscapeSequence( buffer[i] & 0xFF,  Math.floor( ( (i) / 2 ) / numberOfChannels-1 ),messagesBuffer,weAreInsideEscapeSequence, messageBufferIndex,escapeSequenceDetectorIndex,oBuffHead);
        // testEscapeSequence( buffer[i] ,  Math.floor( ( (i) / 2 ) / numberOfChannels-1 ));
        cBufHead = oBuffHead.value;
      }

      //  testEscapeSequence(((unsigned int) buffer[i]) & 0xFF,  ((i-(numberOfZeros>0?numberOfZeros+1:0))/2)/_numberOfChannels-1);
  }
  const writeFrame = messageBufferIndex * Uint8Array.BYTES_PER_ELEMENT;
  processedFrame = writeFrame ;
  outputWriteIndex = ( outputWriteIndex + writeFrame ) % CONFIG.ringBufferLength;
  inputReadIndex = ( inputReadIndex + writeFrame ) % CONFIG.ringBufferLength;
  // console.log(writeFrame);

  States[STATE.IB_READ_INDEX] = inputReadIndex;
  States[STATE.OB_WRITE_INDEX] = outputWriteIndex;

  if(size==-1)
  {
      return -1;
  }

  // console.log( "3", (new Date()).getTime() )

  let LSB;
  let MSB;
  let haveData = true;
  let weAlreadyProcessedBeginingOfTheFrame;
  let numberOfParsedChannels;
  
  let arr = [];
  let initialHeads = [];
  // console.log("LOG J, I :",j,i);
  for (j=0;j<SERIAL_CHANNEL_MAX;j++){
    initialHeads[j] =_arrHeadsInt[j];
  }

  // numberOfChannels = (new Uint8Array(SharedBuffers.minChannels) )[0];
  // console.log("numberOfChannels ",numberOfChannels);
  if (deviceType =='hid'){
    if (drawState){                   
      // if (numberOfChannels < drawState[DRAW_STATE.CHANNEL_COUNTS]) {
        numberOfChannels = drawState[DRAW_STATE.CHANNEL_COUNTS];
      // }
    }

  }

  // for (i=0; i < CONFIG.kernelLength; i++){
  // let tempCurrentData = new Int16Array(CONFIG.ringBufferLength);
  while (haveData){
    
    MSB = (circularBuffer[cBufTail]) & 0xFF;
    let additionalFlag = true;
    // if (deviceType == 'hid'){
    //   additionalFlag = frameHasAllBytes(numberOfChannels);
    // }
    // console.log("ADDITIONAL FLAG : ", additionalFlag);
    if(MSB > 127 && additionalFlag )//if we are at the begining of frame
    {
        weAlreadyProcessedBeginingOfTheFrame = false;
        numberOfParsedChannels = 0;
        // _arrHeadsInt.fill(0);
        if(functions.checkIfHaveWholeFrame(circularBuffer,cBufTail,cBufHead))
        // if(checkIfHaveWholeFrame())
        {
            numberOfFrames++;
            let idxChannelLoop = 0;
            while (1) 
            {
              
              //HID
              // idxChannelLoop++;


                if (deviceType != "hid"){
                  // console.log("SERIAL ? ",deviceType);
                  MSB  = (circularBuffer[cBufTail]) & 0xFF;
                  if(weAlreadyProcessedBeginingOfTheFrame && MSB>127)
                  {
                      numberOfFrames--;
                      //std::cout<< "Incomplete frame 1 \n";
                      // console.log("prcess begining");
                      break;//continue as if we have new frame
                  }  
                }

                MSB  = (circularBuffer[cBufTail]) & 0x7F;
                weAlreadyProcessedBeginingOfTheFrame = true;

                cBufTail++;
                if(cBufTail>=CONFIG.ringBufferLength)
                {
                    cBufTail = 0;
                }
                LSB  = (circularBuffer[cBufTail]) & 0xFF;
                //if we have error in frame (lost data)
                if(LSB>127)
                {
                    numberOfFrames--;
                    // obufferIndex++;
                    // if (obufferIndex>10){
                    //   obufferIndex=0;
                    // }

                    // std::cout<< "Incomplete frame 2 \n";
                    console.log("!!!! PROCESS LSB", cBufTail, circularBuffer[cBufTail], circularBuffer[cBufTail - 1 ]);
                    console.log("!!!! MSB",  circularBuffer[cBufTail - 1 ] & 0xFF, circularBuffer[cBufTail - 1 ] & 0x7F);
                    console.log("!!!! LSB",  circularBuffer[cBufTail ] & 0xFF, circularBuffer[cBufTail - 1 ] & 0x7F);
                    if (deviceType == 'hid'){

                      return;
                    }else{
                      break;
                    }
                    // break;//continue as if we have new frame
                }
                // std::cout<< cBufTail<<" -L "<<LSB<<"\n";
                LSB  = (circularBuffer[cBufTail]) & 0x7F;

                MSB = MSB<<7;
                writeInteger = LSB | MSB;
                // writeInteger = functions.multiplicationz(5,writeInteger);
                // arr.push(writeInteger);

                numberOfParsedChannels++;
                if (drawState){                   
                  if (numberOfChannels != drawState[DRAW_STATE.CHANNEL_COUNTS]) {
                    numberOfChannels = drawState[DRAW_STATE.CHANNEL_COUNTS];
                  }
                }

                if (deviceType =='hid'){
              
                  if (numberOfParsedChannels> numberOfChannels){
                    console.log("num parsed channel", numberOfParsedChannels, numberOfChannels);
                    break;
                  }
                }else
                if(numberOfParsedChannels> numberOfChannels)
                {
                    //std::cout<< "More channels than expected\n";
                    // break;//continue as if we have new frame
                    // return;//continue as if we have new frame
                }

                if (deviceType == 'hid'){
                  sample =  (-(writeInteger-512));
                }else{
                  if (deviceIds[0] == 4){
                    sample =  (-(writeInteger - 8192)); // SpikeDesktop 448
                  }else{
                    sample =  (-(writeInteger - 512)); // SpikeDesktop 448
                  }

                }

                if (MyConfig[2] != -1){
                  if (numberOfParsedChannels == 1 && !isStartRecording){
                    isStartRecording = true
                    console.log("Start Recording : ", -sample, currentIdxEnd, numberOfParsedChannels);
                  }
                  if (isStartRecording){
                    if (flagChannelDisplays[numberOfParsedChannels-1] == 1){
                      currentTempInt[currentIdxEnd++] = -sample;
                    }else{
                    }
                  }
                }else{
                  isStartRecording = false;                  
                }

                arrMaxInt = allArrMaxInt[numberOfParsedChannels - 1];
                envelopes = allEnvelopes[numberOfParsedChannels - 1];
                _head = _arrHeadsInt[numberOfParsedChannels - 1];
                try{
                  // envelopingSamples(_head, sample, envelopes);                  
                  // functions.enveloping(_head, sample, envelopes, SIZE_LOGS2, skipCounts);                  
                  functions.envelopingSamples(_head, sample, envelopes, SIZE_LOGS2, skipCounts);                  
                }catch(err){
                  //err undefined 512 undefined
                  // error when changing from audio long time to serial
                  // 7 undefined -4352 undefined
                  console.log("err : ",err, numberOfParsedChannels, _head, sample, envelopes);
                  break;
                }
                // for (j = 0; j < SIZE_LOGS2; j++){
                //   const skipCount = skipCounts[j];
                //   const envelopeSampleIndex = Math.floor( _head / skipCount );
                //   const interleavedSignalIdx = envelopeSampleIndex * 2; 

                //   if (_head % skipCount == 0){
                //     envelopes[ j ] [interleavedSignalIdx] = sample; //20967 * 2  =40k
                //     envelopes[ j ] [interleavedSignalIdx + 1] = sample;
                //   }else{
                //     if (sample < envelopes[ j ] [interleavedSignalIdx]){
                //         envelopes[ j ] [interleavedSignalIdx] = sample;
                //     }
                //     if (sample > envelopes[ j ] [interleavedSignalIdx + 1]){
                //         envelopes[ j ] [interleavedSignalIdx+1] = sample;
                //     }
                //   }
                // }  

                const interleavedHeadSignalIdx = _head * 2;
                arrMaxInt[interleavedHeadSignalIdx] = sample;
                arrMaxInt[interleavedHeadSignalIdx + 1] = sample;

                _head++;
                if (_head == SIZE){
                  _head = 0;        
                  _arrIsFullInt[numberOfParsedChannels-1]++;
                  if (numberOfParsedChannels == 1) {
                    globalPositionCap[0]++;
                  }
            
                  isFull = true;
                }     

                _arrHeadsInt[numberOfParsedChannels-1] = _head;
                if (numberOfParsedChannels == 1){
                  if (drawState){
                    if (drawState[DRAW_STATE.EVENT_FLAG] == 1){
                      drawState[DRAW_STATE.EVENT_POSITION] = _arrHeadsInt[0];

                      let ctr = drawState[DRAW_STATE.EVENT_COUNTER];
                      eventsInt[ctr] = drawState[DRAW_STATE.EVENT_NUMBER];
                      eventPositionInt[ctr] = _arrHeadsInt[0];
                      eventGlobalPositionInt[ctr] = globalPositionCap[0] * SIZE + _head;            
                      eventsIdxInt[ctr] = drawState[DRAW_STATE.EVENT_NUMBER];
                      ctr++;
                      if ( ctr >= MAX_EVENT_MARKERS){
                        ctr=ctr % MAX_EVENT_MARKERS;
                        eventsCounterInt.fill(0);
                        eventsInt.fill(0);
                        eventPositionInt.fill(0);
                        eventsPositionResultInt.fill(0);        
                      }
                      eventsCounterInt[0]=ctr;


                      drawState[DRAW_STATE.EVENT_COUNTER] = ctr;                  
                      console.log("eventsCounter : ", ctr, "head : ", _head);
                      console.log("Position : ", eventPositionInt);
                      console.log("Result : ", eventPositionResultInt);
            
                      drawState[DRAW_STATE.EVENT_FLAG] = 0;
                    }
                  }
                }

                if(functions.areWeAtTheEndOfFrame(circularBuffer,cBufTail))
                // if(areWeAtTheEndOfFrame())
                {
                    break;
                }
                else
                {
                  cBufTail++;
                  if(cBufTail>=SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
                  {
                      cBufTail = 0;
                  }
                }
            }
        }
        else
        {
            haveData = false;
            // console.log("have data false");
            break;
        }
    }
    if(!haveData)
    {
        break;
    }    
    cBufTail++;   
    if(cBufTail>=SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER){
        cBufTail = 0;
    }
    if(cBufTail==cBufHead){
      haveData = false;
      break;
    }

  }
  
  // !!! this is because of each sample need 2 bytes, and need to be multiplied per channels
  if (sabDraw){
    curChannel = drawState[DRAW_STATE.CHANNEL_COUNTS];
    if (drawState[DRAW_STATE.CHANNEL_COUNTS] < drawState[DRAW_STATE.MIN_CHANNELS]){
      curChannel = drawState[DRAW_STATE.MIN_CHANNELS];
    }
    flagChannelDisplays = new Uint32Array(sabDraw.channelDisplays);
  }

  let readFrame = 0;
  if (deviceType != 'hid'){
    readFrame = numberOfFrames * 2 * curChannel;
  }else{
    if (curChannel <2){
      readFrame = numberOfFrames * 2 * 2;
    }else{
      readFrame = numberOfFrames * 2 * curChannel;
    }

  }
  currentDataLengthInt[0] = currentIdxEnd;
  currentDataStartInt[0] = 0;
  currentDataEndInt[0] = currentIdxEnd;

  if (MyConfig[2] != -1){
    if (isStartRecording && currentIdxEnd > writeFileCap){
      currentDataInt.set(currentTempInt.slice(0, currentIdxEnd));
      if (currentIdxEnd > 0){
        currentIdxEnd = 0;
        Atomics.notify(StatesWrite, STATE.REQUEST_WRITE_FILE, 1);  
        Atomics.notify(sharedFileContainerStatusInt, 9, 1);   
      }
    }

  }

  // console.log("new DATA LENGTH : ", inputReadIndex, newDataLength, processedFrame, (new Date()).getTime() );
  
  outputWriteIndex = ( outputWriteIndex + readFrame ) % CONFIG.ringBufferLength;
  inputReadIndex = ( inputReadIndex + readFrame ) % CONFIG.ringBufferLength;

  processedFrame += readFrame;

  States[STATE.IB_READ_INDEX] = inputReadIndex;
  States[STATE.OB_WRITE_INDEX] = outputWriteIndex;

  StatesWrite[STATE.IB_WRITE_INDEX] = inputReadIndex;
  // console.log("new DATA LENGTH2 : ", inputReadIndex, newDataLength, processedFrame, (new Date()).getTime() );



  // console.log("BUFFER REQUEST DRAW", (new Date()).getTime() );
  Atomics.notify(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 1);
  eventGlobalHeaderInt[0] = globalPositionCap[0] * SIZE + _head;
  

  MyConfig[0] = _head;
  MyConfig[1] = isFull? 1:0;


  // console.log("time",(new Date()).getTime()-d);
}

/**
 * Waits for the signal delivered via |States| SAB. When signaled, process
 * the audio data to fill up |outputRingBuffer|.
 */
function waitOnRenderSerialRequest() {
  // As long as |REQUEST_RENDER| is zero, keep waiting. (sleep)
  try{
    while (Atomics.wait(States, STATE.REQUEST_RENDER, 0) === 'ok') {
      processSerialKernel();
      // Update the number of available frames in the buffer.
      // States[STATE.IB_FRAMES_AVAILABLE] -= CONFIG.kernelLength;
      // States[STATE.OB_FRAMES_AVAILABLE] += CONFIG.kernelLength;
      States[STATE.IB_FRAMES_AVAILABLE] -= processedFrame;
      States[STATE.OB_FRAMES_AVAILABLE] += processedFrame;

      // Reset the request render bit, and wait again.
      Atomics.store(States, STATE.REQUEST_RENDER, 0);

      
    }
  }catch(err){
    console.log("error wait onrenderrequest : ",err);
  }
}

/**
 * Initialize the worker; allocates SAB, sets up TypedArrayViews, primes
 * |States| buffer and notify the main thread.
 *
 * @param {object} options User-supplied options.
 */
function initializeSerial(options) {
  if (options.deviceType) {
    deviceType = options.deviceType;
    if (options.deviceType == 'hid'){
      CONFIG.ringBufferLength = 4154 * 2;
      CONFIG.kernelLength = 992 * 2;
      SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER = CONFIG.ringBufferLength * 8;
      // numberOfChannels = 2;
    }
  }
  if (options.sabDraw){
    sabDraw = options.sabDraw;
    drawState = new Int32Array(sabDraw.draw_states[0]);
    curChannel = drawState[DRAW_STATE.CHANNEL_COUNTS];

    eventsCounterInt = new Uint8Array(sabDraw.eventsCounter);
    eventsInt = new Uint8Array(sabDraw.events);
    eventPositionInt = new Uint32Array(sabDraw.eventPosition);
    eventPositionResultInt = new Float32Array(sabDraw.eventPositionResult);
    
  }


  if (options.ringBufferLength) {
    CONFIG.ringBufferLength = options.ringBufferLength;
  }

  if (options.channelCount) {
    CONFIG.channelCount = options.channelCount;
  }

  if (!self.SharedArrayBuffer) {
    postMessage({
      message: 'WORKER_ERROR',
      detail: `SharedArrayBuffer is not supported in your browser. See
          https://developers.google.com/web/updates/2018/06/audio-worklet-design-pattern
          for more info.`,
    });
    return;
  }

  // Allocate SABs.
  // for (let i = 0 ; i < CONFIG.channelCount ; i++){
  //   _bufferChannels.push(new SharedArrayBuffer(CONFIG.ringBufferLength * 1));
  // }
  

  SharedBuffers = createSharedBuffers(0, SERIAL_CHANNEL_MAX);
  allSharedBuffers = [SharedBuffers];
  for (let i = 1 ; i < SERIAL_CHANNEL_MAX ; i++){
    // let sabEnvelope = allSabEnvelopes[i];
    // let arrayMax = allArrMax[i];
    allSharedBuffers.push(createSharedBuffers(i,SERIAL_CHANNEL_MAX));

  }

  deviceIds = new Uint16Array(SharedBuffers.deviceId);

  eventGlobalPositionInt = new Uint32Array(SharedBuffers.eventGlobalPosition);
  eventGlobalHeaderInt = new Uint32Array(SharedBuffers.eventGlobalHeader);
  eventsIdxInt = new Uint8Array(SharedBuffers.eventsIdx);
  globalPositionCap = new Uint8Array(SharedBuffers.globalPositionCap);

  currentDataInt = new Int16Array(SharedBuffers.currentData);
  currentTempInt = new Int16Array(currentDataInt.length);
  currentDataStartInt = new Uint8Array(SharedBuffers.currentDataStart);
  currentDataEndInt = new Uint32Array(SharedBuffers.currentDataEnd);
  currentDataLengthInt = new Uint32Array(SharedBuffers.currentDataLength);

  // Get TypedArrayView from SAB.
  States = new Int32Array(SharedBuffers.states);
  InputRingBuffer = [new Uint8Array(SharedBuffers.inputRingBuffer)];
  OutputRingBuffer = [new Uint8Array(SharedBuffers.outputRingBuffer)];

  StatesDraw = new Int32Array(SharedBuffers.statesDraw);
  StatesWrite = new Int32Array(SharedBuffers.statesWrite);
  MyConfig = new Int32Array(SharedBuffers.config);

  MyConfig[2]=-1;


  // Initialize |States| buffer.
  Atomics.store(States, STATE.RING_BUFFER_LENGTH, CONFIG.ringBufferLength);
  Atomics.store(States, STATE.KERNEL_LENGTH, CONFIG.kernelLength);

  // Notify AWN in the main scope that the worker is ready.
  postMessage({
    message: 'WORKER_READY',
    SharedBuffers: SharedBuffers,
    allSharedBuffers : allSharedBuffers,
  });

  // Start waiting.
  while (true){
    waitOnRenderSerialRequest();

  }
}



/**
 * Process audio data in the ring buffer with the user-supplied kernel.
 *
 * NOTE: This assumes that no one will modify the buffer content while it is
 * processed by this method.
 */
function processAudioKernel(availableFrames) {

  // if (isNaN(InputRingBuffer[0][inputReadIndex]))
  //   console.error('Found NaN at buffer index: %d', inputReadIndex);
  
  // A stupid processing kernel that clones audio data sample-by-sample. Also
  // note here we are handling only the first channel.
  let sample;
  let inputReadIndex;
  let outputWriteIndex;
  let MyConfig;
  StatesWrite[STATE.IB_READ_INDEX] = States[0][STATE.IB_READ_INDEX];
  let flagChannelDisplays = new Uint32Array(sabDraw.channelDisplays);
  const sum = flagChannelDisplays.reduce((pre,curr)=>pre+curr,0);
  for (let c = 0 ;c < AUDIO_CHANNEL_MAX; c++){
    // console.log("States c ", States[c], STATE.IB_READ_INDEX);
    inputReadIndex = States[c][STATE.IB_READ_INDEX];
    outputWriteIndex = States[c][STATE.OB_WRITE_INDEX];
  
    MyConfig = MyConfigs[c];
    // _head = MyConfig[0];
    // const arrHeadsInt = new Uint32Array(allSharedBuffers[c].arrHeads);
    const arrHeadsInt = _arrHeadsInt;
    const channelIdx = c;
    let _envelopes = allEnvelopes[c];
    let _arrMaxInt = allArrMaxInt[c];

    _head = arrHeadsInt[c];
    // if (c == 0)
      // console.log("channel|sample start", c, _head, States[c][STATE.IB_FRAMES_AVAILABLE]);
    // offsetHead = MyConfig[7];
    offsetHead = _arrOffsetHeadInt[c];
    let filePointerHeadInt = filePointerHeadInts[c];
    // let fileContentTempDataContainer = fileContentTempDataInt[c];
    // if (c == 1){
    //   console.log("test ");
    // }
  
    let i = 0;
    let j;
    // console.log("InputRingBuffer[c] : ", InputRingBuffer[0]);
    const prevDate = new Date();
    // for (; i < CONFIG.kernelLength; ++i) {
    for (; i < availableFrames; ++i) {
      sample = InputRingBuffer[c][inputReadIndex];
      try{
        functions.enveloping(_head, sample, _envelopes, SIZE_LOGS2, skipCounts);
        // functions.envelopingSamples(_head, sample, _envelopes, SIZE_LOGS2, skipCounts);
        // envelopingSamples(_head, sample, _envelopes);

        // if (_head % 51200 == 0){
        //   const tempLevel = 9;
        //   let envelopeIdx = Math.floor(_head / skipCounts[tempLevel]);
        //   if (tempArray[envelopeIdx] === 0){
        //     tempArray[envelopeIdx] = _envelopes[tempLevel][envelopeIdx];
        //     // console.log("tempArray[envelopeIdx] : ", envelopeIdx, _envelopes[tempLevel][envelopeIdx]);
        //     // console.log("tempArray[envelopeIdx] : ", _envelopes[tempLevel][envelopeIdx]);
        //     // console.log(tempArray);
        //   }
        // }
      }catch(err){
        // console.log("err");
        // console.log(err);
        // let arrSize = [];
        // let arrError = [];
        // for (j = 0; j< skipCounts.length;j++){
        //   arrError.push(_head/skipCounts[j]);
        //   arrSize.push(_envelopes[j].length);
        // }
        // console.log(_head, envelopeSizes, arrSize, SIZE_LOGS2," ARR ERROR : ",arrError);
      //   // 2645992 Uint32Array(10) [661500, 330750, 165375, 82687, 41343, 20671, 10335, 5167, 2583, 1291, buffer: ArrayBuffer(40), byteLength: 40, byteOffset: 0, length: 10, Symbol(Symbol.toStringTag): 'Uint32Array'] 10 
      //   // Uint32Array(10) [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, buffer: ArrayBuffer(40), byteLength: 40, byteOffset: 0, length: 10, Symbol(Symbol.toStringTag): 'Uint32Array']        
      }
      
  
      const interleavedHeadSignalIdx = _head * 2;
      _arrMaxInt[interleavedHeadSignalIdx] = sample;
      _arrMaxInt[interleavedHeadSignalIdx + 1] = sample;
  
      _head++;
      offsetHead++;
      if (_head == SIZE){
        _head = 0;     
        isFull = true;
        if (channelIdx == 0) {
          globalPositionCap[0]++;
        }
        _arrIsFullInt[channelIdx]++;
      }
  
      if (channelIdx == 0){
        if (drawState){
          if (drawState[DRAW_STATE.EVENT_FLAG] == 1){
            drawState[DRAW_STATE.EVENT_POSITION] = _head;
  
            let ctr = drawState[DRAW_STATE.EVENT_COUNTER];
            eventsInt[ctr] = drawState[DRAW_STATE.EVENT_NUMBER];
            eventPositionInt[ctr] = _head;
            
            eventGlobalPositionInt[ctr] = globalPositionCap[0] * SIZE + _head;
            eventsIdxInt[ctr] = drawState[DRAW_STATE.EVENT_NUMBER];
            ctr++;
            if ( ctr >= MAX_EVENT_MARKERS){
              ctr=ctr % MAX_EVENT_MARKERS;
              eventsCounterInt.fill(0);
              eventsInt.fill(0);
              eventPositionInt.fill(0);
              eventPositionResultInt.fill(0);        
            }
            eventsCounterInt[0]=ctr;
  
            drawState[DRAW_STATE.EVENT_COUNTER] = ctr;
            drawState[DRAW_STATE.EVENT_FLAG] = 0;
            
          }
  
        }
      }

      // if (MyConfigs[c][2] != -1)
      //   console.log("MyConfig : ",c, configIdx, MyConfig);

      if (MyConfigs[0][2] != -1){
        let configIdx = 0;
        if (sum == 1 && flagChannelDisplays[1] == 1){
          configIdx = 1;
        }
  
        try{
          if (channelIdx == configIdx ){
            currentTempInt[sum * filePointerHeadInt[0]] = sample;
          }else{
            currentTempInt[sum * filePointerHeadInt[0]+1] = sample;
          }
    
        }catch(err){
          console.log("Shared file container : ",err);
        }
        // fileContentTempDataContainer[filePointerHeadInt[0]] = sample;
        filePointerHeadInt[0]++;  
        sharedFileContainerStatusInt[channelIdx] = filePointerHeadInt[0];
  
      }
  
      
  
      if (++outputWriteIndex === CONFIG.ringBufferLength)
        outputWriteIndex = 0;
      if (++inputReadIndex === CONFIG.ringBufferLength)
        inputReadIndex = 0;
    }
    // console.log("channel|sample end", c, _head, States[c][STATE.IB_FRAMES_AVAILABLE]);

    console.log( "enveloping speed channel : ", (new Date()) - prevDate, availableFrames, _head, c );

    // if (c == 1){
    //   console.log("_envelopes : ", _head, offsetHead, _arrMaxInt[_head]);
    // }
    MyConfig[5] = 0;
    MyConfig[7] = offsetHead;
    const skipCount = skipCounts[7];
    const envelopeSampleIndex = Math.floor( _head / skipCount );
    const interleavedSignalIdx = envelopeSampleIndex * 2; 

    // console.log("Envelopes 7 : ", skipCounts, _envelopes[7] , _head);
    // console.log("ArrHeads int : ", _arrHeadsInt[c] , _head);
    _arrHeadsInt[c] = _head;
    _arrOffsetHeadInt[c] = offsetHead;
    // _arrIsFullInt[c] = Math.floor(_arrHeadsInt[c] / SIZE);

    MyConfig[0] = _head;
    arrHeadsInt[c] = _head;

    
    MyConfig[1] = isFull? globalPositionCap[0]:0;
    MyConfig[3] = currentDataHead;
    if (MyConfig[2] != -1){
      MyConfig[4]++;
    }
    States[c][STATE.IB_READ_INDEX] = inputReadIndex;
    States[c][STATE.OB_WRITE_INDEX] = outputWriteIndex;
  
    StatesWrite[STATE.IB_WRITE_INDEX] = inputReadIndex;

    /*
    if (States[c][STATE.OPEN_FILE_REDRAW] == 0){
      Atomics.notify(StatesDraw[c], STATE.REQUEST_SIGNAL_REFORM, 1);
    }else{
    }
    */
   
    //START OF RECORDING
    eventGlobalHeaderInt[0] = globalPositionCap[0] * SIZE + _head;
  
    if (MyConfigs[0][2] != -1){
      let configIdx = 0;
      if (sum == 1 && flagChannelDisplays[1] == 1){
        configIdx = 1;
      }
  
      if (filePointerHeadInts[configIdx][0] >= MAX_FILE_SAMPLES){
        const temp1 = filePointerHeadInts[0][0];
        const temp2 = filePointerHeadInts[1][0];
        let total = temp1;

        if (sum > 1){
          total = temp1 + temp2;
        }


        
        currentDataInt.set(currentTempInt.slice(0,total));
        currentTempInt.fill(0);
        filePointerHeadInts[0][0] = 0;
        filePointerHeadInts[1][0] = 0;

        currentDataStartInt[0] = 0;  
        currentDataEndInt[0] = total;
        currentDataLengthInt[0] = total;
        // console.log("total : ",total);

        if (sum==2 && temp1==temp2){
          const channelsTotal = sharedFileContainerStatusInt[0] + sharedFileContainerStatusInt[1];
          // console.log("sum : ", channelsTotal);
          if (channelsTotal > 0){
            Atomics.notify(sharedFileContainerStatusInt, 9, 1);   
          }
        }
        if (configIdx == c && sum == 1 & total > 0){
              // console.log("sum : ", total);
            // console.log("CONFIG IDX : ", configIdx, c, MyConfigs[configIdx][2]);
            // console.log("STATES WRITE ", StatesWrite);
            Atomics.notify(StatesWrite, STATE.REQUEST_WRITE_FILE, 1);
          // console.log("REQUEST_WRITE_FILE");
        }
        
      }
    }
  }

  for (let c = 0; c < AUDIO_CHANNEL_MAX ; c++){
    if (States[c][STATE.OPEN_FILE_REDRAW] == 0){
      Atomics.notify(StatesDraw[c], STATE.REQUEST_SIGNAL_REFORM, 1);
    }else{
    }
  }
}

/**
 * Waits for the signal delivered via |States| SAB. When signaled, process
 * the audio data to fill up |outputRingBuffer|.
 */
function waitOnRenderAudioRequest() {
  // As long as |REQUEST_RENDER| is zero, keep waiting. (sleep)
  const availableFrames = CONFIG.kernelLength;
  while (Atomics.wait(States[0], STATE.REQUEST_RENDER, 0) === 'ok') {
    // const availableFrames = States[0][STATE.IB_FRAMES_AVAILABLE];
    // console.log("States[0][STATE.IB_FRAMES_AVAILABLE] : ", States[0][STATE.IB_FRAMES_AVAILABLE]);
    processAudioKernel(availableFrames);

    // Update the number of available frames in the buffer.
    States[0][STATE.IB_FRAMES_AVAILABLE] -= availableFrames;
    // console.log("available frames ", availableFrames, States[0][STATE.IB_FRAMES_AVAILABLE], States[0][STATE.IB_FRAMES_AVAILABLE] - availableFrames);
    // States[0][STATE.OB_FRAMES_AVAILABLE] += CONFIG.kernelLength;

    States[1][STATE.IB_FRAMES_AVAILABLE] -= availableFrames;
    // States[1][STATE.OB_FRAMES_AVAILABLE] += CONFIG.kernelLength;

    // Reset the request render bit, and wait again.
    Atomics.store(States[0], STATE.REQUEST_RENDER, 0);


    // Reset the request render bit, and wait again.
    Atomics.store(States[1], STATE.REQUEST_RENDER, 0);

  }
}

/**
 * Initialize the worker; allocates SAB, sets up TypedArrayViews, primes
 * |States| buffer and notify the main thread.
 *
 * @param {object} options User-supplied options.
 */
function initializeAudio(options) {
  if (options.ringBufferLength) {
    CONFIG.ringBufferLength = options.ringBufferLength;
  }
  if (options.channelCount) {
    CONFIG.channelCount = options.channelCount;
  }


  if (options.sabDraw !== undefined){
    sabDraw = options.sabDraw;
    drawState = new Int32Array(sabDraw.draw_states[0]);

    eventsCounterInt = new Uint8Array(sabDraw.eventsCounter);
    eventsInt = new Uint8Array(sabDraw.events);
    eventPositionInt = new Uint32Array(sabDraw.eventPosition);
    eventPositionResultInt = new Float32Array(sabDraw.eventPositionResult);
  }

  // if (CONFIG.channelCount == 1 ){
  //   currentData = new SharedArrayBuffer(1024  * CONFIG.bytesPerSample);
  //   currentDataInt = new Int16Array(currentData);
  // }

  if (!self.SharedArrayBuffer) {
    postMessage({
      message: 'WORKER_ERROR',
      detail: `SharedArrayBuffer is not supported in your browser.`,
    });
    return;
  }


  // Allocate SABs.
  SharedBuffers = createSharedBuffers(0,AUDIO_CHANNEL_MAX);
  SharedBuffers2 = createSharedBuffers(1,AUDIO_CHANNEL_MAX);

  allSharedBuffers = [SharedBuffers, SharedBuffers2];



  filePointerHeadInt = new Uint32Array(SharedBuffers.filePointerHead);
  // fileContentTempDataInt = [new Int16Array(SharedBuffers.fileContentTempData), new Int16Array(SharedBuffers2.fileContentTempData)] ;
  // fileContentDataInt = [new Int16Array(SharedBuffers.fileContentData), new Int16Array(SharedBuffers2.fileContentData)];

  filePointerHeadInts = [ filePointerHeadInt, new Uint32Array(SharedBuffers2.filePointerHead)];
  // filePointerFileHeadInts = [new Uint32Array(SharedBuffers.filePointerFileHead), new Uint32Array(SharedBuffers2.filePointerFileHead)];

  eventsIdxInt = new Uint8Array(SharedBuffers.eventsIdx);
  eventGlobalPositionInt = new Uint32Array(SharedBuffers.eventGlobalPosition);
  eventGlobalHeaderInt = new Uint32Array(SharedBuffers.eventGlobalHeader);
  globalPositionCap = new Uint8Array(SharedBuffers.globalPositionCap);

  currentDataInt = new Int16Array(SharedBuffers.currentData);
  currentTempInt = new Int16Array(currentDataInt.length);
  currentDataStartInt = new Uint8Array(SharedBuffers.currentDataStart);
  currentDataEndInt = new Uint32Array(SharedBuffers.currentDataEnd);
  currentDataLengthInt = new Uint32Array(SharedBuffers.currentDataLength);


  // _arrHeadsInt = new Uint32Array(SharedBuffers.arrHeads);
  // _arrIsFullInt = new Uint32Array(SharedBuffers.arrIsFull);
  // eventGlobalNumberInt = new Uint8Array(SharedBuffers.eventGlobalNumber);

  // Get TypedArrayView from SAB.
  States = [new Int32Array(SharedBuffers.states), new Int32Array(SharedBuffers2.states)];
  StatesDraw = [new Int32Array(SharedBuffers.statesDraw), new Int32Array(SharedBuffers2.statesDraw) ];
  StatesWrite = new Int32Array(SharedBuffers.statesWrite);
  MyConfig = new Int32Array(SharedBuffers.config);
  let MyConfig2 = new Int32Array(SharedBuffers2.config);
  MyConfigs = [ MyConfig, new Int32Array(SharedBuffers2.config)];

  MyConfig[2]=-1;
  MyConfig2[2]=-1;

  InputRingBuffer = [new Int16Array(SharedBuffers.inputRingBuffer), new Int16Array(SharedBuffers2.inputRingBuffer)];
  OutputRingBuffer = [new Int16Array(SharedBuffers.outputRingBuffer), new Int16Array(SharedBuffers2.outputRingBuffer)];

  // Initialize |States| buffer.
  Atomics.store(States[0], STATE.RING_BUFFER_LENGTH, CONFIG.ringBufferLength);
  Atomics.store(States[0], STATE.KERNEL_LENGTH, CONFIG.kernelLength);
  Atomics.store(States[1], STATE.RING_BUFFER_LENGTH, CONFIG.ringBufferLength);
  Atomics.store(States[1], STATE.KERNEL_LENGTH, CONFIG.kernelLength);

  // Notify AWN in the main scope that the worker is ready.
  postMessage({
    message: 'WORKER_READY',
    channelIdx : options.channelIdx,
    channelCount : options.channelCount,
    SharedBuffers: SharedBuffers,
    SharedBuffers2: SharedBuffers2,
  });

  // Start waiting.
  waitOnRenderAudioRequest();
}

function myTimeout(ms){
  return new Promise(resolve => setTimeout(resolve,ms));
}

onmessage = async (eventFromMain) => {
  if (eventFromMain.data.message === 'INITIALIZE_WORKER') {
    //this causing the delay because sample rate is not using 5000 for human spikerbox
    deviceType = eventFromMain.data.options.deviceType;
    SEGMENT_SIZE = eventFromMain.data.options.sampleRate;
    arrCounts = eventFromMain.data.options.arrCounts;
    console.log("arrCounts : ", eventFromMain.data, arrCounts, SEGMENT_SIZE);
    skipCounts = new Uint32Array(arrCounts);
        
    // SEGMENT_SIZE = 10000;
    console.log("INITIALIZE WORKER z ", eventFromMain.data.options.sampleRate);
    await myTimeout(1000);
    // if (SEGMENT_SIZE != 10000)
    {
      SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
    
      size = SIZE;
      
      allArrMax = [];
      allArrMaxInt = [];
      for (let c = 0; c < SERIAL_CHANNEL_MAX ; c++){
        const arrTemp = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
        allArrMax.push(arrTemp);
        allArrMaxInt.push(new Int16Array(arrTemp));
      }

      size/=2;

      allEnvelopes = [];
      allSabEnvelopes = [];
      let totalChannel = SERIAL_CHANNEL_MAX;
      if (deviceType == 'audio'){
        totalChannel = AUDIO_CHANNEL_MAX;
      }
      console.log("TOTAL CHANNEL : ", totalChannel);
      for (let c = 0; c < totalChannel ; c++){
        var sabEnvelopes = [];
        var envelopes = [];
        size = SIZE / 2;
        for (let i = 0 ; i < SIZE_LOGS2 ; i++){
          let sz = Math.ceil(size);
          if (sz % 2 == 1) sz++;
          const buffer = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
          
          sabEnvelopes.push(buffer);
          envelopes.push(new Int16Array(buffer));
      
          size/=2;
          envelopeSizes[i] = size;
        }
        allSabEnvelopes.push(sabEnvelopes);
        allEnvelopes.push(envelopes);
      }
      console.log("allEnvelopes : ", allEnvelopes.length);

    }

    if ( deviceType == 'audio' ){
      // console.log("initialize ", _arrMaxInt, allArrMaxInt.length);
      initializeAudio(eventFromMain.data.options)
    }else{
      initializeSerial(eventFromMain.data.options);
    }

    return;
  }

  console.log('[SharedBufferWorker] Unknown message: ', eventFromMain);
};
