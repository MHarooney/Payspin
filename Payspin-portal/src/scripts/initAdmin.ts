import { initializeAdmin } from '../config/firebase-admin';

async function initializeAndTest() {
  try {
    // Initialize admin with service account
    const { adminDb } = initializeAdmin({
      projectId: "payspin-app",
      clientEmail: process.env.FIREBASE_ADMIN_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    });

    // Test the connection by trying to read users collection
    const usersSnapshot = await adminDb.collection('users').limit(1).get();
    console.log('Successfully connected to Firestore!');
    console.log(`Found ${usersSnapshot.size} users`);

    return true;
  } catch (error) {
    console.error('Error initializing admin:', error);
    return false;
  }
}

// Run the initialization
initializeAndTest()
  .then((success) => {
    if (success) {
      console.log('Admin SDK initialized successfully!');
    } else {
      console.error('Failed to initialize Admin SDK');
    }
  })
  .catch(console.error); 