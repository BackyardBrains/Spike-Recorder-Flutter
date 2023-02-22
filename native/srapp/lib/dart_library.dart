import 'dart:typed_data';

unitInitializeEnvelope(int totalChannel, List<List<Int16List>> allEnvelopes,
    List<int> envelopeSizes, double _size, int SIZE, int SIZE_LOGS2) {
  // size = size * 2;
  for (int c = 0; c < totalChannel; c++) {
    List<Int16List> envelopes = [];
    double size = _size;
    for (int i = 0; i < SIZE_LOGS2; i++) {
      int sz = (size).ceil();
      if (sz % 2 == 1) sz++;
      envelopeSizes.add(sz);
      // List<double> buffer = List.generate(sz, (index) => 0);
      Int16List buffer = Int16List(sz);

      envelopes.add(buffer);
      // print("index : " + i.toString());
      // print(size.ceil());
      // print(envelopes[i].length);
      size /= 2;
    }
    print("envelopeSizes");
    print(envelopeSizes);
    allEnvelopes.add(envelopes);
  }
}

asciiToUint8Array(str) {
  // console.log("ASCII",str);
  List<int> chars = [];
  for (var i = 0; i < str.length; ++i) {
    chars.add(str.codeUnitAt(i)); /*from  w  ww. j  a  v  a  2s.c o  m*/
  }
  // return new Uint8Array(chars);
  return Uint8List.fromList(chars);
}

differentInScreenPosition(posX, part, level, skipCounts, int envelopeSize,
    int cBuffIdx, double divider, int innerWidth) {
  int head = (cBuffIdx);
  int prevSegment = (envelopeSize / divider).floor();

  double samplesPerPixel = prevSegment / innerWidth;
  int division = 2;
  if (level == 0) {
    division = 1;
  }
  int elementLength =
      ((innerWidth - posX) * samplesPerPixel / division * skipCounts).floor();

  int curStart = head - (elementLength).floor();

  return curStart;
}

screenPositionToElementPosition(posX, part, level, skipCount,
    double envelopeSize, int cBuffIdx, double divider, double innerWidth) {
  int head = cBuffIdx;
  int prevSegment = (envelopeSize / divider).floor();

  double samplesPerPixel = prevSegment / innerWidth;
  int division = 2;
  // if (level == 0) {
  //   division = 1;
  // }
  int elementLength =
      ((innerWidth - posX) * samplesPerPixel / division * skipCount).floor();

  int curStart = head - (elementLength).floor();
  // print("INNER WIDTH : " + innerWidth.toString() + " POS X  : "+ posX.toString() + " prev Segment : " + prevSegment.toString()+" LEVEL : " + level.toString() + " DIVIDER " + divider.toString() + " Samples per pixel : " + samplesPerPixel.toString() + "Skip Counts : " + skipCount.toString()+ "Element Length "+ elementLength.toString()+ "cur Start : "+ curStart.toString()+ "head : "+ head.toString()+ "Envelope Size : " + envelopeSize.toString());
  print(" POS X  : " +
      posX.toString() +
      " prev Segment : " +
      prevSegment.toString() +
      " LEVEL : " +
      level.toString() +
      " DIVIDER " +
      divider.toString() +
      " Samples per pixel : " +
      samplesPerPixel.toString() +
      "Skip Counts : " +
      skipCount.toString() +
      "Element Length " +
      elementLength.toString() +
      "cur Start : " +
      curStart.toString() +
      "head : " +
      head.toString() +
      "Envelope Size : " +
      envelopeSize.toString());
  if (curStart < 0) {
    curStart = 0;
  }
  return curStart;
}

getVisibleSamples(samples, i, len, int maxOsChannel) {
  List<int> visibleSamples = [];
  for (int j = i * 2; j < len; j += 2 * maxOsChannel) {
    // print("j : "+j.toString());
    // print("i : " +
    //     i.toString() +
    //     " j : " +
    //     j.toString() +
    //     " first : " +
    //     first.toString());
    var arrSubPart = samples.sublist(j, j + 2);
    // print("byteArray");
    // print(arrSubPart.length);
    bool first = true;
    int tmp = 0;
    Uint8List byteArray = Uint8List(2);

    for (int k = 0; k < arrSubPart.length; k++) {
      int sample = arrSubPart[k];
      if (first) {
        byteArray[0] = sample;
      } else {
        byteArray[1] = sample;

        ByteData byteData = ByteData.view(byteArray.buffer);
        tmp = (byteData.getInt16(0, Endian.little));
        visibleSamples.add(tmp);

        tmp = 0;
      }
      first = !first;
    }
  }
  return visibleSamples;
}

getAllChannelsSample(samples, int maxOsChannel) {
  List<List<int>> arrVisibleSamples = [];
  for (int i = 0; i < maxOsChannel; i++) {
    final len = samples.length;
    // tempBuffIdx = cBuffIdx;
    List<int> visibleSamples =
        getVisibleSamples(samples, i, len, maxOsChannel);

    // for (int sample in samples) {

    // if (i == 0) {
    //   print("visibleSamples");
    //   print(visibleSamples);
    // }
    arrVisibleSamples.add(List<int>.from(visibleSamples));
  }
  return arrVisibleSamples;
}
