import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_videolive/model/vo/TokenVO.dart';
import 'package:flutter_videolive/utils/settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock/wakelock.dart';

import 'package:flutter_videolive/model/store/live/ClientStore.dart';
import 'package:flutter_videolive/model/vo/RoomVO.dart';
import 'package:mobx/mobx.dart';

import 'live/AgoraStore.dart';
import 'live/MasterStore.dart';
import 'live/enum/LiveStatus.dart';
import 'live/PeersStore.dart';

part 'LiveStore.g.dart';

class LiveStore = _LiveStore with _$LiveStore;

abstract class _LiveStore with Store {

  DocumentReference _roomDocument;

  ClientStore _clientStore;
  MasterStore _masterStore;

  PeersStore _peersStore = PeersStore();
  AgoraStore _agoraStore = AgoraStore();

  RoomVO roomVO;

  int get uid => _agoraStore.uid;

  @observable
  LiveStatus roomStatus;
  @action void _onLiveStatus(LiveStatus status) {
    print('> LiveStore -> $status');
    if (this.roomStatus != status)
      this.roomStatus = status;
  }

  @observable
  bool isRecording = false;

  @observable
  bool isMaster = false;
  bool get isRoomClosed => roomStatus == LiveStatus.CLOSED;

  _LiveStore() {
    roomStatus = LiveStatus.INITIAL;
    _peersStore.listenStatus(_onLiveStatus);
    _agoraStore.listenStatus(_onLiveStatus);
  }

  Future<void> initialize(RoomVO roomVO, Size size) async
  {
    isMaster = roomVO == null;

    print('> Master: $isMaster');

    if (_peersStore.isConnected(isMaster ? null : roomVO.id)) {
      _onLiveStatus(LiveStatus.ALREADY_CONNECTED);
      return;
    } else if (this.roomVO != null) {
      dispose(false);
    }

    _onLiveStatus(LiveStatus.PREPARE);

    await [Permission.camera, Permission.microphone, Permission.storage].request();
    if (isRoomClosed) return dispose(false);
    _onLiveStatus(LiveStatus.PERMISSIONS_READY);

    final _roomsCollection = FirebaseFirestore.instance.collection('rooms');
    _roomDocument = isMaster ? _roomsCollection.doc() : _roomsCollection.doc(roomVO.id);
    this.roomVO = isMaster ? RoomVO(_roomDocument.id, APP_ID,
        'Room Title', ClientRole.Broadcaster) : roomVO;
    if (isRoomClosed) return dispose(false);
    _onLiveStatus(LiveStatus.ROOM_READY);

    print('> _roomDocument exists: ${(await _roomDocument.get()).exists}');

    await Wakelock.enable();
    if (isRoomClosed) return dispose(false);
    _onLiveStatus(LiveStatus.WAKELOCK_ENABLED);

    await _peersStore.initialize(_roomDocument);
    if (isRoomClosed) return dispose(false);
    _onLiveStatus(LiveStatus.PEERS_COLLECTION_READY);

    await _agoraStore.initialize(this.roomVO, size);
    if (isRoomClosed) return dispose(false);
    _onLiveStatus(LiveStatus.AGORA_ENGINE_READY);

    if (isMaster)
    {
      _masterStore = MasterStore();
      _masterStore.listenStatus(_onLiveStatus);

      await _masterStore.initialize(_peersStore, this.roomVO);
      await _agoraStore.requestRoomToken(this.roomVO);
      await _agoraStore.joinRoom(this.roomVO);

      if (isRoomClosed) return dispose(false);
      _onLiveStatus(LiveStatus.AGORA_JOIN_THE_ROOM);

      _agoraStore.announceBroadcastReady(_roomDocument);

      if (isRoomClosed) return dispose(false);
      _onLiveStatus(LiveStatus.MASTER_READY);
    }
    else
    {
      _clientStore = ClientStore();
      _clientStore.listenStatus(_onLiveStatus);
      _clientStore.initialize(_peersStore, this.roomVO);
      await _agoraStore.setTokenFromRoomDocument(_roomDocument);
      await _agoraStore.joinRoom(this.roomVO);
    }
  }

  @action
  Future<void> record() async {
    print('> LiveStore -> isRecording: $isRecording');
    return;
  }

  Future<void> dispose(bool isClosed) async {
    if (roomStatus == LiveStatus.CLOSED) return;
    try {
      roomStatus = LiveStatus.CLOSED;
      _peersStore.clean();
      if (isMaster) _roomDocument.delete();
      await _clientStore?.dispose(true);
      await _masterStore?.dispose(true);
      await _agoraStore?.dispose(true);
    } catch (e) {
      print('ERROR on dispose -> $e');
    }
    if (isClosed) _onLiveStatus(LiveStatus.DISPOSED);
    print('>>>>>>>>>>> DISPOSED');
  }
}