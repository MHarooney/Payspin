import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { DashboardStats } from '../types/firestore';
import { firebaseService } from '../services/firebase';

interface DataContextType {
  dashboardStats: DashboardStats | null;
  loading: boolean;
  refreshDashboardStats: () => Promise<void>;
  refreshAll: () => Promise<void>;
}

const DataContext = createContext<DataContextType | undefined>(undefined);

export const useData = () => {
  const context = useContext(DataContext);
  if (context === undefined) {
    throw new Error('useData must be used within a DataProvider');
  }
  return context;
};

interface DataProviderProps {
  children: ReactNode;
}

export const DataProvider: React.FC<DataProviderProps> = ({ children }) => {
  const [dashboardStats, setDashboardStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  const refreshDashboardStats = async () => {
    try {
      setLoading(true);
      const stats = await firebaseService.getDashboardStats();
      setDashboardStats(stats);
    } catch (error) {
      console.error('Error fetching dashboard stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const refreshAll = async () => {
    await refreshDashboardStats();
  };

  useEffect(() => {
    refreshDashboardStats();
  }, []);

  const value: DataContextType = {
    dashboardStats,
    loading,
    refreshDashboardStats,
    refreshAll,
  };

  return (
    <DataContext.Provider value={value}>
      {children}
    </DataContext.Provider>
  );
}; 