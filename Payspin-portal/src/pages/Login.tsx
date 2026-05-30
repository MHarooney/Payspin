import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Container,
  Alert,
  InputAdornment,
  IconButton,
  useTheme,
  useMediaQuery,
  Fade,
  Slide,
  Stack,
  Divider,
  Chip,
  CircularProgress,
} from '@mui/material';
import { 
  Visibility, 
  VisibilityOff, 
  Email, 
  Lock, 
  Security as SecurityIcon,
  TrendingUp as TrendingIcon,
  Star as StarIcon,
  CheckCircle as CheckCircleIcon,
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { Navigate, useNavigate } from 'react-router-dom';
import { PayspinColors } from '../theme/theme';

export const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [animateIn, setAnimateIn] = useState(false);

  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const { login, currentUser } = useAuth();
  const navigate = useNavigate();

  // Animation effect on mount
  useEffect(() => {
    setAnimateIn(true);
  }, []);

  // Redirect if already logged in
  if (currentUser) {
    return <Navigate to="/dashboard" replace />;
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!email || !password) {
      setError('Please fill in all fields');
      return;
    }

    try {
      setError('');
      setLoading(true);
      await login(email, password);
    } catch (error) {
      setError('Failed to login. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: `linear-gradient(135deg, ${PayspinColors.primary} 0%, ${PayspinColors.secondary} 50%, ${PayspinColors.primary} 100%)`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        overflow: 'hidden',
        '&::before': {
          content: '""',
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: `
            radial-gradient(circle at 20% 80%, rgba(255,255,255,0.1) 0%, transparent 50%),
            radial-gradient(circle at 80% 20%, rgba(0,255,255,0.1) 0%, transparent 50%),
            radial-gradient(circle at 40% 40%, rgba(252,0,255,0.05) 0%, transparent 50%)
          `,
          zIndex: 1,
        },
        '&::after': {
          content: '""',
          position: 'absolute',
          top: -50,
          right: -50,
          width: 200,
          height: 200,
          borderRadius: '50%',
          background: 'rgba(255,255,255,0.1)',
          filter: 'blur(40px)',
          animation: 'float 6s ease-in-out infinite',
          '@keyframes float': {
            '0%, 100%': { transform: 'translateY(0px) rotate(0deg)' },
            '50%': { transform: 'translateY(-20px) rotate(180deg)' },
          },
        },
      }}
    >
      {/* Animated Background Elements */}
      <Box
        sx={{
          position: 'absolute',
          top: '10%',
          left: '10%',
          width: 100,
          height: 100,
          borderRadius: '50%',
          background: 'rgba(255,255,255,0.05)',
          filter: 'blur(20px)',
          animation: 'pulse 4s ease-in-out infinite',
          '@keyframes pulse': {
            '0%, 100%': { transform: 'scale(1)', opacity: 0.5 },
            '50%': { transform: 'scale(1.2)', opacity: 0.8 },
          },
        }}
      />
      <Box
        sx={{
          position: 'absolute',
          bottom: '20%',
          right: '15%',
          width: 150,
          height: 150,
          borderRadius: '50%',
          background: 'rgba(0,255,255,0.05)',
          filter: 'blur(30px)',
          animation: 'float 8s ease-in-out infinite reverse',
        }}
      />

      <Container maxWidth="sm" sx={{ position: 'relative', zIndex: 2 }}>
        <Fade in={animateIn} timeout={800}>
          <Slide direction="up" in={animateIn} timeout={1000}>
            <Card
              sx={{
                borderRadius: { xs: 2, sm: 3, md: 4 },
                boxShadow: '0px 32px 80px rgba(0, 0, 0, 0.2)',
                backdropFilter: 'blur(20px)',
                background: 'rgba(255, 255, 255, 0.95)',
                border: '1px solid rgba(255, 255, 255, 0.2)',
                position: 'relative',
                overflow: 'hidden',
                '&::before': {
                  content: '""',
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  right: 0,
                  height: '4px',
                  background: `linear-gradient(90deg, ${PayspinColors.primary} 0%, ${PayspinColors.secondary} 100%)`,
                },
              }}
            >
              <CardContent sx={{ p: { xs: 3, sm: 4, md: 5 } }}>
                {/* Enhanced Logo and Title Section */}
                <Box textAlign="center" mb={4}>
                  <Box sx={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'center', 
                    mb: 2,
                    gap: 1,
                  }}>
                    <Box
                      component="img"
                      src="/payspin-ic.png"
                      alt="Payspin Logo"
                      sx={{ 
                        width: { xs: 32, sm: 40, md: 48 },
                        height: { xs: 32, sm: 40, md: 48 },
                        opacity: 0.95,
                        filter: 'drop-shadow(0px 2px 4px rgba(0,0,0,0.1))',
                      }}
                    />
                    <Typography
                      variant="h3"
                      component="h1"
                      fontWeight={800}
                      sx={{
                        background: `linear-gradient(135deg, ${PayspinColors.primary} 0%, ${PayspinColors.secondary} 100%)`,
                        backgroundClip: 'text',
                        WebkitBackgroundClip: 'text',
                        WebkitTextFillColor: 'transparent',
                        fontSize: { xs: '2rem', sm: '2.5rem', md: '3rem' },
                        fontFamily: 'Raleway, sans-serif',
                        letterSpacing: '-0.5px',
                      }}
                    >
                      Payspin
                    </Typography>
                  </Box>
                  
                  <Typography
                    variant="h5"
                    color="text.primary"
                    fontWeight={600}
                    sx={{ 
                      mb: 1,
                      fontSize: { xs: '1.25rem', sm: '1.5rem' },
                    }}
                  >
                    Admin Portal
                  </Typography>
                  
                  <Typography 
                    variant="body1" 
                    color="text.secondary"
                    sx={{ 
                      mb: 3,
                      fontSize: { xs: '0.875rem', sm: '1rem' },
                    }}
                  >
                    Sign in to access the admin dashboard
                  </Typography>

                  {/* Feature Highlights */}
                  <Stack 
                    direction="row" 
                    spacing={2} 
                    justifyContent="center" 
                    flexWrap="wrap"
                    sx={{ mb: 3 }}
                  >
                    <Chip
                      icon={<SecurityIcon />}
                      label="Secure Access"
                      size="small"
                      color="primary"
                      variant="outlined"
                      sx={{ 
                        fontSize: '0.75rem',
                        borderColor: PayspinColors.primary,
                        color: PayspinColors.primary,
                      }}
                    />
                    <Chip
                      icon={<TrendingIcon />}
                      label="Real-time Analytics"
                      size="small"
                      color="primary"
                      variant="outlined"
                      sx={{ 
                        fontSize: '0.75rem',
                        borderColor: PayspinColors.primary,
                        color: PayspinColors.primary,
                      }}
                    />
                  </Stack>
                </Box>

                {/* Error Alert */}
                {error && (
                  <Fade in={!!error}>
                    <Alert 
                      severity="error" 
                      sx={{ 
                        mb: 3, 
                        borderRadius: 2,
                        border: '1px solid',
                        borderColor: 'error.light',
                        '& .MuiAlert-icon': {
                          color: 'error.main',
                        },
                      }}
                    >
                      {error}
                    </Alert>
                  </Fade>
                )}

                {/* Enhanced Login Form */}
                <Box component="form" onSubmit={handleSubmit}>
                  <TextField
                    fullWidth
                    label="Email Address"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    margin="normal"
                    required
                    autoComplete="email"
                    autoFocus
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <Email sx={{ color: PayspinColors.primary }} />
                        </InputAdornment>
                      ),
                    }}
                    sx={{ 
                      mb: 2,
                      '& .MuiOutlinedInput-root': {
                        borderRadius: 2,
                        transition: 'all 0.3s ease',
                        '&:hover': {
                          '& .MuiOutlinedInput-notchedOutline': {
                            borderColor: PayspinColors.primary,
                          },
                        },
                        '&.Mui-focused': {
                          '& .MuiOutlinedInput-notchedOutline': {
                            borderColor: PayspinColors.primary,
                            borderWidth: 2,
                          },
                        },
                      },
                    }}
                  />

                  <TextField
                    fullWidth
                    label="Password"
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    margin="normal"
                    required
                    autoComplete="current-password"
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <Lock sx={{ color: PayspinColors.primary }} />
                        </InputAdornment>
                      ),
                      endAdornment: (
                        <InputAdornment position="end">
                          <IconButton
                            onClick={() => setShowPassword(!showPassword)}
                            edge="end"
                            sx={{
                              color: PayspinColors.primary,
                              '&:hover': {
                                backgroundColor: `${PayspinColors.primary}15`,
                              },
                            }}
                          >
                            {showPassword ? <VisibilityOff /> : <Visibility />}
                          </IconButton>
                        </InputAdornment>
                      ),
                    }}
                    sx={{ 
                      mb: 3,
                      '& .MuiOutlinedInput-root': {
                        borderRadius: 2,
                        transition: 'all 0.3s ease',
                        '&:hover': {
                          '& .MuiOutlinedInput-notchedOutline': {
                            borderColor: PayspinColors.primary,
                          },
                        },
                        '&.Mui-focused': {
                          '& .MuiOutlinedInput-notchedOutline': {
                            borderColor: PayspinColors.primary,
                            borderWidth: 2,
                          },
                        },
                      },
                    }}
                  />

                  <Button
                    type="submit"
                    fullWidth
                    variant="contained"
                    size="large"
                    disabled={loading}
                    sx={{
                      py: 1.75,
                      fontSize: { xs: '1rem', sm: '1.1rem' },
                      fontWeight: 700,
                      textTransform: 'none',
                      borderRadius: 2,
                      mb: 3,
                      background: `linear-gradient(135deg, ${PayspinColors.primary} 0%, ${PayspinColors.secondary} 100%)`,
                      boxShadow: `0px 8px 24px ${PayspinColors.primary}40`,
                      transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                      '&:hover': {
                        transform: 'translateY(-2px)',
                        boxShadow: `0px 12px 32px ${PayspinColors.primary}50`,
                      },
                      '&:disabled': {
                        background: 'rgba(0,0,0,0.12)',
                        transform: 'none',
                        boxShadow: 'none',
                      },
                    }}
                  >
                    {loading ? (
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <CircularProgress size={20} color="inherit" />
                        Signing In...
                      </Box>
                    ) : (
                      'Sign In'
                    )}
                  </Button>
                </Box>

                {/* Security Notice */}
                <Box sx={{ 
                  textAlign: 'center',
                  p: 2,
                  borderRadius: 2,
                  background: 'rgba(252, 0, 255, 0.03)',
                  border: '1px solid rgba(252, 0, 255, 0.1)',
                }}>
                  <Typography 
                    variant="caption" 
                    color="text.secondary"
                    sx={{ 
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: 0.5,
                      fontSize: '0.75rem',
                    }}
                  >
                    <CheckCircleIcon sx={{ fontSize: 16, color: 'success.main' }} />
                    Secure SSL connection • Enterprise-grade security
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Slide>
        </Fade>

        {/* Enhanced Footer */}
        <Fade in={animateIn} timeout={1200}>
          <Box textAlign="center" mt={4}>
            <Typography 
              variant="body2" 
              sx={{ 
                color: 'rgba(255,255,255,0.9)',
                fontSize: { xs: '0.75rem', sm: '0.875rem' },
                fontWeight: 500,
              }}
            >
              © 2025 Payspin. All rights reserved.
            </Typography>
            <Typography 
              variant="caption" 
              sx={{ 
                color: 'rgba(255,255,255,0.7)',
                display: 'block',
                mt: 0.5,
                fontSize: '0.625rem',
              }}
            >
              Enterprise Admin Portal v2.0
            </Typography>
          </Box>
        </Fade>
      </Container>
    </Box>
  );
}; 