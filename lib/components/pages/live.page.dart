import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_videolive/components/widgets/LifeCycleWidget.dart';
import 'package:flutter_videolive/model/store/LiveStore.dart';
import 'package:flutter_videolive/model/store/live/enum/LiveStatus.dart';
import 'package:flutter_videolive/model/vo/RoomVO.dart';
import 'package:flutter_webrtc/rtc_video_view.dart';
import 'package:provider/provider.dart';

import 'live/live.client.widget.dart';
import 'live/live.master.widget.dart';

class LivePage extends StatelessWidget {

  final RoomVO roomVO;
  LivePage(this.roomVO);

  static const _textStyle_Message = TextStyle(color: Colors.red, fontSize: 13.0);
  static const _textStyle_UnexpectedError = TextStyle(color: Colors.red, fontSize: 24.0);
  static const _textStyle_Ready = TextStyle(color: Colors.green, fontSize: 24.0);

  @override
  Widget build(BuildContext ctx) {
    List<Widget> stackChildren = [];
    print('STACK CHILDREN: $stackChildren');
    return Consumer<LiveStore>(builder: (ct, LiveStore liveStore, _) {
      return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Observer(builder: (_) {
          return LiveJoinFloatingButton(liveStore.isMaster, () => _onBackPressed(_, liveStore));
        }),
        body: WillPopScope(
          onWillPop: () => _onBackPressed(ctx, liveStore),
          child: LifeCycleWidget(
            init: () async => await liveStore.initialize(roomVO),
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
      label: Text(isMaster ? 'Exit' : 'Leave'),
      onPressed: onPressed,
      icon: Icon(isMaster ? Icons.close : Icons.exit_to_app),
      backgroundColor: Colors.redAccent,
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final String message;
  final TextStyle textStyle;
  _StatusMessage(this.message, this.textStyle);
  @override Widget build(BuildContext context) {
    return ListTile(
        title: Align(alignment: Alignment.center,
          child: Text(message, style: textStyle)
        ),
    );
  }
}
