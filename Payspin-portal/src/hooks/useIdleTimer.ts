import { useIdleTimer } from 'react-idle-timer';
import { useState } from 'react';

interface UseIdleOptions {
  onIdle: () => void;
  idleTime: number; // in minutes
  debounce?: number;
}

export const useIdle = ({ onIdle, idleTime, debounce = 500 }: UseIdleOptions) => {
  const [isIdle, setIsIdle] = useState<boolean>(false);

  const handleOnIdle = (event: any) => {
    setIsIdle(true);
    
    const currentTime = new Date();
    const formattedCurrentTime = currentTime.toLocaleString("en-US", {
      weekday: "short",
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "numeric",
      second: "numeric",
      timeZoneName: "short",
    });

    console.log("🔄 User is idle", event);
    console.log("🔄 Last Active time", getLastActiveTime());
    console.log("🔄 Current time", formattedCurrentTime);

    onIdle();
  };

  const {
    getLastActiveTime,
    getRemainingTime,
    getElapsedTime,
    getTotalElapsedTime,
    getTotalIdleTime,
    getTotalActiveTime,
    isIdle: isIdleTimer,
    pause,
    resume,
    reset,
  } = useIdleTimer({
    timeout: 1000 * 60 * idleTime, // Convert minutes to milliseconds
    onIdle: handleOnIdle,
    debounce,
    events: [
      'mousedown',
      'mousemove',
      'keypress',
      'scroll',
      'touchstart',
      'click',
      'keydown',
      'keyup',
      'mouseup',
      'focus',
      'blur',
      'input',
      'change',
      'submit',
      'wheel',
      'drag',
      'drop',
      'pointerdown',
      'pointermove',
      'pointerup'
    ],
  });

  return {
    isIdle,
    getLastActiveTime,
    getRemainingTime,
    getElapsedTime,
    getTotalElapsedTime,
    getTotalIdleTime,
    getTotalActiveTime,
    isIdleTimer,
    pause,
    resume,
    reset,
  };
}; 