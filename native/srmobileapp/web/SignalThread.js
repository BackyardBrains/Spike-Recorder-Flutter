let MAX_SERIAL_CHANNELS = 6;
let eventsCounterInt;
let eventsInt;
let eventPositionInt;
let eventGlobalPositionInt;
let eventPositionResultInt;

let CHANNEL_COUNT_FIX=1;
let type = 'audio';
// const arrTimescale = [ 600000,60000, 6000, 1200, 600, 120, 60, 12, 6 ];

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


// const SIZE_LOGS2 = 10;
// const NUMBER_OF_SEGMENTS = 60;
// const SEGMENT_SIZE = 44100;
// const SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;

var signalworker2port;
var workerForwardPort;
var displayWidth;
let vm = this;

// var arrCounts = [ 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288 ];
let sabDrawing = [];
let sabDrawingInt = [];
let rawSabDraw;
var arrCounts;
var skipCounts;
// var arrCounts = [ 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048 ];
// var skipCounts = new Uint32Array(arrCounts);
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

const maxMinMultiplier = 2;
self.onmessage = function( event ) {
  var onMessageFromWorker = function( e ){
    const deviceType = e.data.deviceType;
    const skipCounts = e.data.skipCounts;
    const head = Math.floor(e.data.head/skipCounts);
    const isFull = e.data.isFull;
    const globalPositionCap = e.data.globalPositionCap;    
    const currentCap = e.data.currentCap + 1;
    const halfwayCap = globalPositionCap - Math.floor( (globalPositionCap * 0.2) / currentCap );

    const drawBuffer = e.data.drawBuffer;

    const envelopeSamples = e.data.array;
    const sampleRate = e.data.sampleRate;
    const maxSampleRate = e.data.maxSampleRate;    
    const bufferLength = drawBuffer.length;
    const channelIdx = e.data.channelIdx;

    const offsetHead = e.data.offsetHead;

    let prevSegment;
    if (deviceType == 'audio') {
      prevSegment = Math.floor( envelopeSamples.length/divider);
    }else{
      if (maxSampleRate == 0){ // loading data is loading wav sampleRate (1666,2000,etc), so do not need maxSampleRate
        prevSegment = Math.floor( envelopeSamples.length/divider * sampleRate );
      }else{
        prevSegment = Math.floor( envelopeSamples.length/divider * sampleRate / maxSampleRate);
      }      
    }    
    let start = head * 2 - prevSegment;
    let to = head * 2;
    
    const evtCounter = eventsCounterInt[0];
    const excess = bufferLength - prevSegment;
    // console.log("excess : ", excess);
    
    const nearFull = head * 2 + prevSegment;
    if (!isFull && nearFull <= envelopeSamples.length){
    // if (!isFull){
      // console.log("playback here");
      if (start < 0 ) start = 0;
      if (channelIdx == 0 && offsetHead > 0){
        eventPositionResultInt.fill(0);
        for ( let ctr = 0; ctr < evtCounter; ctr++ ){
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

          // if (eventGlobalPositionInt[ctr] >= globalPositionCap){
          //   const headPosition = Math.floor(eventPositionInt[ctr] / skipCounts * 2); // headPosition in envelope realm
          //   if ( headPosition < start ) {
          //     eventPositionResultInt[ctr] = 0;
          //     isReducingMarkers = true;
          //   }else//{
          //   if (headPosition >= start && headPosition <= to){
          //     eventPositionResultInt[ctr] = ( bufferLength - excess - (to - (headPosition)) ) / bufferLength * vm.drawSurfaceWidth;
          //   }
          // }        
        }
  
      }
  
      const subarray = envelopeSamples.subarray(start,to);
      if (subarray.length < bufferLength){
        const pos = bufferLength - subarray.length  - 1;
        drawBuffer.fill(0,0,pos);
        drawBuffer.set(subarray, pos );
        // console.log("Start To, buffer : ", start,to, drawBuffer.slice(-100));
        // console.log("subarray : ", envelopeSamples.slice(-100), envelopeSamples.slice(0,100), pos);
      }else{
        // try{
          start = to - drawBuffer.length;
          const subarray2 = envelopeSamples.subarray(start,to);

          drawBuffer.set(subarray2, 0 );
        // }catch(err){
        //   console.log(drawBuffer.length, subarray.length);
        // }
      }
    }else{
      let segmentCount = prevSegment;

      if (start<0){
        // console.log("playback here 3 : ", head, "start : ",start, " segment : ", segmentCount);

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
            console.log(drawBuffer, envelopeSamples, start, segmentCount, processedHead, firstPartOfData.length, secondPartOfData.length);
          }
        }else{
          drawBuffer.set(firstPartOfData, bufferLength - firstPartOfData.length-1);  
        }

        if (channelIdx == 0){
          eventPositionResultInt.fill(0);

          for ( let ctr = 0; ctr < evtCounter; ctr++ ){
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
            // if (eventGlobalPositionInt[ctr] >= halfwayCap){
            //   const headPosition = Math.floor(eventPositionInt[ctr] / skipCounts * 2); // headPosition in envelope realm
            //   if ( headPosition < start && headPosition > to) {
            //     eventPositionResultInt[ctr] = 0;
            //     isReducingMarkers = true;
      
            //   }else{
            //     if ( headPosition <= envelopeSamples.length && headPosition>= start){ // upper
            //       const counter = bufferLength - ( envelopeSamples.length - headPosition + secondPartOfData.length );
            //       eventPositionResultInt[ctr] = counter / bufferLength * vm.drawSurfaceWidth;;
            //     }else//{ // headPosition < to // below
            //     if (headPosition <= to && headPosition >=0){
            //       const counter = bufferLength - excess - ( to - (headPosition) );
            //       eventPositionResultInt[ctr] = counter / bufferLength * vm.drawSurfaceWidth;;
            //     }

            //   }          
            // }
          }
        }


      }else{
        //2SignalThread.js:261 playback here 3 :  4308 start :  6894  segment :  1722
        start = start;
        const subarray = envelopeSamples.subarray(start,to);
        const startIdx = bufferLength - subarray.length;
        drawBuffer.set(subarray, startIdx);


        // if (channelIdx == 0){
        //   eventPositionResultInt.fill(0);

        //   for ( let ctr = 0; ctr < evtCounter; ctr++ ){
        //     if (eventGlobalPositionInt[ctr] >= globalPositionCap){
  
        //       const headPosition = Math.floor(eventPositionInt[ctr] / skipCounts * 2); // headPosition in envelope realm
        //       if ( headPosition < start) {
        //         eventPositionResultInt[ctr] = 0;
        //         isReducingMarkers = true;
        //       }else//{
        //       if (headPosition >= start && headPosition <= to){
        //         eventPositionResultInt[ctr] = ( bufferLength - excess - (to - (headPosition)) ) / bufferLength * vm.drawSurfaceWidth;;
        //       }
        //     }          
        //   }
  
        // }
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
              }else
              if (eventGlobalPositionInt[ctr] > offsetHead){
                eventPositionResultInt[ctr] = 0;
                isReducingMarkers = true;
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
      type = event.data.type;
      rawSabDraw= event.data.sabDraw;
      CHANNEL_COUNT_FIX = event.data.channelCount;
      vm.drawSurfaceWidth = event.data.drawSurfaceWidth;
      arrCounts = event.data.arrCounts;
      skipCounts = new Uint32Array(arrCounts);
      
      eventsCounterInt = new Uint8Array(rawSabDraw.eventsCounter);
      eventPositionInt = new Uint32Array(rawSabDraw.eventPosition);
      eventPositionResultInt = new Float32Array(rawSabDraw.eventPositionResult);
      eventsInt = new Uint8Array(rawSabDraw.events);

      
      
      vm.drawBuffers=[];

      sabDrawing = rawSabDraw.levels;
      console.log("sabDrawing : ", sabDrawing);
      let totalChannel = type == 'audio' ? CHANNEL_COUNT_FIX : MAX_SERIAL_CHANNELS;
      if (rawSabDraw === undefined){
        for (let c = 0; c < totalChannel ; c++){
          draw_states[c] = new Int32Array(rawSabDraw.draw_states[c]);

          const sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];
          vm.level = draw_states[0][DRAW_STATE.LEVEL];
          vm.skip_counts = draw_states[0][DRAW_STATE.SKIP_COUNTS];
          vm.isDirect = draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE];
          divider = draw_states[0][DRAW_STATE.DIVIDER] / 10;
    
    
          vm.drawBuffers[c] = new Int16Array(vm.sampleLength / divider);
          sabDrawingInt[c] = new Int16Array(sabDrawing[c]);
        }
      }else{
        for (let c = 0; c < totalChannel ; c++){
          draw_states[c] = new Int32Array(rawSabDraw.draw_states[c]);

          const sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];
          vm.level = draw_states[0][DRAW_STATE.LEVEL];
          vm.skip_counts = draw_states[0][DRAW_STATE.SKIP_COUNTS];
          vm.isDirect = draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE];
          divider = draw_states[0][DRAW_STATE.DIVIDER] / 10;
    
          console.log("sampleRate, divider, arrCounts[vm.level] : ", sampleRate, divider, vm.level, arrCounts);
          vm.drawBuffers[c] = new Int16Array( Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]) );
          sabDrawingInt[c] = new Int16Array(sabDrawing[c]);
        }  
        console.log("drawBuffers : ", totalChannel, vm.drawBuffers);

      }


    break;

    case "sabcs":
      vm.sabStatesDraw = [];
      vm.rawSabcs = event.data.rawSabcs;
      const sabLength = vm.rawSabcs.length;
      let playbackStates;
      if (rawSabDraw.playbackStates !== undefined){
        playbackStates = new Uint32Array(rawSabDraw.playback_states[0]);
      }else{
        playbackStates = [];
      }

      
      for (let c = 0 ; c< sabLength ; c++){
        vm.sabStatesDraw[c]  = new Int32Array(vm.rawSabcs[c].statesDraw);
        if (rawSabDraw.playbackStates === undefined){
          playbackStates[c] = 0;
        }
      }

      vm.isDirect = draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE];
      eventGlobalPositionInt = new Uint32Array(vm.rawSabcs[0].eventGlobalPosition);
      // StatesDraw2 = new Int32Array(vm.sabcs2.statesDraw);        
      // const updateIdx = sabLength-1;
      const updateIdx = 0;
      while ( Atomics.wait(vm.sabStatesDraw[updateIdx], STATE.REQUEST_SIGNAL_REFORM, 0) === 'ok') {
      // while ( Atomics.wait(StatesDraw, STATE.REQUEST_SIGNAL_REFORM, 0) === 'ok'  && Atomics.wait(StatesDraw2, STATE.REQUEST_SIGNAL_REFORM, 0) === 'ok') {

        const sampleRate = draw_states[0][DRAW_STATE.SAMPLE_RATE];
        CHANNEL_COUNT_FIX = draw_states[0][DRAW_STATE.CHANNEL_COUNTS];
        // if (draw_states[0][DRAW_STATE.LEVEL] != vm.level || divider != draw_states[0][DRAW_STATE.DIVIDER]/10 || (vm.drawSurfaceWidth != draw_states[0][DRAW_STATE.SURFACE_WIDTH] && draw_states[0][DRAW_STATE.SURFACE_WIDTH] > 0)){
        if (draw_states[0][DRAW_STATE.LEVEL] != vm.level || divider != draw_states[0][DRAW_STATE.DIVIDER]/10 || CHANNEL_COUNT_FIX != draw_states[0][DRAW_STATE.CHANNEL_COUNTS] || vm.drawSurfaceWidth != draw_states[0][DRAW_STATE.SURFACE_WIDTH]){          
          vm.level = draw_states[0][DRAW_STATE.LEVEL];
          vm.drawSurfaceWidth = draw_states[0][DRAW_STATE.SURFACE_WIDTH];
          vm.sampleRate = sampleRate;
          vm.skip_counts = draw_states[0][DRAW_STATE.SKIP_COUNTS];
          divider = draw_states[0][DRAW_STATE.DIVIDER] / 10;
          let bufferWidth = 0;
          if (vm.level == -1){
            vm.skip_counts = 1;
            bufferWidth = Math.floor(sampleRate * 60 / divider * 2);
          }else{
            bufferWidth = Math.floor(sampleRate * 60 / divider * 2 / arrCounts[vm.level]);
          }

          for (let c = 0 ; c< MAX_SERIAL_CHANNELS ; c++){
            vm.drawBuffers[c]  = new Int16Array( bufferWidth );
          }

        }
        if (vm.isDirect != draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE]){
          const drawBuffersArrLen = vm.drawBuffers.length;
          // console.log("drawBuffersArrLen : ",drawBuffersArrLen);
          for (let c = 0 ; c< drawBuffersArrLen ; c++){
            vm.drawBuffers[c].fill(0);
          }
          vm.isDirect = draw_states[0][DRAW_STATE.DIRECT_LOAD_FILE];
        }


        
        let envelopeSamples;
        for (let c = 0;c < CHANNEL_COUNT_FIX ; c++){
          const sabcs = vm.rawSabcs[c];
          if (vm.level == -1){
            envelopeSamples = new Int16Array(sabcs.arrMax);
          }else{
            try{
              envelopeSamples = new Int16Array(sabcs.sabEnvelopes[vm.level]);
            }catch(err){
              console.log("sabcs.sabEnvelopes : ", c, CHANNEL_COUNT_FIX,vm.rawSabcs);
            }
          }

          const skipCounts = vm.skip_counts;
          let sabsConfig;
          let maxSize;
          let currentCap;
          let globalPositionCap;
          let isFull;
          let head;
          let arrOffsetHeadInt = new Uint32Array(sabcs.arrOffsetHead);
          // let offsetHead;
          // let offsetHead = sabsConfig[7];
          let offsetHead = arrOffsetHeadInt[c];


          if (type == 'audio'){
            sabsConfig = new Int32Array(sabcs.config);
            offsetHead = sabsConfig[7];

            // head = sabsConfig[0];
            // currentCap = sabsConfig[1];
            // globalPositionCap = Math.floor(sabsConfig[1] * maxSize /2);
            // isFull = sabsConfig[1] >= 1 ? true : false;
            head = new Uint32Array(sabcs.arrHeads)[0];
            currentCap = (new Uint32Array(sabcs.arrIsFull)[0]);
            maxSize = (new Int16Array(sabcs.arrMax)).length;
            globalPositionCap = Math.floor(currentCap * maxSize /2);
            isFull = currentCap >= 1 ? true : false;
            if (c==0){
              draw_states[0][DRAW_STATE.CURRENT_HEAD] = head;
              // draw_states[0][DRAW_STATE.IS_FULL] = sabsConfig[1];
              draw_states[0][DRAW_STATE.IS_FULL] = isFull;
            }
            // console.log(head,currentCap,maxSize, globalPositionCap, isFull);
  
          }else{
            head = new Uint32Array(sabcs.arrHeads)[c];
            // console.log("HEAD DRAW ", head);
            maxSize = (new Int16Array(sabcs.arrMax)).length;
            currentCap = (new Uint32Array(sabcs.arrIsFull)[c]);
            globalPositionCap = Math.floor( currentCap* maxSize / 2);
            isFull = currentCap >= 1 ? true : false;
            if (c==0){
              draw_states[0][DRAW_STATE.CURRENT_HEAD] = head;
              draw_states[0][DRAW_STATE.IS_FULL] = isFull;
            }

          }

          // const scrollHorizontalValue = draw_states[0][DRAW_STATE.HORIZONTAL_DRAG];
          const scrollHorizontalValue = playbackStates[PLAYBACK_STATE.DRAG_VALUE];
          const zoomHorizontalDifference = draw_states[0][DRAW_STATE.CURRENT_START];


          if (zoomHorizontalDifference != 0){
            head = head - Math.floor(zoomHorizontalDifference) ;
            offsetHead = offsetHead - Math.floor(zoomHorizontalDifference) ;
          }
          if (scrollHorizontalValue != 0){
            head = head - scrollHorizontalValue;
            offsetHead = offsetHead - scrollHorizontalValue;
          }
          // console.log("buffer : ",c, vm.drawBuffers);
          try{
            vm.drawBuffers[c].fill(0);
          }catch(err){
            console.log("Err : ", err, head, vm.skip_counts, vm.drawBuffers);
          }
          const maxSampleRate = draw_states[0][DRAW_STATE.MAX_SAMPLING_RATE];
          // console.log("MAX_SAMPLING_RATE : ", maxSampleRate);
          let prevSegment; 
          if (type == 'audio'){
            prevSegment = Math.floor( envelopeSamples.length/divider);
          }else{
            if (maxSampleRate == 0){
              prevSegment = Math.floor( envelopeSamples.length/divider * sampleRate );
            }else{
              prevSegment = Math.floor( envelopeSamples.length/divider * sampleRate / maxSampleRate);
            }
          }
          
          // console.log("_head : ", head);
          onMessageFromWorker({
            data : {
              skipCounts : skipCounts,
              head : head,
              isFull : isFull,
              array : envelopeSamples,
              sampleRate : sampleRate,
              maxSampleRate : maxSampleRate,
              offsetHead : offsetHead,
              globalPositionCap : globalPositionCap,
              currentCap : currentCap,
              channelIdx : c,
              drawBuffer : vm.drawBuffers[c] ,
              deviceType : type,
            }
          });

        
        
        
          let temp = new Int16Array(sabDrawing[c]);
          // let temp = sabDrawingInt[c];
          let starting = vm.drawBuffers[c].length - prevSegment;
          if (starting < 0 ) starting = 0;
          
          // console.log("SLICE : ",vm.drawBuffers[c].slice(vm.drawBuffers[c].length-400));
          temp.set(vm.drawBuffers[c].slice(0),0);
          // console.log("temp : ",temp, starting, vm.drawBuffers[c]);
          draw_states[c][DRAW_STATE.HEAD_IDX] = starting;
          draw_states[c][DRAW_STATE.TAIL_IDX] = vm.drawBuffers[c].length;
        }
        
        for (let ch = 0;ch < CHANNEL_COUNT_FIX ; ch++){
          Atomics.store(vm.sabStatesDraw[ch], STATE.REQUEST_SIGNAL_REFORM, 0);
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