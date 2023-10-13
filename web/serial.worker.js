var worker2port;
var workerForwardPort;

var isFull = false;
var envelopeLevel;

var isInitialized = false;
var drawSurfaceWidth,height;
var toSample, fromSample;

const SIZE_LOGS2 = 6;
const NUMBER_OF_SEGMENTS = 60;
const SEGMENT_SIZE = 10000;
const SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;

let arrData = new Int16Array(256);
var drawBuffer;

var arrMax = new Int16Array(SIZE);
let size = SIZE;

var envelopeMax = [];
var envelopeMin = [];
var envelopeSizes = new Uint32Array(SIZE_LOGS2);
envelopeSizes[0] = 1;
let i=0;
var envelopes = [];

size/=128;
for (;i<SIZE_LOGS2;i++){
    envelopes.push(new Int16Array(size));
    size/=2;
    envelopeMax.push(new Int16Array(size));
    envelopeSizes[i] = size;
    envelopeMin.push(new Int16Array(size));
}

console.log("envelopeSizes");
console.log(envelopeSizes);

var _head = 0;
let vm = this;


// var arrCounts = [ 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288 ];
var arrCounts = [ 256, 512, 1024, 2048, 4096, 8192 ];
var skipCounts = new Uint32Array(arrCounts);



self.onmessage = function( event ) {
    
    
    var onInit = function(){
        console.log(self.navigator.serial);
        self.navigator.serial.getPorts()
        .then( async (ports) => {
            console.log(ports);
            const port = ports[0];
            await port.open({baudRate: 230400});
        
            while (port.readable) {
                const reader = port.readable.getReader();
                // console.log(reader);
              
                try {
                    while (true) {
                        const { value, done } = await reader.read();
                        // console.log(value);
                        if (done) {
                            // Allow the serial port to be closed later.
                            reader.releaseLock();
                            break;
                        }
                        if (value) {
                            onMessageFromWorker(value);
                        }
                    }
                } catch (error) {
                    console.log("error");
                    console.log(error);
                  // TODO: Handle non-fatal read error.
                }
            }
        });        
    }

    var onMessageFromWorker = function( value ){
        // WASM process data
                
        // var samples = new Uint8Array(value);
        var samples = value;
        let len = samples.length;

        let sample = -10000;

        for (i = 0;i<len;i++){
            sample = samples[i];
            // console.log(sample);
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
            _head++;
            if (_head == SIZE){
                _head = 0;        
                isFull = true;
            }
        }
        // console.log("envelopes[envelopeLevel]");
        // console.log(envelopes[envelopeLevel]);
        let arrBuffer = (new Int16Array(envelopes[envelopeLevel]));
        workerForwardPort.postMessage({"array":arrBuffer,"head":_head,"isFull": isFull, "skipCounts" : skipCounts[envelopeLevel]},[arrBuffer.buffer]);
        delete samples;
    
    };
    
    
    switch( event.data.command )
    {
        case "connect":
            drawSurfaceWidth = event.data.width;
            height = event.data.height;

            toSample = event.data.toSample;
            fromSample = event.data.fromSample;
            worker2port = event.ports[0];
            // worker2port.onmessage = onMessageFromWorker;
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
    
            // vm.currentArr = new Float32Array(vm.capacity);
            // vm.arrMax = new Float32Array(vm.capacityMax);

    
            vm.idx = 0;
            vm.limiter=4;
            vm.dataWritten=0;
            vm.dataWrittenFlag = false;
            onInit();
    
        break;


        case "setting":
            this.channel2 = event.data.settingChannel;
            this.channel2.onmessage=function(setting){
                vm.timeScale = setting.data;
                if (vm.timeScale === 10){
                    vm.capacityMin = (sampleRate * vm.timeScale / 1000);
                    vm.limiter=3;
                }else
                if (vm.timeScale === 2008){
                    vm.capacityMin = (sampleRate * 0.03);
                    vm.limiter=4;
                }else
                if (vm.timeScale === 6004){
                    vm.capacityMin = (sampleRate * 0.04);
                    vm.limiter=5;
                }else
                if (vm.timeScale === 8002){
                    vm.capacityMin = (sampleRate * 0.06);
                    vm.limiter=6;
                }else{
                    vm.capacityMin = (sampleRate * 0.08);
                    vm.limiter=8;
                }
                vm.capacityMin = Math.floor(sampleRate * vm.timeScale / 1000);

                vm.capacity = vm.capacityMin;
                vm.capacityMax = sampleRate*10;
            }  

        break;

        case "forward":
            workerForwardPort = event.ports[0];
        break;
        

        default:
            console.log( event.data );
    }
};