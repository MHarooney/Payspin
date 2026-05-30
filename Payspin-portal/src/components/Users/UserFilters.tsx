import React, { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  useTheme,
  useMediaQuery,
  Stack,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Typography,
  IconButton,
  Collapse,
  Paper,
} from '@mui/material';
import {
  Search as SearchIcon,
  FilterList as FilterIcon,
  Clear as ClearIcon,
  ExpandMore as ExpandMoreIcon,
} from '@mui/icons-material';
import { UserTableState } from '../../types/firestore';

interface UserFiltersProps {
  filters: UserTableState;
  onFiltersChange: (filters: UserTableState) => void;
  onClearFilters: () => void;
}

export const UserFilters: React.FC<UserFiltersProps> = ({
  filters,
  onFiltersChange,
  onClearFilters,
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const [showFilters, setShowFilters] = useState(false);

  const handleFilterChange = (key: 'status' | 'role', value: any) => {
    onFiltersChange({
      ...filters,
      filters: {
        ...filters.filters,
        [key]: value,
      },
      page: 1, // Reset to first page when filters change
    });
  };

  const handleSearchChange = (value: string) => {
    onFiltersChange({
      ...filters,
      search: value,
      page: 1, // Reset to first page when search changes
    });
  };

  const handleClearFilters = () => {
    onClearFilters();
    setShowFilters(false);
  };

  const hasActiveFilters = filters.search || filters.filters?.status || filters.filters?.role;

  // Mobile Accordion View
  if (isMobile) {
    return (
      <Paper sx={{ mb: 3, borderRadius: 2 }}>
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
              {hasActiveFilters && (
                <Chip
                  label="Active"
                  color="primary"
                  size="small"
                  sx={{ height: 20, fontSize: '0.625rem' }}
                />
              )}
            </Box>
          </AccordionSummary>
          
          <AccordionDetails sx={{ px: 2, pb: 2 }}>
            <Stack spacing={2}>
              {/* Search */}
              <TextField
                fullWidth
                placeholder="Search users..."
                value={filters.search || ''}
                onChange={(e) => handleSearchChange(e.target.value)}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                  sx: { borderRadius: 2 },
                }}
                size="small"
              />

              {/* Status Filter */}
              <FormControl fullWidth size="small">
                <InputLabel>Status</InputLabel>
                <Select
                  value={filters.filters?.status || ''}
                  onChange={(e) => handleFilterChange('status', e.target.value)}
                  label="Status"
                  sx={{ borderRadius: 2 }}
                >
                  <MenuItem value="">All</MenuItem>
                  <MenuItem value="active">Active</MenuItem>
                  <MenuItem value="inactive">Inactive</MenuItem>
                </Select>
              </FormControl>

              {/* Role Filter */}
              <FormControl fullWidth size="small">
                <InputLabel>Role</InputLabel>
                <Select
                  value={filters.filters?.role || ''}
                  onChange={(e) => handleFilterChange('role', e.target.value)}
                  label="Role"
                  sx={{ borderRadius: 2 }}
                >
                  <MenuItem value="">All</MenuItem>
                  <MenuItem value="user">User</MenuItem>
                  <MenuItem value="moderator">Moderator</MenuItem>
                  <MenuItem value="admin">Admin</MenuItem>
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
                {hasActiveFilters && (
                  <Button
                    variant="outlined"
                    onClick={handleClearFilters}
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
      <Box sx={{ display: 'flex', gap: 2, alignItems: 'flex-end', flexWrap: 'wrap' }}>
        {/* Search */}
        <TextField
          placeholder="Search users..."
          value={filters.search || ''}
          onChange={(e) => handleSearchChange(e.target.value)}
          InputProps={{
            startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
            sx: { borderRadius: 2 },
          }}
          sx={{ minWidth: 250, flex: 1 }}
          size="small"
        />

        {/* Status Filter */}
        <FormControl sx={{ minWidth: 120 }} size="small">
          <InputLabel>Status</InputLabel>
          <Select
            value={filters.filters?.status || ''}
            onChange={(e) => handleFilterChange('status', e.target.value)}
            label="Status"
            sx={{ borderRadius: 2 }}
          >
            <MenuItem value="">All</MenuItem>
            <MenuItem value="active">Active</MenuItem>
            <MenuItem value="inactive">Inactive</MenuItem>
          </Select>
        </FormControl>

        {/* Role Filter */}
        <FormControl sx={{ minWidth: 120 }} size="small">
          <InputLabel>Role</InputLabel>
          <Select
            value={filters.filters?.role || ''}
            onChange={(e) => handleFilterChange('role', e.target.value)}
            label="Role"
            sx={{ borderRadius: 2 }}
          >
            <MenuItem value="">All</MenuItem>
            <MenuItem value="user">User</MenuItem>
            <MenuItem value="moderator">Moderator</MenuItem>
            <MenuItem value="admin">Admin</MenuItem>
          </Select>
        </FormControl>

        {/* Clear Filters Button */}
        {hasActiveFilters && (
          <Button
            variant="outlined"
            onClick={handleClearFilters}
            startIcon={<ClearIcon />}
            sx={{ borderRadius: 2 }}
          >
            Clear Filters
          </Button>
        )}
      </Box>

      {/* Active Filters Display */}
      {hasActiveFilters && (
        <Box sx={{ mt: 2, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          {filters.search && (
            <Chip
              label={`Search: ${filters.search}`}
              onDelete={() => handleSearchChange('')}
              size="small"
              color="primary"
              variant="outlined"
            />
          )}
          {filters.filters?.status && (
            <Chip
              label={`Status: ${filters.filters.status}`}
              onDelete={() => handleFilterChange('status', '')}
              size="small"
              color="primary"
              variant="outlined"
            />
          )}
          {filters.filters?.role && (
            <Chip
              label={`Role: ${filters.filters.role}`}
              onDelete={() => handleFilterChange('role', '')}
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