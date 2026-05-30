import { collection, getDocs, QueryConstraint, where, orderBy, limit, startAfter, QuerySnapshot, DocumentData, query, Query, Timestamp, addDoc, deleteDoc, doc } from 'firebase/firestore';
import { BaseRepository } from '../BaseRepository';
import { User, DashboardStats } from '../../../types/firestore';
import { db } from '../../../config/firebase';
import { now, timestampToDate } from '../../../utils/date';

export class UserRepository extends BaseRepository<User> {
  constructor() {
    super('users');
  }

  async getAllUsers(): Promise<User[]> {
    try {
      const querySnapshot = await getDocs(this.collectionRef);
      const now = Timestamp.now();
      return querySnapshot.docs.map(doc => {
        const data = doc.data();
        const cleanUser: User = {
          id: doc.id,
          email: data.email || '',
          displayName: data.display_name || `${data.First_Name || ''} ${data.Last_Name || ''}`.trim() || 'Unknown User',
          firstName: data.First_Name || '',
          lastName: data.Last_Name || '',
          phoneNumber: data.phone_number || '',
          isActive: Boolean(data.isActive !== false), // Default to true if not specified
          role: data.role || 'user',
          createdAt: data.created_time instanceof Timestamp ? data.created_time : (data.createdAt instanceof Timestamp ? data.createdAt : now),
          updatedAt: data.updatedAt instanceof Timestamp ? data.updatedAt : now,
          lastLoginAt: data.lastLoginAt instanceof Timestamp ? data.lastLoginAt : undefined,
          circleId: data.circleIDnotRef || data.circleID?.id || undefined,
          avatar: data.avatar || undefined,
          settings: data.settings || undefined
        };
        return cleanUser;
      });
    } catch (error) {
      console.error('Error getting all users:', error);
      throw error;
    }
  }

  // Get users by role
  async getUsersByRole(role: 'user' | 'admin' | 'moderator'): Promise<User[]> {
    try {
      const q = query(this.collectionRef, where('role', '==', role));
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting users by role:', error);
      throw error;
    }
  }

  // Get active users
  async getActiveUsers(): Promise<User[]> {
    try {
      const q = query(this.collectionRef, where('isActive', '==', true));
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting active users:', error);
      throw error;
    }
  }

  // Get inactive users
  async getInactiveUsers(): Promise<User[]> {
    try {
      const q = query(this.collectionRef, where('isActive', '==', false));
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting inactive users:', error);
      throw error;
    }
  }

  // Get users who joined this month
  async getNewUsersThisMonth(): Promise<User[]> {
    try {
      const firstDayOfMonth = new Date();
      firstDayOfMonth.setDate(1);
      firstDayOfMonth.setHours(0, 0, 0, 0);
      
      const users = await this.getAllUsers();
      return users.filter(user => {
        const createdAt = user.createdAt ? timestampToDate(user.createdAt) : null;
        return createdAt && createdAt >= firstDayOfMonth;
      });
    } catch (error) {
      console.error('Error getting new users this month:', error);
      throw error;
    }
  }

  // Get recently active users
  async getRecentlyActiveUsers(limitCount: number = 10): Promise<User[]> {
    try {
      const allUsers = await this.getAllUsers();
      return allUsers
        .filter(user => user.lastLoginAt) // Filter out users without lastLoginAt
        .sort((a, b) => {
          const dateA = timestampToDate(a.lastLoginAt);
          const dateB = timestampToDate(b.lastLoginAt);
          if (!dateA || !dateB) return 0;
          return dateB.getTime() - dateA.getTime();
        })
        .slice(0, limitCount);
    } catch (error) {
      console.error('Error getting recently active users:', error);
      throw error;
    }
  }

  // Search users
  async searchUsers(searchTerm: string): Promise<User[]> {
    try {
      const allUsers = await this.getAllUsers();
      const searchLower = searchTerm.toLowerCase();
      
      return allUsers.filter(user => 
        user.displayName.toLowerCase().includes(searchLower) ||
        user.email.toLowerCase().includes(searchLower) ||
        user.firstName.toLowerCase().includes(searchLower) ||
        user.lastName.toLowerCase().includes(searchLower) ||
        (user.phoneNumber || '').includes(searchTerm)
      );
    } catch (error) {
      console.error('Error searching users:', error);
      throw error;
    }
  }

  // Get filtered users
  async getFilteredUsers(filters: {
    isActive?: boolean;
    role?: 'user' | 'admin' | 'moderator';
    dateRange?: { start: Date; end: Date };
  }): Promise<User[]> {
    try {
      let users = await this.getAllUsers();

      if (filters.isActive !== undefined) {
        users = users.filter(user => user.isActive === filters.isActive);
      }

      if (filters.role) {
        users = users.filter(user => user.role === filters.role);
      }

      if (filters.dateRange) {
        users = users.filter(user => {
          const createdAt = user.createdAt;
          if (!createdAt) return false;
          const date = timestampToDate(createdAt);
          return date && date >= filters.dateRange!.start && date <= filters.dateRange!.end;
        });
      }

      return users;
    } catch (error) {
      console.error('Error filtering users:', error);
      throw error;
    }
  }

  // Update user status
  async updateUserStatus(userId: string, isActive: boolean): Promise<User | null> {
    try {
      return await this.update(userId, { isActive });
    } catch (error) {
      console.error('Error updating user status:', error);
      return null;
    }
  }

  // Update user role
  async updateUserRole(userId: string, role: 'user' | 'admin' | 'moderator'): Promise<User | null> {
    try {
      return await this.update(userId, { role });
    } catch (error) {
      console.error('Error updating user role:', error);
      return null;
    }
  }

  // Get user statistics
  async getUserStats(): Promise<{
    total: number;
    active: number;
    inactive: number;
  }> {
    try {
      const users = await this.getAllUsers();
      return {
        total: users.length,
        active: users.filter(user => user.isActive).length,
        inactive: users.filter(user => !user.isActive).length,
      };
    } catch (error) {
      console.error('Error getting user stats:', error);
      return {
        total: 0,
        active: 0,
        inactive: 0,
      };
    }
  }

  // Deactivate user (soft delete)
  async deactivateUser(userId: string): Promise<User | null> {
    try {
      return await this.update(userId, { 
        isActive: false
      });
    } catch (error) {
      console.error('Error deactivating user:', error);
      return null;
    }
  }

  // Reactivate user
  async reactivateUser(userId: string): Promise<User | null> {
    try {
      return await this.update(userId, { 
        isActive: true
      });
    } catch (error) {
      console.error('Error reactivating user:', error);
      return null;
    }
  }

  // Get users with pagination and search
  async getUsersWithSearch(
    page: number = 1,
    pageSize: number = 10,
    searchTerm?: string,
    role?: string,
    isActive?: boolean
  ) {
    try {
      let users = await this.getAllUsers();

      // Apply filters
      if (searchTerm) {
        const searchLower = searchTerm.toLowerCase();
        users = users.filter(user => 
          (user.email?.toLowerCase().includes(searchLower) || false) ||
          (user.firstName?.toLowerCase().includes(searchLower) || false) ||
          (user.lastName?.toLowerCase().includes(searchLower) || false) ||
          (user.displayName?.toLowerCase().includes(searchLower) || false)
        );
      }

      if (role) {
        users = users.filter(user => user.role === role);
      }

      if (isActive !== undefined) {
        users = users.filter(user => user.isActive === isActive);
      }

      // Apply pagination
      const total = users.length;
      const totalPages = Math.ceil(total / pageSize);
      const startIndex = (page - 1) * pageSize;
      const endIndex = startIndex + pageSize;
      const paginatedUsers = users.slice(startIndex, endIndex);

      return {
        success: true,
        data: paginatedUsers,
        pagination: {
          page,
          pageSize,
          total,
          totalPages,
          hasNext: page < totalPages,
          hasPrev: page > 1,
          limit: pageSize
        },
        timestamp: new Date()
      };
    } catch (error) {
      console.error('Error getting users with search:', error);
      return {
        success: false,
        data: [],
        pagination: {
          page,
          pageSize,
          total: 0,
          totalPages: 0,
          hasNext: false,
          hasPrev: false,
          limit: pageSize
        },
        timestamp: new Date()
      };
    }
  }

  // Create new user
  async createUser(userData: {
    email: string;
    firstName: string;
    lastName: string;
    phoneNumber?: string;
    role?: 'user' | 'admin' | 'moderator';
    circleId?: string;
    isActive?: boolean;
  }): Promise<User | null> {
    try {
      const newUser = {
        email: userData.email,
        First_Name: userData.firstName,
        Last_Name: userData.lastName,
        display_name: `${userData.firstName} ${userData.lastName}`.trim(),
        phone_number: userData.phoneNumber || '',
        role: userData.role || 'user',
        isActive: userData.isActive !== false, // Default to true
        circleIDnotRef: userData.circleId || '',
        created_time: now(),
        updatedAt: now(),
        uid: '', // Will be set by Firestore
      };

      const docRef = await addDoc(this.collectionRef, newUser);
      
      // Return the created user with the new ID
      return {
        id: docRef.id,
        email: newUser.email,
        displayName: newUser.display_name,
        firstName: newUser.First_Name,
        lastName: newUser.Last_Name,
        phoneNumber: newUser.phone_number,
        isActive: newUser.isActive,
        role: newUser.role,
        createdAt: newUser.created_time,
        updatedAt: newUser.updatedAt,
        circleId: newUser.circleIDnotRef,
      };
    } catch (error) {
      console.error('Error creating user:', error);
      throw error;
    }
  }

  // Update user details
  async updateUserDetails(userId: string, updates: {
    firstName?: string;
    lastName?: string;
    email?: string;
    phoneNumber?: string;
    role?: 'user' | 'admin' | 'moderator';
    circleId?: string;
    isActive?: boolean;
  }): Promise<User | null> {
    try {
      const updateData: any = {
        updatedAt: now()
      };

      if (updates.firstName !== undefined) {
        updateData.First_Name = updates.firstName;
        updateData.display_name = `${updates.firstName} ${updates.lastName || ''}`.trim();
      }

      if (updates.lastName !== undefined) {
        updateData.Last_Name = updates.lastName;
        updateData.display_name = `${updates.firstName || ''} ${updates.lastName}`.trim();
      }

      if (updates.email !== undefined) {
        updateData.email = updates.email;
      }

      if (updates.phoneNumber !== undefined) {
        updateData.phone_number = updates.phoneNumber;
      }

      if (updates.role !== undefined) {
        updateData.role = updates.role;
      }

      if (updates.circleId !== undefined) {
        updateData.circleIDnotRef = updates.circleId;
      }

      if (updates.isActive !== undefined) {
        updateData.isActive = updates.isActive;
      }

      return await this.update(userId, updateData);
    } catch (error) {
      console.error('Error updating user details:', error);
      throw error;
    }
  }

  // Delete user (hard delete)
  async deleteUser(userId: string): Promise<boolean> {
    try {
      const userDoc = doc(db, 'users', userId);
      await deleteDoc(userDoc);
      return true;
    } catch (error) {
      console.error('Error deleting user:', error);
      throw error;
    }
  }

  // Get user by ID
  async getUserById(userId: string): Promise<User | null> {
    try {
      const userDocRef = doc(db, 'users', userId);
      const userSnapshot = await getDocs(query(collection(db, 'users'), where('__name__', '==', userId)));
      
      if (userSnapshot.empty) {
        return null;
      }

      const userDoc = userSnapshot.docs[0];
      const data = userDoc.data();
      
      return {
        id: userDoc.id,
        email: data.email || '',
        displayName: data.display_name || `${data.First_Name || ''} ${data.Last_Name || ''}`.trim() || 'Unknown User',
        firstName: data.First_Name || '',
        lastName: data.Last_Name || '',
        phoneNumber: data.phone_number || '',
        isActive: Boolean(data.isActive !== false),
        role: data.role || 'user',
        createdAt: data.created_time instanceof Timestamp ? data.created_time : now(),
        updatedAt: data.updatedAt instanceof Timestamp ? data.updatedAt : now(),
        lastLoginAt: data.lastLoginAt instanceof Timestamp ? data.lastLoginAt : undefined,
        circleId: data.circleIDnotRef || data.circleID?.id || undefined,
        avatar: data.avatar || undefined,
        settings: data.settings || undefined
      };
    } catch (error) {
      console.error('Error getting user by ID:', error);
      throw error;
    }
  }

  // Check if email already exists
  async checkEmailExists(email: string, excludeUserId?: string): Promise<boolean> {
    try {
      const q = query(this.collectionRef, where('email', '==', email));
      const querySnapshot = await getDocs(q);
      
      if (excludeUserId) {
        // Check if any user with this email exists except the excluded user
        return querySnapshot.docs.some(doc => doc.id !== excludeUserId);
      }
      
      return !querySnapshot.empty;
    } catch (error) {
      console.error('Error checking email existence:', error);
      throw error;
    }
  }

  // Get users by circle ID
  async getUsersByCircle(circleId: string): Promise<User[]> {
    try {
      const q = query(this.collectionRef, where('circleIDnotRef', '==', circleId));
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting users by circle:', error);
      throw error;
    }
  }

  // Helper methods
  private async executeQuery(q: Query<DocumentData>): Promise<QuerySnapshot<DocumentData>> {
    const { getDocs } = await import('firebase/firestore');
    return getDocs(q);
  }

  private convertQuerySnapshot(querySnapshot: QuerySnapshot<DocumentData>): User[] {
    return querySnapshot.docs.map(doc => {
      const rawData = doc.data();
      const nowTimestamp = Timestamp.now();
      const cleanUser: User = {
        id: doc.id,
        email: rawData.email || '',
        displayName: rawData.display_name || `${rawData.First_Name || ''} ${rawData.Last_Name || ''}`.trim() || 'Unknown User',
        firstName: rawData.First_Name || '',
        lastName: rawData.Last_Name || '',
        phoneNumber: rawData.phone_number || '',
        isActive: Boolean(rawData.isActive !== false),
        role: rawData.role || 'user',
        createdAt: rawData.created_time instanceof Timestamp ? rawData.created_time : (rawData.createdAt instanceof Timestamp ? rawData.createdAt : nowTimestamp),
        updatedAt: rawData.updatedAt instanceof Timestamp ? rawData.updatedAt : nowTimestamp,
        lastLoginAt: rawData.lastLoginAt instanceof Timestamp ? rawData.lastLoginAt : undefined,
        circleId: rawData.circleIDnotRef || rawData.circleID?.id || undefined,
        avatar: rawData.avatar || undefined,
        settings: rawData.settings || undefined
      };
      return cleanUser;
    });
  }

  protected convertTimestamp(data: DocumentData): Partial<User> {
    const nowTimestamp = Timestamp.now();
    return {
      ...data,
      id: data.id,
      createdAt: data.createdAt instanceof Timestamp ? data.createdAt : nowTimestamp,
      updatedAt: data.updatedAt instanceof Timestamp ? data.updatedAt : nowTimestamp,
      lastLoginAt: data.lastLoginAt instanceof Timestamp ? data.lastLoginAt : undefined
    };
  }

  private convertUserData(data: any): Partial<User> {
    const now = Timestamp.now();
    return {
      ...data,
      id: data.id,
      createdAt: data.createdAt instanceof Timestamp ? data.createdAt : now,
      updatedAt: data.updatedAt instanceof Timestamp ? data.updatedAt : now,
      lastLoginAt: data.lastLoginAt instanceof Timestamp ? data.lastLoginAt : undefined,
    };
  }
} 