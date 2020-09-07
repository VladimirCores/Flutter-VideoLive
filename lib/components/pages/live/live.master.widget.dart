import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_videolive/model/store/LiveStore.dart';
import 'package:flutter_videolive/model/store/live/enum/LiveStatus.dart';
import 'package:provider/provider.dart';

import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;

List<Widget> _statusChildren;
Widget _videoWidget;
Widget _spinnerWidget = _createSpinner();

Key videoKey = Key('VIDEO_UNIQUE_KEY');

class LiveMaster extends StatelessWidget {
  LiveMaster() {
    _statusChildren = <Widget>[];
  }

  static const _tsMessage = TextStyle(color: Colors.red, fontSize: 14.0);

  @override
  Widget build(BuildContext ctx) {
    List<Widget> stackChildren = [];
    return Consumer<LiveStore>(builder: (ct, LiveStore liveStore, _) {
      return Center(
        child: Observer(builder: (ost) {
          final roomStatus = liveStore.roomStatus;
          print('< LiveClient: LiveStatus = $roomStatus');
          switch(roomStatus) {
            /****************************/
            /* START -> MASTER INITIALIZATION */
            case LiveStatus.PREPARE:
            case LiveStatus.ROOM_READY:
              _spinnerWidget = _createSpinner();
              break;
            case LiveStatus.MASTER_CREATED:
              break;
            case LiveStatus.MASTER_SET_MEDIA_RENDERER_STREAM:
              break;
            case LiveStatus.MASTER_REGISTER_ROOM:
              break;
            case LiveStatus.MASTER_READY:
              _spinnerWidget = null;
              break;
            /* END -> MASTER INITIALIZATION */
            /****************************/
            /* START -> NEW CLIENT */
            case LiveStatus.MASTER_PEER_REGISTERED:
              _statusChildren.clear();
              break;
            case LiveStatus.MASTER_PEER_LOCAL_DESCRIPTION_SET:
              break;
            case LiveStatus.MASTER_PEER_OFFER_POSTED:
              break;
            case LiveStatus.MASTER_PEER_ANSWER_ARRIVED:
              break;
            case LiveStatus.MASTER_PEER_REMOTE_DESCRIPTION_SET:
              break;
            case LiveStatus.MASTER_PEER_REMOVED:
              break;
            /* END -> NEW CLIENT */
            /****************************/
            /* START -> PEER CONNECTION */
            case LiveStatus.ICE_CHECKING:
              break;
            case LiveStatus.ICE_CONNECTED:
            case LiveStatus.ICE_COMPLETE:
              break;
            case LiveStatus.ICE_FAILED:
              break;
            case LiveStatus.ICE_DISCONNECTED:
              _statusChildren.clear();
              break;
            /* END -> PEER CONNECTION */
            /****************************/
            /* START -> MASTER CLOSE */
            case LiveStatus.MASTER_READY:
              _videoWidget = Expanded(child: Container(
                  child: RtcLocalView.SurfaceView()));
              break;
            case LiveStatus.MASTER_DISPOSED:
              _videoWidget = null;
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
      key: UniqueKey(),
      title: Align(alignment: Alignment.topLeft,
        child: Text(message, style: textStyle)
      ),
    );
  }
}
