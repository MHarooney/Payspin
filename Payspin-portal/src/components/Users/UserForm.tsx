import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  FormHelperText,
  Switch,
  FormControlLabel,
  Box,
  Typography,
  Alert,
  CircularProgress,
} from '@mui/material';
import { User } from '../../types/firestore';

interface UserFormProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (userData: {
    email: string;
    firstName: string;
    lastName: string;
    phoneNumber?: string;
    role?: 'user' | 'admin' | 'moderator';
    circleId?: string;
    isActive?: boolean;
  }) => Promise<User | null>;
  user?: User | null;
  mode: 'create' | 'edit';
  onCheckEmailExists?: (email: string, excludeUserId?: string) => Promise<boolean>;
}

interface FormData {
  email: string;
  firstName: string;
  lastName: string;
  phoneNumber: string;
  role: 'user' | 'admin' | 'moderator';
  circleId: string;
  isActive: boolean;
}

interface FormErrors {
  email?: string;
  firstName?: string;
  lastName?: string;
  phoneNumber?: string;
}

const defaultFormData: FormData = {
  email: '',
  firstName: '',
  lastName: '',
  phoneNumber: '',
  role: 'user',
  circleId: '',
  isActive: true,
};

export const UserForm: React.FC<UserFormProps> = ({
  open,
  onClose,
  onSubmit,
  user,
  mode,
  onCheckEmailExists,
}) => {
  const [formData, setFormData] = useState<FormData>(defaultFormData);
  const [errors, setErrors] = useState<FormErrors>({});
  const [loading, setLoading] = useState(false);
  const [emailChecking, setEmailChecking] = useState(false);

  useEffect(() => {
    if (user && mode === 'edit') {
      setFormData({
        email: user.email || '',
        firstName: user.firstName || '',
        lastName: user.lastName || '',
        phoneNumber: user.phoneNumber || '',
        role: user.role || 'user',
        circleId: user.circleId || '',
        isActive: user.isActive !== false,
      });
    } else {
      setFormData(defaultFormData);
    }
    setErrors({});
  }, [user, mode, open]);

  const validateForm = async (): Promise<boolean> => {
    const newErrors: FormErrors = {};

    // Email validation
    if (!formData.email) {
      newErrors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Please enter a valid email address';
    } else if (onCheckEmailExists) {
      setEmailChecking(true);
      try {
        const emailExists = await onCheckEmailExists(formData.email, user?.id);
        if (emailExists) {
          newErrors.email = 'Email already exists';
        }
      } catch (error) {
        console.error('Error checking email:', error);
      } finally {
        setEmailChecking(false);
      }
    }

    // First name validation
    if (!formData.firstName.trim()) {
      newErrors.firstName = 'First name is required';
    }

    // Last name validation
    if (!formData.lastName.trim()) {
      newErrors.lastName = 'Last name is required';
    }

    // Phone number validation (optional but if provided, should be valid)
    if (formData.phoneNumber && !/^\+?[\d\s\-\(\)]+$/.test(formData.phoneNumber)) {
      newErrors.phoneNumber = 'Please enter a valid phone number';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    const isValid = await validateForm();
    if (!isValid) return;

    setLoading(true);
    try {
      const result = await onSubmit({
        email: formData.email.trim(),
        firstName: formData.firstName.trim(),
        lastName: formData.lastName.trim(),
        phoneNumber: formData.phoneNumber.trim() || undefined,
        role: formData.role,
        circleId: formData.circleId.trim() || undefined,
        isActive: formData.isActive,
      });

      if (result) {
        onClose();
      }
    } catch (error) {
      console.error('Error submitting form:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (field: keyof FormData, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }));

    // Clear error when user starts typing
    if (errors[field as keyof FormErrors]) {
      setErrors(prev => ({
        ...prev,
        [field]: undefined,
      }));
    }
  };

  const handleClose = () => {
    if (!loading) {
      onClose();
    }
  };

  return (
    <Dialog 
      open={open} 
      onClose={handleClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: {
          borderRadius: 2,
        },
      }}
    >
      <DialogTitle>
        <Typography variant="h6" component="div">
          {mode === 'create' ? 'Create New User' : 'Edit User'}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {mode === 'create' 
            ? 'Add a new user to the system' 
            : `Edit details for ${user?.firstName} ${user?.lastName}`
          }
        </Typography>
      </DialogTitle>

      <form onSubmit={handleSubmit}>
        <DialogContent>
          <Grid container spacing={3}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="First Name"
                value={formData.firstName}
                onChange={(e) => handleInputChange('firstName', e.target.value)}
                error={!!errors.firstName}
                helperText={errors.firstName}
                disabled={loading}
                required
              />
            </Grid>
            
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Last Name"
                value={formData.lastName}
                onChange={(e) => handleInputChange('lastName', e.target.value)}
                error={!!errors.lastName}
                helperText={errors.lastName}
                disabled={loading}
                required
              />
            </Grid>

            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Email"
                type="email"
                value={formData.email}
                onChange={(e) => handleInputChange('email', e.target.value)}
                error={!!errors.email}
                helperText={errors.email}
                disabled={loading || emailChecking}
                required
                InputProps={{
                  endAdornment: emailChecking ? (
                    <CircularProgress size={20} />
                  ) : null,
                }}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Phone Number"
                value={formData.phoneNumber}
                onChange={(e) => handleInputChange('phoneNumber', e.target.value)}
                error={!!errors.phoneNumber}
                helperText={errors.phoneNumber || 'Optional'}
                disabled={loading}
                placeholder="+1234567890"
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Circle ID"
                value={formData.circleId}
                onChange={(e) => handleInputChange('circleId', e.target.value)}
                disabled={loading}
                helperText="Optional"
                placeholder="Enter circle ID"
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <FormControl fullWidth disabled={loading}>
                <InputLabel>Role</InputLabel>
                <Select
                  value={formData.role}
                  onChange={(e) => handleInputChange('role', e.target.value)}
                  label="Role"
                >
                  <MenuItem value="user">User</MenuItem>
                  <MenuItem value="moderator">Moderator</MenuItem>
                  <MenuItem value="admin">Admin</MenuItem>
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12} sm={6}>
              <Box sx={{ display: 'flex', alignItems: 'center', height: '100%' }}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={formData.isActive}
                      onChange={(e) => handleInputChange('isActive', e.target.checked)}
                      disabled={loading}
                    />
                  }
                  label="Active User"
                />
              </Box>
            </Grid>
          </Grid>

          {mode === 'edit' && (
            <Alert severity="info" sx={{ mt: 2 }}>
              <Typography variant="body2">
                <strong>Note:</strong> Changing user details will update their profile information.
                {user?.role === 'admin' && (
                  <>
                    <br />
                    <strong>Warning:</strong> This user has admin privileges. Be careful when modifying their role.
                  </>
                )}
              </Typography>
            </Alert>
          )}
        </DialogContent>

        <DialogActions sx={{ p: 3, pt: 0 }}>
          <Button 
            onClick={handleClose} 
            disabled={loading}
            variant="outlined"
          >
            Cancel
          </Button>
          <Button
            type="submit"
            variant="contained"
            disabled={loading || emailChecking}
            startIcon={loading ? <CircularProgress size={20} /> : null}
          >
            {loading ? 'Saving...' : mode === 'create' ? 'Create User' : 'Update User'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
}; 