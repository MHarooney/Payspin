import React from 'react';
import {
  Button,
  Box,
  Typography,
  useTheme,
  useMediaQuery,
  Grow,
  SxProps,
  Theme,
} from '@mui/material';
import { PayspinColors } from '../../theme/theme';

interface GradientButtonProps {
  onClick: () => void;
  disabled?: boolean;
  loading?: boolean;
  text: string;
  icon?: React.ReactNode;
  size?: 'small' | 'medium' | 'large';
  variant?: 'primary' | 'secondary';
  fullWidth?: boolean;
  sx?: SxProps<Theme>;
  startIcon?: React.ReactNode;
  endIcon?: React.ReactNode;
}

export const GradientButton: React.FC<GradientButtonProps> = ({
  onClick,
  disabled = false,
  loading = false,
  text,
  icon,
  size = 'medium',
  variant = 'primary',
  fullWidth = false,
  sx = {},
  startIcon,
  endIcon,
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  // Size configurations
  const sizeConfig = {
    small: {
      padding: '8px 16px',
      minWidth: 100,
      height: 36,
      fontSize: '0.75rem',
      iconSize: 16,
    },
    medium: {
      padding: '12px 20px',
      minWidth: 140,
      height: 48,
      fontSize: '0.875rem',
      iconSize: 20,
    },
    large: {
      padding: '16px 28px',
      minWidth: 160,
      height: 56,
      fontSize: '1rem',
      iconSize: 24,
    },
  };

  const config = sizeConfig[size];

  // Gradient configurations
  const gradientConfig = {
    primary: {
      background: PayspinColors.gradient,
      shadow: '0px 4px 16px rgba(252, 0, 255, 0.2)',
      hoverShadow: '0px 6px 24px rgba(252, 0, 255, 0.3)',
    },
    secondary: {
      background: 'linear-gradient(90deg, #5C7AEA 0%, #07D8DD 50%)',
      shadow: '0px 4px 16px rgba(92, 122, 234, 0.2)',
      hoverShadow: '0px 6px 24px rgba(92, 122, 234, 0.3)',
    },
  };

  const gradient = gradientConfig[variant];

  return (
    <Grow in={true} timeout={800}>
      <Box
        sx={{
          position: 'relative',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          width: fullWidth ? '100%' : 'auto',
        }}
      >
        {/* Subtle Background Glow */}
        <Box
          sx={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: gradient.background,
            borderRadius: 3,
            opacity: 0.05,
            filter: 'blur(12px)',
            transform: 'scale(1.1)',
          }}
        />

        {/* Main Button */}
        <Button
          onClick={onClick}
          disabled={disabled || loading}
          variant="contained"
          size={size}
          startIcon={startIcon}
          endIcon={endIcon}
          fullWidth={fullWidth}
          sx={{
            position: 'relative',
            background: gradient.background,
            backgroundSize: '200% 200%',
            color: PayspinColors.white,
            fontWeight: 700,
            fontSize: isMobile ? config.fontSize : config.fontSize,
            padding: isMobile ? config.padding : config.padding,
            borderRadius: 3,
            minWidth: isMobile ? config.minWidth * 0.8 : config.minWidth,
            height: isMobile ? config.height * 0.9 : config.height,
            boxShadow: gradient.shadow,
            border: '2px solid transparent',
            backgroundClip: 'padding-box',
            transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
            textTransform: 'none',
            letterSpacing: '0.5px',
            
            // Hover effects
            '&:hover': {
              background: gradient.background,
              boxShadow: gradient.hoverShadow,
              transform: 'translateY(-1px)',
              '& .MuiButton-startIcon': {
                transform: 'scale(1.05)',
              },
            },
            
            // Active state
            '&:active': {
              transform: 'translateY(0px)',
              boxShadow: gradient.shadow,
            },
            
            // Disabled state
            '&:disabled': {
              background: PayspinColors.gray[300],
              color: PayspinColors.gray[500],
              boxShadow: 'none',
              transform: 'none',
            },
            
            // Focus state
            '&:focus-visible': {
              outline: `3px solid ${PayspinColors.primary}`,
              outlineOffset: '2px',
            },
            

            
            // Responsive adjustments
            [theme.breakpoints.down('sm')]: {
              minWidth: config.minWidth * 0.7,
              padding: `8px ${size === 'large' ? '20px' : '16px'}`,
              fontSize: size === 'large' ? '0.875rem' : config.fontSize,
            },
            
            // Custom styles
            ...sx,
          }}
        >
          <Typography
            component="span"
            sx={{
              fontWeight: 700,
              fontSize: 'inherit',
              lineHeight: 1.2,
            }}
          >
            {loading ? 'Creating...' : text}
          </Typography>
        </Button>


      </Box>
    </Grow>
  );
}; 