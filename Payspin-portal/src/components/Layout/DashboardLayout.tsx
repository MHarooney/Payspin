import React, { useState } from 'react';
import {
  AppBar,
  Box,
  CssBaseline,
  Drawer,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Typography,
  useTheme,
  useMediaQuery,
  Avatar,
  Slide,
  useScrollTrigger,
  Badge,
  Stack,
  Chip,
  SwipeableDrawer,
  Tooltip,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Dashboard as DashboardIcon,
  People as PeopleIcon,
  Groups as GroupsIcon,
  Article as ArticleIcon,
  LocalOffer as OfferIcon,
  Settings as SettingsIcon,
  Notifications as NotificationsIcon,
  AccountCircle as AccountIcon,
  Logout as LogoutIcon,
  Payment as PaymentIcon,
  Analytics as AnalyticsIcon,
  Category as CategoryIcon,
  KeyboardArrowRight as ArrowRightIcon,
  TrendingUp as TrendingIcon,
} from '@mui/icons-material';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { PayspinColors } from '../../theme/theme';
import { SessionStatus } from '../Common/SessionStatus';
import { ActionMenu, useActionMenu, ActionMenuItem } from '../Common/ActionMenu';

// Responsive drawer width
const getDrawerWidth = (isMobile: boolean, isTablet: boolean) => {
  if (isMobile) return '85vw';
  if (isTablet) return 320;
  return 300;
};

interface NavigationItem {
  id: string;
  label: string;
  path: string;
  icon: React.ReactNode;
  badge?: number;
  color?: string;
  featured?: boolean;
  description?: string;
}

const navigationItems: NavigationItem[] = [
  {
    id: 'dashboard',
    label: 'Dashboard',
    path: '/dashboard',
    icon: <DashboardIcon />,
    description: 'Overview & Analytics',
    featured: true,
  },
  {
    id: 'users',
    label: 'Users',
    path: '/users',
    icon: <PeopleIcon />,
    description: 'Manage User Accounts',
  },
  {
    id: 'circles',
    label: 'Circles',
    path: '/circles',
    icon: <GroupsIcon />,
    description: 'Community Groups',
  },
  {
    id: 'posts',
    label: 'Posts',
    path: '/posts',
    icon: <ArticleIcon />,
    description: 'Content Management',
    featured: true,
  },
  {
    id: 'post-types',
    label: 'Post Types',
    path: '/post-types',
    icon: <CategoryIcon />,
    description: 'Content Categories',
  },
  {
    id: 'notifications',
    label: 'Notifications',
    path: '/notifications',
    icon: <NotificationsIcon />,
    description: 'System Alerts',
    badge: 3,
  },
  {
    id: 'offers',
    label: 'Offers',
    path: '/offers',
    icon: <OfferIcon />,
    description: 'Promotional Content',
  },
  {
    id: 'payment-methods',
    label: 'Payment Methods',
    path: '/payment-methods',
    icon: <PaymentIcon />,
    description: 'Transaction Settings',
  },
  {
    id: 'analytics',
    label: 'Analytics',
    path: '/analytics',
    icon: <AnalyticsIcon />,
    description: 'Data Insights',
    featured: true,
  },
  {
    id: 'settings',
    label: 'Settings',
    path: '/settings',
    icon: <SettingsIcon />,
    description: 'System Configuration',
  },
];

interface DashboardLayoutProps {
  children: React.ReactNode;
}

// Hide on scroll component for mobile
function HideOnScroll(props: { children: React.ReactElement }) {
  const { children } = props;
  const trigger = useScrollTrigger();

  return (
    <Slide appear={false} direction="down" in={!trigger}>
      {children}
    </Slide>
  );
}

const DashboardLayout: React.FC<DashboardLayoutProps> = ({ children }) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const isTablet = useMediaQuery(theme.breakpoints.between('md', 'lg'));
  const [mobileOpen, setMobileOpen] = useState(false);
  
  const { userData, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const { anchorEl: userMenuAnchor, handleMenuOpen: handleUserMenuOpen, handleMenuClose: handleUserMenuClose } = useActionMenu();

  const drawerWidth = getDrawerWidth(isMobile, isTablet);

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const handleNavigation = (path: string) => {
    navigate(path);
    if (isMobile) {
      setMobileOpen(false);
    }
  };

  const getUserMenuItems = (): ActionMenuItem[] => [
    {
      id: 'profile',
      label: 'Profile',
      icon: <AccountIcon />,
      onClick: () => handleNavigation('/profile'),
    },
    {
      id: 'logout-divider',
      label: 'Logout Section',
      divider: true,
    },
    {
      id: 'logout',
      label: 'Logout',
      icon: <LogoutIcon />,
      onClick: handleLogout,
      color: 'error',
    },
  ];

  const drawer = (
    <Box sx={{ 
      height: '100%', 
      display: 'flex', 
      flexDirection: 'column',
      background: 'linear-gradient(180deg, #fafafa 0%, #f5f5f5 100%)',
      position: 'relative',
      '&::before': {
        content: '""',
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        height: '100%',
        background: 'radial-gradient(circle at 20% 50%, rgba(252, 0, 255, 0.03) 0%, transparent 50%), radial-gradient(circle at 80% 20%, rgba(0, 255, 255, 0.03) 0%, transparent 50%)',
        pointerEvents: 'none',
      },
    }}>
      {/* Enhanced Logo Section */}
      <Box
        sx={{
          p: { xs: 2, sm: 2.5, md: 3 },
          background: `linear-gradient(135deg, ${PayspinColors.primary} 0%, ${PayspinColors.secondary} 100%)`,
          color: 'white',
          textAlign: 'center',
          position: 'relative',
          borderRadius: { xs: '0 20px 0 0', sm: '0 24px 0 0' },
          overflow: 'hidden',
          boxShadow: '0px 4px 20px rgba(252, 0, 255, 0.2)',
          '&::before': {
            content: '""',
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'linear-gradient(135deg, rgba(255,255,255,0.15) 0%, rgba(255,255,255,0.05) 100%)',
          },
          '&::after': {
            content: '""',
            position: 'absolute',
            top: -50,
            right: -50,
            width: 100,
            height: 100,
            borderRadius: '50%',
            background: 'rgba(255,255,255,0.1)',
            filter: 'blur(20px)',
          },
        }}
      >
        <Box sx={{ position: 'relative', zIndex: 1 }}>
          <Box sx={{ 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center', 
            mb: 1,
            gap: 1,
          }}>
            <Box
              component="img"
              src="/payspin-ic-white.png"
              alt="Payspin Logo"
              sx={{ 
                width: { xs: 20, sm: 24, md: 28 },
                height: { xs: 20, sm: 24, md: 28 },
                filter: 'brightness(0) invert(1)',
                opacity: 0.9,
              }}
            />
            <Typography
              variant="h5"
              fontWeight={800}
              sx={{ 
                fontFamily: 'Raleway, sans-serif',
                fontSize: { xs: '1.25rem', sm: '1.375rem', md: '1.5rem' },
                background: 'linear-gradient(45deg, #ffffff 30%, #f0f0f0 90%)',
                backgroundClip: 'text',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                textShadow: '0px 2px 4px rgba(0,0,0,0.1)',
              }}
            >
              Payspin
            </Typography>
          </Box>
          <Typography 
            variant="caption" 
            sx={{ 
              opacity: 0.9,
              fontSize: { xs: '0.75rem', sm: '0.875rem', md: '1rem' },
              fontWeight: 500,
              letterSpacing: '0.5px',
              textTransform: 'uppercase',
            }}
          >
            Admin Portal
          </Typography>
          <Box sx={{ 
            mt: 1.5,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 0.5,
          }}>
            <Box sx={{ 
              width: 6, 
              height: 6, 
              borderRadius: '50%', 
              bgcolor: 'rgba(255,255,255,0.8)',
              animation: 'pulse 2s infinite',
              '@keyframes pulse': {
                '0%': { opacity: 1, transform: 'scale(1)' },
                '50%': { opacity: 0.5, transform: 'scale(1.2)' },
                '100%': { opacity: 1, transform: 'scale(1)' },
              },
            }} />
            <Typography variant="caption" sx={{ opacity: 0.8, fontSize: '0.75rem' }}>
              Live System
            </Typography>
          </Box>
        </Box>
      </Box>

      {/* Enhanced Navigation */}
      <Box sx={{ flex: 1, overflow: 'auto', position: 'relative', zIndex: 1 }}>
        <List sx={{ p: { xs: 1, sm: 1.5, md: 2 } }}>
          {navigationItems.map((item, index) => {
            const isActive = location.pathname === item.path || 
                           (item.path !== '/dashboard' && location.pathname.startsWith(item.path));
            
            return (
              <ListItem key={item.id} disablePadding sx={{ mb: { xs: 0.5, sm: 0.75, md: 1 } }}>
                <Tooltip 
                  title={item.description || item.label}
                  placement="right"
                  arrow
                  enterDelay={500}
                  sx={{ display: { md: 'none' } }}
                >
                  <ListItemButton
                    onClick={() => handleNavigation(item.path)}
                    sx={{
                      borderRadius: { xs: 2, sm: 2.5, md: 3 },
                      minHeight: { xs: 48, sm: 52, md: 56 },
                      mx: { xs: 0.5, sm: 1, md: 0 },
                      color: isActive ? PayspinColors.primary : 'text.primary',
                      backgroundColor: isActive 
                        ? `linear-gradient(135deg, ${PayspinColors.primary}15 0%, ${PayspinColors.primary}08 100%)`
                        : 'transparent',
                      position: 'relative',
                      transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                      border: isActive ? `1px solid ${PayspinColors.primary}30` : '1px solid transparent',
                      backdropFilter: isActive ? 'blur(10px)' : 'none',
                      '&:hover': {
                        backgroundColor: isActive 
                          ? `linear-gradient(135deg, ${PayspinColors.primary}25 0%, ${PayspinColors.primary}15 100%)`
                          : 'rgba(252, 0, 255, 0.05)',
                        transform: 'translateX(4px) scale(1.02)',
                        boxShadow: isActive 
                          ? `0px 8px 24px ${PayspinColors.primary}25`
                          : '0px 4px 12px rgba(0,0,0,0.1)',
                      },
                      '& .MuiListItemIcon-root': {
                        color: 'inherit',
                        transition: 'all 0.3s ease',
                      },
                      '&:hover .MuiListItemIcon-root': {
                        transform: 'scale(1.1) rotate(5deg)',
                      },
                      '& .MuiListItemText-primary': {
                        fontSize: { xs: '0.875rem', sm: '0.9rem', md: '0.95rem' },
                        fontWeight: isActive ? 700 : 500,
                        transition: 'all 0.3s ease',
                        letterSpacing: '0.3px',
                      },
                      '&::before': isActive ? {
                        content: '""',
                        position: 'absolute',
                        left: 0,
                        top: '50%',
                        transform: 'translateY(-50%)',
                        width: 4,
                        height: '60%',
                        backgroundColor: PayspinColors.primary,
                        borderRadius: '0 2px 2px 0',
                        boxShadow: `0px 0px 8px ${PayspinColors.primary}50`,
                      } : {},
                    }}
                  >
                    <ListItemIcon sx={{ 
                      minWidth: { xs: 36, sm: 40, md: 44 },
                      '& .MuiSvgIcon-root': {
                        fontSize: { xs: 22, sm: 24, md: 26 },
                      },
                    }}>
                      {item.badge ? (
                        <Badge
                          badgeContent={item.badge}
                          color="error"
                          sx={{
                            '& .MuiBadge-badge': {
                              fontSize: { xs: '0.625rem', sm: '0.75rem' },
                              height: { xs: 18, sm: 20 },
                              minWidth: { xs: 18, sm: 20 },
                              fontWeight: 600,
                            },
                          }}
                        >
                          {item.icon}
                        </Badge>
                      ) : (
                        item.icon
                      )}
                    </ListItemIcon>
                    <ListItemText
                      primary={
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          {item.label}
                          {item.featured && (
                            <TrendingIcon sx={{ 
                              fontSize: 16, 
                              color: PayspinColors.secondary,
                              opacity: 0.8,
                            }} />
                          )}
                        </Box>
                      }
                      primaryTypographyProps={{
                        fontSize: { xs: '0.875rem', sm: '0.9rem', md: '0.95rem' },
                        fontWeight: isActive ? 700 : 500,
                        letterSpacing: '0.3px',
                      }}
                    />
                    {isActive && (
                      <ArrowRightIcon sx={{ 
                        fontSize: 20, 
                        color: PayspinColors.primary,
                        ml: 'auto',
                        animation: 'slideRight 0.3s ease-out',
                        '@keyframes slideRight': {
                          '0%': { transform: 'translateX(-10px)', opacity: 0 },
                          '100%': { transform: 'translateX(0)', opacity: 1 },
                        },
                      }} />
                    )}
                  </ListItemButton>
                </Tooltip>
              </ListItem>
            );
          })}
        </List>
      </Box>

      {/* Enhanced User Info Section */}
      <Box sx={{ 
        p: { xs: 1.5, sm: 2, md: 2.5 }, 
        borderTop: `1px solid ${PayspinColors.gray[200]}`,
        background: 'rgba(255,255,255,0.8)',
        backdropFilter: 'blur(10px)',
        position: 'relative',
        zIndex: 1,
      }}>
        <Box sx={{ 
          display: 'flex', 
          alignItems: 'center', 
          gap: { xs: 1.5, sm: 2 }, 
          mb: { xs: 1.5, sm: 2 },
          p: { xs: 1, sm: 1.5 },
          borderRadius: 2,
          background: 'rgba(252, 0, 255, 0.03)',
          border: '1px solid rgba(252, 0, 255, 0.1)',
        }}>
          <Avatar
            sx={{
              width: { xs: 32, sm: 36, md: 44 },
              height: { xs: 32, sm: 36, md: 44 },
              background: `linear-gradient(135deg, ${PayspinColors.primary} 0%, ${PayspinColors.secondary} 100%)`,
              boxShadow: '0px 4px 12px rgba(252, 0, 255, 0.3)',
              border: '2px solid rgba(255,255,255,0.8)',
              fontSize: { xs: '0.875rem', sm: '1rem', md: '1.125rem' },
              fontWeight: 600,
            }}
          >
            {userData?.firstName?.charAt(0) || 'A'}
          </Avatar>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography 
              variant="subtitle2" 
              noWrap
              sx={{ 
                fontSize: { xs: '0.8rem', sm: '0.875rem', md: '1rem' },
                fontWeight: 600,
                color: 'text.primary',
                mb: 0.5,
              }}
            >
              {userData ? `${userData.firstName} ${userData.lastName}` : 'Admin User'}
            </Typography>
            <Stack direction="row" spacing={1} alignItems="center">
              <Chip
                label={userData?.role || 'admin'}
                size="small"
                color="primary"
                variant="outlined"
                sx={{ 
                  height: { xs: 20, sm: 22 },
                  fontSize: { xs: '0.625rem', sm: '0.75rem' },
                  fontWeight: 600,
                  borderColor: PayspinColors.primary,
                  color: PayspinColors.primary,
                  '& .MuiChip-label': {
                    px: 1,
                  },
                }}
              />
              <Box sx={{ 
                width: 6, 
                height: 6, 
                borderRadius: '50%', 
                bgcolor: 'success.main',
                boxShadow: '0px 0px 8px rgba(76, 175, 80, 0.5)',
                animation: 'pulse 2s infinite',
              }} />
            </Stack>
          </Box>
        </Box>
        
        {/* Enhanced Session Status */}
        <SessionStatus showDetails={isMobile ? false : true} />
      </Box>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      {/* Enhanced App Bar */}
      <HideOnScroll>
        <AppBar
          position="fixed"
          elevation={0}
          sx={{
            width: { md: `calc(100% - ${drawerWidth}px)` },
            ml: { md: `${drawerWidth}px` },
            backgroundColor: 'rgba(255,255,255,0.95)',
            backdropFilter: 'blur(20px)',
            borderBottom: `1px solid ${PayspinColors.gray[200]}`,
            zIndex: theme.zIndex.appBar,
            boxShadow: '0px 2px 20px rgba(0,0,0,0.08)',
          }}
        >
          <Toolbar sx={{ minHeight: { xs: 56, md: 64 } }}>
            <IconButton
              color="inherit"
              edge="start"
              onClick={handleDrawerToggle}
              sx={{ 
                mr: 2, 
                display: { md: 'none' },
                minWidth: 44,
                minHeight: 44,
                borderRadius: 2,
                background: 'rgba(252, 0, 255, 0.08)',
                '&:hover': {
                  backgroundColor: 'rgba(252, 0, 255, 0.15)',
                  transform: 'scale(1.05)',
                },
                transition: 'all 0.2s ease',
                '& .MuiSvgIcon-root': {
                  fontSize: { xs: 24, sm: 28 },
                  color: PayspinColors.primary,
                },
              }}
            >
              <MenuIcon />
            </IconButton>

            <Box sx={{ flexGrow: 1 }} />

            {/* Enhanced User Menu */}
            <IconButton
              onClick={handleUserMenuOpen}
              sx={{ 
                p: 0,
                minWidth: 44,
                minHeight: 44,
                borderRadius: 2,
                '&:hover': {
                  backgroundColor: 'rgba(252, 0, 255, 0.08)',
                  transform: 'scale(1.05)',
                },
                transition: 'all 0.2s ease',
              }}
            >
              <Avatar
                sx={{
                  width: { xs: 32, md: 36 },
                  height: { xs: 32, md: 36 },
                  background: `linear-gradient(135deg, ${PayspinColors.primary} 0%, ${PayspinColors.secondary} 100%)`,
                  boxShadow: '0px 4px 12px rgba(252, 0, 255, 0.3)',
                  border: '2px solid rgba(255,255,255,0.8)',
                }}
              >
                {userData?.firstName?.charAt(0) || 'A'}
              </Avatar>
            </IconButton>

            <ActionMenu
              anchorEl={userMenuAnchor}
              onClose={handleUserMenuClose}
              items={getUserMenuItems()}
              paperProps={{
                minWidth: { xs: 180, md: 200 },
                borderRadius: 3,
                boxShadow: '0px 8px 32px rgba(0, 0, 0, 0.12)',
                background: 'rgba(255,255,255,0.95)',
                backdropFilter: 'blur(20px)',
                border: '1px solid rgba(252, 0, 255, 0.1)',
              }}
            />
          </Toolbar>
        </AppBar>
      </HideOnScroll>

      {/* Enhanced Sidebar */}
      <Box
        component="nav"
        sx={{ width: { md: drawerWidth }, flexShrink: { md: 0 } }}
      >
        {/* Enhanced Mobile drawer */}
        <SwipeableDrawer
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          onOpen={() => setMobileOpen(true)}
          ModalProps={{
            keepMounted: true,
          }}
          sx={{
            display: { xs: 'block', md: 'none' },
            zIndex: theme.zIndex.drawer + 1,
            '& .MuiDrawer-paper': {
              boxSizing: 'border-box',
              width: drawerWidth,
              border: 'none',
              borderRadius: { xs: '0 20px 20px 0', sm: '0 24px 24px 0' },
              boxShadow: '0px 12px 40px rgba(0, 0, 0, 0.15)',
              maxWidth: { xs: '320px', sm: '360px' },
              minWidth: { xs: '280px', sm: '300px' },
              zIndex: theme.zIndex.drawer + 1,
              overflow: 'hidden',
            },
            '& .MuiBackdrop-root': {
              backgroundColor: 'rgba(0, 0, 0, 0.5)',
              backdropFilter: 'blur(4px)',
              zIndex: theme.zIndex.drawer,
            },
          }}
          anchor="left"
          disableDiscovery={false}
          disableSwipeToOpen={false}
          swipeAreaWidth={20}
        >
          {drawer}
        </SwipeableDrawer>

        {/* Enhanced Desktop drawer */}
        <Drawer
          variant="permanent"
          sx={{
            display: { xs: 'none', md: 'block' },
            '& .MuiDrawer-paper': {
              boxSizing: 'border-box',
              width: drawerWidth,
              border: 'none',
              borderRight: `1px solid ${PayspinColors.gray[200]}`,
              boxShadow: '2px 0px 20px rgba(0,0,0,0.08)',
              overflow: 'hidden',
            },
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>

      {/* Enhanced Main content */}
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          width: { md: `calc(100% - ${drawerWidth}px)` },
          backgroundColor: 'background.default',
          background: 'linear-gradient(135deg, #fafafa 0%, #f5f5f5 100%)',
        }}
      >
        <Toolbar sx={{ minHeight: { xs: 56, md: 64 } }} />
        <Box sx={{ 
          p: { xs: 2, sm: 3, md: 3 },
          minHeight: 'calc(100vh - 64px)',
        }}>
          {children}
        </Box>
      </Box>
    </Box>
  );
};

export default DashboardLayout; 