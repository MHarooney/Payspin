import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useNavigate, useParams, useLocation } from 'react-router-dom';
import {
  Box,
  Container,
  Typography,
  Paper,
  Grid,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  OutlinedInput,
  FormControlLabel,
  Switch,
  Card,
  CardContent,
  CardHeader,
  Divider,
  Tabs,
  Tab,
  IconButton,
  Autocomplete,
  LinearProgress,
  SelectChangeEvent,
  Alert,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material';
import {
  Save as SaveIcon,
  Publish as PublishIcon,
  ArrowBack as ArrowBackIcon,
  Image as ImageIcon,
  VideoLibrary as VideoIcon,
  Check as CheckIcon,
  Delete as DeleteIcon,
  Add as AddIcon,
  Edit as EditIcon,
  Visibility as VisibilityIcon,
  Star as StarIcon,
  StarBorder as StarBorderIcon,
} from '@mui/icons-material';
import { Post, PostMedia } from '../types/firestore';
import { useAuth } from '../contexts/AuthContext';
import { firebaseService } from '../services/firebase';
import { storageService } from '../services/firebase/storage';
import { usePostTypes } from '../hooks/usePostTypes';
import toast from 'react-hot-toast';
import { Timestamp } from 'firebase/firestore';
import { now } from '../utils/date';
import CountrySelect from '../components/Common/CountrySelect';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

interface PostFormData {
  postType: string;
  postSubtype: string;
  postTitle: string;
  postLocation: string;
  postDescription: string;
  postBodyPrimary: string;
  postBodySecondary: string;
  isFeatured: boolean;
  postOrder: number;
  mainImage: string;
  media: PostMedia[];
  isPublished: boolean;
  isDraft: boolean;
}



// Fixed TabPanel component
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

export const PostEditor: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { id } = useParams<{ id: string }>();
  const { currentUser } = useAuth();
  const { postTypes, getSubtypesByType, loading: typesLoading } = usePostTypes();
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [tabValue, setTabValue] = useState(0);
  const [existingPost, setExistingPost] = useState<Post | null>(null);
  const [mainImagePreview, setMainImagePreview] = useState<string | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [autoSaved, setAutoSaved] = useState(false);
  const [mediaDialogOpen, setMediaDialogOpen] = useState(false);
  const [editingMedia, setEditingMedia] = useState<PostMedia | null>(null);
  const autoSaveTimeoutRef = useRef<NodeJS.Timeout>();

  // Get default type from navigation state
  const defaultType = location.state?.defaultType || 'blog';
  
  const [formData, setFormData] = useState<PostFormData>({
    postType: defaultType,
    postSubtype: '',
    postTitle: '',
    postLocation: 'Netherlands',
    postDescription: '',
    postBodyPrimary: '',
    postBodySecondary: '',
    isFeatured: false,
    postOrder: 1,
    mainImage: '',
    media: [],
    isPublished: false,
    isDraft: true,
  });

  const isEditing = Boolean(id);

  // Auto-save functionality
  const autoSave = useCallback(async () => {
    if (!currentUser || !formData.postTitle.trim()) return;
    
    try {
      // Generate URL automatically for auto-save
      const generatePostUrl = (title: string, postId?: string) => {
        const slug = title
          .toLowerCase()
          .replace(/[^a-z0-9\s-]/g, '')
          .replace(/\s+/g, '-')
          .replace(/-+/g, '-')
          .trim();
        
        if (postId) {
          return `/posts/${postId}/${slug}`;
        }
        return `/posts/${slug}`;
      };

      const postData: Partial<Post> = {
        postType: formData.postType,
        postTitle: formData.postTitle,
        postLocation: formData.postLocation,
        postDescription: formData.postDescription,
        postBodyPrimary: formData.postBodyPrimary,
        postBodySecondary: formData.postBodySecondary,
        isFeatured: formData.isFeatured,
        postOrder: formData.postOrder,
        postUrl: isEditing ? generatePostUrl(formData.postTitle, id) : generatePostUrl(formData.postTitle),
        media: formData.media,
        isPublished: false, // Always save as draft for auto-save
        isDraft: true,
        updatedAt: now(),
      };

      // Only include postSubtype if it has a valid non-empty value
      if (formData.postSubtype && formData.postSubtype.trim() !== '') {
        postData.postSubtype = formData.postSubtype;
      }

      // Only include mainImage if it has a valid value
      if (mainImagePreview) {
        postData.mainImage = mainImagePreview;
      }

      if (isEditing && id) {
        await firebaseService.posts.update(id, postData);
      }
      
      setAutoSaved(true);
      setTimeout(() => setAutoSaved(false), 3000);
    } catch (error) {
      console.error('Auto-save failed:', error);
    }
  }, [currentUser, formData, mainImagePreview, isEditing, id]);

  // Trigger auto-save on form changes (debounced)
  useEffect(() => {
    if (autoSaveTimeoutRef.current) {
      clearTimeout(autoSaveTimeoutRef.current);
    }
    
    autoSaveTimeoutRef.current = setTimeout(() => {
      if (formData.postTitle.trim() && isEditing) {
        autoSave();
      }
    }, 2000);

    return () => {
      if (autoSaveTimeoutRef.current) {
        clearTimeout(autoSaveTimeoutRef.current);
      }
    };
  }, [formData, autoSave, isEditing]);

  // Load existing post if editing
  useEffect(() => {
    if (isEditing && id) {
      const loadPost = async () => {
        try {
          setLoading(true);
          const post = await firebaseService.posts.getById(id);
          if (post) {
            setExistingPost(post);
            setFormData({
              postType: post.postType || 'blog',
              postSubtype: post.postSubtype || '',
              postTitle: post.postTitle || '',
              postLocation: post.postLocation || 'Netherlands',
              postDescription: post.postDescription || '',
              postBodyPrimary: post.postBodyPrimary || '',
              postBodySecondary: post.postBodySecondary || '',
              isFeatured: post.isFeatured || false,
              postOrder: post.postOrder || 1,
              mainImage: post.mainImage || '',
              media: post.media || [],
              isPublished: post.isPublished || false,
              isDraft: post.isDraft !== false,
            });
            if (post.mainImage) {
              setMainImagePreview(post.mainImage);
            }
          }
        } catch (error) {
          console.error('Error loading post:', error);
          toast.error('Failed to load post');
        } finally {
          setLoading(false);
        }
      };
      loadPost();
    }
  }, [isEditing, id]);

  // Validation
  const validateForm = (forPublishing: boolean = false): boolean => {
    const newErrors: Record<string, string> = {};

    // Basic validation always required
    if (!formData.postTitle.trim()) newErrors.postTitle = 'Title is required';
    if (!formData.postLocation.trim()) newErrors.postLocation = 'Country is required';
    if (!formData.postDescription.trim()) newErrors.postDescription = 'Description is required';
    if (!formData.postBodyPrimary.trim()) newErrors.postBodyPrimary = 'Primary content is required';
    if (!formData.mainImage) newErrors.mainImage = 'Main image is required';

    // Additional validation for publishing
    if (forPublishing) {
      if (formData.postBodyPrimary.length < 100) {
        newErrors.postBodyPrimary = 'Primary content must be at least 100 characters for publishing';
      }
      if (formData.postDescription.length < 100) {
        newErrors.postDescription = 'Description must be at least 100 characters for publishing';
      }
    }

    if (formData.postOrder < 1) newErrors.postOrder = 'Order must be at least 1';

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // Clear errors for specific fields
  const clearFieldError = (field: string) => {
    if (errors[field]) {
      setErrors(prev => {
        const newErrors = { ...prev };
        delete newErrors[field];
        return newErrors;
      });
    }
  };

  const handleSave = async (publish: boolean = false) => {
    try {
      setSaving(true);
      
      if (!currentUser) {
        toast.error('You must be logged in to save posts');
        return;
      }

      const formDataWithStatus = { 
        ...formData, 
        isPublished: publish,
        isDraft: !publish,
      };
      
      if (!validateForm(publish)) {
        toast.error(publish ? 'Please fix the form errors before publishing' : 'Please fix the basic form errors');
        return;
      }

      // Generate URL automatically based on title and ID
      const generatePostUrl = (title: string, postId?: string) => {
        const slug = title
          .toLowerCase()
          .replace(/[^a-z0-9\s-]/g, '')
          .replace(/\s+/g, '-')
          .replace(/-+/g, '-')
          .trim();
        
        if (postId) {
          return `/posts/${postId}/${slug}`;
        }
        return `/posts/${slug}`;
      };

      const postData: Partial<Post> = {
        postType: formDataWithStatus.postType,
        postTitle: formDataWithStatus.postTitle,
        postLocation: formDataWithStatus.postLocation,
        postDescription: formDataWithStatus.postDescription,
        postBodyPrimary: formDataWithStatus.postBodyPrimary,
        postBodySecondary: formDataWithStatus.postBodySecondary,
        isFeatured: formDataWithStatus.isFeatured,
        postOrder: formDataWithStatus.postOrder,
        postUrl: isEditing ? generatePostUrl(formDataWithStatus.postTitle, id) : generatePostUrl(formDataWithStatus.postTitle),
        media: formDataWithStatus.media,
        isPublished: formDataWithStatus.isPublished,
        isDraft: formDataWithStatus.isDraft,
        updatedAt: now(),
      };

      // Only include postSubtype if it has a valid non-empty value
      if (formDataWithStatus.postSubtype && formDataWithStatus.postSubtype.trim() !== '') {
        postData.postSubtype = formDataWithStatus.postSubtype;
      }

      // Only include mainImage if it has a valid value
      if (formData.mainImage) {
        postData.mainImage = formData.mainImage;
      }

      if (isEditing) {
        await firebaseService.posts.update(id!, postData);
        toast.success('Post updated successfully');
      } else {
        const newPostData = {
          ...postData,
          createdAt: now(),
          views: 0,
          likes: 0,
        } as Omit<Post, 'id'>;

        if (publish) {
          (newPostData as any).publishedAt = now();
        }
        await firebaseService.posts.create(newPostData);
        toast.success('Post created successfully');
      }

      navigate('/posts');
    } catch (error) {
      console.error('Error saving post:', error);
      toast.error('Failed to save post');
    } finally {
      setSaving(false);
    }
  };

  const handleInputChange = (field: keyof PostFormData, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
      // Reset subtype when post type changes
      ...(field === 'postType' && { postSubtype: '' })
    }));
    clearFieldError(field as string);
  };

  const handleImageUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      try {
        // Show loading state
        setSaving(true);
        
        // Try to use Firebase Storage first
        try {
          // Delete old image if it exists
          if (formData.mainImage && formData.mainImage.startsWith('https://')) {
            try {
              await storageService.deleteImage(formData.mainImage);
            } catch (error) {
              console.warn('Failed to delete old image:', error);
            }
          }
          
          // Compress the image before upload
          const compressedFile = await storageService.compressImage(file, 1200, 1200, 0.8);
          
          // Upload to Firebase Storage
          const downloadURL = await storageService.uploadImage(compressedFile, 'posts/images/');
          
          // Set the preview and store the URL
          setMainImagePreview(downloadURL);
          setFormData(prev => ({ ...prev, mainImage: downloadURL }));
          
          toast.success('Image uploaded successfully');
        } catch (storageError) {
          console.warn('Firebase Storage not available, falling back to base64:', storageError);
          
          // Fallback to base64 encoding (for development/testing)
          const reader = new FileReader();
          reader.onload = (e) => {
            const base64Data = e.target?.result as string;
            setMainImagePreview(base64Data);
            setFormData(prev => ({ ...prev, mainImage: base64Data }));
            toast.success('Image uploaded (base64 mode)');
          };
          reader.readAsDataURL(file);
        }
        
        // Clear the main image error when an image is uploaded
        clearFieldError('mainImage');
      } catch (error) {
        console.error('Error uploading image:', error);
        toast.error('Failed to upload image');
      } finally {
        setSaving(false);
      }
    }
  };

  const handleRemoveImage = async () => {
    try {
      // If there's an existing image URL, try to delete it from storage
      if (formData.mainImage && formData.mainImage.startsWith('https://')) {
        try {
          await storageService.deleteImage(formData.mainImage);
        } catch (storageError) {
          console.warn('Failed to delete from storage (may not be available):', storageError);
        }
      }
      
      setMainImagePreview(null);
      setFormData(prev => ({ ...prev, mainImage: '' }));
      toast.success('Image removed successfully');
    } catch (error) {
      console.error('Error removing image:', error);
      toast.error('Failed to remove image');
      // Still clear the local state even if storage deletion fails
      setMainImagePreview(null);
      setFormData(prev => ({ ...prev, mainImage: '' }));
    }
  };

  const handleAddMedia = () => {
    setEditingMedia(null);
    setMediaDialogOpen(true);
  };

  const handleEditMedia = (media: PostMedia) => {
    setEditingMedia(media);
    setMediaDialogOpen(true);
  };

  const handleDeleteMedia = (mediaId: string) => {
    setFormData(prev => ({
      ...prev,
      media: prev.media.filter(m => m.id !== mediaId)
    }));
  };

  const handleSaveMedia = (media: PostMedia) => {
    if (editingMedia) {
      // Update existing media
      setFormData(prev => ({
        ...prev,
        media: prev.media.map(m => m.id === editingMedia.id ? media : m)
      }));
    } else {
      // Add new media
      setFormData(prev => ({
        ...prev,
        media: [...prev.media, { ...media, id: Date.now().toString() }]
      }));
    }
    setMediaDialogOpen(false);
    setEditingMedia(null);
  };

  const getAvailableSubtypes = () => {
    if (!formData.postType) return [];
    return getSubtypesByType(formData.postType);
  };

  if (loading) {
    return (
      <Container maxWidth="lg">
        <Box sx={{ mt: 4 }}>
          <LinearProgress />
          <Typography variant="h6" sx={{ mt: 2 }}>
            Loading post...
          </Typography>
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg">
      <Box sx={{ mt: 4, mb: 4 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center' }}>
            <IconButton onClick={() => navigate('/posts')} sx={{ mr: 2 }}>
              <ArrowBackIcon />
            </IconButton>
            <Typography variant="h4" component="h1">
              {isEditing ? 'Edit Post' : 'Create New Post'}
            </Typography>
          </Box>
          
          {isEditing && autoSaved && (
            <Box sx={{ display: 'flex', alignItems: 'center', color: 'success.main' }}>
              <CheckIcon sx={{ mr: 1, fontSize: 20 }} />
              <Typography variant="body2">
                Auto-saved
              </Typography>
            </Box>
          )}
        </Box>

        {Object.keys(errors).length > 0 && (
          <Alert severity="error" sx={{ mb: 2 }}>
            Please fix the following errors: {Object.keys(errors).join(', ')}
          </Alert>
        )}

        <Paper elevation={3}>
          <Tabs value={tabValue} onChange={(e, newValue) => setTabValue(newValue)}>
            <Tab label="Content" />
            <Tab label="Settings" />
            <Tab label="Media" />
          </Tabs>

          <TabPanel value={tabValue} index={0}>
            <Box sx={{ p: 3 }}>
              <Grid container spacing={3}>
                <Grid item xs={12} md={8}>
                  <TextField
                    fullWidth
                    label="Post Title"
                    value={formData.postTitle}
                    onChange={(e) => handleInputChange('postTitle', e.target.value)}
                    error={Boolean(errors.postTitle)}
                    helperText={errors.postTitle}
                    margin="normal"
                  />

                  <TextField
                    fullWidth
                    label="Post Description"
                    value={formData.postDescription}
                    onChange={(e) => handleInputChange('postDescription', e.target.value)}
                    error={Boolean(errors.postDescription)}
                    helperText={errors.postDescription}
                    margin="normal"
                    multiline
                    rows={3}
                  />

                  <TextField
                    fullWidth
                    label="Primary Content"
                    value={formData.postBodyPrimary}
                    onChange={(e) => handleInputChange('postBodyPrimary', e.target.value)}
                    error={Boolean(errors.postBodyPrimary)}
                    helperText={errors.postBodyPrimary}
                    margin="normal"
                    multiline
                    rows={15}
                  />

                  <TextField
                    fullWidth
                    label="Secondary Content (Optional)"
                    value={formData.postBodySecondary}
                    onChange={(e) => handleInputChange('postBodySecondary', e.target.value)}
                    margin="normal"
                    multiline
                    rows={8}
                  />
                </Grid>

                <Grid item xs={12} md={4}>
                  <Card sx={{ border: errors.mainImage ? '2px solid #d32f2f' : '1px solid rgba(0, 0, 0, 0.12)' }}>
                    <CardHeader 
                      title="Main Image *" 
                      titleTypographyProps={{ 
                        color: errors.mainImage ? 'error' : 'inherit',
                        fontWeight: 'bold'
                      }}
                    />
                    <CardContent>
                      {mainImagePreview ? (
                        <Box>
                          <img
                            src={mainImagePreview}
                            alt="Main"
                            style={{ width: '100%', height: '200px', objectFit: 'cover' }}
                          />
                          <Button
                            fullWidth
                            variant="outlined"
                            color="error"
                            onClick={handleRemoveImage}
                            sx={{ mt: 1 }}
                          >
                            Remove Image
                          </Button>
                        </Box>
                      ) : (
                        <Box sx={{ textAlign: 'center' }}>
                          <input
                            accept="image/*"
                            style={{ display: 'none' }}
                            id="main-image-upload"
                            type="file"
                            onChange={handleImageUpload}
                          />
                          <label htmlFor="main-image-upload">
                            <Button
                              variant="outlined"
                              color={errors.mainImage ? "error" : "primary"}
                              component="span"
                              startIcon={<ImageIcon />}
                              fullWidth
                              sx={{ 
                                borderColor: errors.mainImage ? '#d32f2f' : undefined,
                                '&:hover': {
                                  borderColor: errors.mainImage ? '#d32f2f' : undefined,
                                }
                              }}
                            >
                              Upload Main Image
                            </Button>
                          </label>
                          {errors.mainImage && (
                            <Typography 
                              variant="caption" 
                              color="error" 
                              sx={{ mt: 1, display: 'block' }}
                            >
                              {errors.mainImage}
                            </Typography>
                          )}
                        </Box>
                      )}
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>
            </Box>
          </TabPanel>

          <TabPanel value={tabValue} index={1}>
            <Box sx={{ p: 3 }}>
              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <FormControl fullWidth margin="normal">
                    <InputLabel>Post Type</InputLabel>
                    <Select
                      value={formData.postType}
                      onChange={(e) => handleInputChange('postType', e.target.value)}
                      label="Post Type"
                    >
                      {postTypes.length > 0 ? (
                        postTypes.map((type) => (
                          <MenuItem key={type.id} value={type.name}>
                            {type.label}
                          </MenuItem>
                        ))
                      ) : (
                        <>
                          <MenuItem value="blog">Blog</MenuItem>
                          <MenuItem value="news">News</MenuItem>
                          <MenuItem value="offer">Offer</MenuItem>
                        </>
                      )}
                    </Select>
                    {postTypes.length === 0 && (
                      <Typography variant="caption" color="text.secondary" sx={{ mt: 1 }}>
                        Using default types. Set up post types for enhanced management.
                      </Typography>
                    )}
                  </FormControl>

                  <FormControl fullWidth margin="normal">
                    <InputLabel>Post Subtype</InputLabel>
                    <Select
                      value={formData.postSubtype}
                      onChange={(e) => handleInputChange('postSubtype', e.target.value)}
                      label="Post Subtype"
                    >
                      {postTypes.length > 0 ? (
                        (() => {
                          const availableSubtypes = getAvailableSubtypes();
                          return availableSubtypes.length > 0 ? (
                            availableSubtypes.map((subtype) => (
                              <MenuItem key={subtype.name} value={subtype.name}>
                                {subtype.label}
                              </MenuItem>
                            ))
                          ) : (
                            <MenuItem value="" disabled>
                              No subtypes available for this post type
                            </MenuItem>
                          );
                        })()
                      ) : (
                        <MenuItem value="" disabled>
                          Set up post types to enable subtypes
                        </MenuItem>
                      )}
                    </Select>
                    {postTypes.length === 0 && (
                      <Typography variant="caption" color="text.secondary" sx={{ mt: 1 }}>
                        Subtypes will be available after setting up post types.
                      </Typography>
                    )}
                  </FormControl>

                  <CountrySelect
                    value={formData.postLocation}
                    onChange={(value) => handleInputChange('postLocation', value)}
                    label="Location"
                    placeholder="Search for a country..."
                    fullWidth
                  />
                </Grid>

                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    label="Display Order"
                    type="number"
                    value={formData.postOrder}
                    onChange={(e) => handleInputChange('postOrder', parseInt(e.target.value))}
                    error={Boolean(errors.postOrder)}
                    helperText={errors.postOrder}
                    margin="normal"
                  />

                  <TextField
                    fullWidth
                    label="Generated URL"
                    value={(() => {
                      const slug = formData.postTitle
                        .toLowerCase()
                        .replace(/[^a-z0-9\s-]/g, '')
                        .replace(/\s+/g, '-')
                        .replace(/-+/g, '-')
                        .trim();
                      return isEditing ? `/posts/${id}/${slug}` : `/posts/${slug}`;
                    })()}
                    margin="normal"
                    InputProps={{
                      readOnly: true,
                    }}
                    helperText="URL will be automatically generated from the post title"
                  />

                  <FormControlLabel
                    control={
                      <Switch
                        checked={formData.isFeatured}
                        onChange={(e) => handleInputChange('isFeatured', e.target.checked)}
                      />
                    }
                    label="Featured Post"
                    sx={{ mt: 2 }}
                  />
                </Grid>
              </Grid>
            </Box>
          </TabPanel>

          <TabPanel value={tabValue} index={2}>
            <Box sx={{ p: 3 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h6">Media Gallery</Typography>
                <Button
                  variant="contained"
                  startIcon={<AddIcon />}
                  onClick={handleAddMedia}
                >
                  Add Media
                </Button>
              </Box>

              <List>
                {formData.media.map((media) => (
                  <ListItem key={media.id} divider>
                    <Box sx={{ display: 'flex', alignItems: 'center', width: '100%' }}>
                      {media.type === 'image' ? (
                        <img
                          src={media.url}
                          alt={media.alt || 'Media'}
                          style={{ width: 60, height: 60, objectFit: 'cover', marginRight: 16 }}
                        />
                      ) : (
                        <VideoIcon sx={{ fontSize: 60, mr: 2 }} />
                      )}
                      
                      <ListItemText
                        primary={media.alt || 'Untitled'}
                        secondary={`${media.type} - Order: ${media.order}${media.isMain ? ' (Main)' : ''}`}
                      />
                      
                      <ListItemSecondaryAction>
                        <IconButton onClick={() => handleEditMedia(media)}>
                          <EditIcon />
                        </IconButton>
                        <IconButton onClick={() => handleDeleteMedia(media.id)} color="error">
                          <DeleteIcon />
                        </IconButton>
                      </ListItemSecondaryAction>
                    </Box>
                  </ListItem>
                ))}
                
                {formData.media.length === 0 && (
                  <ListItem>
                    <ListItemText
                      primary="No media added"
                      secondary="Click 'Add Media' to upload images or videos"
                    />
                  </ListItem>
                )}
              </List>
            </Box>
          </TabPanel>

          <Divider sx={{ my: 3 }} />

          <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2, p: 3 }}>
            <Button
              variant="outlined"
              onClick={() => navigate('/posts')}
              disabled={saving}
            >
              Cancel
            </Button>
            <Button
              variant="outlined"
              onClick={() => handleSave(false)}
              disabled={saving}
              startIcon={<SaveIcon />}
            >
              Save Draft
            </Button>
            <Button
              variant="contained"
              onClick={() => handleSave(true)}
              disabled={saving}
              startIcon={<PublishIcon />}
            >
              {isEditing ? 'Update & Publish' : 'Publish'}
            </Button>
          </Box>
        </Paper>
      </Box>

      {/* Media Dialog */}
      <Dialog
        open={mediaDialogOpen}
        onClose={() => setMediaDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          {editingMedia ? 'Edit Media' : 'Add Media'}
        </DialogTitle>
        <DialogContent>
          <MediaForm
            media={editingMedia}
            onSave={handleSaveMedia}
            onCancel={() => setMediaDialogOpen(false)}
          />
        </DialogContent>
      </Dialog>
    </Container>
  );
};

// Media Form Component
interface MediaFormProps {
  media: PostMedia | null;
  onSave: (media: PostMedia) => void;
  onCancel: () => void;
}

const MediaForm: React.FC<MediaFormProps> = ({ media, onSave, onCancel }) => {
  const [formData, setFormData] = useState({
    url: media?.url || '',
    type: media?.type || 'image' as 'image' | 'video',
    alt: media?.alt || '',
    caption: media?.caption || '',
    order: media?.order || 0,
    isMain: media?.isMain || false,
  });

  const handleSave = () => {
    if (!formData.url.trim()) {
      alert('URL is required');
      return;
    }

    const mediaData: PostMedia = {
      id: media?.id || Date.now().toString(),
      url: formData.url,
      type: formData.type,
      alt: formData.alt,
      caption: formData.caption,
      order: formData.order,
      isMain: formData.isMain,
      createdAt: now(),
    };

    onSave(mediaData);
  };

  return (
    <Box sx={{ pt: 1 }}>
      <TextField
        fullWidth
        label="Media URL"
        value={formData.url}
        onChange={(e) => setFormData(prev => ({ ...prev, url: e.target.value }))}
        margin="normal"
        required
      />

      <FormControl fullWidth margin="normal">
        <InputLabel>Type</InputLabel>
        <Select
          value={formData.type}
          onChange={(e) => setFormData(prev => ({ ...prev, type: e.target.value as 'image' | 'video' }))}
          label="Type"
        >
          <MenuItem value="image">Image</MenuItem>
          <MenuItem value="video">Video</MenuItem>
        </Select>
      </FormControl>

      <TextField
        fullWidth
        label="Alt Text"
        value={formData.alt}
        onChange={(e) => setFormData(prev => ({ ...prev, alt: e.target.value }))}
        margin="normal"
      />

      <TextField
        fullWidth
        label="Caption"
        value={formData.caption}
        onChange={(e) => setFormData(prev => ({ ...prev, caption: e.target.value }))}
        margin="normal"
        multiline
        rows={2}
      />

      <TextField
        fullWidth
        label="Display Order"
        type="number"
        value={formData.order}
        onChange={(e) => setFormData(prev => ({ ...prev, order: parseInt(e.target.value) }))}
        margin="normal"
      />

      <FormControlLabel
        control={
          <Switch
            checked={formData.isMain}
            onChange={(e) => setFormData(prev => ({ ...prev, isMain: e.target.checked }))}
          />
        }
        label="Set as Main Media"
        sx={{ mt: 2 }}
      />

      <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2, mt: 3 }}>
        <Button onClick={onCancel}>
          Cancel
        </Button>
        <Button onClick={handleSave} variant="contained">
          Save
        </Button>
      </Box>
    </Box>
  );
}; 