import { SessionConfig } from '../services/SessionManager';

/**
 * Enhanced Session Configuration for Maximum Security
 * Automatic logout every 1 hour with inactivity detection
 */
export const SESSION_CONFIG: SessionConfig = {
  // Primary session timeout - 1 hour for enhanced security
  sessionDurationHours: 1,
  
  // Inactivity timeout - 30 minutes of no activity
  inactivityTimeoutMinutes: 30,
  
  // Warning levels (multiple warnings before expiry)
  warningMinutes: [15, 10, 5, 1],
  
  // Token refresh interval - more frequent for security
  tokenRefreshIntervalMinutes: 15,
  
  // Security features
  enableInactivityDetection: true,
  enableTabFocusDetection: true,
  enableNetworkMonitoring: true,
  enableSessionFingerprinting: true,
  enableAuditLogging: true,
  
  // Storage security
  enableEncryptedStorage: true,
  storageEncryptionKey: 'payspin_session_key_2024',
  
  // Session validation
  validateSessionOnTabFocus: true,
  validateSessionOnNetworkChange: true,
  
  // Audit settings
  logSessionEvents: true,
  logSecurityEvents: true,
}; 