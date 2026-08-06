#!/bin/sh
set -e

: "${BILLING_DB_USER:?BILLING_DB_USER is required}"
: "${BILLING_DB_PASSWORD:?BILLING_DB_PASSWORD is required}"
: "${BILLING_DB_NAME:?BILLING_DB_NAME is required}"

if [ -z "$(ls -A /var/lib/postgresql/data)" ]; then
    su-exec postgres initdb -D /var/lib/postgresql/data
    
    echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf
    echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf
    
    su-exec postgres pg_ctl -D /var/lib/postgresql/data -w start
    su-exec postgres psql -c "CREATE USER \"${BILLING_DB_USER}\" WITH PASSWORD '${BILLING_DB_PASSWORD}';"
    su-exec postgres psql -c "CREATE DATABASE \"${BILLING_DB_NAME}\" OWNER \"${BILLING_DB_USER}\";"
    su-exec postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE \"${BILLING_DB_NAME}\" TO \"${BILLING_DB_USER}\";"
    su-exec postgres pg_ctl -D /var/lib/postgresql/data -m fast -w stop
fi

exec su-exec postgres postgres -D /var/lib/postgresql/data
