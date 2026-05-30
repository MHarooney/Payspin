import React from 'react';
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Chip,
  TablePagination,
  Menu,
  MenuItem,
  Typography,
  Box,
  Link,
  Card,
  CardContent,
  Stack,
  useTheme,
  useMediaQuery,
  Skeleton,
  Divider,
  Button,
  Grid,
} from '@mui/material';
import {
  MoreVert as MoreVertIcon,
  People as PeopleIcon,
  AttachMoney as MoneyIcon,
  Schedule as ScheduleIcon,
  Visibility as ViewIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { Circle } from '../../types/firestore';
import { format } from 'date-fns';
import { Link as RouterLink } from 'react-router-dom';
import { Timestamp } from 'firebase/firestore';
import { PayspinColors } from '../../theme/theme';
import { ActionMenuItem, SimpleActionMenu, useSimpleActionMenu } from '../Common/ActionMenu';

interface CircleTableState {
  page: number;
  pageSize: number;
  search?: string;
  filters: {
    status?: 'active' | 'completed' | 'pending' | 'cancelled';
    finished?: boolean;
  };
  sort?: {
    field: string;
    direction: 'asc' | 'desc';
  };
}

interface CirclesTableProps {
  circles: Circle[];
  loading: boolean;
  tableState: CircleTableState;
  totalCircles: number;
  onTableStateChange: (newState: CircleTableState) => void;
  onUpdateStatus: (circleId: string, status: 'active' | 'completed' | 'pending' | 'cancelled') => Promise<void>;
}

export const CirclesTable: React.FC<CirclesTableProps> = ({
  circles,
  loading,
  tableState,
  totalCircles,
  onTableStateChange,
  onUpdateStatus,
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const isTablet = useMediaQuery(theme.breakpoints.between('md', 'lg'));
  
  // Use the enhanced ActionMenu hook instead of basic MUI Menu
  const { isOpen, selectedItem: selectedCircle, anchorPosition, handleMenuOpen, handleMenuClose } = useSimpleActionMenu<Circle>();

  const handleChangePage = (event: unknown, newPage: number) => {
    onTableStateChange({
      ...tableState,
      page: newPage + 1,
    });
  };

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    onTableStateChange({
      ...tableState,
      page: 1,
      pageSize: parseInt(event.target.value, 10),
    });
  };

  const handleUpdateStatus = async (status: 'active' | 'completed' | 'pending' | 'cancelled') => {
    if (selectedCircle) {
      await onUpdateStatus(selectedCircle.id, status);
      handleMenuClose();
    }
  };

  const getStatusColor = (status: string): "default" | "primary" | "secondary" | "error" | "info" | "success" | "warning" => {
    switch (status) {
      case 'active':
        return 'success';
      case 'completed':
        return 'primary';
      case 'pending':
        return 'warning';
      case 'cancelled':
        return 'error';
      default:
        return 'default';
    }
  };

  const formatDate = (timestamp: Timestamp | null | undefined) => {
    if (!timestamp) return '-';
    try {
      if (timestamp instanceof Timestamp) {
        return format(timestamp.toDate(), 'MMM dd, yyyy');
      }
      return '-';
    } catch (error) {
      console.error('Error formatting date:', error);
      return '-';
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const getActionMenuItems = (circle: Circle): ActionMenuItem[] => {
    return [
      {
        id: 'active',
        label: 'Mark as Active',
        onClick: () => handleUpdateStatus('active'),
      },
      {
        id: 'completed',
        label: 'Mark as Completed',
        onClick: () => handleUpdateStatus('completed'),
      },
      {
        id: 'pending',
        label: 'Mark as Pending',
        onClick: () => handleUpdateStatus('pending'),
      },
      {
        id: 'cancelled',
        label: 'Mark as Cancelled',
        onClick: () => handleUpdateStatus('cancelled'),
        color: 'error',
      },
    ];
  };

  // Mobile Card View
  const MobileCardView = () => (
    <Stack spacing={2}>
      {loading ? (
        // Loading skeletons for mobile
        Array.from({ length: 3 }).map((_, index) => (
          <Card key={index} sx={{ borderRadius: 2 }}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Skeleton variant="text" width="60%" height={24} />
                <Skeleton variant="circular" width={32} height={32} />
              </Box>
              <Stack spacing={1}>
                <Skeleton variant="text" width="40%" height={16} />
                <Skeleton variant="text" width="50%" height={16} />
                <Skeleton variant="text" width="30%" height={16} />
              </Stack>
            </CardContent>
          </Card>
        ))
      ) : circles.length === 0 ? (
        <Box sx={{ p: 3, textAlign: 'center' }}>
          <Typography variant="h6" color="text.secondary" sx={{ mb: 1 }}>
            No circles found
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Try adjusting your filters or search terms
          </Typography>
        </Box>
      ) : (
        circles.map((circle) => (
          <Card key={circle.id} sx={{ borderRadius: 2, boxShadow: theme.shadows[1] }}>
            <CardContent sx={{ p: { xs: 2, sm: 3 } }}>
              {/* Header */}
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Box sx={{ flex: 1, minWidth: 0 }}>
                  <Link
                    component={RouterLink}
                    to={`/circles/${circle.id}`}
                    sx={{ textDecoration: 'none' }}
                  >
                    <Typography 
                      variant="h6" 
                      sx={{ 
                        fontWeight: 600,
                        fontSize: { xs: '1rem', sm: '1.125rem' },
                        color: 'text.primary',
                        '&:hover': { color: 'text.secondary' },
                      }}
                    >
                      {circle.name}
                    </Typography>
                  </Link>
                  <Typography 
                    variant="body2" 
                    sx={{ 
                      fontFamily: 'monospace',
                      color: 'text.secondary',
                      fontSize: { xs: '0.75rem', sm: '0.875rem' },
                    }}
                  >
                    ID: {circle.circle_id}
                  </Typography>
                </Box>
                <IconButton
                  onClick={(e) => handleMenuOpen(e, circle)}
                  size="small"
                  sx={{ ml: 1 }}
                >
                  <MoreVertIcon />
                </IconButton>
              </Box>

              {/* Status */}
              <Box sx={{ mb: 2 }}>
                <Chip
                  label={circle.circle_status}
                  color={getStatusColor(circle.circle_status)}
                  size="small"
                  sx={{ 
                    fontWeight: 600,
                    fontSize: { xs: '0.75rem', sm: '0.875rem' },
                  }}
                />
              </Box>

              {/* Details Grid */}
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                    <PeopleIcon sx={{ mr: 1, fontSize: 16, color: 'text.secondary' }} />
                    <Typography variant="body2" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                      Members
                    </Typography>
                  </Box>
                  <Typography variant="body2" sx={{ fontWeight: 600, fontSize: { xs: '0.875rem', sm: '1rem' } }}>
                    {circle.currentParticipants} / {circle.maxParticipants}
                  </Typography>
                </Grid>

                <Grid item xs={6}>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                    <MoneyIcon sx={{ mr: 1, fontSize: 16, color: 'text.secondary' }} />
                    <Typography variant="body2" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                      Payment/Month
                    </Typography>
                  </Box>
                  <Typography variant="body2" sx={{ fontWeight: 600, fontSize: { xs: '0.875rem', sm: '1rem' } }}>
                    {formatCurrency(circle.payment_per_month)}
                  </Typography>
                </Grid>

                <Grid item xs={6}>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                    <ScheduleIcon sx={{ mr: 1, fontSize: 16, color: 'text.secondary' }} />
                    <Typography variant="body2" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                      Duration
                    </Typography>
                  </Box>
                  <Typography variant="body2" sx={{ fontWeight: 600, fontSize: { xs: '0.875rem', sm: '1rem' } }}>
                    {circle.months} months
                  </Typography>
                </Grid>

                <Grid item xs={6}>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                    <ScheduleIcon sx={{ mr: 1, fontSize: 16, color: 'text.secondary' }} />
                    <Typography variant="body2" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                      Start Date
                    </Typography>
                  </Box>
                  <Typography variant="body2" sx={{ fontWeight: 600, fontSize: { xs: '0.875rem', sm: '1rem' } }}>
                    {formatDate(circle.startdate)}
                  </Typography>
                </Grid>
              </Grid>

              {/* Actions */}
              <Box sx={{ mt: 2, pt: 2, borderTop: `1px solid ${theme.palette.divider}` }}>
                <Stack direction="row" spacing={1}>
                  <Button
                    component={RouterLink}
                    to={`/circles/${circle.id}`}
                    variant="outlined"
                    size="small"
                    startIcon={<ViewIcon />}
                    sx={{ 
                      flex: 1,
                      borderRadius: 2,
                      fontSize: { xs: '0.75rem', sm: '0.875rem' },
                    }}
                  >
                    View Details
                  </Button>
                </Stack>
              </Box>
            </CardContent>
          </Card>
        ))
      )}
    </Stack>
  );

  // Desktop Table View
  const DesktopTableView = () => (
    <TableContainer component={Paper} sx={{ bgcolor: 'background.paper' }}>
      <Table>
        <TableHead>
          <TableRow sx={{ bgcolor: 'grey.50' }}>
            <TableCell sx={{ fontWeight: 600, fontSize: { sm: '0.875rem', md: '1rem' } }}>Name</TableCell>
            <TableCell sx={{ fontWeight: 600, fontSize: { sm: '0.875rem', md: '1rem' } }}>Circle ID</TableCell>
            <TableCell sx={{ fontWeight: 600, fontSize: { sm: '0.875rem', md: '1rem' } }}>Members</TableCell>
            <TableCell sx={{ fontWeight: 600, fontSize: { sm: '0.875rem', md: '1rem' } }}>Payment/Month</TableCell>
            <TableCell sx={{ fontWeight: 600, fontSize: { sm: '0.875rem', md: '1rem' } }}>Duration</TableCell>
            <TableCell sx={{ fontWeight: 600, fontSize: { sm: '0.875rem', md: '1rem' } }}>Start Date</TableCell>
            <TableCell sx={{ fontWeight: 600, fontSize: { sm: '0.875rem', md: '1rem' } }}>Status</TableCell>
            <TableCell sx={{ fontWeight: 600, fontSize: { sm: '0.875rem', md: '1rem' } }}>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {loading ? (
            // Loading skeletons for desktop
            Array.from({ length: 5 }).map((_, index) => (
              <TableRow key={index}>
                <TableCell><Skeleton variant="text" width="80%" /></TableCell>
                <TableCell><Skeleton variant="text" width="60%" /></TableCell>
                <TableCell><Skeleton variant="text" width="40%" /></TableCell>
                <TableCell><Skeleton variant="text" width="50%" /></TableCell>
                <TableCell><Skeleton variant="text" width="30%" /></TableCell>
                <TableCell><Skeleton variant="text" width="60%" /></TableCell>
                <TableCell><Skeleton variant="rectangular" width={60} height={24} sx={{ borderRadius: 1 }} /></TableCell>
                <TableCell><Skeleton variant="circular" width={32} height={32} /></TableCell>
              </TableRow>
            ))
          ) : circles.length === 0 ? (
            <TableRow>
              <TableCell colSpan={8} sx={{ textAlign: 'center', py: 4 }}>
                <Typography variant="h6" color="text.secondary" sx={{ mb: 1 }}>
                  No circles found
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Try adjusting your filters or search terms
                </Typography>
              </TableCell>
            </TableRow>
          ) : (
            circles.map((circle) => (
              <TableRow key={circle.id} sx={{ '&:hover': { bgcolor: 'grey.50' } }}>
                <TableCell>
                  <Link
                    component={RouterLink}
                    to={`/circles/${circle.id}`}
                    sx={{ textDecoration: 'none' }}
                  >
                    <Typography variant="body2" sx={{ fontWeight: 600, color: 'text.primary' }}>
                      {circle.name}
                    </Typography>
                  </Link>
                </TableCell>
                <TableCell>
                  <Typography variant="body2" sx={{ fontFamily: 'monospace', fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                    {circle.circle_id}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <PeopleIcon sx={{ mr: 1, fontSize: 16, color: 'text.secondary' }} />
                    <Typography variant="body2">
                      {circle.currentParticipants} / {circle.maxParticipants}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <MoneyIcon sx={{ mr: 1, fontSize: 16, color: 'text.secondary' }} />
                    <Typography variant="body2">
                      {formatCurrency(circle.payment_per_month)}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <ScheduleIcon sx={{ mr: 1, fontSize: 16, color: 'text.secondary' }} />
                    <Typography variant="body2">
                      {circle.months} months
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>{formatDate(circle.startdate)}</TableCell>
                <TableCell>
                  <Chip
                    label={circle.circle_status}
                    color={getStatusColor(circle.circle_status)}
                    size="small"
                    sx={{ fontWeight: 600 }}
                  />
                </TableCell>
                <TableCell>
                  <IconButton
                    onClick={(e) => handleMenuOpen(e, circle)}
                    size="small"
                  >
                    <MoreVertIcon />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>
    </TableContainer>
  );

  return (
    <>
      {/* Content */}
      {isMobile ? <MobileCardView /> : <DesktopTableView />}

      {/* Pagination */}
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'center', 
        mt: 3,
        '& .MuiTablePagination-root': {
          overflow: 'visible',
        },
      }}>
        <TablePagination
          component="div"
          count={totalCircles}
          page={(tableState.page || 1) - 1}
          onPageChange={handleChangePage}
          rowsPerPage={tableState.pageSize}
          onRowsPerPageChange={handleChangeRowsPerPage}
          rowsPerPageOptions={[5, 10, 25, 50]}
          sx={{
            '& .MuiTablePagination-selectLabel, & .MuiTablePagination-displayedRows': {
              fontSize: { xs: '0.75rem', sm: '0.875rem' },
            },
          }}
        />
      </Box>

      {/* Enhanced Action Menu */}
      {selectedCircle && anchorPosition && (
        <SimpleActionMenu
          items={getActionMenuItems(selectedCircle)}
          isOpen={isOpen}
          anchorPosition={anchorPosition}
          onClose={handleMenuClose}
        />
      )}
    </>
  );
}; 