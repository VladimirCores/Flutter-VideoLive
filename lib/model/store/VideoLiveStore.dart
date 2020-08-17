import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_videolive/model/vo/RoomVO.dart';
import 'package:mobx/mobx.dart';

part 'VideoLiveStore.g.dart';

enum RoomsStatus {
  CONNECTING,
  EMPTY,
  READY,
  ERROR
}

class VideoLiveStore = _VideoLiveStore with _$VideoLiveStore;

abstract class _VideoLiveStore with Store {

  final _roomsColRef = Firestore.instance.collection('rooms');
  StreamSubscription _roomsSubscription;

  @observable
  RoomVO selectedRoom;

  @observable
  RoomsStatus roomsStatus = RoomsStatus.CONNECTING;

  @observable
  List<RoomVO> rooms;

  _VideoLiveStore() {
    _roomsSubscription = _roomsColRef.snapshots().listen((QuerySnapshot rs) {
      final docs = rs.documents;
      print('> VideoLiveStore: roomsSubscription -> isEmpty: ${docs.isEmpty}');
      if (docs.isNotEmpty) {
        // TODO: Replace second param with room title
        rooms = docs.map<RoomVO>((ds) =>
            RoomVO(ds.documentID, ds.documentID)).toList();
        roomsStatus = RoomsStatus.READY;
      }
      else roomsStatus = RoomsStatus.EMPTY;
    });
    _roomsSubscription.onError((error) => roomsStatus = RoomsStatus.ERROR);
  }

  @action
  void onRoomSelected(int index) {

  }
}