import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_videolive/model/vo/PeerVO.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:mobx/mobx.dart';
import 'mixin/LiveStatusDispatcher.dart';
import 'enum/LiveStatus.dart';

import 'peers/PeersStore.dart';

part 'MasterStore.g.dart';

class MasterStore = _MasterStore with _$MasterStore;

abstract class _MasterStore with Store, LiveStatusDispatcher {
  StreamSubscription _peersCollectionSubscription;

  // ignore: close_sinks
  var _onConnectionCreated = StreamController<RTCPeerConnection>();
  get onConnectionCreated => _onConnectionCreated.stream.listen;

  bool _isReady = false;
  bool _isClosed = false;
  set closed(bool value) => _isClosed = value;
  bool get ready => _isReady;

  _MasterStore() {
    _isClosed = false;
    sendStatus(LiveStatus.MASTER_CREATED);
  }

  Future<void> initialize(
    PeersStore _peersStore,
    String roomID) async
  {
    _peersCollectionSubscription = _peersStore.peersCollection.snapshots().listen((QuerySnapshot peersSnapshot) {
      peersSnapshot.docChanges.forEach((DocumentChange peerChange) async {
        if (peerChange.type == DocumentChangeType.modified) return;

        final document = peerChange.doc;
        final peerID = document.id;

        print('> peers: change: ${peerChange.type} | peerID: $peerID');

        if (peerChange.type == DocumentChangeType.removed) {
          if (_peersStore.hasPeer(peerID)) {
            _peersStore.unregisterAndClosePeer(peerID);
            _peersStore.cleanPeerData(peerID);
            if (_isClosed) return dispose(false);
            sendStatus(LiveStatus.MASTER_PEER_REMOVED);
          }
        }
        else if (peerChange.type == DocumentChangeType.added)
        {
          if (!_peersStore.hasPeer(peerID)) {
            print('====> start new registration');
            DocumentReference peerDoc = _peersStore.peersCollection.doc(peerID);
            print('> \t. Create RTC connection client');
            PeerVO peerVO = await _peersStore.registerPeer(peerDoc, roomID);
            if (_isClosed) return dispose(false);
            sendStatus(LiveStatus.CLIENT_PEER_CREATED);

            print('> \t. Add media stream');
            _onConnectionCreated.sink.add(peerVO.connection);

            if (_isClosed) return dispose(false);
            sendStatus(LiveStatus.MASTER_MEDIA_ATTACHED_TO_PEER);

            peerVO.peerDocumentSubscription = peerDoc
            .snapshots().listen((DocumentSnapshot snapshot) async
            {
              final requestingPeerID = snapshot.id;
              if (!snapshot.exists
                && _peersStore.hasPeer(requestingPeerID)) {
                _peersStore.unregisterAndClosePeer(peerID);
                _peersStore.cleanPeerData(peerID);
                return;
              }

              final data = snapshot.data();
              final answer = data['answer'];

              print('> peerDocument.listen: has snapshot: $requestingPeerID');
              if (answer != null) {
                if (_isClosed) return dispose(false);
                sendStatus(LiveStatus.MASTER_ANSWER_ARRIVED);

                print('> peerDocument.listen -> Got remote answer: $answer');
                final rtcSessionDescription = RTCSessionDescription(answer['sdp'], answer['type']);
                await _peersStore.getPeer(requestingPeerID).connection.setRemoteDescription(rtcSessionDescription);

                if (_isClosed) return dispose(false);
                sendStatus(LiveStatus.REMOTE_DESCRIPTION_SET);
              }
            });

            RTCSessionDescription offer = await peerVO.connection.createOffer({});
            await peerVO.connection.setLocalDescription(offer);

            if (_isClosed) return dispose(false);
            sendStatus(LiveStatus.LOCAL_DESCRIPTION_SET);

            await peerDoc.update({'offer':
            { 'type': offer.type, 'sdp': offer.sdp },
            });

            if (_isClosed) return dispose(false);
            sendStatus(LiveStatus.MASTER_OFFER_POSTED);
          }
        }
      });
    });
  }

  @override
  void dispose(manual) {
    _onConnectionCreated.close();
    _onConnectionCreated = null;
    _peersCollectionSubscription?.cancel();
    _peersCollectionSubscription = null;
    _isClosed = true;
    super.dispose(manual);
    print('>>>>>>>>>>> MASTER DISPOSED');
  }
}