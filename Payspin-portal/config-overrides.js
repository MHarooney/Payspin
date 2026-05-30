const webpack = require('webpack');
const NodePolyfillPlugin = require('node-polyfill-webpack-plugin');

module.exports = function override(config) {
  // Add Node polyfill plugin
  config.plugins = (config.plugins || []).concat([
    new NodePolyfillPlugin({
      excludeAliases: ['console']
    }),
    new webpack.ProvidePlugin({
      process: 'process/browser',
      Buffer: ['buffer', 'Buffer'],
    }),
  ]);

  // Configure fallbacks for Node.js core modules
  config.resolve = {
    ...config.resolve,
    fallback: {
      buffer: require.resolve('buffer'),
      crypto: require.resolve('crypto-browserify'),
      stream: require.resolve('stream-browserify'),
      util: require.resolve('util'),
      url: require.resolve('url'),
      assert: require.resolve('assert'),
      http: require.resolve('stream-http'),
      https: require.resolve('https-browserify'),
      os: require.resolve('os-browserify/browser'),
      events: require.resolve('events'),
      path: require.resolve('path-browserify'),
      fs: false,
      net: false,
      tls: false,
      child_process: false,
      http2: false,
      dns: false,
      zlib: require.resolve('browserify-zlib'),
      stream: require.resolve('stream-browserify'),
      util: require.resolve('util/'),
      'node:events': require.resolve('events'),
      'node:stream': require.resolve('stream-browserify'),
      'node:util': require.resolve('util/'),
      'node:process': 'process/browser'
    }
  };

  // Add module rules for handling node: scheme imports
  config.module = {
    ...config.module,
    rules: [
      ...config.module.rules,
      {
        test: /node:/,
        loader: 'node-loader'
      }
    ]
  };

  // Ignore source map warnings
  config.ignoreWarnings = [/Failed to parse source map/];

  // Add resolve aliases for node: scheme modules
  config.resolve.alias = {
    ...config.resolve.alias,
    'node:events': 'events',
    'node:process': 'process/browser',
    'node:stream': 'stream-browserify',
    'node:util': 'util'
  };

  return config;
}; 