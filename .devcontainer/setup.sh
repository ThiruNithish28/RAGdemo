#!/bin/bash
set -e

echo "========================================="
echo "  Setting up Spring Boot RAG Environment"
echo "========================================="

# ─── 1. Install PostgreSQL ───────────────────────────────────────────────────
echo ""
echo "📦 Installing PostgreSQL..."
sudo apt-get update -qq
sudo apt-get install -y postgresql postgresql-contrib build-essential git

# Start PostgreSQL
sudo service postgresql start
sleep 2

# ─── 2. Install PgVector ─────────────────────────────────────────────────────
echo ""
echo "📦 Installing PgVector extension..."

# Install pgvector from source (works on any Postgres version)
cd /tmp
git clone --branch v0.7.0 https://github.com/pgvector/pgvector.git
cd pgvector
make
sudo make install
cd ~

echo "✅ PgVector installed successfully"

# ─── 3. Setup Database ───────────────────────────────────────────────────────
echo ""
echo "🗄️  Setting up database..."

sudo -u postgres psql <<EOF
-- Create developer user
CREATE USER devuser WITH PASSWORD 'devpassword' CREATEDB;

-- Create main application database
CREATE DATABASE appdb OWNER devuser;

-- Create RAG specific database
CREATE DATABASE ragdb OWNER devuser;

-- Enable PgVector in both databases
\c appdb
CREATE EXTENSION IF NOT EXISTS vector;

\c ragdb  
CREATE EXTENSION IF NOT EXISTS vector;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE appdb TO devuser;
GRANT ALL PRIVILEGES ON DATABASE ragdb TO devuser;

\echo '✅ Databases created with PgVector enabled'
EOF

echo "✅ Database setup complete"

# ─── 4. Create pg_hba.conf entry for easy local access ───────────────────────
echo ""
echo "🔧 Configuring PostgreSQL access..."
PG_VERSION=$(ls /etc/postgresql/)
sudo bash -c "echo 'host all all 127.0.0.1/32 md5' >> /etc/postgresql/$PG_VERSION/main/pg_hba.conf"
sudo service postgresql restart
sleep 2

# ─── 5. Install Maven if not present ─────────────────────────────────────────
if ! command -v mvn &> /dev/null; then
  echo ""
  echo "📦 Installing Maven..."
  sudo apt-get install -y maven
fi
echo "✅ Maven: $(mvn -version 2>&1 | head -1)"

# ─── 6. Display Connection Info ──────────────────────────────────────────────
echo ""
echo "========================================="
echo "  ✅ Setup Complete!"
echo "========================================="
echo ""
echo "📌 Database Connection Details:"
echo "   Host:     localhost"
echo "   Port:     5432"
echo "   User:     devuser"
echo "   Password: devpassword"
echo ""
echo "📌 Databases:"
echo "   appdb  → General Spring Boot app  (PgVector ✅)"
echo "   ragdb  → RAG project              (PgVector ✅)"
echo ""
echo "📌 Spring Boot application.properties:"
echo "   spring.datasource.url=jdbc:postgresql://localhost:5432/ragdb"
echo "   spring.datasource.username=devuser"
echo "   spring.datasource.password=devpassword"
echo ""
echo "📌 Ports forwarded:"
echo "   :8080 → Spring Boot"
echo "   :5432 → PostgreSQL"
echo "   :3000 → Frontend"
echo "   :5173 → Vite Frontend"
echo ""
