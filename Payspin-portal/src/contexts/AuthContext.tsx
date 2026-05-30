import React, { createContext, useContext, useEffect, useState, ReactNode, useCallback } from 'react';
import { User as FirebaseUser, onAuthStateChanged, signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { auth } from '../config/firebase';
import { User } from '../types/firestore';
import toast from 'react-hot-toast';
import { Timestamp } from 'firebase/firestore';
import { useSessionManager } from '../hooks/useSessionManager';

interface AuthContextType {
  currentUser: FirebaseUser | null;
  userData: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  isAdmin: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [currentUser, setCurrentUser] = useState<FirebaseUser | null>(null);
  const [userData, setUserData] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  // Session management callback
  const handleSessionExpired = useCallback(async () => {
    try {
      await signOut(auth);
      setUserData(null);
      setCurrentUser(null);
    } catch (error) {
      console.error('Error during session expiry logout:', error);
    }
  }, []);

  // Initialize session manager (background only)
  useSessionManager(currentUser, handleSessionExpired);

  const login = async (email: string, password: string) => {
    try {
      setLoading(true);
      
      // Use Firebase Auth to sign in
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;
      
      // Get the ID token to check custom claims
      const idTokenResult = await user.getIdTokenResult();
      const isAdmin = idTokenResult.claims.admin === true;
      
      if (!isAdmin) {
        // Sign out if not admin
        await signOut(auth);
        throw new Error('Access denied. Admin privileges required.');
      }

      // Create user data object
      const adminUserData: User = {
        id: user.uid,
        firstName: 'Admin',
        lastName: 'User',
        email: user.email || '',
        displayName: user.displayName || 'Admin User',
        isActive: true,
        role: 'admin',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      };
      
      setUserData(adminUserData);
      toast.success('Successfully logged in as admin!');
    } catch (error: any) {
      console.error('Login error:', error);
      if (error.code === 'auth/wrong-password' || error.code === 'auth/user-not-found') {
        toast.error('Invalid email or password');
      } else if (error.code === 'auth/too-many-requests') {
        toast.error('Too many failed attempts. Please try again later.');
      } else {
        toast.error(error.message || 'Failed to login');
      }
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const logout = async () => {
    try {
      await signOut(auth);
      setUserData(null);
      toast.success('Successfully logged out');
    } catch (error: any) {
      console.error('Logout error:', error);
      toast.error('Failed to logout');
      throw error;
    }
  };

  // Check if user is admin
  const isAdmin = Boolean(currentUser && userData?.role === 'admin');

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      setCurrentUser(user);
      
      if (user) {
        try {
          // Check if user has admin claims
          const idTokenResult = await user.getIdTokenResult();
          const isAdmin = idTokenResult.claims.admin === true;
          
          if (isAdmin) {
            // Create user data for admin
            const adminUserData: User = {
              id: user.uid,
              firstName: 'Admin',
              lastName: 'User',
              email: user.email || '',
              displayName: user.displayName || 'Admin User',
              isActive: true,
              role: 'admin',
              createdAt: Timestamp.now(),
              updatedAt: Timestamp.now(),
            };
            setUserData(adminUserData);
          } else {
            // Not an admin, sign them out
            await signOut(auth);
            setUserData(null);
          }
        } catch (error) {
          console.error('Error checking user claims:', error);
          setUserData(null);
        }
      } else {
        setUserData(null);
      }
      
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  const value: AuthContextType = {
    currentUser,
    userData,
    loading,
    login,
    logout,
    isAdmin,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}; 