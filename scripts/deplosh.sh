cd /opt/loop

export BACKEND_IMAGE='ghcr.io/frontend-alex/loop-backend:IMAGE'

docker compose -f compose.deploy.yaml pull backend
docker compose -f compose.deploy.yaml up -d backend

curl -f http://127.0.0.1:8080/health