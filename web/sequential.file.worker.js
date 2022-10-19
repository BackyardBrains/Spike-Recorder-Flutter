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

let productId = '';
let deviceInfo;
let deviceType;


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
        wav.fromScratch(channelCount, vm.sampleRate, '16', []);
        console.log("wav.byteRate", wav.byteRate);
        writable = await _fileHandle.createWritable();
        console.log("WRITABLE", writable, vm.channelCount);

        // wav.fromScratch(vm.channelCount, vm.sampleRate, '16', arr);
        wavBuffer = wav.toBuffer();
    

        // if ( vm.channelCount != 2 ){
        //     let arr = [];
        //     wav.fromScratch(vm.channelCount, vm.sampleRate, '16', arr);
        //     wavBuffer = wav.toBuffer();
        //     console.log(wavBuffer);
        // }else{
        //     wav.fromScratch(2, vm.sampleRate, '16', []);
        //     wavBuffer = wav.toBuffer();
        // }
        // console.log( JSON.stringify(wavBuffer) );
        await writable.write(wavBuffer);
        // return wavBuffer.length;
    }

    async function createWavList(channelCount, sampleRate, data, startIdx){
        wavList.fromScratch(channelCount, sampleRate, '16', []);
        let subChunks = [];
        let chunkSizeTotal = 0;
        let flagChannelDisplays = new Uint32Array(vm.sabDraw.channelDisplays);
        // console.log("flags : ", flagChannelDisplays, vm.sabDraw);
        // const sum = flagChannelDisplays.reduce((pre,curr)=>pre+curr,0);

        let labels =["cpos", "ctrs", "cgin", "cclr", "ctms", "cnam", "cdev"];
        for (let j = 0; j < labels.length ; j++){
            const size = channelCount * 2 + 1;
            chunkSizeTotal += size;
            let subchunk = {
                chunkId : labels[j],
                chunkSize : size,
                value : ''
            };
            for (let i = 0; i < channelCount; i++){
                if (flagChannelDisplays[i] == 1){
                    switch (labels[j]){
                        case  'cpos' :
                            subchunk["value"] += ("0."+i+";");
                        break;
                        case  'ctrs' :
                            subchunk["value"] += ("0;");
                        break;
                        case  'cgin' :
                            subchunk["value"] += ("0.5;");
                        break;
                        case  'ctms' :
                            subchunk["value"] += ("1;");
                        break;
                        case  'cclr' :
                            subchunk["value"] += ( (data["color"+(i+1)]===undefined? 1 : data["color"+(i+1)] )+";");
                        break;
                        case  'cnam' :
                            if (data.deviceType == 'hid'){
                                subchunk["value"] += (data["productId"]+"@HID - Channel "+ (i + 1) +";");
                            }else{
                                subchunk["value"] += (data["productId"]+"@Serial - Channel "+ (i + 1) +";");
                            }
                        break;
                    }
                }
            }
            if (labels[j] == 'cdev'){
                if (deviceInfo.deviceIdx !== undefined){
                    subchunk["value"] = deviceInfo.deviceIdx;
                }else
                    subchunk["value"] = '7;';
            }
            subChunks.push(subchunk);
        }
        console.log("subChunks : ",subChunks);
        wavList.LIST = [{
            chunkId: 'LIST',
            chunkSize: chunkSizeTotal,
            format: 'INFO',
            subChunks: subChunks
        }];
        const result = wavList.toBuffer().subarray(startIdx);
        console.log("subChunks result raw : ",JSON.stringify(wavList.toBuffer()) );
        console.log("subChunks result : ", JSON.stringify(result) );
        return result;
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
            vm.settingParams = event.data;
            vm.sabWriteState = new Int32Array(event.data.sabWriteState);
            worker2port = event.ports[0];

            let flagChannelDisplays = new Uint32Array(vm.sabDraw.channelDisplays);
            const sum = flagChannelDisplays.reduce((pre,curr)=>pre+curr,0);
            console.log("flags : ", sum, flagChannelDisplays, vm.sabDraw);

            // await createHeader(vm.channelCount);
            await createHeader(sum);

            const NUMBER_OF_SEGMENTS = 60;
            const SEGMENT_SIZE = sampleRate;
            const SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;

            const wavBuffer = wav.toBuffer();

            productId = event.data['productId'];
            deviceInfo = DEVICE_PRODUCT[productId];
            deviceType = event.data.deviceType;

            // const subArrayList = await createWavList(vm.channelCount, vm.sampleRate, event.data, wavBuffer.length);
            const subArrayList = await createWavList(sum, vm.sampleRate, event.data, wavBuffer.length);
            WAV_STATE.SUBCHUNK2_SIZE_INDEX = wavBuffer.length - (4);

            console.log("SABCS CONNECT", vm.rawSabcs);
            vm.sabcs1 = vm.rawSabcs[0];

            const eventGlobalHeaderInt = new Uint32Array(vm.sabcs1.eventGlobalHeader);
            vm.startingHeader = eventGlobalHeaderInt[0];


            let MyConfig = new Int32Array(vm.sabcs1.config);
            MyConfig[2] = 1;
            let StatesFile1 = new Int32Array(vm.sabcs1.statesWrite);
            console.log("--vm.channelCount",vm.channelCount);

            while (!isStopRecording && Atomics.wait(StatesFile1, STATE.REQUEST_WRITE_FILE, 0) === 'ok') {
                // const ringBuffer = new Uint16Array(vm.sabcs1.inputRingBuffer);
                // let readIdx = StatesFile1[STATE.IB_READ_INDEX];
                // let writeIdx = StatesFile1[STATE.IB_WRITE_INDEX];

                // let myconfig = new Int32Array(vm.sabcs1.config);
                let currentDataInt = new Int16Array(vm.sabcs1.currentData);
                let currentDataEndInt = new Uint32Array(vm.sabcs1.currentDataEnd);

                const subpart = currentDataInt.slice(0, currentDataEndInt[0]);
                // console.log("subpart : ",subpart);

                await writable.write(subpart.buffer);
                vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT]+=subpart.length;

                if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                    isStopRecording = true;                        
                    break;
                }else
                if (!isStopRecording){
                    Atomics.store(StatesFile1, STATE.REQUEST_WRITE_FILE, 0);
                }
            }

            // const subArrList = wavList.toBuffer().subarray(44);

            wavBufferWriteTailIdx = vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT];
            console.log("STOPPP RECORDING1 ", wavBufferWriteTailIdx);//365568
            
            let currentDataLengthInt = new Uint32Array(vm.sabcs1.currentDataLength);
            console.log("currentDataLengthInt : ", currentDataLengthInt);

            const firstListChunkPos = wavBufferWriteTailIdx * 1 * 16 / 8;
            // let bufferOdd = wavBuffer.length + firstListChunkPos;
            // if ( bufferOdd  % 2 == 1){
            //     console.log("BUFFER ODD : ",bufferOdd);
            //     await writable.write('\0')
            //     wavBufferWriteTailIdx++;
            // }
            await writable.write(subArrayList);


            let temp2 = new Uint32Array(1);
            // const Subchunk2Size = wavBufferWriteTailIdx * 1 * 16 / 8;
            const Subchunk2Size = firstListChunkPos;//252432 => 36 + 252160 + 236
            temp2[0] = Subchunk2Size;
            await writable.write({ type: "write", position: WAV_STATE.SUBCHUNK2_SIZE_INDEX, data: temp2.buffer })

            let temp = new Uint32Array(1);
            let chunk_size_data = 36 + Subchunk2Size + subArrayList.length;//36 + 252164 + 236
            temp[0] = chunk_size_data;
            await writable.write({ type: "write", position: WAV_STATE.CHUNK_SIZE_INDEX, data: temp.buffer });

            console.log("CLOSEEEZ", temp[0],temp2[0]);
            // CLOSEEEZ 460888 460714
            await writable.close();



            const file = await _fileHandle.getFile();
            const buffers = new Uint8Array (await file.arrayBuffer());
            console.log("startingHeader : ", vm.startingHeader);

            let str = '';
            const eventGlobalPositionInt = new Uint32Array(vm.sabcs1.eventGlobalPosition);
            const counter = (new Uint32Array(vm.sabDraw.draw_states[0]))[DRAW_STATE.EVENT_COUNTER];
            const eventsIdxInt = new Uint8Array(vm.sabDraw.events);
            const tabSeparator = String.fromCharCode(9);
            
            for (let i = 0 ; i < counter ; i++){
                let adjustedPosition = (eventGlobalPositionInt[i] - vm.startingHeader);
                if (adjustedPosition>0){
                    const pos = ( adjustedPosition / sampleRate ).toFixed(4);
                    str+=(eventsIdxInt[i]+","+tabSeparator+pos)+"\r\n";
                    console.log("adjusted position ",eventGlobalPositionInt[i],vm.startingHeader);    
                }
            }
            console.log("STR : ", str);

        
            zip.file("signal.wav", buffers);
            zip.file("signal-events.txt", 
                `# Marker IDs can be arbitrary strings.\r\n# Marker ID,	Time (in s)\r\n`+str);
            // console.log("STR : ", str);
            // console.log("eventGlobalPositionInt : ", eventGlobalPositionInt);
            // console.log("eventsIdxInt : ", eventsIdxInt);
            
            const strVersion = "1";
            const curDateTime = new Date();
            const recordingDate = curDateTime.getMonth()+"."+curDateTime.getDate()+"."+curDateTime.getFullYear();
            const recordingTime = curDateTime.getHours()+":"+curDateTime.getMinutes()+":"+curDateTime.getSeconds();

            const recordingDevice = "<recordingdevice><name>"+deviceInfo['name']+" Device</name><type>"+deviceType.toUpperCase()+" Device</type><filter><hp>0</hp><lp>"+Math.floor(sampleRate/2)+"</lp><comment></comment></filter></recordingdevice>";
            // List<Color> audioChannelColors = [ Color(0xFF10ff00), Color(0xFFff0035), Color(0xFFe1ff4b), Color(0xFFff8755), Color(0xFF6bf063),Color(0xFF00c0c9),];
            const startSubIdx = event.data.userAgent.indexOf("(")+1;
            const endSubIdx = event.data.userAgent.indexOf(")");
            const applicationTag = "<application><platform>web</platform><sysversion>"+event.data.userAgent.substring(startSubIdx,endSubIdx)+"</sysversion><appversion>"+event.data.versionNumber+"</appversion><details>"+event.data.userAgent+"</details></application>";

            // const applicationTag = "<application><platform>"+event.data.os+"</platform><sysversion>"+event.data.userAgent+"</sysversion><appversion>"+event.data.versionNumber+"</appversion></application>";
            const serialColors = ["#1ed400", "#FF0035", "#ffff00", "#20b4aa", "#dcdcdc", "#ff3800",];

            let strChannels = '';
            for (let i = 1; i <= vm.channelCount ; i++){
                if (flagChannelDisplays[i-1]==1){
                    console.log("channelColor---"+i);
                    console.log(vm.settingParams["color"+i]);
                    console.log(serialColors[vm.settingParams["color"+i]]);
                    const colorIndex = serialColors[vm.settingParams["color"+i]];
                    strChannels += '<channels><channel><name>Channel '+i+'</name><filter><hp>0</hp><lp>'+ Math.floor(sampleRate/2) +'</lp><notch></notch></filter><samplerate>'+sampleRate+'</samplerate><colorindex>'+colorIndex+'</colorindex> <digitalmin>-32768</digitalmin><digitalmax>32767</digitalmax> <physicalmin>100</physicalmin> <physicalmax>100</physicalmax> <physicaldimension>mV</physicaldimension> </channel></channels>';
                }
            }

            let recordingFiles = "<file><type>signal</type><version>"+strVersion+"</version> <path>signal.wav</path> <format>wav</format> <bytespersample>2</bytespersample> <samplerate>"+sampleRate+"</samplerate> <numchannels>"+sum+"</numchannels>"+strChannels+" </file> <file><type>events</type><version>" + strVersion + "</version> <path>signal-events.txt</path> </file> <file><type>spikes</type><version>" + strVersion + "</version> <path>signal-events.txt</path> </file>";

            let header = "<header><version>"+strVersion+"</version><recordingdate>"+recordingDate+"</recordingdate><recordingtime>"+recordingTime+"</recordingtime>"+
                         applicationTag +
                         "<subject><name></name><id></id><comment></comment></subject> " + recordingDevice + "<files>" + recordingFiles + "</files> </header>";
            console.log("HEADER ", header);
            zip.file("header.xml", header);

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
                clearBuffer(vm.sabcs1, vm.sabWriteState);

                //saveAs(content, "hello.zip");
            });


        break;
        case "sabcs":
            vm.rawSabcs = event.data.rawSabcs;
            vm.sabDraw = event.data.sabDraw;
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

const DEVICE_PRODUCT = {
    '1_11891' : { //Muscle SpikerBox Pro
      "deviceIdx" : 1,
      "maxSamplingRate" : 10000,
      "minChannels" : 2,
      "maxChannels" : 4,
      "channels" : [2,3,4],
      "sampleRates" : [10000,10000,5000,5000],
    },
    '2_11891' : { // Neuron SpikerBox Pro
      "deviceIdx" : 6,
      "maxSamplingRate" : 10000,
      "minChannels" : 2,
      "maxChannels" : 4,
      "channels" : [2,3,4],
      "sampleRates" : [10000,10000,5000,5000],
    },
    '24597_1027' : { // Heart & brain spiker box
      "deviceIdx" : 5,
      "maxSamplingRate" : 10000,
      "minChannels" : 1,
      "maxChannels" : 1,
      "channels" : [1],
      "sampleRates" : [10000],
      "baudRate" : 222222,
    },
    '32822_9025' : { // Plant SpikerBox
      "deviceIdx" : 2,
      "maxSamplingRate" : 10000,
      "minChannels" : 1,
      "maxChannels" : 1,
      "channels" : [1],
      "sampleRates" : [10000],
      "baudRate" : 222222,
    },
    // 67 : { // Human-Human-Interface 
    //   "maxSamplingRate" : 10000,
    //   "minChannels" : 1,
    //   "maxChannels" : 1,
    //   "channels" : [1],
    //   "sampleRates" : [10000],
    // },
    // '24597_1027' : { //Human-Human-Interface (second generation, under development)
    //   "maxSamplingRate" : 10000,
    //   "minChannels" : 1,
    //   "maxChannels" : 1,
    //   "channels" : [1],
    //   "sampleRates" : [10000],
    //   "baudRate" : 500000,
    // },
    //'67_10755'
    '67_1204' : { //Muscle SpikerShield
      "deviceIdx" : 4,
      "maxSamplingRate" : 10000,
      "minChannels" : 1,
      "maxChannels" : 6,
      "channels" : [1,2,3,4,5,6],
      "sampleRates" : [10000,5000,3333,2500,2000,1666],
      "baudRate" : 222222,    
    },
    '67_1240' : { //Muscle SpikerShield
      "deviceIdx" : 4,
      "maxSamplingRate" : 10000,
      "minChannels" : 1,
      "maxChannels" : 6,
      "channels" : [1,2,3,4,5,6],
      "sampleRates" : [10000,5000,3333,2500,2000,1666],
      "baudRate" : 222222,    
    },
    '67_1240' : { //Muscle SpikerShield
      "deviceIdx" : 4,
      "maxSamplingRate" : 10000,
      "minChannels" : 1,
      "maxChannels" : 6,
      "channels" : [1,2,3,4,5,6],
      "sampleRates" : [10000,5000,3333,2500,2000,1666],
      "baudRate" : 222222,    
    },
    '67_1659' : { //Muscle SpikerShield
      "deviceIdx" : 4,
      "maxSamplingRate" : 10000,
      "minChannels" : 1,
      "maxChannels" : 6,
      "channels" : [1,2,3,4,5,6],
      "sampleRates" : [10000,5000,3333,2500,2000,1666],
      "baudRate" : 222222,    
    },
    '67_17224' : { //Muscle SpikerShield
      "deviceIdx" : 4,
      "maxSamplingRate" : 10000,
      "minChannels" : 1,
      "maxChannels" : 6,
      "channels" : [1,2,3,4,5,6],
      "sampleRates" : [10000,5000,3333,2500,2000,1666],
      "baudRate" : 222222,    
    },
    '67_6790' : { //Muscle SpikerShield
      "deviceIdx" : 4,
      "maxSamplingRate" : 10000,
      "minChannels" : 1,
      "maxChannels" : 6,
      "channels" : [1,2,3,4,5,6],
      "sampleRates" : [10000,5000,3333,2500,2000,1666],
      "baudRate" : 222222,    
    },
    '67_1027' : { //Muscle SpikerShield
      "deviceIdx" : 4,
      "maxSamplingRate" : 10000,
      "minChannels" : 1,
      "maxChannels" : 6,
      "channels" : [1,2,3,4,5,6],
      "sampleRates" : [10000,5000,3333,2500,2000,1666],
      "baudRate" : 222222,    
    },
    '67_9114' : { //Muscle SpikerShield
      "deviceIdx" : 4,
      "maxSamplingRate" : 10000,
      "minChannels" : 1,
      "maxChannels" : 6,
      "channels" : [1,2,3,4,5,6],
      "sampleRates" : [10000,5000,3333,2500,2000,1666],
      "baudRate" : 222222,    
    },
    '67_6991' : { //Muscle SpikerShield
      "deviceIdx" : 4,
      "maxSamplingRate" : 10000,
      "minChannels" : 1,
      "maxChannels" : 6,
      "channels" : [1,2,3,4,5,6],
      "sampleRates" : [10000,5000,3333,2500,2000,1666],
      "baudRate" : 222222,    
    },
    '67_9025' : { //Muscle SpikerShield
      "deviceIdx" : 4,
      "maxSamplingRate" : 10000,
      "minChannels" : 1,
      "maxChannels" : 6,
      "channels" : [1,2,3,4,5,6],
      "sampleRates" : [10000,5000,3333,2500,2000,1666],
      "baudRate" : 222222,    
    },
  
    '67_10755' : { //Muscle SpikerShield
      "deviceIdx" : 4,
      "maxSamplingRate" : 10000,
      "minChannels" : 1,
      "maxChannels" : 6,
      "channels" : [1,2,3,4,5,6],
      "sampleRates" : [10000,5000,3333,2500,2000,1666],
      "baudRate" : 222222,    
    },
    '4_11891' : { //Human SpikerBox
      "deviceIdx" : 9,
      "maxSamplingRate" : 5000,
      "minChannels" : 2,
      "maxChannels" : 4,
      "channels" : [2,3,4],
      "sampleRates" : [5000, 5000,5000,5000],
      "baudRate" : 222222,
    },
  
  };