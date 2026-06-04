# @note バイナリ作成
FROM golang:alpine3.23 AS builder

RUN apk add --no-cache git

WORKDIR /usr/local/src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o /app/server ./cmd/app/api

# @note イメージ作成
FROM alpine:latest

WORKDIR /app
ARG TARGET_DIR

COPY --from=builder /app/server .
COPY ${TARGET_DIR}/entrypoint.sh .

RUN chmod +x entrypoint.sh && \
    adduser -S appuser -u 1000
USER 1000

ENTRYPOINT ["./entrypoint.sh"]