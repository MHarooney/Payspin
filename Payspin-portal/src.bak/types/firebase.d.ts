declare module 'firebase/firestore' {
  import { Firestore as FirestoreType } from '@firebase/firestore-types';

  export interface DocumentData {
    [key: string]: any;
  }

  export interface DocumentReference<T = DocumentData> {
    id: string;
    path: string;
    parent: CollectionReference<T>;
  }

  export interface QueryDocumentSnapshot<T = DocumentData> {
    id: string;
    data(): T;
    exists(): boolean;
  }

  export interface CollectionReference<T = DocumentData> {
    path: string;
    parent: DocumentReference<T> | null;
  }

  export interface Timestamp {
    toDate(): Date;
    fromDate(date: Date): Timestamp;
  }

  export interface Firestore extends FirestoreType {}

  export function collection(firestore: Firestore, path: string): CollectionReference;
  export function doc(firestore: Firestore, path: string, ...pathSegments: string[]): DocumentReference;
  export function getDoc<T>(docRef: DocumentReference<T>): Promise<QueryDocumentSnapshot<T>>;
  export function getDocs<T>(query: CollectionReference<T>): Promise<{ docs: QueryDocumentSnapshot<T>[] }>;
  export function addDoc<T>(collectionRef: CollectionReference<T>, data: T): Promise<DocumentReference<T>>;
  export function updateDoc<T>(docRef: DocumentReference<T>, data: Partial<T>): Promise<void>;
  export function deleteDoc(docRef: DocumentReference): Promise<void>;
  export function query<T>(collectionRef: CollectionReference<T>, ...queryConstraints: any[]): CollectionReference<T>;
  export function where(fieldPath: string, opStr: string, value: any): any;
} 