let deviceType = 'serial';
let sabDraw;
let drawState;
let drawStates;

let eventsCounterInt;
let eventsInt;
let eventPositionInt;

let globalPositionCap = 0;
let eventGlobalPositionInt;
let eventGlobalHeaderInt;
let eventGlobalNumberInt;

let currentDataInt;
let currentDataStartInt;
let currentDataEndInt;
let currentDataLengthInt;


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
let _bufferChannels = [];
var _head = 0;
var offsetHead = 0;

var _arrHeads = new SharedArrayBuffer( 6 * Uint32Array.BYTES_PER_ELEMENT );
var _arrHeadsInt = new Uint32Array(_arrHeads);

var _arrTails = new SharedArrayBuffer( 6 * Uint32Array.BYTES_PER_ELEMENT );
var _arrTailsInt = new Uint32Array(_arrTails);

var _arrOffsetHead = new SharedArrayBuffer( 6 * Uint32Array.BYTES_PER_ELEMENT );
var _arrOffsetHeadInt = new Uint32Array(_arrOffsetHead);

var _arrIsFull = new SharedArrayBuffer( 6 * Uint32Array.BYTES_PER_ELEMENT );
var _arrIsFullInt = new Uint32Array(_arrIsFull);

let vm = this;
var arrCounts = [ 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048 ];
var skipCounts = new Uint32Array(arrCounts);
var isFull = false;


const batchSizeForSerial = 600;
let numberOfChannels = 6;
let hasEscapeSequence = false;
let hasEndEscapeSequence = false;


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


};


// Worker processor config.
const CONFIG = {
  bytesPerState: Int32Array.BYTES_PER_ELEMENT,
  bytesPerSample: Int16Array.BYTES_PER_ELEMENT,
  rawBytesPerSample: Uint8Array.BYTES_PER_ELEMENT,
  stateBufferLength: 32,
  ringBufferLength: 4096,
  kernelLength: 1024,
  channelCount: 1,
  waitTimeOut: 25000,
};

// Shared states between this worker and AWP.
let States;
let StatesDraw;
let StatesWrite;
var MyConfig;

// Shared RingBuffers between this worker and AWP.
let InputRingBuffer;
let OutputRingBuffer;


// PARSING DATA
let SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER = CONFIG.ringBufferLength;

let processedFrame = 0;
// let messagesBuffer = new Uint8Array(SIZE_OF_MESSAGES_BUFFER);
// let circularBuffer = new Uint8Array(SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER);
// let messagesBuffer = new Uint8Array(CONFIG.ringBufferLength);
// let circularBuffer = new Uint8Array(CONFIG.ringBufferLength);
// let obuffer = new Uint16Array(6*SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER);
// circularBuffer[0] = '\n';

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



let SEGMENT_SIZE = 10000;
let SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;

let size = SIZE;

let arrMax = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
let arrMaxInt = new Int16Array(arrMax);

let arrMax1 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
let arrMaxInt1 = new Int16Array(arrMax1);
let arrMax2 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
let arrMaxInt2 = new Int16Array(arrMax2);
let arrMax3 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
let arrMaxInt3 = new Int16Array(arrMax3);
let arrMax4 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
let arrMaxInt4 = new Int16Array(arrMax4);
let arrMax5 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
let arrMaxInt5 = new Int16Array(arrMax5);
let arrMax6 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
let arrMaxInt6 = new Int16Array(arrMax6);

size/=2;
let i = 0;
for (;i<SIZE_LOGS2;i++){
    const sz = Math.floor(size);
    const buffer1 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
    sabEnvelopes1.push(buffer1)

    const buffer2 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
    sabEnvelopes2.push(buffer2)

    const buffer3 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
    sabEnvelopes3.push(buffer3)

    const buffer4 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
    sabEnvelopes4.push(buffer4)

    const buffer5 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
    sabEnvelopes5.push(buffer5)

    const buffer6 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
    sabEnvelopes6.push(buffer6)

    
    envelopes1.push(new Int16Array(buffer1));
    envelopes2.push(new Int16Array(buffer2));
    envelopes3.push(new Int16Array(buffer3));
    envelopes4.push(new Int16Array(buffer4));
    envelopes5.push(new Int16Array(buffer5));
    envelopes6.push(new Int16Array(buffer6));

    size/=2;
    envelopeSizes[i] = size;
}    

function clearBuffer(){
  isClearingBuffer = true;
  console.log("clearBuffer()");
  const sabcs = SharedBuffers;
  let c = 0;
  let envelopeSamples;
  const heads = new Uint32Array(sabcs.arrHeads);
  heads.fill(0);
  let CHANNEL_COUNT_FIX = 1;  
  


  for (;c < CHANNEL_COUNT_FIX ; c++){
    // const sabcs = this.sabcs[c];
    envelopeSamples = new Int16Array(sabcs.arrMax);
    envelopeSamples.fill(0);
    envelopeSamples = new Int16Array(sabcs.arrMax2);
    envelopeSamples.fill(0);
    envelopeSamples = new Int16Array(sabcs.arrMax3);
    envelopeSamples.fill(0);
    envelopeSamples = new Int16Array(sabcs.arrMax4);
    envelopeSamples.fill(0);
    envelopeSamples = new Int16Array(sabcs.arrMax5);
    envelopeSamples.fill(0);
    envelopeSamples = new Int16Array(sabcs.arrMax6);
    envelopeSamples.fill(0);

  }
  const SIZE_LOGS2 = 10;
  for (let l = 0 ; l < SIZE_LOGS2 ; l++){
    envelopeSamples = new Int16Array(sabcs.sabEnvelopes[l]);
    envelopeSamples.fill(0);
    envelopeSamples = new Int16Array(sabcs.sabEnvelopes2[l]);
    envelopeSamples.fill(0);
    envelopeSamples = new Int16Array(sabcs.sabEnvelopes3[l]);
    envelopeSamples.fill(0);
    envelopeSamples = new Int16Array(sabcs.sabEnvelopes4[l]);
    envelopeSamples.fill(0);
    envelopeSamples = new Int16Array(sabcs.sabEnvelopes5[l]);
    envelopeSamples.fill(0);
    envelopeSamples = new Int16Array(sabcs.sabEnvelopes6[l]);
    envelopeSamples.fill(0);
  }
  Atomics.notify(StatesDraw, STATE.REQUEST_RENDER, 0);   
}



/**
 * Process data in the ring buffer with the user-supplied kernel.
 *
 * NOTE: This assumes that no one will modify the buffer content while it is
 * processed by this method.
 */
function processKernel(newDataLength) {
  let inputReadIndex = States[0][STATE.IB_READ_INDEX];
  let outputWriteIndex = States[0][STATE.OB_WRITE_INDEX];

  StatesWrite[STATE.IB_READ_INDEX] = inputReadIndex;
  let sample;
  let j;
 
  // const newDataLength = States[STATE.IB_FRAMES_AVAILABLE];
  if (newDataLength<=0) return;


  
  for (let c = 0 ; c < numberOfChannels; c++){
    numberOfParsedChannels = c+1;
    let buffer = new Int16Array(newDataLength);
  
    if (inputReadIndex + newDataLength <= CONFIG.ringBufferLength){
      buffer.set(InputRingBuffer[c].subarray(inputReadIndex, inputReadIndex + newDataLength));
    }else{
      let firstPartData = InputRingBuffer[c].subarray(inputReadIndex);
      buffer.set(firstPartData,0);
      const remainderLength = newDataLength - firstPartData.length;
      let secondPartData = InputRingBuffer[c].subarray(0,remainderLength);
      buffer.set(secondPartData,firstPartData.length);
    }
  
    // console.log("sample : ", buffer);
    for (let i = 0; i < buffer.length; ++i) {
      sample = -buffer[i];


      if (numberOfParsedChannels == 1){
        arrMaxInt = arrMaxInt1;
        envelopes = envelopes1;
      }else
      if (numberOfParsedChannels == 2){
        arrMaxInt = arrMaxInt2;
        envelopes = envelopes2;
      }else
      if (numberOfParsedChannels == 3){
        arrMaxInt = arrMaxInt3;
        envelopes = envelopes3;
      }else
      if (numberOfParsedChannels == 4){
        arrMaxInt = arrMaxInt4;
        envelopes = envelopes4;
      }else
      if (numberOfParsedChannels == 5){
        arrMaxInt = arrMaxInt5;
        envelopes = envelopes5;
      }else
      if (numberOfParsedChannels == 6){
        arrMaxInt = arrMaxInt6;
        envelopes = envelopes6;
      }

      _head = _arrHeadsInt[numberOfParsedChannels - 1];
      offsetHead = _arrOffsetHeadInt[numberOfParsedChannels - 1];

      for (j = 0; j < SIZE_LOGS2; j++){
        const skipCount = skipCounts[j];
        const envelopeSampleIndex = Math.floor( _head / skipCount );
        const interleavedSignalIdx = envelopeSampleIndex * 2; 

        if (_head % skipCount == 0){
          envelopes[ j ] [interleavedSignalIdx] = sample; //20967 * 2  =40k
          envelopes[ j ] [interleavedSignalIdx + 1] = sample;
        }else{
          if (sample < envelopes[ j ] [interleavedSignalIdx]){
              envelopes[ j ] [interleavedSignalIdx] = sample;
          }
          if (sample > envelopes[ j ] [interleavedSignalIdx + 1]){
              envelopes[ j ] [interleavedSignalIdx+1] = sample;
          }
        }
      }  

      const interleavedHeadSignalIdx = _head * 2;
      arrMaxInt[interleavedHeadSignalIdx] = sample;
      arrMaxInt[interleavedHeadSignalIdx + 1] = sample;

      _head++;
      offsetHead++ ;
      if (_head == SIZE){
        _head = 0;        
        _arrIsFullInt[numberOfParsedChannels-1] = 1;
        if (numberOfParsedChannels == 1) {
          globalPositionCap++;
        }

        isFull = true;
      }     

      _arrHeadsInt[numberOfParsedChannels-1] = _head;
      _arrOffsetHeadInt[numberOfParsedChannels-1] = offsetHead;

    }
  }
  outputWriteIndex = ( outputWriteIndex + newDataLength ) % CONFIG.ringBufferLength;
  inputReadIndex = ( inputReadIndex + newDataLength ) % CONFIG.ringBufferLength;

  States[0][STATE.IB_READ_INDEX] = inputReadIndex;
  States[0][STATE.OB_WRITE_INDEX] = outputWriteIndex;

  StatesWrite[STATE.IB_WRITE_INDEX] = inputReadIndex;
  MyConfig[0] = _head;
  MyConfig[1] = isFull? 1:0;

  Atomics.notify(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 1);
  eventGlobalHeaderInt[0] = globalPositionCap * SIZE + _head;
  


}

/**
 * Waits for the signal delivered via |States| SAB. When signaled, process
 * the audio data to fill up |outputRingBuffer|.
 */
function waitOnRenderRequest() {
  // As long as |REQUEST_RENDER| is zero, keep waiting. (sleep)
  try{
    let sumData = 0;
    while (Atomics.wait(States[0], STATE.REQUEST_RENDER, 0) === 'ok') {
      const newDataLength = States[0][STATE.IB_FRAMES_AVAILABLE];
      sumData += newDataLength;
      
      processKernel(newDataLength);
      // Update the number of available frames in the buffer.
      States[0][STATE.IB_FRAMES_AVAILABLE] -= newDataLength;
      States[0][STATE.OB_FRAMES_AVAILABLE] += newDataLength;
      // States[STATE.IB_FRAMES_AVAILABLE] -= processedFrame;
      // States[STATE.OB_FRAMES_AVAILABLE] += processedFrame;

      // Reset the request render bit, and wait again.
      Atomics.store(States[0], STATE.REQUEST_RENDER, 0);
      // console.log("sumData : ",sumData);
      
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
function initialize(options) {
  if (options.deviceType) {
    deviceType = options.deviceType;
    // if (options.deviceType == 'hid'){
    //   CONFIG.ringBufferLength = 4154 * 2;
    //   CONFIG.kernelLength = 992 * 2;
    //   SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER = CONFIG.ringBufferLength * 8;
    //   // numberOfChannels = 2;
    // }
  }
  numberOfChannels = options.channelCount;

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
  for (let i = 0 ; i < CONFIG.channelCount ; i++){
    _bufferChannels.push(new SharedArrayBuffer(CONFIG.ringBufferLength * 1));
  }
  
  SharedBuffers = {
    states:[
        new SharedArrayBuffer(CONFIG.stateBufferLength * CONFIG.bytesPerState),
        new SharedArrayBuffer(CONFIG.stateBufferLength * CONFIG.bytesPerState),
        new SharedArrayBuffer(CONFIG.stateBufferLength * CONFIG.bytesPerState),
        new SharedArrayBuffer(CONFIG.stateBufferLength * CONFIG.bytesPerState),
        new SharedArrayBuffer(CONFIG.stateBufferLength * CONFIG.bytesPerState),
        new SharedArrayBuffer(CONFIG.stateBufferLength * CONFIG.bytesPerState),
    ],
    inputRingBuffer:
        // new SharedArrayBuffer(CONFIG.ringBufferLength * CONFIG.channelCount * CONFIG.bytesPerSample),
        [ 
          new SharedArrayBuffer(CONFIG.ringBufferLength * 1 * CONFIG.bytesPerSample), 
          new SharedArrayBuffer(CONFIG.ringBufferLength * 1 * CONFIG.bytesPerSample), 
          new SharedArrayBuffer(CONFIG.ringBufferLength * 1 * CONFIG.bytesPerSample), 
          new SharedArrayBuffer(CONFIG.ringBufferLength * 1 * CONFIG.bytesPerSample), 
          new SharedArrayBuffer(CONFIG.ringBufferLength * 1 * CONFIG.bytesPerSample), 
          new SharedArrayBuffer(CONFIG.ringBufferLength * 1 * CONFIG.bytesPerSample), 
        ],
    outputRingBuffer:
        // new SharedArrayBuffer(CONFIG.ringBufferLength * CONFIG.channelCount * CONFIG.bytesPerSample),
        new SharedArrayBuffer(CONFIG.ringBufferLength * 1 * CONFIG.bytesPerSample),

    bufferChannels : _bufferChannels,

    statesDraw:
      new SharedArrayBuffer(CONFIG.stateBufferLength * CONFIG.bytesPerState),
    
    statesWrite:
      new SharedArrayBuffer(CONFIG.stateBufferLength * CONFIG.bytesPerState),
                      
    arrHeads : _arrHeads,
    arrTails : _arrTails,
    arrOffsetHead : _arrOffsetHead,
    arrIsFull : _arrIsFull,

    sabEnvelopes : sabEnvelopes1,
    arrMax : arrMax1,

    sabEnvelopes2 : sabEnvelopes2,
    arrMax2 : arrMax2,

    sabEnvelopes3 : sabEnvelopes3,
    arrMax3 : arrMax3,

    sabEnvelopes4 : sabEnvelopes4,
    arrMax4 : arrMax4,

    sabEnvelopes5 : sabEnvelopes5,
    arrMax5 : arrMax5,

    sabEnvelopes6 : sabEnvelopes6,
    arrMax6 : arrMax6,

    config : new SharedArrayBuffer(CONFIG.bytesPerState * 70),
    
    productId : new SharedArrayBuffer( 1 * Uint16Array.BYTES_PER_ELEMENT),
    maxSampleRate : new SharedArrayBuffer( 1 * Uint16Array.BYTES_PER_ELEMENT),
    minChannels : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT),
    maxChannels : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT),
    sampleRates : new SharedArrayBuffer( 6 * Uint16Array.BYTES_PER_ELEMENT),
    channels : new SharedArrayBuffer( 6 * Uint8Array.BYTES_PER_ELEMENT),

    eventGlobalPosition : new SharedArrayBuffer(200 * Uint32Array.BYTES_PER_ELEMENT),
    eventGlobalHeader : new SharedArrayBuffer(1 * Uint32Array.BYTES_PER_ELEMENT),
    eventsIdx : new SharedArrayBuffer(200 * Uint8Array.BYTES_PER_ELEMENT),
    
    currentData : new SharedArrayBuffer(CONFIG.ringBufferLength * Int16Array.BYTES_PER_ELEMENT),
    currentDataStart : new SharedArrayBuffer(1 * Uint8Array.BYTES_PER_ELEMENT),
    currentDataEnd : new SharedArrayBuffer(1 * Uint32Array.BYTES_PER_ELEMENT),
    currentDataLength : new SharedArrayBuffer(1 * Uint32Array.BYTES_PER_ELEMENT),

  };
  eventGlobalPositionInt = new Uint32Array(SharedBuffers.eventGlobalPosition);
  eventGlobalHeaderInt = new Uint32Array(SharedBuffers.eventGlobalHeader);
  eventsIdxInt = new Uint8Array(SharedBuffers.eventsIdx);

  currentDataInt = new Int16Array(SharedBuffers.currentData);
  currentDataStartInt = new Uint8Array(SharedBuffers.currentDataStart);
  currentDataEndInt = new Uint32Array(SharedBuffers.currentDataEnd);
  currentDataLengthInt = new Uint32Array(SharedBuffers.currentDataLength);

  // Get TypedArrayView from SAB.
  States = [
    new Int32Array(SharedBuffers.states[0]),
    new Int32Array(SharedBuffers.states[1]),
    new Int32Array(SharedBuffers.states[2]),
    new Int32Array(SharedBuffers.states[3]),
    new Int32Array(SharedBuffers.states[4]),
    new Int32Array(SharedBuffers.states[5]),
  ];
  InputRingBuffer = [
                      new Int16Array(SharedBuffers.inputRingBuffer[0]),
                      new Int16Array(SharedBuffers.inputRingBuffer[1]),
                      new Int16Array(SharedBuffers.inputRingBuffer[2]),
                      new Int16Array(SharedBuffers.inputRingBuffer[3]),
                      new Int16Array(SharedBuffers.inputRingBuffer[4]),
                      new Int16Array(SharedBuffers.inputRingBuffer[5]),
                    ];
  OutputRingBuffer = [new Uint16Array(SharedBuffers.outputRingBuffer)];

  StatesDraw = new Int32Array(SharedBuffers.statesDraw);
  StatesWrite = new Int32Array(SharedBuffers.statesWrite);
  MyConfig = new Int32Array(SharedBuffers.config);

  MyConfig[2]=-1;


  // Initialize |States| buffer.
  for (let c = 0 ; c<6 ; c++){
    Atomics.store(States[c], STATE.RING_BUFFER_LENGTH, CONFIG.ringBufferLength);
    Atomics.store(States[c], STATE.KERNEL_LENGTH, CONFIG.kernelLength);
  
  }

  // Notify AWN in the main scope that the worker is ready.
  postMessage({
    message: 'WORKER_READY',
    SharedBuffers: SharedBuffers,
  });

  // Start waiting.
  while (true){
    waitOnRenderRequest();

  }
}

onmessage = (eventFromMain) => {
  if (eventFromMain.data.message === 'INITIALIZE_WORKER') {
    // SEGMENT_SIZE = 10000;
    SEGMENT_SIZE = eventFromMain.data.options.sampleRate;
    if (SEGMENT_SIZE != 10000){
      SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
    
      size = SIZE;
      
      arrMax = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
      arrMaxInt = new Int16Array(arrMax);
      arrMax1 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
      arrMaxInt1 = new Int16Array(arrMax1);
      arrMax2 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
      arrMaxInt2 = new Int16Array(arrMax2);
      arrMax3 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
      arrMaxInt3 = new Int16Array(arrMax3);
      arrMax4 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
      arrMaxInt4 = new Int16Array(arrMax4);
      arrMax5 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
      arrMaxInt5 = new Int16Array(arrMax5);
      arrMax6 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
      arrMaxInt6 = new Int16Array(arrMax6);
      
      size/=2;
      let i = 0;

      try{
        sabEnvelopes1=[];
        sabEnvelopes2=[];
        sabEnvelopes3=[];
        sabEnvelopes4=[];
        sabEnvelopes5=[];
        sabEnvelopes6=[];  
      }catch(err){
        console.log(err);
      }

      try{
        envelopes1=[];
        envelopes2=[];
        envelopes3=[];
        envelopes4=[];
        envelopes5=[];
        envelopes6=[];
      }catch(err){
        console.log(err);
      }

      
      for (;i<SIZE_LOGS2;i++){
        const sz = Math.floor(size);
        const buffer1 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
        sabEnvelopes1.push(buffer1)
    
        const buffer2 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
        sabEnvelopes2.push(buffer2)
    
        const buffer3 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
        sabEnvelopes3.push(buffer3)
    
        const buffer4 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
        sabEnvelopes4.push(buffer4)
    
        const buffer5 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
        sabEnvelopes5.push(buffer5)
    
        const buffer6 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
        sabEnvelopes6.push(buffer6)
    
        
        envelopes1.push(new Int16Array(buffer1));
        envelopes2.push(new Int16Array(buffer2));
        envelopes3.push(new Int16Array(buffer3));
        envelopes4.push(new Int16Array(buffer4));
        envelopes5.push(new Int16Array(buffer5));
        envelopes6.push(new Int16Array(buffer6));
    
        size/=2;
        envelopeSizes[i] = size;
      }
    }

    initialize(eventFromMain.data.options);
    return;
  }

  console.log('[SharedBufferWorker] Unknown message: ', eventFromMain);
};
