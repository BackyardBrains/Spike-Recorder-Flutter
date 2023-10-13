let eventsCounterInt;
let eventsInt;
let eventPositionInt;
let eventGlobalPositionInt;
let eventPositionResultInt;

let CHANNEL_COUNT_FIX=1;
let type = 'audio';
const arrTimescale = [ 600000,60000, 6000, 1200, 600, 120, 60, 12, 6 ];

const STATE = {
  'REQUEST_SIGNAL_REFORM': 9,
};

const CONFIG = {
  bytesPerState: Int32Array.BYTES_PER_ELEMENT,
  bytesPerSample: Int16Array.BYTES_PER_ELEMENT,
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


const SIZE_LOGS2 = 10;
const NUMBER_OF_SEGMENTS = 60;
const SEGMENT_SIZE = 44100;
const SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;

var signalworker2port;
var workerForwardPort;
var displayWidth;
let vm = this;

// var arrCounts = [ 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288 ];
let sabDrawing = [];
let rawSabDraw;
var arrCounts = [ 4, 8, 16, 32, 64, 128, 256,512,1024, 2048 ];
var skipCounts = new Uint32Array(arrCounts);
let divider = 6;
let draw_states = [
  new Int32Array(Int32Array.BYTES_PER_ELEMENT * 8),
  new Int32Array(Int32Array.BYTES_PER_ELEMENT * 8)
];
let isReducingMarkers = false;

const shiftLeft = (collection, steps = 1, pos = 1) => {
  const subarr = collection.slice(steps);
  collection.fill(0, 0);
  collection.set(subarr,0);
  return collection;
}

function reduceMarkers(ctr){
  // if (eventPositionResultInt[0] == 0 && draw_states[0][DRAW_STATE.EVENT_FLAG]==0 ){
  //   eventsCounterInt[0]--;
  //   const pos = eventsCounterInt[0];
  //   draw_states[0][DRAW_STATE.EVENT_COUNTER] = pos;
  //   console.log("eventsCounterInt[0] reduce markers: ",eventsCounterInt[0]);
  //   shiftLeft(eventsInt,1,pos);
  //   shiftLeft(eventPositionInt,1,pos);
  //   shiftLeft(eventPositionResultInt,1,pos);
  // }
  // eventsInt.set( eventsInt.slice(1),0 );
  // eventPositionInt.set( eventPositionInt.slice(1),0 );
  // eventPositionResultInt.set( eventPositionResultInt.slice(1),0 ); 
}

self.onmessage = function( event ) {
  var onMessageFromWorker = function( e ){
    // const samples = new Float32Array(e.data);
    // console.log(e.data.array);
    
    const skipCounts = e.data.skipCounts;
    const head = Math.floor(e.data.head/skipCounts);
    const tail = Math.floor(e.data.tail/skipCounts);
    const isFull = e.data.isFull;
    const globalPositionCap = e.data.globalPositionCap;    
    const nextGlobalPositionCap = e.data.nextGlobalPositionCap;    
    const maxSize = nextGlobalPositionCap - globalPositionCap;
    const halfwayCap = globalPositionCap * 0.8;

    const drawBuffer = e.data.drawBuffer;
        
    const envelopeSamples = e.data.array;
    const rawLength = envelopeSamples.length;
    const bufferLength = drawBuffer.length;
    const maxMinMultiplier = 2;
    const channelIdx = e.data.channelIdx;

    const offsetHead = e.data.offsetHead;
    // const offsetTo = Math.floor( (offsetHead % maxSize )/skipCounts * maxMinMultiplier);

    // console.log("Channeld Idx : ", channelIdx);

    // if (vm.level == -1){
    //   maxMinMultiplier = 1;
    // }
    const prevSegment = Math.floor( envelopeSamples.length/divider);
    let start = head * maxMinMultiplier - prevSegment;
    // let offsetStart = offsethead * maxMinMultiplier - prevSegment;
    let to = head * maxMinMultiplier;
    // let startTail = tail * maxMinMultiplier;
    // let toTail = tail * maxMinMultiplier;

    const evtCounter = eventsCounterInt[0];
    const excess = bufferLength - prevSegment;
    const nearFull = start + prevSegment;
    const modSamples = envelopeSamples.length;

    if (!isFull && nearFull <= envelopeSamples.length){
      if (start < 0 ) start = 0;
      // eventPositionResultInt.fill(0);
      if (channelIdx == 0 && offsetHead > 0){
        eventPositionResultInt.fill(0);
        for ( let ctr = 0; ctr < evtCounter; ctr++ ){
          {
          // if (eventGlobalPositionInt[ctr] >= globalPositionCap && eventGlobalPositionInt[ctr] < nextGlobalPositionCap){
            
            // const headPosition = Math.floor(eventPositionInt[ctr] / skipCounts * 2); // headPosition in envelope realm
            /*
            const headPosition = Math.floor(eventPositionInt[ctr] / skipCounts * maxMinMultiplier); // headPosition in envelope realm
            // channel idx :  0 31745 0 248 0
            if ( headPosition < start) {
              eventPositionResultInt[ctr] = 0;
              isReducingMarkers = true;
            }else//{
            if (headPosition >= start && headPosition <= to){posMarker
              // eventPositionResultInt[ctr] = bufferLength - excess - (to - (headPosition));
              eventPositionResultInt[ctr] = ( bufferLength - excess - (to - (headPosition)) ) / bufferLength * vm.drawSurfaceWidth;
            }*/

            // const markerPosition = Math.floor(eventPositionInt[ctr] / skipCounts * maxMinMultiplier); // headPosition in envelope realm
            let offsetTail = offsetHead - bufferLength / 2 * skipCounts;
            if ( offsetTail < 0 ) offsetTail = 0;

            if (eventGlobalPositionInt[ctr] < offsetTail){
              eventPositionResultInt[ctr] = 0;
              isReducingMarkers = true;
            }else
            if (eventGlobalPositionInt[ctr] >= offsetTail && eventGlobalPositionInt[ctr] <= offsetHead){
              // eventPositionResultInt[ctr] = ( bufferLength - excess - (to - (markerPosition)) ) / bufferLength * vm.drawSurfaceWidth;
              // eventPositionResultInt[ctr] = ( bufferLength - excess - (bufferLength - (markerPosition)) ) / bufferLength * vm.drawSurfaceWidth;
              const posMarker = Math.floor( (offsetHead - eventGlobalPositionInt[ctr] ) /skipCounts * maxMinMultiplier);              
              eventPositionResultInt[ctr] = ( bufferLength - excess - posMarker ) / bufferLength * vm.drawSurfaceWidth;
            }else
            if (eventGlobalPositionInt[ctr] > offsetHead){
              eventPositionResultInt[ctr] = 0;
              isReducingMarkers = true;
            }

          } 
          // console.log(bufferLength," headPos "+ctr, "CTR : "+eventsInt[ctr], " _____ " ,eventPositionResultInt[ctr], headPosition, start,to);
          
        }
      }

      const subarray = envelopeSamples.subarray(start,to );
      // vm.drawBuffer.set(subarray, bufferLength - subarray.length  - 1 );
      if (subarray.length < bufferLength){
        drawBuffer.set(subarray, bufferLength - subarray.length  - 1 );
        // console.log(subarray);
      }else{
        start = to - bufferLength;
        try{
          // var diff = Math.abs(vm.drawBuffer.length - subarray.length);
          const subarray2 = envelopeSamples.subarray(start,to);

          drawBuffer.set(subarray2, 0 );
        }catch(err){
          console.log(drawBuffer.length, bufferLength, subarray.length);
          console.log("Error signal 000", err, subarray, envelopeSamples.length, start, to, bufferLength);
        }
      }
      // if (start > 0 ) {
      //   console.log("almost", start, e.data.head, head, subarray.length);
      // }

      // if (start >-100 && start <0){
      //   console.log("almost", start, e.data.head, head, subarray.length);
      // }

      // console.log("start");
      // console.log(subarray, vm.drawBuffer.length, rawLength, subarray.length);
      // 20671 41343 1236
      // vm.drawBuffer.set(subarray, 0 );
      // console.log(start, to , bufferLength);
      //signal.worker.js:28 0 6892
      
    }else{
      let segmentCount = prevSegment;
      if (start<0){
        const processedHead = head * maxMinMultiplier;
        segmentCount = segmentCount - processedHead - 1;
        start = envelopeSamples.length - segmentCount;
        const firstPartOfData = envelopeSamples.subarray(start);
        const secondPartOfData = envelopeSamples.subarray(0, processedHead);
        const secondIdx = bufferLength - secondPartOfData.length - 1;
        if (secondPartOfData.length>0){
          // vm.drawBuffer.set(secondPartOfData, secondIdx);
          // vm.drawBuffer.set(firstPartOfData, secondIdx - firstPartOfData.length);  
          try{
            drawBuffer.set(firstPartOfData, 0);  
            drawBuffer.set(secondPartOfData, firstPartOfData.length);  
          }catch(err){
            console.log("ERR ", err, start, segmentCount,envelopeSamples.length, start, to, bufferLength);
          }
        }else{
          drawBuffer.set(firstPartOfData, bufferLength - firstPartOfData.length-1);  
        }
        
        
        if (channelIdx == 0){
          eventPositionResultInt.fill(0);
          for ( let ctr = 0; ctr < evtCounter; ctr++ ){
            // if (eventGlobalPositionInt[ctr] >= halfwayCap){
            {
              let offsetTail = offsetHead - bufferLength / 2 * skipCounts;
              if ( offsetTail < 0 ) offsetTail = 0;
  
              if (eventGlobalPositionInt[ctr] < offsetTail){
                eventPositionResultInt[ctr] = 0;
                isReducingMarkers = true;
              }else
              if (eventGlobalPositionInt[ctr] >= offsetTail && eventGlobalPositionInt[ctr] <= offsetHead){
                const posMarker = Math.floor( (offsetHead - eventGlobalPositionInt[ctr] ) /skipCounts * maxMinMultiplier);              
                eventPositionResultInt[ctr] = ( bufferLength - excess - posMarker ) / bufferLength * vm.drawSurfaceWidth;
  
                // eventPositionResultInt[ctr] = ( bufferLength - excess - (offsetTo - (markerPosition)) ) / bufferLength * vm.drawSurfaceWidth;
              }else
              if (eventGlobalPositionInt[ctr] > offsetHead){
                eventPositionResultInt[ctr] = 0;
                isReducingMarkers = true;
              }


              // const markerPosition = Math.floor(eventPositionInt[ctr] / skipCounts * maxMinMultiplier); // headPosition in envelope realm
              // const offsetTail = offsetHead - bufferLength / maxMinMultiplier * skipCounts;
              // const offsetStart = (offsetTail) * maxMinMultiplier / skipCounts;
              // const offsetEnd = offsetStart + bufferLength;
              // if (eventGlobalPositionInt[ctr] >= offsetTail && eventGlobalPositionInt[ctr] <= offsetHead){

              //   if (markerPosition >= offsetStart && markerPosition <= envelopeSamples.length){
              //     const pos = bufferLength - excess - ( envelopeSamples.length - markerPosition);
              //     eventPositionResultInt[ctr] = pos / bufferLength * vm.drawSurfaceWidth;
              //   }else//{ // headPosition < to // below
              //   if (markerPosition <= offsetEnd && markerPosition >=0){
              //     // console.log("below");
              //     const pos = bufferLength - excess - ( offsetEnd - (markerPosition) );
              //     eventPositionResultInt[ctr] = pos / bufferLength * vm.drawSurfaceWidth;
              //   }
              // }else{
              //   eventPositionResultInt[ctr] = 0;
              //   isReducingMarkers = true;
              // }
            }
              
            // if (eventGlobalPositionInt[ctr] >= globalPositionCap && eventGlobalPositionInt[ctr] < nextGlobalPositionCap){
            /*
            if (eventGlobalPositionInt[ctr] >= halfwayCap){
              const headPosition = Math.floor(eventPositionInt[ctr] / skipCounts * maxMinMultiplier); // headPosition in envelope realm
              if ( headPosition < start && headPosition > to) {
                eventPositionResultInt[ctr] = 0;
                isReducingMarkers = true;
      
              }else{
                if ( headPosition <= envelopeSamples.length && headPosition>= start){ // upper
                  const counter = bufferLength - ( envelopeSamples.length - headPosition + secondPartOfData.length );
                  // const counter = prevSegment - excess - ( (maxSampleSingular - headPosition + secondPartOfData.length );
                  // const counter = prevSegment - excess - ( (firstPartOfData.length - (headPosition - start) ) + secondPartOfData.length );
  
                  // eventPositionResultInt[ctr] = 300;
                  eventPositionResultInt[ctr] = counter / bufferLength * vm.drawSurfaceWidth;
                  // console.log("upper ", eventPositionResultInt[ctr].toString());
                }else//{ // headPosition < to // below
                if (headPosition <= to && headPosition >=0){
  
                  // console.log("below");
                  const counter = bufferLength - excess - ( to - (headPosition) );
                  eventPositionResultInt[ctr] = counter / bufferLength * vm.drawSurfaceWidth;
                }
              }  
              */
              // const markerPosition = Math.floor(eventPositionInt[ctr] / skipCounts * maxMinMultiplier); // headPosition in envelope realm
              // const offsetTail = offsetHead - bufferLength / 2 * divider * skipCounts;
              // if (eventGlobalPositionInt[ctr] < offsetHead && eventGlobalPositionInt > offsetTail){
              //   eventPositionResultInt[ctr] = 0;
              //   isReducingMarkers = true;
              // }else{
              //   if (markerPosition >= start && markerPosition <= envelopeSamples.length){
              //     const counter = bufferLength - ( envelopeSamples.length - headPosition + secondPartOfData.length );
              //     eventPositionResultInt[ctr] = counter / bufferLength * vm.drawSurfaceWidth;
              //   }else//{ // headPosition < to // below
              //   if (markerPosition <= to && markerPosition >=0){
  
              //     // console.log("below");
              //     const counter = bufferLength - excess - ( to - (markerPosition) );
              //     eventPositionResultInt[ctr] = counter / bufferLength * vm.drawSurfaceWidth;
              //   }

              //   // if (markerPosition >= start && markerPosition <= envelopeSamples.length){
              //   //   const counter = bufferLength - ( envelopeSamples.length - headPosition + secondPartOfData.length );
              //   //   eventPositionResultInt[ctr] = counter / bufferLength * vm.drawSurfaceWidth;
              //   // }else//{ // headPosition < to // below
              //   // if (markerPosition <= offsetTo && markerPosition >=0){
  
              //   //   // console.log("below");
              //   //   const counter = bufferLength - excess - ( offsetTo - (markerPosition) );
              //   //   eventPositionResultInt[ctr] = counter / bufferLength * vm.drawSurfaceWidth;
              //   // }

              // }
  
            // }     
          }

        }
        

      }else{
        start = start;
        const subarray = envelopeSamples.subarray(start,to);
        const startIdx = bufferLength - subarray.length;
        // console.log(start, to, startIdx, bufferLength);
        // let flagError = false;
        try{
          drawBuffer.set(subarray, startIdx);
        }catch(err){
          console.log("Error signal", err, startIdx, subarray, envelopeSamples.length, start, to, bufferLength);
          if (subarray.length > bufferLength){
            start = to - bufferLength;
            const subarr = envelopeSamples.subarray(start, to);
            drawBuffer.set(subarr,0);
          }
          // const offsetTail = offsetHead - bufferLength / 2 * skipCounts;
          // console.log("eventGlobalPositionInt : ", eventGlobalPositionInt, offsetTail);
          // flagError = true;
        }

        if (channelIdx == 0 && offsetHead > 0){
          for ( let ctr = 0; ctr < evtCounter; ctr++ ){
            // if (eventGlobalPositionInt[ctr] >= globalPositionCap && eventGlobalPositionInt[ctr] < nextGlobalPositionCap){
            {
              const markerPosition = Math.floor(eventPositionInt[ctr] / skipCounts * maxMinMultiplier); // headPosition in envelope realm
              let offsetTail = offsetHead - bufferLength / 2 * skipCounts;
              if ( offsetTail < 0 ) offsetTail = 0;

              if (eventGlobalPositionInt[ctr] < offsetTail){
                eventPositionResultInt[ctr] = 0;
                isReducingMarkers = true;
              }else
              if (eventGlobalPositionInt[ctr] >= offsetTail && eventGlobalPositionInt[ctr] <= offsetHead){
                const posMarker = Math.floor( (offsetHead - eventGlobalPositionInt[ctr] ) /skipCounts * maxMinMultiplier);              
                eventPositionResultInt[ctr] = ( bufferLength - excess - posMarker ) / bufferLength * vm.drawSurfaceWidth;
                // if (flagError){
                //   console.log("eventPositionResultInt : ",eventPositionResultInt);
                // }
                // eventPositionResultInt[ctr] = ( bufferLength - excess - (offsetTo - (markerPosition)) ) / bufferLength * vm.drawSurfaceWidth;
              }else
              if (eventGlobalPositionInt[ctr] > offsetHead){
                eventPositionResultInt[ctr] = 0;
                isReducingMarkers = true;
              }
  
            }
          }  
        }        
        // if (channelIdx == 0){
        //   eventPositionResultInt.fill(0);
        //   for ( let ctr = 0; ctr < evtCounter; ctr++ ){
        //     /*
        //     if (eventGlobalPositionInt[ctr] >= globalPositionCap && eventGlobalPositionInt[ctr] < nextGlobalPositionCap){
  
        //       const headPosition = Math.floor(eventPositionInt[ctr] / skipCounts * maxMinMultiplier); // headPosition in envelope realm
        //       if ( headPosition < start) {
        //         eventPositionResultInt[ctr] = 0;
        //         isReducingMarkers = true;
        //       }else//{
        //       if (headPosition >= start && headPosition <= to){
  
        //         // console.log("middle");
        //         // eventPositionResultInt[ctr] = bufferLength - excess - ( to - (headPosition) );
        //         eventPositionResultInt[ctr] = ( bufferLength - excess - (to - (headPosition)) ) / bufferLength * vm.drawSurfaceWidth;
        //       }
        //     }     
        //     */
  
        //     const markerPosition = Math.floor(eventPositionInt[ctr] / skipCounts * maxMinMultiplier); // headPosition in envelope realm
        //     let offsetTail = offsetHead - bufferLength / 2 * skipCounts;
        //     if ( offsetTail < 0 ) offsetTail = 0;

        //     if (eventGlobalPositionInt[ctr] < offsetTail){
        //       eventPositionResultInt[ctr] = 0;
        //       isReducingMarkers = true;
        //     }else
        //     if (eventGlobalPositionInt[ctr] >= offsetTail && eventGlobalPositionInt[ctr] <= offsetHead){
        //       // eventPositionResultInt[ctr] = ( bufferLength - excess - (to - (markerPosition)) ) / bufferLength * vm.drawSurfaceWidth;
        //       // eventPositionResultInt[ctr] = ( bufferLength - excess - (bufferLength - (markerPosition)) ) / bufferLength * vm.drawSurfaceWidth;
        //       eventPositionResultInt[ctr] = ( bufferLength - excess - (offsetTo - (markerPosition)) ) / bufferLength * vm.drawSurfaceWidth;
        //     }  
            
        //   }
        // }
  
      }
  
      // const firstPartOfData = rawSamples.subarray(start, rawLength);
      // const secondPartOfData = rawSamples.subarray(0, end);
      // vm.drawBuffer.set(firstPartOfData, 0);
      // vm.drawBuffer.set(secondPartOfData, firstPartOfData.length);
    }

    // const samples = vm.drawBuffer;
    // let n = vm.drawBuffer.length;
    // console.log("LENGTH : ",n);

    // get counter
    // for position head aray from 0 to counter
    // translate into position in the x, draw line, add number by dividing with skipCounts
    // check if within start and to
    // put EVENT_HEAD & EVENT_TAIL


    // ----------------
    // const samples = e.data.array;
    // let n = samples.length;
    // ----------------

    // var idxCounter = 0;
    // let max = -10000;
    // let min = 100000;
    // // let arrData = [];
    // if (vm.toSample < 0){
    //   vm.toSample = samples.length;
    //   // vm.fromSample = samples.length % skipCounts[vm.level];
    //   // vm.toSample = (samples.length - vm.fromSample) / skipCounts[vm.level];
    //   // vm.toSample *= skipCounts[vm.level];
    // }
    // const drawSamplesCount = vm.toSample - vm.fromSample;
    // // if (drawSamplesCount < vm.drawSurfaceWidth) vm.drawSurfaceWidth = drawSamplesCount;

    // const samplesPerPixel = Math.floor(drawSamplesCount / vm.drawSurfaceWidth);
    // const samplesPerPixelRest = drawSamplesCount % vm.drawSurfaceWidth;
    // // 0
    // const samplesPerEnvelope = samplesPerPixel * 2; //why multiply by 2? is it because we save min and max
    // let envelopeCounter = 0; 
    // let eventCounter = 0;

    
    // let sample;
    // let i = 0;
    // //n = vm.toSample;
    // for (;i<n;i++){ //n =128
    //   sample = samples[i];
    //   if (samplesPerPixel == 1 && samplesPerPixelRest == 0) {//7. is it 1:1 scale?
    //       vm.arrData[idxCounter]=(sample);
    //       idxCounter++;
    //       eventCounter = 0;
    //   } else {
    //       if (sample > max) max = sample;// 4. are we trying to get the most significant max min?  //short min = SHRT_MAX, max = SHRT_MIN;
    //       if (sample < min) min = sample;
    //       if (envelopeCounter == samplesPerEnvelope) {// if envelop counter equals with the samples that are supposed to be in envelope
    //           vm.arrData[idxCounter]=(max);
    //           idxCounter++;
    //           vm.arrData[idxCounter]=(min);
    //           idxCounter++;
  
    //           envelopeCounter = 0;
    //           max = -1000000000;
    //           min = 1000000000;

    //           eventCounter = 0;
    //       }

    //       envelopeCounter++;
    //   }
    // }    

    // vm.idx++;   
    // if (vm.idx>=Math.ceil(vm.limiter/2))
    // {
    //   // console.log(vm.arrData);
    // //0.008631458505988121, -0.010035599581897259

    //     vm.idx=0;
    //     let arrBuffer = ( new Int16Array(vm.drawBuffer) ).buffer;
    //     // let arrBuffer = (new Int16Array(vm.arrData)).buffer;
    //     workerForwardPort.postMessage(arrBuffer,[arrBuffer]);
    // }
    // delete samples;

  };

  switch( event.data.command )
  {
    case "initialize_drawing":
      vm.channelCount = event.data.channelCount;
      // vm.channelCount = event.data.channelCount;
      vm.channelIdx = event.data.channelIdx;
      console.log("initialize drawing " , vm.channelIdx, vm.channelCount);
    break;
    case "connect":
      console.log("connnect");
      signalworker2port = event.ports[0];
      signalworker2port.onmessage = onMessageFromWorker;
      vm.idx=0;
      vm.limiter = 4;
    break;

    case "setUp":
      if (event.data.divider !== undefined){
        divider = event.data.divider / 10;
      } 
      type = event.data.type;
      rawSabDraw= event.data.sabDraw;
      let c = 0;
      CHANNEL_COUNT_FIX = event.data.channelCount;
      for (; c < CHANNEL_COUNT_FIX ; c++){
        draw_states[c] = new Int32Array(rawSabDraw.draw_states[c]);
      }

      // let temp = new Int32Array(rawSabDraw.draw_states[0]);

      sabDrawing = rawSabDraw.levels;
      
      vm.drawSurfaceWidth = event.data.drawSurfaceWidth;
      vm.level = draw_states[0][DRAW_STATE.LEVEL];
      vm.skip_counts = draw_states[0][DRAW_STATE.SKIP_COUNTS];
      divider = draw_states[0][DRAW_STATE.DIVIDER] / 10;
      vm.isDirect = draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE];
      // vm.fromSample = event.data.fromSample;
      // vm.toSample = event.data.toSample;
      // vm.level = event.data.level;
      // vm.sampleLength = event.data.sampleLength;

      eventsCounterInt = new Uint8Array(rawSabDraw.eventsCounter);
      eventPositionInt = new Uint32Array(rawSabDraw.eventPosition);
      eventPositionResultInt = new Float32Array(rawSabDraw.eventPositionResult);
      eventsInt = new Uint8Array(rawSabDraw.events);

      const sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];

      if (rawSabDraw === undefined){
        vm.drawBuffer = new Int16Array(vm.sampleLength / divider); // 10 seconds per 120 seconds
        vm.drawBuffer2 = new Int16Array(vm.sampleLength / divider); // it fix channel 2 slow drawing
      }else{
        console.log("SETUP with sabDraw data", Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]), sampleRate, divider, vm.level, arrCounts[vm.level]);
        // vm.drawBuffer = new Int32Array(rawSabDraw.levels[0]);
        if (vm.level == -1){
          vm.drawBuffer = new Int16Array( Math.floor(sampleRate * 60 / divider * 2 ) );
          vm.drawBuffer2 = new Int16Array( Math.floor(sampleRate * 60 / divider * 2 ) );
        }else{
          vm.drawBuffer = new Int16Array( Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]) );
          vm.drawBuffer2 = new Int16Array( Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]) );
        }

      }

      // vm.drawBuffer = new Int16Array(vm.sampleLength / divider); // 10 seconds per 120 seconds
      // console.log("DATE TIME ",p-(new Date()).getTime());
      // console.log(vm.sampleLength, divider);
      // vm.originalBuffer = new Int16Array(vm.sampleLength/divider); // 10 seconds per 120 seconds
      // console.log("vm.level", vm.level);

    break;

    case "sabcs":
      vm.rawSabcs = event.data.rawSabcs;
      vm.sabcs = vm.rawSabcs[0];
      vm.sabcs2 = vm.rawSabcs[1];

      console.log("vm.sabcs 0 11111",vm.sabcs);
      const playbackStates = new Uint32Array(rawSabDraw.playback_states[0]);

      // console.log(vm.sabcs);
      let StatesDraw = new Int32Array(vm.sabcs.statesDraw);
      let StatesDraw2;
      console.log("type", type);
      // console.log("vm.sabcs2");
      // console.log(vm.sabcs2);
      if (type == 'audio'){
        eventGlobalPositionInt = new Uint32Array(vm.sabcs.eventGlobalPosition);        
        if (vm.sabcs2 === undefined){
            while ( Atomics.wait(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0) === 'ok' ) {
              const sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];
              CHANNEL_COUNT_FIX = draw_states[0][DRAW_STATE.CHANNEL_COUNTS];

                vm.drawBuffer.fill(0);
                vm.isDirect = draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE];
    
              if (draw_states[0][DRAW_STATE.LEVEL] != vm.level || divider != draw_states[0][DRAW_STATE.DIVIDER]/10 || vm.drawSurfaceWidth != draw_states[0][DRAW_STATE.SURFACE_WIDTH]){
                vm.level = draw_states[0][DRAW_STATE.LEVEL];
                divider = draw_states[0][DRAW_STATE.DIVIDER] / 10;
                vm.drawSurfaceWidth = draw_states[0][DRAW_STATE.SURFACE_WIDTH];
                vm.skip_counts = draw_states[0][DRAW_STATE.SKIP_COUNTS];
                if (vm.level == -1){
                  vm.skip_counts = 1;
                  vm.drawBuffer = new Int16Array( Math.floor(sampleRate * 60 / divider * 2) );
                }else{
                  vm.drawBuffer = new Int16Array( Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]) );
                }
              }
      

              let c = 0;
              let envelopeSamples;
              // console.log(sabcs.arrMax);
              for (;c < CHANNEL_COUNT_FIX ; c++){
                const sabcs = vm.rawSabcs[c];
                if (vm.level == -1){
                  envelopeSamples = new Int16Array(sabcs.arrMax);
                }else{
                  envelopeSamples = new Int16Array(sabcs.sabEnvelopes[vm.level]);
                }
                const skipCounts = vm.skip_counts;
                let sabsConfig = new Int32Array(sabcs.config);
                // let head = 10000000;
                // head = sabsConfig[0];
                let head = sabsConfig[0];
                let tail = sabsConfig[5];
                let offsetHead = sabsConfig[7];
                // console.log("SIGNAL HEAD ", head, sabsConfig);
                const maxSize = (new Int16Array(sabcs.arrMax)).length;
                // const currentCap = sabsConfig[1];
                const currentCap = Math.floor(sabsConfig[7] / maxSize);
                const globalPositionCap = Math.floor(currentCap * maxSize /2);
                const nextGlobalPositionCap = Math.floor( (currentCap+1) * maxSize / 2 );
                    // console.log("globalPositionCap", globalPositionCap);
                // const isFull = globalPositionCap >= 1 ? true : false;
  
                const isFull = sabsConfig[1] >= 1 ? true : false;

                draw_states[0][DRAW_STATE.CURRENT_HEAD] = head;
                draw_states[0][DRAW_STATE.IS_FULL] = sabsConfig[1];
    
                const scrollHorizontalValue = playbackStates[PLAYBACK_STATE.DRAG_VALUE];
                const zoomHorizontalDifference = draw_states[0][DRAW_STATE.CURRENT_START]; //ZOOM DONOT DELETE
    
                if (zoomHorizontalDifference != 0){
                  head = head - Math.floor(zoomHorizontalDifference) ;
                  offsetHead = offsetHead - Math.floor(zoomHorizontalDifference) ;
                }
                if (scrollHorizontalValue > 0){
                  console.log("SCROLLING : ",zoomHorizontalDifference, head,scrollHorizontalValue, zoomHorizontalDifference == scrollHorizontalValue);
                  head = head - scrollHorizontalValue;
                  offsetHead = offsetHead - scrollHorizontalValue;
                }
          
                onMessageFromWorker({
                  data : {
                    skipCounts : skipCounts,
                    head : head,
                    tail : tail,
                    offsetHead : offsetHead,
                    isFull : isFull,
                    array : envelopeSamples,
                    globalPositionCap : globalPositionCap,                    
                    nextGlobalPositionCap : nextGlobalPositionCap,                
                    channelIdx : c,
                    drawBuffer : vm.drawBuffer,
                  }
                });
    
                const prevSegment = Math.floor( envelopeSamples.length/divider);
              
              
                let temp = new Int16Array(sabDrawing[c]);
                let starting = vm.drawBuffer.length - prevSegment;
                if (starting < 0 ) starting = 0;
    
                temp.set(vm.drawBuffer.slice(0),0);
                // console.log(temp);
                draw_states[c][DRAW_STATE.HEAD_IDX]=starting;
                draw_states[c][DRAW_STATE.TAIL_IDX]=vm.drawBuffer.length;
                  // console.log(temp);
              }
      
              Atomics.store(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0);
              if (isReducingMarkers == true){
                // console.log("reduceMarkers ", reduceMarkers);
                isReducingMarkers=false;
                reduceMarkers(1);
              }
    
    
            }
    
          return;    
        }
        StatesDraw2 = new Int32Array(vm.sabcs2.statesDraw);        
        while ( Atomics.wait(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0) === 'ok') {
          // console.log("vm.sabcs1 12323" );
          // const samples = new Int32Array(vm.sabcs.sabEnvelopes[6]);
          // const arr = samples.slice();
          // const skipCounts = 256;
          // const head = new Int32Array(vm.sabcs.config)[0];
          // const isFull = new Int32Array(vm.sabcs.config)[1] == 1 ? true : false;
          // const envelopeSamples = arr;
          const sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];
          CHANNEL_COUNT_FIX = draw_states[0][DRAW_STATE.CHANNEL_COUNTS];
          // if (vm.isDirect != draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE]){
          //   vm.drawBuffer.fill(0);
          //   vm.isDirect = draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE];
          // }
          if (draw_states[0][DRAW_STATE.LEVEL] != vm.level || divider != draw_states[0][DRAW_STATE.DIVIDER]/10 || vm.drawSurfaceWidth != draw_states[0][DRAW_STATE.SURFACE_WIDTH]){
            vm.level = draw_states[0][DRAW_STATE.LEVEL];
            divider = draw_states[0][DRAW_STATE.DIVIDER] / 10;
            vm.drawSurfaceWidth = draw_states[0][DRAW_STATE.SURFACE_WIDTH];
            vm.skip_counts = draw_states[0][DRAW_STATE.SKIP_COUNTS];
            if (vm.level == -1){
              vm.skip_counts = 1;
              vm.drawBuffer = new Int16Array( Math.floor(sampleRate * 60 / divider * 2) );
            }else{
              vm.drawBuffer = new Int16Array( Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]) );
            }

          }

          vm.drawBuffer.fill(0);
  
            // const arrCounts = [ 4, 8, 16, 32, 64, 128, 256 ];
            // const arrTimescale = [ 600000,60000, 6000, 1200, 600, 120, 60, 12, 6 ];
            // let rawPocket = timescale * sampleRate / window.innerWidth /1000;
            //LENGTH  5 44100 12 128 3445 3445
            //LENGTH  3 44100 60 32 3445 2756
            //LENGTH  -1 44100 600 undefined 6890 8820
          // console.log("LENGTH ", (sampleRate * 60 / divider * 2 / arrCounts[vm.level]), sampleRate, divider,arrCounts[vm.level], vm.level, sabDrawing[0].byteLength/Int32Array.BYTES_PER_ELEMENT,vm.drawBuffer.length);
          // console.log("vm.level",vm.level, vm.drawBuffer.buffer.byteLength , " @ ", sabDrawing[vm.level].byteLength);
          // if (vm.drawBuffer.buffer.byteLength != sabDrawing[vm.level].byteLength){
          // }
    
    
          // const samples = new Int32Array(vm.sabcs.sabEnvelopes[vm.level]);
          // const arr = samples.slice();
          // const arr = samples.slice();
          // const envelopeSamples = arr;
  
          let c = 0;
          let envelopeSamples;
          // console.log(sabcs.arrMax);
          for (;c < CHANNEL_COUNT_FIX ; c++){
            const sabcs = vm.rawSabcs[c];
            if (vm.level == -1){
              envelopeSamples = new Int16Array(sabcs.arrMax);
            }else{
              // if (c ==1){
              //   // console.log("sabcs",vm.rawSabcs);
              // }
              envelopeSamples = new Int16Array(sabcs.sabEnvelopes[vm.level]);
            }

            // console.log("PLAYBACK AUDIO PARAMETERS ", vm.level, sampleRate, vm.skip_counts, divider, vm.drawBuffer, arrCounts[vm.level], Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]), envelopeSamples.length);
            // SIGNAL vm.level  2 skipcounts16 divider66 drawbufferInt16Array(5011) arrCounts16 calculation5011 envelopeSamples330750
            // vm.level 3 skipcounts 32 divider6.6 Int16Array(27272) 32 27272 180000

            const skipCounts = vm.skip_counts;
            const sabsConfig = new Int32Array(sabcs.config);
            let head = sabsConfig[0];
            let tail = sabsConfig[5];
            let offsetHead = sabsConfig[7];

            // const maxSize = (new Int16Array(sabcs.arrMax)).length;
            const maxSize = sampleRate * NUMBER_OF_SEGMENTS;
            // const currentCap = sabsConfig[1];
            // const currentCap = Math.floor(sabsConfig[7] / (maxSize / 2));
            const currentCap = Math.floor(sabsConfig[7] / maxSize);
            const globalPositionCap = Math.floor(currentCap * maxSize);
            const nextGlobalPositionCap = Math.floor( (currentCap+1) * maxSize );
            // const isFull = globalPositionCap >= 1 ? true : false;
            // console.log("globalPositionCap", globalPositionCap);

            const isFull = sabsConfig[1] >= 1 ? true : false;

            draw_states[0][DRAW_STATE.CURRENT_HEAD] = head;
            draw_states[0][DRAW_STATE.IS_FULL] = sabsConfig[1];

            const scrollHorizontalValue = playbackStates[PLAYBACK_STATE.DRAG_VALUE];
            const zoomHorizontalDifference = draw_states[0][DRAW_STATE.CURRENT_START]; //ZOOM DONOT DELETE

            if (zoomHorizontalDifference != 0){
              head = head - Math.floor(zoomHorizontalDifference) ;
              offsetHead = offsetHead - Math.floor(zoomHorizontalDifference) ;
            }
            if (scrollHorizontalValue > 0){
              console.log("SCROLLING : ",zoomHorizontalDifference, head,scrollHorizontalValue, zoomHorizontalDifference == scrollHorizontalValue);
              head = head - scrollHorizontalValue;
              offsetHead = offsetHead - scrollHorizontalValue;
            }
      

            // const scrollHorizontalStart = draw_states[0][DRAW_STATE.CURRENT_START];
            // // console.log("scrollHorizontalStart : ",scrollHorizontalStart);


            // if (scrollHorizontalStart != 0){
            //   // console.log("SCROLL HEAD0 ", head, scrollHorizontalStart);
            //   head = head - Math.floor(scrollHorizontalStart);
            //   // console.log("SCROLL HEAD ", head, scrollHorizontalStart);
            // }
            
            onMessageFromWorker({
              data : {
                skipCounts : skipCounts,
                offsetHead : offsetHead,
                head : head,
                tail : tail,
                isFull : isFull,
                array : envelopeSamples,
                globalPositionCap : globalPositionCap,                
                nextGlobalPositionCap : nextGlobalPositionCap,                
                channelIdx : c,
                drawBuffer : c==0 ? vm.drawBuffer : vm.drawBuffer2,

              }
            });

         
          //set sab with drawBufer
          //rawSabDraw & sabDrawing
          // console.log("vm.channelCount", vm.channelCount);

            const prevSegment = Math.floor( envelopeSamples.length/divider);
          
              

            let temp = new Int16Array(sabDrawing[c]);
            let starting = vm.drawBuffer.length - prevSegment;
            if (starting < 0 ) starting = 0;

            temp.set(vm.drawBuffer,0);

            // console.log(temp);
            draw_states[c][DRAW_STATE.HEAD_IDX]=starting;
            draw_states[c][DRAW_STATE.TAIL_IDX]=vm.drawBuffer.length;
              // console.log(temp);
          }
          
  
  
          Atomics.store(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0);
          Atomics.store(StatesDraw2, STATE.REQUEST_SIGNAL_REFORM, 0);
          if (isReducingMarkers == true){
            // console.log("reduceMarkers ", reduceMarkers);
            isReducingMarkers=false;
            reduceMarkers(1);
          }


        }
      }else
      if (type == 'serial'){
        console.log("sabcs2 undefined", StatesDraw[STATE.REQUEST_SIGNAL_REFORM]);
        while ( Atomics.wait(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0) === 'ok' ) {
          // console.log("vm.sabcs1 12323" );
          const sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];
          CHANNEL_COUNT_FIX = draw_states[0][DRAW_STATE.CHANNEL_COUNTS];
          vm.drawBuffer.fill(0);
          if (draw_states[0][DRAW_STATE.LEVEL] != vm.level || divider != draw_states[0][DRAW_STATE.DIVIDER]/10){
            vm.level = draw_states[0][DRAW_STATE.LEVEL];
            divider = draw_states[0][DRAW_STATE.DIVIDER];
            vm.skip_counts = draw_states[0][DRAW_STATE.SKIP_COUNTS];
            if (vm.level == -1){
              vm.skip_counts = 1;
              vm.drawBuffer = new Int16Array( Math.floor(sampleRate * 60 / divider * 2) );
            }else{
              vm.drawBuffer = new Int16Array( Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]) );
            }
          }
  
          let c = 0;
          let envelopeSamples;
          // console.log(sabcs.arrMax);
          // for (;c < CHANNEL_COUNT_FIX ; c++){
          for (;c < 1 ; c++){
            const sabcs = vm.rawSabcs[c];
            if (vm.level == -1){
              envelopeSamples = new Int16Array(sabcs.arrMax);
            }else{
              envelopeSamples = new Int16Array(sabcs.sabEnvelopes[vm.level]);
            }
            const skipCounts = vm.skip_counts;
            const head = new Int32Array(sabcs.config)[0];
            const isFull = new Int32Array(sabcs.config)[1] == 1 ? true : false;
  
            onMessageFromWorker({
              data : {
                skipCounts : skipCounts,
                head : head,
                isFull : isFull,
                array : envelopeSamples,
                channelIdx : c,

              }
            });
  
            let temp = new Int16Array(sabDrawing[c]);
            temp.set(vm.drawBuffer,0);
            // console.log(temp);
            draw_states[c][DRAW_STATE.HEAD_IDX]=0;
            draw_states[c][DRAW_STATE.TAIL_IDX]=vm.drawBuffer.length-1;
          }
          
  
          Atomics.store(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0);
        }           
      }
      // let sampleLength = 44100 * 60 * 2 / 256;
      // vm.drawBuffer = new Int32Array(sampleLength / divider *2 ); // 10 seconds per 120 seconds

    break;    

    case "forward":
      workerForwardPort = event.ports[0];
    break;

    default:
      console.log( event.data );
  }
};