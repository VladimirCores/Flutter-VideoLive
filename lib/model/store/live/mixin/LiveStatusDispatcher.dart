import 'dart:async';

import '../enum/LiveStatus.dart';

abstract class LiveStatusDispatcher {
  // ignore: close_sinks
  var _onLiveStatus = StreamController<LiveStatus>();
  get listenStatus => _onLiveStatus.stream.listen;
  get sendStatus => _onLiveStatus != null
    ? _onLiveStatus.sink.add
    : (LiveStatus status) => { print('> LiveStatusDispatcher Cant transmit the message $status') };

  Future<void> dispose(manual) async {
    await _onLiveStatus?.close();
    _onLiveStatus = null;
    return;
  }
}