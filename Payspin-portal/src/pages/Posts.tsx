import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Button,
  Grid,
  Alert,
  Chip,
  IconButton,
  Tooltip,
  LinearProgress,
  useTheme,
  useMediaQuery,
  Stack,
} from '@mui/material';
import { 
  Add as AddIcon,
  Category as CategoryIcon,
  Refresh as RefreshIcon,
  PlayArrow as SetupIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { usePosts } from '../hooks/usePosts';
import { usePostTypes } from '../hooks/usePostTypes';
import { PostFilters } from '../components/Post/PostFilters';
import { PostTable } from '../components/Post/PostTable';
import { GradientButton } from '../components/Common/GradientButton';
import { StatCard } from '../components/Common/StatCard';
import { LoadingSpinner } from '../components/Common/LoadingSpinner';
import { Post } from '../types/firestore';
import { seedPostTypes } from '../scripts/seedPostTypes';
import toast from 'react-hot-toast';
import { PayspinColors } from '../theme/theme';
import {
  Article as ArticleIcon,
  Publish as PublishIcon,
  Drafts as DraftIcon,
  Star as StarIcon,
  Visibility as VisibilityIcon,
  ThumbUp as ThumbUpIcon,
} from '@mui/icons-material';

export const Posts: React.FC = () => {
  const navigate = useNavigate();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const isTablet = useMediaQuery(theme.breakpoints.between('md', 'lg'));
  
  const [refreshKey, setRefreshKey] = useState(0);
  const [seedingTypes, setSeedingTypes] = useState(false);

  const {
    posts,
    loading,
    error,
    stats,
    tableState,
    handleTableStateChange,
    deletePost,
    publishPost,
    unpublishPost,
    toggleFeatured,
    updatePost,
  } = usePosts();

  const {
    postTypes,
    postSubtypes,
    loading: typesLoading,
    error: typesError,
    needsSetup,
    refreshData: refreshTypes,
  } = usePostTypes();

  const handleEditClick = (post: Post) => {
    navigate(`/posts/edit/${post.id}`);
  };

  const handleViewClick = (post: Post) => {
    // Open post URL if available, otherwise show in modal
    if (post.postUrl) {
      window.open(post.postUrl, '_blank');
    } else {
      // Could implement a modal view here
      console.log('View post:', post);
      toast('Post preview feature coming soon!', { icon: 'ℹ️' });
    }
  };

  const handleCreateClick = () => {
    navigate('/posts/create');
  };

  const handleDeleteClick = async (id: string) => {
    try {
      await deletePost(id);
      toast.success('Post deleted successfully');
    } catch (error) {
      console.error('Error deleting post:', error);
      toast.error('Failed to delete post');
    }
  };

  const handleUpdateStatus = async (id: string, status: string) => {
    try {
      if (status === 'published') {
        await publishPost(id);
        toast.success('Post published successfully');
      } else if (status === 'draft') {
        await unpublishPost(id);
        toast.success('Post moved to draft');
      } else {
        await updatePost(id, { isPublished: false, isDraft: false });
        toast.success('Post archived');
      }
    } catch (error) {
      console.error('Error updating post status:', error);
      toast.error('Failed to update post status');
    }
  };

  const handleToggleFeatured = async (id: string) => {
    try {
      await toggleFeatured(id);
      toast.success('Featured status updated');
    } catch (error) {
      console.error('Error toggling featured status:', error);
      toast.error('Failed to update featured status');
    }
  };

  const handleRefresh = async () => {
    setRefreshKey(prev => prev + 1);
    await refreshTypes();
    toast.success('Data refreshed');
  };

  const handleSeedPostTypes = async () => {
    try {
      setSeedingTypes(true);
      await seedPostTypes();
      toast.success('Post types initialized successfully!');
      await refreshTypes();
    } catch (error) {
      console.error('Error seeding post types:', error);
      toast.error('Failed to initialize post types');
    } finally {
      setSeedingTypes(false);
    }
  };

  const getTypeLabel = (typeName: string) => {
    const type = postTypes.find(t => t.name === typeName);
    return type?.label || typeName;
  };

  // Loading state
  if (loading && posts.length === 0) {
    return (
      <Container maxWidth="xl" sx={{ py: 3 }}>
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '50vh' }}>
          <LoadingSpinner variant="default" size="large" />
        </Box>
      </Container>
    );
  }

  // Error handling
  if (error) {
    return (
      <Container maxWidth="xl" sx={{ py: 3 }}>
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Typography variant="h6" color="error" sx={{ mb: 2 }}>
            Error Loading Posts
          </Typography>
          <Typography color="text.secondary" sx={{ mb: 3 }}>
            {error.message}
          </Typography>
          <Button 
            onClick={() => window.location.reload()} 
            variant="contained"
            sx={{ borderRadius: 2 }}
          >
            Reload Page
          </Button>
        </Box>
      </Container>
    );
  }

  // Show optional post types setup alert but don't block the interface
  const showTypesSetupAlert = needsSetup || (typesError && !typesError.includes('index'));

  return (
    <Container maxWidth="xl" sx={{ p: { xs: 2, sm: 3, md: 4 } }}>
      {/* Optional Post Types Setup Alert */}
      {showTypesSetupAlert && (
        <Alert 
          severity="info" 
          sx={{ 
            mt: 2, 
            mb: 3,
            borderRadius: 2,
            '& .MuiAlert-message': {
              width: '100%',
            },
          }}
        >
          <Typography 
            variant="h6" 
            sx={{ 
              mb: 1,
              fontSize: { xs: '1rem', sm: '1.125rem' }
            }}
          >
            Optional: Enhanced Post Management
          </Typography>
          <Typography 
            sx={{ 
              mb: 2,
              fontSize: { xs: '0.875rem', sm: '1rem' },
              lineHeight: 1.6,
            }}
          >
            Set up post types for enhanced categorization, filtering, and management features.
            You can still create and manage posts normally without this setup.
          </Typography>
          <Stack 
            direction={{ xs: 'column', sm: 'row' }} 
            spacing={{ xs: 1, sm: 2 }}
            sx={{ 
              flexWrap: 'wrap',
              gap: 2,
            }}
          >
            <Button 
              onClick={handleSeedPostTypes}
              variant="contained" 
              size="medium"
              disabled={seedingTypes}
              startIcon={seedingTypes ? <SetupIcon /> : <SetupIcon />}
              sx={{ 
                borderRadius: 3,
                fontWeight: 600,
                minWidth: { xs: 'auto', sm: 140, md: 160 },
                px: { xs: 3, sm: 4, md: 5 },
                py: 1.5,
                bgcolor: PayspinColors.primary,
                color: 'white',
                whiteSpace: 'nowrap',
                overflow: 'hidden',
                textOverflow: 'ellipsis',
                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                '&:hover': {
                  bgcolor: PayspinColors.primary,
                  transform: 'translateY(-2px)',
                  boxShadow: `0px 8px 24px ${PayspinColors.primary}30`,
                },
                '&:disabled': {
                  opacity: 0.7,
                  transform: 'none',
                },
                '& .MuiButton-startIcon': {
                  mr: { xs: 1, sm: 1.5 },
                },
              }}
            >
              {seedingTypes ? 'Setting up...' : 'Quick Setup'}
            </Button>
            <Button 
              onClick={refreshTypes} 
              variant="outlined" 
              size="medium" 
              disabled={seedingTypes}
              sx={{ 
                borderRadius: 3,
                fontWeight: 600,
                minWidth: { xs: 'auto', sm: 100, md: 120 },
                px: { xs: 3, sm: 4, md: 5 },
                py: 1.5,
                borderWidth: 2,
                borderColor: PayspinColors.secondary,
                color: PayspinColors.secondary,
                whiteSpace: 'nowrap',
                overflow: 'hidden',
                textOverflow: 'ellipsis',
                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                '&:hover': {
                  borderColor: PayspinColors.secondary,
                  bgcolor: `${PayspinColors.secondary}08`,
                  transform: 'translateY(-2px)',
                  boxShadow: `0px 8px 24px ${PayspinColors.secondary}25`,
                },
                '&:disabled': {
                  opacity: 0.5,
                  transform: 'none',
                },
              }}
            >
              Retry
            </Button>
            <Button 
              onClick={() => navigate('/post-types')} 
              variant="outlined" 
              size="medium" 
              disabled={seedingTypes}
              sx={{ 
                borderRadius: 3,
                fontWeight: 600,
                minWidth: { xs: 'auto', sm: 140, md: 160 },
                px: { xs: 3, sm: 4, md: 5 },
                py: 1.5,
                borderWidth: 2,
                borderColor: PayspinColors.primary,
                color: PayspinColors.primary,
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
                '&:disabled': {
                  opacity: 0.5,
                  transform: 'none',
                },
              }}
            >
              Advanced Setup
            </Button>
          </Stack>
        </Alert>
      )}

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
                color: 'text.primary',
                fontSize: { xs: '1.5rem', sm: '1.75rem', md: '2rem', lg: '2.25rem' },
              }}
            >
              Post Management
            </Typography>
            <Typography 
              variant="body1" 
              color="text.secondary"
              sx={{ 
                mb: 2,
                fontSize: { xs: '1rem', sm: '1.1rem' },
                opacity: 0.8,
              }}
            >
              Manage your posts across all content types
            </Typography>
            {postTypes.length > 0 && (
              <Box sx={{ 
                display: 'flex', 
                gap: 1, 
                flexWrap: 'wrap',
                mb: { xs: 2, lg: 0 }
              }}>
                {postTypes.map((type) => (
                  <Chip
                    key={type.id}
                    label={type.label}
                    size="small"
                    variant="outlined"
                    sx={{ 
                      fontSize: { xs: '0.75rem', sm: '0.875rem' },
                      height: { xs: 24, sm: 28 },
                      borderColor: PayspinColors.primary,
                      color: PayspinColors.primary,
                      '&:hover': {
                        bgcolor: `${PayspinColors.primary}08`,
                        borderColor: PayspinColors.primary,
                      },
                    }}
                  />
                ))}
              </Box>
            )}
          </Grid>
          <Grid item xs={12} lg={4}>
            <Stack 
              direction={{ xs: 'column', sm: 'row', lg: 'row' }} 
              spacing={2}
              sx={{ 
                justifyContent: { xs: 'stretch', lg: 'flex-end' },
                alignItems: { xs: 'stretch', sm: 'center' },
                width: '100%',
              }}
            >
              <Tooltip title="Refresh data">
                <span>
                  <IconButton 
                    onClick={handleRefresh} 
                    disabled={loading || typesLoading}
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
                startIcon={<CategoryIcon />}
                onClick={() => navigate('/post-types')}
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
                {isMobile ? 'Types' : 'Manage Types'}
              </Button>
              <GradientButton
                onClick={handleCreateClick}
                text={isMobile ? 'New Post' : 'Create Post'}
                startIcon={<AddIcon />}
                size="large"
                variant="primary"
                sx={{
                  minHeight: { xs: 44, sm: 48 },
                  minWidth: { xs: 'auto', sm: 140, md: 160 },
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

      {/* Loading States */}
      {(loading || typesLoading) && (
        <Box sx={{ mb: 3, textAlign: 'center' }}>
          <LoadingSpinner variant="default" size="medium" />
          <Typography 
            variant="body2" 
            sx={{ 
              mt: 2,
              color: 'text.secondary',
            }}
          >
            {typesLoading ? 'Loading post types...' : 'Loading posts...'}
          </Typography>
        </Box>
      )}

      {/* Stats Section */}
      {stats && !loading && (
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} lg={3}>
            <StatCard
              title="Total Posts"
              value={stats.total}
              icon={<ArticleIcon />}
              color={PayspinColors.primary}
              subtitle="All posts created"
              variant="elevated"
              size="large"
            />
          </Grid>
          <Grid item xs={12} sm={6} lg={3}>
            <StatCard
              title="Published"
              value={stats.published}
              icon={<PublishIcon />}
              color={PayspinColors.success}
              subtitle="Live posts"
              variant="elevated"
              size="large"
            />
          </Grid>
          <Grid item xs={12} sm={6} lg={3}>
            <StatCard
              title="Drafts"
              value={stats.drafts}
              icon={<DraftIcon />}
              color={PayspinColors.warning}
              subtitle="Work in progress"
              variant="elevated"
              size="large"
            />
          </Grid>
          <Grid item xs={12} sm={6} lg={3}>
            <StatCard
              title="Featured"
              value={posts.filter(p => p.isFeatured).length}
              icon={<StarIcon />}
              color={PayspinColors.yellow}
              subtitle="Highlighted posts"
              variant="elevated"
              size="large"
            />
          </Grid>
          <Grid item xs={12} sm={6} lg={3}>
            <StatCard
              title="Total Views"
              value={stats.totalViews.toLocaleString()}
              icon={<VisibilityIcon />}
              color={PayspinColors.primary}
              subtitle="Page views"
              variant="elevated"
              size="large"
            />
          </Grid>
          <Grid item xs={12} sm={6} lg={3}>
            <StatCard
              title="Total Likes"
              value={stats.totalLikes.toLocaleString()}
              icon={<ThumbUpIcon />}
              color={PayspinColors.secondary}
              subtitle="User engagement"
              variant="elevated"
              size="large"
            />
          </Grid>
        </Grid>
      )}

      {/* Filters and Table */}
      <Box sx={{ mb: 4 }}>
        <PostFilters
          tableState={tableState}
          onFilterChange={handleTableStateChange}
        />
      </Box>

      <PostTable
        posts={posts}
        loading={loading}
        tableState={tableState}
        totalPosts={stats?.total || 0}
        onTableStateChange={handleTableStateChange}
        onDeletePost={handleDeleteClick}
        onUpdateStatus={handleUpdateStatus}
        onEditPost={handleEditClick}
        onViewPost={handleViewClick}
      />

      {/* Mobile Floating Action Button */}
      {isMobile && (
        <Box
          sx={{
            position: 'fixed',
            bottom: 20,
            right: 20,
            zIndex: theme.zIndex.fab,
          }}
        >
          <GradientButton
            onClick={handleCreateClick}
            text=""
            startIcon={<AddIcon />}
            size="small"
            variant="primary"
            sx={{
              minWidth: 56,
              height: 56,
              borderRadius: '50%',
              padding: 0,
              boxShadow: '0px 8px 32px rgba(252, 0, 255, 0.3)',
              transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
              '&:hover': {
                transform: 'scale(1.05) rotate(90deg)',
                boxShadow: '0px 12px 40px rgba(252, 0, 255, 0.4)',
              },
              '& .MuiButton-startIcon': {
                transition: 'all 0.3s ease',
              },
              '&:hover .MuiButton-startIcon': {
                transform: 'scale(1.1)',
              },
            }}
          />
        </Box>
      )}
    </Container>
  );
}; 