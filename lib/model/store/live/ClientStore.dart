import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:mobx/mobx.dart';
import 'mixin/LiveStatusDispatcher.dart';
import 'enum/LiveStatus.dart';

import 'peers/PeersStore.dart';

part 'ClientStore.g.dart';

class ClientStore = _ClientStore with _$ClientStore;

abstract class _ClientStore with Store, LiveStatusDispatcher {

  // ignore: close_sinks
  var _onAttachMediaToPeer = StreamController<RTCPeerConnection>();
  get onAttachMediaToPeer => _onAttachMediaToPeer.stream.listen;

  // ignore: close_sinks
  var _onMediaStreamArrived = StreamController<MediaStream>();
  get onMediaArrived => _onMediaStreamArrived.stream.listen;

  // ignore: close_sinks
  var _onMediaTrackArrived = StreamController<MediaStreamTrack>();
  get onMediaTrackArrived => _onMediaTrackArrived.stream.listen;

  bool _isReady = false;
  bool _isClosed = false;
  set closed(bool value) => _isClosed = value;
  bool get ready => _isReady;

  _ClientStore() {
    _isClosed = false;
    sendStatus(LiveStatus.CLIENT_CREATED);
  }

  Future<void> initialize(
      PeersStore _peersStore,
      String roomID) async
  {
    DocumentReference peerDocument = _peersStore.peersCollection.doc();
    print('> ClientStore -> ======= Join room: $roomID');

    print('> \t0. Create peer');
    final peerVO = await _peersStore.registerClientPeer(peerDocument, roomID);
    if(_isClosed) return dispose(false);
    sendStatus(LiveStatus.CLIENT_PEER_CREATED);

    print('> \t1. Register peer');
    await peerDocument.set({ 'info': { 'name': DateTime.now().toString()}});

    if (_isClosed) return dispose(false);
    sendStatus(LiveStatus.CLIENT_PEER_REGISTERED);

    print('> \t2. Save peer in a collection');

    peerVO.peerDocumentSubscription =
      peerDocument.snapshots().listen((
          DocumentSnapshot peerDocumentSnapshot) async {
        if (!peerDocumentSnapshot.exists || _isClosed) {
          return dispose(false);
        }

        final data = peerDocumentSnapshot.data();
        final answer = data['answer'];
        final offer = data['offer'];

        print('> -> peerDocument.listen: has snapshot: ${peerDocumentSnapshot.id}');
        print('> -> update: offer|answer (${offer != null}|${answer != null})');

        if (offer != null && answer == null)
        {
          sendStatus(LiveStatus.CLIENT_OFFER_RECEIVED);

          final peerConnection = peerVO.connection;
          print('> \t3. Listen for media tracks');

          _onAttachMediaToPeer.sink.add(peerConnection);
          peerConnection.onAddTrack = (MediaStream stream, MediaStreamTrack track) {
            print('>>>> onAddTrack');
          };
          peerConnection.onAddStream = _onMediaStreamArrived.sink.add;
          peerConnection.onRemoveStream = _onMediaStreamArrived.sink.add;

          print('> \t4.1 Register offer: ${offer['type']}');
          final remoteSessionDescription = RTCSessionDescription(offer['sdp'], offer['type']);
          await peerConnection.setRemoteDescription(remoteSessionDescription);

          if (_isClosed) return dispose(false);
          sendStatus(LiveStatus.REMOTE_DESCRIPTION_SET);

          print('> \t4.2 Answer created');
          final answer = await peerConnection.createAnswer({});
          peerConnection.setLocalDescription(answer);

          if (_isClosed) return dispose(false);
          sendStatus(LiveStatus.LOCAL_DESCRIPTION_SET);

          print('> \t5. Post answer to the peer document');
          await peerDocument.update({'answer':
          { 'type': answer.type, 'sdp': answer.sdp}});

          if (_isClosed) return dispose(false);
          sendStatus(LiveStatus.CLIENT_ANSWER_POSTED);
        }
      });
  }

  @override
  void dispose(manual) {
    _onMediaStreamArrived.close();
    _onMediaStreamArrived = null;
    _isClosed = true;
    super.dispose(manual);
    print('>>>>>>>>>>> CLIENT DISPOSED');
  }
}