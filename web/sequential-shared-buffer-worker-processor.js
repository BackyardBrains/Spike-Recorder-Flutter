const SERIAL_WRITE_STATE = {
  'HEAD_IDX' : 0,
  'TAIL_IDX' : 1,
}


const PROCESSOR_STATE = {
  STATUS : 0
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


let processorSab;
let sabDrawingState;

var processorWorkerPort;
var serialPort;
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
};


var onInit = function(sharedBuffers){
  // console.log(self.navigator.serial);
  self.navigator.serial.getPorts()
  .then( async (ports) => {
      serialPort = ports[0];
      const productId = serialPort.getInfo().usbProductId;
      // console.log("serialPort",serialPort,productId);
      // await serialPort.open({baudRate: 230400});
      // const productId = serialPort.getInfo().usbProductId;
      const vendorId = serialPort.getInfo().usbVendorId;

      this.deviceId = productId + "_" + vendorId;
      // console.log(this.deviceId);

      this._deviceInfo = DEVICE_PRODUCT[this.deviceId];
      this._deviceInfo.productId = this.deviceId;

      /* Device Determination */
      let productIds = new Uint16Array(sharedBuffers.productId);
      productIds[0] = productId;
      productIds[1] = vendorId;
      
      let maxSampleRate = new Uint16Array(sharedBuffers.maxSampleRate);
      maxSampleRate[0] = this._deviceInfo.maxSamplingRate;
      sabDrawingState[DRAW_STATE.SAMPLE_RATE] = this._deviceInfo.maxSamplingRate;
      console.log("maxSamplingRate ; ", sabDrawingState[DRAW_STATE.SAMPLE_RATE]);
    
    
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
    
      processorWorkerPort.postMessage({
        message: 'PROCESSOR_READY',
        deviceId : this.deviceId,
      });

      
      await serialPort.open({baudRate: this._deviceInfo.baudRate});
      // serialPort.addEventListener('connect', (event) => {
      //   console.log(event.target, " connected12 ");
      // });
      // serialPort.addEventListener('disconnect', (event) => {
      //   console.log(event.target, " disconnected12 ");
      // });
      const writer = serialPort.writable.getWriter();
  
      while (serialPort.readable) {
        const reader = serialPort.readable.getReader();
        // reader.releaseLock();
        try {
          while (true) {
            // console.log("processorSab[PROCESSOR_STATE.STATUS]",processorSab[PROCESSOR_STATE.STATUS]);
            // console.log("this.sabSerialWriteDataMessage", this.sabSerialWriteDataMessage);
            if (this.sabSerialWriteDataMessage[0] != 0){
              console.log("CHANGE CHANNELS??");
              writer.write(this.sabSerialWriteDataMessage.slice(0,this.sabSerialWriteDataState[SERIAL_WRITE_STATE.TAIL_IDX]));
              this.sabSerialWriteDataMessage.fill(0);
              this.sabSerialWriteDataState.fill(0);
            }

            if (processorSab[PROCESSOR_STATE.STATUS] == 1){
              try{
                reader.releaseLock();
              }catch(err){
                console.log(err);
              }

              try{
                writer.releaseLock();
              }catch(err){
                console.log(err);
              }

              serialPort.close();
              return;
            }

            const { value, done } = await reader.read();
            if (done) {
              // reader.releaseLock();
              break;
            }
            if (value) {
              // console.log("value length : ", value.length);
              if (processorSab[PROCESSOR_STATE.STATUS] == 2){
                continue;
              }else{
                this._pushInputChannelData(value);
              }
    
              if (this._states[STATE.IB_FRAMES_AVAILABLE] >= this._kernelLength) {
                Atomics.notify(this._states, STATE.REQUEST_RENDER, 1);
              }
            }
          }
        } catch (error) {
            console.log("error");
            console.log(error);
          // TODO: Handle non-fatal read error.
        }  
    
      }
    }
  );

    // console.log(self.navigator.usb);
    // self.navigator.usb.getDevices()
    // .then( async (devices) => {
    //     console.log(devices);
    //     const device = devices[0];
    //     await device.open({baudRate: 230400});
    //     await device.selectConfiguration(1);
    //     await device.claimInterface(1);
    //     await device.controlTransferOut({
    //       requestType: 'class',
    //       recipient: 'interface',
    //       request: 34,
    //       value: 1,
    //       index: 1}); // Ready to receive data
    //       // request: 0x22,
    //       // value: 0x01,
    //       // index: 0x02}); // Ready to receive data

    //     while (true) {
    //       console.log("reader");
    //       //0x83
    //       const reader = await device.transferIn(83,64);
    //       console.log(reader);
      
    //     }
    // });        
}


/* DEFAULT */
var _initializeOnEvent = function (eventFromWorker){
  const sharedBuffers = eventFromWorker.data.rawSabcs[0];

  this._states = new Int32Array(sharedBuffers.states);

  this._inputRingBuffer = [new Uint8Array(sharedBuffers.inputRingBuffer)];
  this._outputRingBuffer = [new Uint8Array(sharedBuffers.outputRingBuffer)];

  this._ringBufferLength = this._states[STATE.RING_BUFFER_LENGTH];
  this._kernelLength = this._states[STATE.KERNEL_LENGTH];

  const sabSerialWriteData = eventFromWorker.data.sabSerialWriteData;

  console.log(sabSerialWriteData);

  this.sabSerialWriteDataState = new Int32Array(sabSerialWriteData.serialWriteState);
  this.sabSerialWriteDataMessage = new Uint8Array(sabSerialWriteData.serialWriteMessage);

  this._initialized = true;
  
  onInit(sharedBuffers);
  // processorWorkerPort.postMessage({
  //   message: 'PROCESSOR_READY',
  // });
  

}

var _pushInputChannelData =function (inputChannelData) {
  let inputWriteIndex = this._states[STATE.IB_WRITE_INDEX];

  if (inputWriteIndex + inputChannelData.length < this._ringBufferLength) {
    // If the ring buffer has enough space to push the input.
    this._inputRingBuffer[0].set(inputChannelData, inputWriteIndex);
    this._states[STATE.IB_WRITE_INDEX] += inputChannelData.length;
  } else {
    // When the ring buffer does not have enough space so the index needs to
    // be wrapped around.
    let splitIndex = this._ringBufferLength - inputWriteIndex;
    let firstHalf = inputChannelData.subarray(0, splitIndex);
    let secondHalf = inputChannelData.subarray(splitIndex);
    this._inputRingBuffer[0].set(firstHalf, inputWriteIndex);
    this._inputRingBuffer[0].set(secondHalf);
    this._states[STATE.IB_WRITE_INDEX] = secondHalf.length;
  }
  this._states[STATE.IB_FRAMES_AVAILABLE] += inputChannelData.length;
}

var _pullOutputChannelData = function(outputChannelData) {
  const outputReadIndex = this._states[STATE.OB_READ_INDEX];
  const nextReadIndex = outputReadIndex + outputChannelData.length;

  if (nextReadIndex < this._ringBufferLength) {
    outputChannelData.set(
        this._outputRingBuffer[0].subarray(outputReadIndex, nextReadIndex));
    this._states[STATE.OB_READ_INDEX] += outputChannelData.length;
  } else {
    let overflow = nextReadIndex - this._ringBufferLength;
    let firstHalf = this._outputRingBuffer[0].subarray(outputReadIndex);
    let secondHalf = this._outputRingBuffer[0].subarray(0, overflow);
    outputChannelData.set(firstHalf);
    outputChannelData.set(secondHalf, firstHalf.length);
    this._states[STATE.OB_READ_INDEX] = secondHalf.length;
  }
}

/* END DEFAULT */


self.onmessage = function( event ) {

  switch( event.data.command )
  {
    case "connect":
      processorWorkerPort = event.ports[0];
      processorSab = new Int32Array(event.data.processorSab);
      sabDrawingState = new Int32Array(event.data.sabDraw.draw_states[0]);

      console.log("event.data333");
      console.log(event.data);
      _initializeOnEvent(event);
    break;

    case "setConfig":
    break;
    case "init":
    break;

    case "setting":
      // this.channel2 = event.data.settingChannel;
    break;

    case "forward":
      workerForwardPort = event.ports[0];
    break;
    
    case "close":
      serialPort.close();

      // this.channel2 = event.data.settingChannel;
    break;

    default:
      console.log( event.data );
  }
};






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