import 'dart:async';

import 'package:flutter_webrtc/rtc_peerconnection.dart';

class PeerVO {
  RTCPeerConnection connection;
  StreamSubscription iceSubscription;
  StreamSubscription peerDocumentSubscription;
  String id;
  String roomID;

  PeerVO(this.id, this.roomID, this.connection);
}