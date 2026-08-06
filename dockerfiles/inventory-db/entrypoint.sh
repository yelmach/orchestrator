#!/bin/sh
set -e

: "${INVENTORY_DB_USER:?INVENTORY_DB_USER is required}"
: "${INVENTORY_DB_PASSWORD:?INVENTORY_DB_PASSWORD is required}"
: "${INVENTORY_DB_NAME:?INVENTORY_DB_NAME is required}"

# Initialize DB only if the data directory is empty
if [ -z "$(ls -A /var/lib/postgresql/data)" ]; then
    su-exec postgres initdb -D /var/lib/postgresql/data
    
    # Configure Postgres to listen on all Docker network interfaces
    echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf
    echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf
    
    su-exec postgres pg_ctl -D /var/lib/postgresql/data -w start
    su-exec postgres psql -c "CREATE USER \"${INVENTORY_DB_USER}\" WITH PASSWORD '${INVENTORY_DB_PASSWORD}';"
    su-exec postgres psql -c "CREATE DATABASE \"${INVENTORY_DB_NAME}\" OWNER \"${INVENTORY_DB_USER}\";"
    su-exec postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE \"${INVENTORY_DB_NAME}\" TO \"${INVENTORY_DB_USER}\";"
    su-exec postgres pg_ctl -D /var/lib/postgresql/data -m fast -w stop
fi

exec su-exec postgres postgres -D /var/lib/postgresql/data