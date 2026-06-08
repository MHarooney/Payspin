const path = require('path');

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'standalone',
  outputFileTracingRoot: path.join(__dirname, '..', '..'),
  eslint: {
    // Lint is run explicitly in CI (A5); don't fail production builds on it.
    ignoreDuringBuilds: true,
  },
};

module.exports = nextConfig;
