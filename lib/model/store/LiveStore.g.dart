// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'LiveStore.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$LiveStore on _LiveStore, Store {
  final _$roomStatusAtom = Atom(name: '_LiveStore.roomStatus');

  @override
  LiveStatus get roomStatus {
    _$roomStatusAtom.reportRead();
    return super.roomStatus;
  }

  @override
  set roomStatus(LiveStatus value) {
    _$roomStatusAtom.reportWrite(value, super.roomStatus, () {
      super.roomStatus = value;
    });
  }

  final _$isMasterAtom = Atom(name: '_LiveStore.isMaster');

  @override
  bool get isMaster {
    _$isMasterAtom.reportRead();
    return super.isMaster;
  }

  @override
  set isMaster(bool value) {
    _$isMasterAtom.reportWrite(value, super.isMaster, () {
      super.isMaster = value;
    });
  }

  final _$_LiveStoreActionController = ActionController(name: '_LiveStore');

  @override
  void _onLiveStatus(LiveStatus status) {
    final _$actionInfo = _$_LiveStoreActionController.startAction(
        name: '_LiveStore._onLiveStatus');
    try {
      return super._onLiveStatus(status);
    } finally {
      _$_LiveStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
roomStatus: ${roomStatus},
isMaster: ${isMaster}
    ''';
  }
}
