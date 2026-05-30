// Polyfills for Node.js compatibility in browser environment
// This file should be imported at the top of your index.tsx

// Buffer polyfill
import { Buffer } from 'buffer';

// Process polyfill
import process from 'process';

// Global polyfills for Firebase compatibility
if (typeof (window as any).global === 'undefined') {
  (window as any).global = window;
}

// Set up Buffer and process globally
(window as any).Buffer = Buffer;
(window as any).process = process;

// Node.js core module polyfills - these will be resolved by webpack fallbacks
// Don't override read-only properties like crypto
if (!(window as any).stream) (window as any).stream = {};
if (!(window as any).util) (window as any).util = {};
if (!(window as any).url) (window as any).url = {};
if (!(window as any).assert) (window as any).assert = {};
if (!(window as any).http) (window as any).http = {};
if (!(window as any).https) (window as any).https = {};
if (!(window as any).os) (window as any).os = {};
if (!(window as any).events) (window as any).events = {};
if (!(window as any).path) (window as any).path = {};
if (!(window as any).zlib) (window as any).zlib = {};

// Node.js scheme imports
(window as any)['node:events'] = (window as any).events;
(window as any)['node:process'] = process;
(window as any)['node:stream'] = (window as any).stream;
(window as any)['node:util'] = (window as any).util; 