import 'dart:async';

import 'package:flutter_videolive/model/store/live/enum/LiveStatus.dart';

import '../mixin/LiveStatusDispatcher.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:mobx/mobx.dart';

part 'MediaStore.g.dart';

const Map<String, dynamic> _DEFAULT_MEDIA_STREAM_PARAMS = {
  'audio': true,
  'video': {
    'mandatory': {
      'minWidth': '640', // Provide your own width, height and frame rate here
      'minHeight': '480',
      'minFrameRate': '30',
    },
    'facingMode': 'user',
    'optional': [],
  }
};

class MediaStore = _MediaStore with _$MediaStore;

abstract class _MediaStore with Store, LiveStatusDispatcher {

  MediaStream _mediaStream;
  MediaStream get mediaStream => _mediaStream;

  RTCVideoRenderer _mediaRenderer;
  RTCVideoRenderer get mediaRenderer => _mediaRenderer;

  bool get hasStream => _mediaStream != null;
  
  _MediaStore();

  Future<void> initialize() async {
    _mediaRenderer = RTCVideoRenderer();
    _mediaRenderer.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    await _mediaRenderer.initialize();
    _mediaRenderer.mirror = true;
  }

  Future<void> addStreamToPeer(RTCPeerConnection connection) async {
    print('> MediaStore -> addStream: hasStream = $hasStream');
    print('> MediaStore -> addStream: connection = $connection');
    if (hasStream) {
      await _mediaStream.getMediaTracks();
      _mediaStream.getVideoTracks().forEach((track) async {
        print('> \t\t: video track = ${track.kind}');
        await connection.addTrack(track, [_mediaStream.id]);
      });
      _mediaStream.getAudioTracks().forEach((track) async {
        print('> \t\t: audio track = ${track.kind}');
        await connection.addTrack(track, [_mediaStream.id]);
      });
      connection.getRemoteStreams().add(_mediaStream);
      connection.getLocalStreams().add(_mediaStream);
      await connection.addStream(_mediaStream);
    }
    else {
      sendStatus(LiveStatus.MEDIA_ERROR_NO_STREAM_TO_ADD);
      throw 'No media stream to attach to connection';
    }
  }

  Future<void> setLocalStream(MediaStream stream) async {
    
  }

  Future<void> setRemoteStream(MediaStream stream) async {
    print('> MediaStore -> setRemoteStream: can be set = ${_mediaStream != stream && _mediaRenderer != null}');
    if (_mediaStream != stream) {
      if (stream == null) _mediaStream?.dispose();

      _mediaStream = stream;

      if (_mediaRenderer != null) {
        _mediaRenderer.srcObject = stream;
      } else {
        sendStatus(LiveStatus.MEDIA_ERROR_NO_RENDERED);
        throw 'MediaRenderer is not ready';
      }
    } else {
      sendStatus(LiveStatus.MEDIA_ERROR_SAME_STREAM);
      throw 'Same stream cant be set to MediaRenderer';
    }
    sendStatus(LiveStatus.MEDIA_STORE_STREAM_SET);
    return Future.value(true);
  }

  Future<void> createStreamFromCamera({params}) async {
    var stream = await navigator.getUserMedia(_DEFAULT_MEDIA_STREAM_PARAMS);
    return setRemoteStream(stream);
  }

  @override
  void dispose(manual) {
    if (_mediaStream != null) {
      _mediaStream?.dispose();
      _mediaStream = null;
    }
    _mediaRenderer.srcObject = null;
    super.dispose(manual);
  }
}