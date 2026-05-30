import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';
import { Toaster } from 'react-hot-toast';

// Theme
import { theme } from './theme/theme';

// Layout Components
import DashboardLayout from './components/Layout/DashboardLayout';

// Page Components
import { Dashboard } from './pages/Dashboard';
import { Users } from './pages/Users';
import { Circles } from './pages/Circles';
import { CircleDetail } from './pages/CircleDetail';
import { Posts } from './pages/Posts';
import { PostEditor } from './pages/PostEditor';
import { PostTypeManager } from './pages/PostTypeManager';
import { Notifications } from './pages/Notifications';
import { Offers } from './pages/Offers';
import { PaymentMethods } from './pages/PaymentMethods';
import { Analytics } from './pages/Analytics';
import { Settings } from './pages/Settings';
import { Login } from './pages/Login';

// Context Providers
import { AuthProvider } from './contexts/AuthContext';
import { DataProvider } from './contexts/DataContext';

// Components
import ProtectedRoute from './components/Auth/ProtectedRoute';

const App: React.FC = () => {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AuthProvider>
        <DataProvider>
          <Router>
            <div className="App">
              {/* React Hot Toast for notifications */}
              <Toaster
                position="top-right"
                toastOptions={{
                  duration: 4000,
                  style: {
                    background: '#fff',
                    color: '#374151',
                    border: '1px solid #E5E7EB',
                    borderRadius: '12px',
                    boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.08)',
                    fontFamily: 'Inter, sans-serif',
                    fontSize: 'clamp(0.875rem, 1vw, 1rem)',
                    maxWidth: '90vw',
                    padding: '12px 16px',
                  },
                  success: {
                    iconTheme: {
                      primary: '#10B981',
                      secondary: '#fff',
                    },
                  },
                  error: {
                    iconTheme: {
                      primary: '#EF4444',
                      secondary: '#fff',
                    },
                  },
                  loading: {
                    iconTheme: {
                      primary: '#07D8DD',
                      secondary: '#fff',
                    },
                  },
                }}
                containerStyle={{
                  top: 20,
                  right: 20,
                }}
                gutter={8}
              />

              <Routes>
                {/* Public Routes */}
                <Route path="/login" element={<Login />} />

                {/* Protected Routes */}
                <Route
                  path="/*"
                  element={
                    <ProtectedRoute>
                      <DashboardLayout>
                        <main id="main-content" tabIndex={-1}>
                          <Routes>
                            {/* Dashboard */}
                            <Route path="/" element={<Dashboard />} />
                            <Route path="/dashboard" element={<Dashboard />} />

                            {/* Users Management */}
                            <Route path="/users" element={<Users />} />

                            {/* Circles Management */}
                            <Route path="/circles" element={<Circles />} />
                            <Route path="/circles/:id" element={<CircleDetail />} />

                            {/* Content Management */}
                            <Route path="/posts" element={<Posts />} />
                            <Route path="/posts/create" element={<PostEditor />} />
                            <Route path="/posts/edit/:id" element={<PostEditor />} />
                            <Route path="/post-types" element={<PostTypeManager />} />

                            {/* Communications */}
                            <Route path="/notifications" element={<Notifications />} />

                            {/* Promotions */}
                            <Route path="/offers" element={<Offers />} />

                            {/* Payment Management */}
                            <Route path="/payment-methods" element={<PaymentMethods />} />

                            {/* Analytics & Reports */}
                            <Route path="/analytics" element={<Analytics />} />

                            {/* System Settings */}
                            <Route path="/settings" element={<Settings />} />

                            {/* Catch all route */}
                            <Route path="*" element={<Navigate to="/dashboard" replace />} />
                          </Routes>
                        </main>
                      </DashboardLayout>
                    </ProtectedRoute>
                  }
                />
              </Routes>
            </div>
          </Router>
        </DataProvider>
      </AuthProvider>
    </ThemeProvider>
  );
};

export default App;
