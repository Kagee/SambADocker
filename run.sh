#! /bin/bash
source env.sh
if command -v docker-compose 1>/dev/null && command -v docker 1>/dev/null; then
  docker-compose up && docker-compose down
elif command -v podman 1>/dev/null; then
  IMAGE="$DOCKER_IMG_PREFIX/$DOCKER_IMG_NAME"
  podman run \
    --rm \
    --name "$DOCKER_CONTAINER_NAME" \
    --hostname "$SMB_HOSTNAME" \
    --env-file=".env" \
    --publish "$HOST_BIND_IP:$HOST_PORT_LDAP:389" \
    --publish "$HOST_BIND_IP:$HOST_PORT_LDAPS:636" \
    --volume "samba_data:/var/lib/samba" \
    "$IMAGE"
fi
