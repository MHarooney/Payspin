import React, { useState, useEffect } from 'react';
import {
  Box,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Button,
  Chip,
  OutlinedInput,
  SelectChangeEvent,
  Autocomplete,
  CircularProgress,
  Alert,
  Paper,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Stack,
  useTheme,
  useMediaQuery,
  Typography,
  IconButton,
} from '@mui/material';
import {
  Search as SearchIcon,
  Clear as ClearIcon,
  FilterList as FilterIcon,
  Category as CategoryIcon,
  ExpandMore as ExpandMoreIcon,
} from '@mui/icons-material';
import { TableState } from '../../types/firestore';
import { usePostTypes } from '../../hooks/usePostTypes';
import { useNavigate } from 'react-router-dom';
import CountrySelect from '../Common/CountrySelect';
import { PayspinColors } from '../../theme/theme';

interface PostFiltersProps {
  tableState: TableState;
  onFilterChange: (newState: Partial<TableState>) => void;
}

interface Filters {
  search: string;
  postType: string;
  postSubtype: string;
  location: string;
  status: string;
  featured: string;
}

export const PostFilters: React.FC<PostFiltersProps> = ({
  tableState,
  onFilterChange,
}) => {
  const navigate = useNavigate();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const { postTypes, getSubtypesByType, loading: typesLoading, error: typesError } = usePostTypes();
  
  const [filters, setFilters] = useState<Filters>({
    search: tableState.search || '',
    postType: (tableState.filters?.postType as string) || '',
    postSubtype: (tableState.filters?.postSubtype as string) || '',
    location: (tableState.filters?.location as string) || '',
    status: (tableState.filters?.status as string) || '',
    featured: tableState.filters?.featured !== undefined ? 
              String(tableState.filters.featured) : '',
  });

  const [showAdvanced, setShowAdvanced] = useState(false);
  const [showFilters, setShowFilters] = useState(false);

  // Update filters when tableState changes (for type-specific tabs)
  useEffect(() => {
    setFilters(prev => ({
      ...prev,
      postType: (tableState.filters?.postType as string) || '',
      postSubtype: (tableState.filters?.postSubtype as string) || '',
      location: (tableState.filters?.location as string) || '',
      status: (tableState.filters?.status as string) || '',
      featured: tableState.filters?.featured !== undefined ? 
                String(tableState.filters.featured) : '',
    }));
  }, [tableState.filters]);

  const handleFilterChange = (field: keyof Filters, value: string) => {
    const newFilters = { ...filters, [field]: value };
    
    // Clear subtype when post type changes
    if (field === 'postType' && value !== filters.postType) {
      newFilters.postSubtype = '';
    }
    
    setFilters(newFilters);

    // Update table state
    const newTableState: Partial<TableState> = {
      page: 1, // Reset to first page when filters change
    };

    // Add search to table state
    if (newFilters.search) {
      newTableState.search = newFilters.search;
    }

    // Add filters to table state
    if (Object.values(newFilters).some(v => v && v !== newFilters.search)) {
      newTableState.filters = {
        ...tableState.filters,
        postType: newFilters.postType || undefined,
        postSubtype: newFilters.postSubtype || undefined,
        location: newFilters.location || undefined,
        status: newFilters.status || undefined,
        featured: newFilters.featured === 'true' ? true : 
                  newFilters.featured === 'false' ? false : undefined,
      };
    }

    onFilterChange(newTableState);
  };

  const clearFilters = () => {
    const clearedFilters = {
      search: '',
      postType: '',
      postSubtype: '',
      location: '',
      status: '',
      featured: '',
    };
    setFilters(clearedFilters);
    onFilterChange({
      page: 1,
      search: '',
      filters: {},
    });
  };

  const getAvailableSubtypes = () => {
    if (!filters.postType) return [];
    return getSubtypesByType(filters.postType);
  };

  const hasActiveFilters = () => {
    return Object.values(filters).some(value => value !== '');
  };

  const getTypeLabelByName = (typeName: string) => {
    const type = postTypes.find(t => t.name === typeName);
    return type?.label || typeName;
  };

  const getSubtypeLabelByName = (subtypeName: string) => {
    const subtypes = getAvailableSubtypes();
    const subtype = subtypes.find(s => s.name === subtypeName);
    return subtype?.label || subtypeName;
  };

  // Show error state if types failed to load
  if (typesError) {
    return (
      <Box sx={{ mb: 3 }}>
        <Alert 
          severity="error" 
          action={
            <Button 
              color="inherit" 
              size="small"
              onClick={() => navigate('/post-types')}
              startIcon={<CategoryIcon />}
              sx={{ borderRadius: 2 }}
            >
              Manage Types
            </Button>
          }
          sx={{ borderRadius: 2 }}
        >
          Failed to load post types: {typesError}
        </Alert>
      </Box>
    );
  }

  // Mobile Accordion View
  if (isMobile) {
    return (
      <Paper sx={{ mb: 3, borderRadius: 2, overflow: 'hidden' }}>
        <Accordion
          expanded={showFilters}
          onChange={() => setShowFilters(!showFilters)}
          sx={{ 
            '&:before': { display: 'none' },
            boxShadow: 'none',
          }}
        >
          <AccordionSummary
            expandIcon={<ExpandMoreIcon />}
            sx={{
              px: 2,
              py: 1,
              '& .MuiAccordionSummary-content': {
                margin: 0,
              },
            }}
          >
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flex: 1 }}>
              <FilterIcon sx={{ fontSize: 20 }} />
              <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                Filters
              </Typography>
              {hasActiveFilters() && (
                <Chip
                  label="Active"
                  sx={{ 
                    height: 20, 
                    fontSize: '0.625rem',
                    bgcolor: PayspinColors.primary,
                    color: 'white',
                    '& .MuiChip-label': {
                      color: 'white',
                    },
                  }}
                />
              )}
            </Box>
          </AccordionSummary>
          
          <AccordionDetails sx={{ px: 2, pb: 2 }}>
            <Stack spacing={2}>
              {/* Search */}
              <TextField
                fullWidth
                placeholder="Search posts..."
                value={filters.search}
                onChange={(e) => handleFilterChange('search', e.target.value)}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                  sx: { borderRadius: 2 },
                }}
                size="small"
              />

              {/* Post Type */}
              <FormControl fullWidth size="small">
                <InputLabel>Type</InputLabel>
                <Select
                  value={filters.postType}
                  onChange={(e) => handleFilterChange('postType', e.target.value)}
                  label="Type"
                  disabled={typesLoading}
                  sx={{ borderRadius: 2 }}
                >
                  <MenuItem value="">All Types</MenuItem>
                  {postTypes.map((type) => (
                    <MenuItem key={type.id} value={type.name}>
                      {type.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              {/* Post Subtype */}
              {filters.postType && (
                <FormControl fullWidth size="small">
                  <InputLabel>Subtype</InputLabel>
                  <Select
                    value={filters.postSubtype}
                    onChange={(e) => handleFilterChange('postSubtype', e.target.value)}
                    label="Subtype"
                    sx={{ borderRadius: 2 }}
                  >
                    <MenuItem value="">All Subtypes</MenuItem>
                    {getAvailableSubtypes().map((subtype) => (
                      <MenuItem key={subtype.id} value={subtype.name}>
                        {subtype.label}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              )}

              {/* Location */}
              <CountrySelect
                value={filters.location}
                onChange={(value) => handleFilterChange('location', value)}
                placeholder="All Locations"
                size="small"
              />

              {/* Status */}
              <FormControl fullWidth size="small">
                <InputLabel>Status</InputLabel>
                <Select
                  value={filters.status}
                  onChange={(e) => handleFilterChange('status', e.target.value)}
                  label="Status"
                  sx={{ borderRadius: 2 }}
                >
                  <MenuItem value="">All Status</MenuItem>
                  <MenuItem value="published">Published</MenuItem>
                  <MenuItem value="draft">Draft</MenuItem>
                  <MenuItem value="archived">Archived</MenuItem>
                </Select>
              </FormControl>

              {/* Featured */}
              <FormControl fullWidth size="small">
                <InputLabel>Featured</InputLabel>
                <Select
                  value={filters.featured}
                  onChange={(e) => handleFilterChange('featured', e.target.value)}
                  label="Featured"
                  sx={{ borderRadius: 2 }}
                >
                  <MenuItem value="">All Posts</MenuItem>
                  <MenuItem value="true">Featured Only</MenuItem>
                  <MenuItem value="false">Not Featured</MenuItem>
                </Select>
              </FormControl>

              {/* Action Buttons */}
              <Stack direction="row" spacing={1}>
                <Button
                  variant="contained"
                  onClick={() => setShowFilters(false)}
                  sx={{ flex: 1, borderRadius: 2 }}
                >
                  Apply
                </Button>
                {hasActiveFilters() && (
                  <Button
                    variant="outlined"
                    onClick={clearFilters}
                    startIcon={<ClearIcon />}
                    sx={{ borderRadius: 2 }}
                  >
                    Clear
                  </Button>
                )}
              </Stack>
            </Stack>
          </AccordionDetails>
        </Accordion>
      </Paper>
    );
  }

  // Desktop View
  return (
    <Paper sx={{ p: 3, mb: 3, borderRadius: 2 }}>
      <Grid container spacing={2} alignItems="flex-end">
        {/* Search Field */}
        <Grid item xs={12} md={4}>
          <TextField
            fullWidth
            placeholder="Search posts..."
            value={filters.search}
            onChange={(e) => handleFilterChange('search', e.target.value)}
            InputProps={{
              startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
              sx: { borderRadius: 2 },
            }}
            size="small"
          />
        </Grid>

        {/* Basic Filters */}
        <Grid item xs={12} md={8}>
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'flex-end', flexWrap: 'wrap' }}>
            <FormControl size="small" sx={{ minWidth: 140 }}>
              <InputLabel>Type</InputLabel>
              <Select
                value={filters.postType}
                onChange={(e) => handleFilterChange('postType', e.target.value)}
                label="Type"
                disabled={typesLoading}
                sx={{ borderRadius: 2 }}
              >
                <MenuItem value="">All Types</MenuItem>
                {postTypes.map((type) => (
                  <MenuItem key={type.id} value={type.name}>
                    {type.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            {filters.postType && (
              <FormControl size="small" sx={{ minWidth: 140 }}>
                <InputLabel>Subtype</InputLabel>
                <Select
                  value={filters.postSubtype}
                  onChange={(e) => handleFilterChange('postSubtype', e.target.value)}
                  label="Subtype"
                  sx={{ borderRadius: 2 }}
                >
                  <MenuItem value="">All Subtypes</MenuItem>
                  {getAvailableSubtypes().map((subtype) => (
                    <MenuItem key={subtype.id} value={subtype.name}>
                      {subtype.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            )}

            <Box sx={{ minWidth: 200 }}>
              <CountrySelect
                value={filters.location}
                onChange={(value) => handleFilterChange('location', value)}
                placeholder="All Locations"
                size="small"
              />
            </Box>

            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Status</InputLabel>
              <Select
                value={filters.status}
                onChange={(e) => handleFilterChange('status', e.target.value)}
                label="Status"
                sx={{ borderRadius: 2 }}
              >
                <MenuItem value="">All Status</MenuItem>
                <MenuItem value="published">Published</MenuItem>
                <MenuItem value="draft">Draft</MenuItem>
                <MenuItem value="archived">Archived</MenuItem>
              </Select>
            </FormControl>

            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Featured</InputLabel>
              <Select
                value={filters.featured}
                onChange={(e) => handleFilterChange('featured', e.target.value)}
                label="Featured"
                sx={{ borderRadius: 2 }}
              >
                <MenuItem value="">All Posts</MenuItem>
                <MenuItem value="true">Featured Only</MenuItem>
                <MenuItem value="false">Not Featured</MenuItem>
              </Select>
            </FormControl>

            {/* Clear Filters Button */}
            {hasActiveFilters() && (
              <Button
                variant="outlined"
                onClick={clearFilters}
                startIcon={<ClearIcon />}
                sx={{ borderRadius: 2 }}
              >
                Clear Filters
              </Button>
            )}
          </Box>
        </Grid>
      </Grid>

      {/* Active Filters Display */}
      {hasActiveFilters() && (
        <Box sx={{ mt: 2, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          {filters.search && (
            <Chip
              label={`Search: ${filters.search}`}
              onDelete={() => handleFilterChange('search', '')}
              size="small"
              color="primary"
              variant="outlined"
            />
          )}
          {filters.postType && (
            <Chip
              label={`Type: ${getTypeLabelByName(filters.postType)}`}
              onDelete={() => handleFilterChange('postType', '')}
              size="small"
              color="primary"
              variant="outlined"
            />
          )}
          {filters.postSubtype && (
            <Chip
              label={`Subtype: ${getSubtypeLabelByName(filters.postSubtype)}`}
              onDelete={() => handleFilterChange('postSubtype', '')}
              size="small"
              color="primary"
              variant="outlined"
            />
          )}
          {filters.location && (
            <Chip
              label={`Location: ${filters.location}`}
              onDelete={() => handleFilterChange('location', '')}
              size="small"
              color="primary"
              variant="outlined"
            />
          )}
          {filters.status && (
            <Chip
              label={`Status: ${filters.status}`}
              onDelete={() => handleFilterChange('status', '')}
              size="small"
              color="primary"
              variant="outlined"
            />
          )}
          {filters.featured && (
            <Chip
              label={`Featured: ${filters.featured === 'true' ? 'Yes' : 'No'}`}
              onDelete={() => handleFilterChange('featured', '')}
              size="small"
              color="primary"
              variant="outlined"
            />
          )}
        </Box>
      )}
    </Paper>
  );
}; 