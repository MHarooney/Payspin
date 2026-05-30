import { User as FirebaseUser } from 'firebase/auth';
import toast from 'react-hot-toast';

export interface SessionConfig {
  sessionDurationHours: number;
  inactivityTimeoutMinutes: number;
  warningMinutes: number[]; // Array of warning times in minutes
  tokenRefreshIntervalMinutes: number;
  
  // Security features
  enableInactivityDetection: boolean;
  enableTabFocusDetection: boolean;
  enableNetworkMonitoring: boolean;
  enableSessionFingerprinting: boolean;
  enableAuditLogging: boolean;
  
  // Storage security
  enableEncryptedStorage: boolean;
  storageEncryptionKey: string;
  
  // Session validation
  validateSessionOnTabFocus: boolean;
  validateSessionOnNetworkChange: boolean;
  
  // Audit settings
  logSessionEvents: boolean;
  logSecurityEvents: boolean;
}

export interface SessionState {
  loginTime: number;
  lastActivity: number;
  isSessionValid: boolean;
  sessionExpiry: number;
  inactivityExpiry: number;
  sessionFingerprint: string;
  networkStatus: 'online' | 'offline';
  tabFocused: boolean;
  warningsShown: number[];
}

export interface AuditEvent {
  timestamp: number;
  event: string;
  details: any;
  sessionId: string;
}

export class SessionManager {
  private static instance: SessionManager;
  private config: SessionConfig;
  private sessionState: SessionState | null = null;
  private sessionTimer: NodeJS.Timeout | null = null;
  private inactivityTimer: NodeJS.Timeout | null = null;
  private tokenRefreshTimer: NodeJS.Timeout | null = null;
  private onSessionExpired: (() => void) | null = null;
  private auditLog: AuditEvent[] = [];
  private networkStatus: 'online' | 'offline' = 'online';
  private tabFocused: boolean = true;

  private constructor(config: SessionConfig) {
    this.config = config;
    this.initializeSecurityFeatures();
  }

  public static getInstance(config?: SessionConfig): SessionManager {
    if (!SessionManager.instance) {
      const defaultConfig: SessionConfig = {
        sessionDurationHours: 1,
        inactivityTimeoutMinutes: 30,
        warningMinutes: [15, 10, 5, 1],
        tokenRefreshIntervalMinutes: 15,
        enableInactivityDetection: true,
        enableTabFocusDetection: true,
        enableNetworkMonitoring: true,
        enableSessionFingerprinting: true,
        enableAuditLogging: true,
        enableEncryptedStorage: true,
        storageEncryptionKey: 'payspin_session_key_2024',
        validateSessionOnTabFocus: true,
        validateSessionOnNetworkChange: true,
        logSessionEvents: true,
        logSecurityEvents: true,
      };
      SessionManager.instance = new SessionManager(config || defaultConfig);
    }
    return SessionManager.instance;
  }

  private initializeSecurityFeatures(): void {
    if (this.config.enableNetworkMonitoring) {
      this.setupNetworkMonitoring();
    }
    
    if (this.config.enableTabFocusDetection) {
      this.setupTabFocusDetection();
    }
  }

  private setupNetworkMonitoring(): void {
    window.addEventListener('online', () => {
      this.networkStatus = 'online';
      this.logAuditEvent('network_online', { previousStatus: 'offline' });
      if (this.config.validateSessionOnNetworkChange) {
        this.validateSession();
      }
    });

    window.addEventListener('offline', () => {
      this.networkStatus = 'offline';
      this.logAuditEvent('network_offline', { previousStatus: 'online' });
    });
  }

  private setupTabFocusDetection(): void {
    document.addEventListener('visibilitychange', () => {
      this.tabFocused = !document.hidden;
      this.logAuditEvent('tab_visibility_change', { 
        focused: this.tabFocused,
        timestamp: Date.now()
      });
      
      if (this.config.validateSessionOnTabFocus && this.tabFocused) {
        this.validateSession();
      }
    });

    window.addEventListener('focus', () => {
      this.tabFocused = true;
      if (this.config.validateSessionOnTabFocus) {
        this.validateSession();
      }
    });

    window.addEventListener('blur', () => {
      this.tabFocused = false;
    });
  }

  private generateSessionFingerprint(): string {
    const fingerprint = {
      userAgent: navigator.userAgent,
      language: navigator.language,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      screenResolution: `${window.screen.width}x${window.screen.height}`,
      colorDepth: window.screen.colorDepth,
      timestamp: Date.now(),
    };
    
    return btoa(JSON.stringify(fingerprint));
  }

  private encryptData(data: string): string {
    if (!this.config.enableEncryptedStorage) return data;
    
    // Simple XOR encryption for demo purposes
    // In production, use a proper encryption library
    const key = this.config.storageEncryptionKey;
    let encrypted = '';
    for (let i = 0; i < data.length; i++) {
      encrypted += String.fromCharCode(data.charCodeAt(i) ^ key.charCodeAt(i % key.length));
    }
    return btoa(encrypted);
  }

  private decryptData(encryptedData: string): string {
    if (!this.config.enableEncryptedStorage) return encryptedData;
    
    try {
      const data = atob(encryptedData);
      const key = this.config.storageEncryptionKey;
      let decrypted = '';
      for (let i = 0; i < data.length; i++) {
        decrypted += String.fromCharCode(data.charCodeAt(i) ^ key.charCodeAt(i % key.length));
      }
      return decrypted;
    } catch (error: any) {
      console.error('Failed to decrypt session data:', error);
      return '';
    }
  }

  private logAuditEvent(event: string, details: any = {}): void {
    if (!this.config.enableAuditLogging) return;
    
    const auditEvent: AuditEvent = {
      timestamp: Date.now(),
      event,
      details,
      sessionId: this.sessionState?.sessionFingerprint || 'no-session',
    };
    
    this.auditLog.push(auditEvent);
    
    // Keep only last 100 events
    if (this.auditLog.length > 100) {
      this.auditLog = this.auditLog.slice(-100);
    }
    
    if (this.config.logSecurityEvents) {
      // Audit logging disabled
    }
  }

  public setSessionExpiredCallback(callback: () => void): void {
    this.onSessionExpired = callback;
  }

  public startSession(user: FirebaseUser): void {
    const now = Date.now();
    const sessionDurationMs = this.config.sessionDurationHours * 60 * 60 * 1000;
    const inactivityDurationMs = this.config.inactivityTimeoutMinutes * 60 * 1000;
    
    this.sessionState = {
      loginTime: now,
      lastActivity: now,
      isSessionValid: true,
      sessionExpiry: now + sessionDurationMs,
      inactivityExpiry: now + inactivityDurationMs,
      sessionFingerprint: this.generateSessionFingerprint(),
      networkStatus: this.networkStatus,
      tabFocused: this.tabFocused,
      warningsShown: [],
    };

    this.saveSessionToStorage();
    this.startSessionMonitoring();
    this.startInactivityMonitoring();
    this.startTokenRefresh(user);

    this.logAuditEvent('session_started', {
      userId: user.uid,
      sessionDuration: this.config.sessionDurationHours,
      inactivityTimeout: this.config.inactivityTimeoutMinutes,
    });


  }

  public updateActivity(): void {
    if (this.sessionState && this.sessionState.isSessionValid) {
      const now = Date.now();
      this.sessionState.lastActivity = now;
      this.sessionState.inactivityExpiry = now + (this.config.inactivityTimeoutMinutes * 60 * 1000);
      this.saveSessionToStorage();
      
      this.logAuditEvent('activity_updated', {
        lastActivity: now,
        inactivityExpiry: this.sessionState.inactivityExpiry,
      });
    }
  }

  public endSession(): void {
    this.logAuditEvent('session_ended', {
      reason: 'manual_logout',
      sessionDuration: this.sessionState ? Date.now() - this.sessionState.loginTime : 0,
    });
    
    this.sessionState = null;
    this.clearTimers();
    this.clearSessionFromStorage();
  }

  public isSessionValid(): boolean {
    if (!this.sessionState) return false;
    
    const now = Date.now();
    const sessionValid = this.sessionState.isSessionValid && now < this.sessionState.sessionExpiry;
    const inactivityValid = now < this.sessionState.inactivityExpiry;
    
    return sessionValid && inactivityValid;
  }

  public getSessionTimeRemaining(): number {
    if (!this.sessionState) return 0;
    return Math.max(0, this.sessionState.sessionExpiry - Date.now());
  }

  public getInactivityTimeRemaining(): number {
    if (!this.sessionState) return 0;
    return Math.max(0, this.sessionState.inactivityExpiry - Date.now());
  }

  public getSessionTimeRemainingFormatted(): string {
    const timeRemaining = this.getSessionTimeRemaining();
    const hours = Math.floor(timeRemaining / (1000 * 60 * 60));
    const minutes = Math.floor((timeRemaining % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((timeRemaining % (1000 * 60)) / 1000);
    
    if (hours > 0) {
      return `${hours}h ${minutes}m`;
    } else if (minutes > 0) {
      return `${minutes}m ${seconds}s`;
    } else {
      return `${seconds}s`;
    }
  }

  public getInactivityTimeRemainingFormatted(): string {
    const timeRemaining = this.getInactivityTimeRemaining();
    const minutes = Math.floor(timeRemaining / (1000 * 60));
    const seconds = Math.floor((timeRemaining % (1000 * 60)) / 1000);
    
    if (minutes > 0) {
      return `${minutes}m ${seconds}s`;
    } else {
      return `${seconds}s`;
    }
  }

  public restoreSessionFromStorage(): boolean {
    try {
      const sessionData = localStorage.getItem('payspin_session');
      if (!sessionData) return false;

      const decryptedData = this.decryptData(sessionData);
      const restored: SessionState = JSON.parse(decryptedData);
      const now = Date.now();

      // Validate session fingerprint if enabled
      if (this.config.enableSessionFingerprinting) {
        const currentFingerprint = this.generateSessionFingerprint();
        if (restored.sessionFingerprint !== currentFingerprint) {
          this.logAuditEvent('session_fingerprint_mismatch', {
            stored: restored.sessionFingerprint,
            current: currentFingerprint,
          });
          this.clearSessionFromStorage();
          return false;
        }
      }

      // Check if the stored session is still valid
      if (restored.isSessionValid && now < restored.sessionExpiry && now < restored.inactivityExpiry) {
        this.sessionState = restored;
        this.startSessionMonitoring();
        this.startInactivityMonitoring();
        
        this.logAuditEvent('session_restored', {
          sessionAge: now - restored.loginTime,
        });
        
        return true;
      } else {
        this.logAuditEvent('session_restore_failed', {
          reason: 'expired',
          sessionExpiry: restored.sessionExpiry,
          inactivityExpiry: restored.inactivityExpiry,
        });
        this.clearSessionFromStorage();
        return false;
      }
    } catch (error: any) {
      console.error('Error restoring session:', error);
      this.logAuditEvent('session_restore_error', { error: error.message });
      this.clearSessionFromStorage();
      return false;
    }
  }

  private validateSession(): void {
    if (!this.sessionState) return;
    
    const now = Date.now();
    const sessionValid = this.sessionState.isSessionValid && now < this.sessionState.sessionExpiry;
    const inactivityValid = now < this.sessionState.inactivityExpiry;
    
    if (!sessionValid || !inactivityValid) {
      this.logAuditEvent('session_validation_failed', {
        sessionValid,
        inactivityValid,
        sessionExpiry: this.sessionState.sessionExpiry,
        inactivityExpiry: this.sessionState.inactivityExpiry,
      });
      this.handleSessionExpired();
    }
  }

  private startSessionMonitoring(): void {
    this.clearTimers();

    // Check session every 10 seconds for real-time security
    this.sessionTimer = setInterval(() => {
      this.checkSession();
    }, 10 * 1000);
  }

  private startInactivityMonitoring(): void {
    if (!this.config.enableInactivityDetection) return;
    
    // Check inactivity every 30 seconds for real-time monitoring
    this.inactivityTimer = setInterval(() => {
      this.checkInactivity();
    }, 30 * 1000);
  }

  private startTokenRefresh(user: FirebaseUser): void {
    // Refresh token every 15 minutes (or configured interval)
    this.tokenRefreshTimer = setInterval(async () => {
      try {
        await user.getIdToken(true); // Force refresh
        this.logAuditEvent('token_refreshed', { success: true });
          } catch (error: any) {
      console.error('Token refresh failed:', error);
      this.logAuditEvent('token_refresh_failed', { error: error.message });
      this.handleSessionExpired();
    }
    }, this.config.tokenRefreshIntervalMinutes * 60 * 1000);
  }

  private checkSession(): void {
    if (!this.sessionState || !this.sessionState.isSessionValid) return;

    const now = Date.now();
    const timeRemaining = this.sessionState.sessionExpiry - now;

    // Show warnings at configured intervals
    this.config.warningMinutes.forEach(warningTime => {
      const warningTimeMs = warningTime * 60 * 1000;
      if (timeRemaining <= warningTimeMs && !this.sessionState!.warningsShown.includes(warningTime)) {
        this.showSessionWarning(warningTime);
        this.sessionState!.warningsShown.push(warningTime);
        this.saveSessionToStorage();
      }
    });

    // Check if session has expired
    if (timeRemaining <= 0) {
      this.logAuditEvent('session_expired', { reason: 'timeout' });
      this.handleSessionExpired();
    }
  }

  private checkInactivity(): void {
    if (!this.sessionState || !this.config.enableInactivityDetection) return;

    const now = Date.now();
    const inactivityTimeRemaining = this.sessionState.inactivityExpiry - now;

    if (inactivityTimeRemaining <= 0) {
      this.logAuditEvent('session_expired', { reason: 'inactivity' });
      this.handleSessionExpired();
    } else if (inactivityTimeRemaining <= 5 * 60 * 1000 && !this.sessionState.warningsShown.includes(-1)) {
      // Show inactivity warning 5 minutes before expiry
      this.showInactivityWarning(Math.ceil(inactivityTimeRemaining / (60 * 1000)));
      this.sessionState.warningsShown.push(-1);
      this.saveSessionToStorage();
    }
  }

  private showSessionWarning(minutesRemaining: number): void {
    const message = `Your session will expire in ${minutesRemaining} minute${minutesRemaining !== 1 ? 's' : ''}. Please save your work.`;
    toast.error(message, { duration: 10000 });
    
    this.logAuditEvent('session_warning_shown', { minutesRemaining });
  }

  private showInactivityWarning(minutesRemaining: number): void {
    const message = `You will be logged out due to inactivity in ${minutesRemaining} minute${minutesRemaining !== 1 ? 's' : ''}.`;
    toast.error(message, { duration: 10000 });
    
    this.logAuditEvent('inactivity_warning_shown', { minutesRemaining });
  }

  private handleSessionExpired(): void {
    if (this.sessionState) {
      this.sessionState.isSessionValid = false;
      this.saveSessionToStorage();
    }



    // Call the session expired callback (logout function)
    if (this.onSessionExpired) {
      this.onSessionExpired();
    }

    this.endSession();
  }

  private saveSessionToStorage(): void {
    if (this.sessionState) {
      const sessionData = JSON.stringify(this.sessionState);
      const encryptedData = this.encryptData(sessionData);
      localStorage.setItem('payspin_session', encryptedData);
    }
  }

  private clearSessionFromStorage(): void {
    localStorage.removeItem('payspin_session');
  }

  private clearTimers(): void {
    if (this.sessionTimer) {
      clearInterval(this.sessionTimer);
      this.sessionTimer = null;
    }
    if (this.inactivityTimer) {
      clearInterval(this.inactivityTimer);
      this.inactivityTimer = null;
    }
    if (this.tokenRefreshTimer) {
      clearInterval(this.tokenRefreshTimer);
      this.tokenRefreshTimer = null;
    }
  }

  // Public methods for debugging and monitoring
  public getAuditLog(): AuditEvent[] {
    return [...this.auditLog];
  }

  public getSessionInfo(): any {
    if (!this.sessionState) return null;
    
    return {
      loginTime: new Date(this.sessionState.loginTime).toLocaleString(),
      lastActivity: new Date(this.sessionState.lastActivity).toLocaleString(),
      sessionExpiry: new Date(this.sessionState.sessionExpiry).toLocaleString(),
      inactivityExpiry: new Date(this.sessionState.inactivityExpiry).toLocaleString(),
      timeRemaining: this.getSessionTimeRemainingFormatted(),
      inactivityRemaining: this.getInactivityTimeRemainingFormatted(),
      warningsShown: this.sessionState.warningsShown,
      networkStatus: this.networkStatus,
      tabFocused: this.tabFocused,
    };
  }
} 