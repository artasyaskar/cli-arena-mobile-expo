# Base image with Node.js
FROM node:18-slim

WORKDIR /app

# Install required tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    jq \
 && rm -rf /var/lib/apt/lists/*

# Install TypeScript globally so tsc command works
RUN npm install -g typescript

# Install Supabase CLI
ENV SUPABASE_CLI_VERSION=2.30.4
RUN curl -L https://github.com/supabase/cli/releases/download/v${SUPABASE_CLI_VERSION}/supabase_${SUPABASE_CLI_VERSION}_linux_amd64.deb \
    -o supabase.deb \
 && apt-get update \
 && apt-get install -y ./supabase.deb \
 && rm supabase.deb

# Copy all project files
COPY . .

# Default shell
CMD ["bash"]
