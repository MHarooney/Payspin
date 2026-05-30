const webpack = require('webpack');

module.exports = {
  webpack: {
    configure: {
      resolve: {
        fallback: {
          stream: require.resolve('stream-browserify'),
          crypto: require.resolve('crypto-browserify'),
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
          vm: false,
          'node:events': require.resolve('events'),
          'node:stream': require.resolve('stream-browserify'),
          'node:util': require.resolve('util'),
          'node:process': require.resolve('process/browser')
        }
      }
    },
    plugins: [
      new webpack.ProvidePlugin({
        process: 'process/browser',
        Buffer: ['buffer', 'Buffer'],
      }),
    ]
  }
}; 