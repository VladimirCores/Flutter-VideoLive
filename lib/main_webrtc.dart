import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> _iceServers = {
  'iceServers': [
    {'url': 'stun:stun1.l.google.com:19302'},
    {'url': 'stun:stun2.l.google.com:19302'},
  ]
};

final Map<String, dynamic> _mediaStreamConstraints = {
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

CollectionReference _roomsCollectionRef;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
//  await Firestore.instance.settings(
//      host: "127.0.0.1:6006",
//      sslEnabled: false,
//      persistenceEnabled: false
//  );
  _roomsCollectionRef = Firestore.instance.collection('rooms');
  runApp(LiveVideoApp());
}

class LiveVideoApp extends StatefulWidget {
  LiveVideoApp({Key key}) : super(key: key);
  @override
  _LiveVideoAppState createState() => _LiveVideoAppState();
}

class _LiveVideoAppState extends State<LiveVideoApp> {
  String _selectedRoomID;
  bool _startConnect = false;

  var style = TextStyle(color: Colors.white, fontSize: 24.0);

  void onSelected(String value) {
    print('Selected $value');
    if (_selectedRoomID != value)
      _selectedRoomID = value;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(body: _startConnect ? VideoLive(reInit:reInit, roomID:_selectedRoomID) :
        StreamBuilder<QuerySnapshot>(
          stream: _roomsCollectionRef.snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text("Something went wrong");
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text("Loading");
            }

            if (!snapshot.hasData) return Text("No Rooms", style: style);

            var docs = snapshot.data.documents;
            return new ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return new SelectableWidget(
                  new SelectableWidgetViewModel(
                    docs[index].documentID,
                    onSelected: onSelected,
                    isSelected: false,
                    style: style
                  ),
                );},
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: reInit,
        child: Icon(!_startConnect ? Icons.camera_enhance : Icons.close),
        backgroundColor: _startConnect ? Colors.red : Colors.blue,
      ),));
  }

  void reInit() {
    setState(() { _startConnect = !_startConnect; });
  }
}

class VideoLive extends StatefulWidget {
  final Function reInit;
  final String roomID;
  VideoLive({Key key, this.reInit, this.roomID}) : super(key: key);
  @override
  _VideoLiveState createState() => _VideoLiveState();
}

class _VideoLiveState extends State<VideoLive> {
  RTCVideoRenderer _rtcFullScreenRenderer;
  RTCVideoRenderer _rtcPreviewRenderer;

  RTCPeerConnection _rtcRemotePeerConnection;

  StreamSubscription _roomCollectionRefScream;
  StreamSubscription _callerCandidatesCollectionScream;
  StreamSubscription _calleeCandidatesCollectionScream;
  StreamSubscription _roomReferenceSnapshotsScream;
  DocumentReference _roomDocumentReference;

  MediaStream _remoteMediaStream;
  MediaStream _localMediaStream;

  bool _isReady = false;
  bool _isUserRoomOwner = false;
  bool _isPreviewReady = false;
  bool _isFullScreenReady = false;
  bool _isRemoteConfigSet = false;

  initRenderers() async {
    _rtcFullScreenRenderer = RTCVideoRenderer();
    _rtcPreviewRenderer = RTCVideoRenderer();

    await _rtcPreviewRenderer.initialize();
    await _rtcFullScreenRenderer.initialize();

    _rtcFullScreenRenderer.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;

    _isUserRoomOwner = widget.roomID == null;
    _roomDocumentReference = !_isUserRoomOwner ?
      _roomsCollectionRef.document(widget.roomID) : _roomsCollectionRef.document();

    DocumentSnapshot room = await _roomDocumentReference.get();

    final calleeCollection = _roomDocumentReference.collection('calleeCandidates');
    final callerCollection = _roomDocumentReference.collection('callerCandidates');

    _localMediaStream = await navigator.getUserMedia(_mediaStreamConstraints);
    _rtcFullScreenRenderer.mirror = true;
    _rtcPreviewRenderer.mirror = true;

    if (!mounted) return;

    _rtcRemotePeerConnection = await createPeerConnection(_iceServers, {});

    _isRemoteConfigSet = false;
    _isFullScreenReady = false;
    _isPreviewReady = false;

    print('_isUserRoomOwner $_isUserRoomOwner');

    if (_isUserRoomOwner) {
      _isFullScreenReady = true;
      _rtcRemotePeerConnection.addStream(_localMediaStream);

      _rtcRemotePeerConnection.onAddStream = (stream) {
        print('> _rtcLocalVideoRenderer.onAddStream -> stream = ${stream.ownerTag == _localMediaStream.ownerTag}');
        _rtcPreviewRenderer.srcObject = stream;
      };
      _rtcRemotePeerConnection.onRemoveStream = (stream) {
        _rtcPreviewRenderer.srcObject = null;
      };
      _rtcRemotePeerConnection.onIceCandidate = (RTCIceCandidate candidate) {
        callerCollection.add({
          'sdpMLineIndex': candidate.sdpMlineIndex,
          'sdpMid': candidate.sdpMid,
          'candidate': candidate.candidate,
        });
      };

      RTCSessionDescription offer = await _rtcRemotePeerConnection.createOffer({});

      await _rtcRemotePeerConnection.setLocalDescription(offer);

      final roomWithOffer = {
        'offer': {
          'type': offer.type,
          'sdp': offer.sdp,
        },
      };
      await _roomDocumentReference.setData(roomWithOffer);

      _roomReferenceSnapshotsScream = _roomDocumentReference.snapshots().listen((DocumentSnapshot snapshot) async {
        final data = snapshot.data;
        print('> roomReference.listen: has snapshot: ${snapshot.documentID}');
        if (!_isRemoteConfigSet && data != null && data['answer'] != null) {
          print('> roomReference.listen -> Got remote answer: ${data['answer']}');
          final answer = data['answer'];
          final rtcSessionDescription = RTCSessionDescription(answer['sdp'], answer['type']);
          await _rtcRemotePeerConnection.setRemoteDescription(rtcSessionDescription);
          _roomReferenceSnapshotsScream?.cancel();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (this.mounted) setState(() { _isRemoteConfigSet = true; });
          });
        }
      });

      _calleeCandidatesCollectionScream = calleeCollection.snapshots().listen((QuerySnapshot snapshot) {
        print('> calleeCollection: snapshots -> snapshot.documents.length = ${snapshot.documents.length}');
        snapshot.documentChanges.forEach((change) async {
          if (change.type == DocumentChangeType.added) {
            final candidateData = change.document.data;
            print('> calleeCollection: snapshots -> DocumentChangeType.added = ${candidateData}');
            final candidate = RTCIceCandidate(
                candidateData['candidate'],
                candidateData['sdpMid'].toString(),
                candidateData['sdpMLineIndex']
            );
            _rtcRemotePeerConnection.addCandidate(candidate);
            _calleeCandidatesCollectionScream?.cancel();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (this.mounted) setState(() { _isPreviewReady = true; });
            });
          }
        });
      });

      print('> _roomID: $widget.roomID');

    } else {
      print('> existing _roomID: ${widget.roomID}');
      print('> room.documentID: ${room.documentID}');
      print('> roomSnapshot.exists: ${room.data}');
      if (room.exists) {

        final offer = room.data['offer'];

        _rtcPreviewRenderer.srcObject = _localMediaStream;
        _isPreviewReady = true;

        _rtcRemotePeerConnection.addStream(_localMediaStream);
        _rtcRemotePeerConnection.onIceCandidate = (RTCIceCandidate candidate) {
          print('> _rtcRemotePeerConnection.onIceCandidate -> candidate.sdpMlineIndex = ${candidate.sdpMlineIndex}');
          calleeCollection.add({
            'sdpMLineIndex': candidate.sdpMlineIndex,
            'sdpMid': candidate.sdpMid,
            'candidate': candidate.candidate,
          });
        };
        _rtcRemotePeerConnection.onAddStream = (stream) {
          print('> _rtcRemotePeerConnection.onAddStream -> stream = ${stream.ownerTag == _localMediaStream.ownerTag}');
          _rtcFullScreenRenderer.srcObject = stream;
        };
        _rtcRemotePeerConnection.onRemoveStream = (stream) {
          _rtcFullScreenRenderer.srcObject = null;
        };

        if (!mounted) return;
        // 1. Register offer
        RTCSessionDescription remote = RTCSessionDescription(offer['sdp'], offer['type']);
        await _rtcRemotePeerConnection.setRemoteDescription(remote);

        // 2. Register answer
        RTCSessionDescription answer = await _rtcRemotePeerConnection.createAnswer({});
        _rtcRemotePeerConnection.setLocalDescription(answer);

        if (!mounted) return;
        // 3. Send room answer
        final roomWithAnswer = { 'answer': { 'type': answer.type, 'sdp': answer.sdp }};
        await _roomDocumentReference.updateData(roomWithAnswer);

        // 4. Listening for remote ICE candidates
        _callerCandidatesCollectionScream = callerCollection.snapshots().listen((QuerySnapshot snapshot) {
          print('> callerCandidates: snapshots -> snapshot.documents.length = ${snapshot.documents.length}');
          snapshot.documentChanges.forEach((change) async {
            if (change.type == DocumentChangeType.added) {
              final candidateData = change.document.data;
              print('> callerCandidates: snapshots -> DocumentChangeType.added = ${candidateData}');
              final candidate = RTCIceCandidate(
                  candidateData['candidate'],
                  candidateData['sdpMid'].toString(),
                  candidateData['sdpMLineIndex']
              );
              _rtcRemotePeerConnection.addCandidate(candidate);
              _callerCandidatesCollectionScream?.cancel();
              setState(() { _isFullScreenReady = true; });
            }
          });
        });
      }
    }

    _roomCollectionRefScream = _roomsCollectionRef.snapshots().listen(
      (QuerySnapshot snapshot) {
        snapshot.documentChanges.forEach((change) async {
          print('> change -> ${change.type} - ${change.document.documentID}');
          if (change.type == DocumentChangeType.removed && change.document.documentID == _roomDocumentReference.documentID) {
            _closeAll();
            if (this.mounted) {
              setState(() {});
              widget.reInit();
            }
          }
        });
    });

    if (this.mounted) setState(() { _isReady = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (_rtcFullScreenRenderer == null || _rtcPreviewRenderer == null) return LinearProgressIndicator();

    var fullscreenSize = Size(_rtcFullScreenRenderer?.width, _rtcFullScreenRenderer?.height);
    var previewSize = Size(_rtcPreviewRenderer?.width, _rtcPreviewRenderer?.height);

    final size = MediaQuery.of(context).size;
    final isRenderLandscape = fullscreenSize.width > fullscreenSize.height;
    final isPreviewLandscape = previewSize.width > previewSize.height;

    fullscreenSize = _boxSizeOnLandscape(isRenderLandscape, fullscreenSize);
    previewSize = _boxSizeOnLandscape(isPreviewLandscape, previewSize);

    final previewBoxWidth = size.width * 0.3;
    final previewBoxHeight = previewBoxWidth * previewSize.aspectRatio;

    print('> RENDER ${_isFullScreenReady} ${_isPreviewReady} $fullscreenSize ${previewSize}');

    return Stack(
      children: [ !(_isReady || _isFullScreenReady) ? Align(alignment: Alignment.center, child: CircularProgressIndicator()) :
        Container(width: size.width, height: size.height,
          child: FittedBox(fit: BoxFit.fitHeight,
            child: Container(width: fullscreenSize.width, height: fullscreenSize.height,
              child: RotatedBox(quarterTurns: (isRenderLandscape && _isUserRoomOwner) ? 1 : 0,
                child: RTCVideoView(_rtcFullScreenRenderer, key: UniqueKey()),
              ),
            ),
          ),
        ),
        !_isPreviewReady ? Container() :
        Padding(padding: EdgeInsets.all(16),
          child: Align(alignment: Alignment.bottomLeft,
            child: Container(width: previewBoxWidth, height: previewBoxHeight,
                child: FittedBox( fit: BoxFit.fitHeight,
                    child: Container( width: previewSize.width, height: previewSize.height,
                        child: RotatedBox(quarterTurns: (isPreviewLandscape && !_isUserRoomOwner) ? 1 : 0,
                            child: RTCVideoView(_rtcPreviewRenderer, key: UniqueKey())))),
//                decoration: BoxDecoration(shape: BoxShape.rectangle, color: Colors.black12),
              ),
          ),
        ),
        _isReady ? Center(child:
          Text('Room ID: ${widget.roomID}', style: TextStyle(color: Colors.red)),
        ) : Container()
      ],
    );
  }

  Size _boxSizeOnLandscape(bool isLandscape, Size originalSize) {
    final w = isLandscape ? originalSize.width : originalSize.height;
    final h = !isLandscape ? originalSize.width : originalSize.height;
    return Size(w, h);
  }

  @override
  void dispose() async {
    super.dispose();
    await _closeAll();
  }

  _closeAll() async {
    try {
      _remoteMediaStream?.dispose();
      _localMediaStream?.dispose();

      _callerCandidatesCollectionScream?.cancel();
      _calleeCandidatesCollectionScream?.cancel();
      _roomCollectionRefScream?.cancel();
      _roomReferenceSnapshotsScream?.cancel();

      _rtcRemotePeerConnection?.close();
      _rtcRemotePeerConnection?.dispose();

      if (_isUserRoomOwner)
        _roomDocumentReference.delete();
    }
    catch (e) { print(e); }
    _isRemoteConfigSet = false;
    print('>>>>>>>>>>> DISPOSED');
  }

  @override
  initState() {
    super.initState();
    initRenderers();
  }
}

class SelectableWidget extends StatefulWidget {
  final SelectableWidgetViewModel viewModel;

  SelectableWidget(this.viewModel);

  @override
  State<StatefulWidget> createState() {
    return SelectableWidgetState();
  }
}

class SelectableWidgetState extends State<SelectableWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Container container;

    if (widget.viewModel.isSelected) {
      container = new Container(
        alignment: Alignment.center,
        height: 100.0,
        color: Colors.green,
        child: new Text(
          widget.viewModel.title,
          textAlign: TextAlign.center,
          style: widget.viewModel.style,
        ),
      );
    } else {
      container = new Container(
        alignment: Alignment.center,
        height: 100.0,
        color: Colors.blue,
        child: new Text(
          widget.viewModel.title,
          textAlign: TextAlign.center,
          style: widget.viewModel.style,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          widget.viewModel.isSelected = !widget.viewModel.isSelected;
          widget.viewModel.onSelected(widget.viewModel.title);
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: container,
      ),
    );
  }
}

typedef void OnSelected(String value);

class SelectableWidgetViewModel {
  bool isSelected;
  String title;
  TextStyle style;
  OnSelected onSelected;

  SelectableWidgetViewModel(this.title, {this.isSelected = false, this.style, this.onSelected});
}