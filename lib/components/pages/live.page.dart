import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_videolive/components/widgets/LifeCycleWidget.dart';
import 'package:flutter_videolive/model/store/LiveStore.dart';
import 'package:flutter_videolive/model/store/live/enum/LiveStatus.dart';
import 'package:flutter_videolive/model/vo/RoomVO.dart';
import 'package:flutter_webrtc/rtc_video_view.dart';
import 'package:provider/provider.dart';

List<Widget> _statusChildren;
Widget _videoWidget;
Widget _spinnerWidget;

class LivePage extends StatelessWidget {

  final RoomVO roomVO;
  LivePage(this.roomVO) {
    _statusChildren = <Widget>[];
    _spinnerWidget = null;
    _videoWidget = null;
  }

  static const _textStyle_Message = TextStyle(color: Colors.red, fontSize: 13.0);
  static const _textStyle_UnexpectedError = TextStyle(color: Colors.red, fontSize: 24.0);
  static const _textStyle_Ready = TextStyle(color: Colors.green, fontSize: 24.0);

  @override
  Widget build(BuildContext ctx) {
    List<Widget> stackChildren = [];
    final screenWidth = MediaQuery.of(ctx).size.width;
    final screenHeight = MediaQuery.of(ctx).size.height;
    print('STACK CHILDREN: $stackChildren');
    return Scaffold(
    body: Container(
      width: screenWidth,
      height: screenHeight,
      color: Colors.black26,
      alignment: Alignment.topLeft,
      child: Consumer<LiveStore>(builder: (ct, LiveStore liveStore, _) {
        return WillPopScope(
          onWillPop: () => _onBackPressed(ctx, liveStore),
          child: LifeCycleWidget(
//            reassemble: () => liveStore.dispose(true),
            init: () => liveStore.initialize(roomVO),
            dispose: () async => liveStore.dispose(true),
            builder: (dct, ss) => Observer(builder: (ost) {
              print('< LivePage: LiveStatus = ${liveStore.roomStatus}');
              final roomStatus = liveStore.roomStatus;
              if (
                  roomStatus == LiveStatus.MASTER_PEER_FOR_CLIENT_CREATED
              )
              {
                _statusChildren.clear();
              }
              _statusChildren.add(_StatusMessage(roomStatus.toString(), _textStyle_Message));
              // checkStatus(roomStatus);

              print('liveStore.hasMediaStream: ${liveStore.hasMedia}');
              if (liveStore.hasMedia)
              {
                var mediaRenderer = liveStore.mediaRenderer;
                print('> mediaRenderer.rotation: ${mediaRenderer.rotation}');
                stackChildren.add(
                  Container(width: screenWidth, height: screenHeight,
                      child: RTCVideoView(mediaRenderer)),
                );
              }

              if (_spinnerWidget != null) stackChildren.add(_spinnerWidget);
              stackChildren.add(ListView(children:_statusChildren));

              print('videoWidget: $_videoWidget');
              print('statusChildren: $_statusChildren');

              return Stack(children: stackChildren);
              },
            ),
          ),
        );
      })
    ),
  );}

  Future<bool> _onBackPressed(context, liveStore) {
    liveStore.dispose(true);
    return Future.value(true);
//
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
