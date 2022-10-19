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
var arrCounts = [ 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048 ];
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


self.onmessage = function( event ) {
  var onMessageFromWorker = function( e ){
    const skipCounts = e.data.skipCounts;
    const head = Math.floor(e.data.head/skipCounts);
    const isFull = e.data.isFull;
    const globalPositionCap = e.data.globalPositionCap;    
    const currentCap = e.data.currentCap + 1;
    const halfwayCap = globalPositionCap - Math.floor( (globalPositionCap * 0.2) / currentCap );

    const drawBuffer = e.data.drawBuffer;

    const envelopeSamples = e.data.array;
    const rawLength = envelopeSamples.length;
    const bufferLength = drawBuffer.length;
    const channelIdx = e.data.channelIdx;

    const prevSegment = Math.floor( envelopeSamples.length/divider);
    let start = head * 2 - prevSegment;
    let to = head * 2;
    
    const evtCounter = eventsCounterInt[0];
    const excess = bufferLength - prevSegment;
    // console.log("excess : ", excess);
    
    const nearFull = head * 2 + prevSegment;
    if (!isFull && nearFull <= envelopeSamples.length){
      if (start < 0 ) start = 0;
      if (channelIdx == 0){
        eventPositionResultInt.fill(0);
        for ( let ctr = 0; ctr < evtCounter; ctr++ ){
          if (eventGlobalPositionInt[ctr] >= globalPositionCap){
            const headPosition = Math.floor(eventPositionInt[ctr] / skipCounts * 2); // headPosition in envelope realm
            if ( headPosition < start ) {
              eventPositionResultInt[ctr] = 0;
              isReducingMarkers = true;
            }else//{
            if (headPosition >= start && headPosition <= to){
              eventPositionResultInt[ctr] = ( bufferLength - excess - (to - (headPosition)) ) / bufferLength * vm.drawSurfaceWidth;
            }
          }        
        }
  
      }
  
      const subarray = envelopeSamples.subarray(start,to);
      if (subarray.length < bufferLength){
        const pos = bufferLength - subarray.length  - 1;
        drawBuffer.fill(0,0,pos);
        drawBuffer.set(subarray, pos );
      }else{
        try{
          start = to - drawBuffer.length;
          const subarray2 = envelopeSamples.subarray(start,to);

          drawBuffer.set(subarray2, 0 );
        }catch(err){
          console.log(drawBuffer.length, subarray.length);
        }
      }
    }else{
      let segmentCount = prevSegment;
      if (start<0){
        const processedHead = head * 2;
        segmentCount = segmentCount - processedHead - 1;
        start = envelopeSamples.length - segmentCount;
        const firstPartOfData = envelopeSamples.subarray(start);
        const secondPartOfData = envelopeSamples.subarray(0, processedHead+1);
        const secondIdx = bufferLength - secondPartOfData.length - 1;
        if (secondPartOfData.length>0){
          try{
            drawBuffer.set(firstPartOfData, 0);  
            drawBuffer.set(secondPartOfData, firstPartOfData.length);  
          }catch(err){
            console.log(err);
          }
        }else{
          drawBuffer.set(firstPartOfData, bufferLength - firstPartOfData.length-1);  
        }

        if (channelIdx == 0){
          eventPositionResultInt.fill(0);

          for ( let ctr = 0; ctr < evtCounter; ctr++ ){
            if (eventGlobalPositionInt[ctr] >= halfwayCap){
              const headPosition = Math.floor(eventPositionInt[ctr] / skipCounts * 2); // headPosition in envelope realm
              if ( headPosition < start && headPosition > to) {
                eventPositionResultInt[ctr] = 0;
                isReducingMarkers = true;
      
              }else{
                if ( headPosition <= envelopeSamples.length && headPosition>= start){ // upper
                  const counter = bufferLength - ( envelopeSamples.length - headPosition + secondPartOfData.length );
                  eventPositionResultInt[ctr] = counter / bufferLength * vm.drawSurfaceWidth;;
                }else//{ // headPosition < to // below
                if (headPosition <= to && headPosition >=0){
                  const counter = bufferLength - excess - ( to - (headPosition) );
                  eventPositionResultInt[ctr] = counter / bufferLength * vm.drawSurfaceWidth;;
                }

              }          
            }
          }
        }


      }else{
        start = start;
        const subarray = envelopeSamples.subarray(start,to);
        const startIdx = bufferLength - subarray.length;
        drawBuffer.set(subarray, startIdx);


        if (channelIdx == 0){
          eventPositionResultInt.fill(0);

          for ( let ctr = 0; ctr < evtCounter; ctr++ ){
            if (eventGlobalPositionInt[ctr] >= globalPositionCap){
  
              const headPosition = Math.floor(eventPositionInt[ctr] / skipCounts * 2); // headPosition in envelope realm
              if ( headPosition < start) {
                eventPositionResultInt[ctr] = 0;
                isReducingMarkers = true;
              }else//{
              if (headPosition >= start && headPosition <= to){
                eventPositionResultInt[ctr] = ( bufferLength - excess - (to - (headPosition)) ) / bufferLength * vm.drawSurfaceWidth;;
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
      sabDrawing = rawSabDraw.levels;
      
      vm.drawSurfaceWidth = event.data.drawSurfaceWidth;
      vm.level = draw_states[0][DRAW_STATE.LEVEL];
      vm.skip_counts = draw_states[0][DRAW_STATE.SKIP_COUNTS];
      divider = draw_states[0][DRAW_STATE.DIVIDER] / 10;
      vm.isDirect = draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE];

      eventsCounterInt = new Uint8Array(rawSabDraw.eventsCounter);
      eventPositionInt = new Uint32Array(rawSabDraw.eventPosition);
      eventPositionResultInt = new Float32Array(rawSabDraw.eventPositionResult);
      eventsInt = new Uint8Array(rawSabDraw.events);

      const sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];

      if (rawSabDraw === undefined){
        vm.drawBuffer = new Int16Array(vm.sampleLength / divider); // 10 seconds per 120 seconds
        vm.drawBuffer2 = new Int16Array(vm.sampleLength / divider);
      }else{
        console.log("SETUP with sabDraw data", Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]), sampleRate, divider, vm.level, arrCounts[vm.level]);
        vm.drawBuffer = new Int16Array( Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]) );
        vm.drawBuffer2 = new Int16Array( Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]) );

      }


    break;

    case "sabcs":
      vm.rawSabcs = event.data.rawSabcs;
      vm.sabcs = vm.rawSabcs[0];
      vm.sabcs2 = vm.rawSabcs[1];

      console.log("vm.sabcs 0 11111",vm.sabcs);

      let StatesDraw = new Int32Array(vm.sabcs.statesDraw);
      let StatesDraw2;
      console.log("type", type);
      if (type == 'audio'){
        eventGlobalPositionInt = new Uint32Array(vm.sabcs.eventGlobalPosition);


        if (vm.sabcs2 === undefined){

            while ( Atomics.wait(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0) === 'ok' ) {
              if (channelIdx == 0){
                eventPositionResultInt.fill(0);
              }
        
              const sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];
              CHANNEL_COUNT_FIX = draw_states[0][DRAW_STATE.CHANNEL_COUNTS];

              if (draw_states[0][DRAW_STATE.LEVEL] != vm.level || divider != draw_states[0][DRAW_STATE.DIVIDER]/10 || (vm.drawSurfaceWidth != draw_states[0][DRAW_STATE.SURFACE_WIDTH] && draw_states[0][DRAW_STATE.SURFACE_WIDTH] > 0)){
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
              for (;c < CHANNEL_COUNT_FIX ; c++){
                const sabcs = vm.rawSabcs[c];
                if (vm.level == -1){
                  envelopeSamples = new Int16Array(sabcs.arrMax);
                }else{
                  envelopeSamples = new Int16Array(sabcs.sabEnvelopes[vm.level]);
                }

                const skipCounts = vm.skip_counts;
                let sabsConfig = new Int32Array(sabcs.config);
                let head = sabsConfig[0];
                console.log("SIGNAL HEAD ", head, sabsConfig);
                const maxSize = (new Int16Array(sabcs.arrMax)).length;
                const currentCap = sabsConfig[1];
                const globalPositionCap = Math.floor(sabsConfig[1] * maxSize / 2);
  
                const isFull = sabsConfig[1] >= 1 ? true : false;
    
                draw_states[0][DRAW_STATE.CURRENT_HEAD] = head;
                draw_states[0][DRAW_STATE.IS_FULL] = sabsConfig[1];
    
                const scrollHorizontalValue = draw_states[0][DRAW_STATE.HORIZONTAL_DRAG];
                const zoomHorizontalDifference = draw_states[0][DRAW_STATE.CURRENT_START];
    
                if (zoomHorizontalDifference != 0){
                  head = head - Math.floor(zoomHorizontalDifference) ;
                }
                if (scrollHorizontalValue != 0){
                  console.log("DATA : ",zoomHorizontalDifference,scrollHorizontalValue);
                  head = head - scrollHorizontalValue;
                }
          
                onMessageFromWorker({
                  data : {
                    skipCounts : skipCounts,
                    head : head,
                    isFull : isFull,
                    array : envelopeSamples,
                    globalPositionCap : globalPositionCap,
                    currentCap : currentCap,
                    channelIdx : c,
                    drawBuffer : vm.drawBuffer
                  }
                });
    
                const prevSegment = Math.floor( envelopeSamples.length/divider);
              
              
                let temp = new Int16Array(sabDrawing[c]);
                let starting = vm.drawBuffer.length - prevSegment;
                if (starting < 0 ) starting = 0;

                if (c==0)
                  temp.set(vm.drawBuffer,0);
                else
                  temp.set(vm.drawBuffer2,0);
                // console.log(temp);
                draw_states[c][DRAW_STATE.HEAD_IDX]=starting;
                draw_states[c][DRAW_STATE.TAIL_IDX]=vm.drawBuffer.length;
              }
      
              Atomics.store(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0);
    
    
            }
    
          return;    
        }
        StatesDraw2 = new Int32Array(vm.sabcs2.statesDraw);        
        while ( Atomics.wait(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0) === 'ok'  && Atomics.wait(StatesDraw2, STATE.REQUEST_SIGNAL_REFORM, 0) === 'ok') {
          if (channelIdx == 0){
            eventPositionResultInt.fill(0);
          }

          const sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];
          CHANNEL_COUNT_FIX = draw_states[0][DRAW_STATE.CHANNEL_COUNTS];
          if (draw_states[0][DRAW_STATE.LEVEL] != vm.level || divider != draw_states[0][DRAW_STATE.DIVIDER]/10 || (vm.drawSurfaceWidth != draw_states[0][DRAW_STATE.SURFACE_WIDTH] && draw_states[0][DRAW_STATE.SURFACE_WIDTH] > 0)){
            vm.level = draw_states[0][DRAW_STATE.LEVEL];
            divider = draw_states[0][DRAW_STATE.DIVIDER] / 10;
            vm.drawSurfaceWidth = draw_states[0][DRAW_STATE.SURFACE_WIDTH];
            vm.skip_counts = draw_states[0][DRAW_STATE.SKIP_COUNTS];
            if (vm.level == -1){
              vm.skip_counts = 1;
              vm.drawBuffer = new Int16Array( Math.floor(sampleRate * 60 / divider * 2) );
              vm.drawBuffer2 = new Int16Array( Math.floor(sampleRate * 60 / divider * 2) );
            }else{
              vm.drawBuffer = new Int16Array( Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]) );
              vm.drawBuffer2 = new Int16Array( Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]) );
            }
          }
  
          let c = 0;
          let envelopeSamples;
          for (;c < CHANNEL_COUNT_FIX ; c++){
            const sabcs = vm.rawSabcs[c];
            if (vm.level == -1){
              envelopeSamples = new Int16Array(sabcs.arrMax);
            }else{
              envelopeSamples = new Int16Array(sabcs.sabEnvelopes[vm.level]);
            }
            const skipCounts = vm.skip_counts;
            const sabsConfig = new Int32Array(sabcs.config);
            let head = sabsConfig[0];
            const maxSize = (new Int16Array(sabcs.arrMax)).length;
            const currentCap = sabsConfig[1];
            const globalPositionCap = Math.floor(sabsConfig[1] * maxSize /2);

            const isFull = sabsConfig[1] >= 1 ? true : false;

            draw_states[0][DRAW_STATE.CURRENT_HEAD] = head;
            draw_states[0][DRAW_STATE.IS_FULL] = sabsConfig[1];

            const scrollHorizontalValue = draw_states[0][DRAW_STATE.HORIZONTAL_DRAG];
            const zoomHorizontalDifference = draw_states[0][DRAW_STATE.CURRENT_START];

            if (zoomHorizontalDifference != 0){
              head = head - Math.floor(zoomHorizontalDifference) ;
            }
            if (scrollHorizontalValue != 0){
              console.log("DATA : ",zoomHorizontalDifference,scrollHorizontalValue);
              head = head - scrollHorizontalValue;
            }

            if (c == 0){
              vm.drawBuffer.fill(0);
            }else{
              vm.drawBuffer2.fill(0);
            }
            onMessageFromWorker({
              data : {
                skipCounts : skipCounts,
                head : head,
                isFull : isFull,
                array : envelopeSamples,
                globalPositionCap : globalPositionCap,
                currentCap : currentCap,
                channelIdx : c,
                drawBuffer : c==0 ? vm.drawBuffer : vm.drawBuffer2,
              }
            });

         
            const prevSegment = Math.floor( envelopeSamples.length/divider);
          
          
            let temp = new Int16Array(sabDrawing[c]);
            let starting = vm.drawBuffer.length - prevSegment;
            if (starting < 0 ) starting = 0;
            if (c == 0){

              temp.set(vm.drawBuffer.slice(0),0);
              draw_states[c][DRAW_STATE.HEAD_IDX]=starting;
              draw_states[c][DRAW_STATE.TAIL_IDX]= vm.drawBuffer.length;
  
            }else{
              temp.set(vm.drawBuffer2.slice(0),0);
              draw_states[c][DRAW_STATE.HEAD_IDX]=starting;
              draw_states[c][DRAW_STATE.TAIL_IDX]= vm.drawBuffer2.length;
            }
                        // console.log(temp);
            if (starting != 0){
              console.log("startin : ", starting);
            }
          }
          
  
  
          Atomics.store(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0);
          Atomics.store(StatesDraw2, STATE.REQUEST_SIGNAL_REFORM, 0);


        }
      }else
      if (type == 'serial'){
        console.log("sabcs2 undefined", StatesDraw[STATE.REQUEST_SIGNAL_REFORM]);
        while ( Atomics.wait(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0) === 'ok' ) {
          const sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];
          CHANNEL_COUNT_FIX = draw_states[0][DRAW_STATE.CHANNEL_COUNTS];
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
                array : envelopeSamples
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

    break;    

    case "forward":
      workerForwardPort = event.ports[0];
    break;

    default:
      console.log( event.data );
  }
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