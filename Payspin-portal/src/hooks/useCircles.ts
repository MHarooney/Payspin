import { useState, useEffect } from 'react';
import {
  collection,
  query,
  where,
  orderBy,
  limit,
  getDocs,
  QuerySnapshot,
  DocumentData,
  CollectionReference,
  Timestamp,
} from 'firebase/firestore';
import { db } from '../config/firebase';
import { Circle, TableState } from '../types/firestore';
import { firebaseService } from '../services/firebase';
import toast from 'react-hot-toast';

interface CircleTableState extends TableState {
  filters: {
    status?: 'active' | 'completed' | 'pending' | 'cancelled';
    finished?: boolean;
  };
}

const defaultTableState: CircleTableState = {
  page: 1,
  pageSize: 10,
  search: '',
  filters: {
    status: undefined,
    finished: undefined,
  },
  sort: {
    field: 'startdate',
    direction: 'desc',
  },
};

interface UseCirclesReturn {
  circles: Circle[];
  loading: boolean;
  error: Error | null;
  totalCircles: number;
  stats: {
    total: number;
    active: number;
    completed: number;
    pending: number;
  };
  tableState: CircleTableState;
  handleTableStateChange: (newState: CircleTableState) => void;
  handleUpdateStatus: (circleId: string, newStatus: 'active' | 'completed' | 'pending' | 'cancelled') => Promise<void>;
}

// Helper function to clean circle data
const cleanCircleData = (data: DocumentData, docId: string): Circle => {
  const cleanCircle: Circle = {
    id: docId,
    adminDocRef: data.adminDocRef,
    months: data.months || 0,
    circle_id: data.circle_id || '',
    payment_per_month: data.payment_per_month || 0,
    endDate: data.endDate instanceof Timestamp ? data.endDate : (typeof data.endDate === 'string' ? Timestamp.fromDate(new Date(data.endDate)) : null),
    adminNotificationRef: data.adminNotificationRef,
    name: data.name || '',
    finished: Boolean(data.finished),
    startdate: data.startdate instanceof Timestamp ? data.startdate : (typeof data.startdate === 'string' ? Timestamp.fromDate(new Date(data.startdate)) : null),
    circle_status: data.circle_status || 'pending',
    description: data.description || '',
    isPrivate: Boolean(data.isPrivate),
    currentTurn: data.currentTurn || 0,
    currentParticipants: data.currentParticipants || (data.RealUsers ? data.RealUsers.length : 0),
    maxParticipants: data.maxParticipants || 10,
    totalAmount: data.totalAmount || (data.payment_per_month * data.months) || 0,
    paymentAmount: data.paymentAmount || data.payment_per_month || 0,
    generatedUsers: Array.isArray(data.generatedUsers) ? data.generatedUsers : [],
    roles: Array.isArray(data.roles) ? data.roles : [],
    RealUsers: Array.isArray(data.RealUsers) ? data.RealUsers : [],
    createdAt: data.createdAt instanceof Timestamp ? data.createdAt : Timestamp.now(),
    updatedAt: data.updatedAt instanceof Timestamp ? data.updatedAt : Timestamp.now(),
  };

  return cleanCircle;
};

export const useCircles = (): UseCirclesReturn => {
  const [circles, setCircles] = useState<Circle[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [totalCircles, setTotalCircles] = useState(0);
  const [stats, setStats] = useState({
    total: 0,
    active: 0,
    completed: 0,
    pending: 0,
  });
  const [tableState, setTableState] = useState<CircleTableState>(defaultTableState);

  const fetchCircles = async () => {
    try {
      setLoading(true);
      setError(null);

      const circlesRef = collection(db, 'circles') as CollectionReference<Circle>;
      let constraints = [];

      // Add filters
      if (tableState.filters.status) {
        constraints.push(where('circle_status', '==', tableState.filters.status));
      }
      
      if (tableState.filters.finished !== undefined) {
        constraints.push(where('finished', '==', tableState.filters.finished));
      }

      // Add sorting
      if (tableState.sort) {
        constraints.push(orderBy(tableState.sort.field, tableState.sort.direction));
      }

      // Add pagination
      constraints.push(limit(tableState.pageSize));

      const baseQuery = query(circlesRef, ...constraints);
      const snapshot = await getDocs(baseQuery);

      const fetchedCircles = snapshot.docs.map(doc => cleanCircleData(doc.data(), doc.id));

      // If we have a search term, filter by it
      let filteredCircles = fetchedCircles;
      if (tableState.search) {
        const searchLower = tableState.search.toLowerCase();
        filteredCircles = fetchedCircles.filter(circle =>
          circle.name.toLowerCase().includes(searchLower) ||
          circle.circle_id.toLowerCase().includes(searchLower) ||
          (circle.description && circle.description.toLowerCase().includes(searchLower))
        );
      }

      // Calculate stats
      const activeCircles = filteredCircles.filter(circle => circle.circle_status === 'active').length;
      const completedCircles = filteredCircles.filter(circle => circle.circle_status === 'completed').length;
      const pendingCircles = filteredCircles.filter(circle => circle.circle_status === 'pending').length;

      setCircles(filteredCircles);
      setTotalCircles(filteredCircles.length);
      setStats({
        total: filteredCircles.length,
        active: activeCircles,
        completed: completedCircles,
        pending: pendingCircles,
      });

    } catch (err) {
      console.error('Error fetching circles:', err);
      setError(err instanceof Error ? err : new Error('An error occurred while fetching circles'));
      toast.error('Failed to fetch circles');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCircles();
  }, [tableState]);

  const handleTableStateChange = (newState: CircleTableState) => {
    setTableState(newState);
  };

  const handleUpdateStatus = async (circleId: string, newStatus: 'active' | 'completed' | 'pending' | 'cancelled') => {
    try {
      await firebaseService.circles.update(circleId, {
        circle_status: newStatus,
        updatedAt: Timestamp.now()
      });
      await fetchCircles(); // Refresh the data
      toast.success(`Circle status updated to ${newStatus} successfully`);
    } catch (error) {
      console.error('Error updating circle status:', error);
      toast.error('Failed to update circle status');
    }
  };

  return {
    circles,
    loading,
    error,
    totalCircles,
    stats,
    tableState,
    handleTableStateChange,
    handleUpdateStatus,
  };
}; 