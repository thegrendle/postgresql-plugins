#!/bin/bash

create_sql="$( mktemp )"

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

cat << EOF >> ${POSTGRESQL_CONF_DIR}/postgresql.conf
cron.database_name = '${POSTGRES_USER}'
EOF

/usr/local/bin/pg_ctl restart

cat << EOF > ${create_sql}
CREATE EXTENSION pg_cron;
EOF

psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" -f ${create_sql}
