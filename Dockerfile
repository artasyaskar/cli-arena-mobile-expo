# Base image with Node.js
FROM node:18-slim

# Set working directory
WORKDIR /app

# Install basic dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gnupg \
    jq \
    # Add other essential CLI tools if needed
    && rm -rf /var/lib/apt/lists/*

# Install Supabase CLI
ARG SUPABASE_CLI_VERSION=v2.30.4
RUN curl -L -o supabase.deb "https://github.com/supabase/cli/releases/download/${SUPABASE_CLI_VERSION}/supabase_${SUPABASE_CLI_VERSION#v}_linux_amd64.deb" \
    && apt-get update \
    && apt-get install -y --no-install-recommends ./supabase.deb \
    && rm -f supabase.deb \
    && rm -rf /var/lib/apt/lists/*

# Install Expo CLI
RUN npm install --global expo-cli --no-optional --legacy-peer-deps

# TODO: Add Java/Kotlin SDK for Android development
# Example:
# RUN apt-get update && apt-get install -y openjdk-11-jdk
# ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
# RUN curl -s "https://get.sdkman.io" | bash
# SHELL ["/bin/bash", "-c"]
# RUN source "$HOME/.sdkman/bin/sdkman-init.sh" && sdk install kotlin

# TODO: Add Swift toolchain for iOS development
# This is more complex as Swift is not easily installed on generic Linux.
# Consider using a macOS runner for CI or a specialized Docker image for Swift.

# Copy application files (this will be done in docker-compose or later stages)
# COPY . .

# Default command (can be overridden)
CMD ["bash"]
