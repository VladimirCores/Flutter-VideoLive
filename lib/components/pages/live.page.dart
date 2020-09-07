import 'package:flutter/material.dart';
import 'package:flutter_videolive/components/widgets/LifeCycleWidget.dart';
import 'package:flutter_videolive/model/store/LiveStore.dart';
import 'package:flutter_videolive/model/vo/RoomVO.dart';
import 'package:provider/provider.dart';

import 'live/live.client.widget.dart';
import 'live/live.master.widget.dart';

class LivePage extends StatelessWidget {

  final RoomVO roomVO;
  LivePage(this.roomVO);

  @override
  Widget build(BuildContext ctx) {
    Size viewportSize = MediaQuery.of(ctx).size;
    return Consumer<LiveStore>(builder: (ct, LiveStore liveStore, _) {
      return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: LiveJoinFloatingButton(liveStore.isMaster, () => _onBackPressed(_, liveStore)),
        body: WillPopScope(
          onWillPop: () => _onBackPressed(ctx, liveStore),
          child: LifeCycleWidget(
            init: () async => await liveStore.initialize(roomVO, viewportSize),
            dispose: () async => liveStore.dispose(true),
            builder: (dct, ss) => (
              liveStore.isMaster
              ? LiveMaster()
              : LiveClient()
            )
          ),
        )
      );
    });
  }

  Future<bool> _onBackPressed(context, LiveStore liveStore) async {
    await liveStore.dispose(true);
    Navigator.of(context).pop(true);
    return Future.value(true);
  }
}

class LiveRecordingFloatingButton extends StatelessWidget {
  final bool isLive;
  final Function onPressed;
  LiveRecordingFloatingButton(this.isLive, this.onPressed);
  @override Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      label: Text(isLive ? 'Stop Recording' : 'Start Recording'),
      onPressed: onPressed,
      icon: Icon(isLive ? Icons.fiber_manual_record : Icons.save),
      backgroundColor: isLive ? Colors.redAccent : Colors.green,
    );
  }
}

class LiveJoinFloatingButton extends StatelessWidget {
  final bool isMaster;
  final Function onPressed;
  LiveJoinFloatingButton(this.isMaster, this.onPressed);
  @override Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      elevation: 0.0,
      label: Text(isMaster ? 'Close' : 'Leave',
        style: TextStyle(color: Colors.red),),
      onPressed: onPressed,
      icon: Icon(isMaster ? Icons.close : Icons.exit_to_app,
        color: Colors.red,),
      backgroundColor: Colors.white.withOpacity(0.12),
    );
  }
}
