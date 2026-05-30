import {
  collection,
  doc,
  getDoc,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  startAfter,
  QueryConstraint,
  DocumentSnapshot,
  CollectionReference,
  DocumentReference,
  Timestamp,
  DocumentData,
  setDoc,
  QuerySnapshot,
} from 'firebase/firestore';
import { db } from '../../config/firebase';
import { FirestoreDocument, PaginatedResponse, TableFilters, SortConfig } from '../../types/firestore';
import { FirebaseDateUtils } from '../../utils/firebase-date';

export abstract class BaseRepository<T extends FirestoreDocument> {
  protected collectionName: string;
  protected collectionRef: CollectionReference;

  constructor(collectionName: string) {
    this.collectionName = collectionName;
    this.collectionRef = collection(db, collectionName);
  }

  // Convert Firestore timestamp to Timestamp
  protected convertTimestamp(data: DocumentData, visited = new Set()): DocumentData {
    if (!data || typeof data !== 'object' || visited.has(data)) {
      return data;
    }

    visited.add(data);
    
    if (Array.isArray(data)) {
      return data.map(item => {
        if (item && typeof item === 'object' && 'seconds' in item && 'nanoseconds' in item) {
          return new Timestamp(item.seconds, item.nanoseconds);
        } else if (item && typeof item === 'object') {
          return this.convertTimestamp(item, visited);
        }
        return item;
      });
    }

    const converted = { ...data } as Record<string, any>;
    Object.entries(converted).forEach(([key, value]) => {
      if (value && typeof value === 'object' && 'seconds' in value && 'nanoseconds' in value) {
        converted[key] = new Timestamp(value.seconds, value.nanoseconds);
      } else if (value && typeof value === 'object') {
        converted[key] = this.convertTimestamp(value, visited);
      }
    });

    return converted;
  }

  // Convert Date to Firestore timestamp
  protected prepareForFirestore(data: Partial<T>, visited = new Set()): DocumentData {
    if (!data || typeof data !== 'object' || visited.has(data)) {
      return data;
    }

    visited.add(data);

    if (Array.isArray(data)) {
      return data.map(item => {
        if (item instanceof Date) {
          return Timestamp.fromDate(item);
        } else if (item && typeof item === 'object') {
          return this.prepareForFirestore(item as Partial<T>, visited);
        }
        return item;
      });
    }

    const prepared = {} as Record<string, any>;
    Object.entries(data).forEach(([key, value]) => {
      if (value instanceof Date) {
        prepared[key] = Timestamp.fromDate(value);
      } else if (value && typeof value === 'object') {
        prepared[key] = this.prepareForFirestore(value as Partial<T>, visited);
      } else {
        prepared[key] = value;
      }
    });

    return prepared;
  }

  // Get document by ID
  async getById(id: string): Promise<T | null> {
    try {
      const docRef = doc(this.collectionRef, id);
      const docSnap = await getDoc(docRef);
      
      if (docSnap.exists()) {
        const data = this.convertTimestamp(docSnap.data());
        return { id: docSnap.id, ...data } as T;
      }
      return null;
    } catch (error) {
      console.error(`Error getting document from ${this.collectionName}:`, error);
      throw error;
    }
  }

  // Get all documents
  async getAll(): Promise<T[]> {
    try {
      const querySnapshot = await getDocs(this.collectionRef);
      return querySnapshot.docs.map(doc => {
        const data = this.convertTimestamp(doc.data());
        return { id: doc.id, ...data } as T;
      });
    } catch (error) {
      console.error(`Error getting all documents from ${this.collectionName}:`, error);
      throw error;
    }
  }

  // Get documents with pagination and filtering
  async getPaginated(
    page: number = 1,
    pageSize: number = 10,
    filters?: TableFilters,
    sort?: SortConfig,
    lastDocument?: DocumentSnapshot
  ): Promise<PaginatedResponse<T>> {
    try {
      const constraints: QueryConstraint[] = [];

      // Apply filters
      if (filters) {
        if (filters.status) {
          constraints.push(where('status', '==', filters.status));
        }
        if (filters.category) {
          constraints.push(where('category', '==', filters.category));
        }
        if (filters.author) {
          constraints.push(where('authorId', '==', filters.author));
        }
      }

      // Apply sorting
      if (sort) {
        constraints.push(orderBy(sort.field, sort.direction));
      } else {
        constraints.push(orderBy('createdAt', 'desc'));
      }

      // Apply pagination
      if (lastDocument) {
        constraints.push(startAfter(lastDocument));
      }
      constraints.push(limit(pageSize));

      const q = query(this.collectionRef, ...constraints);
      const querySnapshot = await getDocs(q);

      const documents = querySnapshot.docs.map(doc => {
        const data = this.convertTimestamp(doc.data());
        return { id: doc.id, ...data } as T;
      });

      // Get total count (this is expensive in Firestore, consider caching)
      const totalQuery = query(this.collectionRef, ...constraints.slice(0, -2)); // Remove limit and startAfter
      const totalSnapshot = await getDocs(totalQuery);
      const total = totalSnapshot.size;

      const totalPages = Math.ceil(total / pageSize);

      return {
        success: true,
        data: documents,
        pagination: {
          page,
          pageSize,
          total,
          totalPages,
          hasNext: page < totalPages,
          hasPrev: page > 1,
          limit: pageSize
        },
        timestamp: Timestamp.now()
      };
    } catch (error) {
      console.error(`Error getting paginated documents from ${this.collectionName}:`, error);
      throw error;
    }
  }

  // Create new document
  async create(data: Omit<T, keyof FirestoreDocument>): Promise<T> {
    const docRef = doc(this.collectionRef);
    const timestamp = FirebaseDateUtils.now();
    
    const documentData = {
      ...data,
      id: docRef.id,
      createdAt: timestamp,
      updatedAt: timestamp
    } as T;

    await setDoc(docRef, this.convertDatesToTimestamps(documentData));
    return documentData;
  }

  // Update document
  async update(id: string, data: Partial<T>): Promise<T> {
    const docRef = doc(this.collectionRef, id);
    const timestamp = FirebaseDateUtils.now();
    
    const updateData = {
      ...data,
      updatedAt: timestamp
    };

    await updateDoc(docRef, this.convertDatesToTimestamps(updateData));
    const updatedDoc = await getDoc(docRef);
    
    if (!updatedDoc.exists()) {
      throw new Error(`Document with id ${id} not found`);
    }

    return this.convertTimestampsToDates({ id, ...updatedDoc.data() } as T);
  }

  // Delete document
  async delete(id: string): Promise<void> {
    console.log(`🔥 BaseRepository.delete called for collection: ${this.collectionName}, ID: ${id}`);
    try {
      const docRef = doc(this.collectionRef, id);
      console.log(`📄 Document reference created for: ${docRef.path}`);
      
      console.log(`🗑️ Calling Firebase deleteDoc...`);
      await deleteDoc(docRef);
      console.log(`✅ Firebase deleteDoc completed successfully`);
    } catch (error) {
      console.error(`❌ Error in BaseRepository.delete:`, error);
      throw error;
    }
  }

  // Search documents by field
  async search(field: keyof T, value: any, operator: '==' | '!=' | '>' | '>=' | '<' | '<=' = '=='): Promise<T[]> {
    try {
      const q = query(this.collectionRef, where(field as string, operator, value));
      const querySnapshot = await getDocs(q);
      
      return querySnapshot.docs.map(doc => {
        const data = this.convertTimestamp(doc.data());
        return { id: doc.id, ...data } as T;
      });
    } catch (error) {
      console.error(`Error searching documents in ${this.collectionName}:`, error);
      throw error;
    }
  }

  // Count documents with optional filter
  async count(filters?: Partial<Record<keyof T, any>>): Promise<number> {
    try {
      const constraints: QueryConstraint[] = [];
      
      if (filters) {
        Object.entries(filters).forEach(([field, value]) => {
          constraints.push(where(field, '==', value));
        });
      }

      const q = query(this.collectionRef, ...constraints);
      const querySnapshot = await getDocs(q);
      
      return querySnapshot.size;
    } catch (error) {
      console.error(`Error counting documents in ${this.collectionName}:`, error);
      throw error;
    }
  }

  // Check if document exists
  async exists(id: string): Promise<boolean> {
    const docRef = doc(this.collectionRef, id);
    const docSnap = await getDoc(docRef);
    return docSnap.exists();
  }

  // Get documents by multiple IDs
  async getByIds(ids: string[]): Promise<T[]> {
    try {
      const promises = ids.map(id => this.getById(id));
      const results = await Promise.all(promises);
      return results.filter(doc => doc !== null) as T[];
    } catch (error) {
      console.error(`Error getting documents by IDs from ${this.collectionName}:`, error);
      throw error;
    }
  }

  // Batch operations
  async batchCreate(documents: Omit<T, keyof FirestoreDocument>[]): Promise<T[]> {
    try {
      const promises = documents.map(doc => this.create(doc));
      return await Promise.all(promises);
    } catch (error) {
      console.error(`Error batch creating documents in ${this.collectionName}:`, error);
      throw error;
    }
  }

  async batchUpdate(updates: { id: string; data: Partial<T> }[]): Promise<T[]> {
    try {
      const promises = updates.map(({ id, data }) => this.update(id, data));
      return await Promise.all(promises);
    } catch (error) {
      console.error(`Error batch updating documents in ${this.collectionName}:`, error);
      throw error;
    }
  }

  async batchDelete(ids: string[]): Promise<void> {
    try {
      const promises = ids.map(id => this.delete(id));
      await Promise.all(promises);
    } catch (error) {
      console.error(`Error batch deleting documents from ${this.collectionName}:`, error);
      throw error;
    }
  }

  protected handleTimestamp(date: Date | Timestamp): Timestamp {
    return date instanceof Date ? Timestamp.fromDate(date) : date;
  }

  protected handleDate(timestamp: Timestamp | null): Date | null {
    return timestamp ? timestamp.toDate() : null;
  }

  private convertDatesToTimestamps(data: any): any {
    if (!data) return data;
    if (data instanceof Date) return FirebaseDateUtils.fromDate(data);
    if (data instanceof Timestamp) return data;
    if (Array.isArray(data)) return data.map(item => this.convertDatesToTimestamps(item));
    if (typeof data === 'object') {
      const result: any = {};
      for (const key in data) {
        result[key] = this.convertDatesToTimestamps(data[key]);
      }
      return result;
    }
    return data;
  }

  private convertTimestampsToDates(data: any): any {
    if (!data) return data;
    if (data instanceof Timestamp) return data;
    if (Array.isArray(data)) return data.map(item => this.convertTimestampsToDates(item));
    if (typeof data === 'object') {
      const result: any = {};
      for (const key in data) {
        result[key] = this.convertTimestampsToDates(data[key]);
      }
      return result;
    }
    return data;
  }
} 