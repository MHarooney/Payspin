const path = require('path');

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Self-contained server bundle for the production Docker image.
  output: 'standalone',
  // Trace workspace packages (e.g. @payspin/shared-types) from the monorepo root.
  outputFileTracingRoot: path.join(__dirname, '..'),
};

module.exports = nextConfig;
