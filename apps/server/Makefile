IMAGE_NAME ?= go-server
CONTAINER_NAME ?= go-server
PORT ?= 8080

.PHONY: image container start run

image:
	docker build -t "$(IMAGE_NAME)" .

container: image
	docker create \
		-p "$(PORT):$(PORT)" \
		-v "$(CURDIR):/app" \
		--name "$(CONTAINER_NAME)" \
		"$(IMAGE_NAME)"

start:
	docker start "$(CONTAINER_NAME)"

run: image
	docker run --rm \
		-p "$(PORT):$(PORT)" \
		-v "$(CURDIR):/app" \
		--name "$(CONTAINER_NAME)" \
		"$(IMAGE_NAME)"

delete-image: 
	docker image rm $(IMAGE_NAME)

delete-container:
	docker rm -f "$(CONTAINER_NAME)"

