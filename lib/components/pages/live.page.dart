import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_videolive/components/widgets/DisposableBuilder.dart';
import 'package:flutter_videolive/model/store/LiveStore.dart';
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
      alignment: Alignment.topLeft,
      child: Consumer<LiveStore>(builder: (ct, LiveStore liveStore, _) {
        return DisposableBuilder(
          init: () => liveStore.initialize(roomVO),
          dispose: () async => liveStore.dispose(true),
          builder: (dct, ss) => Observer(builder: (ost) {
            print('< LivePage: RoomStatus = ${liveStore.roomStatus}');
            final roomStatus = liveStore.roomStatus;
            switch(roomStatus) {
              case RoomStatus.CLOSED:
              case RoomStatus.INITIAL:
                statusChildren.add(Divider());
                break;
              case RoomStatus.ALREADY_CONNECTED:
                statusChildren.add(_StatusMessage("Already Connected", _textStyle_Message));
                break;
              case RoomStatus.PREPARE:
                  spinnerWidget = LinearProgressIndicator();
                  statusChildren.add(_StatusMessage("Prepare Room", _textStyle_Message));
                break;
              case RoomStatus.RENDERER_READY:
                statusChildren.add(_StatusMessage("Renderer Ready", _textStyle_Message));
                break;
              case RoomStatus.ROOM_OWNER:
                statusChildren.add(_StatusMessage("Room Owner", _textStyle_Message));
                break;
              case RoomStatus.CAMERA_READY:
                statusChildren.add(_StatusMessage("Camera Ready", _textStyle_Message));
                break;
              case RoomStatus.ROOM_EXISTS:
                spinnerWidget = null;
                statusChildren.add(_StatusMessage("Room Exists", _textStyle_Message));
                break;
              case RoomStatus.PEER_CREATED:
                statusChildren.add(_StatusMessage("Peer Created", _textStyle_Message));
                break;
              case RoomStatus.PEER_REGISTERED:
                statusChildren.add(_StatusMessage("Peer Registered", _textStyle_Message));
                break;
              case RoomStatus.OFFER_RECEIVED:
                statusChildren.add(_StatusMessage("Offer Received", _textStyle_Message));
                break;
              case RoomStatus.REMOTE_DESCRIPTION_SET:
                statusChildren.add(_StatusMessage("Remote Description Set", _textStyle_Message));
                break;
              case RoomStatus.LOCAL_DESCRIPTION_SET:
                statusChildren.add(_StatusMessage("Local Description Set", _textStyle_Message));
                break;
              case RoomStatus.ANSWER_POSTED:
                statusChildren.add(_StatusMessage("Answer Posted", _textStyle_Message));
                break;
              case RoomStatus.MEDIA_SET:
                statusChildren.add(_StatusMessage("Media Arrived", _textStyle_Ready));
                break;
              case RoomStatus.ICE_FAILED:
                statusChildren.add(_StatusMessage("ICE FAILED", _textStyle_Message));
                break;
              case RoomStatus.ICE_CONNECTED:
                spinnerWidget = null;
                statusChildren.add(_StatusMessage("ICE CONNECTED", _textStyle_Message));
                break;
              case RoomStatus.DISPOSED:
                statusChildren.add(_StatusMessage("Disposed", _textStyle_Message));
                break;
              case RoomStatus.ERROR:
                statusChildren.add(_StatusMessage("Error", _textStyle_UnexpectedError));
                break;
            }

            if (liveStore.mediaStream != null)
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
