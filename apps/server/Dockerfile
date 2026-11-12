# Development image: keep Air for local hot reload.
FROM golang:1.27.3-alpine3.24 AS development 

## Changes that I have made, 

WORKDIR /app

#Preventing Compiler Changes
# Use GO compiler already installed in the image
ENV GOTOOLCHAIN=local

#/usr/local/bin is the place where we install the air dependacny 
# Install air before switching users because * /usr/local/bin * is a sys dir that user should not modify
RUN GOBIN=/usr/local/bin go install github.com/air-verse/air@v1.67.4

#Preparing an ordinary user withouth root privileges
RUN addgroup -S -g 10001 loop \
    && adduser -S -D -u 10001 -G loop -h /home/loop loop \
    && mkdir -p /go/pkg/mod /home/loop/.cache/go-build \
    #makes the app dir and Go dirs owned by the user
    && chown -R loop:loop /app /go/pkg /home/loop


# Moved from root to user, reduce premission on attacker has when exploting API
USER loop:loop

COPY --chown=loop:loop go.mod go.sum ./

RUN go mod download

# Copy . .

# We copy now only what development needs
COPY --chown=loop:loop .air.toml ./
COPY --chown=loop:loop cmd/ ./cmd/
COPY --chown=loop:loop internal/ ./internal/
COPY --chown=loop:loop api/ ./api/

EXPOSE 8080

CMD ["air", "-c", ".air.toml"]
