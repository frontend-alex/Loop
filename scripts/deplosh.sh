cd /opt/loop

export BACKEND_IMAGE='ghcr.io/frontend-alex/loop-backend:4f35c1401c054cb3027d0783ad5215cb34262190'

docker compose -f compose.deploy.yaml pull backend
docker compose -f compose.deploy.yaml up -d backend

curl -f http://127.0.0.1:8080/health