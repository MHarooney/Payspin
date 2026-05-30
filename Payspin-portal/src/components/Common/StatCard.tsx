import React from 'react';
import {
  Card,
  CardContent,
  Typography,
  Box,
  useTheme,
  useMediaQuery,
  Skeleton,
  Tooltip,
  Grow,
} from '@mui/material';
import {
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  Remove as RemoveIcon,
} from '@mui/icons-material';
import { SxProps, Theme } from '@mui/material/styles';
import { PayspinColors } from '../../theme/theme';

interface TrendData {
  value: number;
  direction: 'up' | 'down' | 'neutral';
  period?: string;
}

interface StatCardProps {
  title: string;
  value: number | string;
  subtitle?: string;
  icon?: React.ReactElement;
  color?: string;
  trend?: TrendData;
  loading?: boolean;
  onClick?: () => void;
  gradient?: boolean;
  size?: 'small' | 'medium' | 'large';
  variant?: 'default' | 'elevated' | 'outlined';
  sx?: SxProps<Theme>;
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  subtitle,
  icon,
  color = PayspinColors.primary,
  trend,
  loading = false,
  onClick,
  gradient = false,
  size = 'medium',
  variant = 'default',
  sx = {},
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  // Size configurations
  const sizeConfig = {
    small: {
      padding: '16px',
      iconSize: 32,
      titleFontSize: '0.75rem',
      valueFontSize: '1.25rem',
      subtitleFontSize: '0.625rem',
    },
    medium: {
      padding: '20px',
      iconSize: 40,
      titleFontSize: '0.875rem',
      valueFontSize: '1.5rem',
      subtitleFontSize: '0.75rem',
    },
    large: {
      padding: '24px',
      iconSize: 48,
      titleFontSize: '1rem',
      valueFontSize: '1.75rem',
      subtitleFontSize: '0.875rem',
    },
  };

  const config = sizeConfig[size];

  // Variant configurations
  const variantConfig = {
    default: {
      background: 'background.paper',
      border: 'none',
      boxShadow: '0px 2px 8px rgba(0, 0, 0, 0.06)',
    },
    elevated: {
      background: 'background.paper',
      border: 'none',
      boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.08)',
    },
    outlined: {
      background: 'background.paper',
      border: `1px solid ${PayspinColors.gray[200]}`,
      boxShadow: 'none',
    },
  };

  const variantStyle = variantConfig[variant];

  const getTrendIcon = (direction: 'up' | 'down' | 'neutral') => {
    switch (direction) {
      case 'up':
        return <TrendingUpIcon sx={{ fontSize: 16, color: PayspinColors.success }} />;
      case 'down':
        return <TrendingDownIcon sx={{ fontSize: 16, color: PayspinColors.error }} />;
      default:
        return <RemoveIcon sx={{ fontSize: 16, color: PayspinColors.gray[500] }} />;
    }
  };

  const getTrendColor = (direction: 'up' | 'down' | 'neutral') => {
    switch (direction) {
      case 'up':
        return PayspinColors.success;
      case 'down':
        return PayspinColors.error;
      default:
        return PayspinColors.gray[500];
    }
  };

  if (loading) {
    return (
      <Grow in={true} timeout={600}>
        <Card
          sx={{
            borderRadius: 3,
            background: 'background.paper',
            border: '1px solid',
            borderColor: 'divider',
            transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
            cursor: 'pointer',
            '&:hover': {
              transform: 'translateY(-2px)',
              boxShadow: '0px 8px 32px rgba(0, 0, 0, 0.12)',
            },
            ...sx,
          }}
        >
          <CardContent sx={{ p: config.padding }}>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
              <Skeleton variant="text" width="60%" height={24} />
              <Skeleton variant="circular" width={config.iconSize} height={config.iconSize} />
            </Box>
            <Skeleton variant="text" width="40%" height={32} sx={{ mb: 1 }} />
            <Skeleton variant="text" width="80%" height={20} />
          </CardContent>
        </Card>
      </Grow>
    );
  }

  return (
    <Grow in={true} timeout={600}>
      <Card
        onClick={onClick}
        sx={{
          borderRadius: 3,
          background: variantStyle.background,
          border: variantStyle.border,
          boxShadow: variantStyle.boxShadow,
          transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
          cursor: onClick ? 'pointer' : 'default',
          position: 'relative',
          overflow: 'hidden',
          height: '100%',
          '&:hover': {
            transform: onClick ? 'translateY(-4px)' : 'none',
            boxShadow: onClick ? '0px 12px 40px rgba(0, 0, 0, 0.15)' : variantStyle.boxShadow,
          },
          '&::before': gradient ? {
            content: '""',
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(255, 255, 255, 0.1)',
            opacity: 0,
            transition: 'opacity 0.3s ease',
          } : {},
          '&:hover::before': gradient ? {
            opacity: 1,
          } : {},
          ...sx,
        }}
      >
        <CardContent sx={{ p: config.padding, position: 'relative' }}>
          {/* Header with title and icon */}
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
            <Typography
              variant="body2"
              color="text.secondary"
              sx={{
                fontSize: config.titleFontSize,
                fontWeight: 600,
                opacity: 0.8,
                textTransform: 'uppercase',
                letterSpacing: '0.5px',
              }}
            >
              {title}
            </Typography>
            {icon && (
              <Box
                sx={{
                  width: config.iconSize,
                  height: config.iconSize,
                  borderRadius: 2,
                  background: `${color}12`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: color,
                  transition: 'all 0.3s ease',
                  '&:hover': {
                    transform: 'scale(1.05)',
                    background: `${color}20`,
                  },
                }}
              >
                {React.cloneElement(icon, {
                  sx: {
                    fontSize: config.iconSize * 0.6,
                  }
                })}
              </Box>
            )}
          </Box>

          {/* Main value */}
          <Typography
            variant="h4"
            component="div"
            color="text.primary"
            sx={{
              fontSize: config.valueFontSize,
              fontWeight: 700,
              mb: 1,
              lineHeight: 1.2,
              fontFamily: 'Raleway, sans-serif',
            }}
          >
            {typeof value === 'number' ? value.toLocaleString() : value}
          </Typography>

          {/* Subtitle and trend */}
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            {subtitle && (
              <Typography
                variant="body2"
                color="text.secondary"
                sx={{
                  fontSize: config.subtitleFontSize,
                  opacity: 0.7,
                  flex: 1,
                }}
              >
                {subtitle}
              </Typography>
            )}
            
            {trend && (
              <Tooltip title={`${trend.value}% ${trend.direction} ${trend.period || 'this period'}`}>
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 0.5,
                    ml: 1,
                    p: 0.5,
                    borderRadius: 1,
                    background: `${getTrendColor(trend.direction)}12`,
                    transition: 'all 0.2s ease',
                    '&:hover': {
                      background: `${getTrendColor(trend.direction)}20`,
                    },
                  }}
                >
                  {getTrendIcon(trend.direction)}
                  <Typography
                    variant="caption"
                    color={getTrendColor(trend.direction)}
                    sx={{
                      fontSize: config.subtitleFontSize,
                      fontWeight: 600,
                    }}
                  >
                    {trend.value}%
                  </Typography>
                </Box>
              </Tooltip>
            )}
          </Box>
        </CardContent>


      </Card>
    </Grow>
  );
}; 