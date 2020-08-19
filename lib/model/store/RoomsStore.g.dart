// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'RoomsStore.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$RoomsStore on _RoomsStore, Store {
  Computed<bool> _$hasSelectedRoomComputed;

  @override
  bool get hasSelectedRoom =>
      (_$hasSelectedRoomComputed ??= Computed<bool>(() => super.hasSelectedRoom,
              name: '_RoomsStore.hasSelectedRoom'))
          .value;

  final _$selectedRoomAtom = Atom(name: '_RoomsStore.selectedRoom');

  @override
  RoomVO get selectedRoom {
    _$selectedRoomAtom.reportRead();
    return super.selectedRoom;
  }

  @override
  set selectedRoom(RoomVO value) {
    _$selectedRoomAtom.reportWrite(value, super.selectedRoom, () {
      super.selectedRoom = value;
    });
  }

  final _$statusAtom = Atom(name: '_RoomsStore.status');

  @override
  RoomsStatus get status {
    _$statusAtom.reportRead();
    return super.status;
  }

  @override
  set status(RoomsStatus value) {
    _$statusAtom.reportWrite(value, super.status, () {
      super.status = value;
    });
  }

  final _$roomsAtom = Atom(name: '_RoomsStore.rooms');

  @override
  List<RoomVO> get rooms {
    _$roomsAtom.reportRead();
    return super.rooms;
  }

  @override
  set rooms(List<RoomVO> value) {
    _$roomsAtom.reportWrite(value, super.rooms, () {
      super.rooms = value;
    });
  }

  final _$_RoomsStoreActionController = ActionController(name: '_RoomsStore');

  @override
  void _onStatusChanged(RoomsStatus status) {
    final _$actionInfo = _$_RoomsStoreActionController.startAction(
        name: '_RoomsStore._onStatusChanged');
    try {
      return super._onStatusChanged(status);
    } finally {
      _$_RoomsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _onRoomsUpdated(List<RoomVO> list) {
    final _$actionInfo = _$_RoomsStoreActionController.startAction(
        name: '_RoomsStore._onRoomsUpdated');
    try {
      return super._onRoomsUpdated(list);
    } finally {
      _$_RoomsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void onRoomSelected(String id) {
    final _$actionInfo = _$_RoomsStoreActionController.startAction(
        name: '_RoomsStore.onRoomSelected');
    try {
      return super.onRoomSelected(id);
    } finally {
      _$_RoomsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
selectedRoom: ${selectedRoom},
status: ${status},
rooms: ${rooms},
hasSelectedRoom: ${hasSelectedRoom}
    ''';
  }
}
