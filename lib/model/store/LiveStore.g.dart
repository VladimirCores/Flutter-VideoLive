// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'LiveStore.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$LiveStore on _LiveStore, Store {
  Computed<bool> _$isRoomClosedComputed;

  @override
  bool get isRoomClosed =>
      (_$isRoomClosedComputed ??= Computed<bool>(() => super.isRoomClosed,
              name: '_LiveStore.isRoomClosed'))
          .value;

  final _$mediaRendererAtom = Atom(name: '_LiveStore.mediaRenderer');

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

  final _$mediaStreamAtom = Atom(name: '_LiveStore.mediaStream');

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

  final _$isRoomOwnerAtom = Atom(name: '_LiveStore.isRoomOwner');

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

  final _$roomAtom = Atom(name: '_LiveStore.room');

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

  final _$roomStatusAtom = Atom(name: '_LiveStore.roomStatus');

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

  final _$_LiveStoreActionController = ActionController(name: '_LiveStore');

  @override
  void _onMediaChanged(MediaStream mediaStream) {
    final _$actionInfo = _$_LiveStoreActionController.startAction(
        name: '_LiveStore._onMediaChanged');
    try {
      return super._onMediaChanged(mediaStream);
    } finally {
      _$_LiveStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _onRoomStatusChanged(RoomStatus status) {
    final _$actionInfo = _$_LiveStoreActionController.startAction(
        name: '_LiveStore._onRoomStatusChanged');
    try {
      return super._onRoomStatusChanged(status);
    } finally {
      _$_LiveStoreActionController.endAction(_$actionInfo);
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
