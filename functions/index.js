const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Generate share link
exports.generateShareLink = functions.https.onCall(async (data, context) => {
  const {userId} = data;

  if (!userId) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "userId is required",
    );
  }

  const baseUrl = "https://connect-675b1.web.app";
  const shareLink = `${baseUrl}/refer?userId=${userId}`;

  return {shareLink};
});

// Web redirect handler
exports.handleReferralRedirect = functions.https.onRequest((req, res) => {
  const userId = req.query.userId;

  const androidPackage = "com.app.secureconnect";
  const iosAppId = "YOUR_IOS_APP_ID";

  const userAgent = req.headers["user-agent"] || "";
  const isAndroid = /android/i.test(userAgent);
  const isIOS = /iPad|iPhone|iPod/.test(userAgent);

  const deepLink = `secureconnect://refer?userId=${userId}`;

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Secure Connect</title>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        body {
          font-family: Arial, sans-serif;
          text-align: center;
          padding: 50px;
          background: linear-gradient(135deg, #66C7F4, #1FAAEA);
          color: white;
          margin: 0;
        }
        .container {
          background: white;
          color: #333;
          padding: 30px;
          border-radius: 15px;
          max-width: 400px;
          margin: 0 auto;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .logo {
          font-size: 48px;
          margin-bottom: 20px;
        }
        .button {
          display: inline-block;
          background: #1FAAEA;
          color: white;
          padding: 15px 30px;
          border-radius: 25px;
          text-decoration: none;
          margin: 10px;
          font-weight: bold;
        }
        .spinner {
          border: 3px solid #f3f3f3;
          border-top: 3px solid #1FAAEA;
          border-radius: 50%;
          width: 40px;
          height: 40px;
          animation: spin 1s linear infinite;
          margin: 20px auto;
        }
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="logo">📱</div>
        <h2>Welcome to Secure Connect!</h2>
        <div class="spinner"></div>
        <p>Opening the app...</p>
        <div id="fallback" style="display:none; margin-top: 20px;">
          <p>Don't have the app? Download it now:</p>
          ${isAndroid ? `<a href="https://play.google.com/store/apps/details?id=${androidPackage}" class="button">Download for Android</a>` : ""}
          ${isIOS ? `<a href="https://apps.apple.com/app/id=${iosAppId}" class="button">Download for iOS</a>` : ""}
        </div>
      </div>

      <script>
        const deepLink = "${deepLink}";
        const isAndroid = ${isAndroid};
        const isIOS = ${isIOS};

        window.location.href = deepLink;

        setTimeout(() => {
          document.getElementById("fallback").style.display = "block";
        }, 2000);

        setTimeout(() => {
          if (isAndroid) {
            window.location.href = "https://play.google.com/store/apps/details?id=${androidPackage}";
          } else if (isIOS) {
            window.location.href = "https://apps.apple.com/app/id=${iosAppId}";
          }
        }, 3000);
      </script>
    </body>
    </html>
  `;

  res.send(html);
});
