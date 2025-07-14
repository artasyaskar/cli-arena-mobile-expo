#!/bin/bash
set -e

echo "🟢 Starting Supabase database..."
sudo docker run --name cli-arena-mobile-expo-db-1 \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=postgres \
  -p 54322:5432 \
  -v supabase_db_data:/var/lib/postgresql/data \
  -v ./db/schema.sql:/docker-entrypoint-initdb.d/10-schema.sql:ro \
  -v ./db/seed.sql:/docker-entrypoint-initdb.d/20-seed.sql:ro \
  -d supabase/postgres:15.8.1.060

sleep 10

sudo docker ps
echo "✅ Supabase database started."
