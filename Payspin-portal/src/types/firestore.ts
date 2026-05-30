
import { DocumentReference, Timestamp } from 'firebase/firestore';

// Base Firestore document interface
export interface FirestoreDocument {
  id: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Table filter interface
export interface TableFilters {
  status?: string;
  category?: string;
  role?: string;
  search?: string;
  [key: string]: string | undefined;
}

// User interface
export interface User extends FirestoreDocument {
  email: string;
  displayName: string;
  firstName: string;
  lastName: string;
  phoneNumber?: string;
  circleId?: string;
  isActive: boolean;
  role: 'user' | 'admin' | 'moderator';
  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastLoginAt?: Timestamp;
  avatar?: string;
  settings?: {
    notifications: boolean;
    theme: 'light' | 'dark';
  };
}

// User preferences interface
export interface UserPreferences {
  notifications: {
    email: boolean;
    push: boolean;
    sms: boolean;
  };
  language: string;
  currency: string;
  timezone: string;
}

// Circle interface
export interface Circle extends FirestoreDocument {
  adminDocRef: DocumentReference;
  months: number;
  circle_id: string;
  payment_per_month: number;
  endDate: Timestamp | null;
  adminNotificationRef: DocumentReference;
  name: string;
  finished: boolean;
  startdate: Timestamp | null;
  circle_status: 'active' | 'completed' | 'pending' | 'cancelled';
  description?: string;
  isPrivate?: boolean;
  currentTurn?: number;
  currentParticipants: number;
  maxParticipants: number;
  totalAmount: number;
  paymentAmount: number;
  generatedUsers: Array<{
    id: string;
    name: string;
    turn?: number;
    [key: string]: any;
  }>;
  roles: Array<{
    role: string;
    [key: string]: any;
  }>;
  RealUsers: Array<{
    id: string;
    name: string;
    turn?: number;
    admin?: boolean;
    UserImage?: string;
    phone?: number;
    [key: string]: any;
  }>;
}

// Circle User interface
export interface CircleUser extends FirestoreDocument {
  turn: number;
  CircleUserID: string;
  uId: DocumentReference;
  UserImage: string;
  user_id: string;
  phone: number;
  name: string;
  admin: boolean;
  isActive: boolean;
  paymentStatus: 'pending' | 'paid' | 'processing';
  lastPaymentDate: Timestamp | null;
  joinedAt: Timestamp | null;
  paymentDate: Timestamp | null;
}

// Payout Schedule interface
export interface PayoutSchedule {
  month: number;
  participantId: string;
  amount: number;
  dueDate: Timestamp;
  status: 'pending' | 'paid' | 'processing';
  paymentDate?: Timestamp;
}

// Circle Payout interface
export interface CirclePayout extends FirestoreDocument {
  circleId: string;
  userId: string;
  amount: number;
  status: 'pending' | 'processing' | 'paid' | 'failed';
  paymentMethod: string;
  transactionId?: string;
  completedDate?: Timestamp;
  failureReason?: string;
  metadata?: {
    [key: string]: any;
  };
}

// Post Type and Subtype interfaces
export interface PostType {
  id: string;
  name: string;
  label: string;
  description?: string;
  isActive: boolean;
  order: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface PostSubtype {
  id: string;
  postTypeId: string; // Reference to PostType
  name: string;
  label: string;
  description?: string;
  isActive: boolean;
  order: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Media interface for posts
export interface PostMedia {
  id: string;
  url: string;
  type: 'image' | 'video';
  alt?: string;
  caption?: string;
  order: number;
  isMain: boolean;
  createdAt: Timestamp;
}

// Enhanced Post interface
export interface Post extends FirestoreDocument {
  postType: string; // Reference to post type (News, Offer, Blog)
  postSubtype?: string; // Reference to post subtype (Travel, Gifts, etc.)
  postTitle: string;
  postLocation: string; // Mandatory location
  postDescription: string;
  postBodyPrimary: string;
  postBodySecondary?: string;
  isFeatured: boolean;
  postOrder: number;
  postUrl?: string; // URL for opening in browser
  mainImage?: string; // Main photo URL
  media: PostMedia[]; // Multiple videos/photos
  publishedAt?: Timestamp;
  isPublished: boolean;
  isDraft: boolean;
  
  // Legacy fields for backward compatibility
  title?: string;
  slug?: string;
  content?: string;
  excerpt?: string;
  categories?: string[];
  tags?: string[];
  author?: {
    id: string;
    name: string;
    email: string;
    avatar?: string;
  };
  status?: 'draft' | 'published' | 'archived';
  featuredImage?: string;
  readingTime?: number;
  likes?: number;
  views?: number;
  featured?: boolean;
  order?: number;
  location?: string;
  metaDescription?: string;
  metaKeywords?: string[];
  seoTitle?: string;
}

// Category interface
export interface Category extends FirestoreDocument {
  name: string;
  slug: string;
  description: string;
}



// Notification interface
export interface Notification extends FirestoreDocument {
  userId: string;
  title: string;
  message: string;
  type: 'info' | 'success' | 'warning' | 'error';
  isRead: boolean;
  readAt?: Timestamp;
  metadata?: {
    [key: string]: any;
  };
}

// Push Notification interface (subcollection)
export interface PushNotification extends FirestoreDocument {
  userId: string;
  title: string;
  body: string;
  data?: { [key: string]: any };
  sentAt: Timestamp;
  deliveryStatus: 'sent' | 'delivered' | 'failed' | 'clicked';
  fcmToken: string;
  flag: boolean;
}

// Offer interface - Clean admin interface
export interface Offer extends FirestoreDocument {
  title: string;
  description: string;
  type: 'discount' | 'cashback' | 'bonus' | 'referral' | 'special' | 'limited';
  value?: number;
  valueType?: 'percentage' | 'fixed';
  minAmount?: number;
  maxAmount?: number;
  startDate?: Timestamp;
  endDate?: Timestamp;
  isActive: boolean;
  usedCount: number;
  maxUses?: number;
  targetAudience: 'all' | 'new_users' | 'circle_participants' | 'premium_users' | 'students';
  conditions?: string[];
  featuredImage?: string;
  priority?: 'low' | 'medium' | 'high';
  category?: string;
  tags?: string[];
  views?: number;
  clicks?: number;
  conversionRate?: number;
  favoriteCount?: number;
}

// Firebase Offer interface - Matches existing database structure
export interface FirebaseOffer extends FirestoreDocument {
  label: string;
  description: string;
  imgUrl?: string;
  addedToFav?: string[];
}

// Payment Method interface
export interface PaymentMethod extends FirestoreDocument {
  name: string;
  type: 'bank' | 'card' | 'wallet' | 'other';
  provider: string;
  isActive: boolean;
  processingFee?: number;
  processingTime?: string;
  minAmount?: number;
  maxAmount?: number;
  supportedCurrencies: string[];
  metadata?: {
    [key: string]: any;
  };
}

// FCM Token interface
export interface FCMToken extends FirestoreDocument {
  fcm_token: string;
  device_type: string;
  created_at: Timestamp;
}

// Analytics interfaces
export interface DashboardStats {
  totalUsers: number;
  activeUsers: number;
  inactiveUsers: number;
  totalCircles: number;
  activeCircles: number;
  totalPayouts: number;
  totalVolume: number;
  newUsersThisMonth: number;
  newCirclesThisMonth: number;
  averageCircleSize: number;
  completionRate: number;
}

export interface CircleAnalytics {
  circleId: string;
  participantCount: number;
  totalVolume: number;
  completedPayments: number;
  pendingPayments: number;
  averagePaymentTime: number;
  dropoutRate: number;
}

// Chart data interfaces
export interface ChartData {
  labels: string[];
  datasets: {
    label: string;
    data: number[];
    backgroundColor?: string | string[];
    borderColor?: string | string[];
    borderWidth?: number;
  }[];
}

// API Response interfaces
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  timestamp: Timestamp;
}

export interface PaginatedResponse<T> {
  success: boolean;
  data: T[];
  pagination: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
    limit: number;
  };
  timestamp: Timestamp;
}

// Form interfaces
export interface CreateCircleForm {
  name: string;
  description: string;
  totalAmount: number;
  duration: number;
  maxParticipants: number;
  startDate: Timestamp;
}

export interface CreatePostForm {
  title: string;
  slug: string;
  content: string;
  excerpt: string;
  categories: string[];
  tags: string[];
  featuredImage?: File;
  status: 'draft' | 'published';
  featured?: boolean;
  order?: number;
  location?: string;
  readingTime?: number;
  seo?: {
    metaTitle?: string;
    metaDescription?: string;
    keywords?: string[];
  };
}



// Filter and sort interfaces
export interface SortConfig {
  field: string;
  direction: 'asc' | 'desc';
}

export interface TableState {
  page: number;
  pageSize: number;
  search?: string;
  sort?: {
    field: string;
    direction: 'asc' | 'desc';
  };
  filters?: Record<string, any>;
}

export interface UserTableState extends TableState {
  filters: {
    status?: 'active' | 'inactive';
    role?: 'user' | 'admin' | 'moderator';
  };
}

export interface PostTableState extends TableState {
  filters: {
    status?: 'draft' | 'published' | 'archived';
    categories?: string[];
    featured?: boolean;
  };
}



export interface OfferTableState extends TableState {
  filters: {
    isActive?: boolean;
    type?: 'discount' | 'cashback' | 'bonus' | 'referral' | 'special' | 'limited';
    targetAudience?: 'all' | 'new_users' | 'circle_participants' | 'premium_users' | 'students';
    category?: string;
    priority?: 'low' | 'medium' | 'high';
  };
}

export interface PostFilters {
  status?: Post['status'];
  postType?: string;
  postSubtype?: string;
  location?: string;
  categories?: string[];
  author?: string;
  tag?: string;
  search?: string;
  featured?: boolean;
}

export interface PostStats {
  total: number;
  published: number;
  drafts: number;
  archived: number;
  totalViews: number;
  totalLikes: number;
  categories: { [key: string]: number };
  popularTags: { tag: string; count: number }[];
}



export interface OfferStats {
  total: number;
  active: number;
  inactive: number;
  expired: number;
  totalUsage: number;
  totalClicks: number;
  averageConversionRate: number;
  byType: { [key: string]: number };
  byTargetAudience: { [key: string]: number };
  topPerforming: { id: string; label: string; clicks: number; conversions: number }[];
} 

// Blog interfaces
export interface Blog extends FirestoreDocument {
  title: string;
  content: string;
  excerpt?: string;
  slug: string;
  author: {
    id: string;
    name: string;
    email: string;
    avatar?: string;
  };
  status: 'draft' | 'published' | 'archived';
  featuredImage?: string;
  readingTime?: number;
  readTime?: number; // Alternative property name used in BlogRepository
  likes?: number;
  views?: number;
  featured?: boolean;
  order?: number;
  location?: string;
  metaDescription?: string;
  metaKeywords?: string[];
  seoTitle?: string;
  tags: string[];
  categories?: string[];
  category?: string; // Single category property used in BlogRepository
  publishedAt?: Timestamp;
  isPublished: boolean;
  isDraft: boolean;
}

export interface BlogFilters {
  status?: Blog['status'];
  author?: string;
  tag?: string;
  search?: string;
  featured?: boolean;
  category?: string;
}

export interface BlogStats {
  total: number;
  published: number;
  drafts: number;
  archived: number;
  totalViews: number;
  totalLikes: number;
  categories: { [key: string]: number };
  popularTags: { tag: string; count: number }[];
} 