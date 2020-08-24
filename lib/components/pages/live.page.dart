import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_videolive/components/widgets/LifeCycleWidget.dart';
import 'package:flutter_videolive/model/store/LiveStore.dart';
import 'package:flutter_videolive/model/store/live/enum/LiveStatus.dart';
import 'package:flutter_videolive/model/vo/RoomVO.dart';
import 'package:flutter_webrtc/rtc_video_view.dart';
import 'package:provider/provider.dart';

List<Widget> statusChildren;
Widget videoWidget;
Widget spinnerWidget;

class LivePage extends StatelessWidget {

  final RoomVO roomVO;
  LivePage(this.roomVO) {
    statusChildren = <Widget>[];
    spinnerWidget = null;
    videoWidget = null;
  }

  static const _textStyle_Message = TextStyle(color: Colors.white70, fontSize: 15.0);
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
        return LifeCycleWidget(
          init: () => liveStore.initialize(roomVO),
          dispose: () async => liveStore.dispose(true),
          builder: (dct, ss) => Observer(builder: (ost) {
            print('< LivePage: LiveStatus = ${liveStore.roomStatus}');
            final roomStatus = liveStore.roomStatus;
            switch(roomStatus) {
              case LiveStatus.CLOSED:
              case LiveStatus.INITIAL:
                statusChildren.add(Divider());
                break;
              case LiveStatus.ALREADY_CONNECTED:
                statusChildren.add(_StatusMessage("Already Connected", _textStyle_Message));
                break;
              case LiveStatus.PREPARE:
                  spinnerWidget = LinearProgressIndicator();
                  statusChildren.add(_StatusMessage("Prepare Room", _textStyle_Message));
                break;
              case LiveStatus.RENDERER_READY:
                statusChildren.add(_StatusMessage("Renderer Ready", _textStyle_Message));
                break;
              case LiveStatus.MASTER_REGISTER_ROOM:
                statusChildren.add(_StatusMessage("Room Owner", _textStyle_Message));
                break;
              case LiveStatus.MASTER_CAMERA_READY:
                statusChildren.add(_StatusMessage("Camera Ready", _textStyle_Message));
                break;
              case LiveStatus.ROOM_SET:
                spinnerWidget = null;
                statusChildren.add(_StatusMessage("Room Exists", _textStyle_Message));
                break;
              case LiveStatus.CLIENT_PEER_CREATED:
                statusChildren.add(_StatusMessage("Peer Created", _textStyle_Message));
                break;
              case LiveStatus.CLIENT_PEER_REGISTERED:
                statusChildren.add(_StatusMessage("Peer Registered", _textStyle_Message));
                break;
              case LiveStatus.CLIENT_OFFER_RECEIVED:
                statusChildren.add(_StatusMessage("Offer Received", _textStyle_Message));
                break;
              case LiveStatus.REMOTE_DESCRIPTION_SET:
                statusChildren.add(_StatusMessage("Remote Description Set", _textStyle_Message));
                break;
              case LiveStatus.LOCAL_DESCRIPTION_SET:
                statusChildren.add(_StatusMessage("Local Description Set", _textStyle_Message));
                break;
              case LiveStatus.CLIENT_ANSWER_POSTED:
                statusChildren.add(_StatusMessage("Answer Posted", _textStyle_Message));
                break;
              case LiveStatus.MEDIA_ARRIVED:
                statusChildren.add(_StatusMessage("Media Arrived", _textStyle_Ready));
                break;
              case LiveStatus.MASTER_MEDIA_ATTACHED_TO_PEER:
                statusChildren.add(_StatusMessage("Media Set", _textStyle_Ready));
                break;
              case LiveStatus.ICE_FAILED:
                Navigator.pop(dct);
                statusChildren.add(_StatusMessage("ICE FAILED", _textStyle_Message));
                break;
              case LiveStatus.ICE_CONNECTED:
                spinnerWidget = null;
                statusChildren.add(_StatusMessage("ICE CONNECTED", _textStyle_Message));
                break;
              case LiveStatus.DISPOSED:
                statusChildren.add(_StatusMessage("Disposed", _textStyle_Message));
                break;
              case LiveStatus.CLIENT_ROOM_NOT_EXISTS:
                statusChildren.add(_StatusMessage("Client Room Not Exists", _textStyle_UnexpectedError));
                break;
              case LiveStatus.MASTER_REGISTER_ROOM:
                statusChildren.add(_StatusMessage("Register Room", _textStyle_UnexpectedError));
                break;
              case LiveStatus.PEER_REMOVED:
                // TODO: Handle this case.
                break;
              case LiveStatus.MASTER_OFFER_POSTED:
                statusChildren.add(_StatusMessage("Offer Posted", _textStyle_UnexpectedError));
                break;
              case LiveStatus.MASTER_ANSWER_ARRIVED:
                statusChildren.add(_StatusMessage("Answer Arrived", _textStyle_UnexpectedError));
                break;
              case LiveStatus.MEDIA_ERROR:
                // TODO: Handle this case.
                break;
            }

            print('liveStore.hasMediaStream: ${liveStore.hasMediaStream}');
            if (liveStore.hasMediaStream)
            {
              var mediaRenderer = liveStore.mediaRenderer;
              print('> mediaRenderer.rotation: ${mediaRenderer.rotation}');
              stackChildren.add(
                Container(width: screenWidth, height: screenHeight,
                    child: RTCVideoView(mediaRenderer)
                ),
              );
            }

            if (spinnerWidget != null) stackChildren.add(spinnerWidget);
            stackChildren.add(ListView(children:statusChildren));

            print('videoWidget: $videoWidget');
            print('statusChildren: $statusChildren');

            return Stack(children: stackChildren);
            },
          ),
        );
      })
    ),
  );}
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
