import React, { useEffect, useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Avatar,
  Chip,
  Button,
  useTheme,
  useMediaQuery,
  Grid,
  Stack,
  Divider,
} from '@mui/material';
import {
  People,
  Groups,
  AttachMoney,
  Assessment,
  ArrowUpward,
  ArrowDownward,
} from '@mui/icons-material';
import { useData } from '../contexts/DataContext';
import { firebaseService } from '../services/firebase';
import { PayspinColors } from '../theme/theme';
import LoadingSpinner from '../components/Common/LoadingSpinner';
import { StatCard } from '../components/Common/StatCard';
import toast from 'react-hot-toast';
import { User, Circle } from '../types/firestore';
import { Timestamp } from 'firebase/firestore';



interface DashboardUser {
  id: string;
  phoneNumber: string;
  firstName: string;
  lastName: string;
  displayName: string;
  email: string;
  isActive: boolean;
  createdAt: Date | null;
  updatedAt: Date | null;
  lastLoginAt: Date | null;
  [key: string]: any; // Allow dynamic access for cleaning
}

interface DashboardCircle {
  id: string;
  name: string;
  circle_id: string;
  payment_per_month: number;
  months: number;
  circle_status: string;
  finished: boolean;
  members: number;
  paymentAmount: number;
  startDate: Date | null;
  endDate: Date | null;
  [key: string]: any; // Allow dynamic access for cleaning
}

// Helper function to convert Firestore Timestamp to Date
const convertTimestamp = (timestamp: unknown): Date | null => {
  if (!timestamp) return null;
  if (timestamp instanceof Date) return timestamp;
  if (timestamp instanceof Timestamp) return timestamp.toDate();
  if (typeof timestamp === 'object' && timestamp !== null) {
    // Handle raw Firestore timestamp object
    const ts = timestamp as { seconds: number; nanoseconds: number };
    if ('seconds' in ts && 'nanoseconds' in ts) {
      return new Date(ts.seconds * 1000 + ts.nanoseconds / 1000000);
    }
  }
  if (typeof timestamp === 'string') {
    const date = new Date(timestamp);
    return isNaN(date.getTime()) ? null : date;
  }
  return null;
};

export const Dashboard: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const isTablet = useMediaQuery(theme.breakpoints.between('sm', 'md'));
  const { dashboardStats, loading, refreshDashboardStats } = useData();
  const [recentUsers, setRecentUsers] = useState<DashboardUser[]>([]);
  const [recentCircles, setRecentCircles] = useState<DashboardCircle[]>([]);
  const [loadingData, setLoadingData] = useState(true);

  useEffect(() => {
    const fetchRecentData = async () => {
      try {
        setLoadingData(true);
        const [users, circles] = await Promise.all([
          firebaseService.users.getRecentlyActiveUsers(5).catch(error => {
            console.error('Error fetching recent users:', error);
            return [];
          }),
          firebaseService.circles.getActiveCircles().catch(error => {
            console.error('Error fetching active circles:', error);
            return [];
          }),
        ]);

        // Convert Firestore documents to plain objects and clean the data
        const cleanUsers = users.map(user => {
          const cleanUser: DashboardUser = {
            id: user.id || '',
            phoneNumber: user.phoneNumber || '',
            firstName: user.firstName || '',
            lastName: user.lastName || '',
            displayName: user.displayName || `${user.firstName} ${user.lastName}` || 'Unknown User',
            email: user.email || 'No email',
            isActive: Boolean(user.isActive),
            createdAt: convertTimestamp(user.createdAt),
            updatedAt: convertTimestamp(user.updatedAt),
            lastLoginAt: convertTimestamp(user.lastLoginAt)
          };

          // Add any additional fields from the user object
          Object.keys(user).forEach(key => {
            if (!(key in cleanUser) && !key.startsWith('_') && key !== 'converter' && key !== 'firestore') {
              const value = (user as Record<string, any>)[key];
              if (value && typeof value === 'object') {
                if ('seconds' in value) { // Firestore Timestamp
                  (cleanUser as Record<string, any>)[key] = convertTimestamp(value);
                } else if (Array.isArray(value)) {
                  (cleanUser as Record<string, any>)[key] = value.map(item => 
                    item && typeof item === 'object' && item._path ? item._path.segments.slice(-1)[0] : item
                  );
                } else if (value._path) { // Firestore DocumentReference
                  (cleanUser as Record<string, any>)[key] = value._path.segments.slice(-1)[0];
                } else {
                  (cleanUser as Record<string, any>)[key] = value;
                }
              } else {
                (cleanUser as Record<string, any>)[key] = value;
              }
            }
          });

          return cleanUser;
        });

        const cleanCircles = circles.slice(0, 5).map(circle => {
          const cleanCircle: DashboardCircle = {
            id: circle.id || '',
            name: circle.name || 'Unnamed Circle',
            circle_id: circle.circle_id || '',
            payment_per_month: Number(circle.payment_per_month) || 0,
            months: Number(circle.months) || 0,
            circle_status: circle.circle_status || 'unknown',
            finished: Boolean(circle.finished),
            members: Array.isArray(circle.RealUsers) ? circle.RealUsers.length : 0,
            paymentAmount: Number(circle.payment_per_month) || 0,
            startDate: convertTimestamp(circle.startdate),
            endDate: convertTimestamp(circle.endDate)
          };

          // Add any additional fields from the circle object
          Object.keys(circle).forEach(key => {
            if (!(key in cleanCircle) && !key.startsWith('_') && key !== 'converter' && key !== 'firestore') {
              const value = (circle as Record<string, any>)[key];
              if (value && typeof value === 'object') {
                if ('seconds' in value) { // Firestore Timestamp
                  (cleanCircle as Record<string, any>)[key] = convertTimestamp(value);
                } else if (Array.isArray(value)) {
                  (cleanCircle as Record<string, any>)[key] = value.map(item => 
                    item && typeof item === 'object' && item._path ? item._path.segments.slice(-1)[0] : item
                  );
                } else if (value._path) { // Firestore DocumentReference
                  (cleanCircle as Record<string, any>)[key] = value._path.segments.slice(-1)[0];
                } else {
                  (cleanCircle as Record<string, any>)[key] = value;
                }
              } else {
                (cleanCircle as Record<string, any>)[key] = value;
              }
            }
          });

          return cleanCircle;
        });

        setRecentUsers(cleanUsers);
        setRecentCircles(cleanCircles);
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
        toast.error('Some dashboard data could not be loaded');
        // Set empty arrays to prevent undefined errors
        setRecentUsers([]);
        setRecentCircles([]);
      } finally {
        setLoadingData(false);
      }
    };

    fetchRecentData();
  }, []);

  // Show loading state only when both loading states are true
  if (loading && loadingData) {
    return <LoadingSpinner message="Loading dashboard..." />;
  }

  // Prepare stats with fallback values
  const stats = {
    totalUsers: dashboardStats?.totalUsers || 0,
    activeUsers: dashboardStats?.activeUsers || 0,
    totalCircles: dashboardStats?.totalCircles || 0,
    activeCircles: dashboardStats?.activeCircles || 0,
    totalVolume: dashboardStats?.totalVolume || 0,
    totalPayouts: dashboardStats?.totalPayouts || 0,
    completionRate: dashboardStats?.completionRate || 0,
  };

  return (
    <Box sx={{ maxWidth: '100%', overflow: 'hidden' }}>
      {/* Header */}
      <Box mb={{ xs: 3, md: 4 }}>
        <Typography
          variant="h4"
          fontWeight={700}
          color="text.primary"
          gutterBottom
          sx={{
            fontSize: { xs: '1.5rem', sm: '2rem', md: '2.125rem' },
            lineHeight: 1.2,
          }}
        >
          Dashboard Overview
        </Typography>
        <Typography 
          variant="body1" 
          color="text.secondary"
          sx={{
            fontSize: { xs: '0.875rem', sm: '1rem' },
            lineHeight: 1.5,
          }}
        >
          Monitor your Payspin platform performance and key metrics
        </Typography>
      </Box>

      {/* Statistics Cards */}
      <Grid container spacing={{ xs: 2, sm: 3 }} sx={{ mb: { xs: 3, md: 4 } }}>
        <Grid item xs={12} sm={6} lg={3}>
        <StatCard
          title="Total Users"
          value={stats.totalUsers}
          icon={<People />}
          color={PayspinColors.primary}
          trend={{ value: 12, direction: 'up' }}
          subtitle={`${stats.activeUsers} active users`}
          variant="elevated"
          size="large"
        />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
        <StatCard
          title="Active Circles"
          value={stats.activeCircles}
          icon={<Groups />}
          color={PayspinColors.secondary}
          trend={{ value: 8, direction: 'up' }}
          subtitle={`${stats.totalCircles} total circles`}
          variant="elevated"
          size="large"
        />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
        <StatCard
          title="Total Volume"
          value={`$${stats.totalVolume.toLocaleString()}`}
          icon={<AttachMoney />}
          color={PayspinColors.yellow}
          trend={{ value: 15, direction: 'up' }}
          subtitle={`${stats.totalPayouts} completed payouts`}
          variant="elevated"
          size="large"
        />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
        <StatCard
          title="Completion Rate"
          value={`${stats.completionRate}%`}
          icon={<Assessment />}
          color={PayspinColors.primary}
          trend={{ value: 3, direction: 'up' }}
          subtitle="Circle completion rate"
          variant="elevated"
          size="large"
        />
        </Grid>
      </Grid>

      {/* Recent Activity Section */}
      <Grid container spacing={{ xs: 2, sm: 3 }} sx={{ mb: { xs: 3, md: 4 } }}>
        {/* Recent Users */}
        <Grid item xs={12} md={6}>
          <Card sx={{ height: '100%' }}>
            <CardContent sx={{ p: { xs: 2, sm: 3 } }}>
              <Typography 
                variant="h6" 
                gutterBottom
                sx={{
                  fontSize: { xs: '1rem', sm: '1.25rem' },
                  fontWeight: 600,
                }}
              >
              Recent Active Users
            </Typography>
            {recentUsers.length > 0 ? (
                <Stack spacing={2}>
                  {recentUsers.map((user: DashboardUser) => (
                <Box
                  key={user.id}
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                        gap: 2,
                  }}
                >
                      <Avatar 
                        sx={{ 
                          width: { xs: 32, sm: 40 }, 
                          height: { xs: 32, sm: 40 },
                          flexShrink: 0,
                        }}
                      >
                    {user.displayName?.[0]?.toUpperCase() || user.firstName?.[0]?.toUpperCase() || 'U'}
                  </Avatar>
                      <Box sx={{ flex: 1, minWidth: 0 }}>
                        <Typography 
                          variant="subtitle2"
                          sx={{
                            fontSize: { xs: '0.875rem', sm: '1rem' },
                            fontWeight: 500,
                          }}
                          noWrap
                        >
                      {user.displayName || `${user.firstName || ''} ${user.lastName || ''}`.trim() || 'Unknown User'}
                    </Typography>
                        <Typography 
                          variant="caption" 
                          color="text.secondary"
                          sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}
                          noWrap
                        >
                      {user.email || 'No email'}
                    </Typography>
                  </Box>
                  <Chip
                    size="small"
                    label={user.isActive ? 'Active' : 'Inactive'}
                    color={user.isActive ? 'success' : 'default'}
                        sx={{ 
                          flexShrink: 0,
                          fontSize: { xs: '0.625rem', sm: '0.75rem' },
                          height: { xs: 20, sm: 24 },
                        }}
                  />
                </Box>
                  ))}
                </Stack>
            ) : (
                <Typography 
                  variant="body2" 
                  color="text.secondary" 
                  textAlign="center" 
                  py={2}
                  sx={{ fontSize: { xs: '0.875rem', sm: '1rem' } }}
                >
                No recent users to display
              </Typography>
            )}
          </CardContent>
        </Card>
        </Grid>

        {/* Recent Circles */}
        <Grid item xs={12} md={6}>
          <Card sx={{ height: '100%' }}>
            <CardContent sx={{ p: { xs: 2, sm: 3 } }}>
              <Typography 
                variant="h6" 
                gutterBottom
                sx={{
                  fontSize: { xs: '1rem', sm: '1.25rem' },
                  fontWeight: 600,
                }}
              >
              Active Circles
            </Typography>
            {recentCircles.length > 0 ? (
                <Stack spacing={2}>
                  {recentCircles.map((circle: DashboardCircle) => (
                <Box
                  key={circle.id}
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                        gap: 2,
                  }}
                >
                      <Avatar 
                        sx={{ 
                          width: { xs: 32, sm: 40 }, 
                          height: { xs: 32, sm: 40 },
                          bgcolor: PayspinColors.secondary,
                          flexShrink: 0,
                        }}
                      >
                    <Groups />
                  </Avatar>
                      <Box sx={{ flex: 1, minWidth: 0 }}>
                        <Typography 
                          variant="subtitle2"
                          sx={{
                            fontSize: { xs: '0.875rem', sm: '1rem' },
                            fontWeight: 500,
                          }}
                          noWrap
                        >
                          {circle.name || 'Unnamed Circle'}
                        </Typography>
                        <Typography 
                          variant="caption" 
                          color="text.secondary"
                          sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}
                          noWrap
                        >
                      {circle.members || 0} members
                    </Typography>
                  </Box>
                  <Chip
                    size="small"
                    label={`$${(circle.paymentAmount || 0).toLocaleString()}`}
                    color="primary"
                        sx={{ 
                          flexShrink: 0,
                          fontSize: { xs: '0.625rem', sm: '0.75rem' },
                          height: { xs: 20, sm: 24 },
                        }}
                  />
                </Box>
                  ))}
                </Stack>
            ) : (
                <Typography 
                  variant="body2" 
                  color="text.secondary" 
                  textAlign="center" 
                  py={2}
                  sx={{ fontSize: { xs: '0.875rem', sm: '1rem' } }}
                >
                No active circles to display
              </Typography>
            )}
          </CardContent>
        </Card>
        </Grid>
      </Grid>

      {/* Welcome Card */}
      <Card sx={{ mb: { xs: 3, md: 4 } }}>
        <CardContent sx={{ 
          p: { xs: 3, sm: 4 }, 
          textAlign: 'center' 
        }}>
          <Typography 
            variant="h5" 
            fontWeight={600} 
            color="text.primary" 
            mb={2}
            sx={{
              fontSize: { xs: '1.25rem', sm: '1.5rem' },
              lineHeight: 1.3,
            }}
          >
            Welcome to Payspin Admin Portal
          </Typography>
          <Typography 
            variant="body1" 
            color="text.secondary" 
            mb={3}
            sx={{
              fontSize: { xs: '0.875rem', sm: '1rem' },
              lineHeight: 1.6,
            }}
          >
            You have successfully set up the admin portal for managing your Payspin platform.
            All the Firebase services are configured and ready to use.
          </Typography>
          <Stack 
            direction={{ xs: 'column', sm: 'row' }} 
            spacing={2} 
            justifyContent="center" 
            alignItems="center"
          >
            <Button
              variant="contained"
              className="gradient-button"
              sx={{ 
                minWidth: { xs: '100%', sm: 120 },
                height: { xs: 48, sm: 40 },
              }}
              onClick={() => window.location.href = '/users'}
            >
              Manage Users
            </Button>
            <Button
              variant="outlined"
              sx={{
                minWidth: { xs: '100%', sm: 120 },
                height: { xs: 48, sm: 40 },
                borderColor: PayspinColors.secondary,
                color: PayspinColors.secondary,
              }}
              onClick={() => window.location.href = '/circles'}
            >
              View Circles
            </Button>
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
}; 