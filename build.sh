#!/bin/bash

declare date="$( date +%Y%m%d )"
POSTGRES_VERSION="${POSTGRES_VERSION:-14}"

function build {
  docker build \
    --build-arg POSTGRES_VERSION=${POSTGRES_VERSION} \
    -t dblonski/postgresql-plugins:pg${POSTGRES_VERSION}-${date} \
    .
}

function publish {
  docker tag dblonski/postgresql-plugins:pg${POSTGRES_VERSION}-${date} dblonski/postgresql-plugins:pg${POSTGRES_VERSION}-latest
  #docker image push dblonski/postgresql-plugins:pg${POSTGRES_VERSION}-${date} dblonski/postgresql-plugins:pg${POSTGRES_VERSION}-latest
}

if [[ $# -eq 0 ]]; then
  build
else
  $1
fi
