#!/bin/bash

declare date="$( date +%Y%m%d )"

. settings.sh

export CLANG_VERSION="${CLANG_VERSION:-19}"
export DOCKER_REPO="${DOCKER_REPO:-dblonski}"
export GOLANG_VERSION="${GOLANG_VERSION:-1.24}"
export GOSU_VERSION="${GOSU_VERSION:-1.17}"
export POSTGRES_VERSION="${POSTGRES_VERSION:-18}"

function build {
  docker build \
    --no-cache \
    --build-arg CLANG_VERSION=${CLANG_VERSION} \
    --build-arg DOCKER_REPO=${DOCKER_REPO} \
    --build-arg GOLANG_VERSION=${GOLANG_VERSION} \
    --build-arg GOSU_VERSION=${GOSU_VERSION} \
    --build-arg POSTGRES_VERSION=${POSTGRES_VERSION} \
    -t ${DOCKER_REPO}/postgresql-plugins:pg${POSTGRES_VERSION}-${date} \
    .
}

function tag_only {
  local POSTGRES_FULL_VERSION="$( docker run -it ${DOCKER_REPO}/postgresql-plugins:pg${POSTGRES_VERSION}-${date} psql --version | awk '{ print $3; }' | tr '\n\r' '  ' )"
  local TAGS=(
    "pg${POSTGRES_VERSION}-latest"
    "pg${POSTGRES_FULL_VERSION}"
    )
  for tag in ${TAGS[@]}; do
    docker tag ${DOCKER_REPO}/postgresql-plugins:pg${POSTGRES_VERSION}-${date} ${DOCKER_REPO}/postgresql-plugins:${tag}
  done
}

function publish {
  local POSTGRES_FULL_VERSION="$( docker run -it ${DOCKER_REPO}/postgresql-plugins:pg${POSTGRES_VERSION}-${date} psql --version | awk '{ print $3; }' | tr '\n\r' '  ' )"
  local TAGS=(
    "pg${POSTGRES_VERSION}-latest"
    "pg${POSTGRES_FULL_VERSION}"
    )
  for tag in ${TAGS[@]}; do
    docker tag ${DOCKER_REPO}/postgresql-plugins:pg${POSTGRES_VERSION}-${date} ${DOCKER_REPO}/postgresql-plugins:${tag}
    docker image push ${DOCKER_REPO}/postgresql-plugins:${tag}
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
