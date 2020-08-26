mdc.ripple.MDCRipple.attachTo(document.querySelector('.mdc-button'));

// DEfault configuration - Change these if you have a different STUN or TURN server.
const configuration = {
  iceServers: [
    {
      urls: [
        'stun:stun.liveo.fr:3478',
        // 'stun:stun1.l.google.com:19302',
        // 'stun:stun2.l.google.com:19302',
        // 'stun:stun3.l.google.com:19302',
        // 'stun:stun4.l.google.com:19302',
      ],
    },
  ],
  iceCandidatePoolSize: 10,
};

const _peers = new Map();
let _isRoomOwner = false;
let _roomID;

let _mediaStream = null;

let dataChannel = null;
let isDataChannelAvailable = false;
let masterDataChannel = null;

const MASTER_ICE_COLLECTION = 'callerCandidates';
const CLIENT_ICE_COLLECTION = 'calleeCandidates';
const PEERS_COLLECTION = 'peers';

let peersCollection;

let roomDialog = null;

async function init() {
  document.querySelector('#cameraBtn').onclick = openUserMedia;
  document.querySelector('#hangupBtn').onclick = cleanUpConnection;
  document.querySelector('#createBtn').onclick = createRoom;
  document.querySelector('#joinBtn').onclick = joinRoom;
  roomDialog = new mdc.dialog.MDCDialog(document.querySelector('#room-dialog'));
  document.querySelector('#joinBtn').disabled = false;
  document.querySelector('#cameraBtn').disabled = false;
  document.querySelector('#createBtn').disabled = true;
  document.querySelector('#hangupBtn').disabled = true;
  window.document.querySelector('#peers').innerHTML = '';
  window.document.querySelector('#rooms').innerHTML = '';
  document.querySelector('#currentRoom').innerText = '';

  const db = firebase.firestore();
  const roomsCollection = db.collection('rooms');
  roomsCollection.onSnapshot(s => s.docChanges().forEach(async change => {
    const document = change.doc;
    const roomID = document.id;
    if (change.type === 'modified') return;
    else if (change.type === 'removed') {
      console.log('> Room removed:', roomID);
      let dom = window.document.querySelector('#a' + roomID);
      if (dom) dom.remove();
    }
    else if (change.type === 'added') {
      console.log('> Room added:', roomID);
      if (window.document.querySelector('#a' + roomID) == null) {
        const roomDOM = window.document.createElement('div');
        roomDOM.innerText = roomID;
        roomDOM.id = 'a' + roomID;
        window.document.querySelector('#rooms').appendChild(roomDOM);
      }
    }
  }));
}

async function createRoom() {
  document.querySelector('#createBtn').disabled = true;
  document.querySelector('#joinBtn').disabled = true;
  document.querySelector('#hangupBtn').disabled = false;

  const db = firebase.firestore();
  const roomsCollection = db.collection('rooms');
  const roomDocument = await roomsCollection.doc();
  peersCollection = roomDocument.collection(PEERS_COLLECTION);
  roomDocument.set({ info: { name: Date.now() }});

  _isRoomOwner = true;

  peersCollection.onSnapshot(s => s.docChanges().forEach(async change => {
    if (change.type === 'modified') return;

    const document = change.doc;
    const peerID = document.id;
    console.log('> peers:', "change: " + change.type, "| id:", document.id);

    if (change.type === 'removed' && _peers.has(peerID)) {
      const videoDOM = window.document.querySelector('#v' + peerID);
      if (videoDOM) {
        videoDOM.srcObject = null;
        videoDOM.remove();
      }
      window.document.querySelector('#a' + peerID).remove();
      _peers.get(peerID)?.close();
      _peers.delete(peerID);
    }

    if (change.type === 'added' && !_peers.has(peerID))
    {
      console.log(`====> start new registration`);

      const peerDocument = peersCollection.doc(peerID);
      console.log('> \t1. Create RTC connection client');
      const pc = new RTCPeerConnection(configuration);
      _peers.set(peerID, pc);

      console.log('> \t2. Save in a collections of connections');

      const peerDOM = window.document.createElement('div');
      peerDOM.innerText = peerID;
      peerDOM.id = 'a' + peerID;
      window.document.querySelector('#peers').appendChild(peerDOM);

      console.log('> \t3. Has media stream: ' + (_mediaStream != null));
      if (_mediaStream != null) {
        _mediaStream.getTracks().forEach(t => { pc.addTrack(t, _mediaStream); });
        console.log('> \t3.1. Attach _mediaStream tracks to connection');
      }
      const remoteStream = new MediaStream();
      const videosDOM = window.document.querySelector('#videos');
      const remoteVideoDOM = window.document.createElement('video');
      remoteVideoDOM.id = 'v' + peerID;
      remoteVideoDOM.autoplay = true;
      remoteVideoDOM.playsinline = true;
      remoteVideoDOM.srcObject = remoteStream;
      videosDOM.appendChild(remoteVideoDOM);
      pc.ontrack = e => {
        console.log('>> Got track: ', e.streams[0]);
        e.streams[0].getTracks().forEach(t => { remoteStream.addTrack(t); });
      };
      pc.onicecandidateerror = e => console.log('>> ICE error: ', e);
      pc.onconnectionstatechange = e => console.log('>> ICE connection: ', e);
      pc.onicecandidate = event => {
        if (!event.candidate) return;
        console.log('>> Got ICE: ', event.candidate.foundation);
        peersCollection.doc(peerID).collection(MASTER_ICE_COLLECTION)
          .add(event.candidate.toJSON());
      };
      console.log('> \t4.1. Listener on ICE registered was added');
      peersCollection.doc(peerID).collection(CLIENT_ICE_COLLECTION)
        .onSnapshot(s => s.docChanges().forEach(async ch => {
          if (ch.type === 'added') {
            const clientIceCandidate = new RTCIceCandidate(ch.doc.data());
            console.log('\t >> Add client ICE: ', clientIceCandidate.foundation);
            await pc.addIceCandidate(clientIceCandidate);
          }
        }));

      const unsubscribeForAnswerListener = peerDocument.onSnapshot(async s => {
        if (!s.exists) { unsubscribeForAnswerListener(); return; }
        const answer = s.data().answer;
        console.log('> -> peerDocument update: answer = ', (!!answer));
        if (answer) {
          console.log('> \t6. Answer received: peerID = ' + peerID);
          if (!pc.currentRemoteDescription) {
            console.log('> \t7. Add answer descriptor');
            const answerDescriptor = new RTCSessionDescription(answer);
            await pc.setRemoteDescription(answerDescriptor);
            // console.log('> \t8. Unsubscribe from client answer');
            // unsubscribeForAnswerListener();
          }
        }
      });

      console.log('> \t4.2. Setup listener for answer');
      // 5. Post offer for peerID
      const offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      console.log('> \t5. Post offer for:', peerID);
      await peerDocument.update({
        offer: { type: offer.type,  sdp: offer.sdp }
      });
    }
  }, e => { console.error(e); }));

  _roomID = roomDocument.id;
  console.log(`New room created with SDP offer. Room ID: ${roomDocument.id}`);
  document.querySelector('#currentRoom').innerText = `Current room is ${roomDocument.id} - You are the caller!`;
}

function joinRoom() {
  document.querySelector('#createBtn').disabled = true;
  document.querySelector('#joinBtn').disabled = true;
  document.querySelector('#hangupBtn').disabled = false;

  document.querySelector('#confirmJoinBtn').addEventListener('click', async () => {
      const roomId = document.querySelector('#room-id').value;
      document.querySelector('#currentRoom').innerText = `Current room is ${roomId} - You are the callee!`;
      await joinRoomById(roomId);
    }, {once: true});
  roomDialog.open();
}

async function joinRoomById(rid) {
  const db = firebase.firestore();
  const roomDocRef = db.collection('rooms').doc(`${rid}`);
  const roomDocSnapshot = await roomDocRef.get();

  if (roomDocSnapshot.exists) {
    peersCollection = roomDocRef.collection(PEERS_COLLECTION);

    _roomID = rid;
    _isRoomOwner = false;

    const peerDocRef = peersCollection.doc();
    await peerDocRef.set({ info: { name: Date.now() }});
    const peerID = peerDocRef.id;

    console.log(`======= Join room: ${rid}`);
    console.log(`> 0. Peer created: ${peerID}`);

    peerDocRef.onSnapshot(async s => {
      if (!s.exists) { await cleanUpConnection(null); return; }

      const data = s.data();
      const offer = data.offer;
      const answer = data.answer;

      console.log(`> -> peer update: offer|answer (${!!offer}|${!!answer})`);

      if (offer && !answer)
      {
        const pc = new RTCPeerConnection(configuration);
        _peers.set(peerID, pc);

        peerDocRef.collection(MASTER_ICE_COLLECTION)
        .onSnapshot(s => s.docChanges().forEach(async ch => {
          if (ch.type === 'added') {
            const masterIceCandidate = new RTCIceCandidate(ch.doc.data());
            console.log('>> Got master ICE: ', masterIceCandidate.foundation);
            await pc.addIceCandidate(masterIceCandidate);
          }
        }));

        console.log('> 1. Client created and listened for ICE');
        pc.onicecandidateerror = e => console.log('>> ICE error: ', e);
        pc.onicecandidate = e => {
          if (!e.candidate) { console.log('>> Got final candidate!'); return; }
          console.log('>> \t Got client ICE: ', e.candidate.foundation);
          peerDocRef.collection(CLIENT_ICE_COLLECTION).add(e.candidate.toJSON());
        };
        _peers.set(peerID, pc);
        console.log('> 2. Set new remote MediaStream');
        const remoteStream = new MediaStream();
        pc.onconnectionstatechange = e => console.log('>> ICE connection: ', e);
        pc.ontrack = e => {
          console.log('>> Got track');
          e.streams[0].getTracks().forEach(t => { remoteStream.addTrack(t); });
        };
        if (_mediaStream != null) {
          _mediaStream.getTracks().forEach(t => { pc.addTrack(t, _mediaStream); });
          console.log('> \t2.1. Attach _mediaStream tracks to connection');
          const videosDOM = window.document.querySelector('#videos');
          const remoteVideoDOM = window.document.createElement('video');
          remoteVideoDOM.id = 'v' + peerID;
          remoteVideoDOM.autoplay = true;
          remoteVideoDOM.playsinline = true;
          remoteVideoDOM.srcObject = remoteStream;
          videosDOM.appendChild(remoteVideoDOM);
        } else {
          document.querySelector('#video').srcObject = remoteStream;
        }
        console.log('> 3. Answer created:', peerID);
        const remoteDescription = new RTCSessionDescription(offer);
        await pc.setRemoteDescription(remoteDescription);
        const answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        console.log('> 4. Post answer to the peer document');
        await peerDocRef.update({
          answer: { type: answer.type, sdp: answer.sdp }
        });
      }
    });
  } // roomSnapshot.exists
}

async function openUserMedia(e) {
  _mediaStream = await navigator.mediaDevices.getUserMedia(
      {video: true, audio: true});
  document.querySelector('#video').srcObject = _mediaStream;
  document.querySelector('#joinBtn').disabled = false;
  document.querySelector('#cameraBtn').disabled = true;
  document.querySelector('#createBtn').disabled = false;
  document.querySelector('#hangupBtn').disabled = false;
}

async function cleanUpConnection() {
  if (_mediaStream != null) {
    _mediaStream.getTracks().forEach(t => {t.stop();});
  }

  if (_roomID) {
    const db = firebase.firestore();
    const roomDocRef = db.collection('rooms').doc(_roomID);
    const peersColRef = roomDocRef.collection(PEERS_COLLECTION);
    // Delete room on hangup
    console.log('> peers: ' + _peers.size, _peers.keys());
    for (let key of _peers.keys()) {
      await clearPeer(peersColRef, key);
      const videoDOM = window.document.querySelector('#v' + key);
      if (videoDOM) {
        videoDOM.srcObject = null;
        videoDOM.remove();
      }
      _peers.get(key)?.close();
    }
    _peers.clear();

    if (_isRoomOwner) {
      await roomDocRef.delete();
    }
  }

  document.querySelector('#video').srcObject = null;
  document.querySelector('#rooms').innerHTML = '';
  init();
}

async function clearPeer(peersColRef, peerID) {
  const peerDocRef = await peersColRef.doc(peerID);
  if (peerDocRef) {
    const clientICE = await peerDocRef.collection(CLIENT_ICE_COLLECTION).get();
    const masterICE = await peerDocRef.collection(MASTER_ICE_COLLECTION).get();
    if (clientICE)
      clientICE.forEach(candidate => { candidate.ref.delete(); });
    if (masterICE)
      masterICE.forEach(candidate => { candidate.ref.delete(); });
    peerDocRef.delete();
  }
}

function send(message) {
  console.log('> Sending message : ' + message);
  if (isDataChannelAvailable) {
    if (dataChannel != null)
      dataChannel.send(message);
    if (masterDataChannel != null)
      masterDataChannel.send(message)
  }
}

window.send = send;

// function registerPeerConnectionListeners() {
//   pc.addEventListener('icegatheringstatechange', () => {
//     console.log(
//         `ICE gathering state changed: ${pc.iceGatheringState}`);
//   });
//
//   pc.addEventListener('connectionstatechange', () => {
//     console.log(`Connection state change: ${pc.connectionState}`);
//   });
//
//   pc.addEventListener('signalingstatechange', () => {
//     console.log(`Signaling state change: ${pc.signalingState}`);
//   });
//
//   pc.addEventListener('iceconnectionstatechange ', () => {
//     console.log(
//         `ICE connection state change: ${pc.iceConnectionState}`);
//   });
// }
window.onload = () => {
  init();
};

