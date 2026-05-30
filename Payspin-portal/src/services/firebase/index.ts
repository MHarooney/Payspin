// Service container for managing all Firebase repositories
import { UserRepository } from './repositories/UserRepository';
import { CircleRepository } from './repositories/CircleRepository';
import { PostRepository } from './repositories/PostRepository';
import { PostTypeRepository } from './repositories/PostTypeRepository';
import { PostSubtypeRepository } from './repositories/PostSubtypeRepository';
import { BaseRepository } from './BaseRepository';
import { storageService } from './storage';
import { 
  Notification, 
  Offer, 
  PaymentMethod, 
  CirclePayout,
  DashboardStats,
  Circle,
  User,
  FirestoreDocument
} from '../../types/firestore';
import { Timestamp } from 'firebase/firestore';
import { FirebaseDateUtils } from '../../utils/firebase-date';

interface UserStats {
  total: number;
  active: number;
  inactive: number;
  newThisMonth: number;
}

interface CircleStats {
  total: number;
  active: number;
  newThisMonth: number;
  totalVolume: number;
  averageSize: number;
}

interface PayoutStats {
  totalPayouts: number;
  totalAmount: number;
}

type CreateOffer = Omit<Offer, keyof FirestoreDocument>;
type CreatePaymentMethod = Omit<PaymentMethod, keyof FirestoreDocument>;



// Notification Repository
export class NotificationRepository extends BaseRepository<Notification> {
  constructor() {
    super('notifications');
  }

  async getNotificationsByRecipient(userId: string): Promise<Notification[]> {
    return this.search('recipient' as keyof Notification, userId);
  }

  async getUnreadNotifications(userId: string): Promise<Notification[]> {
    try {
      const userNotifications = await this.getNotificationsByRecipient(userId);
      return userNotifications.filter(notification => !notification.isRead);
    } catch (error) {
      console.error('Error getting unread notifications:', error);
      throw error;
    }
  }

  async markAsRead(notificationId: string): Promise<Notification> {
    return this.update(notificationId, {
      isRead: true,
      readAt: Timestamp.now(),
    });
  }

  async markNotificationAsRead(notificationId: string): Promise<Notification> {
    return this.update(notificationId, {
      isRead: true,
      readAt: Timestamp.now(),
    });
  }
}

// Offer Repository
export class OfferRepository extends BaseRepository<Offer> {
  constructor() {
    super('offers');
  }

  async getActiveOffers(): Promise<Offer[]> {
    return this.search('isActive', true);
  }

  async getOffersByType(type: 'discount' | 'cashback' | 'bonus' | 'referral'): Promise<Offer[]> {
    return this.search('type', type);
  }

  async activateOffer(offerId: string): Promise<Offer> {
    return this.update(offerId, { isActive: true });
  }

  async deactivateOffer(offerId: string): Promise<Offer> {
    return this.update(offerId, { isActive: false });
  }
}

// Payment Method Repository
export class PaymentMethodRepository extends BaseRepository<PaymentMethod> {
  constructor() {
    super('payment_methods');
  }

  async getActivePaymentMethods(): Promise<PaymentMethod[]> {
    return this.search('isActive', true);
  }

  async getPaymentMethodsByType(type: 'bank_transfer' | 'mobile_money' | 'card' | 'digital_wallet'): Promise<PaymentMethod[]> {
    return this.search('type', type);
  }
}

// Circle Payout Repository
export class CirclePayoutRepository extends BaseRepository<CirclePayout> {
  constructor() {
    super('Circle_Payouts');
  }

  async getPayoutsByCircle(circleId: string): Promise<CirclePayout[]> {
    return this.search('circleId', circleId);
  }

  async getPayoutsByStatus(status: 'pending' | 'paid' | 'processing' | 'failed'): Promise<CirclePayout[]> {
    return this.search('status', status);
  }

  async getPayoutsByParticipant(participantId: string): Promise<CirclePayout[]> {
    return this.search('participantId' as keyof CirclePayout, participantId);
  }

  async completePayout(payoutId: string, transactionId?: string): Promise<CirclePayout> {
    return this.update(payoutId, {
      status: 'paid',
      completedDate: Timestamp.now(),
      ...(transactionId && { transactionId }),
    });
  }

  async markPayoutAsPaid(payoutId: string, transactionId?: string): Promise<CirclePayout> {
    return this.update(payoutId, {
      status: 'paid',
      completedDate: FirebaseDateUtils.now(),
      ...(transactionId && { transactionId }),
    });
  }
}

// Main service container implementing Singleton pattern
export class FirebaseService {
  private static instance: FirebaseService;
  
  // Repository instances
  public readonly users: UserRepository;
  public readonly circles: CircleRepository;
  public readonly posts: PostRepository;
  public readonly postTypes: PostTypeRepository;
  public readonly postSubtypes: PostSubtypeRepository;

  public readonly notifications: NotificationRepository;
  public readonly offers: OfferRepository;
  public readonly paymentMethods: PaymentMethodRepository;
  public readonly circlePayouts: CirclePayoutRepository;
  public readonly storage: typeof storageService;

  private constructor() {
    // Initialize all repositories
    this.users = new UserRepository();
    this.circles = new CircleRepository();
    this.posts = new PostRepository();
    this.postTypes = new PostTypeRepository();
    this.postSubtypes = new PostSubtypeRepository();

    this.notifications = new NotificationRepository();
    this.offers = new OfferRepository();
    this.paymentMethods = new PaymentMethodRepository();
    this.circlePayouts = new CirclePayoutRepository();
    this.storage = storageService;
  }

  // Singleton pattern implementation
  public static getInstance(): FirebaseService {
    if (!FirebaseService.instance) {
      FirebaseService.instance = new FirebaseService();
    }
    return FirebaseService.instance;
  }

  // Get comprehensive dashboard statistics
  async getDashboardStats(): Promise<DashboardStats> {
    try {
      const userStats = await this.getUserStats();
      const circleStats = await this.getCircleStats();
      const payoutStats = await this.getPayoutStats();

      return {
        totalUsers: userStats.total,
        activeUsers: userStats.active,
        inactiveUsers: userStats.inactive,
        totalCircles: circleStats.total,
        activeCircles: circleStats.active,
        totalPayouts: payoutStats.totalPayouts,
        totalVolume: circleStats.totalVolume,
        newUsersThisMonth: userStats.newThisMonth,
        newCirclesThisMonth: circleStats.newThisMonth,
        averageCircleSize: circleStats.averageSize,
        completionRate: await this.calculateCompletionRate(),
      };
    } catch (error) {
      console.error('Error getting dashboard stats:', error);
      throw error;
    }
  }

  // Calculate system-wide metrics
  private async getTotalPayoutStats(): Promise<{ totalPayouts: number; totalAmount: number }> {
    try {
      const allPayouts = await this.circlePayouts.getAll();
      const completedPayouts = allPayouts.filter(payout => payout.status === 'paid');
      
      return {
        totalPayouts: completedPayouts.length,
        totalAmount: completedPayouts.reduce((sum, payout) => sum + payout.amount, 0),
      };
    } catch (error) {
      console.error('Error getting total payout stats:', error);
      return { totalPayouts: 0, totalAmount: 0 };
    }
  }

  private async calculateCompletionRate(): Promise<number> {
    try {
      const circles = await this.circles.getAll();
      if (circles.length === 0) return 0;
      
      const completedCircles = circles.filter(circle => circle.circle_status === 'completed');
      return (completedCircles.length / circles.length) * 100;
    } catch (error) {
      console.error('Error calculating completion rate:', error);
      return 0;
    }
  }

  // Utility methods for common operations
  async searchAcrossCollections(searchTerm: string): Promise<{
    users: any[];
    circles: any[];
    posts: any[];
  }> {
    try {
      const [users, circles, posts] = await Promise.all([
        this.users.searchUsers(searchTerm),
        this.circles.searchCircles(searchTerm),
        this.posts.searchPosts(searchTerm),
      ]);

      return { users, circles, posts };
    } catch (error) {
      console.error('Error searching across collections:', error);
      throw error;
    }
  }

  // Health check for all services
  async healthCheck(): Promise<{
    status: 'healthy' | 'unhealthy';
    services: { [key: string]: boolean };
    timestamp: Date;
  }> {
    const services: { [key: string]: boolean } = {};
    let allHealthy = true;

    try {
      // Test each repository
      const tests = [
        { name: 'users', test: () => this.users.count() },
        { name: 'circles', test: () => this.circles.count() },
        { name: 'posts', test: () => this.posts.count() },

        { name: 'notifications', test: () => this.notifications.count() },
        { name: 'offers', test: () => this.offers.count() },
        { name: 'paymentMethods', test: () => this.paymentMethods.count() },
        { name: 'circlePayouts', test: () => this.circlePayouts.count() },
      ];

      await Promise.all(
        tests.map(async ({ name, test }) => {
          try {
            await test();
            services[name] = true;
          } catch (error) {
            console.error(`Health check failed for ${name}:`, error);
            services[name] = false;
            allHealthy = false;
          }
        })
      );

      return {
        status: allHealthy ? 'healthy' : 'unhealthy',
        services,
        timestamp: new Date(),
      };
    } catch (error) {
      console.error('Health check failed:', error);
      return {
        status: 'unhealthy',
        services,
        timestamp: new Date(),
      };
    }
  }

  async getUserStats(): Promise<UserStats> {
    try {
      const users = await this.users.getAllUsers();
      const firstDayOfMonth = FirebaseDateUtils.getFirstDayOfMonth();

      return {
        total: users.length,
        active: users.filter(user => user.isActive).length,
        inactive: users.filter(user => !user.isActive).length,
        newThisMonth: users.filter(user => 
          user.createdAt && FirebaseDateUtils.isAfter(user.createdAt, firstDayOfMonth)
        ).length
      };
    } catch (error) {
      console.error('Error getting user stats:', error);
      throw error;
    }
  }

  async getCircleStats(): Promise<CircleStats> {
    try {
      const circles = await this.circles.getAll();
      const firstDayOfMonth = FirebaseDateUtils.getFirstDayOfMonth();

      return {
        total: circles.length,
        active: circles.filter(circle => circle.circle_status === 'active').length,
        newThisMonth: circles.filter(circle => 
          circle.createdAt && FirebaseDateUtils.isAfter(circle.createdAt, firstDayOfMonth)
        ).length,
        totalVolume: circles.reduce((sum, circle) => sum + circle.totalAmount, 0),
        averageSize: circles.length > 0 ? circles.reduce((sum, circle) => sum + circle.currentParticipants, 0) / circles.length : 0
      };
    } catch (error) {
      console.error('Error getting circle stats:', error);
      throw error;
    }
  }

  async getPayoutStats(): Promise<PayoutStats> {
    try {
      const payouts = await this.circlePayouts.getAll();
      const completedPayouts = payouts.filter(payout => payout.status === 'paid');
      
      return {
        totalPayouts: completedPayouts.length,
        totalAmount: completedPayouts.reduce((sum, payout) => sum + payout.amount, 0),
      };
    } catch (error) {
      console.error('Error getting payout stats:', error);
      return { totalPayouts: 0, totalAmount: 0 };
    }
  }



  // Notification operations
  async markNotificationAsRead(notificationId: string): Promise<Notification> {
    return this.notifications.update(notificationId, {
      isRead: true,
      readAt: Timestamp.now(),
    });
  }

  // Payout operations
  async markPayoutAsPaid(payoutId: string, transactionId?: string): Promise<CirclePayout> {
    return this.circlePayouts.update(payoutId, {
      status: 'paid',
      completedDate: Timestamp.now(),
      ...(transactionId && { transactionId }),
    });
  }

  // Offer operations
  async createOffer(data: CreateOffer): Promise<Offer> {
    return this.offers.create({
      ...data,
      usedCount: 0,
      isActive: true,
    });
  }

  async updateOffer(offerId: string, data: Partial<Offer>): Promise<Offer> {
    return this.offers.update(offerId, data);
  }

  // Payment method operations
  async createPaymentMethod(data: CreatePaymentMethod): Promise<PaymentMethod> {
    return this.paymentMethods.create(data);
  }

  async updatePaymentMethod(methodId: string, data: Partial<PaymentMethod>): Promise<PaymentMethod> {
    return this.paymentMethods.update(methodId, data);
  }

  // Circle operations
  async updateCircleStatus(circleId: string, status: Circle['circle_status']): Promise<Circle> {
    return this.circles.update(circleId, { circle_status: status });
  }

  async updateCircleTurn(circleId: string, turn: number): Promise<Circle> {
    return this.circles.update(circleId, { currentTurn: turn });
  }

  // User operations
  async updateUserStatus(userId: string, isActive: boolean): Promise<User> {
    return this.users.update(userId, { isActive });
  }

  async updateUserRole(userId: string, role: User['role']): Promise<User> {
    return this.users.update(userId, { role });
  }
}

// Export the singleton instance
export const firebaseService = FirebaseService.getInstance();

// Individual repositories are already exported above

// Export the service as default
export default firebaseService; 