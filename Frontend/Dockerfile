# ==============================================================================
# AirSense Frontend - Flutter Web Production Multi-Stage Dockerfile
# ==============================================================================

# Stage 1: Build Flutter Web application
FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app

# Accept API URL build argument (defaults to /api for reverse proxy)
ARG API_BASE_URL=""

# Copy dependency specifications first to leverage layer caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy all project source files
COPY . .

# Build web release
RUN flutter build web --release

# Stage 2: Serve with lightweight Nginx web server
FROM nginx:alpine AS runner

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy compiled web assets from builder
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration with SPA routing and API reverse-proxy
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
