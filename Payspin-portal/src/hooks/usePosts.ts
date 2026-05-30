import { useState, useEffect, useCallback } from 'react';
import { Post, PostFilters, PostStats } from '../types/firestore';
import { postRepository } from '../services/firebase/repositories/PostRepository';
import { TableState } from '../types/firestore';

interface UsePostsReturn {
  posts: Post[];
  loading: boolean;
  error: Error | null;
  stats: PostStats | null;
  tableState: TableState;
  handleTableStateChange: (newState: Partial<TableState>) => void;
  deletePost: (id: string) => Promise<void>;
  publishPost: (id: string) => Promise<void>;
  unpublishPost: (id: string) => Promise<void>;
  toggleFeatured: (id: string) => Promise<void>;
  updatePost: (id: string, data: Partial<Post>) => Promise<void>;
  getPostsByType: (postType: string) => Promise<Post[]>;
  getPostsBySubtype: (postSubtype: string) => Promise<Post[]>;
  getPostsByLocation: (location: string) => Promise<Post[]>;
  getFeaturedPosts: () => Promise<Post[]>;
  searchPosts: (searchTerm: string) => Promise<Post[]>;
}

export const usePosts = (): UsePostsReturn => {
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [stats, setStats] = useState<PostStats | null>(null);
  const [tableState, setTableState] = useState<TableState>({
    page: 1,
    pageSize: 10,
    search: '',
    sort: {
      field: 'createdAt',
      direction: 'desc',
    },
  });

  const loadPosts = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      const filters: PostFilters = {};
      
      if (tableState.search) {
        filters.search = tableState.search;
      }

      // Add filters from tableState
      if (tableState.filters) {
        Object.assign(filters, tableState.filters);
      }

      const allPosts = await postRepository.getPostsWithFilters(filters);
      
      // Apply sorting
      let sortedPosts = [...allPosts];
      if (tableState.sort) {
        sortedPosts.sort((a, b) => {
          const aValue = getFieldValue(a, tableState.sort!.field);
          const bValue = getFieldValue(b, tableState.sort!.field);
          
          if (aValue < bValue) return tableState.sort!.direction === 'asc' ? -1 : 1;
          if (aValue > bValue) return tableState.sort!.direction === 'asc' ? 1 : -1;
          return 0;
        });
      }

      // Apply pagination
      const startIndex = (tableState.page - 1) * tableState.pageSize;
      const endIndex = startIndex + tableState.pageSize;
      const paginatedPosts = sortedPosts.slice(startIndex, endIndex);

      setPosts(paginatedPosts);
      
      // Load stats
      const postStats = await postRepository.getPostStats();
      setStats(postStats);
    } catch (err) {
      console.error('Error loading posts:', err);
      setError(err instanceof Error ? err : new Error('Failed to load posts'));
    } finally {
      setLoading(false);
    }
  }, [tableState]);

  const getFieldValue = (post: Post, field: string): any => {
    switch (field) {
      case 'postTitle':
        return post.postTitle;
      case 'postType':
        return post.postType;
      case 'postLocation':
        return post.postLocation;
      case 'postOrder':
        return post.postOrder;
      case 'isFeatured':
        return post.isFeatured;
      case 'isPublished':
        return post.isPublished;
      case 'createdAt':
        return post.createdAt;
      case 'updatedAt':
        return post.updatedAt;
      case 'publishedAt':
        return post.publishedAt;
      default:
        return '';
    }
  };

  const handleTableStateChange = useCallback((newState: Partial<TableState>) => {
    setTableState(prev => ({
      ...prev,
      ...newState,
      // Reset to first page when search changes
      page: newState.search !== undefined ? 1 : prev.page,
    }));
  }, []);

  const deletePost = useCallback(async (id: string) => {
    try {
      await postRepository.delete(id);
      await loadPosts(); // Reload posts after deletion
    } catch (err) {
      throw err instanceof Error ? err : new Error('Failed to delete post');
    }
  }, [loadPosts]);

  const publishPost = useCallback(async (id: string) => {
    try {
      await postRepository.publishPost(id);
      await loadPosts(); // Reload posts after publishing
    } catch (err) {
      throw err instanceof Error ? err : new Error('Failed to publish post');
    }
  }, [loadPosts]);

  const unpublishPost = useCallback(async (id: string) => {
    try {
      await postRepository.unpublishPost(id);
      await loadPosts(); // Reload posts after unpublishing
    } catch (err) {
      throw err instanceof Error ? err : new Error('Failed to unpublish post');
    }
  }, [loadPosts]);

  const toggleFeatured = useCallback(async (id: string) => {
    try {
      await postRepository.toggleFeatured(id);
      await loadPosts(); // Reload posts after toggling featured
    } catch (err) {
      throw err instanceof Error ? err : new Error('Failed to toggle featured status');
      }
  }, [loadPosts]);

  const updatePost = useCallback(async (id: string, data: Partial<Post>) => {
    try {
      await postRepository.update(id, data);
      await loadPosts(); // Reload posts after update
    } catch (err) {
      throw err instanceof Error ? err : new Error('Failed to update post');
    }
  }, [loadPosts]);

  const getPostsByType = useCallback(async (postType: string): Promise<Post[]> => {
    try {
      return await postRepository.getPostsByType(postType);
    } catch (err) {
      throw err instanceof Error ? err : new Error('Failed to get posts by type');
    }
  }, []);

  const getPostsBySubtype = useCallback(async (postSubtype: string): Promise<Post[]> => {
    try {
      return await postRepository.getPostsBySubtype(postSubtype);
    } catch (err) {
      throw err instanceof Error ? err : new Error('Failed to get posts by subtype');
    }
  }, []);

  const getPostsByLocation = useCallback(async (location: string): Promise<Post[]> => {
    try {
      return await postRepository.getPostsByLocation(location);
    } catch (err) {
      throw err instanceof Error ? err : new Error('Failed to get posts by location');
    }
  }, []);

  const getFeaturedPosts = useCallback(async (): Promise<Post[]> => {
    try {
      return await postRepository.getFeaturedPosts();
    } catch (err) {
      throw err instanceof Error ? err : new Error('Failed to get featured posts');
    }
  }, []);

  const searchPosts = useCallback(async (searchTerm: string): Promise<Post[]> => {
    try {
      return await postRepository.searchPosts(searchTerm);
    } catch (err) {
      throw err instanceof Error ? err : new Error('Failed to search posts');
    }
  }, []);

  useEffect(() => {
    loadPosts();
  }, [loadPosts]);

  return {
    posts,
    loading,
    error,
    stats,
    tableState,
    handleTableStateChange,
    deletePost,
    publishPost,
    unpublishPost,
    toggleFeatured,
    updatePost,
    getPostsByType,
    getPostsBySubtype,
    getPostsByLocation,
    getFeaturedPosts,
    searchPosts,
  };
}; 