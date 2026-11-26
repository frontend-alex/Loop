#!/bin/sh
set -eu

# 1. Check the settings supplied by GitHub Actions.
: "${DEPLOY_HOST:?Set DEPLOY_HOST}"
: "${DEPLOY_USER:?Set DEPLOY_USER}"
: "${DEPLOY_KEY:?Set DEPLOY_KEY}"
: "${DEPLOY_KNOWN_HOSTS:?Set DEPLOY_KNOWN_HOSTS}"
: "${BACKEND_IMAGE:?Set BACKEND_IMAGE to the published immutable image digest}"

# Only accept an exact GHCR image, not a moving tag such as "latest".
case "$BACKEND_IMAGE" in *[!a-z0-9._/@:-]*) echo "Invalid image reference" >&2; exit 1;; esac
printf '%s\n' "$BACKEND_IMAGE" | grep -Eq '^ghcr\.io/[a-z0-9._/-]+@sha256:[a-f0-9]{64}$' \
    || { echo "Expected an immutable ghcr.io image digest" >&2; exit 1; }

# 2. Prepare temporary SSH credentials; remove them when this script exits.
ssh_dir=$(mktemp -d)
trap 'rm -rf "$ssh_dir"' EXIT
trap 'exit 1' HUP INT TERM
umask 077
printf '%s\n' "$DEPLOY_KEY" > "$ssh_dir/key"
printf '%s\n' "$DEPLOY_KNOWN_HOSTS" > "$ssh_dir/known_hosts"

# 3. Connect to the server. Everything below REMOTE runs there, not in Actions.
ssh -T -i "$ssh_dir/key" \
    -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
    -o "UserKnownHostsFile=$ssh_dir/known_hosts" \
    -- "$DEPLOY_USER@$DEPLOY_HOST" sh -s -- "$BACKEND_IMAGE" <<'REMOTE'
set -eu
cd /opt/loop
export BACKEND_IMAGE="$1"

# 4. Download the image and restart the backend using it.
docker compose -f compose.deploy.yaml pull backend
docker compose -f compose.deploy.yaml up -d --no-build backend

# 5. Check that the backend and database are ready; fail if they stay unhealthy.
curl --fail --silent --show-error --retry 10 --retry-connrefused \
    --retry-all-errors --retry-delay 2 http://127.0.0.1:8080/health/ready
REMOTE
