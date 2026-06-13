FROM golang:1.21-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o bin/server ./cmd/server/

FROM alpine:latest

WORKDIR /app

RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Shanghai

COPY --from=builder /app/bin/server /app/server
COPY config /app/config

RUN chmod +x /app/server

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["/app/server"]
