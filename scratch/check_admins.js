const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // Assume it exists or we need it

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function listAdmins() {
  const snapshot = await db.collection('Admins').get();
  if (snapshot.empty) {
    console.log('No admins found.');
  } else {
    snapshot.forEach(doc => {
      console.log(doc.id, '=>', doc.data());
    });
  }
}

listAdmins();
