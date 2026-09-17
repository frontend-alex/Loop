FROM golang:1.27.1-alpine3.24 AS build

WORKDIR /app

COPY . .

RUN go get .

RUN go build -o main .

EXPOSE 8080

CMD ["./main"]