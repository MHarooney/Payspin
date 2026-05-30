import { useEffect, useState } from 'react';
import { User as FirebaseUser } from 'firebase/auth';
import { SessionManager } from '../services/SessionManager';
import { SESSION_CONFIG } from '../config/session';

export const useSessionManager = (
  user: FirebaseUser | null,
  onSessionExpired: () => void
): void => {
  const [sessionManager] = useState(() => SessionManager.getInstance(SESSION_CONFIG));

  useEffect(() => {
    if (!sessionManager) return;

    // Set the session expired callback
    sessionManager.setSessionExpiredCallback(onSessionExpired);

    // If user is logged in, try to restore or start session
    if (user) {
      const restored = sessionManager.restoreSessionFromStorage();
      if (!restored) {
        sessionManager.startSession(user);
      }
    } else {
      sessionManager.endSession();
    }

    // No need for UI updates
  }, [user, sessionManager, onSessionExpired]);

  // Track user activity with enhanced event detection
  useEffect(() => {
    const handleActivity = () => {
      sessionManager.updateActivity();
    };

    // Enhanced activity events for better security
    const events = [
      'mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart', 'click',
      'keydown', 'keyup', 'mousedown', 'mouseup', 'focus', 'blur',
      'input', 'change', 'submit', 'wheel', 'drag', 'drop'
    ];
    
    // Add activity listeners with passive option for better performance
    events.forEach(event => {
      document.addEventListener(event, handleActivity, { passive: true, capture: true });
    });

    return () => {
      // Remove activity listeners
      events.forEach(event => {
        document.removeEventListener(event, handleActivity, { capture: true });
      });
    };
  }, [sessionManager]);

  // Additional security: Monitor for suspicious activity
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.hidden) {
        // User switched tabs or minimized window
        console.log('User switched away from tab');
      } else {
        // User returned to tab - validate session
        if (user && sessionManager) {
          // Force session validation when user returns
          setTimeout(() => {
            if (!sessionManager.isSessionValid()) {
              console.log('Session invalidated while user was away');
              onSessionExpired();
            }
          }, 1000);
        }
      }
    };

    const handleBeforeUnload = (event: BeforeUnloadEvent) => {
      // Warn user if they have unsaved changes (optional)
      // event.preventDefault();
      // event.returnValue = '';
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('beforeunload', handleBeforeUnload);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('beforeunload', handleBeforeUnload);
    };
  }, [user, sessionManager, onSessionExpired]);

  // No return needed for background-only functionality
}; 