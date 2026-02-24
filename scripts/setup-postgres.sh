#!/bin/bash
set -euo pipefail

# Start PostgreSQL temporarily for setup
pg_ctlcluster 16 main start

# Create the laravel user and database
sudo -u postgres createuser -s exedev 2>/dev/null || true
sudo -u postgres createdb -O exedev laravel 2>/dev/null || true

# Allow local connections without password (peer auth)
# This is fine — it's a single-user VM
pg_ctlcluster 16 main stop
