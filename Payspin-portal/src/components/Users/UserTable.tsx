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
  useTheme,
  useMediaQuery,
  Card,
  CardContent,
  Stack,
  Avatar,
  Divider,
  Button,
} from '@mui/material';
import {
  MoreVert as MoreVertIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  Circle as CircleIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  CalendarToday as CalendarIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { User, UserTableState } from '../../types/firestore';
import { format, isValid } from 'date-fns';
import { Link as RouterLink } from 'react-router-dom';
import { Timestamp, DocumentReference } from 'firebase/firestore';
import { GradientButton } from '../Common/GradientButton';
import { LoadingSpinner } from '../Common/LoadingSpinner';
import { Add as AddIcon } from '@mui/icons-material';

interface UserTableProps {
  users: User[];
  loading: boolean;
  tableState: UserTableState;
  totalUsers: number;
  onTableStateChange: (newState: UserTableState) => void;
  onUpdateStatus: (userId: string, isActive: boolean) => Promise<void>;
  onUpdateRole: (userId: string, role: User['role']) => Promise<void>;
  onCreateUser?: () => void;
  onEditUser?: (user: User) => void;
  onDeleteUser?: (user: User) => void;
}

export const UserTable: React.FC<UserTableProps> = ({
  users,
  loading,
  tableState,
  totalUsers,
  onTableStateChange,
  onUpdateStatus,
  onUpdateRole,
  onCreateUser,
  onEditUser,
  onDeleteUser
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const isTablet = useMediaQuery(theme.breakpoints.between('md', 'lg'));
  
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const [selectedUser, setSelectedUser] = React.useState<User | null>(null);

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, user: User) => {
    setAnchorEl(event.currentTarget);
    setSelectedUser(user);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setSelectedUser(null);
  };

  const handleChangePage = (event: unknown, newPage: number) => {
    onTableStateChange({
      ...tableState,
      page: newPage + 1
    });
  };

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    onTableStateChange({
      ...tableState,
      page: 1,
      pageSize: parseInt(event.target.value, 10)
    });
  };

  const handleUpdateStatus = async () => {
    if (selectedUser) {
      await onUpdateStatus(selectedUser.id, !selectedUser.isActive);
      handleMenuClose();
    }
  };

  const handleUpdateRole = async (role: User['role']) => {
    if (selectedUser) {
      await onUpdateRole(selectedUser.id, role);
      handleMenuClose();
    }
  };

  const getRoleColor = (role: User['role']) => {
    switch (role) {
      case 'admin':
        return 'error';
      case 'moderator':
        return 'warning';
      default:
        return 'primary';
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

  const getCircleId = (circleId: string | undefined) => {
    if (!circleId) return '-';
    return circleId;
  };

  if (loading && users.length === 0) {
    return (
      <Box sx={{ p: 3, textAlign: 'center' }}>
        <LoadingSpinner variant="default" size="large" />
        <Typography sx={{ mt: 2, color: 'text.secondary' }}>
          Loading users...
        </Typography>
      </Box>
    );
  }

  if (!loading && users.length === 0) {
    return (
      <Box sx={{ 
        p: 4, 
        textAlign: 'center',
        bgcolor: 'background.paper',
        borderRadius: 2,
        border: '1px solid',
        borderColor: 'divider',
      }}>
        <Typography variant="h6" sx={{ mb: 1, color: 'text.primary' }}>
          No Users Found
        </Typography>
        <Typography sx={{ mb: 3, color: 'text.secondary' }}>
          Get started by creating your first user account
        </Typography>
        {onCreateUser && (
          <GradientButton
            onClick={onCreateUser}
            text="Create First User"
            startIcon={<AddIcon />}
            size="large"
            variant="primary"
          />
        )}
      </Box>
    );
  }

  // Mobile/Tablet Card View
  if (isMobile || isTablet) {
    return (
      <>
        <Stack spacing={2} sx={{ mb: 2 }}>
          {users.map((user) => (
            <Card key={user.id} sx={{ width: '100%' }}>
              <CardContent sx={{ p: { xs: 2, sm: 3 } }}>
                <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', mb: 2 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, flex: 1 }}>
                    <Avatar sx={{ 
                      width: { xs: 40, sm: 48 }, 
                      height: { xs: 40, sm: 48 },
                      bgcolor: user.isActive ? 'success.main' : 'grey.400'
                    }}>
                      {user.firstName?.[0]?.toUpperCase() || user.lastName?.[0]?.toUpperCase() || 'U'}
                    </Avatar>
                    <Box sx={{ flex: 1, minWidth: 0 }}>
                      <Typography 
                        variant="subtitle1" 
                        sx={{ 
                          fontWeight: 600,
                          fontSize: { xs: '1rem', sm: '1.125rem' },
                          mb: 0.5,
                        }}
                        noWrap
                      >
                        {user.firstName} {user.lastName}
                      </Typography>
                      <Stack direction="row" spacing={1} alignItems="center" flexWrap="wrap">
                        <Chip
                          label={user.isActive ? 'Active' : 'Inactive'}
                          color={user.isActive ? 'success' : 'default'}
                          size="small"
                          sx={{ 
                            fontSize: { xs: '0.625rem', sm: '0.75rem' },
                            height: { xs: 20, sm: 24 },
                          }}
                        />
                        <Chip
                          label={user.role || 'user'}
                          color={getRoleColor(user.role)}
                          variant="outlined"
                          size="small"
                          sx={{ 
                            fontSize: { xs: '0.625rem', sm: '0.75rem' },
                            height: { xs: 20, sm: 24 },
                          }}
                        />
                      </Stack>
                    </Box>
                  </Box>
                  <IconButton
                    onClick={(e) => handleMenuOpen(e, user)}
                    sx={{ 
                      minWidth: 44,
                      minHeight: 44,
                    }}
                  >
                    <MoreVertIcon />
                  </IconButton>
                </Box>

                <Stack spacing={1.5}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <EmailIcon sx={{ fontSize: { xs: 16, sm: 18 }, color: 'text.secondary' }} />
                    <Typography 
                      variant="body2" 
                      sx={{ 
                        fontSize: { xs: '0.875rem', sm: '1rem' },
                        color: 'text.secondary',
                      }}
                      noWrap
                    >
                      {user.email || 'No email'}
                    </Typography>
                  </Box>

                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <PhoneIcon sx={{ fontSize: { xs: 16, sm: 18 }, color: 'text.secondary' }} />
                    <Typography 
                      variant="body2" 
                      sx={{ 
                        fontSize: { xs: '0.875rem', sm: '1rem' },
                        color: 'text.secondary',
                      }}
                      noWrap
                    >
                      {user.phoneNumber || 'No phone'}
                    </Typography>
                  </Box>

                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <CircleIcon sx={{ fontSize: { xs: 16, sm: 18 }, color: 'text.secondary' }} />
                    <Typography 
                      variant="body2" 
                      sx={{ 
                        fontSize: { xs: '0.875rem', sm: '1rem' },
                        color: 'text.secondary',
                      }}
                      noWrap
                    >
                      Circle: {getCircleId(user.circleId)}
                    </Typography>
                  </Box>

                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <CalendarIcon sx={{ fontSize: { xs: 16, sm: 18 }, color: 'text.secondary' }} />
                    <Typography 
                      variant="body2" 
                      sx={{ 
                        fontSize: { xs: '0.875rem', sm: '1rem' },
                        color: 'text.secondary',
                      }}
                    >
                      Created: {formatDate(user.createdAt)}
                    </Typography>
                  </Box>
                </Stack>
              </CardContent>
            </Card>
          ))}
        </Stack>

        <TablePagination
          component="div"
          count={totalUsers}
          page={(tableState.page || 1) - 1}
          onPageChange={handleChangePage}
          rowsPerPage={tableState.pageSize}
          onRowsPerPageChange={handleChangeRowsPerPage}
          sx={{
            '& .MuiTablePagination-selectLabel, & .MuiTablePagination-displayedRows': {
              fontSize: { xs: '0.75rem', sm: '0.875rem' },
            },
          }}
        />

        <Menu
          anchorEl={anchorEl}
          open={Boolean(anchorEl)}
          onClose={handleMenuClose}
          PaperProps={{
            sx: {
              minWidth: { xs: 160, sm: 180 },
              borderRadius: 2,
            },
          }}
        >
          <MenuItem onClick={handleUpdateStatus}>
            {selectedUser?.isActive ? 'Deactivate User' : 'Activate User'}
          </MenuItem>
          <Divider />
          <MenuItem onClick={() => handleUpdateRole('user')}>
            Set as User
          </MenuItem>
          <MenuItem onClick={() => handleUpdateRole('moderator')}>
            Set as Moderator
          </MenuItem>
          <MenuItem onClick={() => handleUpdateRole('admin')}>
            Set as Admin
          </MenuItem>
          {onEditUser && (
            <>
              <Divider />
              <MenuItem onClick={() => {
                onEditUser(selectedUser!);
                handleMenuClose();
              }}>
                <EditIcon sx={{ mr: 1, fontSize: 20 }} />
                Edit User
              </MenuItem>
            </>
          )}
          {onDeleteUser && (
            <>
              <Divider />
              <MenuItem 
                onClick={() => {
                  onDeleteUser(selectedUser!);
                  handleMenuClose();
                }}
                              sx={{ color: 'error.main' }}
              >
                <DeleteIcon sx={{ mr: 1, fontSize: 20 }} />
                Delete User
              </MenuItem>
            </>
          )}
        </Menu>
      </>
    );
  }

  // Desktop Table View
  return (
    <>
      <TableContainer 
        component={Paper} 
        sx={{ 
          mb: 2, 
          bgcolor: 'background.paper',
          borderRadius: 2,
          overflow: 'hidden',
        }}
      >
        <Table>
          <TableHead>
            <TableRow>
              <TableCell sx={{ fontWeight: 600 }}>Name</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Email</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Phone</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Circle ID</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Created</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Status</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Role</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {users.map((user) => (
              <TableRow key={user.id} hover>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Avatar sx={{ 
                      width: 32, 
                      height: 32,
                      bgcolor: user.isActive ? 'success.main' : 'grey.400'
                    }}>
                      {user.firstName?.[0]?.toUpperCase() || user.lastName?.[0]?.toUpperCase() || 'U'}
                    </Avatar>
                    <Typography variant="body2" sx={{ fontWeight: 500 }}>
                  {user.firstName} {user.lastName}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Typography variant="body2" noWrap sx={{ maxWidth: 200 }}>
                    {user.email}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {user.phoneNumber || '-'}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {getCircleId(user.circleId)}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {formatDate(user.createdAt)}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip
                    label={user.isActive ? 'Active' : 'Inactive'}
                    color={user.isActive ? 'success' : 'error'}
                    size="small"
                    sx={{ fontSize: '0.75rem' }}
                  />
                </TableCell>
                <TableCell>
                  <Chip
                    label={user.role || 'user'}
                    color={getRoleColor(user.role)}
                    variant="outlined"
                    size="small"
                    sx={{ fontSize: '0.75rem' }}
                  />
                </TableCell>
                <TableCell>
                  <IconButton
                    onClick={(e) => handleMenuOpen(e, user)}
                    size="small"
                    sx={{ minWidth: 32, minHeight: 32 }}
                  >
                    <MoreVertIcon />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
      
      <TablePagination
        component="div"
        count={totalUsers}
        page={(tableState.page || 1) - 1}
        onPageChange={handleChangePage}
        rowsPerPage={tableState.pageSize}
        onRowsPerPageChange={handleChangeRowsPerPage}
      />

      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
        PaperProps={{
          sx: {
            minWidth: 200,
            borderRadius: 2,
          },
        }}
      >
        <MenuItem onClick={handleUpdateStatus}>
          {selectedUser?.isActive ? 'Deactivate User' : 'Activate User'}
        </MenuItem>
        <Divider />
        <MenuItem onClick={() => handleUpdateRole('user')}>
          Set as User
        </MenuItem>
        <MenuItem onClick={() => handleUpdateRole('moderator')}>
          Set as Moderator
        </MenuItem>
        <MenuItem onClick={() => handleUpdateRole('admin')}>
          Set as Admin
        </MenuItem>
        {onEditUser && (
          <>
            <Divider />
            <MenuItem onClick={() => {
              onEditUser(selectedUser!);
              handleMenuClose();
            }}>
              <EditIcon sx={{ mr: 1, fontSize: 20 }} />
              Edit User
            </MenuItem>
          </>
        )}
        {onDeleteUser && (
          <>
            <Divider />
            <MenuItem 
              onClick={() => {
                onDeleteUser(selectedUser!);
                handleMenuClose();
              }}
              sx={{ color: 'error.main' }}
            >
              <DeleteIcon sx={{ mr: 1, fontSize: 20 }} />
              Delete User
            </MenuItem>
          </>
        )}
      </Menu>
    </>
  );
}; 