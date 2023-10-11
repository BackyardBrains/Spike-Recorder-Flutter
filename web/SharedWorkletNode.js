// import Module from ("build/web/a.out.js"); 
// Module.onRuntimeInitialized = _ => {
// }; 


// let Module;
// CModule().then(function(mymod) {
//   Module = mymod;
// });
/* 
  THIS IS WHERE THE MULTICHANNEL WORKER CREATED
  1 Shared-buffer-worklet-node will create many shared-buffer-worker according to the channels
  channelIdx need to be passed,
  each worker channel need to send to signal worker to be reshaped and drawn to Canvas
  each shared array buffer inside worker channel has currentLevel, that send respective envelope level to signal worker
  signal worker has all the channel data inside the 

  Step by step signal worker creation
  0. This Constructor will receive channels count, and will pass signal worker
  a. Created in UI Thread
  b. send to this worker
  c. _onWorkerInitialized received data from created sub worker channel of this thread and sending each shared array buffer channels (SABCs)
  d. SABCs will be Arrayed inside shared-buffer-worklet-processor.js
  e. SABCs should be also arrayed inside the signal worker so it can be posted from signal worker to UI Thread (flutter)
  f. _onWorkerInitialized will also send the data processed to the signal worker also for that particular channel
*/


/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

/**
 * The AudioWorkletNode that has a DedicatedWorker as a backend. The
 * communication between Worker and AWP is done via SharedArrayBuffer,
 * which runs like a big ring buffer between two objects. This class is to
 * demonstrate a design of using Worker, SharedArrayBuffer and the AudioWorklet
 * system in one place.
 *
 * In order to use this class, you need 3 files:
 *  - shared-buffer-worklet-node.js (main scope)
 *  - shared-buffer-worklet-processor.js (via `audioWorklet.addModule()` call)
 *  - shared-buffer-worker.js (via `new Worker()` call)
 *
 * @class SharedBufferWorkletNode
 * @extends AudioWorkletNode
 */



const PROCESSOR_STATE = {
  STATUS : 0
};
const STATE = {
  'REQUEST_RENDER': 0,
  'IB_FRAMES_AVAILABLE': 1,
  'IB_READ_INDEX': 2,
  'IB_WRITE_INDEX': 3,
  'OB_FRAMES_AVAILABLE': 4,
  'OB_READ_INDEX': 5,
  'OB_WRITE_INDEX': 6,
  'RING_BUFFER_LENGTH': 7,
  'KERNEL_LENGTH': 8,
  'REQUEST_SIGNAL_REFORM': 9,
  'REQUEST_WRITE_FILE': 10,
  'REQUEST_CLOSE_FILE': 11,  
  'OPEN_FILE_REDRAW':12,
  'THRESHOLD_PAUSE':13,
};

const CONFIG = {
  bytesPerState: Int32Array.BYTES_PER_ELEMENT,
  bytesPerSample: Int16Array.BYTES_PER_ELEMENT,
  stateBufferLength: 16,
  ringBufferLength: 4096,
  kernelLength: 1024,
  channelCount: 1,
  waitTimeOut: 25000,
};



let globalPositionCap = 0;
let eventsCounterInt;
let eventsInt;
let eventsIdxInt;
let eventPositionInt;
let eventPositionResultInt;
let eventGlobalPositionInt;
let eventGlobalHeaderInt;
let eventGlobalNumberInt;
let drawState;
let Module;

let sharedFileContainer = new SharedArrayBuffer(1024 * 2*2 * Int16Array.BYTES_PER_ELEMENT);// *2 to make it easier to access
let sharedFileContainerResult = new SharedArrayBuffer(1024 * 2*2 * Int16Array.BYTES_PER_ELEMENT);
let sharedFileContainerStatus = new SharedArrayBuffer(10 * Int32Array.BYTES_PER_ELEMENT);// *2 to make it easier to access


class SharedBufferWorkletNode // eslint-disable-line no-unused-vars
 extends AudioWorkletNode {
  /**
  * @constructor
  * @param {BaseAudioContext} context The associated BaseAudioContext.
  * @param {AudioWorkletNodeOptions} options User-supplied options for
  * AudioWorkletNode.
  * @param {object} options.worker Options for worker processor.
  * @param {number} options.worker.ringBufferLength Ring buffer length of
  * worker processor.
  * @param {number} options.worker.channelCount Channel count of worker
  * processor.
  */
  constructor(context, options) {
    super(context, 'shared-buffer-worklet-processor', options);

    // START for instantiating workers
    let c = 0;

    this._workers = [];
    this._fileHandle;
    

    this._workerOptions = (options && options.worker)
      ? options.worker
      : {ringBufferLength: 3072, channelIdx : c , channelCount: options.channelCount};

    let sampleRate = this._workerOptions.sampleRate;
    this.fileSab = [new SharedArrayBuffer(sampleRate*10*Int16Array.BYTES_PER_ELEMENT), new SharedArrayBuffer(sampleRate*10*Int16Array.BYTES_PER_ELEMENT)];

    // Worker backend.
    let _worker = new Worker('build/web/ProcessThread.js');

    // This node is a messaging hub for the Worker and AWP. After the initial
    // setup, the message passing between the worker and the process are rarely
    // necessary because of the SharedArrayBuffer.
    _worker.onmessage = this._onWorkerInitialized.bind(this);
    this._workers.push(_worker);

    this.port.onmessage = this._onProcessorInitialized.bind(this);
    


    // Initialize the worker.
    if (this._workerOptions.module !== undefined){
      Module = this._workerOptions.module;
    }
    const workerOptions1 = {
      deviceType : "audio",
      ringBufferLength: this._workerOptions.ringBufferLength,
      channelCount: this._workerOptions.channelCount,
      fileSab : this.fileSab,
      sampleRate : sampleRate,
      sabDraw : this._workerOptions.sabDraw,
      sharedFileContainer : sharedFileContainer,
      sharedFileContainerResult : sharedFileContainerResult,
      sharedFileContainerStatus : sharedFileContainerStatus,
      arrCounts:this._workerOptions.arrCounts,
      module:this._workerOptions.module,
    };
    console.log("ARR COUNTS : ", sampleRate, this._workerOptions.arrCounts);
    if (this._workerOptions.directAction !== undefined){
      workerOptions1['directAction'] = 'directLoad';
    }
    _worker.postMessage({
      message: 'INITIALIZE_WORKER',
      options: workerOptions1
    });

    
    // END for instantiating workers

    // Initialize signal worker to be embedded inside SABCs workerChannels
    // It will be used in 
    this.sabcs = [];
    this.signalWorker = this._workerOptions.signalWorker;
    this.signalWorker.postMessage({
      command: 'initialize_drawing',
      channelCount: this._workerOptions.channelCount,
    });

    this.fileWorker = this._workerOptions.fileWorker;

  }
  
  clearThresholdPause(){
    const States = new Int32Array(this.sabcs[0].states);
    States[STATE.THRESHOLD_PAUSE] = 0;
    const States1 = new Int32Array(this.sabcs[1].states);
    States1[STATE.THRESHOLD_PAUSE] = 0;

  }
  redraw(isThresholding){
    try{

      // for (let c = 0; c< 2; c++){
      //   let drawState = new Int32Array(this._workerOptions.sabDraw.draw_states[c]);
      //   if (isThresholding){
      //     if (drawState[DRAW_STATE.IS_THRESHOLDING] >= 1){
      //       const thresholdEnvelope = ( new Int16Array(this.sabcs[c].sabThresholdEnvelopes[drawState[DRAW_STATE.LEVEL]]) );
      //       const sampleNeeded = thresholdEnvelope.length;
      //       const temp = Module.getSamplesThresholdProcess(
      //         c, new Int16Array(1), drawState[DRAW_STATE.LEVEL], drawState[DRAW_STATE.DIVIDER] / 10, drawState[DRAW_STATE.CURRENT_START], sampleNeeded);
      //       // allEnvelopesThreshold[c][drawState[DRAW_STATE.LEVEL]].set(temp);  
      //       // allSabThresholdEnvelopes.push(sabThresholdEnvelopes);
      //       thresholdEnvelope.set(temp);
      //     }
      //   }  
      // }
      const StatesDraw = new Int32Array(this.sabcs[0].statesDraw);
      if (isThresholding){
        const States = new Int32Array(this.sabcs[0].states);
        States[STATE.THRESHOLD_PAUSE] = 1;
        if (this.sabcs.length>1){
          const States1 = new Int32Array(this.sabcs[1].states);
          States1[STATE.THRESHOLD_PAUSE] = 1;
          Atomics.notify(States1, STATE.REQUEST_RENDER, 1);

        }
        Atomics.notify(States, STATE.REQUEST_RENDER, 1);

        // let _worker = this._workers[0];
        // _worker.postMessage({
        //   message: 'REDRAW',
        // });
    
      }else{
        Atomics.notify(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 1);
        if (this.sabcs[1] !== undefined){
          const StatesDraw2 = new Int32Array(this.sabcs[1].statesDraw);
          Atomics.notify(StatesDraw2, STATE.REQUEST_SIGNAL_REFORM, 1);
    
        }
      }

  
    }catch(err){
      console.log("Audio redraw", err);
    }
  }

  pauseResumeProcessor(isPlaying){
  }

  closeProcessor(){
  }


  /**
   * Push 128 samples to the shared input buffer.
   *
   * @param {Int32Array} inputChannelData The input data.
   */
   _pushInputChannelData(channelIdx, inputChannelData) {
    let inputWriteIndex = this._states[channelIdx][STATE.IB_WRITE_INDEX];

    if (inputWriteIndex + inputChannelData.length < this._ringBufferLength[channelIdx]) {
      // If the ring buffer has enough space to push the input.
      this._inputRingBuffer[channelIdx].set(inputChannelData, inputWriteIndex);
      this._states[channelIdx][STATE.IB_WRITE_INDEX] += inputChannelData.length;
    } else {
      // When the ring buffer does not have enough space so the index needs to
      // be wrapped around.
      let splitIndex = this._ringBufferLength[channelIdx] - inputWriteIndex;
      let firstHalf = inputChannelData.subarray(0, splitIndex);
      let secondHalf = inputChannelData.subarray(splitIndex);
      this._inputRingBuffer[channelIdx].set(firstHalf, inputWriteIndex);
      this._inputRingBuffer[channelIdx].set(secondHalf);
      this._states[channelIdx][STATE.IB_WRITE_INDEX] = secondHalf.length;
    }

    // Update the number of available frames in the input ring buffer.
    this._states[channelIdx][STATE.IB_FRAMES_AVAILABLE] += inputChannelData.length;
  }  

  async loadMarkers(wav, markers, sampleRate, sabDraw, channels){
    const channelLength = channels;
    const tabSeparator = String.fromCharCode(9);
    const SIZE = 60 * sampleRate; // = 60 seconds
    const drawState = new Int32Array(sabDraw.draw_states[0]);

    this._states = [];
    this._inputRingBuffer = [];
    let startingIdx = [];
    this._ringBufferLength = [];

    eventsCounterInt = new Uint8Array(sabDraw.eventsCounter);
    eventPositionInt = new Uint32Array(sabDraw.eventPosition);
    eventPositionResultInt = new Float32Array(sabDraw.eventPositionResult);
    eventsInt = new Uint8Array(sabDraw.events);

    eventsCounterInt.fill(0);
    eventsCounterInt[0] = 0;
    drawState[DRAW_STATE.EVENT_COUNTER] = 0;
    // eventPositionInt.fill(0);
    // eventPositionResultInt.fill(0);
    // eventsInt.fill(0);


    for (let i = 0 ; i < channelLength ; i++){
      const sabcs = this.sabcs[i];
      
      let _state = new Int32Array(sabcs.states);      
      this._states.push(_state);
      let inputBuffer = new Int16Array(sabcs.inputRingBuffer);
      this._inputRingBuffer.push(inputBuffer);
      this._ringBufferLength.push(4096);

      startingIdx.push(0);

    }
      


    for (let i = 0; i < markers.length; i++){
      let arrMarker = markers[i].split(","+tabSeparator);
      const number = parseInt(arrMarker[0]);
      const time = parseFloat(arrMarker[1]);
      const timePosition = Math.floor(SIZE / (60/time)); // SIZE(60s)/ (60s/10s)


      if (drawState){
        // console.log(drawState);
        const sabcs = this.sabcs[0];
        let ctr = drawState[DRAW_STATE.EVENT_COUNTER];

        const eventsIdxInt = new Uint32Array(sabcs.eventsIdx);
        eventsIdxInt[ctr] = number;
        const eventGlobalPositionInt = new Uint32Array(sabcs.eventGlobalPosition);
        eventGlobalPositionInt[ctr] = timePosition;
  
        eventsInt[ctr] = number;
        // eventPositionInt[ctr] = timePosition;
        const globalMultiplierPositionCap = Math.floor(timePosition/SIZE) * SIZE;
        eventPositionInt[ctr] = timePosition - globalMultiplierPositionCap;
        
        ctr++;
        if ( ctr >= 200){
          ctr=ctr % 200;
          eventsCounterInt.fill(0);
          eventsInt.fill(0);
          eventPositionInt.fill(0);
          // eventsPositionResultInt.fill(0);        
        }
        // ctr = (ctr + 1) % 200;
        eventsCounterInt[0]=ctr;

        drawState[DRAW_STATE.EVENT_COUNTER] = ctr;
        drawState[DRAW_STATE.EVENT_FLAG] = 0;

    
      }
      
    }
    // console.log("LOAD MARKERS  :  ",eventsCounterInt,eventsInt, eventPositionInt, eventPositionResultInt);

  }

  processAudioKernel(States, MyConfig, InputRingBuffer, skipCounts, envelopes, arrMaxInt, SIZE, channelIdx, StatesDraw, sabcs) {
    const _sabcs = sabcs[channelIdx];
    const arrHeadsInt = new Uint32Array(_sabcs.arrHeads);
    const arrOffsetHeadInt = new Uint32Array(_sabcs.arrOffsetHead);

    const SINGLE_SCREEN_SAMPLE = 6;
    let _head = 0;
    let offsetHead = 0;
    // let _head = MyConfig[0];
    let inputReadIndex = States[STATE.IB_READ_INDEX];
    let outputWriteIndex = States[STATE.OB_WRITE_INDEX];
    const SIZE_LOGS2 = 10;
    let isFull = false;

  
    
    let sample;
    let i = 0;
    let j;
    let currentDataHead = MyConfig[2];
    let currentDataTail = MyConfig[3];
  
  
    for (; i < InputRingBuffer.length; i++) {
      sample = InputRingBuffer[i];
  
      const thead = _head % SIZE;
      for (j = 0; j < SIZE_LOGS2; j++){
        const skipCount = skipCounts[j];
        const envelopeSampleIndex = Math.floor( thead / skipCount );
        const interleavedSignalIdx = envelopeSampleIndex * 2; 
        if (thead % skipCount == 0){
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
  
      const interleavedHeadSignalIdx = thead * 2;
      arrMaxInt[interleavedHeadSignalIdx] = sample;
      arrMaxInt[interleavedHeadSignalIdx + 1] = sample;
  
      _head++;
      offsetHead++;
      if (_head == SIZE){
        console.log("HEADSSS RESET");
        const temp = Math.floor(_head / SIZE);
        // _head = 0;     
        isFull = true;
        if (channelIdx == 0) {
          globalPositionCap = temp;
        }
      }     
  
    }
    MyConfig[5] = MyConfig[0] + _head <= SIZE / SINGLE_SCREEN_SAMPLE ? 0 : MyConfig[0] < 0 ? 0 : MyConfig[0];
    MyConfig[0] = _head;    
    arrHeadsInt[channelIdx] = _head;
    arrOffsetHeadInt[channelIdx] = arrOffsetHeadInt[channelIdx] + offsetHead;
    MyConfig[7] = MyConfig[7] + offsetHead;    
    MyConfig[1] = Math.floor(_head / SIZE);
    // MyConfig[3] = currentDataHead;

    // console.log("_head : ",_head, envelopes);
    
  
    Atomics.notify(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 1);
  
       
  }
  

  async loadAudioBuffer(wav, markers, sampleRate, sabDraw, channels, startPos = -1, endPos = -1){
    globalPositionCap = 0;
    const channelLength = channels;
    const tabSeparator = String.fromCharCode(9);
    const SIZE = 60 * sampleRate; // = 60 seconds
    const drawState = new Int32Array(sabDraw.draw_states[0]);

    this._states = [];
    this._inputRingBuffer = [];
    let startingIdx = [];
    this._ringBufferLength = [];
    console.log("Load Audio Buffer markers.length : ",markers.length);

    this.loadMarkers(wav,markers,sampleRate,sabDraw,channels);

    // for (let i = 0 ; i < channelLength ; i++){
    //   const sabcs = this.sabcs[i];
      
    //   let _state = new Int32Array(sabcs.states);      
    //   this._states.push(_state);
    //   let inputBuffer = new Int16Array(sabcs.inputRingBuffer);
    //   this._inputRingBuffer.push(inputBuffer);
    //   this._ringBufferLength.push(4096);

    //   startingIdx.push(0);

    // }
      
    // eventsCounterInt = new Uint8Array(sabDraw.eventsCounter);
    // eventPositionInt = new Uint32Array(sabDraw.eventPosition);
    // eventPositionResultInt = new Int16Array(sabDraw.eventPositionResult);
    // eventsInt = new Uint8Array(sabDraw.events);


    // for (let i = 0; i < markers.length; i++){
    //   let arrMarker = markers[i].split(","+tabSeparator);
    //   const number = parseInt(arrMarker[0]);
    //   const time = parseFloat(arrMarker[1]);
    //   const timePosition = SIZE / (60/time); // SIZE(60s)/ (60s/10s)


    //   if (drawState){
    //     // console.log(drawState);
    //     const sabcs = this.sabcs[0];
    //     let ctr = drawState[DRAW_STATE.EVENT_COUNTER];

    //     const eventsIdxInt = new Uint32Array(sabcs.eventsIdx);
    //     eventsIdxInt[ctr] = number;
    //     const eventGlobalPositionInt = new Uint32Array(sabcs.eventGlobalPosition);
    //     eventGlobalPositionInt[ctr] = timePosition;
  
    //     eventsInt[ctr] = number;
    //     eventPositionInt[ctr] = timePosition;
        
    //     ctr++;
    //     if ( ctr >= 200){
    //       ctr=ctr % 200;
    //       eventsCounterInt.fill(0);
    //       eventsInt.fill(0);
    //       eventPositionInt.fill(0);
    //       // eventsPositionResultInt.fill(0);        
    //     }
    //     // ctr = (ctr + 1) % 200;
    //     eventsCounterInt[0]=ctr;

    //     drawState[DRAW_STATE.EVENT_COUNTER] = ctr;
    //     drawState[DRAW_STATE.EVENT_FLAG] = 0;

    
    //   }
      
    // }
    // let counter = 512;
    var arrCounts = [ 4, 8, 16, 32, 64, 128, 256,512,1024, 2048 ];
    var skipCounts = new Uint32Array(arrCounts);
    const SIZE_LOGS2 = 10;
    // let arrMaxInt = new Int16Array(SIZE*2*CONFIG.bytesPerSample);
    
    
    // processKernel(States, MyConfig, InputRingBuffer, skipCounts, envelopes, arrMaxInt) {
    for (let c = 0 ; c < channelLength ; c++){
      const sabcs = this.sabcs[c];
      const arrHeadsInt = new Uint32Array(sabcs.arrHeads);
      const arrIsFullInt = new Uint32Array(sabcs.arrIsFull);
      let States = new Int32Array(sabcs.states);
      let MyConfig = new Int32Array(sabcs.config);
      MyConfig[0]=0; // POSITION IN THE SCROLLBAR
      MyConfig[5]=0;
      MyConfig[7]=0; // POSITION IN THE BUFFER
      
      const arrOffsetHeadInt = new Uint32Array(sabcs.arrOffsetHead);      
      arrOffsetHeadInt[c] = 0;

      let envelopes = [];
      for (let l = 0; l < SIZE_LOGS2; l++){
        envelopes.push(new Int16Array(sabcs.sabEnvelopes[l]));
      }
      let arrMaxInt = new Int16Array(sabcs.arrMax);
      // fill wav
      // calculate marker in glbal position
      // redraw
      // const eventGlobalHeaderInt = new Uint32Array(sabcs.eventGlobalHeader);
      // eventGlobalHeaderInt[0] = Math.floor( i / SIZE);

      const samples = wav[10+c];
      let samplesLength = samples.length;
      let startSamples = 0;
      let endSamples = samples.length;
      if (startPos != -1 && endPos != -1){
        startSamples = startPos;
        endSamples = endPos;
        samplesLength = endSamples - startSamples;
        console.log("POS SAMPLES : ",startSamples, endSamples);
        // _head = MyConfig[0]; change head
        MyConfig[7] = startPos;
        MyConfig[1] = Math.floor(startPos / SIZE);
        globalPositionCap = Math.floor(startPos / SIZE);

        arrHeadsInt[c] = 0;
        arrOffsetHeadInt[c] = startPos;
        arrIsFullInt[c] = Math.floor(startPos / SIZE);

      }
      let remainder = samples.length - SIZE;
      let j = 0;
      // const _states = this._states[c];
      let arrRawInt = new Int16Array(samplesLength);
      const sampled = samples.subarray(startSamples, endSamples);
      // console.log(sampled);
      arrRawInt.set(sampled,0);

      // if (remainder<0){
      //   arrRawInt.set(samples.subarray(0, samples.length),0);
      //   console.log("REMAINDER < 0", arrRawInt, samples.length);
      // }else{
      //   arrRawInt.set(samples.subarray(remainder, SIZE),0);
      // }
      const StatesDraw =  new Int32Array(sabcs.statesDraw);
      // console.log( "(new Date()).getTime()" );
      // console.log( (new Date()).getTime() );
      this.processAudioKernel(States, MyConfig, arrRawInt , skipCounts, envelopes, arrMaxInt, SIZE, c, StatesDraw, this.sabcs);
      // console.log( (new Date()).getTime() );

      // do{
      //   remainder -= counter;
      //   if (remainder < 0){
      //     counter = remainder+counter;
      //   }
      //   this._pushInputChannelData(c,samples.subarray(startingIdx[c],startingIdx[c]+counter));
      //   startingIdx[c]+=counter;
      //   j+=counter;
      //   // console.log(remainder, _states[STATE.IB_FRAMES_AVAILABLE] , _states[STATE.KERNEL_LENGTH], _states[STATE.IB_FRAMES_AVAILABLE] >= _states[STATE.KERNEL_LENGTH]);
      //   if (_states[STATE.IB_FRAMES_AVAILABLE] >= _states[STATE.KERNEL_LENGTH] ) {
      //     if (remainder-counter <= 0){
      //       _states[STATE.OPEN_FILE_REDRAW] = 0;
      //     }else{
      //       _states[STATE.OPEN_FILE_REDRAW] = 0;

      //     }
      //     Atomics.notify(_states, STATE.REQUEST_RENDER, 1);
      //     // await this.sleep(100);
      //   }else
      //   if (remainder == counter){
      //     Atomics.notify(_states, STATE.REQUEST_RENDER, 1);
      //   }
          
      // }while(j<samples.length);
      // console.log("doneloading");

      

    }
    console.log("LOAD BUFFER");

  }
  
  sleep(time) {
    return new Promise((resolve) => setTimeout(resolve, Math.ceil(time * 1)));
  }

  async clearSamples(i){
    const sabcs = this.sabcs[i];
    let _states = new Int32Array(sabcs.states);
    _states.fill(0);
    Atomics.store(_states, STATE.RING_BUFFER_LENGTH, CONFIG.ringBufferLength);
    Atomics.store(_states, STATE.KERNEL_LENGTH, CONFIG.kernelLength);
  
    let _config = new Int32Array(sabcs.config);
    _config.fill(0);
    _config[2]=-1;

    const inputRingBufferInt = new Int16Array(sabcs.inputRingBuffer);
    inputRingBufferInt.fill(0);
    const arrMaxInt = new Int16Array(sabcs.arrMax);
    arrMaxInt.fill(0);
    for (let ctr =0; ctr < sabcs.sabEnvelopes.length ; ctr++){
      const sabEnvelope = sabcs.sabEnvelopes[ctr];
      const sabEnvelopesInt = new Int16Array(sabEnvelope);
      sabEnvelopesInt.fill(0);

    }


    const eventGlobalPositionInt = new Uint32Array(sabcs.eventGlobalPosition);
    eventGlobalPositionInt.fill(0);
    const eventGlobalNumberInt = new Uint8Array(sabcs.eventGlobalNumber);
    eventGlobalNumberInt.fill(0);
    const eventGlobalHeaderInt = new Uint32Array(sabcs.eventGlobalHeader);
    eventGlobalHeaderInt.fill(0);
    const eventsIdxInt = new Uint32Array(sabcs.eventsIdx);
    eventsIdxInt.fill(0);
    const globalPositionCapInt = new Uint8Array(sabcs.globalPositionCap);
    globalPositionCapInt.fill(0);
  }


  async clearBuffer(){
    const channelLength = this.sabcs.length;

    for (let i = 0 ; i < channelLength ; i++){
      const sabcs = this.sabcs[i];
      let _states = new Int32Array(sabcs.states);
      _states.fill(0);
      Atomics.store(_states, STATE.RING_BUFFER_LENGTH, CONFIG.ringBufferLength);
      Atomics.store(_states, STATE.KERNEL_LENGTH, CONFIG.kernelLength);
    
      let _config = new Int32Array(sabcs.config);
      _config.fill(0);
      _config[2]=-1;

      const inputRingBufferInt = new Int16Array(sabcs.inputRingBuffer);
      inputRingBufferInt.fill(0);
      const arrMaxInt = new Int16Array(sabcs.arrMax);
      arrMaxInt.fill(0);
      for (let ctr =0; ctr < sabcs.sabEnvelopes.length ; ctr++){
        const sabEnvelope = sabcs.sabEnvelopes[ctr];
        const sabEnvelopesInt = new Int16Array(sabEnvelope);
        sabEnvelopesInt.fill(0);
  
      }


      const eventGlobalPositionInt = new Uint32Array(sabcs.eventGlobalPosition);
      eventGlobalPositionInt.fill(0);
      const eventGlobalNumberInt = new Uint8Array(sabcs.eventGlobalNumber);
      eventGlobalNumberInt.fill(0);
      const eventGlobalHeaderInt = new Uint32Array(sabcs.eventGlobalHeader);
      eventGlobalHeaderInt.fill(0);
      const eventsIdxInt = new Uint32Array(sabcs.eventsIdx);
      eventsIdxInt.fill(0);
      const globalPositionCapInt = new Uint8Array(sabcs.globalPositionCap);
      globalPositionCapInt.fill(0);

    }

  }
  
  terminateAll(){
    try{
      this._workers[0].terminate();
    }catch(err){
      console.log("ERR : ",err);
    }

    try{
      this._workers[1].terminate();
    }catch(err){
      console.log("ERR : ",err);
    }


    try{
      this.signalWorker.terminate();
    }catch(err){
      console.log("ERR SIGNAL : ",err);
    }

    try{
      this.fileWorker.terminate();
    }catch(err){
      console.log("ERR FILE : ",err);
    }
  }

  /**
  * Handles the initial event from the associated worker.
  *
  * @param {Event} eventFromWorker
  */
  _onWorkerInitialized(eventFromWorker) {
    const data = eventFromWorker.data;
    if (data.message === 'WORKER_READY') {
      // Send SharedArrayBuffers to the processor.
      // push the sharedBuffers to array
      this.sabcs.push( data.SharedBuffers );
      this.sabcs.push( data.SharedBuffers2 );

      console.log("TEST " , this.sabcs.length , this._workerOptions.channelCount);

      if (this._workerOptions.directAction === undefined){
        this.port.postMessage({message:'init',sabcs:this.sabcs, sabDraw: this._workerOptions.sabDraw});
      }else{
        this.port.postMessage({message:'init',sabcs:this.sabcs,directAction:'directLoad', sabDraw:this._workerOptions.sabDraw});
      }


      this.signalWorker.postMessage( {
        command:"sabcs",
        rawSabcs:this.sabcs
      } );
      console.log("NODE : ", this.sabcs);
      if (this._workerOptions.action !== undefined && this._workerOptions.action == 'playback'){

      }else{
        try{
          this.fileWorker.postMessage( {
            command:"sabcs",
            rawSabcs:this.sabcs,
            sabDraw : this._workerOptions.sabDraw,
            sharedFileContainer : sharedFileContainer,
            sharedFileContainerResult : sharedFileContainerResult,
            sharedFileContainerStatus : sharedFileContainerStatus,
          } );  
        }catch(err){
          console.log("err");
          console.log(err);
        }
      }

      return;
    }

    console.log('[SharedBufferWorklet] Unknown message: ',
                eventFromWorker);
  }

  /**
  * Handles the initial event form the associated processor.
  *
  * @param {Event} eventFromProcessor
  */
  _onProcessorInitialized(eventFromProcessor) {
    const data = eventFromProcessor.data;
    if (data.message === 'PROCESSOR_READY' &&
        typeof this.onInitialized === 'function') {
      this.onInitialized();
      return;
    }

    console.log('[SharedBufferWorklet] Unknown message: ',
                eventFromProcessor);
  }
} // class SharedBufferWorkletNode


export default SharedBufferWorkletNode;
