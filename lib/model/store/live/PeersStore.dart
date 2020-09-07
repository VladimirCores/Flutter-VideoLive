import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_videolive/model/vo/RoomVO.dart';
import 'package:flutter_videolive/model/vo/TokenVO.dart';
import 'package:mobx/mobx.dart';

import 'mixin/LiveStatusDispatcher.dart';
import '../../vo/PeerVO.dart';

part 'PeersStore.g.dart';

const MASTER_ICE_COLLECTION = 'callerCandidates';
const CLIENT_ICE_COLLECTION = 'calleeCandidates';
const PEERS_COLLECTION = 'peers';

class PeersStore = _PeersStore with _$PeersStore;

abstract class _PeersStore with Store, LiveStatusDispatcher {
  final _peers = new Map<String, PeerVO>();
  DocumentReference roomDocument;
  CollectionReference peersCollection;

  bool isConnected(roomID) {
    return roomID != null &&
        _peers.isNotEmpty &&
        _peers.values.any((peerVO) => peerVO.roomID == roomID);
  }

  _PeersStore();

  Future<void> initialize(DocumentReference roomDocument) async {
    this.roomDocument = roomDocument;
    peersCollection = roomDocument.collection(PEERS_COLLECTION);
  }

  void clean() async {
    _peers.forEach((String peerID, PeerVO peerVO) async {
      await cleanPeerData(peerID);
    });
    _peers.clear();
  }

  bool hasPeer(String peerID) {
    return _peers.containsKey(peerID);
  }

  PeerVO getPeer(String peerID) {
    return _peers[peerID];
  }

  void unregisterAndClosePeer(String peerID) {
    if (!hasPeer(peerID)) return;
    // final peerVO = _peers[peerID];
    cleanPeerData(peerID);
    _peers.remove(peerID);
  }

  Future<PeerVO> registerMasterPeer(String peerID, String roomID) async {
    DocumentReference peerDoc = peersCollection.doc(peerID);
    return _registerPeer(
        iceCollectionToPost: peerDoc.collection(MASTER_ICE_COLLECTION),
        iceCollectionToListen: peerDoc.collection(CLIENT_ICE_COLLECTION),
        peerDoc: peerDoc,
        roomID: roomID);
  }

  Future<PeerVO> registerClientPeer(String peerID, String roomID) async {
    DocumentReference peerDoc = peersCollection.doc(peerID);
    return _registerPeer(
        iceCollectionToPost: peerDoc.collection(CLIENT_ICE_COLLECTION),
        iceCollectionToListen: peerDoc.collection(MASTER_ICE_COLLECTION),
        peerDoc: peerDoc,
        roomID: roomID);
  }

  Future<void> cleanPeerData(String peerID) async {
    final peerDocRef = peersCollection.doc(peerID);
    if (peerDocRef != null) {
      final clientICE = peerDocRef.collection(CLIENT_ICE_COLLECTION);
      if (clientICE != null)
        await clientICE.get()
          ..docs.clear();
      final masterICE = peerDocRef.collection(MASTER_ICE_COLLECTION);
      if (masterICE != null)
        await masterICE.get()
          ..docs.clear();
      await peerDocRef.delete();
    }
  }

  Future<void> announceRoomReady(RoomVO roomVO, TokenVO tokenVO) async {
    await roomDocument.set({
      'ready': true,
      'token': tokenVO.toJSON()
    });
  }
  
  Future<PeerVO> _registerPeer(
      {CollectionReference iceCollectionToPost,
      CollectionReference iceCollectionToListen,
      DocumentReference peerDoc,
      String roomID}) async {
    String peerID = peerDoc.id;

    final result = PeerVO(peerID, roomID);

    // result.iceSubscription = iceCollectionToListen
    //     .snapshots()
    //     .listen((QuerySnapshot iceListenSnapshot) {
    //   iceListenSnapshot.docChanges
    //       .forEach((DocumentChange iceListenChange) async {
    //     if (iceListenChange.type == DocumentChangeType.added) {
    //       final cd = iceListenChange.doc.data();
    //       print(
    //           '> PeerStore: $peerID -> iceListenChange: candidate added: $cd');
    //       final candidate = RTCIceCandidate(
    //           cd['candidate'], cd['sdpMid'], cd['sdpMLineIndex']);
    //       peerConnection.addCandidate(candidate);
    //     }
    //   });
    // });

    _peers[peerID] = result;

    return result;
  }
}
