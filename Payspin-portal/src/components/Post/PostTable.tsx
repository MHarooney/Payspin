import React, { useState } from 'react';
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
  Box,
  Typography,
  TablePagination,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Tooltip,
  Avatar,
  Switch,
  FormControlLabel,
  Card,
  CardContent,
  Stack,
  useTheme,
  useMediaQuery,
  Skeleton,
  Button,
  Divider,
  Grid,
  Popover,
  Portal,
} from '@mui/material';
import {
  MoreVert as MoreVertIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as VisibilityIcon,
  Publish as PublishIcon,
  Unpublished as UnpublishIcon,
  Star as StarIcon,
  StarBorder as StarBorderIcon,
  LocationOn as LocationIcon,
  Category as CategoryIcon,
  Link as LinkIcon,
  OpenInNew as OpenInNewIcon,
  CalendarToday as CalendarIcon,
} from '@mui/icons-material';
import { Post, TableState } from '../../types/firestore';
import { PayspinColors } from '../../theme/theme';
import { ActionMenuItem, ActionMenu, useActionMenu, ActionMenuDropdown, useActionMenuDropdown, SimpleActionMenu, useSimpleActionMenu } from '../Common/ActionMenu';

interface PostTableProps {
  posts: Post[];
  loading: boolean;
  tableState: TableState;
  totalPosts: number;
  onTableStateChange: (newState: Partial<TableState>) => void;
  onDeletePost: (id: string) => Promise<void>;
  onUpdateStatus: (id: string, status: string) => Promise<void>;
  onEditPost?: (post: Post) => void;
  onViewPost?: (post: Post) => void;
}

const getTypeColor = (type: string) => {
  switch (type.toLowerCase()) {
    case 'blog':
      return 'success';
    case 'news':
      return 'info';
    case 'announcements':
      return 'warning';
    default:
      return 'default';
  }
};

const getStatusColor = (isPublished: boolean, isDraft: boolean) => {
  if (isPublished) return 'success';
  if (isDraft) return 'warning';
  return 'default';
};

const getStatusLabel = (isPublished: boolean, isDraft: boolean) => {
  if (isPublished) return 'Published';
  if (isDraft) return 'Draft';
  return 'Unknown';
};

export const PostTable: React.FC<PostTableProps> = ({
  posts,
  loading,
  tableState,
  totalPosts,
  onTableStateChange,
  onDeletePost,
  onUpdateStatus,
  onEditPost,
  onViewPost,
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const isTablet = useMediaQuery(theme.breakpoints.between('md', 'lg'));
  
  // Option 1: Use the enhanced ActionMenu (with better anchor validation)
  // const { anchorEl, selectedItem: selectedPost, handleMenuOpen, handleMenuClose } = useActionMenu<Post>();
  
  // Option 2: Use SimpleActionMenu (completely avoids MUI Popover issues)
  const { isOpen, selectedItem: selectedPost, anchorPosition, handleMenuOpen, handleMenuClose } = useSimpleActionMenu<Post>();

  const handleEdit = () => {
    if (selectedPost && onEditPost) {
      onEditPost(selectedPost);
    }
  };

  const handleView = () => {
    if (selectedPost && onViewPost) {
      onViewPost(selectedPost);
    }
  };

  const handleDelete = async () => {
    if (selectedPost) {
      await onDeletePost(selectedPost.id);
    }
  };

  const handleStatusChange = async () => {
    if (!selectedPost) return;
    const newStatus = selectedPost.isPublished ? 'draft' : 'published';
    await onUpdateStatus(selectedPost.id, newStatus);
  };

  const handleFeaturedToggle = async (post: Post) => {
    // This would need to be implemented in the parent component
    // For now, we'll just toggle the local state
    console.log('Toggle featured for post:', post.id);
  };

  const handlePageChange = (event: unknown, newPage: number) => {
    onTableStateChange({ page: newPage + 1 });
  };

  const handlePageSizeChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    onTableStateChange({
      pageSize: parseInt(event.target.value, 10),
      page: 1,
    });
  };

  const truncateText = (text: string, maxLength: number = 50) => {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  };

  const getActionMenuItems = (post: Post): ActionMenuItem[] => {
    console.log('Creating menu items for post:', post.id, post.postTitle); // Debug log
    
    return [
      {
        id: 'edit',
        label: 'Edit Post',
        icon: <EditIcon fontSize="small" />,
        onClick: () => {
          console.log('Edit clicked for post:', post.id); // Debug log
          if (onEditPost) {
            onEditPost(post);
          }
        },
      },
      ...(post.postUrl ? [{
        id: 'view',
        label: 'View Post',
        icon: <VisibilityIcon fontSize="small" />,
        onClick: () => {
          console.log('View clicked for post:', post.id); // Debug log
          if (onViewPost) {
            onViewPost(post);
          }
        },
      }] : []),
      {
        id: 'divider-1',
        divider: true,
        label: 'Status Actions',
      },
      {
        id: 'status',
        label: post.isPublished ? 'Unpublish Post' : 'Publish Post',
        icon: post.isPublished ? <UnpublishIcon fontSize="small" /> : <PublishIcon fontSize="small" />,
        onClick: async () => {
          console.log('Status change clicked for post:', post.id); // Debug log
          const newStatus = post.isPublished ? 'draft' : 'published';
          await onUpdateStatus(post.id, newStatus);
        },
      },
      {
        id: 'divider-2',
        divider: true,
        label: 'Danger Zone',
      },
      {
        id: 'delete',
        label: 'Delete Post',
        icon: <DeleteIcon fontSize="small" />,
        onClick: async () => {
          console.log('Delete clicked for post:', post.id); // Debug log
          await onDeletePost(post.id);
        },
        color: 'error',
      },
    ];
  };

  const MobileCardView = () => (
    <Stack spacing={2}>
      {loading ? (
        Array.from({ length: 3 }).map((_, index) => (
          <Card key={index}>
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
      ) : (
        posts.map((post) => (
          <Card key={post.id}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Box sx={{ flex: 1, minWidth: 0 }}>
                  <Typography 
                    variant="h6" 
                    sx={{ 
                      fontWeight: 600,
                      fontSize: { xs: '1rem', sm: '1.125rem' },
                      color: 'text.primary',
                      '&:hover': { color: 'text.secondary' },
                    }}
                  >
                    {truncateText(post.postTitle, 60)}
                  </Typography>
                  <Stack direction="row" spacing={1} alignItems="center" flexWrap="wrap" sx={{ mt: 1 }}>
                    <Chip
                      label={post.postType || 'Unknown'}
                      color={getTypeColor(post.postType || '')}
                      size="small"
                      sx={{ 
                        fontSize: { xs: '0.625rem', sm: '0.75rem' },
                        height: { xs: 20, sm: 24 },
                      }}
                    />
                    <Chip
                      label={getStatusLabel(post.isPublished, !post.isPublished)}
                      color={getStatusColor(post.isPublished, !post.isPublished)}
                      size="small"
                      sx={{ 
                        fontSize: { xs: '0.625rem', sm: '0.75rem' },
                        height: { xs: 20, sm: 24 },
                      }}
                    />
                  </Stack>
                </Box>
                <IconButton
                  onClick={(e) => handleMenuOpen(e, post)}
                  sx={{ 
                    minWidth: 44,
                    minHeight: 44,
                  }}
                >
                  <MoreVertIcon />
                </IconButton>
              </Box>

              <Stack spacing={2}>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <LocationIcon sx={{ mr: 1, color: 'text.secondary', fontSize: 20 }} />
                  <Typography variant="body2" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                    {post.postLocation || post.location || 'N/A'}
                  </Typography>
                </Box>

                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <CategoryIcon sx={{ mr: 1, color: 'text.secondary', fontSize: 20 }} />
                  <Typography variant="body2" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                    {post.postType || 'Unknown Type'}
                  </Typography>
                </Box>

                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <CalendarIcon sx={{ mr: 1, color: 'text.secondary', fontSize: 20 }} />
                  <Typography variant="body2" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                    {post.createdAt ? new Date(post.createdAt.seconds * 1000).toLocaleDateString() : '-'}
                  </Typography>
                </Box>
              </Stack>
            </CardContent>
          </Card>
        ))
      )}
    </Stack>
  );

  const DesktopTableView = () => (
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
            <TableCell sx={{ fontWeight: 600 }}>Title</TableCell>
            <TableCell sx={{ fontWeight: 600 }}>Type</TableCell>
            <TableCell sx={{ fontWeight: 600 }}>Status</TableCell>
            <TableCell sx={{ fontWeight: 600 }}>Location</TableCell>
            <TableCell sx={{ fontWeight: 600 }}>Created</TableCell>
            <TableCell sx={{ fontWeight: 600 }}>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {loading ? (
            Array.from({ length: 5 }).map((_, index) => (
              <TableRow key={index}>
                <TableCell><Skeleton variant="text" width="80%" /></TableCell>
                <TableCell><Skeleton variant="text" width="60%" /></TableCell>
                <TableCell><Skeleton variant="text" width="40%" /></TableCell>
                <TableCell><Skeleton variant="text" width="50%" /></TableCell>
                <TableCell><Skeleton variant="text" width="30%" /></TableCell>
                <TableCell><Skeleton variant="circular" width={32} height={32} /></TableCell>
              </TableRow>
            ))
          ) : (
            posts.map((post) => (
              <TableRow key={post.id} hover>
                <TableCell>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {truncateText(post.postTitle, 50)}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip
                    label={post.postType || 'Unknown'}
                    color={getTypeColor(post.postType || '')}
                    size="small"
                    sx={{ fontSize: '0.75rem' }}
                  />
                </TableCell>
                <TableCell>
                  <Chip
                    label={getStatusLabel(post.isPublished, !post.isPublished)}
                    color={getStatusColor(post.isPublished, !post.isPublished)}
                    size="small"
                    sx={{ fontSize: '0.75rem' }}
                  />
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {post.postLocation || post.location || 'N/A'}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {post.createdAt ? new Date(post.createdAt.seconds * 1000).toLocaleDateString() : '-'}
                  </Typography>
                </TableCell>
                <TableCell>
                  <IconButton
                    size="small"
                    onClick={(e) => handleMenuOpen(e, post)}
                    data-action-menu
                    sx={{ 
                      minWidth: 32, 
                      minHeight: 32,
                    }}
                  >
                    <MoreVertIcon fontSize="small" />
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
        p: 2,
        '& .MuiTablePagination-root': {
          overflow: 'visible',
        },
      }}>
        <TablePagination
          component="div"
          count={totalPosts}
          page={(tableState.page || 1) - 1}
          onPageChange={handlePageChange}
          rowsPerPage={tableState.pageSize}
          onRowsPerPageChange={handlePageSizeChange}
          rowsPerPageOptions={[5, 10, 25, 50]}
          sx={{
            '& .MuiTablePagination-selectLabel, & .MuiTablePagination-displayedRows': {
              fontSize: { xs: '0.75rem', sm: '0.875rem' },
            },
          }}
        />
      </Box>

      {/* Action Menu - Option 1: Enhanced ActionMenu */}
      {/*
      {selectedPost && (
        <ActionMenu
          items={getActionMenuItems(selectedPost)}
          anchorEl={anchorEl}
          onClose={handleMenuClose}
        />
      )}
      */}

      {/* Action Menu - Option 2: SimpleActionMenu (uncomment to use this instead) */}
      {selectedPost && anchorPosition && (
        <SimpleActionMenu
          items={getActionMenuItems(selectedPost)}
          isOpen={isOpen}
          anchorPosition={anchorPosition}
          onClose={handleMenuClose}
        />
      )}

      {/* Action Menu - Option 3: ActionMenuDropdown (uncomment to use this instead) */}
      {/*
      const { isOpen, selectedItem: selectedPostDropdown, buttonRef, handleMenuOpen: handleDropdownOpen, handleMenuClose: handleDropdownClose } = useActionMenuDropdown<Post>();
      
      // In the IconButton onClick:
      // onClick={(e) => handleDropdownOpen(e, post)}
      // ref={buttonRef}
      
      {selectedPostDropdown && isOpen && (
        <ActionMenuDropdown
          items={getActionMenuItems(selectedPostDropdown)}
          onClose={handleDropdownClose}
          buttonRef={buttonRef}
        />
      )}
      */}
    </>
  );
}; 