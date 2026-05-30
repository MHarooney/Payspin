import React, { useState } from 'react';
import {
  Container,
  Typography,
  Box,
  TextField,
  Select,
  MenuItem,
  FormControl,
  Grid,
  SelectChangeEvent,
} from '@mui/material';
import { UserTable } from '../components/Users/UserTable';
import { UserForm } from '../components/Users/UserForm';
import { DeleteConfirmationDialog } from '../components/Users/DeleteConfirmationDialog';
import { CreateUserButton } from '../components/Users/CreateUserButton';
import { useUsers } from '../hooks/useUsers';
import { UserTableState, User } from '../types/firestore';
import { doc, updateDoc } from 'firebase/firestore';
import { db } from '../config/firebase';
import toast from 'react-hot-toast';
import { PayspinColors } from '../theme/theme';
import { StatCard } from '../components/Common/StatCard';
import { LoadingSpinner } from '../components/Common/LoadingSpinner';
import {
  People as PeopleIcon,
  PersonAdd as PersonAddIcon,
  PersonOff as PersonOffIcon,
  AdminPanelSettings as AdminIcon,
} from '@mui/icons-material';

const defaultTableState: UserTableState = {
  page: 1,
  pageSize: 10,
  filters: {
    status: undefined,
  },
  search: '',
  sort: {
    field: 'created_time',
    direction: 'desc'
  }
};

export const Users = () => {
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [showEditForm, setShowEditForm] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);

  const {
    users,
    loading,
    error,
    stats,
    totalUsers,
    tableState,
    handleTableStateChange: onTableStateChange,
    handleUpdateStatus: onUpdateStatus,
    handleUpdateRole: onUpdateRole,
    handleCreateUser,
    handleUpdateUser,
    handleDeleteUser,
    handleCheckEmailExists,
  } = useUsers();

  const handleStatusChange = (event: SelectChangeEvent<string>) => {
    const value = event.target.value as 'active' | 'inactive' | undefined;
    onTableStateChange({
      ...tableState,
      filters: {
        ...tableState.filters,
        status: value,
      },
    });
  };

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    onTableStateChange({
      ...tableState,
      search: event.target.value,
      page: 1,
    });
  };

  const handleTableStateChange = (newState: UserTableState) => {
    onTableStateChange(newState);
  };

  const handleUpdateStatus = async (userId: string, newStatus: boolean) => {
    try {
      const userRef = doc(db, 'users', userId);
      await updateDoc(userRef, {
        isActive: newStatus
      });
      toast.success(`User ${newStatus ? 'activated' : 'deactivated'} successfully`);
      // Refresh the table state to reload data
      handleTableStateChange({
        ...tableState,
        page: 1 // Reset to first page to ensure we see the updated user
      });
    } catch (error) {
      console.error('Error updating user status:', error);
      toast.error('Failed to update user status');
    }
  };

  const handleUpdateRole = async (userId: string, newRole: 'user' | 'admin' | 'moderator') => {
    try {
      const userRef = doc(db, 'users', userId);
      await updateDoc(userRef, {
        role: newRole
      });
      toast.success(`User role updated to ${newRole} successfully`);
      // Refresh the table state to reload data
      handleTableStateChange({
        ...tableState,
        page: 1 // Reset to first page to ensure we see the updated user
      });
    } catch (error) {
      console.error('Error updating user role:', error);
      toast.error('Failed to update user role');
    }
  };

  const handleCreateUserClick = () => {
    setShowCreateForm(true);
  };

  const handleEditUserClick = (user: User) => {
    setSelectedUser(user);
    setShowEditForm(true);
  };

  const handleDeleteUserClick = (user: User) => {
    setSelectedUser(user);
    setShowDeleteDialog(true);
  };

  const handleCreateUserSubmit = async (userData: {
    email: string;
    firstName: string;
    lastName: string;
    phoneNumber?: string;
    role?: 'user' | 'admin' | 'moderator';
    circleId?: string;
    isActive?: boolean;
  }) => {
    return await handleCreateUser(userData);
  };

  const handleEditUserSubmit = async (userData: {
    email: string;
    firstName: string;
    lastName: string;
    phoneNumber?: string;
    role?: 'user' | 'admin' | 'moderator';
    circleId?: string;
    isActive?: boolean;
  }) => {
    if (!selectedUser) return null;
    return await handleUpdateUser(selectedUser.id, userData);
  };

  const handleDeleteUserConfirm = async () => {
    if (!selectedUser) return false;
    return await handleDeleteUser(selectedUser.id);
  };

  if (loading) {
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
            Error Loading Users
          </Typography>
          <Typography color="text.secondary">
            {error.message}
          </Typography>
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="xl" sx={{ py: 3 }}>
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
          Users
        </Typography>
        <Typography 
          variant="body1" 
          color="text.secondary"
          sx={{ fontSize: '1.1rem', opacity: 0.8 }}
        >
          Manage your platform users and their permissions
        </Typography>
      </Box>

      {/* Stats Section */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            title="Total Users"
            value={totalUsers}
            icon={<PeopleIcon />}
            color={PayspinColors.primary}
            subtitle="All registered users"
            variant="elevated"
            size="large"
          />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            title="Active Users"
            value={stats.active}
            icon={<PersonAddIcon />}
            color={PayspinColors.success}
            subtitle="Currently active"
            variant="elevated"
            size="large"
          />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            title="Inactive Users"
            value={stats.inactive}
            icon={<PersonOffIcon />}
            color={PayspinColors.error}
            subtitle="Deactivated accounts"
            variant="elevated"
            size="large"
          />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <StatCard
            title="Admin Users"
            value={stats.admin}
            icon={<AdminIcon />}
            color={PayspinColors.secondary}
            subtitle="Administrators"
            variant="elevated"
            size="large"
          />
        </Grid>
      </Grid>

      {/* Create User Button */}
      <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 4 }}>
        <CreateUserButton
          onClick={handleCreateUserClick}
          disabled={loading}
        />
      </Box>

      {/* Search & Filter Section */}
      <Box sx={{ 
        mb: 4, 
        p: 3, 
        bgcolor: 'background.paper', 
        borderRadius: 2,
        boxShadow: '0px 2px 8px rgba(0, 0, 0, 0.06)',
        border: '1px solid',
        borderColor: 'divider',
      }}>
        <Typography variant="h6" sx={{ mb: 3, fontWeight: 600, color: 'text.primary' }}>
          Search & Filter
        </Typography>
        <Grid container spacing={3}>
          <Grid item xs={12} sm={6} md={4}>
            <TextField
              fullWidth
              placeholder="Search users by name, email, or phone..."
              value={tableState.search || ''}
              onChange={handleSearchChange}
              size="medium"
              sx={{
                '& .MuiOutlinedInput-root': {
                  borderRadius: 1.5,
                  '&:hover .MuiOutlinedInput-notchedOutline': {
                    borderColor: PayspinColors.primary,
                  },
                  '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                    borderColor: PayspinColors.primary,
                    borderWidth: 2,
                  },
                },
              }}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={4}>
            <FormControl fullWidth>
              <Select
                value={tableState.filters.status || ''}
                onChange={handleStatusChange}
                displayEmpty
                size="medium"
                sx={{
                  borderRadius: 1.5,
                  '& .MuiOutlinedInput-notchedOutline': {
                    '&:hover': {
                      borderColor: PayspinColors.primary,
                    },
                  },
                  '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                    borderColor: PayspinColors.primary,
                    borderWidth: 2,
                  },
                }}
              >
                <MenuItem value="">All Status</MenuItem>
                <MenuItem value="active">Active</MenuItem>
                <MenuItem value="inactive">Inactive</MenuItem>
              </Select>
            </FormControl>
          </Grid>
        </Grid>
      </Box>

      <UserTable
        users={users}
        loading={loading}
        tableState={tableState}
        totalUsers={totalUsers}
        onTableStateChange={onTableStateChange}
        onUpdateStatus={onUpdateStatus}
        onUpdateRole={onUpdateRole}
        onCreateUser={handleCreateUserClick}
        onEditUser={handleEditUserClick}
        onDeleteUser={handleDeleteUserClick}
      />

      {/* User Form Dialogs */}
      <UserForm
        open={showCreateForm}
        onClose={() => setShowCreateForm(false)}
        onSubmit={handleCreateUserSubmit}
        mode="create"
        onCheckEmailExists={handleCheckEmailExists}
      />

      <UserForm
        open={showEditForm}
        onClose={() => {
          setShowEditForm(false);
          setSelectedUser(null);
        }}
        onSubmit={handleEditUserSubmit}
        user={selectedUser}
        mode="edit"
        onCheckEmailExists={handleCheckEmailExists}
      />

      {/* Delete Confirmation Dialog */}
      <DeleteConfirmationDialog
        open={showDeleteDialog}
        onClose={() => {
          setShowDeleteDialog(false);
          setSelectedUser(null);
        }}
        onConfirm={handleDeleteUserConfirm}
        user={selectedUser}
      />
    </Container>
  );
}; 