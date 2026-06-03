FROM golang:1.25 AS builder
WORKDIR /src
ARG TARGET_DIR

COPY go.mod go.sum ./
RUN go mod download
COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o /src/server ./${TARGET_DIR}

FROM scratch
WORKDIR /app
COPY --from=builder /src/server /app/server

EXPOSE 8080/tcp
EXPOSE 7654/udp
ENTRYPOINT ["/app/server"]