import { 
  Firestore, 
  CollectionReference, 
  DocumentData, 
  addDoc, 
  collection, 
  deleteDoc, 
  doc, 
  getDoc, 
  getDocs, 
  query, 
  updateDoc, 
  where, 
  QueryDocumentSnapshot,
  Timestamp
} from 'firebase/firestore';
import { db } from '../../config/firebase';

export interface BaseModel {
  id: string;
  createdAt: Date;
  updatedAt: Date;
}

type FirestoreData<T> = {
  [K in keyof T]: T[K] extends Date ? Timestamp : T[K];
};

export class BaseRepository<T extends BaseModel> {
  protected collectionRef: CollectionReference<DocumentData>;

  constructor(collectionPath: string) {
    this.collectionRef = collection(db, collectionPath);
  }

  protected prepareForFirestore(data: Partial<T>): DocumentData {
    const prepared: { [key: string]: any } = { ...data };
    Object.entries(prepared).forEach(([key, value]) => {
      if (value instanceof Date) {
        prepared[key] = Timestamp.fromDate(value);
      }
    });
    return prepared;
  }

  protected convertFromFirestore(doc: QueryDocumentSnapshot<DocumentData>): T {
    const data = doc.data();
    const converted: { [key: string]: any } = { ...data, id: doc.id };
    
    // Convert Timestamp back to Date
    Object.entries(converted).forEach(([key, value]) => {
      if (value instanceof Timestamp) {
        converted[key] = value.toDate();
      }
    });
    
    return converted as T;
  }

  async getAll(): Promise<T[]> {
    const snapshot = await getDocs(this.collectionRef);
    return snapshot.docs.map(doc => this.convertFromFirestore(doc));
  }

  async getById(id: string): Promise<T | null> {
    const docRef = doc(this.collectionRef, id);
    const snapshot = await getDoc(docRef);
    
    if (!snapshot.exists()) {
      return null;
    }
    
    return this.convertFromFirestore(snapshot as QueryDocumentSnapshot<DocumentData>);
  }

  async create(data: Omit<T, 'id'>): Promise<T> {
    try {
      const dataWithTimestamps = {
        ...data,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const preparedData = this.prepareForFirestore(dataWithTimestamps as Partial<T>);
      const docRef = await addDoc(this.collectionRef, preparedData);
      const newDoc = await getDoc(docRef);
      
      return this.convertFromFirestore(newDoc as QueryDocumentSnapshot<DocumentData>);
    } catch (error) {
      console.error('Error creating document:', error);
      throw error;
    }
  }

  async update(id: string, data: Partial<Omit<T, 'id' | 'createdAt'>>): Promise<T> {
    const docRef = doc(this.collectionRef, id);
    const updateData = {
      ...data,
      updatedAt: new Date(),
    };
    
    const preparedData = this.prepareForFirestore(updateData as Partial<T>);
    await updateDoc(docRef, preparedData);
    
    const updated = await getDoc(docRef);
    return this.convertFromFirestore(updated as QueryDocumentSnapshot<DocumentData>);
  }

  async delete(id: string): Promise<void> {
    const docRef = doc(this.collectionRef, id);
    await deleteDoc(docRef);
  }

  async findWhere(field: keyof T, value: unknown): Promise<T[]> {
    const q = query(this.collectionRef, where(field as string, '==', value));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => this.convertFromFirestore(doc));
  }
} 