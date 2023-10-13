// 1 channel = 48 -> | 23 | 29 | 30 | 31 | 33 | 41 | 
// // 40-44 | 45 - n
// 4         4   ChunkSize        36 + SubChunk2Size, or more precisely:
// 40        4   Subchunk2Size    == NumSamples * NumChannels * BitsPerSample/8
//                        This is the number of bytes in the data.
//                        You can also think of this as the size
//                        of the read of the subchunk following this 
//                        number.
// 44 - n    n   Samples Length

// -1,-1
// 1 channel = 48
//  1   2   3   4   5  6  7  8  9   10  11  12   13   14   15  16  17 18 19 20 21 22 23 24  25  26  27 28 29    30 31 32 33 34  35 36  37   38  39   40 41 42 43 44   45   46   47   48
// 82, 73, 70, 70, 40, 0, 0, 0, 87, 65, 86, 69, 102, 109, 116, 32, 16, 0, 0, 0, 1, 0, 1, 0, 68, 172, 0, 0, 136, 88, 1, 0, 2, 0, 16, 0, 100, 97, 116, 97, 4, 0, 0, 0, 255, 255, 255, 255
// 2 channel  52
// 40-44 | 45 - n
// [-1,-1] , [-1,-1] 
//  1   2   3   4   5  6  7  8  9   10  11  12   13   14   15  16  17 18 19 20 21 22 23 24   25   26 27 28 29   30 31 32 33 34  35 36  37   38  39   40 41 42 43 44 45 46 47 48   49   50   51   52  53 54 55 56 
// 82, 73, 70, 70, 44, 0, 0, 0, 87, 65, 86, 69, 102, 109, 116, 32, 16, 0, 0, 0, 1, 0, 1, 0, 68, 172, 0, 0, 136, 88, 1, 0, 2, 0, 16, 0, 100, 97, 116, 97, 8, 0, 0, 0, 3, 0, 12, 0, 87, 1, 225, 2  ->3,12,23,343,737
// 82, 73, 70, 70, 42, 0, 0, 0, 87, 65, 86, 69, 102, 109, 116, 32, 16, 0, 0, 0, 1, 0, 1, 0, 68, 172, 0, 0, 136, 88, 1, 0, 2, 0, 16, 0, 100, 97, 116, 97, 6, 0, 0, 0, 3, 0, 12, 0, 23, 0  ->3,12,23
// 82, 73, 70, 70, 42, 0, 0, 0, 87, 65, 86, 69, 102, 109, 116, 32, 16, 0, 0, 0, 1, 0, 1, 0, 68, 172, 0, 0, 136, 88, 1, 0, 2, 0, 16, 0, 100, 97, 116, 97, 6, 0, 0, 0, 3, 0, 12, 0, 87, 1  ->3,12, 353

// 82, 73, 70, 70, 42, 0, 0, 0, 87, 65, 86, 69, 102, 109, 116, 32, 16, 0, 0, 0, 1, 0, 1, 0, 68, 172, 0, 0, 136, 88, 1, 0, 2, 0, 16, 0, 100, 97, 116, 97, 6, 0, 0, 0, 0, 0, 1, 0,   2,   0
// 82, 73, 70, 70, 48, 0, 0, 0, 87, 65, 86, 69, 102, 109, 116, 32, 16, 0, 0, 0, 1, 0, 2, 0, 68, 172, 0, 0, 16, 177, 2, 0, 4, 0, 16, 0, 100, 97, 116, 97,12, 0, 0, 0, 0, 0, 0, 0,   1,   0,   1,   0,  2, 0, 2, 0,
// 82, 73, 70, 70, 68, 78,0, 0, 87, 65, 86, 69, 102, 109, 116, 32, 16, 0, 0, 0, 1, 0, 1, 0, 68, 172, 0, 0, 136, 88, 1, 0, 2, 0, 16, 0, 100, 97, 116, 97,32,78, 0, 0, 0, 0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8, 0, 9, 0, 10, 0, 11, 0, 12, 0, 13, 0, 14, 0, 15, 0, 16, 0, 17, 0, 18, 0, 19, 0, 20, 0, 21, 0, 22, 0, 23, 0, 24, 0, 25, 0, 26, 0, 27, 0,
// 82, 73, 70, 70, 44, 0, 0, 0, 87, 65, 86, 69, 102, 109, 116, 32, 16, 0, 0, 0, 1, 0, 2, 0, 68, 172, 0, 0, 16, 177, 2, 0, 4, 0, 16, 0, 100, 97, 116, 97, 8, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255


const NUMBER_OF_SEGMENTS = 60;
const SEGMENT_SIZE = 44100;
const SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;


let WAV_STATE = {
    'CHUNK_SIZE_INDEX' : 4,
    'SUBCHUNK2_SIZE_INDEX' : 40,
}

const WRITE_CONFIG = {
    bytesPerState : Int32Array.BYTES_PER_ELEMENT,
    state_length : 10,
};
const WRITE_STATE = {
    'WRITE_CHANNEL_COUNT':0,
    'IS_RECORDING':1,
    'PROCESSED_COUNT':2,
};

let isStopRecording = false;

var worker2port;
var workerForwardPort;
var _fileHandle;
var writable;
const STATE = {
    'IB_READ_INDEX': 2,
    'IB_WRITE_INDEX': 3,
  
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


const CONFIG = {
    bytesPerSample : Int16Array.bytesPerSample,
    ringBufferLength: 4096,
    kernelLength: 1024,
};

var wavBuffer;
var wavBufferWriteTailIdx = 0;
  

var vm = this;
// try{
importScripts("wavefile.js");    
importScripts("jszip.min.js");    
var wav = new wavefile.WaveFile();
var wavList = new wavefile.WaveFile();
var zip = new JSZip();

// console.log('importScripts("wavefile.js")');
// console.log(importScripts("wavefile.js"));
// }catch(err){
//     console.log("err");
//     console.log(err);
// }

// let fileTempArr = [new Int16Array(SIZE * CONFIG.bytesPerSample),new Int16Array(SIZE * CONFIG.bytesPerSample)];
let fileTempArr = new Int16Array(1024 * 1024 * 20);
let counterHead = 0;

self.onmessage = async function( event ) {
    console.log( event.data );    
    // WHEN RECORDED SETTING button gone
    async function createHeader(channelCount){
        // wav.fromScratch(vm.channelCount, vm.sampleRate, '16', [3,12,343,737]);
        
        // wav.fromScratch(vm.channelCount, vm.sampleRate, '16', []);
        wav.fromScratch(channelCount, vm.sampleRate, '16', []);
        // wav.fromScratch(2, vm.sampleRate, '16', [
        //     [0,1,2],
        //     [0,1,2],
        // ]);

        // console.log( wav.toBuffer() );
        // let a = new Uint16Array(1);
        // a[0] = 343;
        // console.log( a.buffer );
        // return;

        // fs.writeFileSync(path, wav.toBuffer());      
  
        // this.header = "RIFF";
        console.log("wav.byteRate", wav.byteRate);
        writable = await _fileHandle.createWritable();
        console.log("WRITABLE", writable, vm.channelCount);
        // await writable.write( wav.toBuffer() );

        if ( channelCount == 1 ){
            let arr = [];
            // let arr = new Uint16Array(5);
            // arr[0] = 1;
            // arr[1] = 2;
            // arr[2] = 4;
            // arr[3] = 7;
            // arr[4] = 8;
            // idx[40] = 32,78, 0, 0,
            // for (let i = 0;i<10000;i++){
            //     arr.push(i);
            // }
            // 46

            wav.fromScratch(channelCount, vm.sampleRate, '16', arr);
            wavBuffer = wav.toBuffer();
            console.log(wavBuffer);
        }else{
            wav.fromScratch(2, vm.sampleRate, '16', []);
            wavBuffer = wav.toBuffer();
        }
        await writable.write(wavBuffer);
        // arr = new Uint16Array(5);
        // arr[0] = 1;
        // arr[1] = 2;
        // arr[2] = 4;
        // arr[3] = 7;
        // arr[4] = 8;

        // await writable.write(arr.buffer);
        // // await writable.write({data:arr.buffer});
        // let chunk_size_data = 36 + 5*2 + 5*2;
        // let chunk_size_data_array = new Uint16Array(1);
        // chunk_size_data_array[0] = chunk_size_data;
        // writable.write({ type: "write", position: WAV_STATE.CHUNK_SIZE_INDEX, data: chunk_size_data_array.buffer });
        // const Subchunk2Size = 2 * 5 * 1 * 16 / 8;
        // const Subchunk2Size_Array = new Uint16Array(1);
        // Subchunk2Size_Array[0] = Subchunk2Size;
        // writable.write({ type: "write", position: WAV_STATE.SUBCHUNK2_SIZE_INDEX, data: Subchunk2Size_Array.buffer }).then(async ()=>{
        //     await writable.close();
        // });    
        // data : 56

        // await writable.close();

    }

    async function closeFile(){
        await writable.close();        
    }

    var onMessageFromWorker = function( value ){

    }

    switch( event.data.command )
    {
        case "connect":
            console.log("CONNECT");
            _fileHandle = event.data.fileHandle;
            vm.channelCount = event.data.channelCount;
            console.log("vm.channelCount",vm.channelCount);
            vm.sampleRate = event.data.sampleRate;
            vm.sabWriteState = new Int32Array(event.data.sabWriteState);
            vm.channelColor1 = event.data.channelColor1;
            vm.channelColor2 = event.data.channelColor2;
            vm.currentColor = event.data.channelColor1;

            let flagChannelDisplays = new Uint32Array(vm.sabDraw.channelDisplays);
            console.log("flags : ", flagChannelDisplays, vm.sabDraw);
            const sum = flagChannelDisplays.reduce((pre,curr)=>pre+curr,0);

            worker2port = event.ports[0];

            await createHeader(sum);
            

            // if (vm.channelCount == 1){
            if (sum == 1){
                if (flagChannelDisplays[1] == 1){
                    vm.currentColor =event.data.channelColor2;
                }

                vm.sabcs1 = vm.rawSabcs[0];// we are still using 0 because it helds same data as it is parallel
                vm.sabcs2 = vm.rawSabcs[1];// we are still using 0 because it helds same data as it is parallel
                const eventGlobalHeaderInt = new Uint32Array(vm.sabcs1.eventGlobalHeader);
                vm.startingHeader = eventGlobalHeaderInt[0];
                let currentData;
                if (flagChannelDisplays[1] == 1 ){
                    currentData = new Int16Array(vm.sabcs2.fileContentData);
                }else{
                    currentData = new Int16Array(vm.sabcs1.fileContentData);
                }
                // let currentData = new Int16Array(vm.sabcs1.currentDataChannel1);

                let StatesFile1 = new Int32Array(vm.sabcs1.statesWrite);
                // console.log("--vm.channelCount",vm.channelCount);
                // writable = await _fileHandle.createWritable();

                // let promises = [];
                // let arrMax = new Int16Array(vm.sabcs1.arrFileMax);
                let myconfig = new Int32Array(vm.sabcs1.config);
                myconfig[2] = 0 ;
                // let fileContentDataInt1 = new Int16Array(vm.sabcs1.fileContentData);
                // let fileContentDataInt1 = new Int16Array(vm.sabcs1.fileContentData);
                let filePointerFileHeadInt;
                if (flagChannelDisplays[1] == 1){
                    filePointerFileHeadInt = new Uint32Array(vm.sabcs2.filePointerFileHead);
                }else{
                    filePointerFileHeadInt = new Uint32Array(vm.sabcs1.filePointerFileHead);
                }
                const min = 1024 * 1;
                
                while (!isStopRecording && Atomics.wait(StatesFile1, STATE.REQUEST_WRITE_FILE, 0) === 'ok') {
                    // const ringBuffer = new Uint16Array(vm.sabcs1.inputRingBuffer);
                    // let readIdx = StatesFile1[STATE.IB_READ_INDEX];
                    // let writeIdx = StatesFile1[STATE.IB_WRITE_INDEX];


                    // let currentData = new Int16Array(vm.sabcs1.currentDataChannel1);
                    // await writable.write(currentData.slice(0).buffer);
                    // console.log("currentData",currentData);

                    // let head = myconfig[0];
                    // let isFull = myconfig[1];
                    // let switchId = myconfig[2];

                    // if (isFull){
                    //     if (head-1024<0){
                    //         const start = arrMax.length + head - 1024;
                    //         fileTempArr.set(arrMax.subarray(start, arrMax.length),counterHead);
                    //         counterHead += arrMax.length - start;    
                    //         fileTempArr.set(arrMax.subarray(0, head),counterHead);
                    //         counterHead += head;

                    //     }else{
                    //         fileTempArr.set(arrMax.subarray(head-1024, head),counterHead);
                    //         counterHead += 1024;    
                    //     }
                    // }else{
                    //     if (head-1024<0){
                    //         fileTempArr.set(arrMax.subarray(0,head),counterHead);
                    //     }else{
                    //         fileTempArr.set(arrMax.subarray(head-1024, head),counterHead);
                    //     }
                    //     counterHead += 1024;
                    // }

                    // // const switchIdx = myconfig[2] % 2;
                    // fileTempArr.set(ringBuffer, dataIdx - 44);
                    // dataIdx += 1024;
    
                    // console.log("vm.channelCount",myconfig[0], vm.channelCount, readIdx, writeIdx);

                    // console.log("CHANNELS : ",readIdx,writeIdx);
                    // if (isStopRecording){
                    //     return;
                    // }

                    // let promises = [];
                    
                    /*
                    let mytemp = new Uint16Array(ringBuffer.length);
                    let tempIdx = 0;
                    while(readIdx != writeIdx){
                        // new Uint16Array
                        if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                            console.log("WHILE IS STOP RECORDING 0 ");
                            isStopRecording = true;                        
                            break;
                        }
    
                        if (isStopRecording){
                            console.log("WHILE IS STOP RECORDING");
                            break;
                        }
                        mytemp[tempIdx] = ringBuffer[readIdx];
                        // promises.push(
                        //     writable.write(mytemp.buffer).then(()=>{
                        //     })
                        // );
                            
                        if (++readIdx === CONFIG.ringBufferLength)
                            readIdx = 0;    

                        tempIdx++;
                    };
                    */
                    // writable.write(mytemp.buffer).catch((err)=>{
                    //     console.log("err",err);
                    // });

                    
                    // Promise.all(promises).then(async (allPromise)=>{
                    // })
                    // let currentData = new Int16Array(vm.sabcs1.currentDataChannel1);
                    // await writable.write(currentData.slice(0).buffer);

                    // vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT]+=1024;
                    // await writable.write(currentData.slice(0,filePointerFileHeadInt[0]).buffer);
                    // let currentData = new Int16Array(vm.sabcs1.currentDataChannel1);
                    // await writable.write(currentData.slice(0).buffer);
                    await writable.write(currentData.slice(0,filePointerFileHeadInt[0]).buffer);

                    vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT]+=min;

                    if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                        isStopRecording = true;                        
                        break;
                    }else
                    if (!isStopRecording){
                        Atomics.store(StatesFile1, STATE.REQUEST_WRITE_FILE, 0);
                    }

                }
                wavBufferWriteTailIdx = vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT];
                /*
                let config = new Int32Array(vm.sabcs1.config);
                wavBufferWriteTailIdx = config[0];
                // wavBufferWriteTailIdx = vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT]*(CONFIG.kernelLength)/Int16Array.BYTES_PER_ELEMENT;
                // let samplesCount = wavBufferWriteTailIdx*(CONFIG.kernelLength)/Int16Array.BYTES_PER_ELEMENT;
                let samplesCount = wavBufferWriteTailIdx;
                console.log("arrMax.length");
                console.log(arrMax.length, samplesCount, config[1], vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT],CONFIG.kernelLength);
                //5292000 297984 0 43 1024
                //5292000 = 120 seconds | 10 seconds = 5292000/12 =441000
                console.log(arrMax.buffer);
                await writable.write( (arrMax.slice(0,samplesCount)).buffer );
                //file.worker.js:236 Uncaught (in promise) TypeError: Failed to execute 'write' on 'FileSystemWritableFileStream': Failed to convert value to 'ArrayBuffer'.
                // wavBufferWriteTailIdx = arrMax.length;
                */
                // console.log("STOPPP RECORDING1 ",wavBufferWriteTailIdx);//365568

                // asciiToUint8Array("cpos");
                // fwrite("LIST\0\0\0\0", 8, 1, _file);
                // uint32_t sizepos = ftell(_file)-4;
            
                // fwrite("INFO", 4, 1, _file);
                // fwrite(id, 4, 1, f);
                // put32(content.size()+1, f);
                // fwrite(content.c_str(), content.size()+1, 1, f);
                // padbyte(f);


                // console.log("wavList : ", JSON.stringify(wavList.toBuffer().subarray(44)) );

                // let strSuffix = asciiToUint8Array("LIST\0\0\0\0");
                // // console.log("strSuffix : ",strSuffix);
                // await writable.write(strSuffix.buffer);
                // let strInfo = asciiToUint8Array("INFO");
                // await writable.write(strInfo.buffer);
                // let currentBufferCount = wavBuffer.length + wavBufferWriteTailIdx * 1 * 16 / 8 + strSuffix.length + strInfo.length;
                // console.log("currentBufferCount1 : ",currentBufferCount);

                // currentBufferCount = await writeSubchunk(writable, "cpos", "1;", currentBufferCount);
                // currentBufferCount = await writeSubchunk(writable, "ctrs", "0;", currentBufferCount);
                // currentBufferCount = await writeSubchunk(writable, "cgin", "1;", currentBufferCount);
                // currentBufferCount = await writeSubchunk(writable, "cclr", "2;", currentBufferCount);
                // currentBufferCount = await writeSubchunk(writable, "ctms", "0;", currentBufferCount);
                // currentBufferCount = await writeSubchunk(writable, "cnam", "AUDIO - 1;", currentBufferCount);
                // currentBufferCount = await writeSubchunk(writable, "cdev", "1;", currentBufferCount);
                // 28+ 2*6 +10

                // const u32 = new Uint32Array(1);
                // u32[0] = currentBufferCount;

                // (new DataView(u32.buffer)).setUint32(0,currentBufferCount - firstListChunkPos - 4, true);

                // console.log("currentBufferCount2 : ",currentBufferCount);
                // await writable.write({ type: "write", position: firstListChunkPos, data: u32.buffer });
                // await writable.write({ type: "write", position: firstListChunkPos, data: dv.buffer });

            
                // write_subchunk("cpos", poss.str(), _file);
                // write_subchunk("ctrs", threshs.str(), _file);
                // write_subchunk("cgin", gains.str(), _file);
                // write_subchunk("cclr", colors.str(), _file);
                // write_subchunk("ctms", timeScale.str(), _file);
                // write_subchunk("cnam", names.str(), _file);


                const firstListChunkPos = wavBufferWriteTailIdx * 1 * 16 / 8;

                // wavList.fromScratch(vm.channelCount, vm.sampleRate, '16', []);
                wavList.fromScratch(sum, vm.sampleRate, '16', []);
                wavList.LIST = [{
                    chunkId: 'LIST',
                    chunkSize: 29,
                    format: 'INFO',
                    subChunks: [
                        {
                            chunkId: 'cpos',
                            chunkSize: 3,
                            value: '1;'
                        },
                        {
                            chunkId: 'ctrs',
                            chunkSize: 3,
                            value: '0;'
                        },
                        {
                            chunkId: 'cgin',
                            chunkSize: 3,
                            value: '1;'
                        },
                        {
                            chunkId: 'cclr',
                            chunkSize: 3,
                            // value: vm.channelColor1+';'
                            value: vm.currentColor+';'
                        },
                        {
                            chunkId: 'ctms',
                            chunkSize: 3,
                            value: '0;'
                        },
                        {
                            chunkId: 'cnam',
                            chunkSize: 11,
                            value: 'AUDIO - 1;'
                        },
                        {
                            chunkId: 'cdev',
                            chunkSize: 3,
                            value: '1;'
                        },                                                                                                                        
                    ]                    
                }];

                const subArrList = wavList.toBuffer().subarray(wavBuffer.length);
                console.log("sum : ",sum, flagChannelDisplays, "channelColor1 : ",vm.channelColor1, "channelColor2 : ",vm.channelColor2, "CurrentColor : ",vm.currentColor, wavList);
                
                let bufferOdd = wavBuffer.length + firstListChunkPos;
                if ( bufferOdd  % 2 == 1){
                    // console.log("BUFFER ODD : ",bufferOdd);
                    await writable.write('\0')
                    wavBufferWriteTailIdx++;
                }
                

                await writable.write(subArrList);
                WAV_STATE.SUBCHUNK2_SIZE_INDEX = wavBuffer.length - (4);

                let temp2 = new Uint32Array(1);
                // const Subchunk2Size = wavBufferWriteTailIdx * 1 * 16 / 8;
                const Subchunk2Size = firstListChunkPos;
                // console.log("SUB CHUNK 2 SIZE  : ", Subchunk2Size);
                // temp2[0] = Subchunk2Size;
                temp2[0] = Subchunk2Size;
                await writable.write({ type: "write", position: WAV_STATE.SUBCHUNK2_SIZE_INDEX, data: temp2.buffer })

                let temp = new Uint32Array(1);
                let chunk_size_data = 36 + Subchunk2Size + subArrList.length;
                // let chunk_size_data = Subchunk2Size - 8;
                temp[0] = chunk_size_data;
                await writable.write({ type: "write", position: WAV_STATE.CHUNK_SIZE_INDEX, data: temp.buffer });


                // console.log("CLOSEEEZ", wavBufferWriteTailIdx, temp[0],temp2[0], firstListChunkPos, subArrList.length);
                //CLOSEEEZ 110592 221368 221332 221228 104
                await writable.close();

                const file = await _fileHandle.getFile();
                // console.log("file : ", file);
                const buffers = new Uint8Array (await file.arrayBuffer());
                // console.log("buffers : ", buffers);
                console.log("startingHeader : ", vm.startingHeader);

                let str = '';
                const eventGlobalPositionInt = new Uint32Array(vm.sabcs1.eventGlobalPosition);
                const counter = (new Uint32Array(vm.sabDraw.draw_states[0]))[DRAW_STATE.EVENT_COUNTER];
                const eventsIdxInt = new Uint8Array(vm.sabDraw.events);
                const tabSeparator = String.fromCharCode(9);
                // const SIZE = NUMBER_OF_SEGMENTS * vm.sampleRate;
                
                for (let i = 0 ; i < counter ; i++){
                    let adjustedPosition = (eventGlobalPositionInt[i] - vm.startingHeader);
                    if (adjustedPosition>0){
                        const pos = ( adjustedPosition / sampleRate ).toFixed(4);
                        str+=(eventsIdxInt[i]+","+tabSeparator+pos)+"\r\n";
                    }

                    console.log("adjusted position ",eventGlobalPositionInt[i],vm.startingHeader);    
                    // str+=`${eventsIdxInt[i]},${tabSeparator}${pos}\r\n`;
                }
                console.log("STR : ", str);

            
                zip.file("signal.wav", buffers);
                zip.file("signal-events.txt", 
                    `# Marker IDs can be arbitrary strings.\r\n# Marker ID,	Time (in s)\r\n`+str);

                const strVersion = "1";
                const curDateTime = new Date();
                const recordingDate = curDateTime.getMonth()+"."+curDateTime.getDate()+"."+curDateTime.getFullYear();
                const recordingTime = curDateTime.getHours()+":"+curDateTime.getMinutes()+":"+curDateTime.getSeconds();
                const recordingDevice = "<recordingdevice><name>Audio Device</name><type>Audio Device</type><filter><hp>0</hp><lp>"+Math.floor(sampleRate/2)+"</lp><comment></comment></filter></recordingdevice>";
                // List<Color> audioChannelColors = [ Color(0xFF10ff00), Color(0xFFff0035), Color(0xFFe1ff4b), Color(0xFFff8755), Color(0xFF6bf063),Color(0xFF00c0c9),];
                const startSubIdx = event.data.userAgent.indexOf("(")+1;
                const endSubIdx = event.data.userAgent.indexOf(")");
                const applicationTag = "<application><platform>web</platform><sysversion>"+event.data.userAgent.substring(startSubIdx,endSubIdx)+"</sysversion><appversion>"+event.data.versionNumber+"</appversion><details>"+event.data.userAgent+"</details></application>";

                const audioColors = ["#10FF00", "#FF0035", "#E1FF4B", "#FF8755", "#6BF063", "#00c0c9",];
                let strChannels = '';
                for (let i = 1; i <= vm.channelCount ; i++){
                    if (flagChannelDisplays[i-1] == 1){
                        console.log("channelColor---"+i);
                        console.log(vm["channelColor"+i]);
                        console.log(audioColors[vm["channelColor"+i]]);
                        const colorIndex = audioColors[vm["channelColor"+i]];
                        strChannels += '<channels><channel><name>Channel '+i+'</name><filter><hp>0</hp><lp>'+ Math.floor(sampleRate/2) +'</lp><notch></notch></filter><samplerate>'+sampleRate+'</samplerate><colorindex>'+colorIndex+'</colorindex> <digitalmin>-32768</digitalmin><digitalmax>32767</digitalmax> <physicalmin>100</physicalmin> <physicalmax>100</physicalmax> <physicaldimension>dB</physicaldimension> </channel></channels>';    
                    }
                }

                // let recordingFiles = "<file><type>signal</type><version>"+strVersion+"</version> <path>signal.wav</path> <format>wav</format> <bytespersample>2</bytespersample> <samplerate>"+sampleRate+"</samplerate> <numchannels>"+vm.channelCount+"</numchannels>"+strChannels+" </file> <file><type>events</type><version>" + strVersion + "</version> <path>signal-events.txt</path> </file> <file><type>spikes</type><version>" + strVersion + "</version> <path>signal-events.txt</path> </file>";
                let recordingFiles = "<file><type>signal</type><version>"+strVersion+"</version> <path>signal.wav</path> <format>wav</format> <bytespersample>2</bytespersample> <samplerate>"+sampleRate+"</samplerate> <numchannels>"+sum+"</numchannels>"+strChannels+" </file> <file><type>events</type><version>" + strVersion + "</version> <path>signal-events.txt</path> </file> <file><type>spikes</type><version>" + strVersion + "</version> <path>signal-events.txt</path> </file>";

                let header = "<header><version>"+strVersion+"</version><recordingdate>"+recordingDate+"</recordingdate><recordingtime>"+recordingTime+"</recordingtime>"+
                             applicationTag +
                             "<subject><name></name><id></id><comment></comment></subject> " + recordingDevice + "<files>" + recordingFiles + "</files> </header>";
                console.log("HEADER ", header);
                zip.file("header.xml", header);

                console.log("STR : ", str);
                console.log("eventGlobalPositionInt : ", eventGlobalPositionInt);
                console.log("eventsIdxInt : ", eventsIdxInt);
                
                zip.generateAsync({
                    type: 'uint8array',
                    compression : 'store',
                    mimeType: 'application/wav',
                }).then( async function (content) {
                    // see FileSaver.js
                    console.log("content : ",content);
                    
                    writable = await _fileHandle.createWritable();
                    await writable.write(content);
                    await writable.close();


                    //saveAs(content, "hello.zip");
                });
                        
            }else{
                console.log("CHANNEL IS 2 recording ", isStopRecording);
                vm.sabcs1 = vm.rawSabcs[0];
                vm.sabcs2 = vm.rawSabcs[1];

                const eventGlobalHeaderInt = new Uint32Array(vm.sabcs1.eventGlobalHeader);
                vm.startingHeader = eventGlobalHeaderInt[0];
    
                let StatesFile1 = new Int32Array(vm.sabcs1.statesWrite);
                let StatesFile2 = new Int32Array(vm.sabcs2.statesWrite);
                let combiningData = new Uint16Array(1024 * 8 * 2);
                let combinedData = new Uint16Array(1024 * 2);
                let currentData1 = new Uint16Array(vm.sabcs1.currentData);
                let currentData2 = new Uint16Array(vm.sabcs2.currentData);
    
                let myconfig = new Int32Array(vm.sabcs1.config);
                let myconfig2 = new Int32Array(vm.sabcs2.config);
                let idxChannel1 = myconfig[4];
                let idxChannel2 = myconfig2[4];
                myconfig[2] = 0 ;
                myconfig2[2] = 0 ;
                let sum = 0;
                let isMax = false;



                let filePointerHeadInt1 = new Uint32Array(vm.sabcs1.filePointerFileHead);
                // let filePointerTailInt1 = new Uint32Array(vm.sabcs1.filePointerTail);
                // let fileContentDataInt1 = new Int16Array(vm.sabcs1.fileContentData);
                let filePointerHeadInt2 = new Uint32Array(vm.sabcs2.filePointerFileHead);
                // let filePointerTailInt2 = new Uint32Array(vm.sabcs2.filePointerTail);
                // let fileContentDataInt2 = new Int16Array(vm.sabcs2.fileContentData);
                const min = 1024 * 4;
                let fileCombinedDataInt = new Int16Array(vm.sharedFileContainerResult);
                let fileCombinedStatusInt = new Int32Array(vm.sharedFileContainerStatus);
                // let currentData1 = new Uint16Array(vm.sabcs1.currentData);
                // let currentData2 = new Uint16Array(vm.sabcs2.currentData);

                
                let myidx = 0;
                // while (Atomics.wait(StatesFile1, STATE.REQUEST_WRITE_FILE, 0) === 'ok' && Atomics.wait(StatesFile2, STATE.REQUEST_WRITE_FILE, 0) === 'ok') {
                // while (Atomics.wait(StatesFile1, STATE.REQUEST_WRITE_FILE, 0) === 'ok' && Atomics.wait(StatesFile2, STATE.REQUEST_WRITE_FILE, 0) === 'ok') {
                while (!isStopRecording && Atomics.wait(fileCombinedStatusInt, 9,0) === 'ok') {
                // while (!isStopRecording && Atomics.wait(StatesFile1, STATE.REQUEST_WRITE_FILE, 0) === 'ok') {
                    // fileCombinedDataInt.fill(0);
                    // for (let idx = 0;idx<min;idx++){
                    //     myidx = idx*2;
                    //     fileCombinedDataInt[myidx] = fileContentDataInt1[idx];
                    //     fileCombinedDataInt[myidx+1] = fileContentDataInt2[idx];
                    // }
                    
                    // console.log("Combined data : ", fileCombinedDataInt.length, fileContentDataInt1.length, fileContentDataInt2.length);
                    sum = fileCombinedStatusInt[0]+fileCombinedStatusInt[1];
                    const subarray = fileCombinedDataInt.slice(0,sum);
                    // console.log(subarray);
                    await writable.write(subarray.buffer);
                    // console.log(" filePointerHeadInt1 : ",filePointerHeadInt1[0], filePointerHeadInt2[0], sum);
                    vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT]+=(sum);
                    if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                        isStopRecording = true;                        
                        break;
                    }else
                    if (!isStopRecording){
                        filePointerHeadInt1[0] = 0;
                        filePointerHeadInt2[0] = 0;
                        fileCombinedStatusInt[0] = 0;
                        fileCombinedStatusInt[1] = 0;
                        // Atomics.store(StatesFile1, STATE.REQUEST_WRITE_FILE, 0);
                        // Atomics.store(StatesFile2, STATE.REQUEST_WRITE_FILE, 0);
                        Atomics.store(fileCombinedStatusInt, 9, 0);
                    }
                }
                // while (!isStopRecording && Atomics.wait(StatesFile1, STATE.REQUEST_WRITE_FILE, 0) === 'ok' && Atomics.wait(StatesFile2, STATE.REQUEST_WRITE_FILE, 0) === 'ok') {
                // while (Atomics.wait(StatesFile1, STATE.REQUEST_WRITE_FILE, 0) === 'ok' && Atomics.wait(StatesFile2, STATE.REQUEST_WRITE_FILE, 0) === 'ok') {
                //     if (!isStopRecording) break;
                // // while (!isStopRecording) {
                //     // let readIdx = StatesFile1[STATE.IB_READ_INDEX];
                //     // let writeIdx = StatesFile1[STATE.IB_WRITE_INDEX];
                //     // let readIdx2 = StatesFile2[STATE.IB_READ_INDEX];
                //     // let writeIdx2 = StatesFile2[STATE.IB_WRITE_INDEX];
                //     // console.log("myconfig", myconfig[2], myconfig2[2],readIdx,writeIdx,readIdx2,writeIdx2);
                //     let tempIdxChannel1 = myconfig[4];
                //     let tempIdxChannel2 = myconfig2[4];
                //     // myconfigzzz 498 499 498 499
                //     // myconfig 1024 1024 1024 1024
                //     // console.log("myconfigzzz", idxChannel1, tempIdxChannel1, idxChannel2 , tempIdxChannel2);
                //     if (idxChannel1 != tempIdxChannel1 && idxChannel2 != tempIdxChannel2){
                //         idxChannel1 = tempIdxChannel1;
                //         idxChannel2 = tempIdxChannel2;
                //         // console.log("myconfig", myconfig[2], myconfig2[2], myconfig[3], myconfig2[3], myconfig[4], myconfig2[3]);
                //         //myconfig 1024 0 2048 1024 462 1024
                //         let idx = myconfig[2];
                //         let min = Math.min(myconfig[3], myconfig2[3]);
                //         let min1 = 0;
                //         let min2 = 0;
                //         //if write max, and read still not max, 
                //         if (myconfig[3] == 0 && myconfig[2]==7168){
                //             // console.log("MINNNS");
                //             myconfig[2] = 0;
                //             min1 = 8192;
                //         }
                //         if (myconfig2[3] == 0 && myconfig2[2]==7168){
                //             // console.log("MINNNS2");
                //             myconfig2[2] = 0;
                //             min = 8192;
                //             min2 = min;
                //             isMax = true;
                //         }

                //         // this thread increase head, buffer-worker.js increase tail
                //         // if head equal or morethan tail, slow down,
                //         let diff = min-idx;
                //         if (diff<=0) continue;
                //         sum += (min-idx)*2;

                //         // console.log("min-idx : ",min-idx, min, idx, min1, min2);

                //         let myidx = 0;
                //         let counter = 0;
                //         for (;idx<min;idx++, counter++){
                //             // if (idx % 2 === 0) {
                //             //     combinedData[idx] = currentData1[idx / 2];
                //             // } else {
                //             //     combinedData[idx] = currentData2[(idx - 1) / 2];
                //             // }                        
                //             myidx = counter*2;
                //             combinedData[myidx] = currentData1[idx];
                //             combinedData[myidx+1] = currentData2[idx];
                //             // combinedData[myidx] = tempIdxChannel1;
                //             // combinedData[myidx+1] = tempIdxChannel1;

                //             // myconfig 3072 3072 4096 4096 375 4096
                //             // file.worker.js:491 stop recording2  768000 true 375 375
                //             // file.worker.js:495 wavBufferWriteTailIdx  739328
                //             currentData1[idx] = 0;
                //             currentData2[idx] = 0;
                //         }
                //         myconfig[2] += diff;
                //         myconfig[2] = myconfig[2] % 8192;
                //         myconfig2[2] += diff;
                //         myconfig2[2] = myconfig2[2] % 8192;

                //         // combinedData.set( combiningData.slice(0,combinedData.length), 0 );
    
                //         // if (myconfig[2] == 7168){
                //         //     console.log("combinedData",combinedData);
                //         //     console.log("2min-idx : ",min-idx, min, idx, min1, min2);
                //         //     console.log("2myconfig", myconfig[2], myconfig2[2], myconfig[3], myconfig2[3], myconfig[4], myconfig2[3]);
                //         // }
                //         // }else{
                //             await writable.write(combinedData.buffer);
                //             vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT]+=2048;                    
                //         // }
                //         if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                //             isStopRecording = true;                        
                //             break;
                //         }else
                //         if (!isStopRecording){
                //             Atomics.store(StatesFile1, STATE.REQUEST_WRITE_FILE, 0);
                //             Atomics.store(StatesFile2, STATE.REQUEST_WRITE_FILE, 0);
                //         }
        
        
                //     }
    
                //     // console.log("entered?");
                //     // console.log("myidx",myidx);




                //     /*

                //     const ringBuffer1 = new Uint16Array(vm.sabcs1.inputRingBuffer);
                //     let readIdx1 = StatesFile1[STATE.IB_READ_INDEX];
                //     const writeIdx1 = StatesFile1[STATE.IB_WRITE_INDEX];

                //     const ringBuffer2 = new Uint16Array(vm.sabcs2.inputRingBuffer);
                //     let readIdx2 = StatesFile2[STATE.IB_READ_INDEX];
                //     const writeIdx2 = StatesFile2[STATE.IB_WRITE_INDEX];

                //     while(readIdx1 != writeIdx1 && readIdx2 != writeIdx2){
                //         // wavBufferWriteTailIdx++;
                //         if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                //             console.log("WHILE IS STOP RECORDING 0 ");
                //             isStopRecording = true;                        
                //             break;
                //         }
    
                //         if (isStopRecording){
                //             console.log("WHILE IS STOP RECORDING");
                //             break;
                //         }

                //         // console.log("DATA : ",ringBuffer1[readIdx1],ringBuffer2[readIdx2]);

                //         if (readIdx1 != writeIdx1){//prevent mismatch
                //             let mytemp = new Uint16Array(1);
                //             mytemp[0] = ringBuffer1[readIdx1];
                //             await writable.write(mytemp).then(()=>{
                //             });
                //             if (++readIdx1 === CONFIG.ringBufferLength)
                //                 readIdx1 = 0;
                //         }
                //         if (readIdx2 != writeIdx2){//prevent mismatch
                //             let mytemp = new Uint16Array(1);
                //             mytemp[0] = ringBuffer2[readIdx2];
                //             await writable.write(mytemp).then(()=>{
                //             });
            
                //             if (++readIdx2 === CONFIG.ringBufferLength)
                //                 readIdx2 = 0;
                //         }
                //         vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT]++;                                

                //     };
                //     if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                //         isStopRecording = true;                        
                //         break;
                //     }else
                //     if (!isStopRecording){
                //         Atomics.store(StatesFile1, STATE.REQUEST_WRITE_FILE, 0);
                //         Atomics.store(StatesFile2, STATE.REQUEST_WRITE_FILE, 0);
                //     }

                //     */


                //     // write samples data
                //     //writeable.write()

                // }

                console.log("stop recording2 ",channelCount, sum, isStopRecording, myconfig[4], myconfig2[4]);

                if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                    wavBufferWriteTailIdx = vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT];
                    console.log("wavBufferWriteTailIdx ", wavBufferWriteTailIdx);// 195584
                                    
                    // let chunk_size_data = 36 + wavBufferWriteTailIdx - 44;
                    // writableStream.write({ type: "write", position: WAV_STATE.CHUNK_SIZE_INDEX, data: chunk_size_data }).then(async ()=>{
                    //     const Subchunk2Size = wavBufferWriteTailIdx * 2 * 16 / 8;
                    //     await writableStream.write({ type: "write", position: WAV_STATE.SUBCHUNK2_SIZE_INDEX, data: Subchunk2Size });    
                    //     await writableStream.close();

                    // });
                    //wav.LIST :  [{"chunkId":"LIST","chunkSize":172,"format":"INFO","subChunks":[{"chunkId":"cpos","chunkSize":19,"value":"0.257143;0.532767;"},{"chunkId":"ctrs","chunkSize":9,"value":"100;100;"},{"chunkId":"cgin","chunkSize":9,"value":"0.5;0.5;"},{"chunkId":"cclr","chunkSize":5,"value":"6;2;"},{"chunkId":"ctms","chunkSize":5,"value":"0.1;"},{"chunkId":"cnam","chunkSize":56,"value":"Built-in Microphone [Left];Built-in Microphone [Right];"},{"chunkId":"cdev","chunkSize":3,"value":"0;"}]}];
                    const firstListChunkPos = wavBufferWriteTailIdx * 1 * 16 / 8;
                    // num channels should be 1 & not 2 because it is priced in the wavBufferWriteTailIdx total samples in 2 channels
                    wavList.fromScratch(vm.channelCount, vm.sampleRate, '16', []);
                    wavList.LIST = [{
                        chunkId: 'LIST',
                        chunkSize: 47,
                        format: 'INFO',
                        subChunks: [
                            {
                                chunkId: 'cpos',
                                chunkSize: 5,
                                value: '0.1;0.3;'
                            },
                            {
                                chunkId: 'ctrs',
                                chunkSize: 5,
                                value: '0;0;'
                            },
                            {
                                chunkId: 'cgin',
                                chunkSize: 5,
                                value: '0.5;0.5;'
                            },
                            {
                                chunkId: 'cclr',
                                chunkSize: 5,
                                value: vm.channelColor1+';' + vm.channelColor2 + ';'
                            },
                            {
                                chunkId: 'ctms',
                                chunkSize: 3,
                                value: '1;'
                            },
                            {
                                chunkId: 'cnam',
                                chunkSize: 21,
                                value: 'AUDIO - 1;AUDIO - 2;'
                            },
                            {
                                chunkId: 'cdev',
                                chunkSize: 3,
                                value: '0;'
                            },   
                        ] 
                    }];
    
                    const subArrList = wavList.toBuffer().subarray(wavBuffer.length);
                    let bufferOdd = wavBuffer.length + firstListChunkPos;
                    if ( bufferOdd  % 2 == 1){
                        console.log("BUFFER ODD : ",bufferOdd);
                        await writable.write('\0')
                        wavBufferWriteTailIdx++;
                    }
                    
    
                    await writable.write(subArrList);

                    let temp2 = new Uint32Array(1);
                    // const Subchunk2Size = wavBufferWriteTailIdx * 2 * 16 / 8;
                    // const Subchunk2Size = wavBufferWriteTailIdx * 2 * 16/8;
                    const Subchunk2Size = firstListChunkPos;

                    temp2[0] = Subchunk2Size;
                    await writable.write({ type: "write", position: WAV_STATE.SUBCHUNK2_SIZE_INDEX, data: temp2.buffer });


                    let temp = new Uint32Array(1);
                    let chunk_size_data = 36 + Subchunk2Size + subArrList.length;
                    temp[0] = chunk_size_data;
                    await writable.write({ type: "write", position: WAV_STATE.CHUNK_SIZE_INDEX, data: temp.buffer }).then(async()=>{
                    });

                    await writable.close();

                    const file = await _fileHandle.getFile();
                    // console.log("file : ",file);
                    const buffers = new Uint8Array (await file.arrayBuffer());
                    // console.log("buffers : ",buffers);
    
                    let str = '';
                    const eventGlobalPositionInt = new Uint32Array(vm.sabcs1.eventGlobalPosition);
                    const eventsIdxInt = new Uint8Array(vm.sabDraw.events);
                    const counter = (new Uint32Array(vm.sabDraw.draw_states[0]))[DRAW_STATE.EVENT_COUNTER];
                    const tabSeparator = String.fromCharCode(9);
                    // const SIZE = NUMBER_OF_SEGMENTS * vm.sampleRate;
                    
                    for (let i = 0 ; i < counter ; i++){
                        let adjustedPosition = (eventGlobalPositionInt[i] - vm.startingHeader);
                        if (adjustedPosition>0){
                            const pos = ( adjustedPosition / sampleRate ).toFixed(4);
                            str+=(eventsIdxInt[i]+","+tabSeparator+pos)+"\r\n";
                        }
                        console.log("adjusted position ",eventGlobalPositionInt[i],vm.startingHeader);    
                        // str+=`${eventsIdxInt[i]},${tabSeparator}${pos}\r\n`;
                    }
                    
                    
                    zip.file("signal.wav", buffers);
                    zip.file("signal-events.txt", 
                        `# Marker IDs can be arbitrary strings.\r\n# Marker ID,	Time (in s)\r\n`+str);
                        
                        const strVersion = "1";
                        const curDateTime = new Date();
                        const recordingDate = curDateTime.getMonth()+"."+curDateTime.getDate()+"."+curDateTime.getFullYear();
                        const recordingTime = curDateTime.getHours()+":"+curDateTime.getMinutes()+":"+curDateTime.getSeconds();
                        const recordingDevice = "<recordingdevice><name>Audio Device</name><type>Audio Device</type><filter><hp>0</hp><lp>"+Math.floor(sampleRate/2)+"</lp><comment></comment></filter></recordingdevice>";
                        const applicationTag = "<application><platform>"+event.data.os+"</platform><sysversion>"+event.data.userAgent+"</sysversion><appversion>"+event.data.versionNumber+"</appversion></application>";
                        // List<Color> audioChannelColors = [ Color(0xFF10ff00), Color(0xFFff0035), Color(0xFFe1ff4b), Color(0xFFff8755), Color(0xFF6bf063),Color(0xFF00c0c9),];
                        const audioColors = ["#10FF00", "#FF0035", "#E1FF4B", "#FF8755", "#6BF063", "#00c0c9",];
                        let strChannels = '';
                        for (let i = 1; i <= vm.channelCount ; i++){
                            const colorIndex = audioColors[vm["channelColor"+i]];
                            strChannels += '<channels><channel><name>Channel '+i+'</name><filter><hp>0</hp><lp>'+ Math.floor(sampleRate/2) +'</lp><notch>0</notch></filter><samplerate>'+sampleRate+'</samplerate><colorindex>'+colorIndex+'</colorindex> <digitalmin>-32768</digitalmin><digitalmax>32767</digitalmax> <physicalmin>100</physicalmin> <physicalmax>100</physicalmax> <physicaldimension>dB</physicaldimension> </channel></channels>';
                        }
        
                        let recordingFiles = "<file><type>signal</type><version>"+strVersion+"</version> <path>signal.wav</path> <format>wav</format> <bytespersample>2</bytespersample> <samplerate>"+sampleRate+"</samplerate> <numchannels>"+vm.channelCount+"</numchannels>"+strChannels+" </file> <file><type>events</type><version>" + strVersion + "</version> <path>signal-events.txt</path> </file> <file><type>spikes</type><version>" + strVersion + "</version> <path>signal-events.txt</path> </file>";
        
                        let header = "<header><version>"+strVersion+"</version><recordingdate>"+recordingDate+"</recordingdate>"+recordingTime+
                                     applicationTag +
                                     "<subject><name></name><id></id><comment></comment></subject> " + recordingDevice + "<files>" + recordingFiles + "</files> </header>";
                    console.log("HEADER2 ", header);

                    zip.file("header.xml", header);
                            
                    zip.generateAsync({
                        type: 'uint8array',
                        compression : 'store',
                        mimeType: 'application/wav',
                    }).then(async function (content) {
                        // see FileSaver.js
                        console.log("content : ",content);
                        writable = await _fileHandle.createWritable();
                        await writable.write(content);
                        await writable.close();

    
                        //saveAs(content, "hello.zip");
                    }).catch(function(err){
                        console.log("Genberate async : ",err);
                    });
    

                }                
                myconfig2[2] = -1;
    
            }
            let myconfig = new Int32Array(vm.sabcs1.config);
            myconfig[2] = -1;
            clearBuffer(vm.sabcs1, vm.sabWriteState);
            if (vm.sabcs2 !== undefined)
                clearBuffer(vm.sabcs2,vm.sabWriteState);
            isStopRecording = false;
            vm.sabWriteState[WRITE_STATE.IS_RECORDING] = 0;


            // worker2port.onmessage = onMessageFromWorker;
        break;
        case "sabcs":
            vm.rawSabcs = event.data.rawSabcs;
            vm.sabDraw = event.data.sabDraw;
            vm.sharedFileContainer = event.data.sharedFileContainer;
            vm.sharedFileContainerResult = event.data.sharedFileContainerResult;
            vm.sharedFileContainerStatus = event.data.sharedFileContainerStatus;
            console.log("SABCS", vm.rawSabcs,vm.channelCount);
            // return;
      
        break;
        case "setUp":
            vm.channelCount = event.data.channelCount;
        break;
        case "forward":
            workerForwardPort = event.ports[0];
        break;
        

        default:
            console.log( event.data );
    }
};

function asciiToUint8Array(str){
    console.log("ASCII",str);
    var chars = [];
    for (var i = 0; i < str.length; ++i){
      chars.push(str.charCodeAt(i));/*from  w  ww. j  a  v  a  2s.c o  m*/
    }
    return new Uint8Array(chars);
}
  
async function writeSubchunk(writable,label, value, currentBufferCount){
    const arrLabel = asciiToUint8Array(label);
    const arrValue = asciiToUint8Array(value+"\0");

    await writable.write(arrLabel.buffer);
    const put32 = new Uint32Array(1);
    // put32[0] = label.length + 1;
    const dv = new DataView(put32.buffer).setUint32(0,arrValue.length, true);

    await writable.write(put32.buffer);
    // await writable.write(dv.buffer);
    await writable.write(arrValue.buffer);
    
    console.log("currentBufferCount3 : ",currentBufferCount);
    if (currentBufferCount+arrLabel.length + arrValue.length % 2 == 0){
        await writable.write(asciiToUint8Array('\0').buffer);
        currentBufferCount =  currentBufferCount+arrLabel.length+arrValue.length;
    }else{
        currentBufferCount =  currentBufferCount+arrLabel.length+arrValue.length;
    }
    return currentBufferCount;
}
// fwrite(id, 4, 1, f);
// put32(content.size()+1, f);
// fwrite(content.c_str(), content.size()+1, 1, f);
// padbyte(f);

function clearBuffer(sabcs,sabWriteState){
    // let _config = new Int32Array(sabcs.config);
    // _config[2]=-1;

    // const eventGlobalPositionInt = new Uint32Array(sabcs.eventGlobalPosition);
    // eventGlobalPositionInt.fill(0);
    // const eventGlobalNumberInt = new Uint8Array(sabcs.eventGlobalNumber);
    // eventGlobalNumberInt.fill(0);
    // const eventGlobalHeaderInt = new Uint32Array(sabcs.eventGlobalHeader);
    // eventGlobalHeaderInt.fill(0);
    // const eventsIdxInt = new Uint32Array(sabcs.eventsIdx);
    // eventsIdxInt.fill(0);
    // const globalPositionCapInt = new Uint8Array(sabcs.globalPositionCap);
    // globalPositionCapInt.fill(0);

    sabWriteState[WRITE_STATE.PROCESSED_COUNT] = 0;

    // (new Uint32Array(vm.sabDraw.draw_states[0]))[DRAW_STATE.EVENT_COUNTER] = 0;
    // eventsCounterInt = new Uint8Array(sabDraw.eventsCounter);
    // eventPositionInt = new Uint32Array(sabDraw.eventPosition);
    // eventPositionResultInt = new Float32Array(sabDraw.eventPositionResult);
    // eventsInt = new Uint8Array(sabDraw.events);

    // eventsCounterInt.fill(0);


}