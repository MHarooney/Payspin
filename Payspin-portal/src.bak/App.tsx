import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import ProtectedRoute from './components/Auth/ProtectedRoute';
import DashboardLayout from './components/Layout/DashboardLayout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import Circles from './pages/Circles';
import CircleDetail from './pages/CircleDetail';
import Blogs from './pages/Blogs';
import BlogEditor from './pages/BlogEditor';
import News from './pages/News';
import NewsEditor from './pages/NewsEditor';
import Notifications from './pages/Notifications';
import Offers from './pages/Offers';
import PaymentMethods from './pages/PaymentMethods';
import Analytics from './pages/Analytics';
import Settings from './pages/Settings';

const App: React.FC = () => {
  return (
    <Router>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        
        {/* Protected Routes */}
        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <Dashboard />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/users"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <Users />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/circles"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <Circles />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/circles/:id"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <CircleDetail />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/blogs"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <Blogs />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/blogs/new"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <BlogEditor />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/news"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <News />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/news/new"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <NewsEditor />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/notifications"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <Notifications />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/offers"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <Offers />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/payment-methods"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <PaymentMethods />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/analytics"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <Analytics />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/settings"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <Settings />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
      </Routes>
    </Router>
  );
};

export default App; 