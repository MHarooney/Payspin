import React, { Component, ReactNode } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  useTheme,
  useMediaQuery,
} from '@mui/material';
import {
  Warning as WarningIcon,
  Refresh as RefreshIcon,
  BugReport as BugReportIcon,
} from '@mui/icons-material';
import { PayspinColors } from '../../theme/theme';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
    
    // Log error to console for debugging
    if (process.env.NODE_ENV === 'development') {
      console.group('🚨 Error Boundary');
      console.error('Error:', error);
      console.error('Error Info:', errorInfo);
      console.groupEnd();
    }
  }

  render() {
    if (this.state.hasError) {
      return (
        <Box
          sx={{
            minHeight: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            bgcolor: 'background.default',
            p: { xs: 2, sm: 3 },
          }}
        >
          <Paper
            elevation={4}
            sx={{
              maxWidth: { xs: '100%', sm: 500 },
              width: '100%',
              p: { xs: 3, sm: 4 },
              borderRadius: 3,
              textAlign: 'center',
            }}
          >
            <Box
              sx={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 2,
              }}
            >
              <Box
                sx={{
                  width: { xs: 60, sm: 80 },
                  height: { xs: 60, sm: 80 },
                  borderRadius: '50%',
                  background: `linear-gradient(135deg, ${PayspinColors.error}15, ${PayspinColors.warning}15)`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  mb: 2,
                }}
              >
                <WarningIcon
                  sx={{
                    fontSize: { xs: 32, sm: 40 },
                    color: PayspinColors.error,
                  }}
                />
              </Box>

              <Typography
                variant="h4"
                sx={{
                  fontWeight: 700,
                  fontSize: { xs: '1.5rem', sm: '2rem' },
                  color: 'text.primary',
                  mb: 1,
                }}
              >
                Something went wrong
              </Typography>

              <Typography
                variant="body1"
                sx={{
                  color: 'text.secondary',
                  mb: 3,
                  fontSize: { xs: '0.875rem', sm: '1rem' },
                  lineHeight: 1.6,
                }}
              >
                We're sorry, but something unexpected happened. Please try refreshing the page or contact support if the problem persists.
              </Typography>

              <Box
                sx={{
                  display: 'flex',
                  gap: 2,
                  flexDirection: { xs: 'column', sm: 'row' },
                  width: '100%',
                }}
              >
                <Button
                  variant="contained"
                  onClick={() => window.location.reload()}
                  startIcon={<RefreshIcon />}
                  sx={{
                    flex: 1,
                    borderRadius: 2,
                    py: { xs: 1.5, sm: 2 },
                    background: PayspinColors.gradient,
                    '&:hover': {
                      background: PayspinColors.gradient,
                      opacity: 0.9,
                    },
                  }}
                >
                  Refresh Page
                </Button>

                <Button
                  variant="outlined"
                  onClick={() => window.history.back()}
                  sx={{
                    flex: 1,
                    borderRadius: 2,
                    py: { xs: 1.5, sm: 2 },
                    borderColor: PayspinColors.primary,
                    color: PayspinColors.primary,
                    '&:hover': {
                      borderColor: PayspinColors.primary,
                      backgroundColor: `${PayspinColors.primary}15`,
                    },
                  }}
                >
                  Go Back
                </Button>
              </Box>

              {process.env.NODE_ENV === 'development' && this.state.error && (
                <Box
                  sx={{
                    mt: 3,
                    width: '100%',
                    textAlign: 'left',
                  }}
                >
                  <Typography
                    variant="subtitle2"
                    sx={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 1,
                      mb: 1,
                      color: 'text.secondary',
                      cursor: 'pointer',
                      '&:hover': {
                        color: 'text.primary',
                      },
                    }}
                    onClick={() => {
                      const details = document.getElementById('error-details');
                      if (details) {
                        details.style.display = details.style.display === 'none' ? 'block' : 'none';
                      }
                    }}
                  >
                    <BugReportIcon sx={{ fontSize: 16 }} />
                    Error Details (Development Only)
                  </Typography>
                  <Box
                    id="error-details"
                    sx={{
                      display: 'none',
                      p: 2,
                      bgcolor: 'error.50',
                      borderRadius: 2,
                      border: `1px solid ${PayspinColors.error}20`,
                    }}
                  >
                    <Typography
                      variant="caption"
                      component="pre"
                      sx={{
                        color: PayspinColors.error,
                        fontSize: '0.75rem',
                        lineHeight: 1.4,
                        whiteSpace: 'pre-wrap',
                        wordBreak: 'break-word',
                        overflow: 'auto',
                        maxHeight: 200,
                      }}
                    >
                      {this.state.error.stack}
                    </Typography>
                  </Box>
                </Box>
              )}
            </Box>
          </Paper>
        </Box>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary; 