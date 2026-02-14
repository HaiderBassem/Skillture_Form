# ============================================
# Stage 1: Build Frontend
# ============================================
FROM node:20-alpine AS frontend-builder

WORKDIR /app/web

# Install dependencies first (layer caching)
COPY web/package.json web/package-lock.json ./
RUN npm ci --no-audit --no-fund

# Build the React app
COPY web/ ./
RUN npm run build


# ============================================
# Stage 2: Build Go Backend
# ============================================
FROM golang:1.25-alpine AS backend-builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

# Install Go dependencies first (layer caching)
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# Copy source code
COPY cmd/ ./cmd/
COPY internal/ ./internal/

# Build the binary with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /app/skillture-form \
    ./cmd/api


# ============================================
# Stage 3: Production Runtime
# ============================================
FROM alpine:3.21 AS production

# Security: add ca-certs and timezone data
RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup

WORKDIR /app

# Copy the binary from backend builder
COPY --from=backend-builder /app/skillture-form .

# Copy the frontend build from frontend builder
COPY --from=frontend-builder /app/web/dist ./web/dist

# Copy the database schema (for reference/init)
COPY internal/database/database.sql ./internal/database/database.sql

# Security: run as non-root user
USER appuser

# Expose the app port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:8080/api/v1/forms/ || exit 1

# Run the application
ENTRYPOINT ["./skillture-form"]
