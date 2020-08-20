import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_videolive/model/vo/PeerVO.dart';
import 'package:flutter_videolive/model/vo/RoomVO.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:mobx/mobx.dart';

part 'MasterStore.g.dart';

const MASTER_ICE_COLLECTION = 'callerCandidates';
const CLIENT_ICE_COLLECTION = 'calleeCandidates';
const PEERS_COLLECTION = 'peers';

Map<String, dynamic> _iceServers = {
  'iceServers': [
    {'url': 'stun:stun1.l.google.com:19302'},
    {'url': 'stun:stun2.l.google.com:19302'},
  ]
};

final Map<String, dynamic> _mediaStreamConstraints = {
  'audio': true,
  'video': {
    'mandatory': {
      'minWidth': '640', // Provide your own width, height and frame rate here
      'minHeight': '480',
      'minFrameRate': '30',
    },
    'facingMode': 'user',
    'optional': [],
  }
};

enum RoomStatus {
  INITIAL,
  ALREADY_CONNECTED,
  PREPARE,
  RENDERER_READY,
  ROOM_OWNER,
  REGISTER_ROOM,
  ROOM_EXISTS,
  CAMERA_READY,
  PEER_CREATED,
  PEER_REMOVED,
  PEER_REGISTERED,
  OFFER_POSTED,
  OFFER_RECEIVED,
  REMOTE_DESCRIPTION_SET,
  LOCAL_DESCRIPTION_SET,
  ANSWER_POSTED,
  ANSWER_ARRIVED,
  ICE_CONNECTED,
  ICE_FAILED,

  MEDIA_SET,
  DISPOSED,
  CLOSED,
  ERROR
}

class MasterStore = _MasterStore with _$MasterStore;

abstract class _MasterStore with Store {

  final _peers = new Map<String, PeerVO>();
  final _roomsColRef = FirebaseFirestore.instance.collection('rooms');
  StreamSubscription _peersCollectionSubscription;
  CollectionReference _peersColRef;
  DocumentReference _roomDocRef;

  @observable
  RTCVideoRenderer mediaRenderer;

  @observable
  MediaStream mediaStream;
  @action
  void _onMediaChanged(MediaStream mediaStream) {
    print('> MasterStore -> _onMediaChanged: $mediaStream');
    if (this.mediaStream != mediaStream) {
      if (isRoomClosed) {
        dispose(false);
        return;
      }
      _onRoomStatusChanged(RoomStatus.MEDIA_SET);
      this.mediaStream?.dispose();
      this.mediaStream = mediaStream;
      this.mediaRenderer.srcObject = this.mediaStream;
    }
  }

  @observable
  bool isRoomOwner = false;

  @observable
  RoomVO room;

  @computed
  bool get isRoomClosed => roomStatus == RoomStatus.CLOSED;

  @observable
  RoomStatus roomStatus;
  @action
  void _onRoomStatusChanged(RoomStatus status) {
    print('> MasterStore -> _onRoomStatusChanged: $status');
    if (this.roomStatus != status)
      this.roomStatus = status;
  }

  _MasterStore() {
    roomStatus = RoomStatus.INITIAL;
  }

  void initialize(RoomVO room) async
  {
    isRoomOwner = room == null;
    
    String roomID = isRoomOwner ? null : room.id;
    final isAlreadyConnectedToRoom = _peers.isNotEmpty && !isRoomOwner &&
        _peers.values.any((peerVO) => peerVO.roomID == roomID);

    print('> MasterStore -> isAlreadyConnectedToRoom: ${room.id}');

    _onRoomStatusChanged(RoomStatus.PREPARE);

    if (isAlreadyConnectedToRoom) {
      _onRoomStatusChanged(RoomStatus.ALREADY_CONNECTED);
      return;
    }

    _roomDocRef = !isRoomOwner
        ? _roomsColRef.doc(room.id)
        : _roomsColRef.doc();

    mediaRenderer = RTCVideoRenderer();
    mediaRenderer.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    await mediaRenderer.initialize();
    mediaRenderer.mirror = true;

    if (isRoomClosed) {
      dispose(false);
      return;
    }
    _onRoomStatusChanged(RoomStatus.RENDERER_READY);

    final DocumentSnapshot roomDoc = await _roomDocRef.get();
    roomID = roomDoc.id;

    if (isRoomClosed) { dispose(false); return; }
    
    if (isRoomOwner)
    {
      this.room = RoomVO(roomID, 'ROOM DATA'); // TODO: Add room data from Firebase document
      _onRoomStatusChanged(RoomStatus.ROOM_OWNER);
      
      await roomDoc.reference.set({ 'info': //TODO: Set real user data
        { 'name': DateTime.now().toString() } });

      if (isRoomClosed) { dispose(false); return; }
      _onRoomStatusChanged(RoomStatus.REGISTER_ROOM);

      await createAndRegisterOwner(roomID);
    }
    else if (roomDoc.exists)
    {
      this.room = room;
      _onRoomStatusChanged(RoomStatus.ROOM_EXISTS);
      await createAndRegisterRoomClient(roomID);
    }
    else
    {
      _onRoomStatusChanged(RoomStatus.ERROR);
    }
  }

  void _onICEConnectionStatus(RTCIceConnectionState state) {
    print('> onIceConnectionState: $state');
    if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
      if (isRoomClosed) {
        dispose(false);
        return;
      }
      _onRoomStatusChanged(RoomStatus.ICE_FAILED);
    }
    else if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
      if (isRoomClosed) {
        dispose(false);
        return;
      }
      _onRoomStatusChanged(RoomStatus.ICE_CONNECTED);
    }
  }

  void dispose(bool isClosed) async {
    try {
      roomStatus = isClosed ? RoomStatus.CLOSED : RoomStatus.DISPOSED;
      mediaStream?.dispose();
      _peers.forEach((String peerID, PeerVO peerVO) async {
        peerVO.connection.close();
        peerVO.iceSubscription?.cancel();
        peerVO.peerDocumentSubscription?.cancel();
        _cleanPeerData(peerID);
      });
      if (isRoomOwner && _roomDocRef != null) {
        await _roomDocRef.delete();
        _peersCollectionSubscription?.cancel();
        _peersCollectionSubscription = null;
        _roomDocRef = null;
      }
    } catch (e) { print('ERROR on dispose -> $e'); }
    _peers.clear();
    if (_peersCollectionSubscription != null) {
      _peersCollectionSubscription.cancel();
      _peersCollectionSubscription = null;
    }
    print('>>>>>>>>>>> DISPOSED');
  }

  Future<PeerVO> _createPeer(
      String peerID,
      String roomID,
      CollectionReference iceCollectionToPost,
      CollectionReference iceCollectionToListen
  ) async {
    final peerConnection = await createPeerConnection(_iceServers, {});
    final result = PeerVO(peerID, roomID, peerConnection);

    peerConnection.onIceCandidate = (RTCIceCandidate iceCandidate) {
      print('> \t $peerID -> onIceCandidate: got ice candidate: ${iceCandidate.sdpMid}');
      iceCollectionToPost.add({
        'sdpMLineIndex': iceCandidate.sdpMlineIndex,
        'sdpMid': iceCandidate.sdpMid,
        'candidate': iceCandidate.candidate,
      });
    };

    result.iceSubscription = iceCollectionToListen.snapshots().listen((QuerySnapshot iceListenSnapshot) {
      iceListenSnapshot.docChanges.forEach((DocumentChange iceListenChange) async {
        if (iceListenChange.type == DocumentChangeType.added) {
          final cd = iceListenChange.doc.data();
          print('> \t $peerID -> iceListenChange: candidate added: $cd');
          final candidate = RTCIceCandidate(cd['candidate'], cd['sdpMid'], cd['sdpMLineIndex']);
          peerConnection.addCandidate(candidate);
        }
      });
    });

    return result;
  }

  Future<void> createAndRegisterRoomClient(String roomID) async
  {
    _peersColRef = _roomDocRef.collection(PEERS_COLLECTION);
    final peerDocRef = _peersColRef.doc();
    final peerID = peerDocRef.id;
    
    print('> MasterStore -> ======= Join room: ${room.id}');
    print('> \t0. Peer created: $peerID');

    final peerVO = await _createPeer(
        peerID, roomID,
        peerDocRef.collection(CLIENT_ICE_COLLECTION),
        peerDocRef.collection(MASTER_ICE_COLLECTION)
    );

    if (isRoomClosed) { dispose(false); return; }
    _onRoomStatusChanged(RoomStatus.PEER_CREATED);

    // TODO: Replace with ream user data
    await peerDocRef.set({ 'info': { 'name': DateTime.now().toString()}});
    
    if (isRoomClosed) { dispose(false); return; }
    _onRoomStatusChanged(RoomStatus.PEER_REGISTERED);
    
    print('> \t1. Peer connection created');
    _peers[peerID] = peerVO;
    print('> \t2. Save peerID ($peerID) in a collection');
    peerVO.peerDocumentSubscription =
      peerDocRef.snapshots().listen((
        DocumentSnapshot peerDocSnapshot) async {
      if (!peerDocSnapshot.exists || isRoomClosed) {
        dispose(false);
        return;
      }

      final data = peerDocSnapshot.data();
      final answer = data['answer'];
      final offer = data['offer'];

      print('> $peerID -> peerDocument.listen: has snapshot: ${peerDocSnapshot.id}');
      print('> $peerID -> update: offer|answer (${offer != null}|${answer != null})');

      if (offer != null && answer == null)
      {
        _onRoomStatusChanged(RoomStatus.OFFER_RECEIVED);

        final connection = peerVO.connection;
        print('> \t3. Listen for media tracks');

        connection.onAddStream = _onMediaChanged;
        connection.onRemoveStream = _onMediaChanged;
        connection.onIceConnectionState = _onICEConnectionStatus;

        print('> \t4.1 Register offer: ${offer['type']}');
        final remoteSessionDescription = RTCSessionDescription(offer['sdp'], offer['type']);
        await connection.setRemoteDescription(remoteSessionDescription);

        if (isRoomClosed) { dispose(false); return; }
        _onRoomStatusChanged(RoomStatus.REMOTE_DESCRIPTION_SET);

        print('> \t4.2 Answer created');
        final answer = await connection.createAnswer({});
        connection.setLocalDescription(answer);

        if (isRoomClosed) { dispose(false); return; }
        _onRoomStatusChanged(RoomStatus.LOCAL_DESCRIPTION_SET);

        print('> \t5. Post answer to the peer document');
        await peerDocRef.update({'answer':
        { 'type': answer.type, 'sdp': answer.sdp}});

        if (isRoomClosed) { dispose(false); return; }
        _onRoomStatusChanged(RoomStatus.ANSWER_POSTED);
      }
    });
  }

  createAndRegisterOwner(String roomID) async {

    mediaStream = await navigator.getUserMedia(_mediaStreamConstraints);
    mediaRenderer.srcObject = mediaStream;

    if (isRoomClosed) { dispose(false); return; }
    _onRoomStatusChanged(RoomStatus.CAMERA_READY);
    
    _peersCollectionSubscription = _peersColRef.snapshots().listen((QuerySnapshot peersSnapshot) {
      peersSnapshot.docChanges.forEach((DocumentChange peerChange) async {
        if (peerChange.type == DocumentChangeType.modified) return;

        final document = peerChange.doc;
        final peerID = document.id;

        print('> peers: change: ${peerChange.type} | peerID: $peerID');

        if (peerChange.type == DocumentChangeType.removed) {
          if (_peers.containsKey(peerID)) {
            _removePeer(peerID);
            if (isRoomClosed) { dispose(false); return; }
            _onRoomStatusChanged(RoomStatus.PEER_REMOVED);
          }
        }
        else if (peerChange.type == DocumentChangeType.added) {
          if (!_peers.containsKey(peerID)) {
            print('====> start new registration');
            final peerDocRef = _peersColRef.doc(peerID);
            print('> \t. Create RTC connection client');
            final peerVO = await _createPeer(
                peerID, roomID,
                peerDocRef.collection(CLIENT_ICE_COLLECTION),
                peerDocRef.collection(MASTER_ICE_COLLECTION)
            );
            if (isRoomClosed) { dispose(false); return; }
            _onRoomStatusChanged(RoomStatus.PEER_CREATED);

            final connection = peerVO.connection;

            print('> \t. Add media stream');
            await connection.addStream(mediaStream);

            if (isRoomClosed) { dispose(false); return; }
            _onRoomStatusChanged(RoomStatus.MEDIA_SET);

            connection.onIceConnectionState = _onICEConnectionStatus;

            peerVO.peerDocumentSubscription = peerDocRef.snapshots().listen(
              (DocumentSnapshot snapshot) async
            {
              final requestingPeerID = snapshot.id;
              if (!snapshot.exists) { _removePeer(requestingPeerID); return; }

              final data = snapshot.data();
              final answer = data['answer'];

              print('> peerDocument.listen: has snapshot: $requestingPeerID');
              if (answer != null) {
                if (isRoomClosed) { dispose(false); return; }
                _onRoomStatusChanged(RoomStatus.ANSWER_ARRIVED);

                print('> peerDocument.listen -> Got remote answer: $answer');
                final rtcSessionDescription = RTCSessionDescription(answer['sdp'], answer['type']);
                await _peers[requestingPeerID].connection.setRemoteDescription(rtcSessionDescription);

                if (isRoomClosed) { dispose(false); return; }
                _onRoomStatusChanged(RoomStatus.REMOTE_DESCRIPTION_SET);
              }
            });

            RTCSessionDescription offer = await peerVO.connection.createOffer({});
            await peerVO.connection.setLocalDescription(offer);

            if (isRoomClosed) { dispose(false); return; }
            _onRoomStatusChanged(RoomStatus.LOCAL_DESCRIPTION_SET);

            await peerDocRef.update({'offer':
              { 'type': offer.type, 'sdp': offer.sdp },
            });

            if (isRoomClosed) { dispose(false); return; }
            _onRoomStatusChanged(RoomStatus.OFFER_POSTED);
          }
        }
      });
    });
  }
  
  void _removePeer(String peerID) {
    print('> peers: remove peer: $peerID');
    _cleanPeerData(peerID);
    _peers[peerID].connection.close();
    _peers.remove(peerID);
  }
  
  void _cleanPeerData(String peerID) async {
    final peerDocRef = _peersColRef.doc(peerID);
    if (peerDocRef != null) {
      final clientICE = peerDocRef.collection(CLIENT_ICE_COLLECTION);
      if (clientICE != null) await clientICE.get()..docs.clear();
      final masterICE = peerDocRef.collection(MASTER_ICE_COLLECTION);
      if (masterICE != null) await masterICE.get()..docs.clear();
      await peerDocRef.delete();
    }
  }
}