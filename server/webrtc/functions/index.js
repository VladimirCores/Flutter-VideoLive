const functions = require('firebase-functions');
var { RtcTokenBuilder, RtcRole } = require('agora-access-token')

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// test: liveAgoraRequestToken({"appId":"0d157089e4cc4d43b8f8930ae7b4752e","roomId":"firebase-function-test"})
exports.liveAgoraRequestToken = functions.https.onCall(async (data, context) => {
  // Grab the text parameter.
  functions.logger.info("liveAgoraRequestToken -> data: " + JSON.stringify(data));

  var APP_CERTIFICATE = "e63a3633d9e94f3088a5f98641685cb1";
  var EXPIRATION_TIME_IN_SECONDS = 1 * 60 * 60; // hours * minutes * seconds

  // Rtc Examples
  const now = parseInt(Date.now());

  const currentTimestamp = Math.floor(now / 1000)
  const expireTimeSeconds = currentTimestamp + EXPIRATION_TIME_IN_SECONDS
  const uid = 0;

  // Build token with uid
  const token = await RtcTokenBuilder.buildTokenWithUid(
    data.appId,
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
