import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  Future<void> initialize(RoomVO room, Size size) async
  {
    isMaster = room == null;

    print('> Master: $isMaster');

    if (_peersStore.isConnected(isMaster ? null : room.id)) {
      _onLiveStatus(LiveStatus.ALREADY_CONNECTED);
      return;
    }

    _onLiveStatus(LiveStatus.PREPARE);

    await [Permission.camera, Permission.microphone, Permission.storage].request();
    if (isRoomClosed) return dispose(false);
    _onLiveStatus(LiveStatus.PERMISSIONS_READY);

    final _roomsCollection = FirebaseFirestore.instance.collection('rooms');
    _roomDocument = isMaster ? _roomsCollection.doc() : _roomsCollection.doc(room.id);
    this.roomVO = isMaster ? RoomVO(_roomDocument.id, APP_ID,
        'Room Title', ClientRole.Broadcaster) : room;
    if (isRoomClosed) return dispose(false);
    _onLiveStatus(LiveStatus.ROOM_READY);

    print('> _roomDocument exists: ${(await _roomDocument.get()).exists}');

    // await Wakelock.enable();
    // if (isRoomClosed) return dispose(false);
    // _onLiveStatus(LiveStatus.WAKELOCK_ENABLED);

    await _peersStore.initialize(_roomDocument);
    if (isRoomClosed) return dispose(false);
    _onLiveStatus(LiveStatus.PEERS_COLLECTION_READY);

    await _agoraStore.initialize(roomVO, size);
    if (isRoomClosed) return dispose(false);
    _onLiveStatus(LiveStatus.AGORA_ENGINE_READY);

    if (isMaster)
    {
      _masterStore = MasterStore();
      _masterStore.listenStatus(_onLiveStatus);

      await _masterStore.initialize(_peersStore, roomVO);
      await _agoraStore.requestRoomToken(roomVO);
      await _agoraStore.joinRoom(roomVO);

      if (isRoomClosed) return dispose(false);
      _onLiveStatus(LiveStatus.AGORA_JOIN_THE_ROOM);

      await _roomDocument.set({
        'ready': true,
        'token': _agoraStore.tokenVO.toJSON()
      });

      if (isRoomClosed) return dispose(false);
      _onLiveStatus(LiveStatus.MASTER_READY);
    }
    else
    {

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
    } catch (e) {
      print('ERROR on dispose -> $e');
    }
    _onLiveStatus(LiveStatus.DISPOSED);
    print('>>>>>>>>>>> DISPOSED');
  }
}