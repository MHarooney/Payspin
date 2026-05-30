import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Paper,
  Grid,
  Button,
  Card,
  CardHeader,
  CardContent,
  CardActions,
  TextField,
  Switch,
  FormControlLabel,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  IconButton,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  Divider,
  Alert,
  Tab,
  Tabs,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  useTheme,
  useMediaQuery,
  Stack,
  Skeleton,
  Tooltip,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  DragIndicator as DragIcon,
  ExpandMore as ExpandMoreIcon,
  Category as CategoryIcon,
  Label as SubtypeIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as VisibilityOffIcon,
  Refresh as RefreshIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
} from '@mui/icons-material';
import { PostType, PostSubtype } from '../types/firestore';
import { firebaseService } from '../services/firebase';
import { seedPostTypes } from '../scripts/seedPostTypes';
import { GradientButton } from '../components/Common/GradientButton';
import { StatCard } from '../components/Common/StatCard';
import { LoadingSpinner } from '../components/Common/LoadingSpinner';
import toast from 'react-hot-toast';
import { PayspinColors } from '../theme/theme';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

interface PostTypeFormData {
  name: string;
  label: string;
  description: string;
  isActive: boolean;
  order: number;
}

interface PostSubtypeFormData {
  name: string;
  label: string;
  description: string;
  postTypeId: string;
  isActive: boolean;
  order: number;
}

const TabPanel = ({ children, value, index }: TabPanelProps) => {
  return (
    <Box
      role="tabpanel"
      sx={{
        display: value === index ? 'block' : 'none',
        width: '100%',
      }}
    >
      {children}
    </Box>
  );
};

export const PostTypeManager: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const isTablet = useMediaQuery(theme.breakpoints.between('md', 'lg'));
  
  const [loading, setLoading] = useState(false);
  const [tabValue, setTabValue] = useState(0);
  const [postTypes, setPostTypes] = useState<PostType[]>([]);
  const [postSubtypes, setPostSubtypes] = useState<PostSubtype[]>([]);
  
  // Dialog states
  const [typeDialogOpen, setTypeDialogOpen] = useState(false);
  const [subtypeDialogOpen, setSubtypeDialogOpen] = useState(false);
  const [editingType, setEditingType] = useState<PostType | null>(null);
  const [editingSubtype, setEditingSubtype] = useState<PostSubtype | null>(null);
  
  // Form states
  const [typeForm, setTypeForm] = useState<PostTypeFormData>({
    name: '',
    label: '',
    description: '',
    isActive: true,
    order: 1,
  });
  
  const [subtypeForm, setSubtypeForm] = useState<PostSubtypeFormData>({
    name: '',
    label: '',
    description: '',
    postTypeId: '',
    isActive: true,
    order: 1,
  });

  // Load data on component mount
  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [typesData, subtypesData] = await Promise.all([
        firebaseService.postTypes.getAll(),
        firebaseService.postSubtypes.getAll(),
      ]);
      setPostTypes(typesData.sort((a, b) => a.order - b.order));
      setPostSubtypes(subtypesData.sort((a, b) => a.order - b.order));
    } catch (error) {
      console.error('Error loading data:', error);
      toast.error('Failed to load post types and subtypes');
    } finally {
      setLoading(false);
    }
  };

  // Post Type Operations
  const handleCreateType = () => {
    setEditingType(null);
    setTypeForm({
      name: '',
      label: '',
      description: '',
      isActive: true,
      order: postTypes.length + 1,
    });
    setTypeDialogOpen(true);
  };

  const handleEditType = (type: PostType) => {
    setEditingType(type);
    setTypeForm({
      name: type.name,
      label: type.label,
      description: type.description || '',
      isActive: type.isActive,
      order: type.order,
    });
    setTypeDialogOpen(true);
  };

  const handleSaveType = async () => {
    try {
      if (!typeForm.name.trim() || !typeForm.label.trim()) {
        toast.error('Name and label are required');
        return;
      }

      const typeData = {
        name: typeForm.name.trim(),
        label: typeForm.label.trim(),
        description: typeForm.description.trim(),
        isActive: typeForm.isActive,
        order: typeForm.order,
      };

      if (editingType) {
        await firebaseService.postTypes.updatePostType(editingType.id, typeData);
        toast.success('Post type updated successfully');
      } else {
        await firebaseService.postTypes.createPostType(typeData);
        toast.success('Post type created successfully');
      }

      setTypeDialogOpen(false);
      loadData();
    } catch (error) {
      console.error('Error saving post type:', error);
      toast.error('Failed to save post type');
    }
  };

  const handleDeleteType = async (type: PostType) => {
    if (!window.confirm(`Are you sure you want to delete "${type.label}"? This will also delete all associated subtypes.`)) {
      return;
    }

    try {
      // Delete all associated subtypes first
      await firebaseService.postSubtypes.deleteByPostType(type.id);
      // Then delete the type
      await firebaseService.postTypes.delete(type.id);
      toast.success('Post type and associated subtypes deleted');
      loadData();
    } catch (error) {
      console.error('Error deleting post type:', error);
      toast.error('Failed to delete post type');
    }
  };

  const handleToggleTypeStatus = async (type: PostType) => {
    try {
      await firebaseService.postTypes.toggleActive(type.id, !type.isActive);
      toast.success(`Post type ${!type.isActive ? 'activated' : 'deactivated'}`);
      loadData();
    } catch (error) {
      console.error('Error toggling post type status:', error);
      toast.error('Failed to update post type status');
    }
  };

  // Post Subtype Operations
  const handleCreateSubtype = (postTypeId?: string) => {
    setEditingSubtype(null);
    setSubtypeForm({
      name: '',
      label: '',
      description: '',
      postTypeId: postTypeId || '',
      isActive: true,
      order: getSubtypesByType(postTypeId || '').length + 1,
    });
    setSubtypeDialogOpen(true);
  };

  const handleEditSubtype = (subtype: PostSubtype) => {
    setEditingSubtype(subtype);
    setSubtypeForm({
      name: subtype.name,
      label: subtype.label,
      description: subtype.description || '',
      postTypeId: subtype.postTypeId,
      isActive: subtype.isActive,
      order: subtype.order,
    });
    setSubtypeDialogOpen(true);
  };

  const handleSaveSubtype = async () => {
    try {
      if (!subtypeForm.name.trim() || !subtypeForm.label.trim() || !subtypeForm.postTypeId) {
        toast.error('Name, label, and post type are required');
        return;
      }

      const subtypeData = {
        name: subtypeForm.name.trim(),
        label: subtypeForm.label.trim(),
        description: subtypeForm.description.trim(),
        postTypeId: subtypeForm.postTypeId,
        isActive: subtypeForm.isActive,
        order: subtypeForm.order,
      };

      if (editingSubtype) {
        await firebaseService.postSubtypes.updateSubtype(editingSubtype.id, subtypeData);
        toast.success('Post subtype updated successfully');
      } else {
        await firebaseService.postSubtypes.createSubtype(subtypeData);
        toast.success('Post subtype created successfully');
      }

      setSubtypeDialogOpen(false);
      loadData();
    } catch (error) {
      console.error('Error saving post subtype:', error);
      toast.error('Failed to save post subtype');
    }
  };

  const handleDeleteSubtype = async (subtype: PostSubtype) => {
    if (!window.confirm(`Are you sure you want to delete "${subtype.label}"?`)) {
      return;
    }

    try {
      await firebaseService.postSubtypes.delete(subtype.id);
      toast.success('Post subtype deleted');
      loadData();
    } catch (error) {
      console.error('Error deleting post subtype:', error);
      toast.error('Failed to delete post subtype');
    }
  };

  const handleToggleSubtypeStatus = async (subtype: PostSubtype) => {
    try {
      await firebaseService.postSubtypes.toggleActive(subtype.id, !subtype.isActive);
      toast.success(`Post subtype ${!subtype.isActive ? 'activated' : 'deactivated'}`);
      loadData();
    } catch (error) {
      console.error('Error toggling post subtype status:', error);
      toast.error('Failed to update post subtype status');
    }
  };

  // Helper functions
  const getSubtypesByType = (postTypeId: string): PostSubtype[] => {
    return postSubtypes.filter(subtype => subtype.postTypeId === postTypeId);
  };

  // Loading state
  if (loading && postTypes.length === 0) {
    return (
      <Container maxWidth="xl" sx={{ py: 3 }}>
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '50vh' }}>
          <LoadingSpinner variant="default" size="large" />
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="xl" sx={{ p: { xs: 2, sm: 3, md: 4 } }}>
      {/* Header Section */}
      <Box sx={{ mb: 4 }}>
        <Grid container spacing={3} alignItems="flex-start">
          <Grid item xs={12} lg={8}>
            <Typography 
              variant="h4" 
              component="h1"
              sx={{ 
                mb: 1,
                fontWeight: 700,
                fontSize: { xs: '1.5rem', sm: '1.75rem', md: '2rem', lg: '2.25rem' },
                color: 'text.primary',
              }}
            >
              Post Type Management
            </Typography>
            <Typography 
              variant="body1" 
              color="text.secondary"
              sx={{ 
                fontSize: { xs: '1rem', sm: '1.1rem' },
                lineHeight: 1.6,
                mb: 2,
              }}
            >
              Manage post types and their subtypes for enhanced content categorization
            </Typography>
          </Grid>
          <Grid item xs={12} lg={4}>
            <Stack 
              direction={{ xs: 'column', sm: 'row', lg: 'row' }} 
              spacing={2}
              sx={{ 
                justifyContent: { xs: 'stretch', lg: 'flex-end' },
                alignItems: { xs: 'stretch', sm: 'center' },
                width: '100%',
                flexWrap: 'wrap',
                gap: 2,
              }}
            >
              <Tooltip title="Refresh data">
                <span>
                  <IconButton 
                    onClick={loadData}
                    disabled={loading}
                    sx={{ 
                      minWidth: { xs: 44, sm: 48 },
                      minHeight: { xs: 44, sm: 48 },
                      bgcolor: 'background.paper',
                      border: '1px solid',
                      borderColor: 'divider',
                      color: 'text.primary',
                      transition: 'all 0.2s ease',
                      '&:hover': {
                        bgcolor: 'action.hover',
                        transform: 'scale(1.05)',
                        boxShadow: '0px 4px 12px rgba(0, 0, 0, 0.1)',
                      },
                      '&:disabled': {
                        opacity: 0.5,
                        transform: 'none',
                      },
                    }}
                  >
                    <RefreshIcon />
                  </IconButton>
                </span>
              </Tooltip>
              <Button
                variant="outlined"
                startIcon={<SubtypeIcon />}
                onClick={() => handleCreateSubtype()}
                sx={{ 
                  borderRadius: 3,
                  fontSize: { xs: '0.875rem', sm: '1rem' },
                  fontWeight: 600,
                  minHeight: { xs: 44, sm: 48 },
                  minWidth: { xs: 'auto', sm: 140, md: 160 },
                  px: { xs: 3, sm: 4, md: 5 },
                  py: { xs: 1, sm: 1.5 },
                  borderWidth: 2,
                  borderColor: PayspinColors.primary,
                  color: PayspinColors.primary,
                  bgcolor: 'background.paper',
                  whiteSpace: 'nowrap',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                  '&:hover': {
                    borderColor: PayspinColors.primary,
                    bgcolor: `${PayspinColors.primary}08`,
                    transform: 'translateY(-2px)',
                    boxShadow: `0px 8px 24px ${PayspinColors.primary}25`,
                  },
                  '& .MuiButton-startIcon': {
                    transition: 'all 0.3s ease',
                    mr: { xs: 1, sm: 1.5 },
                  },
                  '&:hover .MuiButton-startIcon': {
                    transform: 'scale(1.1) rotate(5deg)',
                  },
                }}
              >
                {isMobile ? 'Add Subtype' : 'Add Subtype'}
              </Button>
              <GradientButton
                onClick={handleCreateType}
                text={isMobile ? 'Add Type' : 'Add Post Type'}
                startIcon={<CategoryIcon />}
                size="large"
                variant="primary"
                sx={{
                  minHeight: { xs: 44, sm: 48 },
                  minWidth: { xs: 'auto', sm: 160, md: 180 },
                  px: { xs: 3, sm: 4, md: 5 },
                  py: { xs: 1, sm: 1.5 },
                  fontSize: { xs: '0.875rem', sm: '1rem' },
                  fontWeight: 700,
                  letterSpacing: '0.5px',
                  textTransform: 'none',
                  borderRadius: 3,
                  whiteSpace: 'nowrap',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  boxShadow: '0px 8px 32px rgba(252, 0, 255, 0.3)',
                  transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                  '&:hover': {
                    transform: 'translateY(-2px) scale(1.02)',
                    boxShadow: '0px 12px 40px rgba(252, 0, 255, 0.4)',
                  },
                  '& .MuiButton-startIcon': {
                    transition: 'all 0.3s ease',
                    mr: { xs: 1, sm: 1.5 },
                  },
                  '&:hover .MuiButton-startIcon': {
                    transform: 'scale(1.1) rotate(90deg)',
                  },
                  '& .MuiButton-label': {
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    width: '100%',
                  },
                }}
              />
            </Stack>
          </Grid>
        </Grid>
      </Box>

      {/* Statistics Section */}
      {!loading && postTypes.length > 0 && (
        <Box sx={{ mb: 4 }}>
          <Grid container spacing={3}>
            <Grid item xs={12} sm={6} md={3}>
              <StatCard
                title="Total Post Types"
                value={postTypes.length}
                icon={<CategoryIcon />}
                color="primary"
              />
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <StatCard
                title="Active Types"
                value={postTypes.filter(t => t.isActive).length}
                icon={<CheckCircleIcon />}
                color="success"
              />
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <StatCard
                title="Total Subtypes"
                value={postSubtypes.length}
                icon={<SubtypeIcon />}
                color="info"
              />
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <StatCard
                title="Active Subtypes"
                value={postSubtypes.filter(s => s.isActive).length}
                icon={<CheckCircleIcon />}
                color="success"
              />
            </Grid>
          </Grid>
        </Box>
      )}

      {/* Loading States */}
      {loading && (
        <Box sx={{ mb: 3, textAlign: 'center' }}>
          <LoadingSpinner variant="default" size="medium" />
          <Typography 
            variant="body2" 
            sx={{ 
              mt: 2,
              color: 'text.secondary',
            }}
          >
            Loading post types and subtypes...
          </Typography>
        </Box>
      )}

      {/* Info Alert */}
      <Alert 
        severity="info" 
        sx={{ 
          mb: 3,
          borderRadius: 3,
          border: '1px solid',
          borderColor: 'info.light',
          bgcolor: 'info.50',
          '& .MuiAlert-message': {
            width: '100%',
          },
        }}
      >
        <Typography 
          variant="body2"
          sx={{ 
            fontSize: { xs: '0.875rem', sm: '1rem' },
            lineHeight: 1.6,
            color: 'info.dark',
          }}
        >
          Manage post types and their subtypes. Post types define the main categories (News, Offers, Blogs), 
          while subtypes provide more specific classifications within each type.
          {postTypes.length === 0 && (
            <>
              <br /><br />
              <strong>No post types found!</strong> Click the "Seed Default Types" button below to initialize with default post types and subtypes.
            </>
          )}
        </Typography>
      </Alert>

      {/* Seed Default Types Button */}
      {postTypes.length === 0 && (
        <Box sx={{ 
          mb: 4, 
          textAlign: 'center',
          p: 4,
          bgcolor: 'background.paper',
          borderRadius: 3,
          border: '1px solid',
          borderColor: 'divider',
          boxShadow: theme.shadows[1],
        }}>
          <Typography 
            variant="h6" 
            sx={{ 
              mb: 2,
              fontWeight: 600,
              color: 'text.primary',
            }}
          >
            Get Started with Default Types
          </Typography>
          <Typography 
            variant="body2" 
            color="text.secondary"
            sx={{ 
              mb: 3,
              maxWidth: 600,
              mx: 'auto',
            }}
          >
            Initialize your post management system with pre-configured post types and subtypes 
            that cover common content categories like News, Offers, Blogs, and Announcements.
          </Typography>
          <GradientButton
            onClick={async () => {
              try {
                setLoading(true);
                await seedPostTypes();
                toast.success('Default post types and subtypes created successfully!');
                loadData();
              } catch (error) {
                console.error('Error seeding post types:', error);
                toast.error('Failed to create default post types');
              } finally {
                setLoading(false);
              }
            }}
            text="Seed Default Types & Subtypes"
            startIcon={<CategoryIcon />}
            size="large"
            variant="primary"
            loading={loading}
            sx={{
              minHeight: 48,
              minWidth: { xs: 'auto', sm: 280, md: 320 },
              px: { xs: 4, sm: 5, md: 6 },
              py: 1.5,
              fontSize: { xs: '0.875rem', sm: '1rem' },
              fontWeight: 700,
              letterSpacing: '0.5px',
              textTransform: 'none',
              borderRadius: 3,
              whiteSpace: 'nowrap',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              boxShadow: '0px 8px 32px rgba(252, 0, 255, 0.3)',
              transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
              '&:hover': {
                transform: 'translateY(-2px) scale(1.02)',
                boxShadow: '0px 12px 40px rgba(252, 0, 255, 0.4)',
              },
              '& .MuiButton-startIcon': {
                transition: 'all 0.3s ease',
                mr: { xs: 1.5, sm: 2 },
              },
              '&:hover .MuiButton-startIcon': {
                transform: 'scale(1.1) rotate(90deg)',
              },
            }}
          />
        </Box>
      )}

      {/* Main Content */}
      <Paper 
        elevation={0}
        sx={{ 
          borderRadius: 3,
          overflow: 'hidden',
          border: '1px solid',
          borderColor: 'divider',
          bgcolor: 'background.paper',
        }}
      >
        {/* Responsive Tabs */}
        <Box sx={{ 
          borderBottom: '1px solid',
          borderColor: 'divider',
          bgcolor: 'background.default',
        }}>
          <Tabs 
            value={tabValue} 
            onChange={(e, newValue) => setTabValue(newValue)}
            variant={isMobile ? "scrollable" : "standard"}
            scrollButtons={isMobile ? "auto" : false}
            sx={{
              '& .MuiTab-root': {
                fontSize: { xs: '0.875rem', sm: '1rem' },
                minHeight: { xs: 48, sm: 56 },
                px: { xs: 2, sm: 3 },
                fontWeight: 600,
                textTransform: 'none',
                color: 'text.secondary',
                '&.Mui-selected': {
                  color: PayspinColors.primary,
                  fontWeight: 700,
                },
              },
              '& .MuiTabs-indicator': {
                backgroundColor: PayspinColors.primary,
                height: 3,
              },
            }}
          >
            <Tab label="Post Types" />
            <Tab label="Manage Subtypes" />
            <Tab label="Overview" />
          </Tabs>
        </Box>

        {/* Post Types Tab */}
        <TabPanel value={tabValue} index={0}>
          <Box sx={{ p: { xs: 2, sm: 3 } }}>
            {loading ? (
              <Grid container spacing={3}>
                {Array.from({ length: 6 }).map((_, index) => (
                  <Grid item xs={12} sm={6} md={4} key={index}>
                    <Card sx={{ borderRadius: 2 }}>
                      <CardContent>
                        <Skeleton variant="text" width="60%" height={32} sx={{ mb: 1 }} />
                        <Skeleton variant="text" width="40%" height={24} sx={{ mb: 2 }} />
                        <Skeleton variant="text" width="100%" height={16} sx={{ mb: 1 }} />
                        <Skeleton variant="text" width="80%" height={16} sx={{ mb: 2 }} />
                        <Skeleton variant="rectangular" width="100%" height={40} sx={{ borderRadius: 1 }} />
                      </CardContent>
                    </Card>
                  </Grid>
                ))}
              </Grid>
            ) : postTypes.length === 0 ? (
              <Box sx={{ 
                p: 6, 
                textAlign: 'center',
                bgcolor: 'background.default',
                borderRadius: 2,
                m: 2,
              }}>
                <CategoryIcon 
                  sx={{ 
                    fontSize: 64, 
                    color: 'text.disabled',
                    mb: 2,
                  }} 
                />
                <Typography 
                  variant="h6" 
                  color="text.secondary" 
                  sx={{ 
                    mb: 1,
                    fontWeight: 600,
                  }}
                >
                  No post types found
                </Typography>
                <Typography 
                  variant="body2" 
                  color="text.secondary" 
                  sx={{ 
                    mb: 3,
                    maxWidth: 400,
                    mx: 'auto',
                  }}
                >
                  Create your first post type to get started with content categorization
                </Typography>
                <GradientButton
                  onClick={handleCreateType}
                  text="Create Post Type"
                  startIcon={<CategoryIcon />}
                  size="large"
                  variant="primary"
                  sx={{
                    minHeight: 48,
                    minWidth: { xs: 'auto', sm: 180, md: 200 },
                    px: { xs: 4, sm: 5 },
                    py: 1.5,
                    fontSize: { xs: '0.875rem', sm: '1rem' },
                    fontWeight: 700,
                    letterSpacing: '0.5px',
                    textTransform: 'none',
                    borderRadius: 3,
                    whiteSpace: 'nowrap',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    boxShadow: '0px 8px 32px rgba(252, 0, 255, 0.3)',
                    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                    '&:hover': {
                      transform: 'translateY(-2px) scale(1.02)',
                      boxShadow: '0px 12px 40px rgba(252, 0, 255, 0.4)',
                    },
                    '& .MuiButton-startIcon': {
                      transition: 'all 0.3s ease',
                      mr: { xs: 1.5, sm: 2 },
                    },
                    '&:hover .MuiButton-startIcon': {
                      transform: 'scale(1.1) rotate(90deg)',
                    },
                  }}
                />
              </Box>
            ) : (
              <Grid container spacing={{ xs: 2, sm: 3 }}>
                {postTypes.map((type) => (
                  <Grid item xs={12} sm={6} md={4} key={type.id}>
                    <Card 
                      sx={{ 
                        borderRadius: 2,
                        boxShadow: theme.shadows[1],
                        transition: 'all 0.3s ease-in-out',
                        '&:hover': {
                          transform: 'translateY(-2px)',
                          boxShadow: theme.shadows[4],
                        },
                      }}
                    >
                      <CardHeader
                        title={
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
                            <Typography 
                              variant="h6" 
                              sx={{ 
                                fontSize: { xs: '1rem', sm: '1.125rem' },
                                fontWeight: 600,
                              }}
                            >
                              {type.label}
                            </Typography>
                            <Chip
                              size="small"
                              label={type.isActive ? 'Active' : 'Inactive'}
                              color={type.isActive ? 'success' : 'default'}
                              sx={{ 
                                fontSize: { xs: '0.75rem', sm: '0.875rem' },
                                height: { xs: 20, sm: 24 },
                              }}
                            />
                          </Box>
                        }
                        subheader={
                          <Typography 
                            variant="body2" 
                            sx={{ 
                              fontSize: { xs: '0.75rem', sm: '0.875rem' },
                              fontFamily: 'monospace',
                            }}
                          >
                            ID: {type.name}
                          </Typography>
                        }
                        sx={{
                          '& .MuiCardHeader-content': {
                            minWidth: 0,
                          },
                        }}
                      />
                      <CardContent sx={{ pt: 0 }}>
                        <Typography 
                          variant="body2" 
                          color="text.secondary"
                          sx={{ 
                            mb: 2,
                            fontSize: { xs: '0.875rem', sm: '1rem' },
                            lineHeight: 1.5,
                          }}
                        >
                          {type.description || 'No description'}
                        </Typography>
                        <Typography 
                          variant="caption" 
                          display="block" 
                          sx={{ 
                            color: 'text.secondary',
                            fontSize: { xs: '0.75rem', sm: '0.875rem' },
                          }}
                        >
                          Order: {type.order} | Subtypes: {getSubtypesByType(type.id).length}
                        </Typography>
                      </CardContent>
                      <CardActions sx={{ p: 2, pt: 0 }}>
                        <Stack 
                          direction="row" 
                          spacing={0.5}
                          sx={{ width: '100%', justifyContent: 'space-between' }}
                        >
                          <Box sx={{ display: 'flex', gap: 0.5 }}>
                            <Tooltip title="Edit">
                              <IconButton
                                size="small"
                                onClick={() => handleEditType(type)}
                                color="primary"
                                sx={{ minWidth: 32, minHeight: 32 }}
                              >
                                <EditIcon fontSize="small" />
                              </IconButton>
                            </Tooltip>
                            <Tooltip title={type.isActive ? 'Deactivate' : 'Activate'}>
                              <IconButton
                                size="small"
                                onClick={() => handleToggleTypeStatus(type)}
                                color={type.isActive ? 'warning' : 'success'}
                                sx={{ minWidth: 32, minHeight: 32 }}
                              >
                                {type.isActive ? <VisibilityOffIcon fontSize="small" /> : <VisibilityIcon fontSize="small" />}
                              </IconButton>
                            </Tooltip>
                          </Box>
                          <Box sx={{ display: 'flex', gap: 0.5 }}>
                            <Tooltip title="Add Subtype">
                              <IconButton
                                size="small"
                                onClick={() => handleCreateSubtype(type.id)}
                                color="info"
                                sx={{ minWidth: 32, minHeight: 32 }}
                              >
                                <AddIcon fontSize="small" />
                              </IconButton>
                            </Tooltip>
                            <Tooltip title="Delete">
                              <IconButton
                                size="small"
                                onClick={() => handleDeleteType(type)}
                                color="error"
                                sx={{ minWidth: 32, minHeight: 32 }}
                              >
                                <DeleteIcon fontSize="small" />
                              </IconButton>
                            </Tooltip>
                          </Box>
                        </Stack>
                      </CardActions>
                    </Card>
                  </Grid>
                ))}
              </Grid>
            )}
          </Box>
        </TabPanel>

        {/* Manage Subtypes Tab */}
        <TabPanel value={tabValue} index={1}>
          <Box sx={{ p: { xs: 1, sm: 2, md: 3 } }}>
            {loading ? (
              <Stack spacing={{ xs: 1.5, sm: 2 }}>
                {Array.from({ length: 3 }).map((_, index) => (
                  <Accordion key={index} sx={{ borderRadius: 2 }}>
                    <AccordionSummary>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, width: '100%' }}>
                        <Skeleton variant="circular" width={24} height={24} />
                        <Skeleton variant="text" width="30%" height={24} />
                        <Skeleton variant="rectangular" width={80} height={24} sx={{ borderRadius: 1 }} />
                        <Box sx={{ ml: 'auto' }}>
                          <Skeleton variant="rectangular" width={100} height={32} sx={{ borderRadius: 2 }} />
                        </Box>
                      </Box>
                    </AccordionSummary>
                    <AccordionDetails>
                      <Grid container spacing={{ xs: 1, sm: 2 }}>
                        {Array.from({ length: 2 }).map((_, subIndex) => (
                          <Grid item xs={12} sm={6} key={subIndex}>
                            <Card sx={{ borderRadius: 2 }}>
                              <CardContent>
                                <Skeleton variant="text" width="60%" height={20} sx={{ mb: 1 }} />
                                <Skeleton variant="text" width="40%" height={16} sx={{ mb: 1 }} />
                                <Skeleton variant="text" width="100%" height={16} sx={{ mb: 2 }} />
                                <Skeleton variant="rectangular" width="100%" height={32} sx={{ borderRadius: 1 }} />
                              </CardContent>
                            </Card>
                          </Grid>
                        ))}
                      </Grid>
                    </AccordionDetails>
                  </Accordion>
                ))}
              </Stack>
            ) : postTypes.length === 0 ? (
              <Box sx={{ p: { xs: 3, sm: 4 }, textAlign: 'center' }}>
                <Typography 
                  variant="h6" 
                  color="text.secondary" 
                  sx={{ 
                    mb: 1,
                    fontSize: { xs: '1.125rem', sm: '1.25rem' },
                  }}
                >
                  No post types available
                </Typography>
                <Typography 
                  variant="body2" 
                  color="text.secondary" 
                  sx={{ 
                    mb: 3,
                    fontSize: { xs: '0.875rem', sm: '1rem' },
                  }}
                >
                  Create post types first to manage their subtypes
                </Typography>
                <GradientButton
                  onClick={handleCreateType}
                  text="Create Post Type"
                  startIcon={<CategoryIcon />}
                  size="medium"
                  variant="primary"
                />
              </Box>
            ) : (
              <Stack spacing={{ xs: 1.5, sm: 2, md: 3 }}>
                {postTypes.map((type) => (
                  <Accordion 
                    key={type.id}
                    sx={{ 
                      borderRadius: 2,
                      '&:before': { display: 'none' },
                      boxShadow: theme.shadows[1],
                      '& .MuiAccordionSummary-root': {
                        minHeight: { xs: 56, sm: 64 },
                        px: { xs: 1.5, sm: 2 },
                      },
                    }}
                  >
                    <AccordionSummary
                      expandIcon={<ExpandMoreIcon />}
                      aria-controls={`${type.id}-content`}
                      id={`${type.id}-header`}
                      sx={{
                        '& .MuiAccordionSummary-content': {
                          margin: 0,
                        },
                      }}
                    >
                      <Box sx={{ 
                        display: 'flex', 
                        alignItems: 'center', 
                        gap: { xs: 1, sm: 1.5, md: 2 }, 
                        width: '100%',
                        flexWrap: { xs: 'wrap', sm: 'nowrap' },
                      }}>
                        <CategoryIcon 
                          color="primary" 
                          sx={{ 
                            fontSize: { xs: 20, sm: 22, md: 24 },
                            minWidth: { xs: 20, sm: 22, md: 24 },
                          }} 
                        />
                        <Typography 
                          variant="h6" 
                          sx={{ 
                            fontSize: { xs: '0.875rem', sm: '1rem', md: '1.125rem' },
                            fontWeight: 600,
                            minWidth: 0,
                            flex: 1,
                          }}
                        >
                          {type.label}
                        </Typography>
                        <Chip
                          size="small"
                          label={`${getSubtypesByType(type.id).length} subtypes`}
                          color="info"
                          sx={{ 
                            fontSize: { xs: '0.625rem', sm: '0.75rem', md: '0.875rem' },
                            height: { xs: 18, sm: 20, md: 24 },
                            minWidth: { xs: 50, sm: 60, md: 80 },
                          }}
                        />
                        <Box sx={{ 
                          ml: { xs: 0, sm: 'auto' },
                          mt: { xs: 1, sm: 0 },
                          width: { xs: '100%', sm: 'auto' },
                        }}>
                          <Button
                            size="small"
                            startIcon={<AddIcon />}
                            onClick={(e) => {
                              e.stopPropagation();
                              handleCreateSubtype(type.id);
                            }}
                            sx={{ 
                              borderRadius: 2,
                              fontSize: { xs: '0.75rem', sm: '0.875rem' },
                              width: { xs: '100%', sm: 'auto' },
                              minHeight: { xs: 36, sm: 32 },
                              px: { xs: 2, sm: 1.5 },
                            }}
                          >
                            {isMobile ? 'Add Subtype' : 'Add Subtype'}
                          </Button>
                        </Box>
                      </Box>
                    </AccordionSummary>
                    <AccordionDetails sx={{ p: { xs: 1.5, sm: 2, md: 3 } }}>
                      {getSubtypesByType(type.id).length === 0 ? (
                        <Box sx={{ 
                          p: { xs: 2, sm: 3 }, 
                          textAlign: 'center',
                          borderRadius: 2,
                          bgcolor: 'action.hover',
                        }}>
                          <Typography 
                            sx={{ 
                              fontSize: { xs: '0.875rem', sm: '1rem' },
                              color: 'text.secondary',
                              mb: 1,
                            }}
                          >
                            No subtypes found
                          </Typography>
                          <Typography 
                            variant="body2" 
                            sx={{ 
                              fontSize: { xs: '0.75rem', sm: '0.875rem' },
                              color: 'text.secondary',
                              mb: 2,
                            }}
                          >
                            Click 'Add Subtype' to create the first subtype for this post type
                          </Typography>
                          <Button
                            size="small"
                            startIcon={<AddIcon />}
                            onClick={() => handleCreateSubtype(type.id)}
                            sx={{ 
                              borderRadius: 2,
                              fontSize: { xs: '0.75rem', sm: '0.875rem' },
                            }}
                          >
                            Add First Subtype
                          </Button>
                        </Box>
                      ) : (
                        <Grid container spacing={{ xs: 1, sm: 1.5, md: 2 }}>
                          {getSubtypesByType(type.id).map((subtype) => (
                            <Grid item xs={12} sm={6} md={4} key={subtype.id}>
                              <Card 
                                sx={{ 
                                  borderRadius: 2,
                                  boxShadow: theme.shadows[1],
                                  transition: 'all 0.3s ease-in-out',
                                  '&:hover': {
                                    transform: 'translateY(-2px)',
                                    boxShadow: theme.shadows[4],
                                  },
                                }}
                              >
                                <CardHeader
                                  title={
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
                                      <Typography 
                                        variant="h6" 
                                        sx={{ 
                                          fontSize: { xs: '0.875rem', sm: '1rem' },
                                          fontWeight: 600,
                                        }}
                                      >
                                        {subtype.label}
                                      </Typography>
                                      <Chip
                                        size="small"
                                        label={subtype.isActive ? 'Active' : 'Inactive'}
                                        color={subtype.isActive ? 'success' : 'default'}
                                        sx={{ 
                                          fontSize: { xs: '0.625rem', sm: '0.75rem' },
                                          height: { xs: 18, sm: 20 },
                                        }}
                                      />
                                    </Box>
                                  }
                                  subheader={
                                    <Typography 
                                      variant="body2" 
                                      sx={{ 
                                        fontSize: { xs: '0.75rem', sm: '0.875rem' },
                                        fontFamily: 'monospace',
                                      }}
                                    >
                                      ID: {subtype.name}
                                    </Typography>
                                  }
                                  sx={{
                                    '& .MuiCardHeader-content': {
                                      minWidth: 0,
                                    },
                                    p: { xs: 1.5, sm: 2 },
                                  }}
                                />
                                <CardContent sx={{ pt: 0, px: { xs: 1.5, sm: 2 } }}>
                                  <Typography 
                                    variant="body2" 
                                    color="text.secondary"
                                    sx={{ 
                                      mb: 2,
                                      fontSize: { xs: '0.75rem', sm: '0.875rem' },
                                      lineHeight: 1.5,
                                    }}
                                  >
                                    {subtype.description || 'No description'}
                                  </Typography>
                                  <Typography 
                                    variant="caption" 
                                    display="block" 
                                    sx={{ 
                                      color: 'text.secondary',
                                      fontSize: { xs: '0.625rem', sm: '0.75rem' },
                                    }}
                                  >
                                    Order: {subtype.order}
                                  </Typography>
                                </CardContent>
                                <CardActions sx={{ p: { xs: 1.5, sm: 2 }, pt: 0 }}>
                                  <Stack 
                                    direction="row" 
                                    spacing={0.5}
                                    sx={{ width: '100%', justifyContent: 'space-between' }}
                                  >
                                    <Box sx={{ display: 'flex', gap: 0.5 }}>
                                      <Tooltip title="Edit">
                                        <IconButton
                                          size="small"
                                          onClick={() => handleEditSubtype(subtype)}
                                          color="primary"
                                          sx={{ minWidth: 32, minHeight: 32 }}
                                        >
                                          <EditIcon fontSize="small" />
                                        </IconButton>
                                      </Tooltip>
                                      <Tooltip title={subtype.isActive ? 'Deactivate' : 'Activate'}>
                                        <IconButton
                                          size="small"
                                          onClick={() => handleToggleSubtypeStatus(subtype)}
                                          color={subtype.isActive ? 'warning' : 'success'}
                                          sx={{ minWidth: 32, minHeight: 32 }}
                                        >
                                          {subtype.isActive ? <VisibilityOffIcon fontSize="small" /> : <VisibilityIcon fontSize="small" />}
                                        </IconButton>
                                      </Tooltip>
                                    </Box>
                                    <Box sx={{ display: 'flex', gap: 0.5 }}>
                                      <Tooltip title="Delete">
                                        <IconButton
                                          size="small"
                                          onClick={() => handleDeleteSubtype(subtype)}
                                          color="error"
                                          sx={{ minWidth: 32, minHeight: 32 }}
                                        >
                                          <DeleteIcon fontSize="small" />
                                        </IconButton>
                                      </Tooltip>
                                    </Box>
                                  </Stack>
                                </CardActions>
                              </Card>
                            </Grid>
                          ))}
                        </Grid>
                      )}
                    </AccordionDetails>
                  </Accordion>
                ))}
              </Stack>
            )}
          </Box>
        </TabPanel>

        {/* Overview Tab */}
        <TabPanel value={tabValue} index={2}>
          <Box sx={{ p: { xs: 2, sm: 3 } }}>
            <Grid container spacing={{ xs: 2, sm: 3 }}>
              <Grid item xs={12} sm={6}>
                <Card sx={{ borderRadius: 2, boxShadow: theme.shadows[1] }}>
                  <CardHeader 
                    title={
                      <Typography 
                        variant="h6" 
                        sx={{ 
                          fontSize: { xs: '1rem', sm: '1.125rem' },
                          fontWeight: 600,
                        }}
                      >
                        Post Types Summary
                      </Typography>
                    }
                  />
                  <CardContent>
                    <Typography 
                      variant="h4" 
                      color="primary"
                      sx={{ 
                        fontSize: { xs: '2rem', sm: '2.5rem' },
                        fontWeight: 700,
                        mb: 1,
                      }}
                    >
                      {postTypes.length}
                    </Typography>
                    <Typography 
                      variant="body2" 
                      color="text.secondary"
                      sx={{ 
                        fontSize: { xs: '0.875rem', sm: '1rem' },
                        mb: 2,
                      }}
                    >
                      Total Post Types
                    </Typography>
                    <Typography 
                      variant="body2" 
                      sx={{ 
                        fontSize: { xs: '0.875rem', sm: '1rem' },
                        color: 'text.secondary',
                      }}
                    >
                      Active: {postTypes.filter(t => t.isActive).length} | 
                      Inactive: {postTypes.filter(t => !t.isActive).length}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Card sx={{ borderRadius: 2, boxShadow: theme.shadows[1] }}>
                  <CardHeader 
                    title={
                      <Typography 
                        variant="h6" 
                        sx={{ 
                          fontSize: { xs: '1rem', sm: '1.125rem' },
                          fontWeight: 600,
                        }}
                      >
                        Subtypes Summary
                      </Typography>
                    }
                  />
                  <CardContent>
                    <Typography 
                      variant="h4" 
                      color="secondary"
                      sx={{ 
                        fontSize: { xs: '2rem', sm: '2.5rem' },
                        fontWeight: 700,
                        mb: 1,
                      }}
                    >
                      {postSubtypes.length}
                    </Typography>
                    <Typography 
                      variant="body2" 
                      color="text.secondary"
                      sx={{ 
                        fontSize: { xs: '0.875rem', sm: '1rem' },
                        mb: 2,
                      }}
                    >
                      Total Subtypes
                    </Typography>
                    <Typography 
                      variant="body2" 
                      sx={{ 
                        fontSize: { xs: '0.875rem', sm: '1rem' },
                        color: 'text.secondary',
                      }}
                    >
                      Active: {postSubtypes.filter(s => s.isActive).length} | 
                      Inactive: {postSubtypes.filter(s => !s.isActive).length}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            </Grid>
          </Box>
        </TabPanel>
      </Paper>

      {/* Post Type Dialog */}
      <Dialog
        open={typeDialogOpen}
        onClose={() => setTypeDialogOpen(false)}
        maxWidth="sm"
        fullWidth
        PaperProps={{
          sx: { borderRadius: 2 },
        }}
      >
        <DialogTitle sx={{ pb: 1 }}>
          <Typography 
            variant="h6" 
            sx={{ 
              fontSize: { xs: '1.125rem', sm: '1.25rem' },
              fontWeight: 600,
            }}
          >
            {editingType ? 'Edit Post Type' : 'Create Post Type'}
          </Typography>
        </DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <Stack spacing={2}>
            <TextField
              fullWidth
              label="Name (ID)"
              value={typeForm.name}
              onChange={(e) => setTypeForm({ ...typeForm, name: e.target.value })}
              helperText="Unique identifier (e.g., 'news', 'offer', 'blog')"
              sx={{ '& .MuiInputBase-root': { borderRadius: 2 } }}
            />
            <TextField
              fullWidth
              label="Display Label"
              value={typeForm.label}
              onChange={(e) => setTypeForm({ ...typeForm, label: e.target.value })}
              helperText="User-friendly name (e.g., 'News', 'Offers', 'Blogs')"
              sx={{ '& .MuiInputBase-root': { borderRadius: 2 } }}
            />
            <TextField
              fullWidth
              label="Description"
              value={typeForm.description}
              onChange={(e) => setTypeForm({ ...typeForm, description: e.target.value })}
              multiline
              rows={3}
              helperText="Optional description for this post type"
              sx={{ '& .MuiInputBase-root': { borderRadius: 2 } }}
            />
            <TextField
              fullWidth
              label="Display Order"
              type="number"
              value={typeForm.order}
              onChange={(e) => setTypeForm({ ...typeForm, order: parseInt(e.target.value) })}
              helperText="Order for displaying in lists"
              sx={{ '& .MuiInputBase-root': { borderRadius: 2 } }}
            />
            <FormControlLabel
              control={
                <Switch
                  checked={typeForm.isActive}
                  onChange={(e) => setTypeForm({ ...typeForm, isActive: e.target.checked })}
                />
              }
              label="Active"
            />
          </Stack>
        </DialogContent>
        <DialogActions sx={{ p: 3, pt: 1 }}>
          <Button 
            onClick={() => setTypeDialogOpen(false)}
            sx={{ borderRadius: 2 }}
          >
            Cancel
          </Button>
          <GradientButton
            onClick={handleSaveType}
            text={editingType ? 'Update' : 'Create'}
            size="medium"
            variant="primary"
          />
        </DialogActions>
      </Dialog>

      {/* Post Subtype Dialog */}
      <Dialog
        open={subtypeDialogOpen}
        onClose={() => setSubtypeDialogOpen(false)}
        maxWidth="sm"
        fullWidth
        PaperProps={{
          sx: { borderRadius: 2 },
        }}
      >
        <DialogTitle sx={{ pb: 1 }}>
          <Typography 
            variant="h6" 
            sx={{ 
              fontSize: { xs: '1.125rem', sm: '1.25rem' },
              fontWeight: 600,
            }}
          >
            {editingSubtype ? 'Edit Post Subtype' : 'Create Post Subtype'}
          </Typography>
        </DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <Stack spacing={2}>
            <TextField
              fullWidth
              label="Post Type"
              select
              value={subtypeForm.postTypeId}
              onChange={(e) => setSubtypeForm({ ...subtypeForm, postTypeId: e.target.value })}
              SelectProps={{ native: true }}
              sx={{ '& .MuiInputBase-root': { borderRadius: 2 } }}
            >
              <option value="">Select Post Type</option>
              {postTypes.filter(t => t.isActive).map((type) => (
                <option key={type.id} value={type.id}>
                  {type.label}
                </option>
              ))}
            </TextField>
            <TextField
              fullWidth
              label="Name (ID)"
              value={subtypeForm.name}
              onChange={(e) => setSubtypeForm({ ...subtypeForm, name: e.target.value })}
              helperText="Unique identifier (e.g., 'travel', 'discount', 'announcement')"
              sx={{ '& .MuiInputBase-root': { borderRadius: 2 } }}
            />
            <TextField
              fullWidth
              label="Display Label"
              value={subtypeForm.label}
              onChange={(e) => setSubtypeForm({ ...subtypeForm, label: e.target.value })}
              helperText="User-friendly name (e.g., 'Travel', 'Discount', 'Announcement')"
              sx={{ '& .MuiInputBase-root': { borderRadius: 2 } }}
            />
            <TextField
              fullWidth
              label="Description"
              value={subtypeForm.description}
              onChange={(e) => setSubtypeForm({ ...subtypeForm, description: e.target.value })}
              multiline
              rows={3}
              helperText="Optional description for this subtype"
              sx={{ '& .MuiInputBase-root': { borderRadius: 2 } }}
            />
            <TextField
              fullWidth
              label="Display Order"
              type="number"
              value={subtypeForm.order}
              onChange={(e) => setSubtypeForm({ ...subtypeForm, order: parseInt(e.target.value) })}
              helperText="Order for displaying in lists"
              sx={{ '& .MuiInputBase-root': { borderRadius: 2 } }}
            />
            <FormControlLabel
              control={
                <Switch
                  checked={subtypeForm.isActive}
                  onChange={(e) => setSubtypeForm({ ...subtypeForm, isActive: e.target.checked })}
                />
              }
              label="Active"
            />
          </Stack>
        </DialogContent>
        <DialogActions sx={{ p: 3, pt: 1 }}>
          <Button 
            onClick={() => setSubtypeDialogOpen(false)}
            sx={{ borderRadius: 2 }}
          >
            Cancel
          </Button>
          <GradientButton
            onClick={handleSaveSubtype}
            text={editingSubtype ? 'Update' : 'Create'}
            size="medium"
            variant="primary"
          />
        </DialogActions>
      </Dialog>

      {/* Mobile Floating Action Button */}
      {isMobile && (
        <Box
          sx={{
            position: 'fixed',
            bottom: 16,
            right: 16,
            zIndex: theme.zIndex.fab,
          }}
        >
          <GradientButton
            onClick={handleCreateType}
            text=""
            startIcon={<AddIcon />}
            size="small"
            variant="primary"
            sx={{
              minWidth: 56,
              height: 56,
              borderRadius: '50%',
              padding: 0,
            }}
          />
        </Box>
      )}
    </Container>
  );
}; 