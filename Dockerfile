# https://github.com/thegrendle/docker
ARG POSTGRES_VERSION=16
ARG GOLANG_VERSION=1.24
ARG GOSU_VERSION=1.17
ARG CLANG_VERSION=19

FROM golang:${GOLANG_VERSION}-alpine AS gosubuild
ARG GOLANG_VERSION
RUN apk update && \
    apk upgrade && \
    apk add git && \
    git config --global http.sslVerify false && \
    git clone https://github.com/tianon/gosu.git /build/gosu && \
    cd /build/gosu && \
    git checkout ${GOSU_VERSION} && \
    go build .

FROM postgres:${POSTGRES_VERSION}-alpine AS pluginbuild
ARG POSTGRES_VERSION
RUN apk update && \
    apk upgrade && \
    apk add git make clang${CLANG_VERSION} gcc glib-dev llvm${CLANG_VERSION}-dev krb5-dev musl-dev protobuf-c-dev openssl-dev && \
    git config --global http.sslVerify false && \
    git clone https://github.com/debezium/postgres-decoderbufs.git /build/decoderbufs && \
    cd /build/decoderbufs && \
    export PATH=$PATH:/usr/pgsql-${POSTGRES_VERSION}/bin/ && \
    make && \
    make install && \
    git clone https://github.com/pgaudit/pgaudit.git /build/pgaudit && \
    cd /build/pgaudit && \
    git checkout REL_${POSTGRES_VERSION}_STABLE && \
    make install USE_PGXS=1 PG_CONFIG=/usr/local/bin/pg_config && \
    git clone https://github.com/cybertec-postgresql/pg_squeeze.git /build/pgsqueeze && \
    cd /build/pgsqueeze && \
    make && \
    make install && \
    git clone https://github.com/citusdata/pg_cron.git /build/pg_cron && \
    cd /build/pg_cron && \
    make && \
    make install

FROM postgres:${POSTGRES_VERSION}-alpine
ARG POSTGRES_VERSION

RUN apk update && \
    apk upgrade && \
    apk add glib libgcc libstdc++ musl musl-utils openssl protobuf protobuf-c llvm krb5 && \
    sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'pgaudit,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample && \
    sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'pg_squeeze,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample && \
    sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'decoderbufs,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample && \
    sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'pg_cron,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample

COPY --from=gosubuild /build/gosu/gosu /usr/local/bin/gosu

COPY --from=pluginbuild \
  /usr/local/lib/postgresql/decoderbufs.so \
  /usr/local/lib/postgresql/pgaudit.so \
  /usr/local/lib/postgresql/pg_squeeze.so \
  /usr/local/lib/postgresql/pg_cron.so \
  /usr/local/lib/postgresql/

COPY --from=pluginbuild \
  /usr/local/share/postgresql/extension/decoderbufs.control \
  /usr/local/share/postgresql/extension/pgaudit.control \
  /usr/local/share/postgresql/extension/pgaudit* \
  /usr/local/share/postgresql/extension/pg_squeeze* \
  /usr/local/share/postgresql/extension/pg_cron* \
  /usr/local/lib/postgresql/bitcode/pg_cron* \
  /usr/local/share/postgresql/extension/

COPY --from=pluginbuild \
  /usr/local/lib/postgresql/bitcode/pg_cron* \
  /usr/local/lib/postgresql/bitcode/

COPY 000_install_pg_squeeze.sh 000_install_pgaudit.sh /docker-entrypoint-initdb.d/
