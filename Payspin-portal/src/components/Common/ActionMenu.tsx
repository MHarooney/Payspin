import React from 'react';
import {
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Divider,
  useTheme,
} from '@mui/material';

export interface ActionMenuItem {
  id: string;
  label?: string;
  icon?: React.ReactNode;
  onClick?: () => void | Promise<void>;
  disabled?: boolean;
  divider?: boolean;
  hide?: boolean;
  color?: 'primary' | 'secondary' | 'error' | 'warning' | 'info' | 'success';
}

export interface ActionMenuProps {
  items: ActionMenuItem[];
  anchorEl: HTMLElement | null;
  onClose: () => void;
  menuProps?: any;
  paperProps?: {
    minWidth?: number | { xs?: number; sm?: number; md?: number; lg?: number; xl?: number };
    maxWidth?: number | { xs?: number; sm?: number; md?: number; lg?: number; xl?: number };
    borderRadius?: number;
    boxShadow?: string;
    background?: string;
    backdropFilter?: string;
    border?: string;
  };
}

export const ActionMenu: React.FC<ActionMenuProps> = ({
  items,
  onClose,
  anchorEl,
  menuProps,
  paperProps = {
    minWidth: 200,
    borderRadius: 2,
  },
}) => {
  const theme = useTheme();
  const filteredItems = items.filter(item => !item.hide);

  // Use a more robust anchor validation
  const [validAnchorEl, setValidAnchorEl] = React.useState<HTMLElement | null>(null);
  const [menuPosition, setMenuPosition] = React.useState<{ x: number; y: number } | null>(null);

  React.useEffect(() => {
    if (!anchorEl) {
      setValidAnchorEl(null);
      setMenuPosition(null);
      return;
    }

    // Validate anchor element with a small delay to ensure DOM is ready
    const validateAnchor = () => {
      try {
        // Check if element exists in DOM
        if (!document.contains(anchorEl)) {
          console.warn('Anchor element not in DOM');
          return false;
        }

        // Check if element is visible
        const rect = anchorEl.getBoundingClientRect();
        if (rect.width === 0 || rect.height === 0) {
          console.warn('Anchor element has zero dimensions');
          return false;
        }

        // Check computed styles
        const computedStyle = window.getComputedStyle(anchorEl);
        if (computedStyle.display === 'none' || computedStyle.visibility === 'hidden') {
          console.warn('Anchor element is hidden');
          return false;
        }

        return true;
      } catch (error) {
        console.warn('Error validating anchor element:', error);
        return false;
      }
    };

    // Use requestAnimationFrame to ensure DOM is ready
    const timeoutId = setTimeout(() => {
      if (validateAnchor()) {
        setValidAnchorEl(anchorEl);
        setMenuPosition(null);
      } else {
        // Fallback: use the anchor element's position
        try {
          const rect = anchorEl.getBoundingClientRect();
          setValidAnchorEl(null);
          setMenuPosition({
            x: rect.right,
            y: rect.bottom,
          });
        } catch (error) {
          console.warn('Failed to get anchor position:', error);
          setValidAnchorEl(null);
          setMenuPosition(null);
        }
      }
    }, 0);

    return () => clearTimeout(timeoutId);
  }, [anchorEl]);

  // Don't render if no valid anchor and no position
  if (!validAnchorEl && !menuPosition) {
    return null;
  }

  return (
    <Menu
      anchorEl={validAnchorEl}
      open={Boolean(anchorEl)}
      onClose={onClose}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'right',
      }}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'right',
      }}
      disableAutoFocus
      disableEnforceFocus
      disableRestoreFocus
      {...menuProps}
      // Use fallback positioning if needed
      {...(menuPosition && !validAnchorEl && {
        anchorReference: 'anchorPosition',
        anchorPosition: { top: menuPosition.y, left: menuPosition.x },
      })}
      PaperProps={{
        sx: {
          minWidth: paperProps.minWidth,
          maxWidth: paperProps.maxWidth,
          borderRadius: paperProps.borderRadius,
          boxShadow: paperProps.boxShadow || '0px 8px 24px rgba(0, 0, 0, 0.14)',
          background: paperProps.background,
          backdropFilter: paperProps.backdropFilter,
          border: paperProps.border,
          mt: 0.5,
          maxHeight: 'calc(100vh - 100px)', // Prevent menu from going off-screen
          overflow: 'auto',
          // Fix for scrolling issues - ensure menu stays in viewport
          '& .MuiMenu-paper': {
            maxHeight: 'calc(100vh - 100px)',
            overflow: 'auto',
          },
          ...menuProps?.PaperProps?.sx,
        },
      }}
      slotProps={{
        paper: {
          sx: {
            maxHeight: 'calc(100vh - 100px)', // Prevent menu from going off-screen
            overflow: 'auto',
            // Ensure menu doesn't get cropped
            zIndex: 1300,
          },
        },
      }}
    >
        {filteredItems.map((item, index) => (
          <React.Fragment key={item.id}>
            {item.divider && index !== 0 && <Divider />}
            <MenuItem
              onClick={() => {
                if (!item.disabled) {
                  item.onClick?.();
                  onClose();
                }
              }}
              disabled={item.disabled}
              sx={{
                color: item.color ? `${item.color}.main` : 'text.primary',
                borderRadius: 1,
                mx: 1,
                '&:hover': {
                  bgcolor: item.color === 'error' 
                    ? 'action.hover'
                    : item.color 
                      ? `${item.color}.light` 
                      : 'action.hover',
                },
                '&.Mui-disabled': {
                  color: 'text.disabled',
                },
              }}
            >
              {item.icon && (
                <ListItemIcon 
                  sx={{ 
                    minWidth: 36,
                    color: item.color ? `${item.color}.main` : 'inherit',
                  }}
                >
                  {item.icon}
                </ListItemIcon>
              )}
              <ListItemText 
                primary={item.label}
                primaryTypographyProps={{
                  fontSize: '0.875rem',
                  fontWeight: 500,
                }}
              />
            </MenuItem>
          </React.Fragment>
                ))}
    </Menu>
    );
};

// Alternative ActionMenuDropdown component that doesn't rely on MUI Popover
export const ActionMenuDropdown: React.FC<ActionMenuProps & {
  buttonRef: React.RefObject<HTMLElement>;
}> = ({
  items,
  onClose,
  buttonRef,
  menuProps,
  paperProps = {
    minWidth: 200,
    borderRadius: 2,
  },
}) => {
  const theme = useTheme();
  const filteredItems = items.filter(item => !item.hide);
  const [position, setPosition] = React.useState<{ x: number; y: number } | null>(null);

  React.useEffect(() => {
    if (buttonRef.current) {
      const rect = buttonRef.current.getBoundingClientRect();
      setPosition({
        x: rect.right,
        y: rect.bottom,
      });
    }
  }, [buttonRef]);

  React.useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (buttonRef.current && !buttonRef.current.contains(event.target as Node)) {
        onClose();
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [buttonRef, onClose]);

  if (!position) return null;

  return (
    <div
      style={{
        position: 'fixed',
        top: position.y,
        left: position.x,
        zIndex: 1300,
        minWidth: typeof paperProps.minWidth === 'number' ? paperProps.minWidth : 200,
        maxWidth: typeof paperProps.maxWidth === 'number' ? paperProps.maxWidth : undefined,
        borderRadius: paperProps.borderRadius || 8,
        boxShadow: paperProps.boxShadow || '0px 8px 24px rgba(0, 0, 0, 0.14)',
        background: paperProps.background || theme.palette.background.paper,
        backdropFilter: paperProps.backdropFilter,
        border: paperProps.border,
        maxHeight: 'calc(100vh - 100px)',
        overflow: 'auto',
        transform: 'translateX(-100%)', // Align to the right of the button
      }}
    >
      {filteredItems.map((item, index) => (
        <React.Fragment key={item.id}>
          {item.divider && index !== 0 && (
            <Divider sx={{ my: 0.5 }} />
          )}
          <MenuItem
            onClick={() => {
              if (!item.disabled) {
                item.onClick?.();
                onClose();
              }
            }}
            disabled={item.disabled}
            sx={{
              color: item.color ? `${item.color}.main` : 'text.primary',
              borderRadius: 1,
              mx: 1,
              '&:hover': {
                bgcolor: item.color === 'error' 
                  ? 'action.hover'
                  : item.color 
                    ? `${item.color}.light` 
                    : 'action.hover',
              },
              '&.Mui-disabled': {
                color: 'text.disabled',
              },
            }}
          >
            {item.icon && (
              <ListItemIcon 
                sx={{ 
                  minWidth: 36,
                  color: item.color ? `${item.color}.main` : 'inherit',
                }}
              >
                {item.icon}
              </ListItemIcon>
            )}
            <ListItemText 
              primary={item.label}
              primaryTypographyProps={{
                fontSize: '0.875rem',
                fontWeight: 500,
              }}
            />
          </MenuItem>
        </React.Fragment>
      ))}
    </div>
  );
};

// Hook for managing action menu state with dropdown alternative
export const useActionMenuDropdown = <T extends unknown>(
  onItemSelect?: (item: T) => void
) => {
  const [isOpen, setIsOpen] = React.useState(false);
  const [selectedItem, setSelectedItem] = React.useState<T | null>(null);
  const buttonRef = React.useRef<HTMLElement>(null);

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, item?: T) => {
    event.preventDefault();
    event.stopPropagation();
    
    setIsOpen(true);
    
    if (item) {
      setSelectedItem(item);
      onItemSelect?.(item);
    }
  };

  const handleMenuClose = () => {
    setIsOpen(false);
    setSelectedItem(null);
  };

  return {
    isOpen,
    selectedItem,
    buttonRef,
    handleMenuOpen,
    handleMenuClose,
  };
};

// Enhanced hook for managing action menu state with better anchor handling
export const useActionMenu = <T extends unknown>(
  onItemSelect?: (item: T) => void
) => {
  const [anchorEl, setAnchorEl] = React.useState<HTMLElement | null>(null);
  const [selectedItem, setSelectedItem] = React.useState<T | null>(null);
  const anchorRef = React.useRef<HTMLElement | null>(null);
  const menuId = React.useRef(`action-menu-${Math.random().toString(36).substr(2, 9)}`);

  const handleMenuOpen = React.useCallback((event: React.MouseEvent<HTMLElement>, item?: T) => {
    // Prevent default to avoid any potential issues
    event.preventDefault();
    event.stopPropagation();
    
    // Use currentTarget to get the button element that the event handler is attached to
    const target = event.currentTarget;
    
    // Store reference for validation
    anchorRef.current = target;
    
    // Set anchor element
    setAnchorEl(target);
    
    if (item) {
      setSelectedItem(item);
      onItemSelect?.(item);
    }
  }, [onItemSelect]);

  const handleMenuClose = React.useCallback(() => {
    setAnchorEl(null);
    setSelectedItem(null);
    anchorRef.current = null;
  }, []);

  // Cleanup on unmount
  React.useEffect(() => {
    return () => {
      setAnchorEl(null);
      setSelectedItem(null);
      anchorRef.current = null;
    };
  }, []);

  return {
    anchorEl,
    selectedItem,
    handleMenuOpen,
    handleMenuClose,
    menuId: menuId.current,
  };
};

// Alternative: Simple ActionMenu that doesn't use MUI Popover at all
export const SimpleActionMenu: React.FC<Omit<ActionMenuProps, 'anchorEl'> & {
  isOpen: boolean;
  anchorPosition?: { x: number; y: number };
}> = ({
  items,
  onClose,
  isOpen,
  anchorPosition,
  menuProps,
  paperProps = {
    minWidth: 200,
    borderRadius: 2,
  },
}) => {
  const theme = useTheme();
  const filteredItems = items.filter(item => !item.hide);
  const menuRef = React.useRef<HTMLDivElement>(null);
  const [adjustedPosition, setAdjustedPosition] = React.useState(anchorPosition);

  // Adjust position after menu renders to account for actual dimensions
  React.useEffect(() => {
    if (!isOpen || !anchorPosition || !menuRef.current) return;

    const adjustPosition = () => {
      const menuElement = menuRef.current;
      if (!menuElement) return;

      const rect = menuElement.getBoundingClientRect();
      const viewportWidth = window.innerWidth;
      const viewportHeight = window.innerHeight;

      let newX = anchorPosition.x;
      let newY = anchorPosition.y;

      // Check if menu goes off-screen and adjust
      if (rect.right > viewportWidth - 10) {
        newX = viewportWidth - rect.width - 10;
      }
      if (rect.bottom > viewportHeight - 10) {
        newY = viewportHeight - rect.height - 10;
      }
      if (rect.left < 10) {
        newX = 10;
      }
      if (rect.top < 10) {
        newY = 10;
      }

      setAdjustedPosition({ x: newX, y: newY });
    };

    // Use a small delay to ensure menu is rendered
    const timeoutId = setTimeout(adjustPosition, 10);
    return () => clearTimeout(timeoutId);
  }, [isOpen, anchorPosition]);

  // Add click outside detection
  React.useEffect(() => {
    if (!isOpen) return;

    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as Element;
      if (menuRef.current && !menuRef.current.contains(target)) {
        // Check if the click is not on an action menu button
        if (!target.closest('[data-action-menu]')) {
          onClose();
        }
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen, onClose]);

  if (!isOpen || !anchorPosition) return null;

  // Use adjusted position if available, otherwise use original position
  const finalPosition = adjustedPosition || anchorPosition;

  // Fallback: ensure menu is always within viewport
  const ensureInViewport = (pos: { x: number; y: number }) => {
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;
    const menuWidth = 220;
    const menuHeight = 250;

    let x = pos.x;
    let y = pos.y;

    // Ensure menu doesn't go off-screen
    if (x + menuWidth > viewportWidth) {
      x = viewportWidth - menuWidth - 10;
    }
    if (y + menuHeight > viewportHeight) {
      y = viewportHeight - menuHeight - 10;
    }
    if (x < 10) {
      x = 10;
    }
    if (y < 10) {
      y = 10;
    }

    return { x, y };
  };

  const safePosition = ensureInViewport(finalPosition);

  const handleItemClick = (item: ActionMenuItem) => {
    console.log('Menu item clicked:', item.id, item.label); // Debug log
    if (!item.disabled && item.onClick) {
      try {
        item.onClick();
        console.log('onClick executed successfully'); // Debug log
      } catch (error) {
        console.error('Error executing onClick:', error);
      }
    }
    onClose();
  };

  return (
    <div
      ref={menuRef}
      data-action-menu
      style={{
        position: 'fixed',
        top: safePosition.y,
        left: safePosition.x,
        zIndex: 1300,
        minWidth: typeof paperProps.minWidth === 'number' ? paperProps.minWidth : 200,
        maxWidth: typeof paperProps.maxWidth === 'number' ? paperProps.maxWidth : undefined,
        borderRadius: paperProps.borderRadius || 8,
        boxShadow: paperProps.boxShadow || '0px 8px 24px rgba(0, 0, 0, 0.14)',
        background: paperProps.background || theme.palette.background.paper,
        backdropFilter: paperProps.backdropFilter,
        border: paperProps.border,
        maxHeight: 'calc(100vh - 20px)', // Increased margin to prevent cropping
        overflow: 'auto',
        // Remove the transform to prevent positioning issues
        // transform: 'translateX(-100%)', // Align to the right of the button
      }}
    >
      {filteredItems.map((item, index) => (
        <React.Fragment key={item.id}>
          {item.divider && index !== 0 && (
            <Divider sx={{ my: 0.5 }} />
          )}
          <MenuItem
            onClick={() => handleItemClick(item)}
            disabled={item.disabled}
            sx={{
              color: item.color ? `${item.color}.main` : 'text.primary',
              borderRadius: 1,
              mx: 1,
              cursor: 'pointer',
              '&:hover': {
                bgcolor: item.color === 'error' 
                  ? 'action.hover'
                  : item.color 
                    ? `${item.color}.light` 
                    : 'action.hover',
              },
              '&.Mui-disabled': {
                color: 'text.disabled',
              },
            }}
          >
            {item.icon && (
              <ListItemIcon 
                sx={{ 
                  minWidth: 36,
                  color: item.color ? `${item.color}.main` : 'inherit',
                }}
              >
                {item.icon}
              </ListItemIcon>
            )}
            <ListItemText 
              primary={item.label}
              primaryTypographyProps={{
                fontSize: '0.875rem',
                fontWeight: 500,
              }}
            />
          </MenuItem>
        </React.Fragment>
      ))}
    </div>
  );
};

// Hook for SimpleActionMenu
export const useSimpleActionMenu = <T extends unknown>(
  onItemSelect?: (item: T) => void
) => {
  const [isOpen, setIsOpen] = React.useState(false);
  const [selectedItem, setSelectedItem] = React.useState<T | null>(null);
  const [anchorPosition, setAnchorPosition] = React.useState<{ x: number; y: number } | null>(null);

  const handleMenuOpen = React.useCallback((event: React.MouseEvent<HTMLElement>, item?: T) => {
    event.preventDefault();
    event.stopPropagation();
    
    const rect = event.currentTarget.getBoundingClientRect();
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;
    
    // Calculate optimal position with better boundary detection
    // Position menu exactly like Posts page - below and aligned with button
    let x = rect.right - 200; // Align menu right edge with button right edge
    let y = rect.bottom + 1; // Very small gap below the button for closer positioning
    
    // Menu dimensions (estimated)
    const menuWidth = 220; // Slightly larger to account for padding
    const menuHeight = 250; // Account for multiple menu items
    
    // Check if menu would go off-screen horizontally
    if (x + menuWidth > viewportWidth - 10) {
      x = rect.left - menuWidth; // Position to the left of anchor (like Posts page)
    }
    
    // Check if menu would go off-screen vertically
    if (y + menuHeight > viewportHeight - 10) {
      y = rect.top - menuHeight; // Position above anchor
    }
    
    // Ensure menu doesn't go off-screen at the top
    if (y < 10) {
      y = 10; // Small margin from top
    }
    
    // Ensure menu doesn't go off-screen at the left
    if (x < 10) {
      x = 10; // Small margin from left
    }
    
    // Ensure menu doesn't go off-screen at the right
    if (x + menuWidth > viewportWidth - 10) {
      x = viewportWidth - menuWidth - 10;
    }
    
    // Ensure menu doesn't go off-screen at the bottom
    if (y + menuHeight > viewportHeight - 10) {
      y = viewportHeight - menuHeight - 10;
    }
    
    setAnchorPosition({ x, y });
    setIsOpen(true);
    
    if (item) {
      setSelectedItem(item);
      onItemSelect?.(item);
    }
  }, [onItemSelect]);

  const handleMenuClose = React.useCallback(() => {
    setIsOpen(false);
    setSelectedItem(null);
    setAnchorPosition(null);
  }, []);

  // Close menu when clicking outside and update position on scroll
  React.useEffect(() => {
    if (!isOpen) return;

    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as Element;
      if (!target.closest('[data-action-menu]')) {
        handleMenuClose();
      }
    };

    const handleScroll = () => {
      // Close menu on scroll to avoid positioning issues
      handleMenuClose();
    };

    document.addEventListener('mousedown', handleClickOutside);
    window.addEventListener('scroll', handleScroll, { passive: true });
    window.addEventListener('resize', handleScroll, { passive: true });

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      window.removeEventListener('scroll', handleScroll);
      window.removeEventListener('resize', handleScroll);
    };
  }, [isOpen, handleMenuClose]);

  return {
    isOpen,
    selectedItem,
    anchorPosition,
    handleMenuOpen,
    handleMenuClose,
  };
}; 