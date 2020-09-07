import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobx/mobx.dart';
import 'mixin/LiveStatusDispatcher.dart';
import 'enum/LiveStatus.dart';

import 'PeersStore.dart';

part 'ClientStore.g.dart';

class ClientStore = _ClientStore with _$ClientStore;

abstract class _ClientStore with Store, LiveStatusDispatcher {

  bool _isClosed = false;
  set closed(bool value) => _isClosed = value;

  _ClientStore() {
    _isClosed = false;
    sendStatus(LiveStatus.CLIENT_CREATED);
  }

  Future<void> initialize(
      PeersStore peersStore,
      String roomID) async
  {
    DocumentReference peerDocument = peersStore.peersCollection.doc();
    print('> ClientStore -> ======= Join room: $roomID | peerID = ${peerDocument.id}');

    print('> \t0. Create peer');
    // final peerVO = await peersStore.registerClientPeer(peerDocument.id, roomID);
    if(_isClosed) return dispose(false);
    sendStatus(LiveStatus.CLIENT_PEER_CREATED);

    print('> \t1. Register peer');
    await peerDocument.set({ 'info': { 'name': DateTime.now().toString()}});

    if (_isClosed) return dispose(false);
    sendStatus(LiveStatus.CLIENT_PEER_REGISTERED);

    print('> \t2. Save peer in a collection');
  }

  @override
  Future<void> dispose(manual) async {
    _isClosed = true;
    sendStatus(LiveStatus.CLIENT_DISPOSED);
    super.dispose(manual);
    print('>>>>>>>>>>> CLIENT DISPOSED');
    return;
  }
}