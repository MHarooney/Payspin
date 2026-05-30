import { useEffect, useState, useCallback, useMemo } from 'react';
import { User as FirebaseUser } from 'firebase/auth';
import { useIdle } from './useIdleTimer';

interface SessionTimeoutConfig {
  sessionDurationHours: number;
  inactivityTimeoutMinutes: number;
  warningTimeSeconds: number;
}

interface UseSessionTimeoutProps {
  user: FirebaseUser | null;
  onSessionExpired: () => void;
  config?: Partial<SessionTimeoutConfig>;
}

export const useSessionTimeout = ({
  user,
  onSessionExpired,
  config = {}
}: UseSessionTimeoutProps) => {
  const [sessionStartTime, setSessionStartTime] = useState<number | null>(null);
  const [lastActivityTime, setLastActivityTime] = useState<number | null>(null);
  const [showWarning, setShowWarning] = useState(false);
  const [remainingTime, setRemainingTime] = useState(0);

  const defaultConfig = useMemo<SessionTimeoutConfig>(() => ({
    sessionDurationHours: 1,
    inactivityTimeoutMinutes: 30,
    warningTimeSeconds: 30,
    ...config
  }), [config]);

  // Initialize session when user logs in
  useEffect(() => {
    if (user && !sessionStartTime) {
      const now = Date.now();
      setSessionStartTime(now);
      setLastActivityTime(now);
      
      // Save session info to localStorage
      const sessionInfo = {
        startTime: now,
        lastActivity: now,
        userId: user.uid,
        sessionDuration: defaultConfig.sessionDurationHours,
        inactivityTimeout: defaultConfig.inactivityTimeoutMinutes
      };
      
      localStorage.setItem('payspin_session_timeout', JSON.stringify(sessionInfo));
      console.log('✅ Session timeout initialized for user:', user.uid);
    } else if (!user) {
      // Clear session when user logs out
      setSessionStartTime(null);
      setLastActivityTime(null);
      setShowWarning(false);
      setRemainingTime(0);
      localStorage.removeItem('payspin_session_timeout');
      console.log('🔄 Session timeout cleared');
    }
  }, [user, sessionStartTime, defaultConfig]);

  // Restore session from localStorage on page load
  useEffect(() => {
    if (user && !sessionStartTime) {
      const savedSession = localStorage.getItem('payspin_session_timeout');
      if (savedSession) {
        try {
          const sessionInfo = JSON.parse(savedSession);
          const now = Date.now();
          
          // Check if session is still valid
          const sessionAge = now - sessionInfo.startTime;
          const sessionDurationMs = defaultConfig.sessionDurationHours * 60 * 60 * 1000;
          
          if (sessionAge < sessionDurationMs) {
            setSessionStartTime(sessionInfo.startTime);
            setLastActivityTime(sessionInfo.lastActivity || now);
            console.log('✅ Session timeout restored from storage');
          } else {
            console.log('❌ Session expired, clearing storage');
            localStorage.removeItem('payspin_session_timeout');
          }
        } catch (error) {
          console.error('❌ Error restoring session timeout:', error);
          localStorage.removeItem('payspin_session_timeout');
        }
      }
    }
  }, [user, sessionStartTime, defaultConfig]);

  // Handle user activity
  const handleActivity = useCallback(() => {
    if (user && sessionStartTime) {
      const now = Date.now();
      setLastActivityTime(now);
      
      // Update localStorage
      const sessionInfo = {
        startTime: sessionStartTime,
        lastActivity: now,
        userId: user.uid,
        sessionDuration: defaultConfig.sessionDurationHours,
        inactivityTimeout: defaultConfig.inactivityTimeoutMinutes
      };
      
      localStorage.setItem('payspin_session_timeout', JSON.stringify(sessionInfo));
      
      // Hide warning if it was showing
      if (showWarning) {
        setShowWarning(false);
        setRemainingTime(0);
        console.log('✅ User activity detected, hiding timeout warning');
      }
    }
  }, [user, sessionStartTime, showWarning, defaultConfig]);

  // Handle idle state
  const handleIdle = useCallback(() => {
    if (user && sessionStartTime) {
      console.log('🔄 User became idle, showing timeout warning');
      setShowWarning(true);
      setRemainingTime(defaultConfig.warningTimeSeconds);
    }
  }, [user, sessionStartTime, defaultConfig]);

  // Use the idle timer hook
  const { isIdle } = useIdle({
    onIdle: handleIdle,
    idleTime: defaultConfig.inactivityTimeoutMinutes,
    debounce: 500
  });

  // Countdown timer for warning
  useEffect(() => {
    let interval: NodeJS.Timeout;

    if (showWarning && remainingTime > 0) {
      interval = setInterval(() => {
        setRemainingTime((prev) => {
          if (prev <= 1) {
            console.log('⏰ Session timeout countdown finished');
            onSessionExpired();
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
    }

    return () => {
      if (interval) {
        clearInterval(interval);
      }
    };
  }, [showWarning, remainingTime, onSessionExpired]);

  // Check session expiration periodically
  useEffect(() => {
    if (!user || !sessionStartTime) return;

    const checkSessionExpiration = () => {
      const now = Date.now();
      const sessionAge = now - sessionStartTime;
      const sessionDurationMs = defaultConfig.sessionDurationHours * 60 * 60 * 1000;
      
      if (sessionAge >= sessionDurationMs) {
        console.log('⏰ Session duration expired');
        onSessionExpired();
      }
    };

    const interval = setInterval(checkSessionExpiration, 60000); // Check every minute

    return () => clearInterval(interval);
  }, [user, sessionStartTime, defaultConfig, onSessionExpired]);

  // Handle user activity events
  useEffect(() => {
    if (!user || !sessionStartTime) return;

    const events = [
      'mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart', 'click',
      'keydown', 'keyup', 'mouseup', 'focus', 'blur',
      'input', 'change', 'submit', 'wheel', 'drag', 'drop'
    ];

    const handleUserActivity = () => {
      handleActivity();
    };

    events.forEach(event => {
      document.addEventListener(event, handleUserActivity, { capture: true });
    });

    return () => {
      events.forEach(event => {
        document.removeEventListener(event, handleUserActivity, { capture: true });
      });
    };
  }, [user, sessionStartTime, handleActivity]);

  // Calculate remaining session time
  const getRemainingSessionTime = useCallback(() => {
    if (!sessionStartTime) return 0;
    
    const now = Date.now();
    const sessionAge = now - sessionStartTime;
    const sessionDurationMs = defaultConfig.sessionDurationHours * 60 * 60 * 1000;
    
    return Math.max(0, sessionDurationMs - sessionAge);
  }, [sessionStartTime, defaultConfig]);

  // Calculate remaining inactivity time
  const getRemainingInactivityTime = useCallback(() => {
    if (!lastActivityTime) return 0;
    
    const now = Date.now();
    const inactivityAge = now - lastActivityTime;
    const inactivityTimeoutMs = defaultConfig.inactivityTimeoutMinutes * 60 * 1000;
    
    return Math.max(0, inactivityTimeoutMs - inactivityAge);
  }, [lastActivityTime, defaultConfig]);

  const handleStayLoggedIn = useCallback(() => {
    console.log('✅ User chose to stay logged in');
    setShowWarning(false);
    setRemainingTime(0);
    handleActivity();
  }, [handleActivity]);

  const handleLogout = useCallback(() => {
    console.log('🚪 User logged out due to session timeout');
    setShowWarning(false);
    setRemainingTime(0);
    onSessionExpired();
  }, [onSessionExpired]);

  return {
    showWarning,
    remainingTime,
    isIdle,
    getRemainingSessionTime,
    getRemainingInactivityTime,
    handleStayLoggedIn,
    handleLogout,
    handleActivity
  };
}; 