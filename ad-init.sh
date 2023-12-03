#! /bin/bash
source env.sh
if command -v docker 1>/dev/null; then
  CMD=docker
elif command -v podman 1>/dev/null; then
  CMD=podman
fi
$CMD exec -it $DOCKER_CONTAINER_NAME /opt/sambadocker/ad-init.sh
