#! /bin/bash
source env.sh
if command -v docker-compose 1>/dev/null && command -v docker 1>/dev/null; then
  docker-compose up && docker-compose down
elif command -v podman 1>/dev/null; then
  # shellcheck disable=SC2046
  export $(grep '^DOCKER_IMG_PREFIX' .env)
  # shellcheck disable=SC2046
  export $(grep '^SMB_HOSTNAME' .env)
  IMAGE="$DOCKER_IMG_PREFIX/sambadocker"
  podman run \
    --rm \
    --name "sambad" \
    --hostname "$SMB_HOSTNAME" \
    --env-file=".env" \
    --publish "0.0.0.0:1389:389" \
    --publish "0.0.0.0:1636:636" \
    --volume "samba_data:/var/lib/samba" \
    "$IMAGE"
fi
