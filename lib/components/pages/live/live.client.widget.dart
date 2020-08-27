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
Widget _spinnerWidget = _createSpinner();

class LiveClient extends StatelessWidget {

  LiveClient() {
    _statusChildren = <Widget>[];
  }

  static const _tsMessage = TextStyle(color: Colors.red, fontSize: 14.0);

  @override
  Widget build(BuildContext ctx) {
    List<Widget> stackChildren = [];
    final size = MediaQuery.of(ctx).size;
    return Consumer<LiveStore>(builder: (ct, LiveStore liveStore, _) {
      return Container(width: size.width, height: size.height,
        child: Observer(builder: (ost) {
          final roomStatus = liveStore.roomStatus;
          print('< LiveMaster: LiveStatus = $roomStatus');
          switch(roomStatus) {
          /****************************/
          /* START -> CONNECTION */
            case LiveStatus.PREPARE:
              break;
            case LiveStatus.CLIENT_PEER_CREATED:
              break;
            case LiveStatus.CLIENT_PEER_REGISTERED:
              break;
            case LiveStatus.CLIENT_READY:
              break;
            case LiveStatus.CLIENT_OFFER_RECEIVED:
              break;
            case LiveStatus.CLIENT_REMOTE_DESCRIPTION_SET:
              break;
            case LiveStatus.CLIENT_LOCAL_DESCRIPTION_SET:
              break;
            case LiveStatus.CLIENT_ANSWER_POSTED:
              break;
          /* END -> CONNECTION */
          /****************************/
          /* START -> PEER CONNECTION */
            case LiveStatus.ICE_CHECKING:
              break;
            case LiveStatus.ICE_CONNECTED:
              _spinnerWidget = null;
              if (liveStore.hasMedia && _videoWidget == null) {
                _videoWidget = RTCVideoView(liveStore.mediaRenderer);
              }
              break;
            case LiveStatus.ICE_COMPLETE:
              break;
            case LiveStatus.ICE_FAILED:
              _spinnerWidget = _createSpinner();
              _videoWidget = null;
              break;
            case LiveStatus.ICE_DISCONNECTED:
              Future.delayed(Duration.zero, () async {
                Navigator.of(ctx).pop(true);
              });
              return Container();

          /* END -> PEER CONNECTION */
          /****************************/
          /* START -> CLIENT CLOSE */
            case LiveStatus.CLIENT_DISPOSED:
              Future.delayed(Duration.zero, () async {
                Navigator.of(ctx).pop(true);
              });
              return Container();
              break;
          }

          _statusChildren.add(_StatusMessage(roomStatus.toString(), _tsMessage));

          print('videoWidget: $_videoWidget');
          print('statusChildren: $_statusChildren');

          if (_videoWidget != null) stackChildren.add(_videoWidget);
          stackChildren.add(ListView(children: _statusChildren));
          if (_spinnerWidget != null) stackChildren.add(_spinnerWidget);

          return Stack(children: stackChildren);
        },
        ),
      );
    });
  }

  Future<void> _onClientDisposed(context) async {
   return showDialog(
     context: context,
     builder: (context) => new AlertDialog(
       title: new Text('Connection fails'),
       content: new Text('Streamer closed video.'),
       actions: <Widget>[
         FlatButton(
         onPressed:() async {
           Navigator.of(context).pop(true);
         },
         child: Text("CLOSE")),
       ],
     ),
   );
  }
}

Widget _createSpinner() {
  return Align(
      alignment: Alignment.center,
      child: CircularProgressIndicator());
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
