const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// 1. Load Credentials from .env
const envPath = path.join(__dirname, '..', '.env');
const envContent = fs.readFileSync(envPath, 'utf8');
const email = envContent.match(/KRAVE_ADMIN_EMAIL=(.*)/)[1];
const password = envContent.match(/KRAVE_ADMIN_PASSWORD=(.*)/)[1];

// 2. Initialize Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();
const db = admin.firestore();

async function bootstrap() {
  console.log(`🚀 Bootstrapping Admin: ${email}...`);

  try {
    let userRecord;
    try {
      // 3. Update Existing User
      userRecord = await auth.getUserByEmail(email);
      console.log('✅ User exists in Auth. Force-syncing password...');
      await auth.updateUser(userRecord.uid, { 
        password: password,
        displayName: 'Krave SuperAdmin'
      });
      console.log('✅ Password Synced.');
    } catch (e) {
      // 4. Create New User
      userRecord = await auth.createUser({
        email: email,
        password: password,
        emailVerified: true,
        displayName: 'Krave SuperAdmin'
      });
      console.log('✅ Created new user in Auth.');
    }

    // 5. Add to Admins Collection
    await db.collection('Admins').doc(userRecord.uid).set({
      email: email,
      role: 'superadmin',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ Promoted to SuperAdmin in Firestore.');

    console.log('\n--- SETUP COMPLETE ---');
    console.log('You can now log in at krave-124.web.app');
    console.log('-----------------------');

  } catch (error) {
    console.error('❌ Bootstrap failed:', error.message);
  }
}

bootstrap();
