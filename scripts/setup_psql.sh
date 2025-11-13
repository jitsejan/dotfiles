#!/usr/bin/env bash
set -e

echo "🐘 Setting up PostgreSQL client (psql)..."

# Check if PostgreSQL is installed
if ! command -v psql &>/dev/null; then
  echo "❌ PostgreSQL not found. Please install it first with 'brew install postgresql'"
  exit 1
fi

# Get version
PSQL_VERSION=$(psql --version | awk '{print $3}')

echo "✅ PostgreSQL client found: $PSQL_VERSION"

# Create .psqlrc configuration file for user-friendly settings
PSQLRC="$HOME/.psqlrc"
if [[ ! -f "$PSQLRC" ]]; then
  echo "📝 Creating .psqlrc configuration file..."
  cat >"$PSQLRC" <<'EOF'
-- PostgreSQL client configuration

-- Show query execution time
\timing

-- Use table format for results
\x auto

-- Set null display
\pset null '∅'

-- Verbose error reports
\set VERBOSITY verbose

-- Autocomplete keywords in uppercase
\set COMP_KEYWORD_CASE upper

-- Better prompt showing database and transaction status
\set PROMPT1 '%[%033[1m%]%M %n@%/%R%[%033[0m%]%# '
\set PROMPT2 '[more] %R > '

-- Save history per database
\set HISTFILE ~/.psql_history- :DBNAME

-- Increase history size
\set HISTSIZE 10000
EOF
  echo "✅ Created ~/.psqlrc with user-friendly defaults"
else
  echo "ℹ️  ~/.psqlrc already exists, skipping creation"
fi

echo ""
echo "📝 PostgreSQL client features:"
echo "   • Full-featured SQL command line interface"
echo "   • Connect to local and remote PostgreSQL databases"
echo "   • Execute SQL queries and view results"
echo "   • Import/export data in various formats"
echo "   • Built-in query timing and formatting"
echo "   • Meta-commands for database inspection"

echo ""
echo "💡 Common usage patterns:"
echo "   • Connect: psql -h hostname -U username -d database"
echo "   • Local connection: psql database_name"
echo "   • List databases: \\l"
echo "   • Connect to database: \\c database_name"
echo "   • List tables: \\dt"
echo "   • Describe table: \\d table_name"
echo "   • Execute SQL file: \\i /path/to/file.sql"
echo "   • Export query: \\copy (SELECT ...) TO 'file.csv' CSV HEADER"
echo "   • Quit: \\q"

echo ""
echo "🔧 Configuration applied:"
echo "   • Query timing enabled"
echo "   • Auto-expanding table format"
echo "   • NULL values displayed as ∅"
echo "   • Enhanced prompt with database info"
echo "   • Per-database command history"
echo "   • Uppercase keyword completion"

echo ""
echo "🔐 Connection examples:"
echo "   • Local: psql postgres"
echo "   • Remote: psql -h db.example.com -U myuser -d mydb"
echo "   • URI: psql postgresql://user:pass@host:5432/dbname"
echo "   • Environment vars: PGHOST, PGPORT, PGUSER, PGDATABASE"

echo ""
echo "✅ PostgreSQL client setup complete!"
echo "💡 Try: psql --help for more options"
