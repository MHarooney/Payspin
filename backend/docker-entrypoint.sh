#!/bin/sh
set -e
cd /app/backend
echo "Running database migrations..."
prisma migrate deploy --schema=./prisma/schema.prisma
echo "Starting API..."
exec "$@"
