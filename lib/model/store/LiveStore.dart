import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_videolive/model/store/live/ClientStore.dart';
import 'package:flutter_videolive/model/vo/RoomVO.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:mobx/mobx.dart';

import 'live/MasterStore.dart';
import 'live/enum/LiveStatus.dart';
import 'live/peers/MediaStore.dart';
import 'live/peers/PeersStore.dart';

part 'LiveStore.g.dart';

class LiveStore = _LiveStore with _$LiveStore;

abstract class _LiveStore with Store {

  DocumentReference _roomDocument;

  ClientStore _clientStore;
  MasterStore _masterStore;

  PeersStore _peersStore = PeersStore();
  MediaStore _mediaStore = MediaStore();

  RoomVO _room;

  RTCVideoRenderer get mediaRenderer => _mediaStore.mediaRenderer;
  bool get hasMediaStream => _mediaStore.hasStream;

  @observable
  LiveStatus roomStatus;
  @action void _onLiveStatus(LiveStatus status) {
    print('> LiveStore -> _onLiveStatusChanged: $status');
    if (this.roomStatus != status)
      this.roomStatus = status;
  }

  @observable
  bool isMaster = false;
  bool get isRoomClosed => roomStatus == LiveStatus.CLOSED;

  _LiveStore() {
    roomStatus = LiveStatus.INITIAL;
    _peersStore.listenStatus(_onLiveStatus);
    _mediaStore.listenStatus(_onLiveStatus);
  }

  void initialize(RoomVO room) async
  {
    isMaster = room == null;

    print('> Master: $isMaster');

    if (_peersStore.isConnected(isMaster ? null : room.id)) {
      _onLiveStatus(LiveStatus.ALREADY_CONNECTED);
      return;
    }

    _onLiveStatus(LiveStatus.PREPARE);

    final _roomsCollection = FirebaseFirestore.instance.collection('rooms');
    _roomDocument = isMaster ? _roomsCollection.doc() : _roomsCollection.doc(room.id);
    _room = isMaster ? RoomVO(_roomDocument.id, 'ROOM DATA') : room;
    if (isRoomClosed) return dispose(false);
    _onLiveStatus(LiveStatus.ROOM_SET);

    print('> _roomDocument exists: ${(await _roomDocument.get()).exists}');

    await _peersStore.initialize(_roomDocument);
    if (isRoomClosed) return dispose(false);
    _onLiveStatus(LiveStatus.PEERS_COLLECTION_READY);

    await _mediaStore.initialize();
    if (isRoomClosed) return dispose(false);
    _onLiveStatus(LiveStatus.RENDERER_READY);

    if (isMaster)
    {
      try {
        await _mediaStore.createStreamFromCamera();
      } catch (e) { }
      if (isRoomClosed) return dispose(false);
      _onLiveStatus(LiveStatus.MASTER_CAMERA_READY);

      await _roomDocument.set({ 'info': //TODO: Set real user data
        { 'name': DateTime.now().toString() } });
      if (isRoomClosed) { dispose(false); return; }
      _onLiveStatus(LiveStatus.MASTER_REGISTER_ROOM);
      
      _masterStore = MasterStore();
      _masterStore.listenStatus(_onLiveStatus);
      _masterStore.onConnectionCreated(_mediaStore.addStream);
      await _masterStore.initialize(_peersStore, _room.id);
    }
    else
    {
      if ((await _roomDocument.get()).exists) {
        _clientStore = ClientStore();
        _clientStore.listenStatus(_onLiveStatus);
        _clientStore.onMediaArrived(_mediaStore.setStream);
        await _clientStore.initialize(_peersStore, _room.id);
      }
      else _onLiveStatus(LiveStatus.CLIENT_ROOM_NOT_EXISTS);
    }
  }

  void dispose(bool isClosed) async {
    try {
      roomStatus = isClosed ? LiveStatus.CLOSED : LiveStatus.DISPOSED;
      _peersStore.clean();
      _mediaStore.dispose(isClosed);
      if (isMaster) _roomDocument.delete();
      (_clientStore != null && _clientStore.ready)
          ? _clientStore?.dispose(true)
          : _clientStore?.closed = true;
      (_masterStore != null && _masterStore.ready)
          ? _masterStore?.dispose(true)
          : _masterStore?.closed = true;
    } catch (e) {
      print('ERROR on dispose -> $e');
    }
    print('>>>>>>>>>>> DISPOSED');
  }
}