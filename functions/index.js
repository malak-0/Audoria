const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });
admin.initializeApp();

//verify firebase token
async function verifyFirebaseToken(authHeader) {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('Unauthorized - No token provided');
  }

  const token = authHeader.split('Bearer ')[1];
  const decodedToken = await admin.auth().verifyIdToken(token);
  return decodedToken;
}

//create a child acc function
exports.createChildAccount = functions.https.onRequest(async (req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const decodedToken = await verifyFirebaseToken(req.headers.authorization);
      const parentUid = decodedToken.uid;
      const { 
        email, 
        password, 
        name, 
        age, 
        grade, 
        school,
      } = req.body;

      if (!email || !password || !name) {
        return res.status(400).json({ error: 'Missing required fields: email, password, name' });
      }

      const childUser = await admin.auth().createUser({
        email,
        password,
        displayName: name,
      });

      const childData = {
        name,
        email,
        childUid: childUser.uid,
        age: age || null,
        grade: grade || null,
        school: school || null,
        parentUid: parentUid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
        accountType: 'child',
      };

      await admin.firestore()
        .collection("users").doc(parentUid)
        .collection("children").doc(childUser.uid)
        .set(childData);

      res.json({
        success: true,
        childUid: childUser.uid,
        message: 'Child account created successfully',
        childData: childData,
      });

    } catch (error) {
      console.error('Error:', error);
      res.status(400).json({
        success: false,
        error: error.message,
      });
    }
  });
});

//generate token for qr code
exports.generateChildLoginToken = functions.https.onRequest(async (req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const decodedToken = await verifyFirebaseToken(req.headers.authorization);
      const parentUid = decodedToken.uid;

      const { childUid } = req.body;

      if (!childUid) {
        return res.status(400).json({ error: 'Missing childUid' });
      }

      const childDoc = await admin.firestore()
        .collection("users").doc(parentUid)
        .collection("children").doc(childUid).get();

      if (!childDoc.exists) {
        return res.status(404).json({ error: 'Child not found' });
      }

      const token = Math.random().toString(36).substring(2) + Date.now().toString(36);
      const expiresAt = new Date(Date.now() + 10 * 60 * 1000); 

      await admin.firestore().collection("loginTokens").doc(token).set({
        childUid,
        parentUid,
        expiresAt,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.json({ 
        success: true,
        token,
        expiresAt: expiresAt.toISOString(),
        qrData: {
          type: 'child_login',
          token: token,
          childUid: childUid,
          app: 'audoria'
        }
      });

    } catch (error) {
      console.error('Error:', error);
      res.status(400).json({
        success: false,
        error: error.message
      });
    }
  });
});

//child login after scan qr code
exports.validateQRToken = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const { token } = req.body;

      if (!token) {
        return res.status(400).json({ error: 'Missing token' });
      }

      const tokenDoc = await admin.firestore().collection("loginTokens").doc(token).get();

      if (!tokenDoc.exists) {
        return res.status(404).json({ error: 'Invalid token' });
      }

      const tokenData = tokenDoc.data();

      if (tokenData.expiresAt.toDate() < new Date()) {
        await admin.firestore().collection("loginTokens").doc(token).delete();
        return res.status(400).json({ error: 'Token expired' });
      }

      const loginStatusId = `login_${tokenData.childUid}_${Date.now()}`;
      await admin.firestore().collection("loginStatus").doc(loginStatusId).set({
        childUid: tokenData.childUid,
        parentUid: tokenData.parentUid,
        status: 'success',
        loginTime: admin.firestore.FieldValue.serverTimestamp(),
        token: token,
      });

      await admin.firestore().collection("loginTokens").doc(token).delete();

      const customToken = await admin.auth().createCustomToken(tokenData.childUid);

      return res.json({
        success: true,
        customToken,
        childUid: tokenData.childUid
      });

    } catch (error) {
      console.error('Error:', error);
      return res.status(400).json({
        success: false,
        error: error.message
      });
    }
  });
});