// This Worker is the actual backend of AudioWorkletProcessor (AWP). After
// instantiated/initialized by AudioWorkletNode (AWN), it communicates with the
// associated AWP via SharedArrayBuffer (SAB).
//
// A pair of SABs is created by this Worker. The one is for the shared states
// (Int32Array) of ring buffer between two obejcts and the other works like the
// ring buffer for audio content (Float32Array).
//
// The synchronization mechanism between two object is done by wake/wait
// function in Atomics API. When the ring buffer runs out of the data to
// consume, the AWP will flip |REQUEST_RENDER| state to signal the worker. The
// work wakes on the signal and renders the audio data requested.

// Indices for the State SAB.
const MAX_FILE_SAMPLES = 1024;
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

  'OPEN_FILE_REDRAW':12,

};

// Worker processor config.
const CONFIG = {
  bytesPerState: Int32Array.BYTES_PER_ELEMENT,
  bytesPerSample: Int16Array.BYTES_PER_ELEMENT,
  stateBufferLength: 16,
  ringBufferLength: 4096,
  kernelLength: 1024,
  channelCount: 1,
  waitTimeOut: 25000,
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


};

// let arrFileMax = new SharedArrayBuffer(SIZE*CONFIG.bytesPerSample);
// let arrFileMaxInt = new Int16Array(arrFileMax);
let currentData = new SharedArrayBuffer(1024 * 8 * CONFIG.bytesPerSample);
let currentDataInt = new Int16Array(currentData);

let currentDataChannel1 = new SharedArrayBuffer(1024 * CONFIG.bytesPerSample);
let currentDataIntChannel1 = new Int16Array(currentDataChannel1);

let SharedBuffers;
let SharedBuffers2;
// Shared states between this worker and AWP.
let States;
let StatesDraw;
let StatesWrite;
var MyConfigs = [];
var MyConfig;

let currentDataHead = 0;
let filePointerHeadInts;
let filePointerHeadInt;
let filePointerFileHeadInts;
let fileContentDataInt;
let fileContentTempDataInt;
let sharedFileContainerInt;
let sharedFileContainerResultInt;
let sharedFileContainerStatusInt;


// Shared RingBuffers between this worker and AWP.
let InputRingBuffer;
let OutputRingBuffer;

let eventsCounterInt;
let eventPositionResultInt;
let eventsInt;
let eventsIdxInt;
let eventPositionInt;
let eventGlobalPositionInt;
let eventGlobalHeaderInt;
let eventGlobalNumberInt;
let drawState;

/* 
  Preparing the envelopes using Shared Array Buffer

*/

/*
Hi, this worker is the main worker which process the enveloping process,
lot of the initialization at the beginning is to speedup the performance,

This thread main functionality is to envelope data that are received,
Also the process of receiving the data is using Shared Array Buffer, and Atomics

*/

const SIZE_LOGS2 = 10;
const NUMBER_OF_SEGMENTS = 60;

var envelopes = [];
var envelopes2 = [];
var envelopeSizes = new Uint32Array(SIZE_LOGS2);
var envelopeSizes2 = new Uint32Array(SIZE_LOGS2);
var envelopeLevel;
var channelLevel;
var isFull = false;

var drawSurfaceWidth,height;
var toSample, fromSample;
var drawBuffer;

var _head = 0;
var offsetHead = 0;
let vm = this;
var arrCounts = [ 4, 8, 16, 32, 64, 128, 256,512,1024, 2048 ];
var skipCounts = new Uint32Array(arrCounts);

var channelIdx;

let sabEnvelopes = [];
let sabEnvelopes2 = [];


let SEGMENT_SIZE = 44100;
let SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
let size = SIZE;
let arrMax = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
let arrMaxInt = new Int16Array(arrMax);
let arrMax2 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
let arrMaxInt2 = new Int16Array(arrMax2);

let globalPositionCap;

size/=2;
let i = 0;
for (;i<SIZE_LOGS2;i++){
    const sz = Math.floor(size);
    const buffer = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
    const buffer2 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
    // const len = (new Int32Array(buffer)).length;
    // console.log("len",len);
    //1323000

    sabEnvelopes.push(buffer)
    sabEnvelopes2.push(buffer2)

    envelopes.push(new Int16Array(buffer));
    envelopes2.push(new Int16Array(buffer2));
    
    size/=2;
    envelopeSizes[i] = size;
    envelopeSizes2[i] = size;
}    


/**
 * Process audio data in the ring buffer with the user-supplied kernel.
 *
 * NOTE: This assumes that no one will modify the buffer content while it is
 * processed by this method.
 */
function processKernel() {

  // console.log("READ : ", inputReadIndex);

  // if (isNaN(InputRingBuffer[0][inputReadIndex]))
  //   console.error('Found NaN at buffer index: %d', inputReadIndex);
  
  // A stupid processing kernel that clones audio data sample-by-sample. Also
  // note here we are handling only the first channel.
  let sample;
  let c = 0;
  let inputReadIndex;
  let outputWriteIndex;
  let MyConfig;
  StatesWrite[STATE.IB_READ_INDEX] = States[0][STATE.IB_READ_INDEX];
  let flagChannelDisplays = new Uint32Array(sabDraw.channelDisplays);
  const sum = flagChannelDisplays.reduce((pre,curr)=>pre+curr,0);

  for ( ;c < 2; c++){
    // if (flagChannelDisplays[c] == 0){
    //   continue;
    // }    
    inputReadIndex = States[c][STATE.IB_READ_INDEX];
    outputWriteIndex = States[c][STATE.OB_WRITE_INDEX];
  
    MyConfig = MyConfigs[c];
    _head = MyConfig[0];
    const channelIdx = c;
    const _envelopes = c == 0 ? envelopes : envelopes2;
    const _arrMaxInt = c == 0 ? arrMaxInt : arrMaxInt2;

    offsetHead = MyConfig[7];
    let filePointerHeadInt = filePointerHeadInts[c];
    let fileContentTempDataContainer = fileContentTempDataInt[c];
  
    let i = 0;
    let j;

    for (; i < CONFIG.kernelLength; ++i) {
      sample = InputRingBuffer[c][inputReadIndex];
      // OutputRingBuffer[c][outputWriteIndex] = sample;
  
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
  
      const interleavedHeadSignalIdx = _head * 2;
      _arrMaxInt[interleavedHeadSignalIdx] = sample;
      _arrMaxInt[interleavedHeadSignalIdx + 1] = sample;
      // arrFileMaxInt[_head] = sample;
  
  
      _head++;
      offsetHead++;
      if (_head == SIZE){
        _head = 0;     
        isFull = true;
        if (channelIdx == 0) {
          globalPositionCap[0]++;
        }
        // MyConfig[2]++;
      }
  
  
  
      if (channelIdx == 0){
        if (drawState){
          // console.log(drawState);
          if (drawState[DRAW_STATE.EVENT_FLAG] == 1){
            drawState[DRAW_STATE.EVENT_POSITION] = _head;
  
            let ctr = drawState[DRAW_STATE.EVENT_COUNTER];
            eventsInt[ctr] = drawState[DRAW_STATE.EVENT_NUMBER];
            eventPositionInt[ctr] = _head;
            
            eventGlobalPositionInt[ctr] = globalPositionCap[0] * SIZE + _head;
            // console.log("eventGlobalPositionInt!!! : ", eventGlobalPositionInt);
  
            eventsIdxInt[ctr] = drawState[DRAW_STATE.EVENT_NUMBER];
            ctr++;
            if ( ctr >= 200){
              ctr=ctr % 200;
              eventsCounterInt.fill(0);
              eventsInt.fill(0);
              eventPositionInt.fill(0);
              eventPositionResultInt.fill(0);        
            }
            // ctr = (ctr + 1) % 200;
            eventsCounterInt[0]=ctr;
  
            drawState[DRAW_STATE.EVENT_COUNTER] = ctr;
            console.log("eventsCounter : ", ctr, "head : ", _head);
            console.log("Position : ", eventPositionInt);
            console.log("Result : ", eventPositionResultInt);
            console.log("eventsInt : ", eventsInt);
            drawState[DRAW_STATE.EVENT_FLAG] = 0;
            
          }
  
        }
      }
      // console.log("my config : ", channelIdx, i, _head);
      let configIdx = 0;
      if (sum == 1 && flagChannelDisplays[1] == 1){
        configIdx = 1;
        // console.log("my config : ", configIdx);
      }


      if (MyConfigs[configIdx][2] != -1){
        // console.log("filePointerHeadInt : ",filePointerHeadInt[0]);
        // console.log("my config : ", MyConfigs[0][2], channelIdx, c);
        // filePointerFileHeadInt[0]++;
        try{
          if (channelIdx == 0 ){
            sharedFileContainerInt[2 * filePointerHeadInt[0]] = sample;
          }else{
            // console.log("channelIdx : ",channelIdx);
            sharedFileContainerInt[2 * filePointerHeadInt[0]+1] = sample;
          }
    
        }catch(err){
          console.log("Shared file container : ",err);
        }
        // fileContentTempDataContainer[filePointerHeadInt[0]% 1024] = sample;
        fileContentTempDataContainer[filePointerHeadInt[0]] = sample;
        filePointerHeadInt[0]++;  
        sharedFileContainerStatusInt[channelIdx] = filePointerHeadInt[0];
  
        // currentDataIntChannel1[currentDataHead % 1024] = sample;
        // currentDataInt[currentDataHead++] = sample;
        // if (currentDataHead >= 1024){
        //   currentDataHead = 0;
        // }
  
      }
  
      
  
      if (++outputWriteIndex === CONFIG.ringBufferLength)
        outputWriteIndex = 0;
      if (++inputReadIndex === CONFIG.ringBufferLength)
        inputReadIndex = 0;
    }
  
    // console.log("process Kernel", InputRingBuffer[0]);
    MyConfig[7] = offsetHead;
    MyConfig[0] = _head;
    
    MyConfig[1] = isFull? globalPositionCap[0]:0;
    // MyConfig[2] = currentDataHead;
    MyConfig[3] = currentDataHead;
    if (MyConfig[2] != -1){
      MyConfig[4]++;
    }
    // console.log("process Kernel", InputRingBuffer[0]);
    // console.log( (new Date()).getTime() - p );
    // console.log( 'this.channelIdx', arrMaxInt[_head] );
    States[c][STATE.IB_READ_INDEX] = inputReadIndex;
    States[c][STATE.OB_WRITE_INDEX] = outputWriteIndex;
  
    StatesWrite[STATE.IB_WRITE_INDEX] = inputReadIndex;
  
    if (States[c][STATE.OPEN_FILE_REDRAW] == 0){
      Atomics.notify(StatesDraw[c], STATE.REQUEST_SIGNAL_REFORM, 1);
    }else{
    }
   
    // eventGlobalHeaderInt[0] = globalPositionCap;
    
    //START OF RECORDING
    eventGlobalHeaderInt[0] = globalPositionCap[0] * SIZE + _head;
    let configIdx =0;
    if (sum == 1 && flagChannelDisplays[1] == 1){
      configIdx = 1;

    }
  
    if (MyConfigs[configIdx][2] != -1){
      // console.log("filePointerHeadInt0 : ", filePointerHeadInt[0]);
      if (filePointerHeadInt[0] >= MAX_FILE_SAMPLES){
        // if (filePointerHeadInt[0] > 4096){
        //   console.log("filePointerHeadInt : ", filePointerHeadInt[0]);
        // }
        // console.log("currentDataHead : ", currentDataHead);
        // fileContentDataInt.set(fileContentTempDataInt.slice(0, filePointerHeadInt[0]+1));
        // fileContentDataInt.set(currentDataIntChannel1,0);
        // fileContentDataInt[c].set(fileContentTempDataInt[c]);
        fileContentDataInt[c].set(fileContentTempDataContainer);
        // console.log("fileContentTempDataInt : ", fileContentTempDataInt);
        fileContentTempDataContainer.fill(0);
        // console.log("fileContentDataInt : ", fileContentDataInt);
        filePointerFileHeadInts[c][0] = filePointerHeadInt[0];
        filePointerHeadInt[0] = 0;
        if (sharedFileContainerStatusInt[0]==sharedFileContainerStatusInt[1]){
          const sum = sharedFileContainerStatusInt[0] + sharedFileContainerStatusInt[1];
          if (sum > 0){
            const sub = sharedFileContainerInt.slice(0,sum);
            // console.log("sub : ", sub);
            sharedFileContainerResultInt.set(sub);
            Atomics.notify(sharedFileContainerStatusInt, 9, 1);   
          }
        }
        if (configIdx == c){
          Atomics.notify(StatesWrite, STATE.REQUEST_WRITE_FILE, 1);
    
        }
    
  
      }
    }  
  }

  // if (!equal(arrMaxInt, arrMaxInt2)){
  //   console.log("ERRROR NOT SAME");
  // }

  // if (MyConfig[2] != -1){
  //   Atomics.notify(StatesWrite, STATE.REQUEST_WRITE_FILE, 1);
  // }
  // console.log("WRITE : ", MyConfig[2], eventGlobalHeaderInt[0]);


}


/**
 * Waits for the signal delivered via |States| SAB. When signaled, process
 * the audio data to fill up |outputRingBuffer|.
 */
function waitOnRenderRequest() {
  // As long as |REQUEST_RENDER| is zero, keep waiting. (sleep)
  while (Atomics.wait(States[0], STATE.REQUEST_RENDER, 0) === 'ok') {
    processKernel();

    // Update the number of available frames in the buffer.
    States[0][STATE.IB_FRAMES_AVAILABLE] -= CONFIG.kernelLength;
    States[0][STATE.OB_FRAMES_AVAILABLE] += CONFIG.kernelLength;

    States[1][STATE.IB_FRAMES_AVAILABLE] -= CONFIG.kernelLength;
    States[1][STATE.OB_FRAMES_AVAILABLE] += CONFIG.kernelLength;

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
function initialize(options) {
  if (options.ringBufferLength) {
    CONFIG.ringBufferLength = options.ringBufferLength;
  }
  if (options.channelCount) {
    CONFIG.channelCount = options.channelCount;
  }

  if (options.channelIdx !== undefined){
    channelIdx = options.channelIdx;    
  }


  if (options.sabDraw !== undefined){
    sabDraw = options.sabDraw;
    // console.log("---- options : ",options);


    drawState = new Int32Array(sabDraw.draw_states[0]);
    // console.log("channelIdx : ",channelIdx);

    // curChannel = drawState[DRAW_STATE.CHANNEL_COUNTS];

    eventsCounterInt = new Uint8Array(sabDraw.eventsCounter);
    eventsInt = new Uint8Array(sabDraw.events);
    eventPositionInt = new Uint32Array(sabDraw.eventPosition);
    eventPositionResultInt = new Float32Array(sabDraw.eventPositionResult);
    // let _states = new Int32Array(sharedBuffers.states);
    
  }

  // console.log("CONFIG.channelCount",CONFIG.channelCount);
  if (CONFIG.channelCount == 1 ){
    currentData = new SharedArrayBuffer(1024  * CONFIG.bytesPerSample);
    currentDataInt = new Int16Array(currentData);
        
  }

  if (!self.SharedArrayBuffer) {
    postMessage({
      message: 'WORKER_ERROR',
      detail: `SharedArrayBuffer is not supported in your browser.`,
    });
    return;
  }


  // Allocate SABs.
  SharedBuffers = {
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
                      
    sabEnvelopes : sabEnvelopes,
    arrMax : arrMax,

    channelIdx : options.channelIdx,
    fileSab : options.fileSab,

    currentData : currentData,
    currentDataChannel1 : currentDataChannel1,
    // arrFileMax : arrFileMax,
    eventGlobalPosition : new SharedArrayBuffer(200 * Uint32Array.BYTES_PER_ELEMENT),
    eventGlobalNumber : new SharedArrayBuffer(200 * Uint8Array.BYTES_PER_ELEMENT),
    eventGlobalHeader : new SharedArrayBuffer(1 * Uint32Array.BYTES_PER_ELEMENT),
    eventsIdx : new SharedArrayBuffer(200 * Uint8Array.BYTES_PER_ELEMENT),
    globalPositionCap : new SharedArrayBuffer(1 * Uint8Array.BYTES_PER_ELEMENT),

    filePointerHead : new SharedArrayBuffer(1 * Uint32Array.BYTES_PER_ELEMENT),
    filePointerFileHead : new SharedArrayBuffer(1 * Uint32Array.BYTES_PER_ELEMENT),
    fileContentData : new SharedArrayBuffer(1024 * 2 * CONFIG.bytesPerSample),//bytesPerSample: Int16Array.BYTES_PER_ELEMENT,
    fileContentTempData : new SharedArrayBuffer(1024 * 2 * CONFIG.bytesPerSample),//bytesPerSample: Int16Array.BYTES_PER_ELEMENT,

    config : new SharedArrayBuffer(CONFIG.bytesPerState * 70),


  };


  SharedBuffers2 = {
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
                      
    sabEnvelopes : sabEnvelopes2,
    arrMax : arrMax2,


    channelIdx : options.channelIdx,
    fileSab : options.fileSab,

    currentData : currentData,
    currentDataChannel1 : currentDataChannel1,
    // arrFileMax : arrFileMax,
    eventGlobalPosition : new SharedArrayBuffer(200 * Uint32Array.BYTES_PER_ELEMENT),
    eventGlobalNumber : new SharedArrayBuffer(200 * Uint8Array.BYTES_PER_ELEMENT),
    eventGlobalHeader : new SharedArrayBuffer(1 * Uint32Array.BYTES_PER_ELEMENT),
    eventsIdx : new SharedArrayBuffer(200 * Uint8Array.BYTES_PER_ELEMENT),
    globalPositionCap : new SharedArrayBuffer(1 * Uint8Array.BYTES_PER_ELEMENT),

    filePointerHead : new SharedArrayBuffer(1 * Uint32Array.BYTES_PER_ELEMENT),
    filePointerFileHead : new SharedArrayBuffer(1 * Uint32Array.BYTES_PER_ELEMENT),
    fileContentData : new SharedArrayBuffer(1024 * 2 * CONFIG.bytesPerSample),//bytesPerSample: Int16Array.BYTES_PER_ELEMENT,
    fileContentTempData : new SharedArrayBuffer(1024 * 2 * CONFIG.bytesPerSample),//bytesPerSample: Int16Array.BYTES_PER_ELEMENT,

    config : new SharedArrayBuffer(CONFIG.bytesPerState * 70),


  };  


  filePointerHeadInt = new Uint32Array(SharedBuffers.filePointerHead);
  fileContentTempDataInt = [new Int16Array(SharedBuffers.fileContentTempData), new Int16Array(SharedBuffers2.fileContentTempData)] ;
  fileContentDataInt = [new Int16Array(SharedBuffers.fileContentData), new Int16Array(SharedBuffers2.fileContentData)];

  filePointerHeadInts = [ filePointerHeadInt, new Uint32Array(SharedBuffers2.filePointerHead)];
  filePointerFileHeadInts = [new Uint32Array(SharedBuffers.filePointerFileHead), new Uint32Array(SharedBuffers2.filePointerFileHead)];

  eventsIdxInt = new Uint8Array(SharedBuffers.eventsIdx);
  eventGlobalPositionInt = new Uint32Array(SharedBuffers.eventGlobalPosition);
  eventGlobalHeaderInt = new Uint32Array(SharedBuffers.eventGlobalHeader);
  eventGlobalNumberInt = new Uint8Array(SharedBuffers.eventGlobalNumber);
  globalPositionCap = new Uint8Array(SharedBuffers.globalPositionCap);

  // Get TypedArrayView from SAB.
  States = [new Int32Array(SharedBuffers.states), new Int32Array(SharedBuffers2.states)];
  StatesDraw = [new Int32Array(SharedBuffers.statesDraw), new Int32Array(SharedBuffers2.statesDraw) ];
  StatesWrite = new Int32Array(SharedBuffers.statesWrite);
  MyConfig = new Int32Array(SharedBuffers.config);
  MyConfigs = [ MyConfig, new Int32Array(SharedBuffers2.config)];

  MyConfig[2]=-1;

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
  // console.log(SharedBuffers);

  // Start waiting.
  waitOnRenderRequest();
}

onmessage = (eventFromMain) => {
  if (eventFromMain.data.message === 'INITIALIZE_WORKER') {
    SEGMENT_SIZE = eventFromMain.data.options.sampleRate;
    sharedFileContainerInt = new Int16Array(eventFromMain.data.options.sharedFileContainer);
    sharedFileContainerResultInt = new Int16Array(eventFromMain.data.options.sharedFileContainerResult);
    sharedFileContainerStatusInt = new Int32Array(eventFromMain.data.options.sharedFileContainerStatus);
    if (SEGMENT_SIZE != 44100){
      SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;

      arrMax = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
      arrMaxInt = new Int16Array(arrMax);
      arrMax2 = new SharedArrayBuffer(SIZE*2*CONFIG.bytesPerSample);
      arrMaxInt2 = new Int16Array(arrMax2);
  
      size = SIZE;
      size/=2;
      sabEnvelopes = [];
      envelopes = [];
      sabEnvelopes2 = [];
      envelopes2 = [];
      let i = 0;
      for (;i<SIZE_LOGS2;i++){
          const sz = Math.floor(size);
          const buffer = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
          const buffer2 = new SharedArrayBuffer(CONFIG.bytesPerSample * sz);
          // const len = (new Int32Array(buffer)).length;
          // console.log("len",len);
          //1323000
      
          sabEnvelopes.push(buffer)
          sabEnvelopes2.push(buffer2)
      
          envelopes.push(new Int16Array(buffer));
          envelopes2.push(new Int16Array(buffer2));
          size/=2;
          envelopeSizes[i] = size;
          envelopeSizes2[i] = size;
      }      
    }

    initialize(eventFromMain.data.options);
    return;
  }else
  if (eventFromMain.data.message === 'SIGNAL_WORKER') {

  }

  console.log('[SharedBufferWorker] Unknown message: ', eventFromMain);
};


function equal (buf1, buf2)
{
    if (buf1.byteLength != buf2.byteLength) return false;
    var dv1 = new Int16Array(buf1);
    var dv2 = new Int16Array(buf2);
    for (var i = 0 ; i != buf1.byteLength ; i++)
    {
        if (dv1[i] != dv2[i]) return false;
    }
    return true;
}