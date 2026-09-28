NETWORK_NAME ?= loop-network

IMAGE_NAME ?= go-server
CONTAINER_NAME ?= go-server
PORT ?= 8080

POSTGRES_PORT ?= 5432
POSTGRES_PASSWORD ?= root
POSTGRES_CONTAINER ?= go-postgres

# if this func exists we ensure that it will run the make function we have created
.PHONY: image container start run delete-image delete-container db-image db-run

network:
	docker network inspect "$(NETWORK_NAME)" >/dev/null 2>&1 || \
		docker network create "$(NETWORK_NAME)"


#-------------------------Backend-----------------------#
image:
	docker build -t "$(IMAGE_NAME)" .


# -v  mounts a directory from your computer into the container.
container: image
	docker create \
		--env-file "$(CURDIR)/.env" \
		-p "$(PORT):$(PORT)" \
		-v "$(CURDIR):/app" \
		--name "$(CONTAINER_NAME)" \
		"$(IMAGE_NAME)"

start:
	docker start "$(CONTAINER_NAME)"

run: image network
	docker run --rm \
		--network "$(NETWORK_NAME)" \
		--env-file "$(CURDIR)/.env" \
		-p "$(PORT):$(PORT)" \
		-v "$(CURDIR):/app" \
		--name "$(CONTAINER_NAME)" \
		"$(IMAGE_NAME)"

delete-image: 
	docker image rm $(IMAGE_NAME)

delete-container:
	docker rm -f "$(CONTAINER_NAME)"

#-------------------------Backend-----------------------#


#-------------------------Db----------------------------#
db-image:
	docker pull postgres

db-run: network
	docker run --rm \
		--name "$(POSTGRES_CONTAINER)" \
		--network "$(NETWORK_NAME)" \
		-p "$(POSTGRES_PORT):$(POSTGRES_PORT)" \
		-e POSTGRES_PASSWORD="$(POSTGRES_PASSWORD)" \
		-d postgres 

# -d detatch instance
# -e env varable

#-------------------------Db---------------------------#
