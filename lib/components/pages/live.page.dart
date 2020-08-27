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
        floatingActionButton: Observer(builder: (_) {
          return FloatingActionButton.extended(
            label: Text(liveStore.isMaster ? 'Stop' : 'Leave'),
            onPressed: () => _onBackPressed(_, liveStore),
            icon: Icon(liveStore.isMaster ? Icons.close : Icons.exit_to_app),
            backgroundColor: Colors.redAccent,
          );
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

//    return showDialog(
//      context: context,
//      builder: (context) => new AlertDialog(
//        title: new Text('Are you sure?'),
//        content: new Text('Do you want to exit an LiveStream'),
//        actions: <Widget>[
//          new GestureDetector(
//            onTap: () async {
//              Navigator.of(context).pop(false);
//            },
//            child: Text("NO"),
//          ),
//          SizedBox(height: 16),
//          new GestureDetector(
//            onTap: () async {
//              await liveStore.dispose(true);
//              Navigator.of(context).pop(true);
//            },
//            child: Text("YES"),
//          ),
//        ],
//      ),
//    ) ??
//        false;
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
