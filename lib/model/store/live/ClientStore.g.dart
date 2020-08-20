// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ClientStore.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$ClientStore on _ClientStore, Store {
  Computed<bool> _$isRoomClosedComputed;

  @override
  bool get isRoomClosed =>
      (_$isRoomClosedComputed ??= Computed<bool>(() => super.isRoomClosed,
              name: '_ClientStore.isRoomClosed'))
          .value;

  final _$mediaRendererAtom = Atom(name: '_ClientStore.mediaRenderer');

  @override
  RTCVideoRenderer get mediaRenderer {
    _$mediaRendererAtom.reportRead();
    return super.mediaRenderer;
  }

  @override
  set mediaRenderer(RTCVideoRenderer value) {
    _$mediaRendererAtom.reportWrite(value, super.mediaRenderer, () {
      super.mediaRenderer = value;
    });
  }

  final _$mediaStreamAtom = Atom(name: '_ClientStore.mediaStream');

  @override
  MediaStream get mediaStream {
    _$mediaStreamAtom.reportRead();
    return super.mediaStream;
  }

  @override
  set mediaStream(MediaStream value) {
    _$mediaStreamAtom.reportWrite(value, super.mediaStream, () {
      super.mediaStream = value;
    });
  }

  final _$isRoomOwnerAtom = Atom(name: '_ClientStore.isRoomOwner');

  @override
  bool get isRoomOwner {
    _$isRoomOwnerAtom.reportRead();
    return super.isRoomOwner;
  }

  @override
  set isRoomOwner(bool value) {
    _$isRoomOwnerAtom.reportWrite(value, super.isRoomOwner, () {
      super.isRoomOwner = value;
    });
  }

  final _$roomAtom = Atom(name: '_ClientStore.room');

  @override
  RoomVO get room {
    _$roomAtom.reportRead();
    return super.room;
  }

  @override
  set room(RoomVO value) {
    _$roomAtom.reportWrite(value, super.room, () {
      super.room = value;
    });
  }

  final _$roomStatusAtom = Atom(name: '_ClientStore.roomStatus');

  @override
  RoomStatus get roomStatus {
    _$roomStatusAtom.reportRead();
    return super.roomStatus;
  }

  @override
  set roomStatus(RoomStatus value) {
    _$roomStatusAtom.reportWrite(value, super.roomStatus, () {
      super.roomStatus = value;
    });
  }

  final _$_ClientStoreActionController = ActionController(name: '_ClientStore');

  @override
  void _onMediaChanged(MediaStream mediaStream) {
    final _$actionInfo = _$_ClientStoreActionController.startAction(
        name: '_ClientStore._onMediaChanged');
    try {
      return super._onMediaChanged(mediaStream);
    } finally {
      _$_ClientStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _onRoomStatusChanged(RoomStatus status) {
    final _$actionInfo = _$_ClientStoreActionController.startAction(
        name: '_ClientStore._onRoomStatusChanged');
    try {
      return super._onRoomStatusChanged(status);
    } finally {
      _$_ClientStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
mediaRenderer: ${mediaRenderer},
mediaStream: ${mediaStream},
isRoomOwner: ${isRoomOwner},
room: ${room},
roomStatus: ${roomStatus},
isRoomClosed: ${isRoomClosed}
    ''';
  }
}
