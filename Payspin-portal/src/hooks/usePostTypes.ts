import { useState, useEffect } from 'react';
import { PostType, PostSubtype } from '../types/firestore';
import { firebaseService } from '../services/firebase';

interface UsePostTypesReturn {
  postTypes: PostType[];
  postSubtypes: PostSubtype[];
  loading: boolean;
  error: string | null;
  isEmpty: boolean;
  needsSetup: boolean;
  getSubtypesByType: (postTypeId: string) => PostSubtype[];
  refreshData: () => Promise<void>;
}

export const usePostTypes = (): UsePostTypesReturn => {
  const [postTypes, setPostTypes] = useState<PostType[]>([]);
  const [postSubtypes, setPostSubtypes] = useState<PostSubtype[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isEmpty, setIsEmpty] = useState(false);
  const [needsSetup, setNeedsSetup] = useState(false);

  const loadData = async () => {
    try {
      setLoading(true);
      setError(null);
      setIsEmpty(false);
      setNeedsSetup(false);
      
      // Try to load with the complex query first
      try {
        const [typesData, subtypesData] = await Promise.all([
          firebaseService.postTypes.getActive(),
          firebaseService.postSubtypes.getActive(),
        ]);
        
        setPostTypes(typesData.sort((a, b) => a.order - b.order));
        setPostSubtypes(subtypesData.sort((a, b) => a.order - b.order));
        
        // Check if we have no data (first time setup)
        if (typesData.length === 0 && subtypesData.length === 0) {
          setIsEmpty(true);
          setNeedsSetup(true);
        }
        
      } catch (indexError: any) {
        // If it's an index error, try fallback to simple queries
        if (indexError?.message?.includes('index') || indexError?.message?.includes('composite')) {
          console.log('Index not available, falling back to simple queries...');
          
          try {
            const [typesData, subtypesData] = await Promise.all([
              firebaseService.postTypes.getAll(),
              firebaseService.postSubtypes.getAll(),
            ]);
            
            // Filter active items client-side
            const activeTypes = typesData.filter(t => t.isActive).sort((a, b) => a.order - b.order);
            const activeSubtypes = subtypesData.filter(s => s.isActive).sort((a, b) => a.order - b.order);
            
            setPostTypes(activeTypes);
            setPostSubtypes(activeSubtypes);
            
            // Check if we have no data (first time setup)
            if (typesData.length === 0 && subtypesData.length === 0) {
              setIsEmpty(true);
              setNeedsSetup(true);
            }
            
          } catch (fallbackError: any) {
            // If even simple queries fail, collections probably don't exist
            setNeedsSetup(true);
            setError(null); // Don't show error - just indicate setup needed
          }
        } else {
          throw indexError; // Re-throw if it's not an index error
        }
      }
      
    } catch (err: any) {
      console.error('Error loading post types:', err);
      
      // Check if it's a "collection doesn't exist" error
      if (err?.code === 'permission-denied' || 
          err?.message?.includes('collection') ||
          err?.message?.includes('permission') ||
          err?.message?.includes('not found')) {
        setNeedsSetup(true);
        setError(null); // Don't show error for setup scenarios
      } else {
        setError(`Failed to load post types: ${err?.message || 'Unknown error'}`);
      }
    } finally {
      setLoading(false);
    }
  };

  const getSubtypesByType = (postTypeName: string): PostSubtype[] => {
    // Find the post type by name to get its ID
    const postType = postTypes.find(type => type.name === postTypeName);
    if (!postType) return [];
    
    // Filter subtypes by the post type ID
    return postSubtypes.filter(subtype => subtype.postTypeId === postType.id);
  };

  const refreshData = async () => {
    await loadData();
  };

  useEffect(() => {
    loadData();
  }, []);

  return {
    postTypes,
    postSubtypes,
    loading,
    error,
    isEmpty,
    needsSetup,
    getSubtypesByType,
    refreshData,
  };
}; 