mdc.ripple.MDCRipple.attachTo(document.querySelector('.mdc-button'));

// DEfault configuration - Change these if you have a different STUN or TURN server.
const configuration = {
  iceServers: [
    {
      urls: [
        'stun:stun.liveo.fr:3478',
         'stun:stun1.l.google.com:19302',
         'stun:stun2.l.google.com:19302',
         'stun:stun3.l.google.com:19302',
         'stun:stun4.l.google.com:19302',
         'stun:stun.12connect.com:3478',
         'stun:stun.12voip.com:3478',
         'stun:stun.1und1.de:3478',
         'stun:stun.2talk.co.nz:3478',
         'stun:stun.2talk.com:3478',
         'stun:stun.3clogic.com:3478',
         'stun:stun.3cx.com:3478',
         'stun:stun.a-mm.tv:3478',
         'stun:stun.aa.net.uk:3478',
         'stun:stun.acrobits.cz:3478',
         'stun:stun.actionvoip.com:3478',
         'stun:stun.advfn.com:3478',
         'stun:stun.aeta-audio.com:3478',
         'stun:stun.aeta.com:3478',
         'stun:stun.alltel.com.au:3478',
         'stun:stun.altar.com.pl:3478',
         'stun:stun.annatel.net:3478',
         'stun:stun.antisip.com:3478',
         'stun:stun.arbuz.ru:3478',
         'stun:stun.avigora.com:3478',
         'stun:stun.avigora.fr:3478',
         'stun:stun.awa-shima.com:3478',
         'stun:stun.awt.be:3478',
         'stun:stun.b2b2c.ca:3478',
         'stun:stun.bahnhof.net:3478',
         'stun:stun.barracuda.com:3478',
         'stun:stun.bluesip.net:3478',
         'stun:stun.bmwgs.cz:3478',
         'stun:stun.botonakis.com:3478',
         'stun:stun.budgetphone.nl:3478',
         'stun:stun.budgetsip.com:3478',
         'stun:stun.cablenet-as.net:3478',
         'stun:stun.callromania.ro:3478',
         'stun:stun.callwithus.com:3478',
         'stun:stun.cbsys.net:3478',
         'stun:stun.chathelp.ru:3478',
         'stun:stun.cheapvoip.com:3478',
         'stun:stun.ciktel.com:3478',
         'stun:stun.cloopen.com:3478',
         'stun:stun.colouredlines.com.au:3478',
         'stun:stun.comfi.com:3478',
         'stun:stun.commpeak.com:3478',
         'stun:stun.comtube.com:3478',
         'stun:stun.comtube.ru:3478',
         'stun:stun.cope.es:3478',
         'stun:stun.counterpath.com:3478',
         'stun:stun.counterpath.net:3478',
         'stun:stun.cryptonit.net:3478',
         'stun:stun.darioflaccovio.it:3478',
         'stun:stun.datamanagement.it:3478',
         'stun:stun.dcalling.de:3478',
         'stun:stun.decanet.fr:3478',
         'stun:stun.demos.ru:3478',
         'stun:stun.develz.org:3478',
         'stun:stun.dingaling.ca:3478',
         'stun:stun.doublerobotics.com:3478',
         'stun:stun.drogon.net:3478',
         'stun:stun.duocom.es:3478',
         'stun:stun.dus.net:3478',
         'stun:stun.e-fon.ch:3478',
         'stun:stun.easybell.de:3478',
         'stun:stun.easycall.pl:3478',
         'stun:stun.easyvoip.com:3478',
         'stun:stun.efficace-factory.com:3478',
         'stun:stun.einsundeins.com:3478',
         'stun:stun.einsundeins.de:3478',
         'stun:stun.ekiga.net:3478',
         'stun:stun.epygi.com:3478',
         'stun:stun.etoilediese.fr:3478',
         'stun:stun.eyeball.com:3478',
         'stun:stun.faktortel.com.au:3478',
         'stun:stun.freecall.com:3478',
         'stun:stun.freeswitch.org:3478',
         'stun:stun.freevoipdeal.com:3478',
         'stun:stun.fuzemeeting.com:3478',
         'stun:stun.gmx.de:3478',
         'stun:stun.gmx.net:3478',
         'stun:stun.gradwell.com:3478',
         'stun:stun.halonet.pl:3478',
         'stun:stun.hellonanu.com:3478',
         'stun:stun.hoiio.com:3478',
         'stun:stun.hosteurope.de:3478',
         'stun:stun.ideasip.com:3478',
         'stun:stun.imesh.com:3478',
         'stun:stun.infra.net:3478',
         'stun:stun.internetcalls.com:3478',
         'stun:stun.intervoip.com:3478',
         'stun:stun.ipcomms.net:3478',
         'stun:stun.ipfire.org:3478',
         'stun:stun.ippi.fr:3478',
         'stun:stun.ipshka.com:3478',
         'stun:stun.iptel.org:3478',
         'stun:stun.irian.at:3478',
         'stun:stun.it1.hr:3478',
         'stun:stun.ivao.aero:3478',
         'stun:stun.jappix.com:3478',
         'stun:stun.jumblo.com:3478',
         'stun:stun.justvoip.com:3478',
         'stun:stun.kanet.ru:3478',
         'stun:stun.kiwilink.co.nz:3478',
         'stun:stun.kundenserver.de:3478',
         'stun:stun.l.google.com:19302',
         'stun:stun.linea7.net:3478',
         'stun:stun.linphone.org:3478',
         'stun:stun.liveo.fr:3478',
         'stun:stun.lowratevoip.com:3478',
         'stun:stun.lugosoft.com:3478',
         'stun:stun.lundimatin.fr:3478',
         'stun:stun.magnet.ie:3478',
         'stun:stun.manle.com:3478',
         'stun:stun.mgn.ru:3478',
         'stun:stun.mit.de:3478',
         'stun:stun.mitake.com.tw:3478',
         'stun:stun.miwifi.com:3478',
         'stun:stun.modulus.gr:3478',
         'stun:stun.mozcom.com:3478',
         'stun:stun.myvoiptraffic.com:3478',
         'stun:stun.mywatson.it:3478',
         'stun:stun.nas.net:3478',
         'stun:stun.neotel.co.za:3478',
         'stun:stun.netappel.com:3478',
         'stun:stun.netappel.fr:3478',
         'stun:stun.netgsm.com.tr:3478',
         'stun:stun.nfon.net:3478',
         'stun:stun.noblogs.org:3478',
         'stun:stun.noc.ams-ix.net:3478',
         'stun:stun.node4.co.uk:3478',
         'stun:stun.nonoh.net:3478',
         'stun:stun.nottingham.ac.uk:3478',
         'stun:stun.nova.is:3478',
         'stun:stun.nventure.com:3478',
         'stun:stun.on.net.mk:3478',
         'stun:stun.ooma.com:3478',
         'stun:stun.ooonet.ru:3478',
         'stun:stun.oriontelekom.rs:3478',
         'stun:stun.outland-net.de:3478',
         'stun:stun.ozekiphone.com:3478',
         'stun:stun.patlive.com:3478',
         'stun:stun.personal-voip.de:3478',
         'stun:stun.petcube.com:3478',
         'stun:stun.phone.com:3478',
         'stun:stun.phoneserve.com:3478',
         'stun:stun.pjsip.org:3478',
         'stun:stun.poivy.com:3478',
         'stun:stun.powerpbx.org:3478',
         'stun:stun.powervoip.com:3478',
         'stun:stun.ppdi.com:3478',
         'stun:stun.prizee.com:3478',
         'stun:stun.qq.com:3478',
         'stun:stun.qvod.com:3478',
         'stun:stun.rackco.com:3478',
         'stun:stun.rapidnet.de:3478',
         'stun:stun.rb-net.com:3478',
         'stun:stun.refint.net:3478',
         'stun:stun.remote-learner.net:3478',
         'stun:stun.rixtelecom.se:3478',
         'stun:stun.rockenstein.de:3478',
         'stun:stun.rolmail.net:3478',
         'stun:stun.rounds.com:3478',
         'stun:stun.rynga.com:3478',
         'stun:stun.samsungsmartcam.com:3478',
         'stun:stun.schlund.de:3478',
         'stun:stun.services.mozilla.com:3478',
         'stun:stun.sigmavoip.com:3478',
         'stun:stun.sip.us:3478',
         'stun:stun.sipdiscount.com:3478',
         'stun:stun.sipgate.net:10000',
         'stun:stun.sipgate.net:3478',
         'stun:stun.siplogin.de:3478',
         'stun:stun.sipnet.net:3478',
         'stun:stun.sipnet.ru:3478',
         'stun:stun.siportal.it:3478',
         'stun:stun.sippeer.dk:3478',
         'stun:stun.siptraffic.com:3478',
         'stun:stun.skylink.ru:3478',
         'stun:stun.sma.de:3478',
         'stun:stun.smartvoip.com:3478',
         'stun:stun.smsdiscount.com:3478',
         'stun:stun.snafu.de:3478',
         'stun:stun.softjoys.com:3478',
         'stun:stun.solcon.nl:3478',
         'stun:stun.solnet.ch:3478',
         'stun:stun.sonetel.com:3478',
         'stun:stun.sonetel.net:3478',
         'stun:stun.sovtest.ru:3478',
         'stun:stun.speedy.com.ar:3478',
         'stun:stun.spokn.com:3478',
         'stun:stun.srce.hr:3478',
         'stun:stun.ssl7.net:3478',
         'stun:stun.stunprotocol.org:3478',
         'stun:stun.symform.com:3478',
         'stun:stun.symplicity.com:3478',
         'stun:stun.sysadminman.net:3478',
         'stun:stun.t-online.de:3478',
         'stun:stun.tagan.ru:3478',
         'stun:stun.tatneft.ru:3478',
         'stun:stun.teachercreated.com:3478',
         'stun:stun.tel.lu:3478',
         'stun:stun.telbo.com:3478',
         'stun:stun.telefacil.com:3478',
         'stun:stun.tis-dialog.ru:3478',
         'stun:stun.tng.de:3478',
         'stun:stun.twt.it:3478',
         'stun:stun.u-blox.com:3478',
         'stun:stun.ucallweconn.net:3478',
         'stun:stun.ucsb.edu:3478',
         'stun:stun.ucw.cz:3478',
         'stun:stun.uls.co.za:3478',
         'stun:stun.unseen.is:3478',
         'stun:stun.usfamily.net:3478',
         'stun:stun.veoh.com:3478',
         'stun:stun.vidyo.com:3478',
         'stun:stun.vipgroup.net:3478',
         'stun:stun.virtual-call.com:3478',
         'stun:stun.viva.gr:3478',
         'stun:stun.vivox.com:3478',
         'stun:stun.vline.com:3478',
         'stun:stun.vo.lu:3478',
         'stun:stun.vodafone.ro:3478',
         'stun:stun.voicetrading.com:3478',
         'stun:stun.voip.aebc.com:3478',
         'stun:stun.voip.blackberry.com:3478',
         'stun:stun.voip.eutelia.it:3478',
         'stun:stun.voiparound.com:3478',
         'stun:stun.voipblast.com:3478',
         'stun:stun.voipbuster.com:3478',
         'stun:stun.voipbusterpro.com:3478',
         'stun:stun.voipcheap.co.uk:3478',
         'stun:stun.voipcheap.com:3478',
         'stun:stun.voipfibre.com:3478',
         'stun:stun.voipgain.com:3478',
         'stun:stun.voipgate.com:3478',
         'stun:stun.voipinfocenter.com:3478',
         'stun:stun.voipplanet.nl:3478',
         'stun:stun.voippro.com:3478',
         'stun:stun.voipraider.com:3478',
         'stun:stun.voipstunt.com:3478',
         'stun:stun.voipwise.com:3478',
         'stun:stun.voipzoom.com:3478',
         'stun:stun.vopium.com:3478',
         'stun:stun.voxgratia.org:3478',
         'stun:stun.voxox.com:3478',
         'stun:stun.voys.nl:3478',
         'stun:stun.voztele.com:3478',
         'stun:stun.vyke.com:3478',
         'stun:stun.webcalldirect.com:3478',
         'stun:stun.whoi.edu:3478',
         'stun:stun.wifirst.net:3478',
         'stun:stun.wwdl.net:3478',
         'stun:stun.xs4all.nl:3478',
         'stun:stun.xtratelecom.es:3478',
         'stun:stun.yesss.at:3478',
         'stun:stun.zadarma.com:3478',
         'stun:stun.zadv.com:3478',
         'stun:stun.zoiper.com:3478',
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

