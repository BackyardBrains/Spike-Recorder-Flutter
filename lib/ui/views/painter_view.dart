import 'package:flutter/material.dart';
import 'package:micsound/core/models/waveform_data_model.dart';
import 'package:micsound/core/services/waveform_data_loader.dart';
import 'package:micsound/ui/widgets/app_bar.dart';
import 'package:micsound/ui/widgets/bottom_app_bar.dart';
import 'package:micsound/ui/widgets/painted_waveform.dart';

class PainterView extends StatelessWidget {
  // const PainterView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: sharedAppBar(context, "Waveform Painter", textColor: Colors.red, backgroundColor: Colors.blue),
      //
      bottomNavigationBar: sharedBottomAppBar(context),
      //
      body: Center(
        child: FutureBuilder<WaveformData>(
          future: loadWaveformData("oneshot.json"),
          builder: (context, AsyncSnapshot<WaveformData> snapshot) {
            if (snapshot.hasData) {
              return PaintedWaveform(key:GlobalKey(),sampleData: snapshot.data!);
            } else if (snapshot.hasError) {
              return Text("Error ${snapshot.error}", style: TextStyle(color: Colors.red));
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
