import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';
import { getStorage, FirebaseStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: "AIzaSyCOnS3dUuS4FVCJwBdn91Tn1zfHMb9tYNQ",
  authDomain: "payspin-app.firebaseapp.com",
  projectId: "payspin-app",
  storageBucket: "payspin-app.appspot.com",
  messagingSenderId: "662471905267",
  appId: "1:662471905267:android:f626c7f4dbe309003d8c86"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firestore
export const db = getFirestore(app);

// Initialize Auth
export const auth = getAuth(app);

// Initialize Storage (optional - may not be available in all projects)
let storage: FirebaseStorage | null = null;
try {
  storage = getStorage(app);
} catch (error) {
  console.warn('Firebase Storage is not available:', error);
  storage = null;
}

// Export the storage instance
export { storage };

// Export the app instance
export default app; 