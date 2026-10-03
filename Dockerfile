# ==============================================================================
# AirSense Root Multi-Stage Dockerfile (Backend Service)
# Designed for root repository deployment (e.g., Render, Railway, Cloud Run, AWS)
# ==============================================================================

# Stage 1: Build the Spring Boot application
FROM maven:3.9.9-eclipse-temurin-21-alpine AS builder
WORKDIR /build

# Cache Maven dependencies
COPY airsense-backend/pom.xml .
RUN mvn dependency:go-offline -B

# Copy backend source code and build production JAR
COPY airsense-backend/src ./src
RUN mvn clean package -DskipTests

# Stage 2: Create minimal, hardened production runtime
FROM eclipse-temurin:21-jre-alpine AS runner
WORKDIR /app

# Run as non-root user
RUN addgroup -S airsense && adduser -S airsense -G airsense

# Copy packaged jar from builder stage
COPY --from=builder /build/target/*.jar app.jar
RUN chown -R airsense:airsense /app

USER airsense

EXPOSE 8080

ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
