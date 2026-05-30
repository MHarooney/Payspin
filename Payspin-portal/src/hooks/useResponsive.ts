import { useMediaQuery, useTheme } from '@mui/material';

export interface ResponsiveBreakpoints {
  isXs: boolean;
  isSm: boolean;
  isMd: boolean;
  isLg: boolean;
  isXl: boolean;
  isMobile: boolean;
  isTablet: boolean;
  isDesktop: boolean;
  isLargeScreen: boolean;
}

export const useResponsive = (): ResponsiveBreakpoints => {
  const theme = useTheme();
  
  const isXs = useMediaQuery(theme.breakpoints.only('xs'));
  const isSm = useMediaQuery(theme.breakpoints.only('sm'));
  const isMd = useMediaQuery(theme.breakpoints.only('md'));
  const isLg = useMediaQuery(theme.breakpoints.only('lg'));
  const isXl = useMediaQuery(theme.breakpoints.up('xl'));
  
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const isTablet = useMediaQuery(theme.breakpoints.between('md', 'lg'));
  const isDesktop = useMediaQuery(theme.breakpoints.up('lg'));
  const isLargeScreen = useMediaQuery(theme.breakpoints.up('xl'));

  return {
    isXs,
    isSm,
    isMd,
    isLg,
    isXl,
    isMobile,
    isTablet,
    isDesktop,
    isLargeScreen,
  };
};

export const useIsMobile = (): boolean => {
  const theme = useTheme();
  return useMediaQuery(theme.breakpoints.down('md'));
};

export const useIsTablet = (): boolean => {
  const theme = useTheme();
  return useMediaQuery(theme.breakpoints.between('md', 'lg'));
};

export const useIsDesktop = (): boolean => {
  const theme = useTheme();
  return useMediaQuery(theme.breakpoints.up('lg'));
};

export const useIsLargeScreen = (): boolean => {
  const theme = useTheme();
  return useMediaQuery(theme.breakpoints.up('xl'));
};

// Hook for touch device detection
export const useIsTouchDevice = (): boolean => {
  const theme = useTheme();
  return useMediaQuery('(hover: none) and (pointer: coarse)');
};

// Hook for reduced motion preference
export const usePrefersReducedMotion = (): boolean => {
  const theme = useTheme();
  return useMediaQuery('(prefers-reduced-motion: reduce)');
};

// Hook for high contrast preference
export const usePrefersHighContrast = (): boolean => {
  const theme = useTheme();
  return useMediaQuery('(prefers-contrast: high)');
};

// Hook for dark mode preference
export const usePrefersDarkMode = (): boolean => {
  const theme = useTheme();
  return useMediaQuery('(prefers-color-scheme: dark)');
};

// Utility function to get responsive spacing
export const getResponsiveSpacing = (
  mobile: number,
  tablet: number = mobile,
  desktop: number = tablet
): number => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const isTablet = useMediaQuery(theme.breakpoints.between('md', 'lg'));
  
  if (isMobile) return mobile;
  if (isTablet) return tablet;
  return desktop;
};

// Utility function to get responsive font size
export const getResponsiveFontSize = (
  mobile: string,
  tablet: string = mobile,
  desktop: string = tablet
): string => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const isTablet = useMediaQuery(theme.breakpoints.between('md', 'lg'));
  
  if (isMobile) return mobile;
  if (isTablet) return tablet;
  return desktop;
};

// Utility function to get responsive padding/margin
export const getResponsiveSx = (
  mobile: any,
  tablet?: any,
  desktop?: any
): any => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const isTablet = useMediaQuery(theme.breakpoints.between('md', 'lg'));
  
  if (isMobile) return mobile;
  if (isTablet) return tablet || mobile;
  return desktop || tablet || mobile;
}; 