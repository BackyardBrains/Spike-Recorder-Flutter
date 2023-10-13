var worker2port;
var workerForwardPort;

var isInitialized = false;
var drawSurfaceWidth,height;
var toSample, fromSample;
// let idx = 0 ;
let lastDraw=0;
let currentDraw=0;

self.onmessage = function( event ) {
    var onMessageFromWorker = function( event ){
        // WASM process data
        const samples = new Float32Array(event.data);
        // console.log("ANOTHER MESSAGE");
        if (isInitialized){
            // currentDraw = (new Date()).getTime();

            // console.log("RUN INITIALIZE");
            // console.log(samples.length);
            const sum = samples.reduce((p,c)=> p+c);
            if (sum== 0) return;
            // if (samples[0]+samples[1]+samples[2]+samples[3] == 0){
            //     return;
            // }

            // let sampleIndex = 0;
            // console.log("============================");
            // console.log((new Date()).getTime());
            const n = samples.length;
            // console.log("============================");
            // console.log(n);

            let max = -1000000000;
            let min = 1000000000;
            let arrData = [];

            if (toSample < 0){
                toSample = samples.length;
            }
            const drawSamplesCount = toSample - fromSample;
            if (drawSamplesCount < drawSurfaceWidth) drawSurfaceWidth = drawSamplesCount;

            const samplesPerPixel = Math.floor(drawSamplesCount / drawSurfaceWidth);
            const samplesPerPixelRest = drawSamplesCount % drawSurfaceWidth;
            // 0
            const samplesPerEnvelope = samplesPerPixel * 2; //why multiply by 2? is it because we save min and max
            let envelopeCounter = 0; 
            let eventCounter = 0;

            const from = fromSample;
            const to = fromSample + drawSamplesCount;

            let sample;
            for (let i =0;i<n;i++){
                sample = samples[i];
                if (samplesPerPixel == 1 && samplesPerPixelRest == 0) {//7. is it 1:1 scale?
                    arrData.push(sample);
    
                    eventCounter = 0;
                } else {
                    if (sample > max) max = sample;// 4. are we trying to get the most significant max min?  //short min = SHRT_MAX, max = SHRT_MIN;
                    if (sample < min) min = sample;
                    if (envelopeCounter == samplesPerEnvelope) {// if envelop counter equals with the samples that are supposed to be in envelope
                        arrData.push(max);
                        arrData.push(min);
            
                        envelopeCounter = 0;
                        min = 1000000000;
                        max = -1000000000;
                        eventCounter = 0;
                    }
    
                    envelopeCounter++;
                }
            }
            let arrBuffer = (new Float32Array(arrData)).buffer;
            // console.log(new Float32Array(arrData));
            //drawSurfaceWidth, drawSamplesCount, samplesPerPixel , samples.length, arrData
            //1 second
            // 873 27904 31 44101 : 1422
            //10 seconds
            //873 27904 31 441001 
            //873 30720 35 480001 : 13714
            //1288 30208 23 324864  : 20868
            // console.log((currentDraw - lastDraw),drawSurfaceWidth, drawSamplesCount, samplesPerPixel , samples.length, arrData);
            // if ( (currentDraw - lastDraw) >500){
            //     lastDraw = currentDraw;
            // }
            workerForwardPort.postMessage(arrBuffer,[arrBuffer]);
            delete arrBuffer;
            delete samples;
            delete event.data;
            // console.log("------------------------");
            // console.log((new Date()).getTime());


            // const typedArray = new Float32Array(samples.length)
            // for (let i=0; i<samples.length; i++) {
            //     typedArray[i] = samples[i];
            // }
            // // console.log(typedArray);
        
            // // console.log("MALLOC");
            // let buffer = Module._malloc(typedArray.length * typedArray.BYTES_PER_ELEMENT);
        
            // Module.HEAPF32.set(typedArray, buffer >> 2);
            // let result = Module.ccall("prepareSignalForDrawing", null, ["number", "number", "number", "number"], [buffer, 0, samples.length,1000])
            // // console.log("result "+samples.length);
            // // console.log(result);
            // let arrayData = [];
            // // console.log(Float32Array.BYTES_PER_ELEMENT);
            // let len = Module.HEAPF32[result/Float32Array.BYTES_PER_ELEMENT];
            // // console.log("len" +len);

            // for (let v=2; v < len; v++) {
            //     // console.log("result/Float32Array.BYTES_PER_ELEMENT+v");
            //     // console.log(result/Float32Array.BYTES_PER_ELEMENT+v);
            //     // console.log(Module.HEAPF32[result/Float32Array.BYTES_PER_ELEMENT+v]);
            //     arrayData.push(Module.HEAPF32[result/Float32Array.BYTES_PER_ELEMENT+v])
            // }
            // // console.log("END RESULT");
            // // console.log(arrayData);
            // // workerForwardPort.postMessage(arrayData,[arrayData]);
            // workerForwardPort.postMessage(arrayData);
            // Module._free(buffer);





            // console.log("FREE");
            // console.log("FREE BUFFER");

            // const prepareDrawing = Module.ccall('prepareSignalForDrawing', 'number', ['number']);
            // console.log(prepareDrawing());

            
            // const c = new Module.DrawingUtils();
            // void prepareSignalForDrawing(float *outSamples, int outSampleCounts, float *outEventIndices,
            //                                             int outEventCount, short *inSamples, int channelCount,
            //                                             const int *inEventIndices, int inEventCount, int fromSample,
            //                                             int toSample, int drawSurfaceWidth) {


            // console.log(c.prepareSignalForDrawing(samples, 0, samples.length,1000));

            // const c = new Module.Counter(22);
            // console.log(c.counter); // prints 22    
            // c.increase();
            // console.log(c.counter); // prints 23
            // console.log(c.squareCounter()); // prints 529

            // forward processed data
            // workerForwardPort.postMessage( event.data.message );

            // console.log("Worker message : " + event.data);
        }
    
    };
    
    
    switch( event.data.command )
    {
        case "connect":
            drawSurfaceWidth = event.data.width;
            height = event.data.height;

            toSample = event.data.toSample;
            fromSample = event.data.fromSample;
            worker2port = event.ports[0];
            worker2port.onmessage = onMessageFromWorker;
            isInitialized = true;
            // importScripts("a.out.js");
            // Module.onRuntimeInitialized = () => {
            //     isInitialized = true;
            // };            
    
            break;
        case "forward":
            //process the 

            workerForwardPort = event.ports[0];
            break;

        //handle other messages from main
        default:
            console.log( event.data );
    }
};