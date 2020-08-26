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
  var _onAttachMediaToPeer = StreamController<RTCPeerConnection>();
  get onAttachMediaToPeer => _onAttachMediaToPeer.stream.listen;

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
            if (_isClosed) return dispose(false);
            sendStatus(LiveStatus.MASTER_PEER_REMOVED);
          }
        }
        else if (peerChange.type == DocumentChangeType.added)
        {
          if (!_peersStore.hasPeer(peerID)) {
            DocumentReference peerDocument = _peersStore.peersCollection.doc(peerID);
            PeerVO peerVO = await _peersStore.registerMasterPeer(peerID, roomID);
            RTCPeerConnection peerConnection = peerVO.connection;
            if (_isClosed) return dispose(false);
            sendStatus(LiveStatus.MASTER_PEER_FOR_CLIENT_CREATED);

            _onAttachMediaToPeer.sink.add(peerConnection);
            if (_isClosed) return dispose(false);
            sendStatus(LiveStatus.MEDIA_ATTACHED_TO_PEER);

            peerVO.peerDocumentSubscription = peerDocument
              .snapshots().listen((DocumentSnapshot snapshot) async
              {
                final requestingPeerID = snapshot.id;
                print('> peerDocument.listen -> Got snapshot: $requestingPeerID - $peerID | ${snapshot.data().containsKey('answer')}');

                if (!snapshot.exists && _peersStore.hasPeer(peerID)) {
                  _peersStore.unregisterAndClosePeer(peerID);
                  return;
                }

                if (!snapshot.data().containsKey('answer')) return;
                final answer = snapshot.data()['answer'];

                print('> peerDocument.listen -> Got remote answer, '
                    'has peer ${_peersStore.hasPeer(peerID)}');

                if (answer != null && _peersStore.hasPeer(peerID))
                {
                  await Future.delayed(Duration(microseconds: 1000));
                  if (_isClosed) return dispose(false);
                  sendStatus(LiveStatus.MASTER_PEER_ANSWER_ARRIVED);
                  await Future.delayed(Duration(microseconds: 1000));

                  final rtcSessionDescription = RTCSessionDescription(answer['sdp'], answer['type']);
                  var connection = _peersStore.getPeer(peerID).connection;
                  await connection.setRemoteDescription(rtcSessionDescription);
                  _peersStore.getPeer(requestingPeerID).isRemoteConnectionSet = true;

                  if (_isClosed) return dispose(false);
                  sendStatus(LiveStatus.MASTER_PEER_REMOTE_DESCRIPTION_SET);
                }
              }
            );

            RTCSessionDescription offer = await peerConnection.createOffer({});
            await peerConnection.setLocalDescription(offer);
            if (_isClosed) return dispose(false);
            sendStatus(LiveStatus.MASTER_PEER_LOCAL_DESCRIPTION_SET);

            await peerDocument.update({'offer':
            { 'type': offer.type, 'sdp': offer.sdp }});
            if (_isClosed) return dispose(false);
            sendStatus(LiveStatus.MASTER_PEER_OFFER_POSTED);
          }
        }
      });
    });
  }

  @override
  void dispose(manual) {
    sendStatus(LiveStatus.MASTER_DISPOSE);
    _onAttachMediaToPeer.close();
    _onAttachMediaToPeer = null;
    _peersCollectionSubscription?.cancel();
    _peersCollectionSubscription = null;
    _isClosed = true;
    super.dispose(manual);
    print('>>>>>>>>>>> MASTER DISPOSED');
  }
}