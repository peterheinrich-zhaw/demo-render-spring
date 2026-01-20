# =========================
# Build stage
# =========================
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Abhängigkeiten cachen
COPY pom.xml .
RUN mvn -B dependency:go-offline

# Source kopieren & bauen
COPY src ./src
RUN mvn -B package -DskipTests

# =========================
# Debug stage (mit Shell)
# =========================
FROM eclipse-temurin:21-jdk AS debug
WORKDIR /app

RUN useradd -m appuser
USER appuser

ENV SPRING_PROFILES_ACTIVE=docker

COPY --from=build /app/target/app.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]

# =========================
# Production stage (distroless)
# =========================
FROM gcr.io/distroless/java21-debian12 AS prod
WORKDIR /app

USER 1000

ENV SPRING_PROFILES_ACTIVE=prod

COPY --from=build /app/target/app.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
