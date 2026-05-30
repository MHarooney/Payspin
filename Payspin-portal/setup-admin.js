const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('./payspin-app-firebase-adminsdk-2cr3x-a05132e637.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'payspin-app'
});

async function createAdminUser() {
  try {
    const userRecord = await admin.auth().createUser({
      email: 'payspin.app@gmail.com',
      password: 'Payspin@2023',
      displayName: 'Admin User',
      emailVerified: true,
    });

    // Set custom claims to mark as admin
    await admin.auth().setCustomUserClaims(userRecord.uid, { 
      admin: true,
      role: 'admin' 
    });

    console.log('Successfully created admin user:', userRecord.uid);
    console.log('Email:', userRecord.email);
    console.log('Admin claims set successfully');
    
    process.exit(0);
  } catch (error) {
    console.error('Error creating admin user:', error);
    process.exit(1);
  }
}

createAdminUser(); 