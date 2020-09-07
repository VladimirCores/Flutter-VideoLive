import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_videolive/model/vo/RoomVO.dart';
import 'package:mobx/mobx.dart';
import 'mixin/LiveStatusDispatcher.dart';
import 'enum/LiveStatus.dart';

import 'PeersStore.dart';

part 'MasterStore.g.dart';

class MasterStore = _MasterStore with _$MasterStore;

abstract class _MasterStore with Store, LiveStatusDispatcher {
  StreamSubscription _peersCollectionSubscription;

  bool _isClosed = false;
  set closed(bool value) => _isClosed = value;

  _MasterStore() {
    _isClosed = false;
    sendStatus(LiveStatus.MASTER_CREATED);
  }

  Future<void> initialize(PeersStore _peersStore, RoomVO room) async
  {
    _peersCollectionSubscription = _peersStore.peersCollection.snapshots().listen((QuerySnapshot peersSnapshot) {
      peersSnapshot.docChanges.forEach((DocumentChange peerChange) async {
        if (peerChange.type == DocumentChangeType.modified) return;

        final document = peerChange.doc;
        final peerID = document.id;

        print('> MasterStore: change: ${peerChange.type} | peerID: $peerID');

        if (peerChange.type == DocumentChangeType.removed) {
          print('> MasterStore: _peersStore.hasPeer: ${_peersStore.hasPeer(peerID)}');
          if (_peersStore.hasPeer(peerID)) {
            _peersStore.unregisterAndClosePeer(peerID);
            if (_isClosed) return dispose(false);
            sendStatus(LiveStatus.MASTER_PEER_REMOVED);
          }
        }
        else if (peerChange.type == DocumentChangeType.added)
        {
          if (!_peersStore.hasPeer(peerID)) {
            // DocumentReference peerDocument = _peersStore.peersCollection.doc(
            //     peerID);
            // PeerVO peerVO = await _peersStore.registerMasterPeer(
            //     peerID, room.id);
          }
        }
      });
    });
  }

  @override
  Future<void> dispose(manual) async {
    sendStatus(LiveStatus.MASTER_DISPOSED);
    await _peersCollectionSubscription?.cancel();
    _peersCollectionSubscription = null;
    _isClosed = true;
    await super.dispose(manual);
    print('>>>>>>>>>>> MASTER DISPOSED');
    return;
  }
}