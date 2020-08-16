import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_videolive/SelectableWidget.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

Map<String, dynamic> _iceServers = {
  'iceServers': [
    {'url': 'stun:stun1.l.google.com:19302'},
    {'url': 'stun:stun2.l.google.com:19302'},
    // TURN SERVER: http://numb.viagenie.ca/
//    {
//      'url': 'turn:numb.viagenie.ca',
//      'username': '****@gmail.com',
//      'credential': '****'
//    }
  ]
};

const MASTER_ICE_COLLECTION = 'callerCandidates';
const CLIENT_ICE_COLLECTION = 'calleeCandidates';
const PEERS_COLLECTION = 'peers';

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

CollectionReference _roomsColRef;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _roomsColRef = Firestore.instance.collection('rooms');
  runApp(LiveVideoApp());
}

class LiveVideoApp extends StatefulWidget {
  LiveVideoApp({Key key}) : super(key: key);
  @override
  _LiveVideoAppState createState() => _LiveVideoAppState();
}

class _LiveVideoAppState extends State<LiveVideoApp> {
  String _selectedRoomID;
  bool _connected = false;

  var style = TextStyle(color: Colors.black, fontSize: 24.0);

  void onSelected(String value) {
    print('Selected $value');
    setState(() {
      _selectedRoomID = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(body: _connected ? VideoLive(disconnect:stopStreaming, roomID:_selectedRoomID) :
        StreamBuilder<QuerySnapshot>(
          stream: _roomsColRef.snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) { return Text("Something went wrong"); }
            if (snapshot.connectionState == ConnectionState.waiting) { return Text("Loading"); }
            if (!snapshot.hasData || snapshot.data.documents.length == 0) return Text("No Rooms", style: style);

            var docs = snapshot.data.documents;
            return new ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return SelectableWidget(SelectableWidgetViewModel(
                    docs[index].documentID,
                    onSelected: onSelected,
                    isSelected: docs[index].documentID == _selectedRoomID,
                    style: style
                  ),
                );},
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: !_connected ? startStreaming : stopStreaming,
        child: Icon(!_connected ? (_selectedRoomID != null ? Icons.camera_enhance : Icons.camera) : Icons.close),
        backgroundColor: _connected ? Colors.red : Colors.blue,
      ),));
  }

  void startStreaming() {
    setState(() {
      _connected = true;
    });
  }
  
  void stopStreaming() {
    setState(() {
      _connected = false;
      _selectedRoomID = null;
    });
  }
}

class VideoLiveClient {
  MediaStream stream;
  String id;
}

class VideoLive extends StatefulWidget {
  final Function disconnect;
  final String roomID;
  VideoLive({Key key, this.disconnect, this.roomID}) : super(key: key);
  @override
  _VideoLiveState createState() => _VideoLiveState();
}

class _VideoLiveState extends State<VideoLive> {
  RTCVideoRenderer _streamVideoRenderer;

  final _peers = new Map<String, RTCPeerConnection>();

  CollectionReference _peersColRef;
  DocumentReference _roomDocRef;

  MediaStream _mediaStream;

  bool _isReady = false;
  bool _isRoomOwner = false;

  @override initState() { super.initState(); initRenderers(); }

  initRenderers() async {
    _streamVideoRenderer = RTCVideoRenderer();
    _streamVideoRenderer.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    await _streamVideoRenderer.initialize();
    _streamVideoRenderer.mirror = true;

    _isRoomOwner = widget.roomID == null;
    print('> _isRoomOwner: $_isRoomOwner');

    _roomDocRef = !_isRoomOwner
        ? _roomsColRef.document(widget.roomID)
        : _roomsColRef.document(); // Create new room

    if (!mounted) return;

    DocumentSnapshot roomDoc = await _roomDocRef.get();

    if (_isRoomOwner)
    {
      roomDoc.reference.setData({ 'info': { 'name': DateTime.now().toString() } });
      _peersColRef = _roomDocRef.collection(PEERS_COLLECTION);

      if (!mounted) return;

      _mediaStream = await navigator.getUserMedia(_mediaStreamConstraints);

      _peersColRef.snapshots().listen((QuerySnapshot peersSnapshot) {
        peersSnapshot.documentChanges.forEach((DocumentChange peerChange) async {
          if (peerChange.type == DocumentChangeType.modified) return;

          final document = peerChange.document;
          final peerID = document.documentID;

          print('> peers: change: ${peerChange.type} | id: ${document.documentID}');

          if (peerChange.type == DocumentChangeType.removed && _peers.containsKey(peerID)) {
            print('> peers: remove peer: $peerID');
            _cleanPeerData(peerID);
            _peers[peerID].close();
            _peers.remove(peerID);
          }

          if (peerChange.type == DocumentChangeType.added && !_peers.containsKey(peerID)) {
            print('====> start new registration');
            final peerDocRef = _peersColRef.document(peerID);
            print('> \t1. Create RTC connection client');
            final peerConnection = await createPeerConnection(_iceServers, {});
            print('> \t2. Save peerID ($peerID) in a collection');
            _peers[peerID] = peerConnection;
            print('> \t3. Add media stream');
            peerConnection.addStream(_mediaStream);
            print('> \t4.1. Listener on ICE candidates');
            peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
              peerDocRef.collection(MASTER_ICE_COLLECTION).add({
                'sdpMLineIndex': candidate.sdpMlineIndex,
                'sdpMid': candidate.sdpMid,
                'candidate': candidate.candidate,
              });
            };
            print('> \t4.2. Setup listener for client ICE collection');
            peerDocRef.collection(CLIENT_ICE_COLLECTION).snapshots().listen((QuerySnapshot iceClientSnapshot) {
              iceClientSnapshot.documentChanges.forEach((DocumentChange iceChange) async {
                if (iceChange.type == DocumentChangeType.added) {
                  final candidateData = iceChange.document.data;
                  print('> $CLIENT_ICE_COLLECTION: snapshots -> candidate added: $candidateData');
                  final candidate = RTCIceCandidate(
                      candidateData['candidate'],
                      candidateData['sdpMid'],
                      candidateData['sdpMLineIndex']
                  );
                  peerConnection.addCandidate(candidate);
                }
              });
            });
            print('> \t4.3. Setup listener for answer');
            var unsubscribeForAnswerListener;
            unsubscribeForAnswerListener = peerDocRef.snapshots().listen((DocumentSnapshot snapshot) async {
              if (!snapshot.exists) { unsubscribeForAnswerListener.cancel(); return; }
              final data = snapshot.data;
              final answer = data['answer'];
              print('> peerDocument.listen: has snapshot: ${snapshot.documentID}');
              if (answer != null) {
                print('> peerDocument.listen -> Got remote answer: $answer');
                final rtcSessionDescription = RTCSessionDescription(answer['sdp'], answer['type']);
                await peerConnection.setRemoteDescription(rtcSessionDescription);
                unsubscribeForAnswerListener?.cancel();
                unsubscribeForAnswerListener = null;
              }
            });
            if (!mounted) return;
            RTCSessionDescription offer = await peerConnection.createOffer({});
            await peerConnection.setLocalDescription(offer);
            await peerDocRef.updateData({
              'offer': { 'type': offer.type, 'sdp': offer.sdp },
            });
          }
        });
      });

      _streamVideoRenderer.srcObject = _mediaStream;

    } else {
      if (roomDoc.exists)
      {
        _peersColRef = _roomDocRef.collection(PEERS_COLLECTION);
        final peerDocRef = _peersColRef.document();
        await peerDocRef.setData({ 'info': { 'name': DateTime.now().toString() }});
        final peerID = peerDocRef.documentID;

        print('======= Join room: ${_roomDocRef.documentID}');
        print('> 0. Peer created: $peerID');

        peerDocRef.collection(MASTER_ICE_COLLECTION).snapshots().listen((QuerySnapshot iceMasterSnapshot) {
          iceMasterSnapshot.documentChanges.forEach((DocumentChange iceMasterChange) async {
            if (iceMasterChange.type == DocumentChangeType.added) {
              final candidateData = iceMasterChange.document.data;
              print('> $MASTER_ICE_COLLECTION: snapshots -> candidate added: $candidateData');
              final candidate = RTCIceCandidate(
                  candidateData['candidate'],
                  candidateData['sdpMid'],
                  candidateData['sdpMLineIndex']
              );
              _peers[peerID].addCandidate(candidate);
            }
          });
        });

        var unsubscribePeerDocListener;
        unsubscribePeerDocListener = peerDocRef.snapshots().listen((DocumentSnapshot peerDocSnapshot) async {
          if (!peerDocSnapshot.exists) {
            unsubscribePeerDocListener.cancel();
            await _closeAll();
            widget.disconnect();
            return;
          }
          final data = peerDocSnapshot.data;
          final answer = data['answer'];
          final offer = data['offer'];
          print('> peerDocument.listen: has snapshot: ${peerDocSnapshot.documentID}');
          print('> -> peer update: offer|answer (${offer!=null}|${answer!=null})');

          if (offer != null && answer == null)
          {
            print('> \t1. Create peerConnection');
            final peerConnection = await createPeerConnection(_iceServers, {});
            print('> \t2. Save peerID ($peerID) in a collection');
            _peers[peerID] = peerConnection;
            print('> \t3. Listen for media tracks');
            peerConnection.onAddStream = (stream) {
              _mediaStream = stream;
              _streamVideoRenderer.srcObject = stream;
              print('>>> peerConnection.onAddStream');
            };
            peerConnection.onRemoveStream = (stream) {
              _mediaStream?.dispose();
              _mediaStream = null;
              _streamVideoRenderer.srcObject = null;
            };
            print('> \t4. Listener on ICE candidates');
            peerConnection.onIceCandidate = (RTCIceCandidate iceClientCandidate) {
              peerDocRef.collection(CLIENT_ICE_COLLECTION).add({
                'sdpMLineIndex': iceClientCandidate.sdpMlineIndex,
                'sdpMid': iceClientCandidate.sdpMid,
                'candidate': iceClientCandidate.candidate,
              });
            };
            if (!mounted) return;
            // 1. Register offer
            print('> 5.1 Register offer: ${offer['type']}');
            RTCSessionDescription remote = RTCSessionDescription(offer['sdp'], offer['type']);
            await peerConnection.setRemoteDescription(remote);
            if (!mounted) return;
            // 2. Register answer
            print('> 5.2 Answer created: $peerID');
            RTCSessionDescription answer = await peerConnection.createAnswer({});
            peerConnection.setLocalDescription(answer);
            print('> 6. Post answer to the peer document');
            await peerDocRef.updateData({
              'answer': { 'type': answer.type, 'sdp': answer.sdp }});
          }
        });
      }
    }

    print('> _roomID: ${_roomDocRef.documentID}');
    if (this.mounted) setState(() { _isReady = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (_streamVideoRenderer == null) return LinearProgressIndicator();

    var fullscreenSize = Size(_streamVideoRenderer?.width, _streamVideoRenderer?.height);

    final size = MediaQuery.of(context).size;
    final isRenderLandscape = fullscreenSize.width > fullscreenSize.height;

    fullscreenSize = _boxSizeOnLandscape(isRenderLandscape, fullscreenSize);

    print('> RENDER _isReady = $_isReady | $fullscreenSize');

    return Stack(
      children: [ Align(alignment: Alignment.center, child: !(_isReady) ? CircularProgressIndicator() :
        Container(width: size.width, height: size.height,
          child: FittedBox(fit: BoxFit.fitHeight,
            child: Container(width: fullscreenSize.width, height: fullscreenSize.height,
              child: RotatedBox(quarterTurns: (isRenderLandscape && _isRoomOwner) ? 1 : 0,
                child: RTCVideoView(_streamVideoRenderer, key: UniqueKey()),
              ),
            ),
          ),
        )),
        _isReady ? Align(alignment: Alignment.center,
          child: Text('Room ID: ${_roomDocRef?.documentID}', style: TextStyle(color: Colors.white)),
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
      _mediaStream?.dispose();
      _peers.forEach((peerID, pc) async {
        _cleanPeerData(peerID);
      });
      if (_isRoomOwner)
        _roomDocRef.delete();
    }
    catch (e) { print(e); }
    print('>>>>>>>>>>> DISPOSED');
  }

  void _cleanPeerData(String peerID) async {
    final peerDocRef = _peersColRef.document(peerID);
    if (peerDocRef != null) {
      final clientICE = peerDocRef.collection(CLIENT_ICE_COLLECTION);
      if (clientICE != null) await clientICE.getDocuments()..documents.clear();
      final masterICE = peerDocRef.collection(MASTER_ICE_COLLECTION);
      if (masterICE != null) await masterICE.getDocuments()..documents.clear();
      await peerDocRef.delete();
    }
  }
}