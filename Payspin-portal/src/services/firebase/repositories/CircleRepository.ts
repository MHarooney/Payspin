import { 
  query, 
  where, 
  orderBy, 
  limit, 
  collection, 
  doc, 
  getDocs,
  getDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  Timestamp
} from 'firebase/firestore';
import { BaseRepository } from '../BaseRepository';
import { Circle, CircleUser, CircleAnalytics } from '../../../types/firestore';
import { db } from '../../../config/firebase';
import { now, timestampToDate } from '../../../utils/date';

export class CircleRepository extends BaseRepository<Circle> {
  constructor() {
    super('circles');
  }

  // Get circles by status
  async getCirclesByStatus(status: 'active' | 'completed' | 'pending' | 'cancelled'): Promise<Circle[]> {
    try {
      const q = query(this.collectionRef, where('circle_status', '==', status));
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting circles by status:', error);
      throw error;
    }
  }

  // Get active circles
  async getActiveCircles(): Promise<Circle[]> {
    return this.getCirclesByStatus('active');
  }

  // Get completed circles
  async getCompletedCircles(): Promise<Circle[]> {
    return this.getCirclesByStatus('completed');
  }

  // Get circles by admin
  async getCirclesByAdmin(adminId: string): Promise<Circle[]> {
    try {
      const q = query(this.collectionRef, where('adminDocRef', '==', adminId));
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting circles by admin:', error);
      throw error;
    }
  }

  // Get public circles
  async getPublicCircles(): Promise<Circle[]> {
    try {
      const q = query(this.collectionRef, where('isPrivate', '==', false));
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting public circles:', error);
      throw error;
    }
  }

  // Search circles by name or description
  async searchCircles(searchTerm: string): Promise<Circle[]> {
    try {
      const allCircles = await this.getAll();
      const searchLower = searchTerm.toLowerCase();
      
      return allCircles.filter(circle => 
        circle.name.toLowerCase().includes(searchLower) ||
        (circle.description?.toLowerCase().includes(searchLower) ?? false)
      );
    } catch (error) {
      console.error('Error searching circles:', error);
      throw error;
    }
  }

  // Get circle statistics
  async getCircleStats(): Promise<{
    total: number;
    active: number;
    completed: number;
    newThisMonth: number;
    totalVolume: number;
    averageSize: number;
  }> {
    try {
      const [total, active, completed, newThisMonth, allCircles] = await Promise.all([
        this.count(),
        this.count({ circle_status: 'active' }),
        this.count({ circle_status: 'completed' }),
        this.getNewCirclesThisMonth().then(circles => circles.length),
        this.getAll(),
      ]);

      const totalVolume = allCircles.reduce((sum, circle) => sum + circle.totalAmount, 0);
      const averageSize = allCircles.length > 0 
        ? allCircles.reduce((sum, circle) => sum + circle.currentParticipants, 0) / allCircles.length 
        : 0;

      return {
        total,
        active,
        completed,
        newThisMonth,
        totalVolume,
        averageSize,
      };
    } catch (error) {
      console.error('Error getting circle stats:', error);
      throw error;
    }
  }

  // Update circle status
  async updateCircleStatus(circleId: string, status: 'active' | 'completed' | 'pending' | 'cancelled'): Promise<Circle> {
    return this.update(circleId, { circle_status: status });
  }

  // Update circle turn
  async updateCircleTurn(circleId: string, turn: number): Promise<Circle> {
    return this.update(circleId, { 
      currentTurn: turn,
    });
  }

  // === Circle Users Subcollection Methods ===

  // Get circle users
  async getCircleUsers(circleId: string): Promise<CircleUser[]> {
    try {
      const circleUsersRef = collection(db, 'circles', circleId, 'circleUsers');
      const querySnapshot = await getDocs(circleUsersRef);
      
      return querySnapshot.docs.map(doc => {
        const data = this.convertTimestamp(doc.data());
        return { id: doc.id, ...data } as CircleUser;
      });
    } catch (error) {
      console.error('Error getting circle users:', error);
      throw error;
    }
  }

  // Get circle user by ID
  async getCircleUser(circleId: string, userId: string): Promise<CircleUser | null> {
    try {
      const userDocRef = doc(db, 'circles', circleId, 'circleUsers', userId);
      const userDocSnap = await getDoc(userDocRef);
      
      if (userDocSnap.exists()) {
        const data = this.convertTimestamp(userDocSnap.data());
        return { id: userDocSnap.id, ...data } as CircleUser;
      }
      return null;
    } catch (error) {
      console.error('Error getting circle user:', error);
      throw error;
    }
  }

  // Add user to circle
  async addUserToCircle(circleId: string, circleUser: Omit<CircleUser, 'id'>): Promise<CircleUser> {
    try {
      const circleUsersRef = collection(db, 'circles', circleId, 'circleUsers');
      const preparedData = this.prepareForFirestore({
        ...circleUser,
        createdAt: now(),
        updatedAt: now(),
      });

      const docRef = await addDoc(circleUsersRef, preparedData);
      
      // Get the created document
      const createdUser = await this.getCircleUser(circleId, docRef.id);
      if (!createdUser) {
        throw new Error('Failed to retrieve created circle user');
      }

      // Update circle participant count
      const circle = await this.getById(circleId);
      if (circle) {
        await this.update(circleId, {
          currentParticipants: (circle.currentParticipants || 0) + 1,
        });
      }

      return createdUser;
    } catch (error) {
      console.error('Error adding user to circle:', error);
      throw error;
    }
  }

  // Update circle user
  async updateCircleUser(circleId: string, userId: string, data: Partial<CircleUser>): Promise<CircleUser> {
    try {
      const userDocRef = doc(db, 'circles', circleId, 'circleUsers', userId);
      const preparedData = this.prepareForFirestore({
        ...data,
        updatedAt: now(),
      });

      await updateDoc(userDocRef, preparedData);
      
      const updatedUser = await this.getCircleUser(circleId, userId);
      if (!updatedUser) {
        throw new Error('Failed to retrieve updated circle user');
      }
      
      return updatedUser;
    } catch (error) {
      console.error('Error updating circle user:', error);
      throw error;
    }
  }

  // Remove user from circle
  async removeUserFromCircle(circleId: string, userId: string): Promise<void> {
    try {
      const userDocRef = doc(db, 'circles', circleId, 'circleUsers', userId);
      await deleteDoc(userDocRef);

      // Update circle participant count
      const circle = await this.getById(circleId);
      if (circle && circle.currentParticipants > 0) {
        await this.update(circleId, {
          currentParticipants: circle.currentParticipants - 1,
        });
      }
    } catch (error) {
      console.error('Error removing user from circle:', error);
      throw error;
    }
  }

  // Get circle users by turn
  async getCircleUsersByTurn(circleId: string, turn: number): Promise<CircleUser[]> {
    try {
      const circleUsersRef = collection(db, 'circles', circleId, 'circleUsers');
      const q = query(circleUsersRef, where('turn', '==', turn));
      const querySnapshot = await getDocs(q);
      
      return querySnapshot.docs.map(doc => {
        const data = this.convertTimestamp(doc.data());
        return { id: doc.id, ...data } as CircleUser;
      });
    } catch (error) {
      console.error('Error getting circle users by turn:', error);
      throw error;
    }
  }

  // Get circle users by payment status
  async getCircleUsersByPaymentStatus(circleId: string, status: 'pending' | 'paid' | 'processing'): Promise<CircleUser[]> {
    try {
      const circleUsersRef = collection(db, 'circles', circleId, 'circleUsers');
      const q = query(circleUsersRef, where('paymentStatus', '==', status));
      const querySnapshot = await getDocs(q);
      
      return querySnapshot.docs.map(doc => {
        const data = this.convertTimestamp(doc.data());
        return { id: doc.id, ...data } as CircleUser;
      });
    } catch (error) {
      console.error('Error getting circle users by payment status:', error);
      throw error;
    }
  }

  // Get circle analytics
  async getCircleAnalytics(circleId: string): Promise<CircleAnalytics> {
    try {
      const [circle, circleUsers] = await Promise.all([
        this.getById(circleId),
        this.getCircleUsers(circleId),
      ]);

      if (!circle) {
        throw new Error('Circle not found');
      }

      const activeUsers = circleUsers.filter(user => user.isActive);
      const paidUsers = circleUsers.filter(user => user.paymentStatus === 'paid');
      const pendingUsers = circleUsers.filter(user => user.paymentStatus === 'pending');
      
      // Calculate average payment time (simplified)
      const usersWithPayments = circleUsers.filter(user => user.lastPaymentDate);
      const averagePaymentTime = usersWithPayments.length > 0 
        ? usersWithPayments.reduce((sum, user) => {
            if (user.lastPaymentDate && user.joinedAt) {
              const paymentDate = timestampToDate(user.lastPaymentDate);
              const joinDate = timestampToDate(user.joinedAt);
              if (paymentDate && joinDate) {
                return sum + (paymentDate.getTime() - joinDate.getTime()) / (1000 * 60 * 60 * 24);
              }
            }
            return sum;
          }, 0) / usersWithPayments.length
        : 0;

      const dropoutRate = circle.maxParticipants > 0 
        ? ((circle.maxParticipants - activeUsers.length) / circle.maxParticipants) * 100
        : 0;

      return {
        circleId,
        participantCount: activeUsers.length,
        totalVolume: circle.totalAmount,
        completedPayments: paidUsers.length,
        pendingPayments: pendingUsers.length,
        averagePaymentTime: Math.round(averagePaymentTime * 100) / 100,
        dropoutRate: Math.round(dropoutRate * 100) / 100,
      };
    } catch (error) {
      console.error('Error getting circle analytics:', error);
      throw error;
    }
  }

  // Helper methods
  private convertQuerySnapshot(querySnapshot: any): Circle[] {
    return querySnapshot.docs.map((doc: any) => {
      const data = this.convertTimestamp(doc.data());
      return { id: doc.id, ...data } as Circle;
    });
  }

  // Get new circles this month
  private async getNewCirclesThisMonth(): Promise<Circle[]> {
    const firstDayOfMonth = new Date();
    firstDayOfMonth.setDate(1);
    firstDayOfMonth.setHours(0, 0, 0, 0);
    
    const circles = await this.getAll();
    return circles.filter(circle => {
      const createdAt = circle.createdAt ? timestampToDate(circle.createdAt) : null;
      return createdAt && createdAt >= firstDayOfMonth;
    });
  }
} 