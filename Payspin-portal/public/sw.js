// Service Worker for Payspin Admin Portal Session Management
// This service worker runs in the background to monitor session state

const CACHE_NAME = 'payspin-admin-v1';
const SESSION_CACHE_KEY = 'payspin_session_background';

// Install event - cache essential resources
self.addEventListener('install', (event) => {
  console.log('Service Worker installing...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        return cache.addAll([
          '/',
          '/static/js/bundle.js',
          '/static/css/main.css',
          '/favicon.ico'
        ]);
      })
      .then(() => {
        console.log('Service Worker installed successfully');
        return self.skipWaiting();
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('Service Worker activating...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('Service Worker activated successfully');
      return self.clients.claim();
    })
  );
});

// Background session monitoring
let sessionData = null;
let sessionCheckInterval = null;

// Handle messages from the main thread
self.addEventListener('message', (event) => {
  const { type, data } = event.data;

  switch (type) {
    case 'SESSION_DATA':
      console.log('Received session data from main thread');
      sessionData = data;
      startSessionMonitoring();
      break;
    
    case 'SESSION_EXPIRED':
      console.log('Session expired notification received');
      stopSessionMonitoring();
      notifyClients('SESSION_EXPIRED');
      break;
    
    case 'UPDATE_SESSION':
      console.log('Session update received');
      sessionData = data;
      break;
    
    default:
      console.log('Unknown message type:', type);
  }
});

// Start monitoring session in background
function startSessionMonitoring() {
  if (sessionCheckInterval) {
    clearInterval(sessionCheckInterval);
  }

  sessionCheckInterval = setInterval(() => {
    if (sessionData) {
      const now = Date.now();
      const sessionValid = sessionData.isSessionValid && now < sessionData.sessionExpiry;
      const inactivityValid = now < sessionData.inactivityExpiry;

      if (!sessionValid || !inactivityValid) {
        console.log('Session expired in background');
        stopSessionMonitoring();
        notifyClients('SESSION_EXPIRED');
      } else {
        // Update session data with current time
        sessionData.lastActivity = now;
        sessionData.inactivityExpiry = now + (30 * 60 * 1000); // 30 minutes
        
        // Store updated session data
        storeSessionData(sessionData);
      }
    }
  }, 30 * 1000); // Check every 30 seconds
}

// Stop session monitoring
function stopSessionMonitoring() {
  if (sessionCheckInterval) {
    clearInterval(sessionCheckInterval);
    sessionCheckInterval = null;
  }
  sessionData = null;
}

// Store session data in IndexedDB for persistence
async function storeSessionData(data) {
  try {
    const db = await openDB('payspin-session', 1, {
      upgrade(db) {
        if (!db.objectStoreNames.contains('sessions')) {
          db.createObjectStore('sessions', { keyPath: 'id' });
        }
      },
    });

    await db.put('sessions', {
      id: 'current',
      data: data,
      timestamp: Date.now()
    });
  } catch (error) {
    console.error('Failed to store session data:', error);
  }
}

// Retrieve session data from IndexedDB
async function retrieveSessionData() {
  try {
    const db = await openDB('payspin-session', 1, {
      upgrade(db) {
        if (!db.objectStoreNames.contains('sessions')) {
          db.createObjectStore('sessions', { keyPath: 'id' });
        }
      },
    });

    const result = await db.get('sessions', 'current');
    return result ? result.data : null;
  } catch (error) {
    console.error('Failed to retrieve session data:', error);
    return null;
  }
}

// Notify all clients about session events
function notifyClients(eventType) {
  self.clients.matchAll().then((clients) => {
    clients.forEach((client) => {
      client.postMessage({
        type: eventType,
        timestamp: Date.now()
      });
    });
  });
}

// Handle background sync for session validation
self.addEventListener('sync', (event) => {
  if (event.tag === 'session-validation') {
    console.log('Background sync for session validation');
    event.waitUntil(validateSessionInBackground());
  }
});

// Validate session in background
async function validateSessionInBackground() {
  try {
    const storedSession = await retrieveSessionData();
    if (storedSession) {
      const now = Date.now();
      const sessionValid = storedSession.isSessionValid && now < storedSession.sessionExpiry;
      const inactivityValid = now < storedSession.inactivityExpiry;

      if (!sessionValid || !inactivityValid) {
        console.log('Background session validation failed');
        notifyClients('SESSION_EXPIRED');
      }
    }
  } catch (error) {
    console.error('Background session validation error:', error);
  }
}

// Handle push notifications for session warnings
self.addEventListener('push', (event) => {
  if (event.data) {
    const data = event.data.json();
    
    if (data.type === 'SESSION_WARNING') {
      const options = {
        body: data.message || 'Your session will expire soon',
        icon: '/favicon.ico',
        badge: '/favicon.ico',
        tag: 'session-warning',
        requireInteraction: true,
        actions: [
          {
            action: 'extend',
            title: 'Extend Session'
          },
          {
            action: 'logout',
            title: 'Logout Now'
          }
        ]
      };

      event.waitUntil(
        self.registration.showNotification('Payspin Admin - Session Warning', options)
      );
    }
  }
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  if (event.action === 'extend') {
    // Extend session
    notifyClients('EXTEND_SESSION');
  } else if (event.action === 'logout') {
    // Logout immediately
    notifyClients('FORCE_LOGOUT');
  } else {
    // Default action - focus on the app
    event.waitUntil(
      self.clients.matchAll().then((clients) => {
        if (clients.length > 0) {
          return clients[0].focus();
        } else {
          return self.clients.openWindow('/');
        }
      })
    );
  }
});

// Handle fetch events for offline support
self.addEventListener('fetch', (event) => {
  // Only handle navigation requests
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request)
        .catch(() => {
          // Return cached version if network fails
          return caches.match('/');
        })
    );
  }
});

// Initialize session monitoring on service worker startup
self.addEventListener('install', (event) => {
  event.waitUntil(
    retrieveSessionData().then((data) => {
      if (data) {
        sessionData = data;
        startSessionMonitoring();
      }
    })
  );
});

// Helper function to open IndexedDB
function openDB(name, version, upgradeCallback) {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(name, version);
    
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
    request.onupgradeneeded = () => upgradeCallback(request.result);
  });
}

console.log('Payspin Admin Service Worker loaded successfully'); 