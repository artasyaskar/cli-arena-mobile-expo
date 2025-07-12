# ---------- Base image ----------
FROM node:18-slim

# ---------- Set working directory ----------
WORKDIR /app

# ---------- Install essential tools ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    jq \
 && rm -rf /var/lib/apt/lists/*

# ---------- Install TypeScript globally ----------
RUN npm install -g typescript

# ---------- Install Supabase CLI ----------
ENV SUPABASE_CLI_VERSION=2.30.4
RUN curl -L "https://github.com/supabase/cli/releases/download/v${SUPABASE_CLI_VERSION}/supabase_${SUPABASE_CLI_VERSION}_linux_amd64.deb" \
    -o supabase.deb \
 && apt-get update \
 && apt-get install -y ./supabase.deb \
 && rm supabase.deb \
 && rm -rf /var/lib/apt/lists/*

# ---------- Copy only required files first (for better caching) ----------
COPY package*.json ./

# ---------- Install dependencies ----------
RUN npm install

# ---------- Copy remaining source files ----------
COPY . .

# ---------- Default command ----------
CMD [ "bash" ]
