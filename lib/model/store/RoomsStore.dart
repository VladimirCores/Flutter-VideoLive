import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_videolive/model/vo/RoomVO.dart';
import 'package:mobx/mobx.dart';

part 'RoomsStore.g.dart';

enum RoomsStatus {
  CONNECTING,
  EMPTY,
  READY,
  ERROR
}

class RoomsStore = _RoomsStore with _$RoomsStore;

abstract class _RoomsStore with Store {

  final _roomsColRef = Firestore.instance.collection('rooms');
  StreamSubscription _roomsSubscription;

  bool isRoomSelected(room) { return selectedRoom == room; }
  void clearSelected() { onRoomSelected(null); }

  @observable
  RoomVO selectedRoom;

  @computed
  bool get hasSelectedRoom => selectedRoom != null;

  @observable
  RoomsStatus status = RoomsStatus.CONNECTING;

  @observable
  List<RoomVO> rooms;

  _RoomsStore() {
    _roomsSubscription = _roomsColRef.snapshots().listen((QuerySnapshot rs) {
      final docs = rs.documents;
      print('> RoomsStore: roomsSubscription -> isEmpty: ${docs.isEmpty}');
      if (docs.isNotEmpty) {
        var canRoomsBeUpdate = rooms == null || docs.length != rooms.length;
        print('> RoomsStore: roomsSubscription -> canRoomsBeUpdate: $canRoomsBeUpdate');
        if (canRoomsBeUpdate) {
          // TODO: Replace second param with room title
          _onRoomsUpdated(docs.map<RoomVO>((ds) =>
              RoomVO(ds.documentID, 'ID: ' + ds.documentID)).toList());
        }
        _onStatusChanged(RoomsStatus.READY);
      }
      else _onStatusChanged(RoomsStatus.EMPTY);
      print('> RoomsStore: roomsSubscription -> hasSelectedRoom: $hasSelectedRoom');
      if (hasSelectedRoom) onRoomSelected(selectedRoom.id);
    });
    _roomsSubscription.onError((error) => _onStatusChanged(RoomsStatus.ERROR));
  }

  @action
  void _onStatusChanged(RoomsStatus status) {
    print('> RoomsStore -> _onStatusChanged: $status');
    if (this.status != status)
      this.status = status;
  }

  @action
  void _onRoomsUpdated(List<RoomVO> list) {
    print('> RoomsStore -> _onRoomsUpdated: ${list.length}');
    rooms = list;
  }

  @action
  void onRoomSelected(String id) {
    print('> RoomsStore -> onRoomSelected: new selected room id = $id');
    final room = id != null ? rooms.singleWhere((r) => r.id == id, orElse: () => null) : null;
    if (room == null || (hasSelectedRoom && room == selectedRoom)) {
      selectedRoom = null;
    } else {
      selectedRoom = room;
    }
  }
}