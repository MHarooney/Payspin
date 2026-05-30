import React, { useState, useMemo } from 'react';
import {
  Autocomplete,
  TextField,
  Box,
  Typography,
  Chip,
  CircularProgress,
} from '@mui/material';
import { countries, Country, searchCountries } from '../../data/countries';

interface CountrySelectProps {
  value: string;
  onChange: (value: string) => void;
  label?: string;
  placeholder?: string;
  error?: boolean;
  helperText?: string;
  disabled?: boolean;
  required?: boolean;
  size?: 'small' | 'medium';
  fullWidth?: boolean;
  sx?: any;
}

export const CountrySelect: React.FC<CountrySelectProps> = ({
  value,
  onChange,
  label = 'Country',
  placeholder = 'Search for a country...',
  error = false,
  helperText,
  disabled = false,
  required = false,
  size = 'medium',
  fullWidth = true,
  sx,
}) => {
  const [inputValue, setInputValue] = useState('');
  const [open, setOpen] = useState(false);

  // Get the selected country object
  const selectedCountry = useMemo(() => {
    if (!value || value.trim() === '') return null;
    return countries.find(country => country.name === value);
  }, [value]);

  // Filter countries based on search input
  const filteredCountries = useMemo(() => {
    return searchCountries(inputValue);
  }, [inputValue]);

  const handleChange = (event: any, newValue: Country | null) => {
    onChange(newValue?.name || '');
  };

  const handleInputChange = (event: any, newInputValue: string) => {
    setInputValue(newInputValue);
  };

  return (
    <Autocomplete
      sx={sx}
      open={open}
      onOpen={() => setOpen(true)}
      onClose={() => setOpen(false)}
      value={selectedCountry}
      onChange={handleChange}
      inputValue={inputValue}
      onInputChange={handleInputChange}
      options={filteredCountries}
      getOptionLabel={(option) => option?.name || ''}
      isOptionEqualToValue={(option, value) => {
        if (!option || !value) return false;
        return option.name === value.name;
      }}
      filterOptions={(x) => x} // Disable built-in filtering since we handle it manually
      renderInput={(params) => (
        <TextField
          {...params}
          label={label}
          placeholder={placeholder}
          error={error}
          helperText={helperText}
          required={required}
          size={size}
          fullWidth={fullWidth}
          InputProps={{
            ...params.InputProps,
            endAdornment: (
              <>
                {open && <CircularProgress color="inherit" size={20} />}
                {params.InputProps.endAdornment}
              </>
            ),
          }}
        />
      )}
      renderOption={(props, option) => (
        <Box component="li" {...props}>
          <Box sx={{ display: 'flex', alignItems: 'center', width: '100%' }}>
            <Typography variant="body2" sx={{ flexGrow: 1 }}>
              {option.name}
            </Typography>
            <Chip
              label={option.code}
              size="small"
              variant="outlined"
              sx={{ ml: 1, fontSize: '0.75rem' }}
            />
          </Box>
        </Box>
      )}
      renderTags={(value, getTagProps) =>
        value.map((option, index) => (
          <Chip
            {...getTagProps({ index })}
            key={option.code}
            label={option.name}
            size="small"
          />
        ))
      }
      noOptionsText="No countries found"
      loading={false}
      disabled={disabled}
      clearOnBlur={false}
      selectOnFocus
      clearOnEscape
      blurOnSelect
    />
  );
};

export default CountrySelect; 