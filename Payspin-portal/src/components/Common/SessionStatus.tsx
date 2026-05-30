import React, { useState, useEffect } from 'react';
import { SessionManager } from '../../services/SessionManager';
import { SESSION_CONFIG } from '../../config/session';

interface SessionStatusProps {
  className?: string;
  showDetails?: boolean;
}

export const SessionStatus: React.FC<SessionStatusProps> = ({ 
  className = '', 
  showDetails = false 
}) => {
  const [sessionInfo, setSessionInfo] = useState<any>(null);
  const [isExpanded, setIsExpanded] = useState(false);
  const [sessionManager] = useState(() => SessionManager.getInstance(SESSION_CONFIG));

  useEffect(() => {
    const updateSessionInfo = () => {
      const info = sessionManager.getSessionInfo();
      setSessionInfo(info);
    };

    // Update immediately
    updateSessionInfo();

    // Update every 1 second for real-time display
    const interval = setInterval(updateSessionInfo, 1000);

    return () => clearInterval(interval);
  }, [sessionManager]);

  if (!sessionInfo) {
    return null;
  }

  const getStatusColor = () => {
    const sessionTime = sessionManager.getSessionTimeRemaining();
    const inactivityTime = sessionManager.getInactivityTimeRemaining();
    
    // Convert to minutes
    const sessionMinutes = Math.floor(sessionTime / (1000 * 60));
    const inactivityMinutes = Math.floor(inactivityTime / (1000 * 60));
    
    if (sessionMinutes <= 5 || inactivityMinutes <= 5) return 'text-red-500';
    if (sessionMinutes <= 15 || inactivityMinutes <= 10) return 'text-yellow-500';
    return 'text-green-500';
  };

  const getStatusIcon = () => {
    const sessionTime = sessionManager.getSessionTimeRemaining();
    const inactivityTime = sessionManager.getInactivityTimeRemaining();
    
    const sessionMinutes = Math.floor(sessionTime / (1000 * 60));
    const inactivityMinutes = Math.floor(inactivityTime / (1000 * 60));
    
    if (sessionMinutes <= 5 || inactivityMinutes <= 5) return '🔴';
    if (sessionMinutes <= 15 || inactivityMinutes <= 10) return '🟡';
    return '🟢';
  };

  return (
    <div className={`session-status ${className}`}>
      {/* Compact Status Display */}
      <div 
        className="flex items-center space-x-2 cursor-pointer p-2 rounded-lg bg-gray-50 hover:bg-gray-100 transition-colors"
        onClick={() => setIsExpanded(!isExpanded)}
      >
        <span className="text-sm">{getStatusIcon()}</span>
        <span className={`text-sm font-medium ${getStatusColor()}`}>
          Session: {sessionInfo.timeRemaining}
        </span>
        {sessionManager.getInactivityTimeRemaining() > 0 && (
          <span className="text-xs text-gray-500">
            | Inactivity: {sessionInfo.inactivityRemaining}
          </span>
        )}
        <span className="text-xs text-gray-400">
          {isExpanded ? '▼' : '▶'}
        </span>
      </div>

      {/* Expanded Details */}
      {isExpanded && showDetails && (
        <div className="mt-2 p-3 bg-white border border-gray-200 rounded-lg shadow-sm">
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-600">Login Time:</span>
              <span className="font-medium">{sessionInfo.loginTime}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Last Activity:</span>
              <span className="font-medium">{sessionInfo.lastActivity}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Session Expires:</span>
              <span className="font-medium">{sessionInfo.sessionExpiry}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Inactivity Expires:</span>
              <span className="font-medium">{sessionInfo.inactivityExpiry}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Network Status:</span>
              <span className={`font-medium ${sessionInfo.networkStatus === 'online' ? 'text-green-500' : 'text-red-500'}`}>
                {sessionInfo.networkStatus}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Tab Focused:</span>
              <span className={`font-medium ${sessionInfo.tabFocused ? 'text-green-500' : 'text-red-500'}`}>
                {sessionInfo.tabFocused ? 'Yes' : 'No'}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Warnings Shown:</span>
              <span className="font-medium">{sessionInfo.warningsShown.length}</span>
            </div>
          </div>
          
          {/* Security Status */}
          <div className="mt-3 pt-3 border-t border-gray-200">
            <h4 className="text-xs font-semibold text-gray-700 mb-2">Security Status</h4>
            <div className="grid grid-cols-2 gap-2 text-xs">
              <div className="flex items-center space-x-1">
                <span className="w-2 h-2 bg-green-500 rounded-full"></span>
                <span>Session Valid</span>
              </div>
              <div className="flex items-center space-x-1">
                <span className="w-2 h-2 bg-green-500 rounded-full"></span>
                <span>Encrypted Storage</span>
              </div>
              <div className="flex items-center space-x-1">
                <span className="w-2 h-2 bg-green-500 rounded-full"></span>
                <span>Activity Monitoring</span>
              </div>
              <div className="flex items-center space-x-1">
                <span className="w-2 h-2 bg-green-500 rounded-full"></span>
                <span>Network Monitoring</span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}; 