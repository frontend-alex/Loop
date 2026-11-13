cd /opt/loop

export BACKEND_IMAGE='ghcr.io/YOUR-ACCOUNT/loop-backend:YOUR-COMMIT-SHA'

docker compose -f compose.deploy.yaml pull backend
docker compose -f compose.deploy.yaml up -d backend

curl -f http://127.0.0.1:8080/health