# ==============================================================================
# AirSense Backend - Production Multi-Stage Dockerfile
# Base: Eclipse Temurin OpenJDK 21 on Alpine Linux
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build Stage
# ------------------------------------------------------------------------------
FROM maven:3.9.9-eclipse-temurin-21-alpine AS builder
WORKDIR /build

# Cache Maven dependencies by copying pom.xml first
COPY pom.xml .
RUN mvn -B -ntp \
    -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.http.retryHandler.count=5 \
    dependency:resolve dependency:resolve-plugins || true

# Copy application source code and build the executable JAR
COPY src ./src
RUN mvn -B -ntp \
    -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.http.retryHandler.count=5 \
    clean package -DskipTests

# ------------------------------------------------------------------------------
# Stage 2: Minimal Runtime Stage
# ------------------------------------------------------------------------------
FROM eclipse-temurin:21-jre-alpine AS runner
WORKDIR /app

# Create a dedicated non-root system user and group for security
RUN addgroup -S airsense && adduser -S airsense -G airsense

# Copy packaged Spring Boot JAR from builder stage
COPY --from=builder /build/target/*.jar app.jar
RUN chown -R airsense:airsense /app

# Switch to non-root user
USER airsense

# Expose ports (8080 standard, 10000 for Render)
EXPOSE 8080 10000

# Configure JVM memory and garbage collection optimizations for containerized environments
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError"

# Run application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
