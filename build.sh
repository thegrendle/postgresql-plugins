#!/bin/bash

declare date="$( date +%Y%m%d )"
POSTGRES_VERSION="${POSTGRES_VERSION:-14}"

function build {
  docker image pull postgres:${POSTGRES_VERSION}-alpine
  docker build \
    --build-arg POSTGRES_VERSION=${POSTGRES_VERSION} \
    -t dblonski/postgresql-plugins:pg${POSTGRES_VERSION}-${date} \
    .
}

function publish {
  local POSTGRES_FULL_VERSION="$( docker run -it dblonski/postgresql-plugins:pg${POSTGRES_VERSION}-${date} psql --version | awk '{ print $3; }' | tr '\n\r' '  ' )"
  local TAGS=(
    "pg${POSTGRES_VERSION}-latest"
    "pg${POSTGRES_FULL_VERSION}"
    )
  for tag in ${TAGS[@]}; do
    docker tag dblonski/postgresql-plugins:pg${POSTGRES_VERSION}-${date} dblonski/postgresql-plugins:${tag}
    docker image push dblonski/postgresql-plugins:${tag}
  done
}

if [[ $# -eq 0 ]]; then
  build
else
  while [[ $# -ne 0 ]]; do
    $1
    shift
  done
fi
