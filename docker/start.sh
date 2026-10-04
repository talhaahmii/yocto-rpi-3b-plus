#!/bin/bash

export USER_UID=$(id -u)
export USER_GID=$(id -g)

docker compose -f docker/docker-compose.yml "$@"
