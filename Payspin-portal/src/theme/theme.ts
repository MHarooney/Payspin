import { createTheme, ThemeOptions } from '@mui/material/styles';

// Payspin Brand Colors
export const PayspinColors = {
  primary: '#FC00FF',
  secondary: '#07D8DD',
  purple: '#8E0FF2',
  blue: '#5C7AEA',
  yellow: '#FFC408',
  gradient: 'linear-gradient(90deg, #FC00FF 0%, #07D8DD 50%)',
  white: '#FFFFFF',
  black: '#000000',
  gray: {
    50: '#F9FAFB',
    100: '#F3F4F6',
    200: '#E5E7EB',
    300: '#D1D5DB',
    400: '#9CA3AF',
    500: '#6B7280',
    600: '#4B5563',
    700: '#374151',
    800: '#1F2937',
    900: '#111827',
  },
  error: '#EF4444',
  warning: '#F59E0B',
  success: '#10B981',
  info: '#3B82F6',
  // Enhanced gradients
  gradients: {
    primary: 'linear-gradient(135deg, #07D8DD 0%, #5C7AEA 100%)',
    secondary: 'linear-gradient(135deg, #FC00FF 0%, #8E0FF2 100%)',
    success: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
    warning: 'linear-gradient(135deg, #F59E0B 0%, #D97706 100%)',
    error: 'linear-gradient(135deg, #EF4444 0%, #DC2626 100%)',
    sunset: 'linear-gradient(135deg, #FF6B6B 0%, #FFE66D 100%)',
    ocean: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    forest: 'linear-gradient(135deg, #11998e 0%, #38ef7d 100%)',
  },
};

// Enhanced breakpoints for better responsive design
const breakpoints = {
  values: {
    xs: 0,
    sm: 480,
    md: 768,
    lg: 1024,
    xl: 1200,
    xxl: 1440,
  },
};

// Responsive typography configuration
const typography = {
  fontFamily: [
    'Raleway',
    'Inter',
    '-apple-system',
    'BlinkMacSystemFont',
    '"Segoe UI"',
    'Roboto',
    '"Helvetica Neue"',
    'Arial',
    'sans-serif',
  ].join(','),
  h1: {
    fontFamily: 'Raleway, sans-serif',
    fontWeight: 800,
    fontSize: 'clamp(1.75rem, 4vw, 2.5rem)',
    lineHeight: 1.2,
    letterSpacing: '-0.02em',
  },
  h2: {
    fontFamily: 'Raleway, sans-serif',
    fontWeight: 700,
    fontSize: 'clamp(1.5rem, 3.5vw, 2rem)',
    lineHeight: 1.3,
    letterSpacing: '-0.01em',
  },
  h3: {
    fontFamily: 'Raleway, sans-serif',
    fontWeight: 600,
    fontSize: 'clamp(1.25rem, 3vw, 1.75rem)',
    lineHeight: 1.4,
  },
  h4: {
    fontFamily: 'Raleway, sans-serif',
    fontWeight: 600,
    fontSize: 'clamp(1.125rem, 2.5vw, 1.5rem)',
    lineHeight: 1.4,
  },
  h5: {
    fontFamily: 'Raleway, sans-serif',
    fontWeight: 600,
    fontSize: 'clamp(1rem, 2vw, 1.25rem)',
    lineHeight: 1.5,
  },
  h6: {
    fontFamily: 'Raleway, sans-serif',
    fontWeight: 600,
    fontSize: 'clamp(0.875rem, 1.8vw, 1rem)',
    lineHeight: 1.5,
  },
  body1: {
    fontFamily: 'Inter, sans-serif',
    fontWeight: 400,
    fontSize: 'clamp(0.875rem, 1.5vw, 1rem)',
    lineHeight: 1.6,
  },
  body2: {
    fontFamily: 'Inter, sans-serif',
    fontWeight: 400,
    fontSize: 'clamp(0.75rem, 1.3vw, 0.875rem)',
    lineHeight: 1.5,
  },
  button: {
    fontFamily: 'Raleway, sans-serif',
    fontWeight: 600,
    fontSize: 'clamp(0.875rem, 1.2vw, 1rem)',
    textTransform: 'none' as const,
    letterSpacing: '0.01em',
  },
  caption: {
    fontFamily: 'Inter, sans-serif',
    fontWeight: 400,
    fontSize: 'clamp(0.625rem, 1vw, 0.75rem)',
    lineHeight: 1.66,
  },
  overline: {
    fontFamily: 'Inter, sans-serif',
    fontWeight: 400,
    fontSize: 'clamp(0.625rem, 1vw, 0.75rem)',
    lineHeight: 2.66,
    textTransform: 'uppercase' as const,
    letterSpacing: '0.1em',
  },
  subtitle1: {
    fontFamily: 'Inter, sans-serif',
    fontWeight: 500,
    fontSize: 'clamp(0.875rem, 1.4vw, 1rem)',
    lineHeight: 1.5,
  },
  subtitle2: {
    fontFamily: 'Inter, sans-serif',
    fontWeight: 500,
    fontSize: 'clamp(0.75rem, 1.2vw, 0.875rem)',
    lineHeight: 1.5,
  },
};

// Theme configuration
const themeOptions: ThemeOptions = {
  breakpoints,
  palette: {
    mode: 'light',
    primary: {
      main: PayspinColors.primary,
      light: '#FC4DFF',
      dark: '#D900DC',
      contrastText: PayspinColors.white,
    },
    secondary: {
      main: PayspinColors.secondary,
      light: '#4FDBDF',
      dark: '#05B8BD',
      contrastText: PayspinColors.white,
    },
    error: {
      main: PayspinColors.error,
    },
    warning: {
      main: PayspinColors.warning,
    },
    info: {
      main: PayspinColors.info,
    },
    success: {
      main: PayspinColors.success,
    },
    grey: PayspinColors.gray,
    background: {
      default: '#FAFBFC',
      paper: PayspinColors.white,
    },
    text: {
      primary: PayspinColors.gray[900],
      secondary: PayspinColors.gray[600],
    },
  },
  typography,
  shape: {
    borderRadius: 12,
  },
  shadows: [
    'none',
    '0px 1px 2px rgba(0, 0, 0, 0.06)',
    '0px 2px 4px rgba(0, 0, 0, 0.08)',
    '0px 4px 8px rgba(0, 0, 0, 0.1)',
    '0px 8px 16px rgba(0, 0, 0, 0.12)',
    '0px 16px 32px rgba(0, 0, 0, 0.14)',
    '0px 1px 3px rgba(0, 0, 0, 0.08)',
    '0px 2px 6px rgba(0, 0, 0, 0.1)',
    '0px 4px 12px rgba(0, 0, 0, 0.12)',
    '0px 8px 24px rgba(0, 0, 0, 0.14)',
    '0px 16px 48px rgba(0, 0, 0, 0.16)',
    '0px 1px 4px rgba(0, 0, 0, 0.1)',
    '0px 2px 8px rgba(0, 0, 0, 0.12)',
    '0px 4px 16px rgba(0, 0, 0, 0.14)',
    '0px 8px 32px rgba(0, 0, 0, 0.16)',
    '0px 16px 64px rgba(0, 0, 0, 0.18)',
    '0px 12px 14px rgba(0, 0, 0, 0.1)',
    '0px 13px 15px rgba(0, 0, 0, 0.1)',
    '0px 14px 16px rgba(0, 0, 0, 0.1)',
    '0px 15px 17px rgba(0, 0, 0, 0.1)',
    '0px 16px 18px rgba(0, 0, 0, 0.1)',
    '0px 17px 19px rgba(0, 0, 0, 0.1)',
    '0px 18px 20px rgba(0, 0, 0, 0.1)',
    '0px 19px 21px rgba(0, 0, 0, 0.1)',
    '0px 20px 22px rgba(0, 0, 0, 0.1)'
  ],
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          textTransform: 'none',
          fontWeight: 600,
          padding: '10px 20px',
          minHeight: 44, // Touch-friendly minimum height
          fontSize: 'clamp(0.875rem, 1.2vw, 1rem)',
          transition: 'all 0.2s ease',
          '&:hover': {
            transform: 'translateY(-1px)',
          },
          '&.MuiButton-sizeSmall': {
            padding: '6px 16px',
            minHeight: 36,
            fontSize: 'clamp(0.75rem, 1vw, 0.875rem)',
          },
          '&.MuiButton-sizeLarge': {
            padding: '14px 28px',
            minHeight: 52,
            fontSize: 'clamp(1rem, 1.4vw, 1.125rem)',
          },
        },
        contained: {
          boxShadow: '0px 2px 8px rgba(0, 0, 0, 0.12)',
          '&:hover': {
            boxShadow: '0px 4px 16px rgba(0, 0, 0, 0.16)',
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          boxShadow: '0px 2px 8px rgba(0, 0, 0, 0.06)',
          border: `1px solid ${PayspinColors.gray[100]}`,
          transition: 'all 0.2s ease',
          '&:hover': {
            boxShadow: '0px 4px 16px rgba(0, 0, 0, 0.08)',
          },
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          boxShadow: '0px 2px 8px rgba(0, 0, 0, 0.06)',
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          background: PayspinColors.white,
          color: PayspinColors.gray[900],
          boxShadow: '0px 1px 3px rgba(0, 0, 0, 0.12)',
        },
      },
    },
    MuiDrawer: {
      styleOverrides: {
        paper: {
          borderRight: `1px solid ${PayspinColors.gray[200]}`,
          background: PayspinColors.white,
          width: 'clamp(280px, 25vw, 320px)', // Responsive drawer width
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: 12,
            fontSize: 'clamp(0.875rem, 1.2vw, 1rem)',
          },
          '& .MuiInputLabel-root': {
            fontSize: 'clamp(0.875rem, 1.2vw, 1rem)',
          },
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          fontWeight: 500,
          fontSize: 'clamp(0.75rem, 1vw, 0.875rem)',
          height: 'auto',
          minHeight: 24,
        },
      },
    },
    MuiTable: {
      styleOverrides: {
        root: {
          '& .MuiTableCell-root': {
            fontSize: 'clamp(0.75rem, 1vw, 0.875rem)',
            padding: 'clamp(8px, 1.5vw, 16px)',
          },
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        root: {
          fontSize: 'clamp(0.75rem, 1vw, 0.875rem)',
          padding: 'clamp(8px, 1.5vw, 16px)',
        },
        head: {
          fontWeight: 600,
          fontSize: 'clamp(0.75rem, 1.1vw, 0.875rem)',
        },
      },
    },
    MuiTablePagination: {
      styleOverrides: {
        root: {
          fontSize: 'clamp(0.75rem, 1vw, 0.875rem)',
        },
        selectLabel: {
          fontSize: 'clamp(0.75rem, 1vw, 0.875rem)',
        },
        displayedRows: {
          fontSize: 'clamp(0.75rem, 1vw, 0.875rem)',
        },
      },
    },
    MuiIconButton: {
      styleOverrides: {
        root: {
          minWidth: 44,
          minHeight: 44,
          '&.MuiIconButton-sizeSmall': {
            minWidth: 36,
            minHeight: 36,
          },
          '&.MuiIconButton-sizeLarge': {
            minWidth: 52,
            minHeight: 52,
          },
        },
      },
    },
    MuiMenu: {
      styleOverrides: {
        paper: {
          borderRadius: 12,
          boxShadow: '0px 8px 32px rgba(0, 0, 0, 0.12)',
          minWidth: 200,
        },
      },
    },
    MuiMenuItem: {
      styleOverrides: {
        root: {
          fontSize: 'clamp(0.875rem, 1.1vw, 1rem)',
          minHeight: 44,
          padding: '12px 16px',
        },
      },
    },
    MuiAvatar: {
      styleOverrides: {
        root: {
          fontSize: 'clamp(0.75rem, 1.2vw, 1rem)',
        },
      },
    },
    MuiBadge: {
      styleOverrides: {
        badge: {
          fontSize: 'clamp(0.625rem, 0.8vw, 0.75rem)',
          minWidth: 'clamp(16px, 2vw, 20px)',
          height: 'clamp(16px, 2vw, 20px)',
        },
      },
    },
    MuiTooltip: {
      styleOverrides: {
        tooltip: {
          fontSize: 'clamp(0.75rem, 1vw, 0.875rem)',
          padding: '8px 12px',
        },
      },
    },
  },
};

export const theme = createTheme(themeOptions);
export default theme; 