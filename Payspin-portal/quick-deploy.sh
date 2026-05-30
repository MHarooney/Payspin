#!/bin/bash

# Quick deploy script for admin-portal
set -e

# Go to the admin-portal directory
cd "$(dirname "$0")/admin-portal"

echo "Installing dependencies..."
npm install --legacy-peer-deps

echo "Building the project..."
npm run build

# Go back to the root directory
cd ..

echo "Deploying to Firebase Hosting..."
firebase deploy --only hosting

echo "Deployment complete!" 