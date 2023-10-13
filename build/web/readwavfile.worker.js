var worker2port;
var workerForwardPort;

var wavFileHandle;
var deviceType;
// importScripts("wavefileparser.js");
// console.log(wavefileParser);
// let wav = new wavefileParser.WaveFileParser();
importScripts("wavefile.js");    
importScripts("jszip.min.js");    

var wav = new wavefile.WaveFile();
var zip = new JSZip();

self.onmessage = async function( event ) {
    switch( event.data.command )
    {
        case "connect":
            worker2port = event.ports[0];   
        break;
        case "setConfig":
            wavFileHandle = event.data.wavFileHandle;
            deviceType = event.data.deviceType;
            workerForwardPort = event.ports[0];   

            const file = await wavFileHandle.getFile();
            const buffers = new Uint8Array (await file.arrayBuffer());
            console.log(buffers);
            await zip.loadAsync(buffers);
            const markerBuffers = await zip.file("signal-events.txt").async("text");
            const wavBuffers = await zip.file("signal.wav").async("uint8array");

            // zip.file("signal-events.txt","Hi, I am updating your data 2");
            // wav.fromScratch(2, 44100, '16', []);

            // console.log(wav.toBuffer());

            
            let arrMarkers = markerBuffers.split("\r\n");
            arrMarkers = arrMarkers.slice( 2, arrMarkers.length - 1 );
            console.log("arrMarkers : ",arrMarkers, markerBuffers , );

            wav.fromBuffer(wavBuffers,true);
            const audioLength = Math.ceil(wav.data.samples.length / wav.fmt.sampleRate / wav.fmt.numChannels);
            console.log("wav.buffer : ", wav );
            console.log("wav.LIST : ", JSON.stringify(wav.LIST) );
            // wav.LIST :  [{"chunkId":"LIST","chunkSize":114,"format":"INFO","subChunks":[{"chunkId":"cpos","chunkSize":5,"value":"1;2;"},{"chunkId":"ctrs","chunkSize":5,"value":"0;0;"},{"chunkId":"cgin","chunkSize":5,"value":"1;1;"},{"chunkId":"cclr","chunkSize":5,"value":"0;1;"},{"chunkId":"ctms","chunkSize":3,"value":"0;"},{"chunkId":"cnam","chunkSize":21,"value":"AUDIO - 1;AUDIO - 2;"},{"chunkId":"cdev","chunkSize":3,"value":"1;"}]}]
            // 4 252502 x 856222
            // 44 252024 x 856064


            let mapWav = [
                wav.fmt.numChannels,
                wav.fmt.sampleRate,
                Math.ceil(wav.fmt.bitsPerSample),
                audioLength,
                wav.LIST[0] === undefined ? [] : wav.LIST[0].subChunks[3].value,//clr
                wav.LIST[0] === undefined ? [] : wav.LIST[0].subChunks[5].value,//cnam
                arrMarkers,//markers
                0, // min channels
                0, // max channels
                0,
            ];   
            if (deviceType == 'audio') {
                mapWav[7] = 1;
                mapWav[8] = wav.fmt.numChannels;
            }else{
                mapWav[7] = 1;
                mapWav[8] = wav.fmt.numChannels;
            }
            console.log(mapWav);
            // const segmentSize = wav.data.samples.length / wav.fmt.numChannels;
            
            
            const rawChannelData = wav.data.samples;
            const bufferSize = Math.floor(rawChannelData.length / Int16Array.BYTES_PER_ELEMENT);
            let channelSamples = [];
            for (let i = 0; i<wav.fmt.numChannels;i++){
                const sampleLength = Math.floor( bufferSize / wav.fmt.numChannels);
                let channelSample = new Int16Array( sampleLength );
                channelSamples.push(channelSample);
            }

            for (let j = 0; j < bufferSize ; j++){
                
                // per channel
                // for (let i = 0; i<wav.fmt.numChannels;i++){
                    const div = Math.floor( j / wav.fmt.numChannels );
                    const mod = (j) % wav.fmt.numChannels;
                    const subBuffer = rawChannelData.slice(j*Int16Array.BYTES_PER_ELEMENT, (j+1) * Int16Array.BYTES_PER_ELEMENT);
                    // console.log("subBuffer : ",subBuffer);
                    channelSamples[mod][div]= new DataView(subBuffer.buffer).getInt16(0, true);
                // }
            }
            for (let i = 0; i<wav.fmt.numChannels;i++){
                mapWav.push( channelSamples[i] );
            }
            console.log("Wav Samples : ",channelSamples);
        
            // const strWav = JSON.stringify(wav);
            // workerForwardPort.postMessage( strWav );
            try{
                console.log("trying to update data");
                // let writable = await wavFileHandle.createWritable();
                // console.log("trying to update data2 ", writable);

                // await zip.generateAsync({
                //     type: 'uint8array',
                //     compression : 'store',
                //     mimeType: 'application/zip',
                // }).then( async function (content) {
                //     // see FileSaver.js
                //     console.log("write possible")
                //     // console.log("content : ",content);
                //     await writable.write(content);
                //     await writable.close();
    
                //     //saveAs(content, "hello.zip");
                // }).catch(function (err){
                //     console.log("write NOT possible", err)
                // });
    
            }catch(err){
                console.log("ERR OPEN : ",err);
            }
            
            workerForwardPort.postMessage( mapWav, );

            // var reader = new FileReader();
            // reader.onload = function(){
            //     const buffers = reader.result;

            //     wav.fromBuffer(buffers);
                
            //     const strWav = JSON.stringify(wav);
            //     worker2port.postMessage( strWav );
    
            // };

            // reader.readAsArrayBuffer(file);


            

        break;

       

        default:
            console.log( event.data );
    }
};