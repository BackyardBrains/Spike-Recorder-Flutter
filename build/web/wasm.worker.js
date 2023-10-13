/*
Hi, this worker is the main worker which process the enveloping process,
lot of the initialization at the beginning is to speedup the performance,

This thread main functionality is to envelope data that are received,
Also the process of receiving the data is using Shared Array Buffer, and Atomics

*/


/* 
    These ports are used for bidirectional communication
*/
var workerLevel = 0;
var worker2port;
var workerForwardPort;

var isFull = false;
var envelopeLevel;

var drawSurfaceWidth,height;
var toSample, fromSample;
const SIZE_LOGS2 = 7;
const NUMBER_OF_SEGMENTS = 60;
const SEGMENT_SIZE = 44100;
const SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;

var drawBuffer;

let arrData = new Int16Array(256);
var arrMax = new Int16Array(SIZE*2);
let size = SIZE;




var envelopes = [];
var envelopeMax = [];
var envelopeMin = [];
var envelopeSizes = new Uint32Array(SIZE_LOGS2);


/*  
    Start SAB
*/

if (!self.SharedArrayBuffer) {
    console.log("SharedArrayBuffer is not supported in your browser.");
}

var CONFIG = {
    bytesPerState: Int32Array.BYTES_PER_ELEMENT,
    bytesPerSample: Int32Array.BYTES_PER_ELEMENT,
    stateBufferLength : 16,
    channelCount: 1,
    waitTimeOut: 25000,
    ringBufferLength: 4096,
    kernelLength: 1024,  
};
  
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

};

var SharedBuffers = {
    states : new SharedArrayBuffer(CONFIG.stateBufferLength * CONFIG.bytesPerState),
    inputRingBuffer:
        new SharedArrayBuffer(CONFIG.ringBufferLength *
                              CONFIG.channelCount * CONFIG.bytesPerSample),
    outputRingBuffer:
        new SharedArrayBuffer(CONFIG.ringBufferLength *
                              CONFIG.channelCount * CONFIG.bytesPerSample),
};

var AudioChannels = [SharedBuffers];

/*  
    End SAB
*/


let i=0;
let idxDelay = 0;
let c = 0;


size/=2;
for (;c<CONFIG.channelCount;c++){
    for (;i<SIZE_LOGS2;i++){
        // SharedBuffers.sabEnvelopes.push(SharedArrayBuffer(CONFIG.bytesPerSample * size))
        // envelopes.push(new Int16Array(SharedBuffers.sabEnvelopes[i]));
        envelopes.push(new Int16Array(size));
        size/=2;
        envelopeSizes[i] = size;
        // envelopeMax.push(new Int16Array(size));
        // envelopeMin.push(new Int16Array(size));
    }    
}


var _head = 0;
let vm = this;

var arrCounts = [ 4, 8, 16, 32, 64, 128, 256 ];
var skipCounts = new Uint32Array(arrCounts);



// This is supposed to be used by Web Assembly
var isInitialized = false;


self.onmessage = function( event ) {
  
    var i;
    var j;
    var onReceivedSampleData = function( event ){
        let samples = event.data;
        let len = samples.length;
        idxDelay++;
        let sample = -10000;

        for (i = 0;i<len;i++){
            sample = samples[i];
            for (j = 0; j < SIZE_LOGS2; j++){
                const skipCount = skipCounts[j];
                const envelopeSampleIndex = Math.floor(_head / skipCount);
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
            arrMax[interleavedHeadSignalIdx] = sample;
            arrMax[interleavedHeadSignalIdx + 1] = sample;
            _head++;
            if (_head == SIZE){
                _head = 0;        
                isFull = true;
            }
        }
        if (idxDelay == 5 ){
            let arrBuffer;
            if (envelopeLevel == -1){
                arrBuffer = (new Int16Array(arrMax));
                workerForwardPort.postMessage({"array":arrBuffer,"head":_head,"isFull": isFull, "skipCounts" : 1},[arrBuffer.buffer]);
            }else{
                arrBuffer = (new Int16Array(envelopes[envelopeLevel]));                
                workerForwardPort.postMessage({"array":arrBuffer,"head":_head,"isFull": isFull, "skipCounts" : skipCounts[envelopeLevel]},[arrBuffer.buffer]);
            }

            idxDelay =0;
        }
        delete samples;
    };
    
    
    switch( event.data.command )
    {
        case "connect":
            drawSurfaceWidth = event.data.width;
            drawBuffer = new Int16Array(drawSurfaceWidth);
            height = event.data.height;

            toSample = event.data.toSample;
            fromSample = event.data.fromSample;
            worker2port = event.ports[0];
            worker2port.onmessage = onReceivedSampleData;
            worker2port.postMessage({
                "message":"sab",
                "channels":AudioChannels
            });
            isInitialized = true;
        break;
        case "setConfig":
            envelopeLevel = event.data.level;
        break;
        case "init":
            console.log("INIT");
            vm.timeScale = 10000; // 10ms
            vm.printFlag = true;
            vm.sampleRate = event.data.sampleRate;    
            vm.capacityMin = (vm.sampleRate/(1000/this.timeScale));
            vm.capacityMax = vm.sampleRate*10;
            vm.capacity = vm.capacityMin;
    
            vm.maxConfig = {
              start : 0,
              end : 0,
              idxStart :0,
              idxEnd : vm.capacity,
            };
    
            vm.idx = 0;
            vm.limiter=4;
            vm.dataWritten=0;
            vm.dataWrittenFlag = false;
    
        break;

        case "setting":
            this.channel2 = event.data.settingChannel;
            this.channel2.onmessage=function(setting){
                envelopeLevel = setting.data;
            }  
        break;

        case "forward":
            workerForwardPort = event.ports[0];
        break;

        default:
            console.log( event.data );
    }
};