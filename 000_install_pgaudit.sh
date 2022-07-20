#!/bin/bash

create_sql=`mktemp`

# Checks to support bitnami image with same scripts so they stay in sync
if [ ! -z "${BITNAMI_IMAGE_VERSION:-}" ]; then
        if [ -z "${POSTGRES_USER:-}" ]; then
                POSTGRES_USER=${POSTGRESQL_USERNAME}
        fi

        if [ -z "${POSTGRES_DB:-}" ]; then
                POSTGRES_DB=${POSTGRESQL_DATABASE}
        fi

        if [ -z "${PGDATA:-}" ]; then
                PGDATA=${POSTGRESQL_DATA_DIR}
        fi
fi

if [ -z "${POSTGRESQL_CONF_DIR:-}" ]; then
        POSTGRESQL_CONF_DIR=${PGDATA}
fi

cat <<EOF >${create_sql}
CREATE EXTENSION if not exists pgaudit;
EOF

cat << EOF >> ${POSTGRESQL_CONF_DIR}/postgresql.conf
pgaudit.log_catalog = 'on'
pgaudit.log_level = 'log'
pgaudit.log_parameter = 'on'
pgaudit.log_relation = on
pgaudit.log_statement_once = 'off'
pgaudit.log = 'write, dll, role, read, function'
wal_level = logical
max_replication_slots = 12
EOF

# create extension timescaledb in initial databases
psql -U "${POSTGRES_USER}" postgres -f ${create_sql}
psql -U "${POSTGRES_USER}" template1 -f ${create_sql}

if [ "${POSTGRES_DB:-postgres}" != 'postgres' ]; then
    psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" -f ${create_sql}
fi
