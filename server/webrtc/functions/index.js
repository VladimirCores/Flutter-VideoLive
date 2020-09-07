const functions = require('firebase-functions');
var { RtcTokenBuilder, RtcRole } = require('agora-access-token')

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
exports.liveAgoraRequestToken = functions.https.onRequest(async (req, res) => {
  // Grab the text parameter.
  functions.logger.info("liveAgoraRequestToken > " + JSON.stringify(req.query), {structuredData: true});

  var APP_CERTIFICATE = "e63a3633d9e94f3088a5f98641685cb1";
  var EXPIRATION_TIME_IN_SECONDS = 1 * 60 * 60; // hours * minutes * seconds

  var role = RtcRole.PUBLISHER;

  // Rtc Examples
  const uid = Date.now();

  const currentTimestamp = Math.floor(uid / 1000)
  const expireTimeSeconds = currentTimestamp + EXPIRATION_TIME_IN_SECONDS

  // Build token with uid
  const token = RtcTokenBuilder.buildTokenWithUid(
    req.query.appId,
    APP_CERTIFICATE,
    req.query.roomId, // channel name
    uid,
    RtcRole.PUBLISHER,
    expireTimeSeconds
  );
  functions.logger.info("liveAgoraRequestToken > token = " + token, {structuredData: true});

  res.send({
    uid: uid,
    token: token,
    expire: expireTimeSeconds
  });
});
