import React from 'react';
import {
  Container,
  Typography,
  Box,
  Grid,
  SelectChangeEvent,
  useTheme,
  useMediaQuery,
} from '@mui/material';
import { CirclesTable } from '../components/Circles/CirclesTable';
import { CirclesFilters } from '../components/Circles/CirclesFilters';
import { useCircles } from '../hooks/useCircles';
import { LoadingSpinner } from '../components/Common/LoadingSpinner';
import { StatCard } from '../components/Common/StatCard';
import { PayspinColors } from '../theme/theme';
import {
  Groups as GroupsIcon,
  CheckCircle as CheckCircleIcon,
  Schedule as ScheduleIcon,
  Cancel as CancelIcon,
} from '@mui/icons-material';
import { Circle } from '../types/firestore';

export const Circles: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const isTablet = useMediaQuery(theme.breakpoints.between('md', 'lg'));

  const {
    circles,
    loading,
    error,
    stats,
    totalCircles,
    tableState,
    handleTableStateChange,
    handleUpdateStatus,
  } = useCircles();

  const handleFilterChange = (filters: { status?: Circle['circle_status']; finished?: boolean }) => {
    handleTableStateChange({
      ...tableState,
      filters: {
        ...tableState.filters,
        ...filters,
      },
      page: 1, // Reset to first page when filters change
    });
  };

  const handleSearchChange = (search: string) => {
    handleTableStateChange({
      ...tableState,
      search,
      page: 1, // Reset to first page when search changes
    });
  };

  if (loading && circles.length === 0) {
    return (
      <Container maxWidth="xl" sx={{ py: 3 }}>
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '50vh' }}>
          <LoadingSpinner variant="default" size="large" />
        </Box>
      </Container>
    );
  }

  if (error) {
    return (
      <Container maxWidth="xl" sx={{ py: 3 }}>
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Typography variant="h6" color="error" sx={{ mb: 2 }}>
            Error Loading Circles
          </Typography>
          <Typography color="text.secondary">
            {error.message}
          </Typography>
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="xl" sx={{ p: { xs: 1, sm: 2, md: 3 } }}>
      {/* Page Header */}
      <Box sx={{ mb: 4 }}>
        <Typography 
          variant="h4" 
          sx={{ 
            mb: 1,
            fontWeight: 700,
            color: 'text.primary',
            fontSize: { xs: '1.75rem', sm: '2rem', md: '2.25rem' },
          }}
        >
          Circles Management
        </Typography>
        <Typography 
          variant="body1" 
          color="text.secondary"
          sx={{ 
            fontSize: '1.1rem',
            opacity: 0.8,
          }}
        >
          Manage circles, participants, and payment schedules
        </Typography>
      </Box>

      {/* Statistics Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            title="Total Circles"
            value={stats.total}
            icon={<GroupsIcon />}
            color={PayspinColors.primary}
            subtitle="All circles created"
            variant="elevated"
            size="large"
          />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            title="Active Circles"
            value={stats.active}
            icon={<CheckCircleIcon />}
            color={PayspinColors.success}
            subtitle="Currently running"
            variant="elevated"
            size="large"
          />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            title="Completed Circles"
            value={stats.completed}
            icon={<CheckCircleIcon />}
            color={PayspinColors.primary}
            subtitle="Successfully finished"
            variant="elevated"
            size="large"
          />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            title="Pending Circles"
            value={stats.pending}
            icon={<ScheduleIcon />}
            color={PayspinColors.warning}
            subtitle="Awaiting start"
            variant="elevated"
            size="large"
          />
        </Grid>
      </Grid>

      {/* Filters Section */}
      <Box sx={{ mb: 4 }}>
        <CirclesFilters
          filters={{
            status: tableState.filters.status,
            finished: tableState.filters.finished,
            search: tableState.search,
          }}
          onFilterChange={handleFilterChange}
          onSearchChange={handleSearchChange}
        />
      </Box>

      <CirclesTable
        circles={circles}
        loading={loading}
        tableState={tableState}
        totalCircles={totalCircles}
        onTableStateChange={handleTableStateChange}
        onUpdateStatus={handleUpdateStatus}
      />
    </Container>
  );
}; 