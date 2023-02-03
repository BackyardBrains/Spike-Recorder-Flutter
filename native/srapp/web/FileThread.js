const NUMBER_OF_SEGMENTS = 60;
const SEGMENT_SIZE = 44100;
const SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;

let productId = '';
let deviceInfo;

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
  'IS_LOW_PASS_FILTER' : 51,
  'IS_HIGH_PASS_FILTER' : 52,
  'LOW_PASS_FILTER' : 53,
  'HIGH_PASS_FILTER' : 54,

};


const CONFIG = {
    bytesPerSample : Int16Array.bytesPerSample,
    ringBufferLength: 4096,
    kernelLength: 1024,
};

var wavBuffer;
var wavBufferWriteTailIdx = 0;
  

var vm = this;
importScripts("wavefile.js");    
importScripts("jszip.min.js");    
var wav = new wavefile.WaveFile();
var wavList = new wavefile.WaveFile();
var zip = new JSZip();

let fileTempArr = new Int16Array(1024 * 1024 * 20);
let counterHead = 0;

self.onmessage = async function( event ) {
    // console.log( event.data );    
    // WHEN RECORDED SETTING button gone

    async function postWriteData(sum, firstListChunkPos){
        let subArrList;
        subArrList = await createWavList(vm.channelCount,sum, vm.sampleRate, event.data, wavBuffer.length);
        // console.log("sum : ",sum, flagChannelDisplays, "channelColor1 : ",vm.color1, "channel count : ",vm.channelCount, "CurrentColor : ",vm.currentColor, wavList);
        await writable.write(subArrList);
        
        WAV_STATE.SUBCHUNK2_SIZE_INDEX = wavBuffer.length - (4);

        let temp2 = new Uint32Array(1);
        const Subchunk2Size = firstListChunkPos;
        temp2[0] = Subchunk2Size;
        await writable.write({ type: "write", position: WAV_STATE.SUBCHUNK2_SIZE_INDEX, data: temp2.buffer })

        let temp = new Uint32Array(1);
        let chunk_size_data = 36 + Subchunk2Size + subArrList.length;
        temp[0] = chunk_size_data;
        await writable.write({ type: "write", position: WAV_STATE.CHUNK_SIZE_INDEX, data: temp.buffer });

    }

    async function createHeader(channelCount){
        wav.fromScratch(channelCount, vm.sampleRate, '16', []);
        console.log("wav.byteRate", wav.byteRate);
        writable = await _fileHandle.createWritable();
        console.log("WRITABLE", writable, vm.channelCount);
        wavBuffer = wav.toBuffer();
        await writable.write(wavBuffer);
    }

    function createEventMarkers(){
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
            }

            console.log("adjusted position ",eventGlobalPositionInt[i],vm.startingHeader);    
        }
        return str;

    }

    async function processZip(buffers,str,sampleRate,deviceInfo){
        let flagChannelDisplays = new Uint32Array(vm.sabDraw.channelDisplays);

        zip.file("signal.wav", buffers);
        zip.file("signal-events.txt", 
            `# Marker IDs can be arbitrary strings.\r\n# Marker ID,	Time (in s)\r\n`+str);
            
            const strVersion = "1";
            const curDateTime = new Date();
            const recordingDate = curDateTime.getMonth()+"."+curDateTime.getDate()+"."+curDateTime.getFullYear();
            const recordingTime = curDateTime.getHours()+":"+curDateTime.getMinutes()+":"+curDateTime.getSeconds();
            // const recordingDevice = "<recordingdevice><name>Audio Device</name><type>Audio Device</type><filter><hp>0</hp><lp>"+Math.floor(sampleRate/2)+"</lp><comment></comment></filter></recordingdevice>";
            const recordingDevice = "<recordingdevice><name>"+deviceInfo['uniqueName']+" Device</name><type>"+vm.deviceType.toUpperCase()+" Device</type><filter><hp>0</hp><lp>"+Math.floor(sampleRate)+"</lp><comment></comment></filter></recordingdevice>";
            const applicationTag = "<application><platform>"+event.data.os+"</platform><sysversion>"+event.data.userAgent+"</sysversion><appversion>"+event.data.versionNumber+"</appversion></application>";
            // List<Color> audioChannelColors = [ Color(0xFF10ff00), Color(0xFFff0035), Color(0xFFe1ff4b), Color(0xFFff8755), Color(0xFF6bf063),Color(0xFF00c0c9),];
            let strChannels = '';
            if (vm.deviceType == 'audio'){
                const audioColors = ["#10FF00", "#FF0035", "#E1FF4B", "#FF8755", "#6BF063", "#00c0c9",];
                for (let i = 1; i <= vm.channelCount ; i++){
                    // const colorIndex = audioColors[vm["color"+i]];
                    if (flagChannelDisplays[i-1]==1){
                        // console.log("channelColor---"+i);
                        // console.log(vm.settingParams["color"+i]);
                        // console.log(serialColors[vm.settingParams["color"+i]]);
                        const colorIndex = audioColors[vm.settingParams["color"+i]];
                        strChannels += '<channels><channel><name>Channel '+i+'</name><filter><hp>0</hp><lp>'+ Math.floor(sampleRate/2) +'</lp><notch></notch></filter><samplerate>'+sampleRate+'</samplerate><colorindex>'+colorIndex+'</colorindex> <digitalmin>-32768</digitalmin><digitalmax>32767</digitalmax> <physicalmin>100</physicalmin> <physicalmax>100</physicalmax> <physicaldimension>mV</physicaldimension> </channel></channels>';
                    }

                    // strChannels += '<channels><channel><name>Channel '+i+'</name><filter><hp>0</hp><lp>'+ Math.floor(sampleRate/2) +'</lp><notch>0</notch></filter><samplerate>'+sampleRate+'</samplerate><colorindex>'+colorIndex+'</colorindex> <digitalmin>-32768</digitalmin><digitalmax>32767</digitalmax> <physicalmin>100</physicalmin> <physicalmax>100</physicalmax> <physicaldimension>dB</physicaldimension> </channel></channels>';
                }
            }else{
                const serialColors = ["#1ed400", "#FF0035", "#ffff00", "#20b4aa", "#dcdcdc", "#ff3800",];

                // let strChannels = '';
                for (let i = 1; i <= vm.channelCount ; i++){
                    if (flagChannelDisplays[i-1]==1){
                        // console.log("channelColor---"+i);
                        // console.log(vm.settingParams["color"+i]);
                        // console.log(serialColors[vm.settingParams["color"+i]]);
                        const colorIndex = serialColors[vm.settingParams["color"+i]];
                        strChannels += '<channels><channel><name>Channel '+i+'</name><filter><hp>0</hp><lp>'+ Math.floor(sampleRate/2) +'</lp><notch></notch></filter><samplerate>'+sampleRate+'</samplerate><colorindex>'+colorIndex+'</colorindex> <digitalmin>-32768</digitalmin><digitalmax>32767</digitalmax> <physicalmin>100</physicalmin> <physicalmax>100</physicalmax> <physicaldimension>mV</physicaldimension> </channel></channels>';
                    }
                }
                    
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
            console.log("Generate async : ",err);
        });

    }
    async function createWavList(channelCount, sum, sampleRate, data, startIdx){
        wavList.fromScratch(sum, sampleRate, '16', []);
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
                            console.log("FLAG CHANNEL DISPLAYS : ", flagChannelDisplays, i);
                            if (data.deviceType == 'audio'){
                                subchunk["value"] += ("AUDIO - "+ (i + 1) +";");
                            }else
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
                console.log("vm.deviceType : ", vm.deviceType);
                if (vm.deviceType == 'audio'){
                    subchunk["value"] = '7;';
                }else
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
        console.log("wavList.list : ", wavList.LIST );
        // console.log("subChunks result raw : ",JSON.stringify(wavList.toBuffer()) );
        // console.log("subChunks result : ", JSON.stringify(result) );
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
            // console.log("CONNECT");
            _fileHandle = event.data.fileHandle;
            vm.channelCount = event.data.channelCount;
            // console.log("vm.channelCount",vm.channelCount);
            vm.sampleRate = event.data.sampleRate;
            vm.settingParams = event.data;
            vm.sabWriteState = new Int32Array(event.data.sabWriteState);
            vm.color1 = event.data.color1;
            vm.color2 = event.data.color2;
            vm.currentColor = event.data.color1;
            vm.deviceType = event.data.deviceType;

            if (vm.deviceType == 'audio'){
                deviceInfo = {'name':'Audio'};
            }else{
                productId = event.data['productId'];
                deviceInfo = DEVICE_PRODUCT[productId];
            }
        

            let flagChannelDisplays = new Uint32Array(vm.sabDraw.channelDisplays);
            const sum = flagChannelDisplays.reduce((pre,curr)=>pre+curr,0);

            worker2port = event.ports[0];
            console.log("SUM, total channels : ", sum, flagChannelDisplays);

            await createHeader(sum);
            
            vm.sabcs1 = vm.rawSabcs[0];// we are still using 0 because it helds same data as it is parallel
            const eventGlobalHeaderInt = new Uint32Array(vm.sabcs1.eventGlobalHeader);
            vm.startingHeader = eventGlobalHeaderInt[0];
            
            let StatesFile1 = new Int32Array(vm.sabcs1.statesWrite);
            let myconfig = new Int32Array(vm.sabcs1.config);
            let currentDataInt = new Int16Array(vm.sabcs1.currentData);
            let currentDataLengthInt = new Uint32Array(vm.sabcs1.currentDataLength);

            // if (vm.channelCount == 1){
            if (sum == 1){

                myconfig[2] = 0 ;

                
                while (!isStopRecording && Atomics.wait(StatesFile1, STATE.REQUEST_WRITE_FILE, 0) === 'ok') {
                    await writable.write(currentDataInt.slice(0,currentDataLengthInt[0]).buffer);

                    vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT]+=currentDataLengthInt[0];

                    if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                        isStopRecording = true;                        
                        break;
                    }else
                    if (!isStopRecording){
                        Atomics.store(StatesFile1, STATE.REQUEST_WRITE_FILE, 0);
                    }

                }
                wavBufferWriteTailIdx = vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT];
                const firstListChunkPos = wavBufferWriteTailIdx * 1 * 16 / 8;
                console.log("vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT] : ", vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT]);

                let bufferOdd = wavBuffer.length + firstListChunkPos;
                if ( bufferOdd  % 2 == 1){
                    // console.log("BUFFER ODD : ",bufferOdd);
                    await writable.write('\0')
                    wavBufferWriteTailIdx++;
                }

                await postWriteData(sum, firstListChunkPos);

                await writable.close();

                const file = await _fileHandle.getFile();
                const buffers = new Uint8Array (await file.arrayBuffer());

                let str = createEventMarkers();

                processZip(buffers, str, vm.sampleRate,deviceInfo);
                // if (vm.deviceType == 'audio'){
                //     processZip(buffers, str, vm.sampleRate,{'name':'Audio'});
                // }else{
                // }


                        
            }else{
                console.log("CHANNEL IS 2 recording ", isStopRecording);
                vm.sabcs2 = vm.rawSabcs[1];// we are still using 0 because it helds same data as it is parallel
                
                let myconfig2 = new Int32Array(vm.sabcs2.config);
                let fileCombinedStatusInt = new Int32Array(vm.sabcs1.sharedFileContainerStatus); // same sab used between 2 SharedArrayBuffers

                myconfig[2] = 0 ;
                myconfig2[2] = 0 ;
                
                while (!isStopRecording && Atomics.wait(fileCombinedStatusInt, 9,0) === 'ok') {
                    const subarray = currentDataInt.slice(0,currentDataLengthInt[0]);
                    await writable.write(subarray.buffer);
                    vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT]+=(currentDataLengthInt[0]);
                    if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                        isStopRecording = true;
                        break;
                    }else
                    if (!isStopRecording){
                        fileCombinedStatusInt[0] = 0;
                        fileCombinedStatusInt[1] = 0;
                        currentDataLengthInt[1] = 0;
                        Atomics.store(fileCombinedStatusInt, 9, 0);
                        Atomics.store(StatesFile1, STATE.REQUEST_WRITE_FILE, 0);
                    }
                }

                console.log("stop recording2 ",channelCount, sum, isStopRecording, myconfig[4], myconfig2[4]);

                if (vm.sabWriteState[WRITE_STATE.IS_RECORDING] == 0){
                    wavBufferWriteTailIdx = vm.sabWriteState[WRITE_STATE.PROCESSED_COUNT];
                    const firstListChunkPos = wavBufferWriteTailIdx * 1 * 16 / 8;
                    console.log("wavBufferWriteTailIdx ", wavBufferWriteTailIdx);// 195584
                                    
                    let bufferOdd = wavBuffer.length + firstListChunkPos;
                    if ( bufferOdd  % 2 == 1){
                        console.log("BUFFER ODD : ",bufferOdd);
                        await writable.write('\0')
                        wavBufferWriteTailIdx++;
                    }
                    
    

                    await postWriteData(sum,firstListChunkPos);

                    await writable.close();

                    const file = await _fileHandle.getFile();
                    const buffers = new Uint8Array (await file.arrayBuffer());
    
                    let str = createEventMarkers();

                    processZip(buffers, str, vm.sampleRate,deviceInfo);
                    // async function processZip(buffers,str,sampleRate,deviceInfo){
                    // if (vm.deviceType == 'audio'){
                    //     processZip(buffers, str, vm.sampleRate,{'name':'Audio'});
                    // }else{
                    //     processZip(buffers, str, vm.sampleRate,deviceInfo);
                    // }

                }                
                myconfig2[2] = -1;
    
            }
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

function clearBuffer(sabcs,sabWriteState){
    sabWriteState[WRITE_STATE.PROCESSED_COUNT] = 0;
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