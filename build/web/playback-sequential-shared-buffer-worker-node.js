const PROCESSOR_STATE = {
  STATUS : 0
};

const STATE = {
  'REQUEST_SIGNAL_REFORM': 9,
};


const PROCESSOR_CONFIG = {
  bytesPerState: Int32Array.BYTES_PER_ELEMENT,
  bytesPerSample: Int16Array.BYTES_PER_ELEMENT,
  rawBytesPerSample: Uint8Array.BYTES_PER_ELEMENT,
  stateBufferLength: 32,
  ringBufferLength: 4154 * 2,
  kernelLength: 992 * 2,
  channelCount: 1,
  waitTimeOut: 25000,
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

const PROCESSOR_BUFFER_STATE = {
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







let vm = this;
var arrCounts = [ 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048 ];
var skipCounts = new Uint32Array(arrCounts);
var isFull = false;


const SIZE_LOGS2 = 10;
var _head = 0;
var offsetHead = 0;
var _tail = 0;
var _arrHeadsInt;
var _arrTailsInt;
var _arrOffsetHeadInt;

var _arrIsFullInt;

let arrMaxInt;
let arrMaxInt1;
let arrMaxInt2;
let arrMaxInt3;
let arrMaxInt4;
let arrMaxInt5;
let arrMaxInt6;


// let envelopes = new Int16Array(sabcs.sabEnvelopes);
let envelopes;    
let envelopes1 = [];
let envelopes2 = [];
let envelopes3 = [];
let envelopes4 = [];
let envelopes5 = [];
let envelopes6 = [];




class SequentialSharedBufferWorkerNode // eslint-disable-line no-unused-vars
extends AudioWorkletNode 
  {

  constructor(context, options) {
    super(context, 'playback-sequential-shared-buffer-worklet-processor', options);
      this.deviceId = "";
    // super(context, 'sequential-shared-buffer-worker-processor', options);

    this._workerOptions = (options && options.worker)
      ? options.worker
      : {ringBufferLength: 3072, channelCount: 1};

    this._worker = new Worker('build/web/playback-sequential-shared-buffer-worker.js');

    this._worker.onmessage = this._onWorkerInitialized.bind(this);

    if (this._workerOptions.deviceType === undefined && this._workerOptions.directAction === undefined){
      this.processorSab = new SharedArrayBuffer(Object.keys(PROCESSOR_STATE).length * Int32Array.BYTES_PER_ELEMENT);    
      this._processorWorker = new Worker('build/web/playback-sequential-shared-buffer-worker-processor.js');
  
      console.log("this._workerOptions");
      console.log(this._workerOptions);
      this._processorMessageChannel = new MessageChannel();
      this._processorMessageChannel.port2.onmessage = this._onProcessorInitialized.bind(this);
  
    }else{
      // this.onInitialized();
    }

  

    // Initialize the worker.
    this._worker.postMessage({
      message: 'INITIALIZE_WORKER',
      options: {
        ringBufferLength: this._workerOptions.ringBufferLength,
        channelCount: this._workerOptions.channelCount,
        deviceType : this._workerOptions.deviceType,
        sabDraw : this._workerOptions.sabDraw,
        sampleRate : this._workerOptions.sampleRate,
      },
    });
    this.signalWorker = options.worker.signalWorker;
    this.fileWorker = options.worker.fileWorker;

  }

  redraw(){
    try{
      const StatesDraw = new Int32Array(this.sabcs[0].statesDraw);
      Atomics.notify(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 1);
    }catch(err){
      console.log(err);
    }

  }

  pauseResumeProcessor(isPlaying){
    if (isPlaying == 2){
      (new Int32Array(this.processorSab))[PROCESSOR_STATE.STATUS] = 2;
    }else{
      (new Int32Array(this.processorSab))[PROCESSOR_STATE.STATUS] = 0;
    }

  }


  closeProcessor(){
    (new Int32Array(this.processorSab))[PROCESSOR_STATE.STATUS] = 1;
    this._processorWorker.terminate();
    (new Int32Array(this.processorSab))[PROCESSOR_STATE.STATUS] = 0;
  }

  
  terminateAll(){
    try{
      this._worker.terminate();
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


  async loadMarkers(wav, markers, sampleRate, sabDraw, channels, multiplier = 1){
    const channelLength = channels;
    const tabSeparator = String.fromCharCode(9);
    const SIZE = 60 * sampleRate; // = 60 seconds
    const drawState = new Int32Array(sabDraw.draw_states[0]);

    this._states = [];
    this._inputRingBuffer = [];
    let startingIdx = [];
    this._ringBufferLength = [];

    for (let i = 0 ; i < channelLength ; i++){
      const sabcs = this.sabcs[0];
      
      let _state = new Int32Array(sabcs.states);      
      this._states.push(_state);
      let inputBuffer = new Int16Array(sabcs.inputRingBuffer[i]);
      this._inputRingBuffer.push(inputBuffer);
      this._ringBufferLength.push(4096);

      startingIdx.push(0);

    }

    let eventsCounterInt;
    let eventsInt;
    let eventPositionInt;
    let eventPositionResultInt;
    
      
    eventsCounterInt = new Uint8Array(sabDraw.eventsCounter);
    eventPositionInt = new Uint32Array(sabDraw.eventPosition);
    eventPositionResultInt = new Float32Array(sabDraw.eventPositionResult);
    eventsInt = new Uint8Array(sabDraw.events);
    eventsCounterInt.fill(0);
    drawState[DRAW_STATE.EVENT_COUNTER] = 0;

    // eventPositionInt.fill(0);
    // eventPositionResultInt.fill(0);
    // eventsInt.fill(0);


    for (let i = 0; i < markers.length; i++){
      let arrMarker = markers[i].split(","+tabSeparator);
      const number = parseInt(arrMarker[0]);
      const time = parseFloat(arrMarker[1]);
      const timePosition = Math.floor(SIZE / (60/time) * multiplier); // SIZE(60s)/ (60s/10s)
      // console.log("time : ", i ,time, SIZE, timePosition);


      if (drawState){
        // console.log(drawState);
        const sabcs = this.sabcs[0];
        let ctr = drawState[DRAW_STATE.EVENT_COUNTER];

        const eventsIdxInt = new Uint32Array(sabcs.eventsIdx);
        eventsIdxInt[ctr] = number;
        const eventGlobalPositionInt = new Uint32Array(sabcs.eventGlobalPosition);
        eventGlobalPositionInt[ctr] = timePosition;
  
        eventsInt[ctr] = number;
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
    console.log(" eventPositionInt : ", eventPositionInt);
  }


  
  processSerialKernel(States, MyConfig, InputRingBuffer, skipCounts, envelopes, arrMaxInt, SIZE, channelIdx, StatesDraw, channelCount) {
    const SINGLE_SCREEN_SAMPLE = 6;
    let sample;
    _head = 0;
    offsetHead = _arrOffsetHeadInt[channelIdx];
    
    let numberOfParsedChannels = channelIdx + 1;
    // console.log("numberOfParsedChannels : ",numberOfParsedChannels);
    
    const numberOfChannels = channelCount;
    // it causing the error
    // if (this._workerOptions.deviceType =='hid'){
    //   // const drawState = new Int32Array(StatesDraw);
    //   // const drawState = StatesDraw;
    //   console.log("StatesDraw[DRAW_STATE.CHANNEL_COUNTS] : ", channelIdx);
    //   console.log("StatesDraw[DRAW_STATE.CHANNEL_COUNTS] : ", channelIdx, StatesDraw[DRAW_STATE.CHANNEL_COUNTS]);
    //   try{
    //     numberOfChannels = StatesDraw[DRAW_STATE.CHANNEL_COUNTS];
    //   }catch(exc){
    //     console.log("Number of channels ", exc);
    //   }
    // }  
  
    

    // const sabcs = this.sabcs[0];

    // console.log("sabcs",sabcs);

    

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

    // console.log("HEAD INT : ", _head, _arrHeadsInt);
    // try{

      for (let i=0; i < InputRingBuffer.length ; i++){
        const sample = -1 * InputRingBuffer[i];
        for (let j = 0; j < SIZE_LOGS2; j++){
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
        offsetHead++;
        if (_head == SIZE){
          _arrIsFullInt[numberOfParsedChannels-1] = Math.floor(_head / SIZE);
          // _head = 0;
          if (numberOfParsedChannels == 0) {
            globalPositionCap = _arrIsFullInt[numberOfParsedChannels-1];
          }
    
          isFull = true;
        }     
    
      }
    // }catch(err){
    //   console.log("ENVELOPER ERROR ", err);
    // }
    // MyConfig[5] = MyConfig[0] + _head <= SIZE / SINGLE_SCREEN_SAMPLE ? 0 : MyConfig[0] < 0 ? 0 : MyConfig[0];
    MyConfig[5] = 0;
    _arrHeadsInt[channelIdx] = _head;    
    _arrTailsInt[channelIdx] = offsetHead;
    _arrOffsetHeadInt[channelIdx] = offsetHead;
    _arrIsFullInt[channelIdx] = Math.floor(_arrHeadsInt[channelIdx] / SIZE);

    // const prevPosition = _arrTailsInt[channelIdx];
    // console.log("CHECK : ", prevPosition, _head - 1 , SIZE / SINGLE_SCREEN_SAMPLE);//CHECK :  384283 33329 33330
    // _arrHeadsInt[channelIdx] = prevPosition + _head - 1;  
    // _arrTailsInt[channelIdx] = prevPosition + _head - 1 <= SIZE / SINGLE_SCREEN_SAMPLE ? 0 : prevPosition < 0 ? 0 : prevPosition;
    // _arrIsFullInt[channelIdx] = Math.floor(_head / SIZE);

    // console.log("_arrHeadsInt : ", _head,_arrHeadsInt);
    // console.log("arrMaxInt : ", arrMaxInt1);
    // console.log("envelopes1 : ", envelopes1);
    // console.log("envelopes2 : ", envelopes2);
    // console.log("envelopes3 : ", envelopes3);
    // console.log("envelopes4 : ", envelopes4);
    // console.log("envelopes5 : ", envelopes5);
    // console.log("envelopes6 : ", envelopes6);


    Atomics.notify(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 1);

  }

  

  async loadSerialBuffer(wav, markers, sampleRate, sabDraw, channels, startPos, endPos){
    const channelLength = channels;
    const tabSeparator = String.fromCharCode(9);
    const SIZE = 60 * sampleRate; // = 60 seconds
    const drawState = new Int32Array(sabDraw.draw_states[0]);

    this._states = [];
    this._inputRingBuffer = [];
    let startingIdx = [];
    this._ringBufferLength = [];

    this.loadMarkers(wav,markers,sampleRate,sabDraw,channels);

    var arrCounts = [ 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048 ];
    var skipCounts = new Uint32Array(arrCounts);
    const SIZE_LOGS2 = 10;
    // let arrMaxInt = new Int16Array(SIZE*2*CONFIG.bytesPerSample);
    
    
    // processKernel(States, MyConfig, InputRingBuffer, skipCounts, envelopes, arrMaxInt) {
    for (let c = 0 ; c < channelLength ; c++){
      const sabcs = this.sabcs[0];
      let States = new Int32Array(sabcs.states[c]);
      let MyConfig = new Int32Array(sabcs.config);
      MyConfig[0]=0;
      MyConfig[5]=0;

      // arrMaxInt = new Int16Array(sabcs.arrMax);
      switch( c )
      {
        case 0:
          arrMaxInt1 = new Int16Array(sabcs.arrMax);
        break;
        case 1:
          arrMaxInt2 = new Int16Array(sabcs.arrMax2);
        break;
        case 2:
          arrMaxInt3 = new Int16Array(sabcs.arrMax3);
          break;
        case 3:
          arrMaxInt4 = new Int16Array(sabcs.arrMax4);
        break;
        case 4:
          arrMaxInt5 = new Int16Array(sabcs.arrMax5);
        break;
        case 5:
          arrMaxInt6 = new Int16Array(sabcs.arrMax6);
        break;
      }      
      // new Int16Array(sabcs.sabEnvelopes[4]).fill(1000);

      const samples = wav[10+c];
      let samplesLength = samples.length;
      let startSamples = 0;
      let endSamples = samples.length;
      if (startPos != -1 && endPos != -1){
        startSamples = startPos;
        endSamples = endPos;
        samplesLength = endSamples - startSamples;
        console.log("POS SERIAL SAMPLES : ",startSamples, endSamples);
        MyConfig[0] = 0;
        MyConfig[1] = Math.floor(startPos / SIZE);
        MyConfig[5] = 0;

        const arrHeadsInt = new Uint32Array(sabcs.arrHeads);
        arrHeadsInt[c] = 0;
        const arrTailsInt = new Uint32Array(sabcs.arrTails);
        arrTailsInt[c] = 0;
        const arrOffsetHeadInt = new Uint32Array(sabcs.arrOffsetHead);
        arrOffsetHeadInt[c] = startPos;
      }

      let remainder = samples.length - SIZE;
      let j = 0;
      // const _states = this._states[c];
      // const arrRawInt = new Int16Array(samples.length);
      // arrRawInt.set(samples,0);
      // console.log(JSON.stringify(arrRawInt));
      const arrRawInt = new Int16Array(samplesLength);
      const sampled = samples.subarray(startSamples, endSamples);
      arrRawInt.set(sampled,0);

      // if (remainder<0){
      //   arrRawInt.set(samples.subarray(0, samples.length),0);
      //   console.log("REMAINDER < 0", arrRawInt, samples.length);
      // }else{
      //   arrRawInt.set(samples.subarray(remainder, SIZE),0);
      // }
      // console.log("sabcs : ",sampled);
      // console.log("sabcs : ",sabcs.statesDraw);

      const StatesDraw =  new Int32Array(sabcs.statesDraw);
      let envelopes;
      // let arrMaxInt;

      this.processSerialKernel(States, MyConfig, arrRawInt , skipCounts, envelopes, arrMaxInt, SIZE, c, StatesDraw,channelLength);

    }
    console.log("LOAD BUFFER");

  }

  async clearBuffer(){
    if (this.sabcs === undefined) return;

    const sabcs = this.sabcs[0];
    if (sabcs === undefined) return;

    for (let c = 0; c<6 ; c++){
      this._states = new Int32Array(sabcs.states[c]);
      this._states.fill(0);
  
  
      if (this._workerOptions.deviceType === undefined){
        Atomics.store(this._states, PROCESSOR_BUFFER_STATE.RING_BUFFER_LENGTH, CONFIG.ringBufferLength);
        Atomics.store(this._states, PROCESSOR_BUFFER_STATE.KERNEL_LENGTH, CONFIG.kernelLength);
      }else{
        Atomics.store(this._states, PROCESSOR_BUFFER_STATE.RING_BUFFER_LENGTH, PROCESSOR_CONFIG.ringBufferLength);
        Atomics.store(this._states, PROCESSOR_BUFFER_STATE.KERNEL_LENGTH, PROCESSOR_CONFIG.kernelLength);
      }
    }

  
    let _config = new Int32Array(sabcs.config);
    _config.fill(0);
    _config[2]=-1;

    let c = 0;
    let CHANNEL_COUNT_FIX = 1;
    let envelopeSamples;


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
      
    const heads = new Uint32Array(sabcs.arrHeads);
    heads.fill(0);          
    return true;
  }

  _pushInputData =function (inputChannelData) {
    let inputWriteIndex = this._states[PROCESSOR_BUFFER_STATE.IB_WRITE_INDEX];
  
    if (inputWriteIndex + inputChannelData.length < this._ringBufferLength) {
      // If the ring buffer has enough space to push the input.
      this._inputRingBuffer[0].set(inputChannelData, inputWriteIndex);
      this._states[PROCESSOR_BUFFER_STATE.IB_WRITE_INDEX] += inputChannelData.length;
    } else {
      // When the ring buffer does not have enough space so the index needs to
      // be wrapped around.
      let splitIndex = this._ringBufferLength - inputWriteIndex;
      let firstHalf = inputChannelData.subarray(0, splitIndex);
      let secondHalf = inputChannelData.subarray(splitIndex);
      this._inputRingBuffer[0].set(firstHalf, inputWriteIndex);
      this._inputRingBuffer[0].set(secondHalf);
      this._states[PROCESSOR_BUFFER_STATE.IB_WRITE_INDEX] = secondHalf.length;
    }
    this._states[PROCESSOR_BUFFER_STATE.IB_FRAMES_AVAILABLE] += inputChannelData.length;
  }  

  processHidData(event){
    if (this.sabcs === undefined) return;

    const rawSabcs = this.sabcs[0];
    if (rawSabcs === undefined) return;

    if (this._workerOptions.directAction !== undefined) return;


    // productId: 1
    // productName: "SpikeRecorder"
    // vendorId: 11891



    const buffer = new Uint8Array(event.data.buffer);
    // console.log( "BUFFER : ", buffer.length, buffer[0] );

    // console.log("rawData.data : ", rawData);
    this._pushInputData( buffer.slice(1) );

    if (this._states[PROCESSOR_BUFFER_STATE.IB_FRAMES_AVAILABLE] >= this._kernelLength) {
      if (this._states[PROCESSOR_BUFFER_STATE.IB_FRAMES_AVAILABLE] > PROCESSOR_CONFIG.ringBufferLength){
        // console.log("this._states[PROCESSOR_BUFFER_STATE.IB_FRAMES_AVAILABLE] " , buffer.length, this._states[PROCESSOR_BUFFER_STATE.IB_FRAMES_AVAILABLE], this._states[PROCESSOR_BUFFER_STATE.IB_READ_INDEX]);
      }
      Atomics.notify(this._states, PROCESSOR_BUFFER_STATE.REQUEST_RENDER, 1);
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
      if (this._workerOptions.deviceType == 'hid'){
        // getHidDeviceInfo(this._workerOptions.reportId);
      }
      this.SharedBuffers = data.SharedBuffers;
    
      // Send SharedArrayBuffers to the processor.
      this.sabcs = [data.SharedBuffers];
      let sabcs = this.sabcs[0];

      if (this._workerOptions.directAction === undefined){
        this.port.postMessage({sabcs:this.sabcs, sabDraw: this._workerOptions.sabDraw, curSampleRate : this._workerOptions.curSampleRate,});
      }else{
        this.port.postMessage({sabcs:this.sabcs,directAction:'directLoad', sabDraw:this._workerOptions.sabDraw, curSampleRate : this._workerOptions.curSampleRate,});
      }
  
      // _arrIsFullInt = new Uint32Array(sabcs._arrIsFull);
      // _arrHeadsInt = new Uint32Array(sabcs._arrHeads);
      const SIZE_LOGS2 = 10;
      envelopes1=[];
      envelopes2=[];
      envelopes3=[];
      envelopes4=[];
      envelopes5=[];
      envelopes6=[];
      for (let l = 0 ; l < SIZE_LOGS2 ; l++){
        envelopes1.push( new Int16Array(sabcs.sabEnvelopes[l]) );
        envelopes2.push( new Int16Array(sabcs.sabEnvelopes2[l]) );
        envelopes3.push( new Int16Array(sabcs.sabEnvelopes3[l]) );
        envelopes4.push( new Int16Array(sabcs.sabEnvelopes4[l]) );
        envelopes5.push( new Int16Array(sabcs.sabEnvelopes5[l]) );
        envelopes6.push( new Int16Array(sabcs.sabEnvelopes6[l]) );
      }
  
      _arrHeadsInt = new Uint32Array(sabcs.arrHeads);
      _arrTailsInt = new Uint32Array(sabcs.arrTails);
      _arrOffsetHeadInt = new Uint32Array(sabcs.arrOffsetHead);
      _arrIsFullInt = new Int16Array(sabcs.arrIsFull);
      
      arrMaxInt = new Int16Array(sabcs.arrMax);
      arrMaxInt1 = new Int16Array(sabcs.arrMax1);
      arrMaxInt2 = new Int16Array(sabcs.arrMax2);
      arrMaxInt3 = new Int16Array(sabcs.arrMax3);
      arrMaxInt4 = new Int16Array(sabcs.arrMax4);
      arrMaxInt5 = new Int16Array(sabcs.arrMax5);
      arrMaxInt6 = new Int16Array(sabcs.arrMax6);      
  
      // let envelopes = new Int16Array(sabcs.sabEnvelopes);
  
  
      // this.port.postMessage(this.sabcs);
      if (this._workerOptions.deviceType === undefined && this._workerOptions.directAction === undefined ){
        this._processorWorker.postMessage({
          command:"connect",
          channelCount : this._workerOptions.channelCount,
          rawSabcs : this.sabcs,
          messageChannel : this._processorMessageChannel.port1,
          processorSab : this.processorSab,
          sabSerialWriteData : this._workerOptions.sabSerialWriteData,
        },[this._processorMessageChannel.port1]);
      }else{
        if (this._workerOptions.deviceType == 'hid'){
          console.log("INIT HID");
          const rawSabcs = this.sabcs[0];
          this._states = new Int32Array(rawSabcs.states);
          this._ringBufferLength = PROCESSOR_CONFIG.ringBufferLength;
          this._kernelLength = this._states[PROCESSOR_BUFFER_STATE.KERNEL_LENGTH];
          this._inputRingBuffer = [new Uint8Array(rawSabcs.inputRingBuffer)];
      
        }
        if (this._workerOptions.strDevice !== undefined){
          const strDevice = this._workerOptions.strDevice;
          this._deviceInfo = DEVICE_PRODUCT[strDevice];
          console.log("strDevice : ",strDevice,this._deviceInfo);
        }

        if (this._deviceInfo !== undefined){
          const sharedBuffers = this.SharedBuffers;
          let productIds = new Uint16Array(sharedBuffers.productId);
          productIds[0] = this._deviceInfo.productId;
          
          let maxSampleRate = new Uint16Array(sharedBuffers.maxSampleRate);
          maxSampleRate[0] = this._deviceInfo.maxSamplingRate;
        
          let minChannels = new Uint8Array(sharedBuffers.minChannels);
          minChannels[0] = this._deviceInfo.minChannels;
          let maxChannels = new Uint8Array(sharedBuffers.maxChannels);
          maxChannels[0] = this._deviceInfo.maxChannels;
        
          let sampleRates = new Uint16Array(sharedBuffers.sampleRates);
          const sampleRatesLength = this._deviceInfo.sampleRates.length;
          for (let i = 0 ; i < sampleRatesLength ; i++){
            sampleRates[i] = this._deviceInfo.sampleRates[i];
          }
        
          let channels = new Uint8Array(sharedBuffers.channels);
          const channelsLength = this._deviceInfo.channels.length;
          for (let i = 0 ; i < channelsLength ; i++){
            channels[i] = this._deviceInfo.channels[i];
          }
  
          let sabDrawing = this._workerOptions.sabDraw;
  
    
          for ( let c = 0; c< 6; c++){
            const drawState = new Int32Array(sabDrawing.draw_states[c]);
            
            drawState[DRAW_STATE.MAX_SAMPLING_RATE] = maxSampleRate[0];
      
            drawState[DRAW_STATE.MIN_CHANNELS] = minChannels[0];
            drawState[DRAW_STATE.MAX_CHANNELS] = maxChannels[0];
      
            // for (let idx = 0; idx <= maxChannels - minChannels ; idx++){
            for (let idx = 0; idx < maxChannels ; idx++){
              drawState[DRAW_STATE.SAMPLING_RATE_1 + idx] = sampleRates[idx];
            }  
          }
       
    
    
        }
      }
  
      this.signalWorker.postMessage( {
        command:"sabcs",
        channelCount : this._workerOptions.channelCount,
        rawSabcs:this.sabcs
      } );

      console.log("NODE : ", this.sabcs);
      try{
        this.fileWorker.postMessage( {
          command:"sabcs",
          sabDraw : this._workerOptions.sabDraw,
          channelCount : this._workerOptions.channelCount,
          rawSabcs:this.sabcs
        } );
      }catch(err){
        console.log(err);
      }


      if (this._workerOptions.directAction !== undefined){
        // const data = eventFromProcessor.data;
        // if (data.message === 'PROCESSOR_READY' &&
        //     typeof this.onInitialized === 'function') {
        const eventFromProcessor = {
          data:{
            message : 'PROCESSOR_READY',
          },
        };
        if (this._workerOptions.onInitialized !== undefined && typeof this._workerOptions.onInitialized === 'function'){
          this.onInitialized = this._workerOptions.onInitialized;
        }
        this._onProcessorInitialized(eventFromProcessor);
      
      }
  
      return;
    }

    if (data.message === 'WORKER_ERROR') {
      console.log('[SharedBufferWorklet] Worker Error:',
                  data.detail);
      if (typeof this.onError === 'function') {
        this.onError(data);
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
      
      this.deviceId = data.deviceId;
      let sabDrawing = this._workerOptions.sabDraw;

      if (this._workerOptions.directAction === undefined){
        const maxSampleRate = new Uint16Array(this.SharedBuffers.maxSampleRate);
        const minChannels = new Uint8Array(this.SharedBuffers.minChannels);
        const maxChannels = new Uint8Array(this.SharedBuffers.maxChannels);
        const sampleRates = new Uint16Array(this.SharedBuffers.sampleRates);
  
        for ( let c = 0; c< 6; c++){
          const drawState = new Int32Array(sabDrawing.draw_states[c]);
          
          drawState[DRAW_STATE.MAX_SAMPLING_RATE] = maxSampleRate[0];
    
          drawState[DRAW_STATE.MIN_CHANNELS] = minChannels[0];
          drawState[DRAW_STATE.MAX_CHANNELS] = maxChannels[0];
    
          // for (let idx = 0; idx <= maxChannels - minChannels ; idx++){
          for (let idx = 0; idx < maxChannels ; idx++){
            drawState[DRAW_STATE.SAMPLING_RATE_1 + idx] = sampleRates[idx];
          }  
        }
        // drawState[DRAW_STATE.SAMPLE_RATE] = drawState[DRAW_STATE.SAMPLING_RATE_1 + minChannels];

      }

   

      this.onInitialized();
      return;
    }

    console.log('[SharedBufferWorklet] Unknown message: ',
                eventFromProcessor);
  }
} // class SequentialSharedBufferWorkerNode


export default SequentialSharedBufferWorkerNode;









const DEVICE_PRODUCT = {
  '1_11891' : { //Muscle SpikerBox Pro
    "deviceIdx" : 1,
    "maxSamplingRate" : 10000,
    "minChannels" : 2,
    "maxChannels" : 4,
    "channels" : [2,3,4],
    "sampleRates" : [10000,10000,5000,5000],
    "baudRate" : 222222,
  },
  '6_11891' : { //Muscle SpikerBox Pro
      "deviceIdx" : 1001,
      "maxSamplingRate" : 10000,
      "minChannels" : 2,
      "maxChannels" : 4,
      "channels" : [2,3,4],
      "sampleRates" : [10000,10000,5000,5000],
      "baudRate" : 222222,
    },
  
  
  '2_11891' : { // Neuron SpikerBox Pro
    "deviceIdx" : 6,
    "maxSamplingRate" : 10000,
    "minChannels" : 2,
    "maxChannels" : 4,
    "channels" : [2,3,4],
    "sampleRates" : [10000,10000,5000,5000],
    "baudRate" : 222222,
  },
  '7_11891' : { // Neuron SpikerBox Pro
      "deviceIdx" : 1006,
      "maxSamplingRate" : 10000,
      "minChannels" : 2,
      "maxChannels" : 4,
      "channels" : [2,3,4],
      "sampleRates" : [10000,10000,5000,5000],
      "baudRate" : 222222,
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

async function getHidDeviceInfo(reportId){
  let data = parseHexArray("3F 3E 62 6F 61 72 64 3A 3B 5C 6E");  
  let reportData = new Uint8Array(data.buffer).slice(1);

  await port.sendReport(reportId, reportData);

}


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
