#!/usr/bin/env bash
set -x
set -eo pipefail

export PGDATA="$PWD/postgres"
export PGHOST="$PGDATA"

DB_USER="${POSTGRES_USER:=postgres}"
DB_PASSWORD="${POSTGRES_PASSWORD:=password}"
DB_NAME="${POSTGRES_DB:=newsletter}"
DB_PORT="${POSTGRES_PORT:=5432}"
DB_HOST="${POSTGRES_HOST:=localhost}"

db_is_ready() {
    pg_isready -q -h "$DB_HOST" -p "$DB_PORT"
}

if ! db_is_ready && [[ ! -d "$PGDATA" ]]; then
    # If the data directory doesn't exist, create an empty one, and...
    initdb
    # ...configure it to listen on the Unix socket & address, and...
    cat >>"$PGDATA/postgresql.conf" <<-EOF
		listen_addresses = '$DB_HOST'
		unix_socket_directories = '$PGHOST'
        port = '$DB_PORT'
        max_connections = 1000
	EOF
    # ...create a database
    echo "CREATE USER $DB_USER WITH SUPERUSER PASSWORD '$DB_PASSWORD';" | postgres --single -E postgres
    echo "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER;" | postgres --single -E postgres
fi

if ! db_is_ready && [[ -d "$PGDATA" ]]; then
    pg_ctl -D "$PGDATA" start
fi

export DATABASE_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

>&2 echo "Postgres is up and running on port ${DB_PORT} - running migrations now!"

sqlx database create
sqlx migrate run

>&2 echo "Postgres has been migrated, ready to go!"
