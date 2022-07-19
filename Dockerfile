# https://github.com/thegrendle/docker
ARG POSTGRES_VERSION=11

FROM postgres:${POSTGRES_VERSION}-alpine as pluginbuild
ARG POSTGRES_VERSION
RUN apk update && \
    apk upgrade && \
    apk add git make clang gcc glib-dev llvm-dev krb5-dev musl-dev protobuf-c-dev openssl-dev && \   
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
    make install

FROM postgres:${POSTGRES_VERSION}-alpine
ARG POSTGRES_VERSION

RUN apk update && \
    apk upgrade && \
    apk add glib libgcc libstdc++ musl musl-utils openssl protobuf protobuf-c llvm krb5 && \
    sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'pgaudit,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample && \
    sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'pg_squeeze,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample && \
    sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'decoderbufs,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample
COPY --from=pluginbuild \
  /usr/local/lib/postgresql/decoderbufs.so \
  /usr/local/lib/postgresql/pgaudit.so \
  /usr/local/lib/postgresql/pg_squeeze.so \
  /usr/local/lib/postgresql/
COPY --from=pluginbuild \
  /usr/local/share/postgresql/extension/decoderbufs.control \
  /usr/local/share/postgresql/extension/pgaudit.control \
  /usr/local/share/postgresql/extension/pgaudit* \
  /usr/local/share/postgresql/extension/pg_squeeze* \
  /usr/local/share/postgresql/extension/
COPY 000_install_pg_squeeze.sh /docker-entrypoint-initdb.d/
