import { initializeApp } from 'firebase/app';
import { getAuth, createUserWithEmailAndPassword } from 'firebase/auth';
import { getFirestore, doc, setDoc } from 'firebase/firestore';
import { ADMIN_EMAIL, ADMIN_PASSWORD, firebaseConfig } from './config';

async function setupAdminAccount() {
  try {
    // Initialize Firebase
    const app = initializeApp(firebaseConfig);
    const auth = getAuth(app);
    const db = getFirestore(app);

    console.log('Creating admin account...');

    // Create admin user in Authentication
    const userCredential = await createUserWithEmailAndPassword(
      auth,
      ADMIN_EMAIL,
      ADMIN_PASSWORD
    );

    console.log('Admin user created in Authentication');

    // Create admin document in Firestore
    await setDoc(doc(db, 'admin_users', userCredential.user.uid), {
      email: ADMIN_EMAIL,
      role: 'admin',
      createdAt: new Date().toISOString(),
      lastLogin: new Date().toISOString()
    });

    console.log('Admin document created in Firestore');
    console.log('Admin account setup completed successfully');
    process.exit(0);
  } catch (error) {
    if (error.code === 'auth/email-already-in-use') {
      console.log('Admin account already exists');
      process.exit(0);
    } else {
      console.error('Error creating admin account:', error);
      process.exit(1);
    }
  }
}

setupAdminAccount(); 