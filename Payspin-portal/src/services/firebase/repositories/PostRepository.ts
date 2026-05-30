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
import { Post, PostFilters, PostStats, PostType, PostSubtype, PostMedia } from '../../../types/firestore';
import { db } from '../../../config/firebase';
import { now, timestampToDate } from '../../../utils/date';

export class PostRepository extends BaseRepository<Post> {
  constructor() {
    super('posts');
  }

  // Create post with enhanced defaults
  async create(data: Omit<Post, 'id'>): Promise<Post> {
    const postData = {
      ...data,
      postOrder: data.postOrder || 1,
      isFeatured: data.isFeatured || false,
      isPublished: data.isPublished || false,
      isDraft: data.isDraft !== false, // Default to true
      media: data.media || [],
      createdAt: now(),
      updatedAt: now(),
    };
    return super.create(postData);
  }

  // Get posts by type
  async getPostsByType(postType: string): Promise<Post[]> {
    try {
      const allPosts = await this.getAll();
      // Handle case sensitivity and pluralization mismatches
      const filterType = postType.toLowerCase();
      return allPosts.filter(post => {
        const postTypeLower = post.postType?.toLowerCase() || '';
        return postTypeLower === filterType || 
               postTypeLower === filterType + 's' || // Handle pluralization
               postTypeLower.replace(/s$/, '') === filterType; // Handle singularization
      });
    } catch (error) {
      console.error('Error getting posts by type:', error);
      throw error;
    }
  }

  // Get posts by subtype
  async getPostsBySubtype(postSubtype: string): Promise<Post[]> {
    try {
      const q = query(this.collectionRef, where('postSubtype', '==', postSubtype));
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting posts by subtype:', error);
      throw error;
    }
  }

  // Get posts by location
  async getPostsByLocation(location: string): Promise<Post[]> {
    try {
      const q = query(this.collectionRef, where('postLocation', '==', location));
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting posts by location:', error);
      throw error;
    }
  }

  // Get featured posts
  async getFeaturedPosts(): Promise<Post[]> {
    try {
      const q = query(
        this.collectionRef,
        where('isFeatured', '==', true),
        where('isPublished', '==', true),
        orderBy('postOrder', 'asc')
      );
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting featured posts:', error);
      throw error;
    }
  }

  // Get published posts
  async getPublishedPosts(): Promise<Post[]> {
    try {
      const q = query(
        this.collectionRef,
        where('isPublished', '==', true),
        orderBy('publishedAt', 'desc')
      );
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting published posts:', error);
      throw error;
    }
  }

  // Get draft posts
  async getDraftPosts(): Promise<Post[]> {
    try {
      const q = query(
        this.collectionRef,
        where('isDraft', '==', true),
        orderBy('createdAt', 'desc')
      );
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting draft posts:', error);
      throw error;
    }
  }

  // Publish post
  async publishPost(postId: string): Promise<Post> {
    return this.update(postId, {
      isPublished: true,
      isDraft: false,
      publishedAt: now(),
    });
  }

  // Unpublish post
  async unpublishPost(postId: string): Promise<Post> {
    return this.update(postId, {
      isPublished: false,
      isDraft: true,
    });
  }

  // Toggle featured status
  async toggleFeatured(postId: string): Promise<Post> {
    const post = await this.getById(postId);
    if (!post) {
      throw new Error('Post not found');
    }
    return this.update(postId, {
      isFeatured: !post.isFeatured,
    });
  }

  // Update post order
  async updatePostOrder(postId: string, order: number): Promise<Post> {
    return this.update(postId, {
      postOrder: order,
    });
  }

  // Add media to post
  async addMedia(postId: string, media: PostMedia): Promise<Post> {
    const post = await this.getById(postId);
    if (!post) {
      throw new Error('Post not found');
    }
    
    const updatedMedia = [...(post.media || []), media];
    return this.update(postId, {
      media: updatedMedia,
    });
  }

  // Remove media from post
  async removeMedia(postId: string, mediaId: string): Promise<Post> {
    const post = await this.getById(postId);
    if (!post) {
      throw new Error('Post not found');
    }
    
    const updatedMedia = (post.media || []).filter(m => m.id !== mediaId);
    return this.update(postId, {
      media: updatedMedia,
    });
  }

  // Update media order
  async updateMediaOrder(postId: string, mediaId: string, order: number): Promise<Post> {
    const post = await this.getById(postId);
    if (!post) {
      throw new Error('Post not found');
    }
    
    const updatedMedia = (post.media || []).map(m => 
      m.id === mediaId ? { ...m, order } : m
    );
    return this.update(postId, {
      media: updatedMedia,
    });
  }

  // Search posts
  async searchPosts(searchTerm: string): Promise<Post[]> {
    try {
      const allPosts = await this.getAll();
      const searchLower = searchTerm.toLowerCase();
      
      return allPosts.filter(post => 
        post.postTitle.toLowerCase().includes(searchLower) ||
        post.postDescription.toLowerCase().includes(searchLower) ||
        post.postBodyPrimary.toLowerCase().includes(searchLower) ||
        (post.postBodySecondary && post.postBodySecondary.toLowerCase().includes(searchLower)) ||
        post.postLocation.toLowerCase().includes(searchLower)
      );
    } catch (error) {
      console.error('Error searching posts:', error);
      throw error;
    }
  }

  // Get filtered posts with enhanced filters
  async getFilteredPosts(filters: {
    postType?: string;
    postSubtype?: string;
    location?: string;
    isPublished?: boolean;
    isDraft?: boolean;
    isFeatured?: boolean;
    dateRange?: { start: Date; end: Date };
  }): Promise<Post[]> {
    try {
      let posts = await this.getAll();

      if (filters.postType) {
        posts = posts.filter(post => post.postType === filters.postType);
      }

      if (filters.postSubtype) {
        posts = posts.filter(post => post.postSubtype === filters.postSubtype);
      }

      if (filters.location) {
        posts = posts.filter(post => post.postLocation === filters.location);
      }

      if (filters.isPublished !== undefined) {
        posts = posts.filter(post => post.isPublished === filters.isPublished);
      }

      if (filters.isDraft !== undefined) {
        posts = posts.filter(post => post.isDraft === filters.isDraft);
      }

      if (filters.isFeatured !== undefined) {
        posts = posts.filter(post => post.isFeatured === filters.isFeatured);
      }

      if (filters.dateRange) {
        posts = posts.filter(post => {
          const publishedAt = post.publishedAt || post.createdAt;
          if (!publishedAt) return false;
          const date = timestampToDate(publishedAt);
          return date && date >= filters.dateRange!.start && date <= filters.dateRange!.end;
        });
      }

      return posts;
    } catch (error) {
      console.error('Error filtering posts:', error);
      throw error;
    }
  }

  // Helper methods
  private convertQuerySnapshot(querySnapshot: any): Post[] {
    return querySnapshot.docs.map((doc: any) => {
      const rawData = doc.data();
      const mappedData = this.mapFirebaseDataToPost(rawData);
      const data = this.convertTimestamp(mappedData);
      return { id: doc.id, ...data } as Post;
    });
  }

  private mapFirebaseDataToPost(firebaseData: any): any {
    // Map Firebase field names to our enhanced Post interface
    return {
      // New enhanced fields
      postType: firebaseData.postType || 'blog',
      postSubtype: firebaseData.postSubtype || undefined,
      postTitle: firebaseData.postTitle || firebaseData.title || 'Untitled',
      postLocation: firebaseData.postLocation || firebaseData.location || 'Unknown',
      postDescription: firebaseData.postDescription || firebaseData.excerpt || '',
      postBodyPrimary: firebaseData.postBodyPrimary || firebaseData.content || '',
      postBodySecondary: firebaseData.postBodySecondary || '',
      isFeatured: firebaseData.isFeatured || firebaseData.featured || false,
      postOrder: firebaseData.postOrder || firebaseData.order || 1,
      postUrl: firebaseData.postUrl || undefined,
      mainImage: firebaseData.mainImage || firebaseData.featuredImage || firebaseData.imgUrl || undefined,
      media: Array.isArray(firebaseData.media) ? firebaseData.media : [],
      isPublished: firebaseData.isPublished || firebaseData.status === 'published' || false,
      isDraft: firebaseData.isDraft !== false && (firebaseData.status === 'draft' || !firebaseData.isPublished),
      
      // Legacy fields for backward compatibility
      title: firebaseData.postTitle || firebaseData.title || 'Untitled',
      slug: firebaseData.slug || '',
      content: firebaseData.postBodyPrimary || firebaseData.content || '',
      excerpt: firebaseData.postDescription || firebaseData.excerpt || '',
      categories: Array.isArray(firebaseData.categories) ? firebaseData.categories : [],
      tags: Array.isArray(firebaseData.tags) ? firebaseData.tags : [],
      author: firebaseData.author || {
        id: 'unknown',
        name: 'Unknown Author',
        email: 'unknown@example.com',
        avatar: undefined
      },
      status: firebaseData.isPublished ? 'published' : (firebaseData.isDraft ? 'draft' : 'archived'),
      featuredImage: firebaseData.mainImage || firebaseData.featuredImage || firebaseData.imgUrl || undefined,
      featured: firebaseData.isFeatured || firebaseData.featured || false,
      order: firebaseData.postOrder || firebaseData.order || 1,
      location: firebaseData.postLocation || firebaseData.location || 'Unknown',
      seoTitle: firebaseData.seoTitle || '',
      metaDescription: firebaseData.metaDescription || '',
      metaKeywords: firebaseData.metaKeywords || [],
      readingTime: firebaseData.readingTime || firebaseData.readTime || 0,
      likes: firebaseData.likes || 0,
      views: firebaseData.views || 0,
      createdAt: firebaseData.createdAt || firebaseData.created_time || undefined,
      updatedAt: firebaseData.updatedAt || firebaseData.updated_time || undefined,
      publishedAt: firebaseData.publishedAt || undefined,
    };
  }

  async getPostsWithFilters(filters: PostFilters): Promise<Post[]> {
    try {
      let posts = await this.getAll();

      // Apply filters
      if (filters.status) {
        posts = posts.filter(post => {
          if (filters.status === 'published') return post.isPublished;
          if (filters.status === 'draft') return post.isDraft;
          return true;
        });
      }

      if (filters.postType) {
        // Handle case sensitivity and pluralization mismatches
        const filterType = filters.postType.toLowerCase();
        posts = posts.filter(post => {
          const postType = post.postType?.toLowerCase() || '';
          return postType === filterType || 
                 postType === filterType + 's' || // Handle pluralization
                 postType.replace(/s$/, '') === filterType; // Handle singularization
        });
      }

      if (filters.postSubtype) {
        posts = posts.filter(post => post.postSubtype === filters.postSubtype);
      }

      if (filters.location) {
        posts = posts.filter(post => post.postLocation === filters.location);
      }

      if (filters.categories && filters.categories.length > 0) {
        posts = posts.filter(post => 
          post.categories && post.categories.some(category => filters.categories!.includes(category))
        );
      }

      if (filters.author) {
        posts = posts.filter(post => post.author && post.author.id === filters.author);
      }

      if (filters.tag) {
        posts = posts.filter(post => post.tags && post.tags.includes(filters.tag!));
      }

      if (filters.search) {
        const searchLower = filters.search.toLowerCase();
        posts = posts.filter(post =>
          post.postTitle.toLowerCase().includes(searchLower) ||
          post.postDescription.toLowerCase().includes(searchLower) ||
          post.postBodyPrimary.toLowerCase().includes(searchLower) ||
          post.postLocation.toLowerCase().includes(searchLower)
        );
      }

      if (filters.featured !== undefined) {
        posts = posts.filter(post => post.isFeatured === filters.featured);
      }

      return posts;
    } catch (error) {
      console.error('Error getting posts with filters:', error);
      throw error;
    }
  }

  async getPostStats(): Promise<PostStats> {
    try {
      const posts = await this.getAll();
      
      const stats: PostStats = {
        total: posts.length,
        published: 0,
        drafts: 0,
        archived: 0,
        totalViews: 0,
        totalLikes: 0,
        categories: {},
        popularTags: []
      };

      const tagCounts: { [key: string]: number } = {};
      const typeCounts: { [key: string]: number } = {};
      const locationCounts: { [key: string]: number } = {};

      posts.forEach(post => {
        // Count by status
        if (post.isPublished) stats.published++;
        else if (post.isDraft) stats.drafts++;
        else stats.archived++;

        // Count views and likes
        stats.totalViews += post.views || 0;
        stats.totalLikes += post.likes || 0;

        // Count by post type
        if (post.postType) {
          typeCounts[post.postType] = (typeCounts[post.postType] || 0) + 1;
        }

        // Count by location
        if (post.postLocation) {
          locationCounts[post.postLocation] = (locationCounts[post.postLocation] || 0) + 1;
        }

        // Count by category (legacy)
        if (post.categories && Array.isArray(post.categories)) {
          post.categories.forEach(category => {
            stats.categories[category] = (stats.categories[category] || 0) + 1;
          });
        }

        // Count tags
        if (post.tags && Array.isArray(post.tags)) {
          post.tags.forEach(tag => {
            tagCounts[tag] = (tagCounts[tag] || 0) + 1;
          });
        }
      });

      // Convert tag counts to popular tags array
      stats.popularTags = Object.entries(tagCounts)
        .map(([tag, count]) => ({ tag, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 10); // Top 10 tags

      return stats;
    } catch (error) {
      console.error('Error getting post stats:', error);
      throw error;
    }
  }

  // Override getAll to use our mapping
  async getAll(): Promise<Post[]> {
    try {
      const querySnapshot = await getDocs(this.collectionRef);
      const posts = this.convertQuerySnapshot(querySnapshot);
      return posts;
    } catch (error) {
      console.error('Error getting all posts:', error);
      throw error;
    }
  }
}

export const postRepository = new PostRepository(); 