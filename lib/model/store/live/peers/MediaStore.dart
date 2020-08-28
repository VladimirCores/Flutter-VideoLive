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

  MediaStream _localStream;
  MediaStream get localStream => _localStream;

  RTCVideoRenderer _mediaRenderer;
  RTCVideoRenderer get mediaRenderer => _mediaRenderer;

  bool get hasLocalStream => _localStream != null;
  bool get hasMediaRendererStream => _mediaRenderer != null && _mediaRenderer.src != null;
  
  _MediaStore();

  Future<void> initialize() async {
    _mediaRenderer = RTCVideoRenderer();
    _mediaRenderer.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    await _mediaRenderer.initialize();
    _mediaRenderer.mirror = true;
  }

  Future<void> addLocalStreamToPeer(RTCPeerConnection connection) async {
    print('> MediaStore -> addStream: hasStream = $hasLocalStream');
    print('> MediaStore -> addStream: connection = $connection');
    if (hasLocalStream) {
      final localStreamId = [_localStream.id];
      await _localStream.getMediaTracks();
      _localStream.getVideoTracks().forEach((track) async {
        print('> \t\t: add track = ${track.kind}');
        await connection.addTrack(track, localStreamId);
      });
      _localStream.getAudioTracks().forEach((track) async {
        print('> \t\t: add track = ${track.kind}');
        await connection.addTrack(track, localStreamId);
      });
    }
    else {
      sendStatus(LiveStatus.MEDIA_ERROR_NO_STREAM_TO_ADD);
      throw 'No media stream to attach to connection';
    }
  }

  Future<void> setLocalStream(MediaStream stream) async {
    print('> MediaStore -> setLocalStream: can be set = ${_localStream != stream}');
    if (_localStream != stream) {
      if (stream == null) _localStream?.dispose();
      _localStream = stream;
    } else {
      sendStatus(LiveStatus.MEDIA_ERROR_SAME_STREAM);
      throw 'Same stream cant be set to MediaRenderer';
    }
  }

  Future<void> setMediaRendererStream(MediaStream stream) async {
    print('> MediaStore -> setMediaRendererStream: can be set = ${_mediaRenderer != null}');
    if (_mediaRenderer != null) {
      _mediaRenderer.srcObject = stream;
    } else {
      sendStatus(LiveStatus.MEDIA_REMOTE_STREAM_ERROR_NO_RENDERED);
      throw 'MediaRenderer is not initialized';
    }
    sendStatus(LiveStatus.MEDIA_RENDER_STREAM_SET);
  }

  Future<void> createLocalStreamFromCamera({params}) async {
    var stream = await navigator.getUserMedia(_DEFAULT_MEDIA_STREAM_PARAMS);
    return setLocalStream(stream);
  }

  @override
  Future<void> dispose(manual) async {
    if (_localStream != null) {
      await _localStream?.dispose();
      _localStream = null;
    }
    if (_mediaRenderer != null) {
      try {
        if (_mediaRenderer.src != null) {
          await _mediaRenderer.src.dispose();
          _mediaRenderer.srcObject = null;
        }
      } catch (e) { }
      _mediaRenderer = null;
    }
    await super.dispose(manual);
    return;
  }
}