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


const WAV_STATE = {
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
var wav = new wavefile.WaveFile();

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
        wav.fromScratch(vm.channelCount, vm.sampleRate, '16', []);
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

        if ( vm.channelCount == 1 ){
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

            wav.fromScratch(vm.channelCount, vm.sampleRate, '16', arr);
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
            worker2port = event.ports[0];

            await createHeader();

            if (vm.channelCount == 1){
                vm.sabcs1 = vm.rawSabcs[0];
                let StatesFile1 = new Int32Array(vm.sabcs1.statesWrite);
                console.log("--vm.channelCount",vm.channelCount);
                // writable = await _fileHandle.createWritable();

                // let promises = [];
                let arrMax = new Int16Array(vm.sabcs1.arrFileMax);

                while (!isStopRecording && Atomics.wait(StatesFile1, STATE.REQUEST_WRITE_FILE, 0) === 'ok') {
                    const ringBuffer = new Uint16Array(vm.sabcs1.inputRingBuffer);
                    let readIdx = StatesFile1[STATE.IB_READ_INDEX];
                    let writeIdx = StatesFile1[STATE.IB_WRITE_INDEX];

                    let myconfig = new Int32Array(vm.sabcs1.config);
                    let currentData = new Int16Array(vm.sabcs1.currentData);
                    // console.log("currentData",currentData);

                    await writable.write(currentData.slice(0).buffer);
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

                    vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT]+=1024;

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
                console.log("STOPPP RECORDING1 ",wavBufferWriteTailIdx);//365568

                let temp2 = new Uint32Array(1);
                const Subchunk2Size = wavBufferWriteTailIdx * 1 * 16 / 8;
                temp2[0] = Subchunk2Size;
                await writable.write({ type: "write", position: WAV_STATE.SUBCHUNK2_SIZE_INDEX, data: temp2.buffer })

                let temp = new Uint32Array(1);
                let chunk_size_data = 36 + Subchunk2Size;
                temp[0] = chunk_size_data;
                await writable.write({ type: "write", position: WAV_STATE.CHUNK_SIZE_INDEX, data: temp.buffer });

                console.log("CLOSEEEZ", temp[0],temp2[0]);
                await writable.close();
                    
            }else{
                console.log("CHANNEL IS 2 recording ", isStopRecording);
                vm.sabcs1 = vm.rawSabcs[0];
                vm.sabcs2 = vm.rawSabcs[1];
                let StatesFile1 = new Int32Array(vm.sabcs1.statesWrite);
                let StatesFile2 = new Int32Array(vm.sabcs2.statesWrite);
                let combinedData = new Uint16Array(1024 * Int16Array.BYTES_PER_ELEMENT);
                let currentData1 = new Uint16Array(vm.sabcs1.currentData);
                let currentData2 = new Uint16Array(vm.sabcs2.currentData);

                while (!isStopRecording && Atomics.wait(StatesFile1, STATE.REQUEST_WRITE_FILE, 0) === 'ok' && Atomics.wait(StatesFile2, STATE.REQUEST_WRITE_FILE, 0) === 'ok') {
                    let myconfig = new Int32Array(vm.sabcs1.config);

                    // console.log("entered?");
                    let idx = 0;
                    let myidx = 0;
                    for (;idx<1024;idx++){
                        // if (idx % 2 === 0) {
                        //     combinedData[idx] = currentData1[idx / 2];
                        // } else {
                        //     combinedData[idx] = currentData2[(idx - 1) / 2];
                        // }                        
                        myidx = idx*2;
                        combinedData[myidx] = currentData1[idx];
                        combinedData[myidx+1] = currentData2[idx];
                    }
                    // console.log("myidx",myidx);
                    await writable.write(combinedData.buffer);
                    vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT]+=1024;                    


                    if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                        isStopRecording = true;                        
                        break;
                    }else
                    if (!isStopRecording){
                        Atomics.store(StatesFile1, STATE.REQUEST_WRITE_FILE, 0);
                        Atomics.store(StatesFile2, STATE.REQUEST_WRITE_FILE, 0);
                    }


                    /*

                    const ringBuffer1 = new Uint16Array(vm.sabcs1.inputRingBuffer);
                    let readIdx1 = StatesFile1[STATE.IB_READ_INDEX];
                    const writeIdx1 = StatesFile1[STATE.IB_WRITE_INDEX];

                    const ringBuffer2 = new Uint16Array(vm.sabcs2.inputRingBuffer);
                    let readIdx2 = StatesFile2[STATE.IB_READ_INDEX];
                    const writeIdx2 = StatesFile2[STATE.IB_WRITE_INDEX];

                    while(readIdx1 != writeIdx1 && readIdx2 != writeIdx2){
                        // wavBufferWriteTailIdx++;
                        if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                            console.log("WHILE IS STOP RECORDING 0 ");
                            isStopRecording = true;                        
                            break;
                        }
    
                        if (isStopRecording){
                            console.log("WHILE IS STOP RECORDING");
                            break;
                        }

                        // console.log("DATA : ",ringBuffer1[readIdx1],ringBuffer2[readIdx2]);

                        if (readIdx1 != writeIdx1){//prevent mismatch
                            let mytemp = new Uint16Array(1);
                            mytemp[0] = ringBuffer1[readIdx1];
                            await writable.write(mytemp).then(()=>{
                            });
                            if (++readIdx1 === CONFIG.ringBufferLength)
                                readIdx1 = 0;
                        }
                        if (readIdx2 != writeIdx2){//prevent mismatch
                            let mytemp = new Uint16Array(1);
                            mytemp[0] = ringBuffer2[readIdx2];
                            await writable.write(mytemp).then(()=>{
                            });
            
                            if (++readIdx2 === CONFIG.ringBufferLength)
                                readIdx2 = 0;
                        }
                        vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT]++;                                

                    };
                    if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                        isStopRecording = true;                        
                        break;
                    }else
                    if (!isStopRecording){
                        Atomics.store(StatesFile1, STATE.REQUEST_WRITE_FILE, 0);
                        Atomics.store(StatesFile2, STATE.REQUEST_WRITE_FILE, 0);
                    }

                    */


                    // write samples data
                    //writeable.write()

                }

                console.log("stop recording2 ", isStopRecording);

                if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                    wavBufferWriteTailIdx = vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT];
                    console.log("wavBufferWriteTailIdx ", wavBufferWriteTailIdx);
                                    
                    // let chunk_size_data = 36 + wavBufferWriteTailIdx - 44;
                    // writableStream.write({ type: "write", position: WAV_STATE.CHUNK_SIZE_INDEX, data: chunk_size_data }).then(async ()=>{
                    //     const Subchunk2Size = wavBufferWriteTailIdx * 2 * 16 / 8;
                    //     await writableStream.write({ type: "write", position: WAV_STATE.SUBCHUNK2_SIZE_INDEX, data: Subchunk2Size });    
                    //     await writableStream.close();

                    // });
                    let temp2 = new Uint32Array(1);
                    // const Subchunk2Size = wavBufferWriteTailIdx * 2 * 16 / 8;
                    const Subchunk2Size = wavBufferWriteTailIdx * 2 * 16/8;
                    temp2[0] = Subchunk2Size;
                    await writable.write({ type: "write", position: WAV_STATE.SUBCHUNK2_SIZE_INDEX, data: temp2.buffer });


                    let temp = new Uint32Array(1);
                    let chunk_size_data = 36 + Subchunk2Size;
                    temp[0] = chunk_size_data;
                    await writable.write({ type: "write", position: WAV_STATE.CHUNK_SIZE_INDEX, data: temp.buffer }).then(async()=>{
                    });

                    await writable.close();

                }                
    
            }


            // worker2port.onmessage = onMessageFromWorker;
        break;
        case "sabcs":
            vm.rawSabcs = event.data.rawSabcs;
            console.log("SABCS", vm.rawSabcs,vm.channelCount);
            // return;
      
        break;
        case "process":
        break;
        case "forward":
            workerForwardPort = event.ports[0];
        break;
        

        default:
            console.log( event.data );
    }
};