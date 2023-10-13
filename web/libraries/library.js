define(function(require, exports, module) {

    function multiply(a, b) {
        return a * b;
    }

    function generateArray(size, initialValue){
        var array = [];
        for (var i = 0; i < size ; ++i){
            var temp = [...array, initialValue];
            array = temp;
        }
        return array;
    }

    function envelopingSamples(_head, sample, _envelopes, SIZE_LOGS2, skipCounts) {

        for (var j = 0; j < SIZE_LOGS2; j++) {
            var skipCount = skipCounts[j];
            var envelopeSampleIndex = Math.floor(_head / skipCount);
            var interleavedSignalIdx = envelopeSampleIndex * 2;
            if (_head % skipCount == 0) {
            _envelopes[j][interleavedSignalIdx] = sample; //20967 * 2  =40k
            _envelopes[j][interleavedSignalIdx + 1] = sample;
            } else {
            if (sample < _envelopes[j][interleavedSignalIdx]) {
                _envelopes[j][interleavedSignalIdx] = sample;
            }
            if (sample > _envelopes[j][interleavedSignalIdx + 1]) {
                _envelopes[j][interleavedSignalIdx + 1] = sample;
            }
            }
        }
        // console.log("enveloping Samples");

    }


    function calculateLevel(timescale, sampleRate, innerWidth, arrCounts) {
        var rawPocket = timescale * sampleRate / innerWidth / 1000;
        var currentLevel = arrCounts.length - 1;
        var i = arrCounts.length - 2;
        if ((rawPocket).floor() < 4) {
            currentLevel = -1;
        } else {
            for (; i >= 0; i--) {
            if (arrCounts[i + 1] >= rawPocket && arrCounts[i] < rawPocket) {
                currentLevel = i + 1;
            }
            }
            if (currentLevel > arrCounts.length - 1) {
            currentLevel = arrCounts.length - 1;
            }
        }

        return currentLevel;
    }

    // SERIAL
    const SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER = 4096;
    const SIZE_OF_MESSAGES_BUFFER = 64;
    const ESCAPE_SEQUENCE_LENGTH = 6;
    const const_data = 4096;

    // int cBufHead = 0;
    // int cBufTail = 0;

    // bool weAreInsideEscapeSequence = false;
    // int escapeSequenceDetectorIndex = 0;
    // int messageBufferIndex = 0;

    var escapeSequence = [255, 255, 1, 1, 129, 255];

    // endOfescapeSequence[0] = 255;
    // endOfescapeSequence[1] = 255;
    // endOfescapeSequence[2] = 1;
    // endOfescapeSequence[3] = 1;
    // endOfescapeSequence[4] = 129;
    // endOfescapeSequence[5] = 255;

    function executeOneMessage(typeOfMessage, valueOfMessage, offsetin) {
    // if(typeOfMessage == "HWT")
    // {
    //     hardwareType = valueOfMessage;

    //     let found=hardwareType.indexOf("PLANTSS");
    //     if (found>-1)
    //     {
    //         // setDeviceTypeToCurrentPort(ArduinoSerial::plant);
    //     }
    //     else
    //     {
    //         found=hardwareType.indexOf("MUSCLESS");
    //         if (found>-1)
    //         {
    //             // setDeviceTypeToCurrentPort(ArduinoSerial::muscle);
    //         }
    //         else
    //         {
    //             found=hardwareType.indexOf("HEARTSS");
    //             if (found>-1)
    //             {
    //                 // setDeviceTypeToCurrentPort(ArduinoSerial::heart);
    //             }
    //             else
    //             {
    //                 found=hardwareType.indexOf("HBLEOSB");//leonardo heart and brain with one channel only
    //                 if (found>-1)
    //                 {
    //                     // setDeviceTypeToCurrentPort(ArduinoSerial::heartOneChannel);
    //                 }
    //                 else
    //                 {
    //                     found=hardwareType.indexOf("HBSBPRO");//leonardo heart and brain with one channel only
    //                     if (found>-1)
    //                     {
    //                         // setDeviceTypeToCurrentPort(ArduinoSerial::heartPro);
    //                     }
    //                     else
    //                     {
    //                         //NEURONSS
    //                         found=hardwareType.indexOf("NEURONSS");//neuron SpikerBox one channel
    //                         if (found>-1)
    //                         {
    //                             // setDeviceTypeToCurrentPort(ArduinoSerial::neuronOneChannel);
    //                         }
    //                         else
    //                         {
    //                             found=hardwareType.indexOf("MUSCUSB1");
    //                             if (found>-1)
    //                             {
    //                                 // setDeviceTypeToCurrentPort(ArduinoSerial::muscleusb);
    //                             }
    //                             else
    //                             {
    //                                 found=hardwareType.indexOf("HUMANSB");
    //                                 if (found>-1)
    //                                 {
    //                                     // setDeviceTypeToCurrentPort(ArduinoSerial::humansb);
    //                                     // _manager->checkIfFirmwareIsAvailableForBootloader();
    //                                 }
    //                                 else
    //                                 {
    //                                     found=hardwareType.indexOf("HHIBOX");
    //                                     if (found>-1)
    //                                     {
    //                                         // setDeviceTypeToCurrentPort(ArduinoSerial::hhibox);
    //                                     }

    //                                 }

    //                             }
    //                         }
    //                     }
    //                 }
    //             }
    //         }
    //     }
    // }

    // if(!_justScanning)
    // if(true)
    // {

    ////////////
    //   if(typeOfMessage == "EVNT")
    //   {
    //     // try{
    //       const mkey = valueOfMessage.codeUnitAt(0)-48;
    //       if (sabDraw){

    //           let ctr = drawState[DRAW_STATE.EVENT_COUNTER];
    //           eventsInt[ctr] = mkey;
    //           eventPositionInt[ctr] = _arrHeadsInt[0] + offsetin;

    //           eventGlobalPositionInt[ctr] = globalPositionCap[0] * SIZE + _arrHeadsInt[0];
    //           // eventsIdxInt[ctr] = drawState[DRAW_STATE.EVENT_NUMBER];
    //           eventsIdxInt[ctr] = mkey;

    //           ctr = (ctr + 1) % 200;
    //           eventsCounterInt[0] = ctr;
    //           drawState[DRAW_STATE.EVENT_NUMBER] = mkey;

    //           drawState[DRAW_STATE.EVENT_COUNTER] = ctr;
    //           drawState[DRAW_STATE.EVENT_POSITION] = _arrHeadsInt[0] + offsetin;
    //           console.log("_arrHeadsInt[0] : ", _arrHeadsInt[0]);

    //         // drawState[DRAW_STATE.EVENT_FLAG] = 1;
    //         // drawState[DRAW_STATE.EVENT_NUMBER] = mkey;
    //       }

    //     // }catch(err){
    //     //   console.log("evnt error");
    //     // }
    //   }//EVNT
    //   else

    //   if(typeOfMessage == "BRD")
    //   {
    //       clearBuffer();
    //       // console.log("EXPANSION BOARDD!!!");
    //       // Log::msg("Change board type on serial");
    //       // int newAddOnBoard = (int)((unsigned int)valueOfMessage[0]-48);
    //       const newAddOnBoard = valueOfMessage.charCodeAt(0)-48;
    //       // const newAddOnBoard = parseInt(valueOfMessage[0]) - 1;
    //       console.log("EXPANSION BOARDD!!! ", newAddOnBoard);
    //       if (newAddOnBoard == 0){

    //         drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
    //         drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //         drawState[DRAW_STATE.MAX_CHANNELS] = (new Uint8Array(SharedBuffers.maxChannels) )[0];

    //               // productId : new SharedArrayBuffer( 1 * Uint16Array.BYTES_PER_ELEMENT),
    //               // maxSampleRate : new SharedArrayBuffer( 1 * Uint16Array.BYTES_PER_ELEMENT),
    //               // minChannels : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT),
    //               // maxChannels : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT),
    //               // sampleRates : new SharedArrayBuffer( 6 * Uint16Array.BYTES_PER_ELEMENT),
    //               // channels : new SharedArrayBuffer( 6 * Uint8Array.BYTES_PER_ELEMENT),
    //         currentAddOnBoard = 0;
    //       }else
    //       if(newAddOnBoard == BOARD_WITH_ADDITIONAL_INPUTS)
    //       {
    //           if(currentAddOnBoard != BOARD_WITH_ADDITIONAL_INPUTS)
    //           {
    //             if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
    //               drawState[DRAW_STATE.CHANNEL_COUNTS] = 4;
    //               drawState[DRAW_STATE.MAX_CHANNELS] =4;
    //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 4;
    //               // clearBuffer();
    //             }else{
    //               drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
    //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //               // clearBuffer();

    //             }
    //             // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 4;

    //             currentAddOnBoard =newAddOnBoard;
    //             _shouldRestartDevice = true;

    //           }

    //       }
    //       else if(newAddOnBoard == BOARD_WITH_HAMMER)
    //       {
    //           if(currentAddOnBoard != BOARD_WITH_HAMMER)
    //           {
    //             console.log("HAMMER : ",drawState[DRAW_STATE.EXTRA_CHANNELS]);
    //             if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
    //               // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
    //               drawState[DRAW_STATE.CHANNEL_COUNTS] = 3;
    //               drawState[DRAW_STATE.MAX_CHANNELS] = 3;
    //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 3;
    //               // clearBuffer();
    //             }else{
    //               drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
    //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //               // clearBuffer();

    //             }

    //             // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;
    //             currentAddOnBoard =newAddOnBoard;
    //             _shouldRestartDevice = true;
    //           }
    //       }
    //       else if(newAddOnBoard == BOARD_WITH_JOYSTICK)
    //       {
    //           if(currentAddOnBoard != BOARD_WITH_JOYSTICK)
    //           {
    //             if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){

    //               // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
    //               drawState[DRAW_STATE.CHANNEL_COUNTS] = 3;
    //               drawState[DRAW_STATE.MAX_CHANNELS] = 3;
    //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 3;
    //               // clearBuffer();
    //             }else{
    //               drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
    //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //               // clearBuffer();
    //             }
    //             // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

    //             currentAddOnBoard =newAddOnBoard;
    //             _shouldRestartDevice = true;
    //           }
    //       }
    //       else if(newAddOnBoard == BOARD_WITH_EVENT_INPUTS)
    //       {
    //           if(currentAddOnBoard != BOARD_WITH_EVENT_INPUTS)
    //           {
    //             if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
    //               // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
    //               drawState[DRAW_STATE.CHANNEL_COUNTS] = 2;
    //               drawState[DRAW_STATE.MAX_CHANNELS] = 2;
    //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 2;
    //               // clearBuffer();
    //             }else{
    //               drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
    //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //               // clearBuffer();
    //             }
    //             // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

    //             currentAddOnBoard =newAddOnBoard;
    //             _shouldRestartDevice = true;

    //           }
    //       }
    //       else if(newAddOnBoard == BOARD_ERG)
    //       {
    //           if(currentAddOnBoard != BOARD_ERG)
    //           {
    //             if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
    //               // drawState[DRAW_STATE.SAMPLE_RATE] = 3000;
    //               drawState[DRAW_STATE.CHANNEL_COUNTS] = 3;
    //               drawState[DRAW_STATE.MAX_CHANNELS] = 3;
    //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 3;
    //               // clearBuffer();
    //             }else{
    //               drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
    //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //               // clearBuffer();
    //             }
    //             // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

    //             currentAddOnBoard =newAddOnBoard;
    //             _shouldRestartDevice = true;
    //           }
    //       }
    //       else
    //       {
    //           if(DRAW_STATE.CHANNEL_COUNTS != 2)
    //           {
    //             if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){

    //               // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
    //               drawState[DRAW_STATE.CHANNEL_COUNTS] = 2;
    //               drawState[DRAW_STATE.MAX_CHANNELS] = 2;
    //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 2;
    //               // clearBuffer();
    //             }else{
    //               drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
    //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //               // clearBuffer();
    //             }
    //             // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

    //             currentAddOnBoard =newAddOnBoard;
    //             _shouldRestartDevice = true;
    //           }
    //       }
    //       drawState[DRAW_STATE.SAMPLE_RATE] = drawState[DRAW_STATE.SAMPLING_RATE_1 + ( drawState[DRAW_STATE.CHANNEL_COUNTS] - 1) ];

    //   }//BRD
    ////////////

    // }
    }

    function executeContentOfMessageBuffer(offset, messagesBuffer) {
        var stillProcessing = true;
        var currentPositionInString = 0;
        //   let message = new Uint8Array(SIZE_OF_MESSAGES_BUFFER);
        var message = generateArray(SIZE_OF_MESSAGES_BUFFER,0);
        var endOfMessage = 0;
        var startOfMessage = 0;

        while (stillProcessing) {
            // if (messagesBuffer[currentPositionInString] == ';'.codeUnitAt(0)) {
            if (messagesBuffer[currentPositionInString] == 59) {
            for (var k = 0; k < endOfMessage - startOfMessage; k++) {
                // if (message[k] == ':'.codeUnitAt(0)) {
                if (message[k] == 58) {
                const str = String.fromCharCode(...message);
                //   var str = utf8.decode(message);
                var arrStr = str.split(':');
                var typeOfMessage = arrStr[0];
                var valueOfMessage = arrStr[1];
                var offsetMessage = offset;

                executeOneMessage(typeOfMessage, valueOfMessage, offsetMessage);
                break;
                }
            }
            startOfMessage = endOfMessage + 1;
            currentPositionInString++;
            endOfMessage++;
            } else {
            message[currentPositionInString - startOfMessage] =
                messagesBuffer[currentPositionInString];
            currentPositionInString++;
            endOfMessage++;
            }

            if (currentPositionInString >= SIZE_OF_MESSAGES_BUFFER) {
            stillProcessing = false;
            }
        }
    }

    function testEscapeSequence(
        newByte,
        offset,
        messagesBuffer,
        weAreInsideEscapeSequence,
        messageBufferIndex,
        escapeSequenceDetectorIndex,
        oBuffHead) {
        if (weAreInsideEscapeSequence) {
            if (messageBufferIndex >= SIZE_OF_MESSAGES_BUFFER) {
            weAreInsideEscapeSequence = false; //end of escape sequence
            executeContentOfMessageBuffer(offset, messagesBuffer);
            escapeSequenceDetectorIndex =
                0; //prepare for detecting begining of sequence
            } else if (escapeSequence[escapeSequenceDetectorIndex] == newByte) {
            escapeSequenceDetectorIndex++;
            if (escapeSequenceDetectorIndex == ESCAPE_SEQUENCE_LENGTH) {
                weAreInsideEscapeSequence = false; //end of escape sequence
                executeContentOfMessageBuffer(offset, messagesBuffer);
                escapeSequenceDetectorIndex =
                    0; //prepare for detecting begining of sequence
            }
            } else {
            escapeSequenceDetectorIndex = 0;
            }
        } else {
            if (escapeSequence[escapeSequenceDetectorIndex] == newByte) {
            escapeSequenceDetectorIndex++;
            if (escapeSequenceDetectorIndex == ESCAPE_SEQUENCE_LENGTH) {
                weAreInsideEscapeSequence = true; //found escape sequence
                for (var i = 0; i < SIZE_OF_MESSAGES_BUFFER; i++) {
                messagesBuffer[i] = 0;
                }
                messageBufferIndex = 0; //prepare for receiving message
                escapeSequenceDetectorIndex =
                    0; //prepare for detecting end of esc. sequence

                //rewind writing head and effectively delete escape sequence from data
                var cBufHead = 0;
                for (var i = 0; i < ESCAPE_SEQUENCE_LENGTH; i++) {
                cBufHead--;
                if (cBufHead < 0) {
                    cBufHead = const_data - 1;
                }
                }
                oBuffHead.value = cBufHead;
            }
            } else {
            escapeSequenceDetectorIndex = 0;
            }
        }
    }

    function frameHasAllBytes(_numberOfChannels, circularBuffer, cBufTail) {
        var tempTail = cBufTail + 1;
        if (tempTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER) {
            tempTail = 0;
        }
        for (var i = 0; i < (_numberOfChannels * 2 - 1); i++) {
            var nextByte = (circularBuffer[tempTail]) & 0xFF;
            if (nextByte > 127) {
            // Log::msg("HID frame with less bytes");
            return false;
            }
            tempTail++;
            if (tempTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER) {
            tempTail = 0;
            }
        }
        return true;
    }

    function checkIfHaveWholeFrame(circularBuffer, cBufTail, cBufHead) {
        var tempTail = cBufTail + 1;
        if (tempTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
        // if(tempTail>= CONFIG.ringBufferLength)
        {
            tempTail = 0;
        }
        while (tempTail != cBufHead) {
            var nextByte = (circularBuffer[tempTail]) & 0xFF;
            if (nextByte > 127) {
            return true;
            }
            tempTail++;
            if (tempTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
            // if(tempTail>= CONFIG.ringBufferLength)
            {
            tempTail = 0;
            }
        }
        return false;
    }

    function areWeAtTheEndOfFrame(circularBuffer, cBufTail) {
        var tempTail = cBufTail + 1;
        if (tempTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
        // if(tempTail>= CONFIG.ringBufferLength)
        {
            tempTail = 0;
        }
        // let nextByte  = ((uint)(circularBuffer[tempTail])) & 0xFF;
        var nextByte = (circularBuffer[tempTail]) & 0xFF;
        if (nextByte > 127) {
            return true;
        }
        return false;
    }
    
    return {
        "multiply": multiply,
        "envelopingSamples" : envelopingSamples,
        "calculateLevel" : calculateLevel,
        "executeOneMessage" : executeOneMessage,
        "executeContentOfMessageBuffer" : executeContentOfMessageBuffer,
        "testEscapeSequence" : testEscapeSequence,
        "frameHasAllBytes" : frameHasAllBytes,
        "checkIfHaveWholeFrame" : checkIfHaveWholeFrame,
        "areWeAtTheEndOfFrame" : areWeAtTheEndOfFrame,
    };
});