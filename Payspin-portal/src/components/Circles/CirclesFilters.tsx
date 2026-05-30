import React, { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
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
import { Circle } from '../../types/firestore';

interface CirclesFiltersProps {
  filters: {
    status?: Circle['circle_status'];
    finished?: boolean;
    search?: string;
  };
  onFilterChange: (filters: { status?: Circle['circle_status']; finished?: boolean }) => void;
  onSearchChange: (search: string) => void;
}

export const CirclesFilters: React.FC<CirclesFiltersProps> = ({
  filters,
  onFilterChange,
  onSearchChange,
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const [showFilters, setShowFilters] = useState(false);

  const handleFilterChange = (key: 'status' | 'finished', value: any) => {
    onFilterChange({
      ...filters,
      [key]: value,
    });
  };

  const handleSearchChange = (value: string) => {
    onSearchChange(value);
  };

  const handleClearFilters = () => {
    onFilterChange({
      status: undefined,
      finished: undefined,
    });
    onSearchChange('');
    setShowFilters(false);
  };

  const hasActiveFilters = filters.search || filters.status || filters.finished;

  return (
    <Box>
      {isMobile ? (
        <Accordion
          expanded={showFilters}
          onChange={() => setShowFilters(!showFilters)}
          sx={{
            boxShadow: 'none',
            '&:before': { display: 'none' },
            bgcolor: 'transparent',
          }}
        >
          <AccordionSummary
            expandIcon={<ExpandMoreIcon />}
            sx={{ px: 2, py: 1 }}
          >
            <Stack direction="row" spacing={1} alignItems="center">
              <FilterIcon sx={{ color: 'text.secondary' }} />
              <Typography variant="subtitle1">Filters</Typography>
              {hasActiveFilters && (
                <Typography
                  variant="caption"
                  sx={{
                    bgcolor: 'primary.main',
                    color: 'primary.contrastText',
                    px: 1,
                    py: 0.5,
                    borderRadius: 1,
                  }}
                >
                  Active
                </Typography>
              )}
            </Stack>
          </AccordionSummary>
          
          <AccordionDetails sx={{ px: 2, pb: 2 }}>
            <Stack spacing={2}>
              {/* Search */}
              <TextField
                fullWidth
                placeholder="Search circles..."
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
                  value={filters.status || ''}
                  onChange={(e) => handleFilterChange('status', e.target.value)}
                  label="Status"
                  sx={{ borderRadius: 2 }}
                >
                  <MenuItem value="">All</MenuItem>
                  <MenuItem value="active">Active</MenuItem>
                  <MenuItem value="completed">Completed</MenuItem>
                  <MenuItem value="pending">Pending</MenuItem>
                  <MenuItem value="cancelled">Cancelled</MenuItem>
                </Select>
              </FormControl>

              {/* Finished Filter */}
              <FormControl fullWidth size="small">
                <InputLabel>Finished</InputLabel>
                <Select
                  value={filters.finished === undefined ? '' : filters.finished}
                  onChange={(e) => handleFilterChange('finished', e.target.value === '' ? undefined : e.target.value === 'true')}
                  label="Finished"
                  sx={{ borderRadius: 2 }}
                >
                  <MenuItem value="">All</MenuItem>
                  <MenuItem value="true">Yes</MenuItem>
                  <MenuItem value="false">No</MenuItem>
                </Select>
              </FormControl>

              {/* Action Buttons */}
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
            </Stack>
          </AccordionDetails>
        </Accordion>
      ) : (
        <Box sx={{ display: 'flex', gap: 2, alignItems: 'flex-end', flexWrap: 'wrap' }}>
          {/* Search */}
          <TextField
            placeholder="Search circles..."
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
              value={filters.status || ''}
              onChange={(e) => handleFilterChange('status', e.target.value)}
              label="Status"
              sx={{ borderRadius: 2 }}
            >
              <MenuItem value="">All</MenuItem>
              <MenuItem value="active">Active</MenuItem>
              <MenuItem value="completed">Completed</MenuItem>
              <MenuItem value="pending">Pending</MenuItem>
              <MenuItem value="cancelled">Cancelled</MenuItem>
            </Select>
          </FormControl>

          {/* Finished Filter */}
          <FormControl sx={{ minWidth: 120 }} size="small">
            <InputLabel>Finished</InputLabel>
            <Select
              value={filters.finished === undefined ? '' : filters.finished}
              onChange={(e) => handleFilterChange('finished', e.target.value === '' ? undefined : e.target.value === 'true')}
              label="Finished"
              sx={{ borderRadius: 2 }}
            >
              <MenuItem value="">All</MenuItem>
              <MenuItem value="true">Yes</MenuItem>
              <MenuItem value="false">No</MenuItem>
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
      )}
    </Box>
  );
}; 