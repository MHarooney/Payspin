import { collection, doc, getDocs, getDoc, addDoc, updateDoc, deleteDoc, query, orderBy, where } from 'firebase/firestore';
import { db } from '../../../config/firebase';
import { PostType } from '../../../types/firestore';
import { BaseRepository } from '../BaseRepository';
import { now } from '../../../utils/date';

export class PostTypeRepository extends BaseRepository<PostType> {
  constructor() {
    super('postTypes');
  }

  async getActive(): Promise<PostType[]> {
    try {
      const q = query(
        collection(db, this.collectionName),
        where('isActive', '==', true),
        orderBy('order', 'asc')
      );
      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      } as PostType));
    } catch (error: any) {
      // If index error, fall back to simple query and filter client-side
      if (error?.message?.includes('index') || error?.message?.includes('composite')) {
        console.log('PostType index not available, using fallback query...');
        try {
          const allTypes = await this.getAll();
          return allTypes
            .filter(type => type.isActive)
            .sort((a, b) => (a.order || 0) - (b.order || 0));
        } catch (fallbackError) {
          console.error('Fallback query also failed:', fallbackError);
          return []; // Return empty array if collections don't exist
        }
      }
      console.error('Error fetching active post types:', error);
      throw error;
    }
  }

  async createPostType(data: Omit<PostType, 'id' | 'createdAt' | 'updatedAt'>): Promise<string> {
    try {
      const postTypeData = {
        ...data,
        createdAt: now(),
        updatedAt: now(),
      };
      const docRef = await addDoc(collection(db, this.collectionName), postTypeData);
      return docRef.id;
    } catch (error) {
      console.error('Error creating post type:', error);
      throw error;
    }
  }

  async updatePostType(id: string, data: Partial<Omit<PostType, 'id' | 'createdAt'>>): Promise<void> {
    try {
      const updateData = {
        ...data,
        updatedAt: now(),
      };
      await updateDoc(doc(db, this.collectionName, id), updateData);
    } catch (error) {
      console.error('Error updating post type:', error);
      throw error;
    }
  }

  async toggleActive(id: string, isActive: boolean): Promise<void> {
    try {
      await this.updatePostType(id, { isActive });
    } catch (error) {
      console.error('Error toggling post type status:', error);
      throw error;
    }
  }

  async reorder(updates: { id: string; order: number }[]): Promise<void> {
    try {
      const updatePromises = updates.map(({ id, order }) =>
        this.updatePostType(id, { order })
      );
      await Promise.all(updatePromises);
    } catch (error) {
      console.error('Error reordering post types:', error);
      throw error;
    }
  }
} 