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
import { Blog, BlogFilters, BlogStats } from '../../../types/firestore';
import { db } from '../../../config/firebase';
import { now, timestampToDate } from '../../../utils/date';

export class BlogRepository extends BaseRepository<Blog> {
  constructor() {
    super('blogs');
  }

  // Create blog with defaults
  async create(data: Omit<Blog, 'id'>): Promise<Blog> {
    const blogData = {
      ...data,
      views: data.views || 0,
      likes: data.likes || 0,
      tags: data.tags || [],
      status: data.status || 'draft',
      readTime: data.readTime || 0,
    };
    return super.create(blogData);
  }

  // Get blogs by author
  async getBlogsByAuthor(authorId: string): Promise<Blog[]> {
    try {
      const q = query(this.collectionRef, where('author', '==', authorId));
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting blogs by author:', error);
      throw error;
    }
  }

  // Get blogs by category
  async getBlogsByCategory(category: string): Promise<Blog[]> {
    try {
      const q = query(this.collectionRef, where('category', '==', category));
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting blogs by category:', error);
      throw error;
    }
  }

  // Get blogs by tag
  async getBlogsByTag(tag: string): Promise<Blog[]> {
    try {
      const q = query(this.collectionRef, where('tags', 'array-contains', tag));
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting blogs by tag:', error);
      throw error;
    }
  }

  // Get published blogs
  async getPublishedBlogs(): Promise<Blog[]> {
    try {
      const q = query(
        this.collectionRef,
        where('status', '==', 'published'),
        orderBy('publishedAt', 'desc')
      );
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting published blogs:', error);
      throw error;
    }
  }

  // Get draft blogs
  async getDraftBlogs(): Promise<Blog[]> {
    try {
      const q = query(
        this.collectionRef,
        where('status', '==', 'draft'),
        orderBy('createdAt', 'desc')
      );
      const querySnapshot = await getDocs(q);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting draft blogs:', error);
      throw error;
    }
  }

  // Publish blog
  async publishBlog(blogId: string): Promise<Blog> {
    return this.update(blogId, {
      status: 'published',
      publishedAt: now(),
    });
  }

  // Increment views
  async incrementViews(blogId: string): Promise<Blog> {
    const blog = await this.getById(blogId);
    if (!blog) {
      throw new Error('Blog not found');
    }
    return this.update(blogId, {
      views: (blog.views || 0) + 1,
    });
  }

  // Toggle like
  async toggleLike(blogId: string, increment: boolean): Promise<Blog> {
    const blog = await this.getById(blogId);
    if (!blog) {
      throw new Error('Blog not found');
    }
    return this.update(blogId, {
      likes: (blog.likes || 0) + (increment ? 1 : -1),
    });
  }

  // Search blogs
  async searchBlogs(searchTerm: string): Promise<Blog[]> {
    try {
      const allBlogs = await this.getAll();
      const searchLower = searchTerm.toLowerCase();
      
      return allBlogs.filter(blog => 
        blog.title.toLowerCase().includes(searchLower) ||
        blog.content.toLowerCase().includes(searchLower) ||
        blog.tags.some(tag => tag.toLowerCase().includes(searchLower))
      );
    } catch (error) {
      console.error('Error searching blogs:', error);
      throw error;
    }
  }

  // Get filtered blogs
  async getFilteredBlogs(filters: {
    status?: 'draft' | 'published';
    author?: string;
    category?: string;
    tag?: string;
    dateRange?: { start: Date; end: Date };
  }): Promise<Blog[]> {
    try {
      let blogs = await this.getAll();

      if (filters.status) {
        blogs = blogs.filter(blog => blog.status === filters.status);
      }

      if (filters.author) {
        blogs = blogs.filter(blog => blog.author.id === filters.author);
      }

      if (filters.tag) {
        blogs = blogs.filter(blog => blog.tags.includes(filters.tag!));
      }

      if (filters.dateRange) {
        blogs = blogs.filter(blog => {
          const publishedAt = blog.publishedAt || blog.createdAt;
          if (!publishedAt) return false;
          const date = timestampToDate(publishedAt);
          return date && date >= filters.dateRange!.start && date <= filters.dateRange!.end;
        });
      }

      return blogs;
    } catch (error) {
      console.error('Error filtering blogs:', error);
      throw error;
    }
  }

  // Helper methods
  private convertQuerySnapshot(querySnapshot: any): Blog[] {
    return querySnapshot.docs.map((doc: any) => {
      const rawData = doc.data();
      const mappedData = this.mapFirebaseDataToBlog(rawData);
      const data = this.convertTimestamp(mappedData);
      return { id: doc.id, ...data } as Blog;
    });
  }

  private mapFirebaseDataToBlog(firebaseData: any): any {
    // Map Firebase field names to our Blog interface
    return {
      title: firebaseData.label || firebaseData.title || 'Untitled',
      content: firebaseData.description || firebaseData.content || '',
      category: firebaseData.category || 'Uncategorized',
      author: firebaseData.author || {
        id: 'unknown',
        name: 'Unknown Author',
        avatar: undefined
      },
      status: firebaseData.status || 'draft',
      publishedAt: firebaseData.publishedAt || undefined,
      tags: Array.isArray(firebaseData.tags) ? firebaseData.tags : [],
      featuredImage: firebaseData.imgUrl || firebaseData.featuredImage || undefined,
      excerpt: firebaseData.excerpt || (firebaseData.description ? firebaseData.description.substring(0, 150) + '...' : ''),
      readTime: firebaseData.readTime || 0,
      likes: firebaseData.likes || 0,
      views: firebaseData.views || 0,
      createdAt: firebaseData.createdAt || firebaseData.created_time || undefined,
      updatedAt: firebaseData.updatedAt || firebaseData.updated_time || undefined,
    };
  }

  async getBlogsWithFilters(filters: BlogFilters): Promise<Blog[]> {
    try {
      let blogs = await this.getAll();

      // Apply filters
      if (filters.status) {
        blogs = blogs.filter(blog => blog.status === filters.status);
      }

      if (filters.category) {
        blogs = blogs.filter(blog => blog.category === filters.category);
      }

      if (filters.author) {
        blogs = blogs.filter(blog => blog.author.id === filters.author);
      }

      if (filters.tag) {
        blogs = blogs.filter(blog => blog.tags.includes(filters.tag!));
      }

      if (filters.search) {
        const searchLower = filters.search.toLowerCase();
        blogs = blogs.filter(blog =>
          blog.title.toLowerCase().includes(searchLower) ||
          blog.content.toLowerCase().includes(searchLower) ||
          blog.author.name.toLowerCase().includes(searchLower)
        );
      }

      return blogs;
    } catch (error) {
      console.error('Error getting blogs with filters:', error);
      throw error;
    }
  }

  async getBlogStats(): Promise<BlogStats> {
    try {
      const blogs = await this.getAll();
      
      const stats: BlogStats = {
        total: blogs.length,
        published: 0,
        drafts: 0,
        archived: 0,
        totalViews: 0,
        totalLikes: 0,
        categories: {},
        popularTags: []
      };

      const tagCounts: { [key: string]: number } = {};

      blogs.forEach(blog => {
        // Count by status
        if (blog.status === 'published') stats.published++;
        else if (blog.status === 'draft') stats.drafts++;
        else if (blog.status === 'archived') stats.archived++;

        // Count views and likes
        stats.totalViews += blog.views || 0;
        stats.totalLikes += blog.likes || 0;

        // Count by category
        if (blog.category) {
          stats.categories[blog.category] = (stats.categories[blog.category] || 0) + 1;
        }

        // Count tags
        if (blog.tags && Array.isArray(blog.tags)) {
          blog.tags.forEach(tag => {
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
      console.error('Error getting blog stats:', error);
      throw error;
    }
  }

  // Override getAll to use our mapping
  async getAll(): Promise<Blog[]> {
    try {
      const querySnapshot = await getDocs(this.collectionRef);
      return this.convertQuerySnapshot(querySnapshot);
    } catch (error) {
      console.error('Error getting all blogs:', error);
      throw error;
    }
  }
}

export const blogRepository = new BlogRepository(); 