let eventsCounterInt;
let eventsInt;
let eventPositionInt;
let eventGlobalPositionInt;
let eventPositionResultInt;

let CHANNEL_COUNT_FIX=1;
let type = 'audio';
const arrTimescale = [ 600000,60000, 6000, 1200, 600, 120, 60, 12, 6 ];

let isPrint = 2;
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


const SIZE_LOGS2 = 10;
const NUMBER_OF_SEGMENTS = 60;
const SEGMENT_SIZE = 10000;
const SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;

var signalworker2port;
var workerForwardPort;
var displayWidth;
let vm = this;

// var arrCounts = [ 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288 ];
let sabDrawing = [];
let rawSabDraw;
var arrCounts = [ 4, 8, 16, 32, 64, 128, 256, 512,1024, 2048 ];
var skipCounts = new Uint32Array(arrCounts);
let divider = 6;
let draw_states = [
  new Int32Array(Int32Array.BYTES_PER_ELEMENT * 8),
  new Int32Array(Int32Array.BYTES_PER_ELEMENT * 8),
  new Int32Array(Int32Array.BYTES_PER_ELEMENT * 8),
  new Int32Array(Int32Array.BYTES_PER_ELEMENT * 8),
  new Int32Array(Int32Array.BYTES_PER_ELEMENT * 8),
  new Int32Array(Int32Array.BYTES_PER_ELEMENT * 8),
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
    const skipCounts = e.data.skipCounts;
    // eventsCounterInt = new Uint8Array(rawSabDraw.eventsCounter);
    // eventPositionInt = new Uint8Array(rawSabDraw.eventPosition);
    // eventsInt = new Uint8Array(rawSabDraw.events);


    const head = Math.floor(e.data.head/skipCounts); // idx of particular envelope
    const isFull = e.data.isFull;
    const globalPositionCap = e.data.globalPositionCap;    
    const currentCap = e.data.currentCap + 1;
    // const halfwayCap = globalPositionCap * 0.8;
    const halfwayCap = globalPositionCap - Math.floor( (globalPositionCap * 0.2) / currentCap );
    const channelIdx = e.data.channelIdx;

    const envelopeSamples = e.data.array;
    const sampleRate = e.data.sampleRate;
    const maxSampleRate = e.data.maxSampleRate;
    // console.log("sampleRate : ",sampleRate, maxSampleRate);
    // console.log("SKIP COUNTZ : ",skipCounts);
    // let sabDraw = new Int16Array(e.data.sabDraw);

    // const rawLength = envelopeSamples.length;
    const bufferLength = vm.drawBuffer.length;

    // sampleRate is already priced in using the maximum samplerate
    let prevSegment;
    if (maxSampleRate == 0){ // loading data is loading wav sampleRate (1666,2000,etc), so do not need maxSampleRate
      prevSegment = Math.floor( envelopeSamples.length/divider * sampleRate );
    }else{
      prevSegment = Math.floor( envelopeSamples.length/divider * sampleRate / maxSampleRate);
    }
    // console.log("prevSegment : ", prevSegment, envelopeSamples.length, sampleRate, skipCounts);
    //prevSegment1562 fullEnvelopeSamples9375 sampleRate10000 skipCounts128
    // 10000 * 60 * 2 /6

    // Envelope Samples
    // 10000 * 60 * 2 / 6
    // if the sample rate decreased,
    // 5000 * 60 * 2 / 6 => immediately the draw buffer became smaller, but the envelope samples is not
    let start = head * 2 - prevSegment;
    let to = head * 2;

    const evtCounter = eventsCounterInt[0];
    const excess = bufferLength - prevSegment;
    const nearFull = start + prevSegment;
    if (channelIdx == 0)
      eventPositionResultInt.fill(0);

    if (!isFull && nearFull <= envelopeSamples.length){
      if (start < 0 ) start = 0;
      if (channelIdx == 0){
        for ( let ctr = 0; ctr < evtCounter; ctr++ ){
          if (eventGlobalPositionInt[ctr] >= globalPositionCap){

            const headPosition = Math.floor(eventPositionInt[ctr] / skipCounts * 2) ; // headPosition in envelope realm
            if ( headPosition < start) {
              eventPositionResultInt[ctr] = 0;
              isReducingMarkers = true;
            }else//{
            if (headPosition >= start && headPosition <= to){
    
              eventPositionResultInt[ctr] = ( bufferLength - excess - (to - (headPosition)) ) / bufferLength * vm.drawSurfaceWidth;;
              // console.log("eventPositionResultInt ","width  : ", vm.drawSurfaceWidth, eventPositionResultInt[ctr], ctr, start, to);
            }
          }
          
        }  
      }



      const subarray = envelopeSamples.subarray(start,to);
      if (subarray.length < bufferLength){
        // console.log(" !isFull 1 subarray.length < bufferLength");
        // sabDraw.set(subarray, bufferLength - subarray.length  - 1 );
        const pos = bufferLength - subarray.length  - 1;
        vm.drawBuffer.fill(0,0,pos);
        vm.drawBuffer.set(subarray, pos );
        // vm.drawBuffer.set(subarray, 0 );
      }else{
        try{
          start = to - vm.drawBuffer.length;
          const subarray2 = envelopeSamples.subarray(start,to);

          // sabDraw.set(subarray2, 0 );
          vm.drawBuffer.set(subarray2, 0 );
        }catch(err){
          console.log(vm.drawBuffer.length, subarray.length);
        }
        // console.log(" !isFull 2 subarray.length >= bufferLength");

      }
    }else{
      let segmentCount = prevSegment;
      if (start<0){
        // console.log(" isFull 3 start<0");

        const processedHead = head * 2;
        segmentCount = segmentCount - processedHead - 1;
        start = envelopeSamples.length - segmentCount;
        const firstPartOfData = envelopeSamples.subarray(start);
        const secondPartOfData = envelopeSamples.subarray(0, processedHead+1);
        const secondIdx = bufferLength - secondPartOfData.length - 1;
        if (secondPartOfData.length>0){
          // sabDraw.set(secondPartOfData, secondIdx);
          // sabDraw.set(firstPartOfData, secondIdx - firstPartOfData.length);

          // vm.drawBuffer.set(firstPartOfData, secondIdx - firstPartOfData.length);
          vm.drawBuffer.set(firstPartOfData, 0);
          vm.drawBuffer.set(secondPartOfData, firstPartOfData.length);

          // vm.drawBuffer.set(firstPartOfData, 0);  
          // vm.drawBuffer.set(secondPartOfData, firstPartOfData.length);
        }else{
        // if (headPosition >= start && headPosition <= to){
          // console.log(" isFull 4 start<0");
          // sabDraw.set(firstPartOfData, bufferLength - firstPartOfData.length-1);  
          vm.drawBuffer.set(firstPartOfData, bufferLength - firstPartOfData.length-1);  

          // vm.drawBuffer.set(firstPartOfData, 0);  
        }

        if (channelIdx == 0){

          for ( let ctr = 0; ctr < evtCounter; ctr++ ){
            const headPosition = Math.floor(eventPositionInt[ctr] / skipCounts * 2 ); // headPosition in envelope realm
            if (eventGlobalPositionInt[ctr] >= halfwayCap){

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
            }
          }
        }
      }else{
        // console.log(" isFull 3 start>=0");
        start = start;
        const subarray = envelopeSamples.subarray(start,to);
        const startIdx = bufferLength - subarray.length;
        // console.log(start, to, startIdx, bufferLength);
        
        // sabDraw.set(subarray, startIdx);
        try{
          vm.drawBuffer.set(subarray, startIdx);
        }catch(err){
          console.log("Error here","start : ", start, "to : ",to, "startIdx : ", startIdx, "bufferLength : ",bufferLength, "subarray : ", subarray.length);
        }
        // vm.drawBuffer.set(subarray, 0);
        if (channelIdx == 0){
          for ( let ctr = 0; ctr < evtCounter; ctr++ ){
            if (eventGlobalPositionInt[ctr] >= globalPositionCap){
 
              const headPosition = Math.floor(eventPositionInt[ctr] / skipCounts * 2 ); // headPosition in envelope realm
              if ( headPosition < start) {
                eventPositionResultInt[ctr] = 0;
                isReducingMarkers = true;
              }else//{
              if (headPosition >= start && headPosition <= to){

                // console.log("middle");
                // eventPositionResultInt[ctr] = prevSegment - excess - ( to - (headPosition) );
                eventPositionResultInt[ctr] = ( bufferLength - excess - (to - (headPosition)) ) / bufferLength * vm.drawSurfaceWidth;
              }
            }
            
          }        
        }
      }
    }

  };

  switch( event.data.command )
  {
    case "initialize_drawing":
      vm.channelCount = event.data.channelCount;
      vm.channelIdx = event.data.channelIdx;
    break;
    case "connect":
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
      // CHANNEL_COUNT_FIX = event.data.channelCount;
      // for (; c < CHANNEL_COUNT_FIX ; c++){
      for (; c < 6 ; c++){
        draw_states[c] = new Int32Array(rawSabDraw.draw_states[c]);
      }

      sabDrawing = rawSabDraw.levels;
      
      vm.drawSurfaceWidth = event.data.drawSurfaceWidth;
      vm.level = draw_states[0][DRAW_STATE.LEVEL];
      vm.skip_counts = draw_states[0][DRAW_STATE.SKIP_COUNTS];
      // vm.level = -1;
      // vm.skip_counts = 1;
      divider = draw_states[0][DRAW_STATE.DIVIDER] / 10;
      vm.isDirect = draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE];

      eventsCounterInt = new Uint8Array(rawSabDraw.eventsCounter);
      eventPositionInt = new Uint32Array(rawSabDraw.eventPosition);
      eventPositionResultInt = new Float32Array(rawSabDraw.eventPositionResult);
      
      eventsInt = new Uint8Array(rawSabDraw.events);

      const sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];

      if (rawSabDraw === undefined){
        vm.drawBufferLength = vm.sampleLength / divider;
        vm.drawBuffer = new Int16Array(vm.drawBufferLength); // 10 seconds per 120 seconds
      }else{
        vm.drawBufferLength = Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]);
        console.log("vm.drawBufferLength : ",vm.drawBufferLength);
        // vm.drawBufferLength = Math.floor(sampleRate * 60 / divider * 2 );
        vm.drawBuffer = new Int16Array( vm.drawBufferLength );
      }

      //SETUP :  10000 6 4 64 3125
      console.log("SETUP : ",sampleRate, divider, vm.level, arrCounts[vm.level], Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]));
    break;

    case "sabcs":
      vm.sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];
      vm.rawSabcs = event.data.rawSabcs;
      vm.sabcs = vm.rawSabcs[0];
      vm.sabcs2 = vm.rawSabcs[1];

      console.log("vm.sabcs 0 11111",vm.sabcs);

      let StatesDraw = new Int32Array(vm.sabcs.statesDraw);
      let StatesDraw2;
      console.log("type", type);
      if (type == 'serial'){
        console.log("sabcs2 undefined", StatesDraw[STATE.REQUEST_SIGNAL_REFORM]);
        // try{
          vm.isDirect = 1;
          eventGlobalPositionInt = new Uint32Array(vm.sabcs.eventGlobalPosition);

          while ( Atomics.wait(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0) === 'ok' ) {
            const sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];
            // vm.drawBufferLength = Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]);
            // // console.log("vm.drawBufferLength : ",vm.drawBufferLength);
            // vm.drawBuffer = new Int16Array( vm.drawBufferLength );
    
            isPrint = draw_states[0][DRAW_STATE.IS_LOG];
            // console.log("vm.sabcs1 12323", sampleRate );
            // console.log( "SIGNAL 1", (new Date()).getTime() )
  
            // console.log("DRAW_STATE.CHANNEL_COUNTS : ", draw_states[0][DRAW_STATE.CHANNEL_COUNTS]);
            // if (draw_states[0][DRAW_STATE.SAMPLE_RATE] != vm.sampleRate || draw_states[0][DRAW_STATE.LEVEL] != vm.level || divider != draw_states[0][DRAW_STATE.DIVIDER]/10 || CHANNEL_COUNT_FIX != draw_states[0][DRAW_STATE.CHANNEL_COUNTS] ){
            // if (draw_states[0][DRAW_STATE.LEVEL] != vm.level || divider != draw_states[0][DRAW_STATE.DIVIDER]/10 || CHANNEL_COUNT_FIX != draw_states[0][DRAW_STATE.CHANNEL_COUNTS] ){
              if (draw_states[0][DRAW_STATE.LEVEL] != vm.level || divider != draw_states[0][DRAW_STATE.DIVIDER]/10 || CHANNEL_COUNT_FIX != draw_states[0][DRAW_STATE.CHANNEL_COUNTS] || vm.drawSurfaceWidth != draw_states[0][DRAW_STATE.SURFACE_WIDTH]){
              // if ( CHANNEL_COUNT_FIX != draw_states[0][DRAW_STATE.CHANNEL_COUNTS] ){
              //   CHANNEL_COUNT_FIX = draw_states[0][DRAW_STATE.CHANNEL_COUNTS];
                
              //   let c=0;
              //   let envelopeSamples;
              // }

            // if ( divider != draw_states[0][DRAW_STATE.DIVIDER] || CHANNEL_COUNT_FIX != draw_states[0][DRAW_STATE.CHANNEL_COUNTS] ){
              vm.level = draw_states[0][DRAW_STATE.LEVEL];
              // vm.level = -1;
              vm.drawSurfaceWidth = draw_states[0][DRAW_STATE.SURFACE_WIDTH]
              vm.sampleRate = sampleRate;
        
              divider = draw_states[0][DRAW_STATE.DIVIDER] / 10; 
              // console.log("CHANGE SOMETHING! ", vm.level,divider);
              vm.skip_counts = draw_states[0][DRAW_STATE.SKIP_COUNTS];
              if (vm.level == -1){
                vm.skip_counts = 1;
                vm.drawBufferLength = Math.floor(sampleRate * 60 / divider * 2);
                vm.drawBuffer = new Int16Array( vm.drawBufferLength );
              }else{
                vm.drawBufferLength = Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]);
                vm.drawBuffer = new Int16Array( vm.drawBufferLength );
              }
            }
            CHANNEL_COUNT_FIX = draw_states[0][DRAW_STATE.CHANNEL_COUNTS];
            // console.log("Compare22 : ", vm.isDirect, draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE]);
            if (vm.isDirect != draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE]){
              vm.drawBuffer.fill(0);
              vm.isDirect = draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE];
            }
    
            let c = 0;
            let envelopeSamples;
            for (;c < CHANNEL_COUNT_FIX ; c++){
              try{

              const sabcs = vm.rawSabcs[0];
              if (vm.level == -1){
                switch( c )
                {
                  case 0:
                    envelopeSamples = new Int16Array(sabcs.arrMax);
                  break;
                  case 1:
                    envelopeSamples = new Int16Array(sabcs.arrMax2);
                  break;
                  case 2:
                    envelopeSamples = new Int16Array(sabcs.arrMax3);
                    break;
                  case 3:
                    envelopeSamples = new Int16Array(sabcs.arrMax4);
                  break;
                  case 4:
                    envelopeSamples = new Int16Array(sabcs.arrMax5);
                  break;
                  case 5:
                    envelopeSamples = new Int16Array(sabcs.arrMax6);
                  break;
                }
  
              }else{
                // console.log("sabcs.sabEnvelopes : ", vm.level);
                //envelopeSamples = new Int16Array(sabcs.sabEnvelopes[vm.level]);
                switch( c )
                {
                  case 0:
                    envelopeSamples = new Int16Array(sabcs.sabEnvelopes[vm.level]);
                  break;
                  case 1:
                    envelopeSamples = new Int16Array(sabcs.sabEnvelopes2[vm.level]);
                  break;
                  case 2:
                    envelopeSamples = new Int16Array(sabcs.sabEnvelopes3[vm.level]);
                    break;
                  case 3:
                    envelopeSamples = new Int16Array(sabcs.sabEnvelopes4[vm.level]);
                  break;
                  case 4:
                    envelopeSamples = new Int16Array(sabcs.sabEnvelopes5[vm.level]);
                  break;
                  case 5:
                    envelopeSamples = new Int16Array(sabcs.sabEnvelopes6[vm.level]);
                  break;
                }
              
              }
              const skipCounts = vm.skip_counts;
              // const head = new Int32Array(sabcs.config)[0];
              // console.log( "sabcs.arrHeads : ", new Uint32Array(sabcs.arrHeads) );
              // const temporary= new Uint32Array(sabcs.arrHeads);
              let head = new Uint32Array(sabcs.arrHeads)[c];
              // console.log("HEAD DRAW ", head);
              const maxSize = (new Int16Array(sabcs.arrMax)).length;
              const currentCap = (new Uint32Array(sabcs.arrIsFull)[c]);
              const globalPositionCap = Math.floor( currentCap* maxSize / 2);
              const isFull = currentCap >= 1 ? true : false;

              // const isFull = new Uint32Array(sabcs.arrIsFull)[c] == 1 ? true : false;
              

              if (c==0){
                draw_states[0][DRAW_STATE.CURRENT_HEAD] = head;
                draw_states[0][DRAW_STATE.IS_FULL] = isFull;
              }
  
              const scrollHorizontalStart = draw_states[0][DRAW_STATE.CURRENT_START];
              if (scrollHorizontalStart != 0){
                head = head - Math.floor(scrollHorizontalStart);
              }
      
              // const d = (new Date()).getTime();
              // console.log("SIGNAL DRAW", d );
  
              // if (isFull){
                // if (isPrint == 3){
                //   let i = new Int32Array(draw_states[0]);
                //   i[DRAW_STATE.IS_LOG] = 1;
                //   isPrint = 1;
                //   console.log( JSON.stringify(envelopeSamples, null, 1) );
                  
                // }
              // }
              // vm.drawBuffer.fill(0);
              const maxSampleRate = draw_states[0][DRAW_STATE.MAX_SAMPLING_RATE];
              // console.log("MAX_SAMPLING_RATE : ", maxSampleRate);
              let prevSegment;
              if (maxSampleRate == 0){
                prevSegment = Math.floor( envelopeSamples.length/divider * sampleRate );
              }else{
                prevSegment = Math.floor( envelopeSamples.length/divider * sampleRate / maxSampleRate);
              }
          
              // const prevSegment = Math.floor( envelopeSamples.length/divider ) * sampleRate / maxSampleRate;
              // const prevSegment = Math.floor( envelopeSamples.length/divider * sampleRate / maxSampleRate);
              let starting = vm.drawBuffer.length - prevSegment;
              if (starting < 0 ) starting = 0;
              onMessageFromWorker({
                data : {
                  skipCounts : skipCounts,
                  head : head,
                  isFull : isFull,
                  array : envelopeSamples,
                  sampleRate : sampleRate,
                  // maxSampleRate : draw_states[0][DRAW_STATE.MAX_SAMPLING_RATE],
                  maxSampleRate : maxSampleRate,
                  globalPositionCap : globalPositionCap,
                  currentCap : currentCap,
                  channelIdx : c,
                  // sabDraw: sabDrawing[c],
                }
              });
              // const now = (new Date()).getTime();
              // console.log("SIGNAL DRAW 2 ", now ,now - d );
  
  
              let temp = new Int16Array(sabDrawing[c]);
              temp.set(vm.drawBuffer.slice(0),0);
              // console.log(temp);
              draw_states[c][DRAW_STATE.HEAD_IDX]=starting;
              draw_states[c][DRAW_STATE.TAIL_IDX]=vm.drawBuffer.length;
              
              
              // let temp = new Int16Array(sabDrawing[c]);
              // temp.set(vm.drawBuffer,0);

              // temp.set(envelopeSamples,0);
              // console.log( JSON.stringify(vm.drawBuffer, null, 2) );
              // console.log("level v skipcounts : ", vm.level, skipCounts, envelopeSamples.length);
              // temp.set(envelopeSamples,0);
              // console.log("envelopeSamples");
              // console.log(envelopeSamples);

              // draw_states[c][DRAW_STATE.HEAD_IDX]=0;
              // draw_states[c][DRAW_STATE.TAIL_IDX]=vm.drawBuffer.length;

              // draw_states[c][DRAW_STATE.TAIL_IDX]=envelopeSamples.length;
              // if (c==1){
              //   console.log("channel");
              // }
  
              // draw_states[c][DRAW_STATE.TAIL_IDX]=(envelopeSamples.length-1);
              }catch(err){
                console.log("ATOMICS WAIT ", err);
              }
            }
            
            // console.log( "SIGNAL 2", (new Date()).getTime() )
   
            Atomics.store(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0);
            if (isReducingMarkers == true){
              // console.log("reduceMarkers ", reduceMarkers);
              isReducingMarkers=false;
              reduceMarkers(1);
            }
  
          }           
  

        // }catch(err){
        //   console.log("SIGNAL err");
        //   console.log(err);
        // }

      }
    break;    

    case "forward":
      workerForwardPort = event.ports[0];
    break;

    default:
      console.log( event.data );
  }
};