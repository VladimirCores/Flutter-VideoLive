import 'dart:async';
import 'dart:ui';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_videolive/model/vo/RoomVO.dart';
import 'package:flutter_videolive/model/vo/TokenVO.dart';
import 'package:mobx/mobx.dart';

import 'enum/LiveStatus.dart';
import 'mixin/LiveStatusDispatcher.dart';

part 'AgoraStore.g.dart';

class AgoraStore = _AgoraStore with _$AgoraStore;

abstract class _AgoraStore with Store, LiveStatusDispatcher {

  RtcEngine _engine;
  TokenVO tokenVO;

  _AgoraStore() {
    sendStatus(LiveStatus.AGORA_CREATED);
  }

  Future<void> initialize(RoomVO roomVO, Size size) async
  {
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
    }, error: (code) {
      sendStatus(LiveStatus.AGORA_ERROR);
    }, joinChannelSuccess: (channel, uid, elapsed) {
      sendStatus(LiveStatus.AGORA_JOIN_CHANNEL_SUCCESS);
    }, leaveChannel: (stats) {
      sendStatus(LiveStatus.AGORA_LEAVE_CHANNEL);
    }, userJoined: (uid, elapsed) {
      sendStatus(LiveStatus.AGORA_USER_JOINED);
    }, userOffline: (uid, elapsed) {
      sendStatus(LiveStatus.AGORA_USER_OFFLINE);
    }, firstRemoteVideoFrame: (uid, width, height, elapsed) {
      sendStatus(LiveStatus.AGORA_FIRST_REMOTE_VIDEO_FRAME);
    }));
  }

  Future<void> joinRoom(RoomVO room) async {
    await _engine.joinChannel(
      tokenVO.value,
      room.id,
      null,
      0
    );
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
    sendStatus(LiveStatus.AGORA_DISPOSED);
    await super.dispose(manual);
    print('>>>>>>>>>>> AGORA DISPOSED');
    return;
  }
}