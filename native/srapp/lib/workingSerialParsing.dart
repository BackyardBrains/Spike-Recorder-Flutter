void serialBufferingEntryPoint(List<dynamic> values) {
  final iReceivePort = ReceivePort();
  SendPort sendPort = values[0];
  List<List<List<double>>> allEnvelopes = values[1];
  int surfaceSize = values[2];
  Uint8List circularBuffer = values[3];
  String deviceType = values[4];
  Uint8List messagesBuffer = Uint8List(SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER);

  int numberOfChannels = 1;

  int cBuffIdx = 0;
  int globalIdx = 0;
  int cBufHead = 0;
  int cBufTail = 0;

  bool weAreInsideEscapeSequence = false;
  int escapeSequenceDetectorIndex = 0;
  int messageBufferIndex = 0;

  List<int> escapeSequence = [255, 255, 1, 1, 129, 255];

  sendPort.send(iReceivePort.sendPort);
  // indexPort.send([cBuffHead,cbufTail]);

  iReceivePort.listen((Object? message) async {
    // List<dynamic> arr = message as List<dynamic>;
    // var samples = arr[1];
    List<int> samples = message as List<int>;
    // print(arr);
    // print("samples");
    // print(samples);

    int len = samples.length;
    int i = 0;
    for (i = 0; i < len; i++) {
      int sample = samples[i];

      if (weAreInsideEscapeSequence) {
        messagesBuffer[messageBufferIndex] = sample;
        messageBufferIndex++;
      } else {
        circularBuffer[cBufHead++] = sample;
        //uint debugMSB  = ((uint)(buffer[i])) & 0xFF;

        if (cBufHead >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
        // if(cBufHead>=CONFIG.ringBufferLength)
        {
          cBufHead = 0;
        }
      }

      Map<String, int> oBufHead = {"value": cBufHead};
      if (deviceType == "serial") {
        if (sample == 0) {
          if (lastWasZero == 1) {
            numberOfZeros++;
          }
          lastWasZero = 1;
        } else {
          lastWasZero = 0;
        }

        testEscapeSequence(
            sample & 0xFF,
            (((i - (numberOfZeros > 0 ? numberOfZeros + 1 : 0)) / 2) /
                    numberOfChannels -
                1),
            messagesBuffer,
            weAreInsideEscapeSequence,
            messageBufferIndex,
            escapeSequenceDetectorIndex,
            oBufHead);
        cBufHead = oBufHead["value"]!;
      } else {
        testEscapeSequence(
            sample,
            (((i) / 2) / numberOfChannels - 1).floor(),
            messagesBuffer,
            weAreInsideEscapeSequence,
            messageBufferIndex,
            escapeSequenceDetectorIndex,
            oBufHead);
        cBufHead = oBufHead["value"]!;
      }
    }    
    
    int LSB;
    int MSB;
    bool haveData = true;
    bool weAlreadyProcessedBeginingOfTheFrame;
    int numberOfParsedChannels;
    int sample;

    while (haveData) {
      MSB = (circularBuffer[cBufTail]) & 0xFF;
      bool additionalFlag = true;
      if (MSB > 127 && additionalFlag) //if we are at the begining of frame
      {
        weAlreadyProcessedBeginingOfTheFrame = false;
        numberOfParsedChannels = 0;
        if (checkIfHaveWholeFrame(circularBuffer, cBufTail, cBufHead)) {
          numberOfFrames++;
          int idxChannelLoop = 0;
          while (true) {
            if (deviceType != "hid") {
              // console.log("SERIAL ? ",deviceType);
              MSB = (circularBuffer[cBufTail]) & 0xFF;
              if (weAlreadyProcessedBeginingOfTheFrame && MSB > 127) {
                numberOfFrames--;
                break; //continue as if we have new frame
              }
            }

            MSB = (circularBuffer[cBufTail]) & 0x7F;
            weAlreadyProcessedBeginingOfTheFrame = true;

            cBufTail++;
            if (cBufTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER) {
              cBufTail = 0;
            }
            LSB = (circularBuffer[cBufTail]) & 0xFF;
            if (LSB > 127) {
              numberOfFrames--;
              if (deviceType == 'hid') {
                return;
              } else {
                break;
              }
            }
            LSB = (circularBuffer[cBufTail]) & 0x7F;

            MSB = MSB << 7;
            writeInteger = LSB | MSB;

            numberOfParsedChannels++;

            if (deviceType == 'hid') {
              if (numberOfParsedChannels > numberOfChannels) {
                break;
              }
            } else if (numberOfParsedChannels > numberOfChannels) {
              //std::cout<< "More channels than expected\n";
              // break;//continue as if we have new frame
              // return;//continue as if we have new frame
            }

            if (deviceType == 'hid') {
              sample = -((writeInteger - 512));
            } else {
              // if (deviceIds[0] == 4){
              //   sample =  (-(writeInteger - 8192)); // SpikeDesktop 448
              // }else{
              sample = -((writeInteger - 512)); // SpikeDesktop 448
              // }

            }
            //
            // put function postProcessing or additionalProcessing();
            // communicate with other isolate and send this sample to another receiverport

            // if (MyConfig[2] != -1){
            //   if (numberOfParsedChannels == 1 && !isStartRecording){
            //     isStartRecording = true
            //     console.log("Start Recording : ", -sample, currentIdxEnd, numberOfParsedChannels);
            //   }
            //   if (isStartRecording){
            //     if (flagChannelDisplays[numberOfParsedChannels-1] == 1){
            //       currentTempInt[currentIdxEnd++] = -sample;
            //     }else{
            //     }
            //   }
            // }else{
            //   isStartRecording = false;
            // }

            // arrMaxInt = allArrMaxInt[numberOfParsedChannels - 1];
            // envelopes = allEnvelopes[numberOfParsedChannels - 1];
            // _head = _arrHeadsInt[numberOfParsedChannels - 1];
            // envelopingSamples(_head, sample, envelopes);
            // print(sample.toDouble());
            envelopingSamples(cBuffIdx, sample.toDouble(), allEnvelopes[0],
                SIZE_LOGS2, skipCounts);
            cBuffIdx++;
            if (cBuffIdx == surfaceSize - 1) {
              cBuffIdx = 0;
              // _arrIsFullInt[numberOfParsedChannels-1]++;
              if (numberOfParsedChannels == 1) {
                // globalPositionCap[0]++;
                globalIdx++;
              }

              // isFull = true;
            }

            // const interleavedHeadSignalIdx = _head * 2;
            // arrMaxInt[interleavedHeadSignalIdx] = sample;
            // arrMaxInt[interleavedHeadSignalIdx + 1] = sample;

            // _head++;
            // if (_head == SIZE){
            //   _head = 0;
            //   _arrIsFullInt[numberOfParsedChannels-1]++;
            //   if (numberOfParsedChannels == 1) {
            //     globalPositionCap[0]++;
            //   }

            //   isFull = true;
            // }

            // _arrHeadsInt[numberOfParsedChannels-1] = _head;
            // if (numberOfParsedChannels == 1){
            //   if (drawState){
            //     if (drawState[DRAW_STATE.EVENT_FLAG] == 1){
            //       drawState[DRAW_STATE.EVENT_POSITION] = _arrHeadsInt[0];

            //       let ctr = drawState[DRAW_STATE.EVENT_COUNTER];
            //       eventsInt[ctr] = drawState[DRAW_STATE.EVENT_NUMBER];
            //       eventPositionInt[ctr] = _arrHeadsInt[0];
            //       eventGlobalPositionInt[ctr] = globalPositionCap[0] * SIZE + _head;
            //       eventsIdxInt[ctr] = drawState[DRAW_STATE.EVENT_NUMBER];
            //       ctr++;
            //       if ( ctr >= MAX_EVENT_MARKERS){
            //         ctr=ctr % MAX_EVENT_MARKERS;
            //         eventsCounterInt.fill(0);
            //         eventsInt.fill(0);
            //         eventPositionInt.fill(0);
            //         eventsPositionResultInt.fill(0);
            //       }
            //       eventsCounterInt[0]=ctr;

            //       drawState[DRAW_STATE.EVENT_COUNTER] = ctr;
            //       console.log("eventsCounter : ", ctr, "head : ", _head);
            //       console.log("Position : ", eventPositionInt);
            //       console.log("Result : ", eventPositionResultInt);

            //       drawState[DRAW_STATE.EVENT_FLAG] = 0;
            //     }
            //   }
            // }

            if (areWeAtTheEndOfFrame(circularBuffer, cBufTail)) {
              break;
            } else {
              cBufTail++;
              if (cBufTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER) {
                cBufTail = 0;
              }
            }
          }
        } else {
          haveData = false;
          // console.log("have data false");
          break;
        }
      }
      if (!haveData) {
        break;
      }
      cBufTail++;
      if (cBufTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER) {
        cBufTail = 0;
      }

      if (cBufTail == cBufHead) {
        haveData = false;
        break;
      }
    }
    
    
    


    // // filter
    // print("level");
    // print(level);
    List<double> envelopeSamples = allEnvelopes[0][6];
    // List<double> envelopeSamples = [];
    int prevSegment = (envelopeSamples.length / divider).floor();
    List<double> cBuff = List<double>.generate(prevSegment, (i) => 0);

    int skipCount = skipCounts[level];
    int head = (cBuffIdx / skipCount).floor();
    int interleavedIdx = head * 2;
    int start = interleavedIdx - prevSegment;
    int to = interleavedIdx;

    if (globalIdx == 0) {
      if (to - prevSegment < 0) {
        List<double> arr = allEnvelopes[0][level].sublist(0, to);
        // print(arr);
        cBuff.setAll(prevSegment - arr.length, arr);
      } else {
        start = to - prevSegment;
        List<double> arr = allEnvelopes[0][level].sublist(start, to);
        cBuff.setAll(prevSegment - arr.length, arr);
      }
      // print(prevSegment - arr.length);
    } else {
      if (start < 0) {
        // it is divided into 2 sections
        int processedHead = head * 2;
        int segmentCount = prevSegment;
        int bufferLength = prevSegment;

        segmentCount = segmentCount - processedHead - 1;
        start = envelopeSamples.length - segmentCount;
        List<double> firstPartOfData = envelopeSamples.sublist(start);
        List<double> secondPartOfData =
            envelopeSamples.sublist(0, processedHead + 1);
        if (secondPartOfData.length > 0) {
          try {
            cBuff.setAll(0, firstPartOfData);
            cBuff.setAll(firstPartOfData.length, secondPartOfData);
          } catch (err) {}
        } else {
          cBuff.setAll(
              bufferLength - firstPartOfData.length - 1, firstPartOfData);
        }
      } else {
        // print("start > 0");
        cBuff = List<double>.from(allEnvelopes[0][level].sublist(start, to));
      }
    }

    sendPort.send(cBuff);
    // sendPort.send({
    //   "cBuffIdx": cBuffIdx,
    //   "cBufHead": cBufHead,
    //   "cBufTail": cBufTail,
    //   "data": cBuff,
    //   "globalIdx": globalIdx
    // });
    // sendPort.send([
    //   cBuffIdx,
    //   cBufHead,
    //   cBufTail,
    //   cBuff,
    //   globalIdx,
    // ]);
    // List<double> data =
    //     List.generate(samples.length, (index) => index.toDouble());
    // sendPort.send(samples);
  });
}
