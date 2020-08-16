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
            if (snapshot.connectionState == ConnectionState.waiting) { return LinearProgressIndicator(); }
            if (!snapshot.hasData || snapshot.data.documents.length == 0) return Align(alignment: Alignment.center, child:Text("No Rooms", style: style));

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

class VideoLivePeer {
  RTCPeerConnection pc;
  StreamSubscription iceSubscription;
  StreamSubscription peerDocSubscription;
  String id;
  VideoLivePeer(this.id, this.pc);
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

  final _peers = new Map<String, VideoLivePeer>();

  StreamSubscription _peersCollectionSubscription;
  CollectionReference _peersColRef;
  DocumentReference _roomDocRef;

  MediaStream _mediaStream;

  bool _isReady = false;
  bool _isRoomOwner = false;
  bool _isMediaReady = false;
  bool _isConnected = false;

  @override initState() { super.initState(); initRenderers(); }

  initRenderers() async {
    _streamVideoRenderer = RTCVideoRenderer();
    _streamVideoRenderer.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    await _streamVideoRenderer.initialize();
    print('> _streamVideoRenderer.textureId = ${_streamVideoRenderer.textureId}');
    _streamVideoRenderer.mirror = true;

    _isMediaReady = false;
    _isConnected = false;

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
      
      _peersCollectionSubscription = _peersColRef.snapshots().listen((QuerySnapshot peersSnapshot) {
        peersSnapshot.documentChanges.forEach((DocumentChange peerChange) async {
          if (peerChange.type == DocumentChangeType.modified) return;

          final document = peerChange.document;
          final peerID = document.documentID;

          print('> peers: change: ${peerChange.type} | id: ${document.documentID}');

          if (peerChange.type == DocumentChangeType.removed && _peers.containsKey(peerID)) {
            print('> peers: remove peer: $peerID');
            _cleanPeerData(peerID);
            _peers[peerID].pc.close();
            _peers.remove(peerID);
          }

          if (peerChange.type == DocumentChangeType.added && !_peers.containsKey(peerID)) {
            print('====> start new registration');
            final peerDocRef = _peersColRef.document(peerID);
            print('> \t1. Create RTC connection client');
            final peerConnection = await createPeerConnection(_iceServers, {});
            print('> \t2. Save peerID ($peerID) in a collection');
            _peers[peerID] = VideoLivePeer(peerID, peerConnection);
            print('> \t3. Add media stream');
            _peers[peerID].pc.addStream(_mediaStream);
            print('> \t4.1. Listener on ICE candidates');
            _peers[peerID].pc.onIceCandidate = (RTCIceCandidate candidate) {
              peerDocRef.collection(MASTER_ICE_COLLECTION).add({
                'sdpMLineIndex': candidate.sdpMlineIndex,
                'sdpMid': candidate.sdpMid,
                'candidate': candidate.candidate,
              });
            };
            _peers[peerID].pc.onIceConnectionState = (RTCIceConnectionState state) {
              print('> onIceConnectionState: $state');
            };
            print('> \t4.2. Setup listener for client ICE collection');
            _peers[peerID].iceSubscription = peerDocRef.collection(CLIENT_ICE_COLLECTION).snapshots().listen((QuerySnapshot iceClientSnapshot) {
              iceClientSnapshot.documentChanges.forEach((DocumentChange iceChange) async {
                if (iceChange.type == DocumentChangeType.added) {
                  final candidateData = iceChange.document.data;
                  print('> $CLIENT_ICE_COLLECTION: snapshots -> candidate added: $candidateData');
                  final candidate = RTCIceCandidate(
                      candidateData['candidate'],
                      candidateData['sdpMid'],
                      candidateData['sdpMLineIndex']
                  );
                  _peers[peerID].pc.addCandidate(candidate);
                }
              });
            });
            print('> \t4.3. Setup listener for answer');
            _peers[peerID].peerDocSubscription = peerDocRef.snapshots().listen((DocumentSnapshot snapshot) async {
              if (!snapshot.exists) { _cleanPeerData(peerID); return; }
              final data = snapshot.data;
              final answer = data['answer'];
              print('> peerDocument.listen: has snapshot: ${snapshot.documentID}');
              if (answer != null) {
                print('> peerDocument.listen -> Got remote answer: $answer');
                final rtcSessionDescription = RTCSessionDescription(answer['sdp'], answer['type']);
                await _peers[peerID].pc.setRemoteDescription(rtcSessionDescription);
              }
            });
            if (!mounted) return;
            RTCSessionDescription offer = await _peers[peerID].pc.createOffer({});
            await _peers[peerID].pc.setLocalDescription(offer);
            await peerDocRef.updateData({
              'offer': { 'type': offer.type, 'sdp': offer.sdp },
            });
          }
        });
      });
      _streamVideoRenderer.srcObject = _mediaStream;
      setState(() {
        _isConnected = true;
        _isMediaReady = true;
      });
    }
    else
    {
      if (roomDoc.exists)
      {
        _peersColRef = _roomDocRef.collection(PEERS_COLLECTION);
        final peerDocRef = _peersColRef.document();
        await peerDocRef.setData({ 'info': { 'name': DateTime.now().toString() }});
        final peerID = peerDocRef.documentID;

        print('======= Join room: ${_roomDocRef.documentID}');
        print('> 0. Peer created: $peerID');

        print('> \t1. Create peerConnection');
        final peerConnection = await createPeerConnection(_iceServers, {});
        print('> \t2. Save peerID ($peerID) in a collection');
        _peers[peerID] = VideoLivePeer(peerID, peerConnection);
        _peers[peerID].pc.onIceConnectionState = (RTCIceConnectionState state) {
          print('> onIceConnectionState: $state');
          if (state == RTCIceConnectionState.RTCIceConnectionStateConnected)
            setState((){ _isConnected = true; });
        };
        _peers[peerID].iceSubscription = peerDocRef.collection(MASTER_ICE_COLLECTION).snapshots().listen((QuerySnapshot iceMasterSnapshot) {
          iceMasterSnapshot.documentChanges.forEach((DocumentChange iceMasterChange) async {
            if (iceMasterChange.type == DocumentChangeType.added) {
              final cd = iceMasterChange.document.data;
              print('> $MASTER_ICE_COLLECTION: snapshots -> candidate added: $cd');
              final candidate = RTCIceCandidate(cd['candidate'], cd['sdpMid'], cd['sdpMLineIndex']);
              _peers[peerID].pc.addCandidate(candidate);
            }
          });
        });

        _peers[peerID].peerDocSubscription = peerDocRef.snapshots().listen((DocumentSnapshot peerDocSnapshot) async {
          if (!peerDocSnapshot.exists) {
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
            print('> \t3. Listen for media tracks');
            _peers[peerID].pc.onAddStream = (stream) {
              _mediaStream = stream;
              _streamVideoRenderer.srcObject = stream;
              print('>>> peerConnection.onAddStream');
              setState(() { _isMediaReady = true; });
            };
            _peers[peerID].pc.onRemoveStream = (stream) {
              print('>>> peerConnection.onRemoveStream');
              _mediaStream?.dispose();
              _streamVideoRenderer.srcObject = null;
              setState(() { _isMediaReady = false; });
            };
            print('> \t4. Listener on ICE candidates');
            _peers[peerID].pc.onIceCandidate = (RTCIceCandidate iceClientCandidate) {
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
            await _peers[peerID].pc.setRemoteDescription(remote);
            if (!mounted) return;
            // 2. Register answer
            print('> 5.2 Answer created: $peerID');
            RTCSessionDescription answer = await _peers[peerID].pc.createAnswer({});
            _peers[peerID].pc.setLocalDescription(answer);
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

    var videoRenderSize = Size(_streamVideoRenderer?.width, _streamVideoRenderer?.height);

    final size = MediaQuery.of(context).size;
    final isRenderLandscape = videoRenderSize.width > videoRenderSize.height;

    videoRenderSize = _boxSizeOnLandscape(isRenderLandscape, videoRenderSize);

    print('> RENDER _isReady = $_isReady | $videoRenderSize');

    return Stack(
      children: [ Align(alignment: Alignment.center,
        child: !(_isReady && _isMediaReady && _isConnected) ? CircularProgressIndicator() :
        Container(width: size.width, height: size.height,
            child: Container(width: videoRenderSize.width, height: videoRenderSize.height,
              child: RotatedBox(quarterTurns: (isRenderLandscape) ? 0 : 1,
                child: RTCVideoView(_streamVideoRenderer),
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
      _peers.forEach((String peerID, VideoLivePeer liveVideoPeer) async {
        liveVideoPeer.pc.close();
        liveVideoPeer.iceSubscription?.cancel();
        liveVideoPeer.peerDocSubscription?.cancel();
        _cleanPeerData(peerID);
      });
      if (_isRoomOwner)
      {
        _roomDocRef.delete();
        if (_peersCollectionSubscription != null)
          _peersCollectionSubscription.cancel();
      }
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