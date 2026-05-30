import { useState, useEffect } from 'react';
import {
  collection,
  query,
  where,
  orderBy,
  limit,
  getDocs,
  startAfter,
  QuerySnapshot,
  DocumentData,
  CollectionReference,
  doc,
  updateDoc,
  Timestamp,
} from 'firebase/firestore';
import { db } from '../config/firebase';
import { User, UserTableState } from '../types/firestore';
import { firebaseService } from '../services/firebase';
import toast from 'react-hot-toast';
import { now } from '../utils/date';

const defaultTableState: UserTableState = {
  page: 1,
  pageSize: 10,
  search: '',
  filters: {
    status: undefined,
  },
  sort: {
    field: 'created_time',
    direction: 'desc',
  },
};

interface UseUsersReturn {
  users: User[];
  loading: boolean;
  error: Error | null;
  totalUsers: number;
  stats: {
    total: number;
    active: number;
    inactive: number;
    admin: number;
  };
  tableState: UserTableState;
  handleTableStateChange: (newState: UserTableState) => void;
  handleUpdateStatus: (userId: string, newStatus: boolean) => Promise<void>;
  handleUpdateRole: (userId: string, newRole: 'user' | 'admin' | 'moderator') => Promise<void>;
  handleCreateUser: (userData: {
    email: string;
    firstName: string;
    lastName: string;
    phoneNumber?: string;
    role?: 'user' | 'admin' | 'moderator';
    circleId?: string;
    isActive?: boolean;
  }) => Promise<User | null>;
  handleUpdateUser: (userId: string, updates: {
    firstName?: string;
    lastName?: string;
    email?: string;
    phoneNumber?: string;
    role?: 'user' | 'admin' | 'moderator';
    circleId?: string;
    isActive?: boolean;
  }) => Promise<User | null>;
  handleDeleteUser: (userId: string) => Promise<boolean>;
  handleGetUserById: (userId: string) => Promise<User | null>;
  handleCheckEmailExists: (email: string, excludeUserId?: string) => Promise<boolean>;
}

// Helper function to convert Firestore Timestamp to Date
const convertTimestamp = (timestamp: unknown): Date | null => {
  if (!timestamp) return null;
  if (timestamp instanceof Date) return timestamp;
  if (timestamp instanceof Timestamp) return timestamp.toDate();
  if (typeof timestamp === 'object' && timestamp !== null) {
    // Handle raw Firestore timestamp object
    const ts = timestamp as { seconds: number; nanoseconds: number };
    if ('seconds' in ts && 'nanoseconds' in ts) {
      return new Date(ts.seconds * 1000 + ts.nanoseconds / 1000000);
    }
  }
  if (typeof timestamp === 'string') {
    const date = new Date(timestamp);
    return isNaN(date.getTime()) ? null : date;
  }
  return null;
};

// Helper function to clean user data
const cleanUserData = (data: DocumentData, docId: string): User => {
  const cleanUser: User = {
    id: docId,
    firstName: data.First_Name || '',
    lastName: data.Last_Name || '',
    displayName: data.display_name || `${data.First_Name || ''} ${data.Last_Name || ''}`.trim() || 'Unknown User',
    email: data.email || '',
    phoneNumber: data.phone_number || '',
    isActive: Boolean(data.isActive !== false), // Default to true if not specified
    role: data.role || 'user',
    createdAt: data.created_time instanceof Timestamp ? data.created_time : Timestamp.now(),
    updatedAt: data.updatedAt instanceof Timestamp ? data.updatedAt : Timestamp.now(),
    lastLoginAt: data.lastLoginAt instanceof Timestamp ? data.lastLoginAt : undefined,
    circleId: data.circleIDnotRef || data.circleID?.id || undefined,
    avatar: data.avatar || undefined,
    settings: data.settings || undefined
  };

  return cleanUser;
};

export const useUsers = (): UseUsersReturn => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [totalUsers, setTotalUsers] = useState(0);
  const [stats, setStats] = useState({
    total: 0,
    active: 0,
    inactive: 0,
    admin: 0,
  });
  const [tableState, setTableState] = useState<UserTableState>(defaultTableState);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      setError(null);

      const usersRef = collection(db, 'users') as CollectionReference<User>;
      let constraints = [];

      // Add filters
      if (tableState.filters.status === 'active') {
        constraints.push(where('isActive', '==', true));
      } else if (tableState.filters.status === 'inactive') {
        constraints.push(where('isActive', '==', false));
      }

      // Add sorting
      if (tableState.sort) {
        constraints.push(orderBy(tableState.sort.field, tableState.sort.direction));
      }

      // Add pagination
      constraints.push(limit(tableState.pageSize));

      const baseQuery = query(usersRef, ...constraints);
      const snapshot = await getDocs(baseQuery);

      const fetchedUsers = snapshot.docs.map(doc => cleanUserData(doc.data(), doc.id));

      // Calculate stats
      const activeUsers = fetchedUsers.filter(user => user.isActive).length;
      const inactiveUsers = fetchedUsers.filter(user => !user.isActive).length;
      const adminUsers = fetchedUsers.filter(user => user.role === 'admin').length;

      setUsers(fetchedUsers);
      setTotalUsers(snapshot.size);
      setStats({
        total: snapshot.size,
        active: activeUsers,
        inactive: inactiveUsers,
        admin: adminUsers,
      });

    } catch (err) {
      console.error('Error fetching users:', err);
      setError(err instanceof Error ? err : new Error('An error occurred while fetching users'));
      toast.error('Failed to fetch users');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [tableState]);

  const handleTableStateChange = (newState: UserTableState) => {
    setTableState(newState);
  };

  const handleUpdateStatus = async (userId: string, newStatus: boolean) => {
    try {
      await firebaseService.users.update(userId, {
        isActive: newStatus,
        updatedAt: now()
      });
      await fetchUsers(); // Refresh the data
      toast.success(`User ${newStatus ? 'activated' : 'deactivated'} successfully`);
    } catch (error) {
      console.error('Error updating user status:', error);
      toast.error('Failed to update user status');
    }
  };

  const handleUpdateRole = async (userId: string, newRole: 'user' | 'admin' | 'moderator') => {
    try {
      await firebaseService.users.update(userId, {
        role: newRole,
        updatedAt: now()
      });
      await fetchUsers(); // Refresh the data
      toast.success('User role updated successfully');
    } catch (error) {
      console.error('Error updating user role:', error);
      toast.error('Failed to update user role');
    }
  };

  const handleCreateUser = async (userData: {
    email: string;
    firstName: string;
    lastName: string;
    phoneNumber?: string;
    role?: 'user' | 'admin' | 'moderator';
    circleId?: string;
    isActive?: boolean;
  }): Promise<User | null> => {
    try {
      const newUser = await firebaseService.users.createUser(userData);
      await fetchUsers(); // Refresh the data
      toast.success('User created successfully');
      return newUser;
    } catch (error) {
      console.error('Error creating user:', error);
      toast.error('Failed to create user');
      return null;
    }
  };

  const handleUpdateUser = async (userId: string, updates: {
    firstName?: string;
    lastName?: string;
    email?: string;
    phoneNumber?: string;
    role?: 'user' | 'admin' | 'moderator';
    circleId?: string;
    isActive?: boolean;
  }): Promise<User | null> => {
    try {
      const updatedUser = await firebaseService.users.updateUserDetails(userId, updates);
      await fetchUsers(); // Refresh the data
      toast.success('User updated successfully');
      return updatedUser;
    } catch (error) {
      console.error('Error updating user:', error);
      toast.error('Failed to update user');
      return null;
    }
  };

  const handleDeleteUser = async (userId: string): Promise<boolean> => {
    try {
      await firebaseService.users.deleteUser(userId);
      await fetchUsers(); // Refresh the data
      toast.success('User deleted successfully');
      return true;
    } catch (error) {
      console.error('Error deleting user:', error);
      toast.error('Failed to delete user');
      return false;
    }
  };

  const handleGetUserById = async (userId: string): Promise<User | null> => {
    try {
      return await firebaseService.users.getUserById(userId);
    } catch (error) {
      console.error('Error getting user by ID:', error);
      toast.error('Failed to get user details');
      return null;
    }
  };

  const handleCheckEmailExists = async (email: string, excludeUserId?: string): Promise<boolean> => {
    try {
      return await firebaseService.users.checkEmailExists(email, excludeUserId);
    } catch (error) {
      console.error('Error checking email existence:', error);
      return false;
    }
  };

  return {
    users,
    loading,
    error,
    totalUsers,
    stats,
    tableState,
    handleTableStateChange,
    handleUpdateStatus,
    handleUpdateRole,
    handleCreateUser,
    handleUpdateUser,
    handleDeleteUser,
    handleGetUserById,
    handleCheckEmailExists,
  };
}; 