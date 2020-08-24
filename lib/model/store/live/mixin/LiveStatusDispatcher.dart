import 'dart:async';

import '../enum/LiveStatus.dart';

abstract class LiveStatusDispatcher {
  // ignore: close_sinks
  var _onLiveStatus = StreamController<LiveStatus>();
  get listenStatus => _onLiveStatus.stream.listen;
  get sendStatus => _onLiveStatus.sink.add;

  void dispose(manual) {
    _onLiveStatus?.close();
    _onLiveStatus = null;
  }
}