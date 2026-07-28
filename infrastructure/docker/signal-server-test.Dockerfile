# Development-only Linux runner for the pinned upstream Signal Server test mode.
# FoundationDB's native Java client is not packaged for Windows; the server must
# execute in a Linux container even when the working tree is on Windows.
FROM eclipse-temurin:25-jdk

RUN apt-get update \
    && apt-get install -y --no-install-recommends maven docker.io docker-compose-v2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
