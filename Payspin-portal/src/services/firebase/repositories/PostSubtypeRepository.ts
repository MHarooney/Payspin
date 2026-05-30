import { collection, doc, getDocs, getDoc, addDoc, updateDoc, deleteDoc, query, orderBy, where } from 'firebase/firestore';
import { db } from '../../../config/firebase';
import { PostSubtype } from '../../../types/firestore';
import { BaseRepository } from '../BaseRepository';
import { now } from '../../../utils/date';

export class PostSubtypeRepository extends BaseRepository<PostSubtype> {
  constructor() {
    super('postSubtypes');
  }

  async getByPostType(postTypeId: string): Promise<PostSubtype[]> {
    try {
      const q = query(
        collection(db, this.collectionName),
        where('postTypeId', '==', postTypeId),
        where('isActive', '==', true),
        orderBy('order', 'asc')
      );
      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      } as PostSubtype));
    } catch (error: any) {
      // If index error, fall back to simple query and filter client-side
      if (error?.message?.includes('index') || error?.message?.includes('composite')) {
        console.log('PostSubtype getByPostType index not available, using fallback query...');
        try {
          const allSubtypes = await this.getAll();
          return allSubtypes
            .filter(subtype => subtype.postTypeId === postTypeId && subtype.isActive)
            .sort((a, b) => (a.order || 0) - (b.order || 0));
        } catch (fallbackError) {
          console.error('Fallback query also failed:', fallbackError);
          return []; // Return empty array if collections don't exist
        }
      }
      console.error('Error fetching post subtypes by type:', error);
      throw error;
    }
  }

  async getActive(): Promise<PostSubtype[]> {
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
      } as PostSubtype));
    } catch (error: any) {
      // If index error, fall back to simple query and filter client-side
      if (error?.message?.includes('index') || error?.message?.includes('composite')) {
        console.log('PostSubtype index not available, using fallback query...');
        try {
          const allSubtypes = await this.getAll();
          return allSubtypes
            .filter(subtype => subtype.isActive)
            .sort((a, b) => (a.order || 0) - (b.order || 0));
        } catch (fallbackError) {
          console.error('Fallback query also failed:', fallbackError);
          return []; // Return empty array if collections don't exist
        }
      }
      console.error('Error fetching active post subtypes:', error);
      throw error;
    }
  }

  async createSubtype(data: Omit<PostSubtype, 'id' | 'createdAt' | 'updatedAt'>): Promise<string> {
    try {
      const subtypeData = {
        ...data,
        createdAt: now(),
        updatedAt: now(),
      };
      const docRef = await addDoc(collection(db, this.collectionName), subtypeData);
      return docRef.id;
    } catch (error) {
      console.error('Error creating post subtype:', error);
      throw error;
    }
  }

  async updateSubtype(id: string, data: Partial<Omit<PostSubtype, 'id' | 'createdAt'>>): Promise<void> {
    try {
      const updateData = {
        ...data,
        updatedAt: now(),
      };
      await updateDoc(doc(db, this.collectionName, id), updateData);
    } catch (error) {
      console.error('Error updating post subtype:', error);
      throw error;
    }
  }

  async toggleActive(id: string, isActive: boolean): Promise<void> {
    try {
      await this.updateSubtype(id, { isActive });
    } catch (error) {
      console.error('Error toggling post subtype status:', error);
      throw error;
    }
  }

  async reorder(updates: { id: string; order: number }[]): Promise<void> {
    try {
      const updatePromises = updates.map(({ id, order }) =>
        this.updateSubtype(id, { order })
      );
      await Promise.all(updatePromises);
    } catch (error) {
      console.error('Error reordering post subtypes:', error);
      throw error;
    }
  }

  async deleteByPostType(postTypeId: string): Promise<void> {
    try {
      const q = query(
        collection(db, this.collectionName),
        where('postTypeId', '==', postTypeId)
      );
      const snapshot = await getDocs(q);
      const deletePromises = snapshot.docs.map(doc => deleteDoc(doc.ref));
      await Promise.all(deletePromises);
    } catch (error) {
      console.error('Error deleting subtypes by post type:', error);
      throw error;
    }
  }
} 