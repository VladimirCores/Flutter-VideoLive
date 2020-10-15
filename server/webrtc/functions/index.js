const functions = require('firebase-functions');
var { RtcTokenBuilder, RtcRole } = require('agora-access-token')
const AXIOS = require('axios');

var APP_ID = "";
var APP_CERTIFICATE = "";

const CLOUD_RECORDING_REQUEST = AXIOS.create({
  baseURL: `https://api.agora.io/v1/apps/${APP_ID}/cloud_recording`,
  headers: {
    'Content-Type': 'application/json;charset=utf-8'
  },
  auth: {
    username: '',
    password: ''
  }
});
const MODE = 'mix';
const UID = '1475127236';
const ROOM = 'zOrAH6taZ8jEB8ACIvlA';
let RESID = 'VHSX885c0AW7PG4p0WsufjXzivvKQF2EiKGUWs9rEfHmtgGpNLRALjaGELtfSnlKgXBLSdiQH_UNFP3uAEtRhtPj2vuH6iTGnjNPrOasAhh27fKSKHrmKVC16rJsgcznJ0zVv7P6AUK-KvN_LGHwNjShYtqHuHwfR0RzAwQ0wTBvzdmcTvLoouTzZS57JdBFk6QFKTFfCIiu4x7xxDMlaiWxH0vn15RhjoWpiA_h6kMg3SUu3i6Ei9F3peJN6xfBfbBE-oY-if9FL04XT9fFpvQ5ZsxFzC07zBgxq79djPgsji7gaenIP8wGWYR4c_0J';
let SID = '9b18ad164146bfd16b8c6f870ad493c4'
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// test: liveAgoraRequestToken({"roomId":"firebase-function-test"})
exports.liveAgoraRequestToken = functions.https.onCall(async (data, context) => {
  // Grab the text parameter.
  functions.logger.info("liveAgoraRequestToken -> data: " + JSON.stringify(data));

  var EXPIRATION_TIME_IN_SECONDS = 1 * 60 * 60; // hours * minutes * seconds

  // Rtc Examples
  const now = parseInt(Date.now());

  const currentTimestamp = Math.floor(now / 1000)
  const expireTimeSeconds = currentTimestamp + EXPIRATION_TIME_IN_SECONDS
  const uid = 0;

  // Build token with uid
  const token = await RtcTokenBuilder.buildTokenWithUid(
    APP_ID,
    APP_CERTIFICATE,
    data.roomId, // channel name
    uid,
    RtcRole.PUBLISHER,
    expireTimeSeconds
  );

  functions.logger.info("liveAgoraRequestToken", "token = " + token);

  return {
    uid: uid,
    token: token,
    expire: expireTimeSeconds
  };
});

// liveAgoraRecordingAcquire({})
exports.liveAgoraRecordingAcquire = functions.https.onCall(async (data, context) => {
  functions.logger.info("liveAgoraRecordingAcquire", "data = " + JSON.stringify(data));

  const BODY = {
    cname: ROOM, // The name of the channel to be recorded.
    uid: UID, // A string that contains the UID of the recording client
    clientRequest: {
      resourceExpiredHour: 1
    }
  }

  // https://docs.agora.io/en/cloud-recording/restfulapi/#/Cloud%20Recording/acquire
  try {
    const response = await CLOUD_RECORDING_REQUEST.post(`acquire`, BODY);
    return { status: response.status, data: response.data };
  } catch(e) {
    console.error('> liveAgoraRecordingAcquire -> error:', e.response.data, e.response.status, e.response.statusText);
    return { status: 'ERROR', message: e.toString() };
  }
});

// Call the start method within 5 minutes after getting the resource ID to join a channel and start the recording.
// liveAgoraRecordingStart({})
exports.liveAgoraRecordingStart = functions.https.onCall(async (data, context) => {

  const resourceId = RESID
  const mode = MODE;
  const URL = `/resourceid/${resourceId}/mode/${mode}/start`;

  const BODY = {
    cname: ROOM, // The name of the channel to be recorded.
    uid: UID, // A string that contains the UID of the recording client
    clientRequest: {
      recordingConfig: {
          maxIdleTime: 30,
          streamTypes: 2,
          channelType: 1,
          videoStreamType: 1,
      },
      recordingFileConfig: {
        avFileType: [
          "hls"
        ]
      },
      storageConfig: {
        vendor: 1,
        accessKey: 'AKIAWNYC5JSVUTTLLAS7',
        region: 7,
        bucket: 'vladimir-test-bucket-1',
        secretKey: 'HJcBMumf1ofWSjSbElJfHv3TXBPiUzv5YC413jkh',
        fileNamePrefix: ['hvnlive', ROOM]
      }
    }
  }

  try {
    const response = await CLOUD_RECORDING_REQUEST.post(URL, BODY);
    return { status: 'OK', code: response.code, data: response.data };
  } catch(e) {
    console.error('> liveAgoraRecordingStart -> error:', e.response.data, e.response.status, e.response.statusText);
    return { status: 'ERROR', code: e.response.code, data: e.response.data };
  }
});

// Five seconds after you receive a sid, use a backoff strategy to call query.
// liveAgoraRecordingQuery({})
exports.liveAgoraRecordingQuery = functions.https.onCall(async (data, context) => {
  const resourceId = RESID;
  const mode = MODE;
  const sid = SID;
  const URL = `/resourceid/${resourceId}/sid/${sid}/mode/${mode}/query`;
  try {
    const response = await CLOUD_RECORDING_REQUEST.get(URL);
    return { status: 'OK', code: response.code, data: response.data };
  } catch(e) {
    console.error('> liveAgoraRecordingStop -> error:', e.response.data, e.response.status, e.response.statusText);
    return { status: 'ERROR', code: e.response.code, data: e.response.data };
  }
});

// liveAgoraRecordingStop({})
exports.liveAgoraRecordingStop = functions.https.onCall(async (data, context) => {

  const resourceId = RESID
  const mode = MODE;
  const sid = SID;

  const URL = `/resourceid/${resourceId}/sid/${sid}/mode/${mode}/stop`;

  const BODY = {
    cname: ROOM, // The name of the channel to be recorded.
    uid: UID, // A string that contains the UID of the recording client
    clientRequest: {}
  }

  try {
    const response = await CLOUD_RECORDING_REQUEST.post(URL, BODY);
    return { status: 'OK', code: response.code, data: response.data };
  } catch(e) {
    console.error('> liveAgoraRecordingStop -> error:', e.response.data, e.response.status, e.response.statusText);
    return { status: 'ERROR', code: e.response.code, data: e.response.data };
  }
});
