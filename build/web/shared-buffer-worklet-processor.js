// THIS IS WHERE THE MULTICHANNEL DATA INSERTION BEGIN

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

// Description of shared states. See shared-buffer-worker.js for the
// description.

// let processorSamples = 0;
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
};

/**
 * @class SharedBufferWorkletProcessor
 * @extends AudioWorkletProcessor
 */
class SharedBufferWorkletProcessor extends AudioWorkletProcessor {
  /**
   * @constructor
   * @param {AudioWorkletNodeOptions} nodeOptions
   */
  constructor(nodeOptions) {
    super();

    this._initialized = false;
    this.port.onmessage = this._initializeOnEvent.bind(this);
  }

  /**
   * Without a proper coordination with the worker backend, this processor
   * cannot function. This initializes upon the event from the worker backend.
   *
   * @param {Event} eventFromWorker
   */
  _initializeOnEvent(eventFromWorker) {
    const rawSharedBuffers = eventFromWorker.data.sabcs;
    const n = rawSharedBuffers.length;
    console.log("PROCESSOR SHARED BUFFER : ",n);

    let i = 0;
    this._inputRingBuffer = [];
    this._ringBufferLength = [];
    this._kernelLength = [];
    this._states = [];
    for (;i<n;i++) {
      // Get the states buffer.
      const sharedBuffers = rawSharedBuffers[i];
      let _states = new Int32Array(sharedBuffers.states);
      this._states.push(_states);

      // Worker's input/output buffers. This example only handles mono channel
      // for both.
      // this._inputRingBuffer = [new Int32Array(sharedBuffers.inputRingBuffer)];
      // this._outputRingBuffer = [new Int32Array(sharedBuffers.outputRingBuffer)];

      // this._ringBufferLength = this._states[STATE.RING_BUFFER_LENGTH];
      // this._kernelLength = this._states[STATE.KERNEL_LENGTH];

      this._inputRingBuffer.push(new Int16Array(sharedBuffers.inputRingBuffer));
      this._ringBufferLength.push( _states[STATE.RING_BUFFER_LENGTH] );
      this._kernelLength.push( _states[STATE.KERNEL_LENGTH] );
    }

    this._initialized = true;
    this.port.postMessage({
      message: 'PROCESSOR_READY',
    });


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

  /**
   * Pull the data out of the shared input buffer to fill |outputChannelData|
   * (128-frames).
   *
   * @param {Int32Array} outputChannelData The output array to be filled.
   */
  _pullOutputChannelData(channelIdx, outputChannelData) {
    const outputReadIndex = this._states[STATE.OB_READ_INDEX];
    const nextReadIndex = outputReadIndex + outputChannelData.length;

    if (nextReadIndex < this._ringBufferLength[channelIdx]) {
      outputChannelData.set(
          this._outputRingBuffer[0].subarray(outputReadIndex, nextReadIndex));
      this._states[STATE.OB_READ_INDEX] += outputChannelData.length;
    } else {
      let overflow = nextReadIndex - this._ringBufferLength[channelIdx];
      let firstHalf = this._outputRingBuffer[0].subarray(outputReadIndex);
      let secondHalf = this._outputRingBuffer[0].subarray(0, overflow);
      outputChannelData.set(firstHalf);
      outputChannelData.set(secondHalf, firstHalf.length);
      this._states[STATE.OB_READ_INDEX] = secondHalf.length;
    }
  }

  /**
   * AWP's process callback.
   *
   * @param {Array} inputs Input audio data.
   * @param {Array} outputs Output audio data.
   * @return {Boolean} Lifetime flag.
   */
  process(inputs, outputs) {
    if (!this._initialized) {
      return true;
    }

    const len = this._inputRingBuffer.length;
    // This example only handles mono channel.
    let c = 0;
    for (; c < len; c++){
      const channel = inputs[0][c];
      // const outputChannelData = outputs[0][0];
      let n = channel.length;
      let samples = new Int16Array(n);
      let i = n-1;
      let s = 1 ;
      let max = Math.max;
      let min = Math.min;
      //turn into Int16 bit
      //https://stackoverflow.com/questions/35234551/javascript-converting-from-int16-to-float32
      for (;i>=0;i--){
        s = max(-1, min(1, channel[i]));
        samples[i] = s < 0 ? s * 0x8000 : s * 0x7FFF;
      }
      // if (c == 0){
      //   processorSamples += n;
      //   console.log("processorSamples : " , processorSamples);
      // }
  
      this._pushInputChannelData(c,samples);
      // console.log("SAMPLES ",c, samples);
      // this._pullOutputChannelData(outputChannelDataInt);
  
    }

    if (this._states[0][STATE.IB_FRAMES_AVAILABLE] >= this._kernelLength[0]) {
      // Now we have enough frames to process. Wake up the worker.
      // console.log("this._states[0][STATE.IB_FRAMES_AVAILABLE] : ",this._states[0][STATE.IB_FRAMES_AVAILABLE], this._states[1][STATE.IB_FRAMES_AVAILABLE]);
      // console.log("this._inputRingBuffer[0],this._inputRingBuffer[1] :: ",this._inputRingBuffer[0],this._inputRingBuffer[1]);
      // const flag = equal(this._inputRingBuffer[0], this._inputRingBuffer[1]);
      // console.log("FLAG ", flag);

      Atomics.notify(this._states[1], STATE.REQUEST_RENDER, 1);
      Atomics.notify(this._states[0], STATE.REQUEST_RENDER, 1);
    }


    return true;
  }
  
} // class SharedBufferWorkletProcessor

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
registerProcessor('shared-buffer-worklet-processor',
                  SharedBufferWorkletProcessor);
