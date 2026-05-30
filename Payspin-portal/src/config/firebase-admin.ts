import { initializeApp as initializeAdminApp, cert, ServiceAccount } from 'firebase-admin/app';
import { getFirestore as getAdminFirestore } from 'firebase-admin/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyCOnS3dUuS4FVCJwBdn91Tn1zfHMb9tYNQ",
  authDomain: "payspin-app.firebaseapp.com",
  projectId: "payspin-app",
  storageBucket: "payspin-app.appspot.com",
  messagingSenderId: "662471905267",
  appId: "1:662471905267:android:f626c7f4dbe309003d8c86"
};

// Firebase Admin SDK initialization
export function initializeAdmin(serviceAccount: ServiceAccount) {
  try {
    // Initialize admin app if not already initialized
    let adminApp;
    try {
      adminApp = initializeAdminApp({
        credential: cert(serviceAccount),
        projectId: serviceAccount.projectId || firebaseConfig.projectId,
      });
    } catch (error: any) {
      // If app already exists, get the existing app
      if (error.code === 'app/duplicate-app') {
        adminApp = initializeAdminApp();
      } else {
        throw error;
      }
    }

    // Initialize admin Firestore
    const adminDb = getAdminFirestore(adminApp);

    return {
      adminApp,
      adminDb,
    };
  } catch (error) {
    console.error('Error initializing Firebase Admin SDK:', error);
    throw error;
  }
} 