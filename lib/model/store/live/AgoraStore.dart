import 'dart:async';
import 'dart:ui';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_videolive/model/vo/RoomVO.dart';
import 'package:flutter_videolive/model/vo/TokenVO.dart';
import 'package:flutter_videolive/utils/settings.dart';
import 'package:mobx/mobx.dart';

import 'enum/LiveStatus.dart';
import 'mixin/LiveStatusDispatcher.dart';

part 'AgoraStore.g.dart';

class AgoraStore = _AgoraStore with _$AgoraStore;

abstract class _AgoraStore with Store, LiveStatusDispatcher {

  RtcEngine _engine;
  TokenVO tokenVO;
  int uid;

  _AgoraStore() {
    sendStatus(LiveStatus.AGORA_CREATED);
  }

  Future<void> initialize(RoomVO roomVO, Size size) async
  {
    print('> AgoraStore -> initialize: role = ${roomVO.role}');
    print('> AgoraStore -> initialize: room = ${roomVO.appId}');
    _engine = await RtcEngine.create(roomVO.appId);
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(roomVO.role);
    await _engine.enableWebSdkInteroperability(true);
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(size.width.toInt(), size.height.toInt());
    await _engine.setVideoEncoderConfiguration(configuration);
    _addAgoraEventHandlers();
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(
    cameraReady: () {
      sendStatus(LiveStatus.AGORA_CAMERA_READY);
    }, error: (ErrorCode err) {
      print('> AgoraStore -> error: ${err.toString()}');
      sendStatus(LiveStatus.AGORA_ERROR);
    }, joinChannelSuccess: (channel, uid, elapsed) {
      print('> AgoraStore -> joinChannelSuccess: uid = $uid');
      print('> AgoraStore -> joinChannelSuccess: channel = $channel');
      sendStatus(LiveStatus.AGORA_JOIN_CHANNEL_SUCCESS);
    }, leaveChannel: (stats) {
      sendStatus(LiveStatus.AGORA_LEAVE_CHANNEL);
    }, userJoined: (uid, elapsed) {
      this.uid = uid;
      print('> AgoraStore -> userJoined: uid = $uid');
      sendStatus(LiveStatus.AGORA_USER_JOINED);
    }, userOffline: (uid, elapsed) {
      sendStatus(LiveStatus.AGORA_USER_OFFLINE);
    }, firstRemoteVideoFrame: (uid, width, height, elapsed) {
      print('> AgoraStore -> firstRemoteVideoFrame: uid = $uid');
      sendStatus(LiveStatus.AGORA_FIRST_REMOTE_VIDEO_FRAME);
    }));
  }

  Future<void> joinRoom(RoomVO room) async {
    await _engine.joinChannel(
      tokenVO.value,
      room.id,
      null,
      tokenVO.uid
    );
  }

  Future<void> setTokenFromRoomDocument(DocumentReference roomDocument) async {
    final data = await roomDocument.get().then((value) => value.data());
    print('> AgoraStore -> setTokenFromRoomDocument data: ${data['token']}');
    if (data != null && data['token'] != null) {
      this.tokenVO = TokenVO.fromJSON(data['token']);
    }
  }
  
  Future<void> announceBroadcastReady(DocumentReference roomDocument) async {
    await roomDocument.set({
      'ready': true,
      'token': tokenVO.toJSON(),
      'info': //TODO: Set real user data
      {
        'name': DateTime.now().toString(), 
        'uid': RoomVO.CURRENT_USER_ID // TODO: Possible source of bugs - rewrite to use document.id
      }
    });
  }

  Future<TokenVO> requestRoomToken(RoomVO room) async
  {
    final HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
      functionName: 'liveAgoraRequestToken',
    );
    final HttpsCallableResult result = await callable.call(<String, dynamic>{
      'appId': room.appId,
      'roomId': room.id,
    });
    print('> AgoraStore -> requestRoomToken data: ${result.data}');
    sendStatus(LiveStatus.AGORA_TOKEN_RECEIVED);
    tokenVO = TokenVO.fromJSON(result.data);
    return tokenVO;
  }

  @override
  Future<void> dispose(manual) async {
    if (_engine == null) return;
    await sendStatus(LiveStatus.AGORA_DISPOSED);
    try {
      final state = await _engine.getConnectionState();
      if (state != ConnectionStateType.Disconnected)
        _engine.leaveChannel();

      _engine.destroy();
    } catch (e) {

    }
    _engine = null;
    await super.dispose(manual);
    print('>>>>>>>>>>> AGORA DISPOSED');
    return;
  }
}