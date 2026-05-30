import React from 'react';
import {
  Box,
  CircularProgress,
  Typography,
  useTheme,
  useMediaQuery,
  Paper,
  Fade,
  Grow,
  Card,
  CardContent,
} from '@mui/material';
import { PayspinColors } from '../../theme/theme';

interface LoadingSpinnerProps {
  message?: string;
  size?: 'small' | 'medium' | 'large';
  fullScreen?: boolean;
  overlay?: boolean;
  variant?: 'default' | 'gradient' | 'minimal';
  showProgress?: boolean;
  progress?: number;
}

export const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  message = 'Loading...',
  size = 'medium',
  fullScreen = false,
  overlay = false,
  variant = 'default',
  showProgress = false,
  progress = 0,
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  const getSize = () => {
    switch (size) {
      case 'small':
        return { xs: 24, sm: 32 };
      case 'large':
        return { xs: 48, sm: 64 };
      default:
        return { xs: 32, sm: 40 };
    }
  };

  const getMessageSize = () => {
    switch (size) {
      case 'small':
        return { xs: '0.75rem', sm: '0.875rem' };
      case 'large':
        return { xs: '1rem', sm: '1.125rem' };
      default:
        return { xs: '0.875rem', sm: '1rem' };
    }
  };

  const spinnerSize = getSize();
  const messageSize = getMessageSize();

  const renderSpinner = () => {
    switch (variant) {
      case 'gradient':
        return (
          <CircularProgress
            size={isMobile ? spinnerSize.xs : spinnerSize.sm}
            sx={{
              color: PayspinColors.primary,
              '& .MuiCircularProgress-circle': {
                strokeLinecap: 'round',
                strokeWidth: 3,
              },
            }}
          />
        );
      
      case 'minimal':
        return (
          <Box
            sx={{
              width: isMobile ? spinnerSize.xs : spinnerSize.sm,
              height: isMobile ? spinnerSize.xs : spinnerSize.sm,
              border: `3px solid ${PayspinColors.gray[200]}`,
              borderTop: `3px solid ${PayspinColors.primary}`,
              borderRadius: '50%',
              animation: 'spin 1s linear infinite',
              '@keyframes spin': {
                '0%': { transform: 'rotate(0deg)' },
                '100%': { transform: 'rotate(360deg)' },
              },
            }}
          />
        );
      
      default:
        return (
          <CircularProgress
            size={isMobile ? spinnerSize.xs : spinnerSize.sm}
            sx={{
              color: PayspinColors.primary,
              '& .MuiCircularProgress-circle': {
                strokeLinecap: 'round',
                strokeWidth: 3,
              },
            }}
          />
        );
    }
  };

  const content = (
    <Grow in={true} timeout={800}>
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 2,
          p: { xs: 2, sm: 3 },
          textAlign: 'center',
        }}
      >
        {renderSpinner()}
        
        {message && (
          <Fade in={true} timeout={1000}>
            <Typography
              variant="body2"
              color={variant === 'gradient' ? 'text.primary' : 'text.secondary'}
              sx={{
                fontSize: messageSize,
                fontWeight: 500,
                maxWidth: { xs: 200, sm: 300 },
                lineHeight: 1.4,
                opacity: variant === 'gradient' ? 0.9 : 0.8,
              }}
            >
              {message}
            </Typography>
          </Fade>
        )}

        {showProgress && progress !== undefined && (
          <Fade in={true} timeout={1200}>
            <Box sx={{ width: '100%', maxWidth: 200 }}>
              <Box
                sx={{
                  width: '100%',
                  height: 4,
                  backgroundColor: PayspinColors.gray[200],
                  borderRadius: 2,
                  overflow: 'hidden',
                  position: 'relative',
                }}
              >
                <Box
                  sx={{
                    width: `${progress}%`,
                    height: '100%',
                    background: variant === 'gradient' ? PayspinColors.gradient : PayspinColors.primary,
                    borderRadius: 2,
                    transition: 'width 0.3s ease',
                    position: 'relative',
                    '&::after': {
                      content: '""',
                      position: 'absolute',
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent)',
                      animation: 'shimmer 2s infinite',
                      '@keyframes shimmer': {
                        '0%': { transform: 'translateX(-100%)' },
                        '100%': { transform: 'translateX(100%)' },
                      },
                    },
                  }}
                />
              </Box>
              <Typography
                variant="caption"
                color="text.secondary"
                sx={{ mt: 0.5, fontSize: '0.75rem' }}
              >
                {progress}% complete
              </Typography>
            </Box>
          </Fade>
        )}
      </Box>
    </Grow>
  );

  if (fullScreen) {
    return (
      <Box
        sx={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: overlay ? 'rgba(255, 255, 255, 0.9)' : 'background.default',
          zIndex: theme.zIndex.modal + 1,
          backdropFilter: overlay ? 'blur(4px)' : 'none',
        }}
      >
        <Paper
          elevation={overlay ? 8 : 0}
          sx={{
            borderRadius: 3,
            backgroundColor: overlay ? 'background.paper' : 'transparent',
            boxShadow: overlay ? '0px 8px 32px rgba(0, 0, 0, 0.12)' : 'none',
          }}
        >
          {content}
        </Paper>
      </Box>
    );
  }

  if (overlay) {
    return (
      <Box
        sx={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: 'rgba(255, 255, 255, 0.9)',
          backdropFilter: 'blur(4px)',
          borderRadius: 2,
          zIndex: 1,
        }}
      >
        <Paper
          elevation={4}
          sx={{
            borderRadius: 2,
            backgroundColor: 'background.paper',
            boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.08)',
          }}
        >
          {content}
        </Paper>
      </Box>
    );
  }

  return (
    <Box
      sx={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: { xs: 120, sm: 160 },
        width: '100%',
      }}
    >
      {content}
    </Box>
  );
};

// Skeleton loading component for content
export const SkeletonLoader: React.FC<{
  variant?: 'text' | 'circular' | 'rectangular';
  width?: string | number;
  height?: string | number;
  count?: number;
}> = ({ variant = 'rectangular', width = '100%', height = 20, count = 1 }) => {
  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
      {Array.from({ length: count }).map((_, index) => (
        <Box
          key={index}
          sx={{
            width,
            height,
            backgroundColor: 'grey.200',
            borderRadius: variant === 'circular' ? '50%' : 1,
            animation: 'pulse 1.5s ease-in-out infinite',
            '@keyframes pulse': {
              '0%': {
                opacity: 1,
              },
              '50%': {
                opacity: 0.5,
              },
              '100%': {
                opacity: 1,
              },
            },
          }}
        />
      ))}
    </Box>
  );
};

// Card skeleton loader
export const CardSkeleton: React.FC<{
  height?: number;
  showAvatar?: boolean;
  lines?: number;
}> = ({ height = 120, showAvatar = false, lines = 2 }) => {
  return (
    <Box
      sx={{
        p: { xs: 2, sm: 3 },
        height,
        display: 'flex',
        flexDirection: 'column',
        gap: 2,
      }}
    >
      {showAvatar && (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Box
            sx={{
              width: { xs: 40, sm: 48 },
              height: { xs: 40, sm: 48 },
              borderRadius: '50%',
              backgroundColor: 'grey.200',
              animation: 'pulse 1.5s ease-in-out infinite',
            }}
          />
          <Box sx={{ flex: 1 }}>
            <Box
              sx={{
                width: '60%',
                height: 16,
                backgroundColor: 'grey.200',
                borderRadius: 1,
                mb: 1,
                animation: 'pulse 1.5s ease-in-out infinite',
              }}
            />
            <Box
              sx={{
                width: '40%',
                height: 12,
                backgroundColor: 'grey.200',
                borderRadius: 1,
                animation: 'pulse 1.5s ease-in-out infinite',
              }}
            />
          </Box>
        </Box>
      )}
      
      {Array.from({ length: lines }).map((_, index) => (
        <Box
          key={index}
          sx={{
            width: index === 0 ? '100%' : `${80 - index * 20}%`,
            height: 16,
            backgroundColor: 'grey.200',
            borderRadius: 1,
            animation: 'pulse 1.5s ease-in-out infinite',
          }}
        />
      ))}
    </Box>
  );
};

export default LoadingSpinner; 