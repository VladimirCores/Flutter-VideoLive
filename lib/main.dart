import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_videolive/components/pages/rooms.page.dart';
import 'package:flutter_videolive/components/widgets/SelectableList.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'components/pages/live.page.dart';
import 'components/pages/wrong.page.dart';
import 'model/store/LiveStore.dart';
import 'model/store/RoomsStore.dart';
import 'model/vo/RoomVO.dart';
import 'routes.dart';

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
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setEnabledSystemUIOverlays([]);
  runApp(MultiProvider(
    providers: [
      Provider<RoomsStore>(create: (ctx) => RoomsStore() ),
      Provider<LiveStore>(create: (ctx) => LiveStore() ),
    ],
    child: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          // Check for errors
          if (snapshot.hasError) {
            return Text('Error Connection Firebase');
          }

          // Once complete, show your application
          if (snapshot.connectionState == ConnectionState.done) {
            return VideoLiveApp();
          }

          // Otherwise, show something whilst waiting for initialization to complete
          return Container(
            width: 100,
            height: 100,
            child: CircularProgressIndicator()
          );
        },
    )
  ));
}

class VideoLiveApp extends StatelessWidget {
  final style = TextStyle(color: Colors.black, fontSize: 24.0);

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomsStore>(builder: (ct, roomsStore, _) {
      return MaterialApp(
          title: 'VideoLive',
          onGenerateRoute: (RouteSettings settings) {
            print("> Main -> onGenerateRoute: ${settings.name}");
            Widget page;
            switch (settings.name) {
              case Routes.LIVE_PAGE:
                page = LivePage(settings.arguments as RoomVO);
                break;
              default:
                page = WrongPage();
            }
            return MaterialPageRoute(builder: (context) => page);;
          },
          /* SELECT ROOM */
          home: RoomsPage()
        /* START STREAM */
//      home: LivePage(null)
        /* JOIN STREAM (ID must be real) */
//      home: LivePage(new RoomVO('tNToqwbRKhpH6hRD4dzO', 'ID'))
//      home: VideoLive(roomID:'9ufNn6h3rvVGU6yUfY0W')
      );
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

//  @override initState() { super.initState(); initRenderers(); }

//  initRenderers() async {
//    _streamVideoRenderer = RTCVideoRenderer();
//    _streamVideoRenderer.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
//    await _streamVideoRenderer.initialize();
//
//    print('> _streamVideoRenderer.textureId = ${_streamVideoRenderer.textureId}');
//    _streamVideoRenderer.mirror = true;
//
//    _isMediaReady = false;
//    _isConnected = false;
//
//    _isRoomOwner = widget.roomID == null;
//    print('> _isRoomOwner: $_isRoomOwner');
//
//    _roomDocRef = !_isRoomOwner
//        ? _roomsColRef.document(widget.roomID)
//        : _roomsColRef.document(); // Create new room
//
//    if (!mounted) return;
//
//    DocumentSnapshot roomDoc = await _roomDocRef.get();
//
//    if (_isRoomOwner)
//    {
//      roomDoc.reference.setData({ 'info': { 'name': DateTime.now().toString() } });
//      _peersColRef = _roomDocRef.collection(PEERS_COLLECTION);
//
//      if (!mounted) return;
//
//      _mediaStream = await navigator.getUserMedia(_mediaStreamConstraints);
//
//      _peersCollectionSubscription = _peersColRef.snapshots().listen((QuerySnapshot peersSnapshot) {
//        peersSnapshot.documentChanges.forEach((DocumentChange peerChange) async {
//          if (peerChange.type == DocumentChangeType.modified) return;
//
//          final document = peerChange.document;
//          final peerID = document.documentID;
//
//          print('> peers: change: ${peerChange.type} | id: ${document.documentID}');
//
//          if (peerChange.type == DocumentChangeType.removed && _peers.containsKey(peerID)) {
//            print('> peers: remove peer: $peerID');
//            _cleanPeerData(peerID);
//            _peers[peerID].pc.close();
//            _peers.remove(peerID);
//          }
//
//          if (peerChange.type == DocumentChangeType.added && !_peers.containsKey(peerID)) {
//            print('====> start new registration');
//            final peerDocRef = _peersColRef.document(peerID);
//            print('> \t1. Create RTC connection client');
//            final peerConnection = await createPeerConnection(_iceServers, {});
//            print('> \t2. Save peerID ($peerID) in a collection');
//            _peers[peerID] = VideoLivePeer(peerID, peerConnection);
//            print('> \t3. Add media stream');
//            _peers[peerID].pc.addStream(_mediaStream);
//            print('> \t4.1. Listener on ICE candidates');
//            _peers[peerID].pc.onIceCandidate = (RTCIceCandidate candidate) {
//              peerDocRef.collection(MASTER_ICE_COLLECTION).add({
//                'sdpMLineIndex': candidate.sdpMlineIndex,
//                'sdpMid': candidate.sdpMid,
//                'candidate': candidate.candidate,
//              });
//            };
//            _peers[peerID].pc.onIceConnectionState = (RTCIceConnectionState state) {
//              print('> onIceConnectionState: $state');
//            };
//            print('> \t4.2. Setup listener for client ICE collection');
//            _peers[peerID].iceSubscription = peerDocRef.collection(CLIENT_ICE_COLLECTION).snapshots().listen((QuerySnapshot iceClientSnapshot) {
//              iceClientSnapshot.documentChanges.forEach((DocumentChange iceChange) async {
//                if (iceChange.type == DocumentChangeType.added) {
//                  final candidateData = iceChange.document.data;
//                  print('> $CLIENT_ICE_COLLECTION: snapshots -> candidate added: $candidateData');
//                  final candidate = RTCIceCandidate(
//                      candidateData['candidate'],
//                      candidateData['sdpMid'],
//                      candidateData['sdpMLineIndex']
//                  );
//                  _peers[peerID].pc.addCandidate(candidate);
//                }
//              });
//            });
//            print('> \t4.3. Setup listener for answer');
//            _peers[peerID].peerDocSubscription = peerDocRef.snapshots().listen((DocumentSnapshot snapshot) async {
//              if (!snapshot.exists) { _cleanPeerData(peerID); return; }
//              final data = snapshot.data;
//              final answer = data['answer'];
//              print('> peerDocument.listen: has snapshot: ${snapshot.documentID}');
//              if (answer != null) {
//                print('> peerDocument.listen -> Got remote answer: $answer');
//                final rtcSessionDescription = RTCSessionDescription(answer['sdp'], answer['type']);
//                await _peers[peerID].pc.setRemoteDescription(rtcSessionDescription);
//              }
//            });
//            if (!mounted) return;
//            RTCSessionDescription offer = await _peers[peerID].pc.createOffer({});
//            await _peers[peerID].pc.setLocalDescription(offer);
//            await peerDocRef.updateData({
//              'offer': { 'type': offer.type, 'sdp': offer.sdp },
//            });
//          }
//        });
//      });
//      _streamVideoRenderer.srcObject = _mediaStream;
//      setState(() {
//        _isConnected = true;
//        _isMediaReady = true;
//      });
//    }
//    else
//    {
//      if (roomDoc.exists)
//      {
//        _peersColRef = _roomDocRef.collection(PEERS_COLLECTION);
//        final peerDocRef = _peersColRef.document();
//        await peerDocRef.setData({ 'info': { 'name': DateTime.now().toString() }});
//        final peerID = peerDocRef.documentID;
//
//        print('======= Join room: ${_roomDocRef.documentID}');
//        print('> \t0. Peer created: $peerID');
//
//        print('> \t1. Create peerConnection');
//        final peerConnection = await createPeerConnection(_iceServers, {});
//        print('> \t2. Save peerID ($peerID) in a collection');
//        _peers[peerID] = VideoLivePeer(peerID, peerConnection);
//        _peers[peerID].pc.onIceConnectionState = (RTCIceConnectionState state) {
//          print('> onIceConnectionState: $state');
//          if (state == RTCIceConnectionState.RTCIceConnectionStateConnected)
//            setState((){ _isConnected = true; });
//        };
//        _peers[peerID].iceSubscription = peerDocRef.collection(MASTER_ICE_COLLECTION).snapshots().listen((QuerySnapshot iceMasterSnapshot) {
//          iceMasterSnapshot.documentChanges.forEach((DocumentChange iceMasterChange) async {
//            if (iceMasterChange.type == DocumentChangeType.added) {
//              final cd = iceMasterChange.document.data;
//              print('> $MASTER_ICE_COLLECTION: snapshots -> candidate added: $cd');
//              final candidate = RTCIceCandidate(cd['candidate'], cd['sdpMid'], cd['sdpMLineIndex']);
//              _peers[peerID].pc.addCandidate(candidate);
//            }
//          });
//        });
//
//        _peers[peerID].peerDocSubscription = peerDocRef.snapshots().listen((DocumentSnapshot peerDocSnapshot) async {
//          if (!peerDocSnapshot.exists) {
//            await _closeAll();
//            widget.disconnect();
//            return;
//          }
//          final data = peerDocSnapshot.data;
//          final answer = data['answer'];
//          final offer = data['offer'];
//          print('> peerDocument.listen: has snapshot: ${peerDocSnapshot.documentID}');
//          print('> -> peer update: offer|answer (${offer!=null}|${answer!=null})');
//
//          if (offer != null && answer == null)
//          {
//            print('> \t3. Listen for media tracks');
//            _peers[peerID].pc.onAddStream = (stream) {
//              _mediaStream = stream;
//              _streamVideoRenderer.srcObject = stream;
//              print('>>> peerConnection.onAddStream');
//              setState(() { _isMediaReady = true; });
//            };
//            _peers[peerID].pc.onRemoveStream = (stream) {
//              print('>>> peerConnection.onRemoveStream');
//              _mediaStream?.dispose();
//              _streamVideoRenderer.srcObject = null;
//              setState(() { _isMediaReady = false; });
//            };
//            print('> \t4. Listener on ICE candidates');
//            _peers[peerID].pc.onIceCandidate = (RTCIceCandidate iceClientCandidate) {
//              peerDocRef.collection(CLIENT_ICE_COLLECTION).add({
//                'sdpMLineIndex': iceClientCandidate.sdpMlineIndex,
//                'sdpMid': iceClientCandidate.sdpMid,
//                'candidate': iceClientCandidate.candidate,
//              });
//            };
//            if (!mounted) return;
//            // 1. Register offer
//            print('> 5.1 Register offer: ${offer['type']}');
//            RTCSessionDescription remote = RTCSessionDescription(offer['sdp'], offer['type']);
//            await _peers[peerID].pc.setRemoteDescription(remote);
//            if (!mounted) return;
//            // 2. Register answer
//            print('> 5.2 Answer created: $peerID');
//            RTCSessionDescription answer = await _peers[peerID].pc.createAnswer({});
//            _peers[peerID].pc.setLocalDescription(answer);
//            print('> 6. Post answer to the peer document');
//            await peerDocRef.updateData({
//              'answer': { 'type': answer.type, 'sdp': answer.sdp }});
//          }
//        });
//      }
//    }
//
//    print('> _roomID: ${_roomDocRef.documentID}');
//    if (this.mounted) setState(() { _isReady = true; });
//  }

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
          child: Text('Room ID: ${_roomDocRef?.documentID}', style: TextStyle(color: Colors.white, fontSize: 12)),
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