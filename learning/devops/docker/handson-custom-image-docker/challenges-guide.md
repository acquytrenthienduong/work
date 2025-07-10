# 🎯 Docker Challenges - Hướng dẫn chi tiết

## 📋 Tổng quan
Sau khi đã tạo được Dockerfile cơ bản, bây giờ chúng ta sẽ nâng cao kỹ năng Docker qua 4 challenges thực tế.

---

## 🏗️ Challenge 1: Optimize Image Size

### 🎯 Mục tiêu
- Giảm image size xuống dưới **100MB**
- Sử dụng Alpine base image
- Remove unnecessary packages
- Áp dụng multi-stage builds

### 📊 Baseline - Kiểm tra size hiện tại
```bash
# Build image hiện tại
docker build -t my-node-app:baseline .

# Check size
docker images my-node-app:baseline
# Kết quả có thể: ~200-300MB
```

### 🔧 Bước 1: Chuyển sang Alpine
Tạo `Dockerfile.alpine`:
```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set ownership
RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 3000

CMD ["npm", "start"]
```

**Test:**
```bash
# Build và compare
docker build -f Dockerfile.alpine -t my-node-app:alpine .
docker images | grep my-node-app
```

### 🔧 Bước 2: Multi-stage Build
Tạo `Dockerfile.multi-stage`:
```dockerfile
# Stage 1: Dependencies
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Stage 2: Build (if needed)
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# RUN npm run build  # Uncomment nếu cần build step

# Stage 3: Runtime
FROM node:18-alpine AS runner
WORKDIR /app

# Create user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy only necessary files
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/app.js ./app.js
COPY --from=builder /app/public ./public

# Set ownership
RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 3000

CMD ["node", "app.js"]
```

**Test:**
```bash
docker build -f Dockerfile.multi-stage -t my-node-app:multi-stage .
docker images | grep my-node-app
```

### 🔧 Bước 3: Extreme Optimization
Tạo `Dockerfile.optimized`:
```dockerfile
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force && \
    rm -rf /tmp/* /var/cache/apk/*

FROM node:18-alpine AS runner
WORKDIR /app

# Install only curl for health check
RUN apk add --no-cache curl && \
    addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy minimal files
COPY --from=deps /app/node_modules ./node_modules
COPY app.js package.json ./
COPY public ./public

# Set ownership và cleanup
RUN chown -R nodejs:nodejs /app && \
    rm -rf /var/cache/apk/* /tmp/*

USER nodejs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

CMD ["node", "app.js"]
```

### 📏 Size Comparison
```bash
# So sánh tất cả versions
docker images | grep my-node-app

# Expected results:
# my-node-app:baseline     ~200-300MB
# my-node-app:alpine       ~150-200MB  
# my-node-app:multi-stage  ~100-150MB
# my-node-app:optimized    ~80-100MB
```

### 🧪 Testing
```bash
# Test functionality
docker run -d -p 3000:3000 --name test-optimized my-node-app:optimized

# Verify app works
curl http://localhost:3000/api/health
curl http://localhost:3000/api/stats

# Cleanup
docker stop test-optimized && docker rm test-optimized
```

### 🏆 Success Criteria
- [ ] Image size < 100MB
- [ ] Application functionality preserved
- [ ] Health check working
- [ ] Non-root user implemented

---

## 🔒 Challenge 2: Security

### 🎯 Mục tiêu
- Run container với non-root user
- Scan image cho vulnerabilities
- Implement proper secrets management
- Apply security best practices

### 🔧 Bước 1: Security-focused Dockerfile
Tạo `Dockerfile.secure`:
```dockerfile
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM node:18-alpine AS runner
WORKDIR /app

# Install security updates
RUN apk upgrade --no-cache && \
    apk add --no-cache curl dumb-init

# Create non-root user với specific UID/GID
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Copy files with proper ownership
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs app.js package.json ./
COPY --chown=nodejs:nodejs public ./public

# Create data directory với proper permissions
RUN mkdir -p /app/data && \
    chown -R nodejs:nodejs /app/data && \
    chmod 755 /app/data

# Remove unnecessary packages
RUN rm -rf /var/cache/apk/* /tmp/*

# Switch to non-root user
USER nodejs

EXPOSE 3000

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "app.js"]
```

### 🔧 Bước 2: Environment Variables Security
Tạo `docker-compose.secure.yml`:
```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.secure
    environment:
      - NODE_ENV=production
      - PORT=3000
      # Không hardcode secrets ở đây
    env_file:
      - .env.production
    ports:
      - "3000:3000"
    restart: unless-stopped
    read_only: true
    tmpfs:
      - /tmp
      - /app/data
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID
    user: "1001:1001"
```

### 🔧 Bước 3: Secrets Management
Tạo `.env.production`:
```bash
NODE_ENV=production
PORT=3000
# Add other non-sensitive configs
```

Tạo `secrets.yml` (for Docker Swarm):
```yaml
version: '3.8'
services:
  app:
    build: .
    secrets:
      - db_password
      - api_key
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password
      - API_KEY_FILE=/run/secrets/api_key

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    file: ./secrets/api_key.txt
```

### 🔧 Bước 4: Update App để handle secrets
Update `app.js` để đọc secrets từ files:
```javascript
const fs = require('fs');
const path = require('path');

// Helper function để đọc secrets
function readSecret(secretName) {
  try {
    const secretPath = process.env[`${secretName.toUpperCase()}_FILE`];
    if (secretPath && fs.existsSync(secretPath)) {
      return fs.readFileSync(secretPath, 'utf8').trim();
    }
  } catch (error) {
    console.error(`Error reading secret ${secretName}:`, error);
  }
  return process.env[secretName];
}

// Usage
const dbPassword = readSecret('DB_PASSWORD');
const apiKey = readSecret('API_KEY');
```

### 🔍 Bước 5: Security Scanning
```bash
# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scan image for vulnerabilities
trivy image my-node-app:secure

# Scan với high/critical only
trivy image --severity HIGH,CRITICAL my-node-app:secure

# Save scan results
trivy image --format json --output scan-results.json my-node-app:secure
```

### 🧪 Testing Security
```bash
# Test container security
docker run -d -p 3000:3000 --name secure-test my-node-app:secure

# Check running user
docker exec secure-test whoami  # Should be 'nodejs'

# Check file permissions
docker exec secure-test ls -la /app

# Try to escalate privileges (should fail)
docker exec secure-test sudo whoami  # Should fail

# Check processes
docker exec secure-test ps aux

# Cleanup
docker stop secure-test && docker rm secure-test
```

### 🏆 Success Criteria
- [ ] Non-root user implemented
- [ ] Security scanning passed
- [ ] Secrets management implemented
- [ ] Container hardening applied
- [ ] No privilege escalation possible

---

## 🚀 Challenge 3: Production Ready

### 🎯 Mục tiêu
- Add proper logging
- Implement graceful shutdown
- Add monitoring endpoints
- Health checks & metrics

### 🔧 Bước 1: Enhanced Logging
Update `app.js` với better logging:
```javascript
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Structured logging
const log = {
  info: (message, meta = {}) => {
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'info',
      message,
      ...meta
    }));
  },
  error: (message, error = null, meta = {}) => {
    console.error(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'error',
      message,
      error: error ? error.message : null,
      stack: error ? error.stack : null,
      ...meta
    }));
  },
  warn: (message, meta = {}) => {
    console.warn(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'warn',
      message,
      ...meta
    }));
  }
};

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    log.info('HTTP Request', {
      method: req.method,
      url: req.url,
      status: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.headers['user-agent'],
      ip: req.ip
    });
  });
  
  next();
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Application state
let visitors = [];
let pageViews = 0;
let isShuttingDown = false;

// Graceful shutdown handler
process.on('SIGTERM', () => {
  log.info('SIGTERM received, starting graceful shutdown');
  isShuttingDown = true;
  
  server.close(() => {
    log.info('Server closed');
    process.exit(0);
  });
  
  // Force exit after 30 seconds
  setTimeout(() => {
    log.error('Forceful shutdown after timeout');
    process.exit(1);
  }, 30000);
});

process.on('SIGINT', () => {
  log.info('SIGINT received, starting graceful shutdown');
  isShuttingDown = true;
  
  server.close(() => {
    log.info('Server closed');
    process.exit(0);
  });
});

// Health check middleware
app.use((req, res, next) => {
  if (isShuttingDown) {
    return res.status(503).json({ error: 'Service unavailable - shutting down' });
  }
  next();
});

// Routes
app.get('/', (req, res) => {
  pageViews++;
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0',
    pid: process.pid
  });
});

app.get('/api/health/ready', (req, res) => {
  // Readiness check
  if (isShuttingDown) {
    return res.status(503).json({ status: 'Not Ready', reason: 'Shutting down' });
  }
  
  res.json({ status: 'Ready', timestamp: new Date().toISOString() });
});

app.get('/api/health/live', (req, res) => {
  // Liveness check
  res.json({ status: 'Live', timestamp: new Date().toISOString() });
});

// Metrics endpoint
app.get('/api/metrics', (req, res) => {
  const memUsage = process.memoryUsage();
  
  res.json({
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    pageViews,
    totalVisitors: visitors.length,
    memory: {
      rss: `${Math.round(memUsage.rss / 1024 / 1024)}MB`,
      heapTotal: `${Math.round(memUsage.heapTotal / 1024 / 1024)}MB`,
      heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)}MB`,
      external: `${Math.round(memUsage.external / 1024 / 1024)}MB`
    },
    platform: process.platform,
    nodeVersion: process.version,
    pid: process.pid
  });
});

// Existing routes...
app.get('/api/stats', (req, res) => {
  res.json({
    pageViews,
    totalVisitors: visitors.length,
    memoryUsage: process.memoryUsage(),
    platform: process.platform,
    nodeVersion: process.version
  });
});

app.post('/api/visitors', (req, res) => {
  try {
    const visitor = {
      id: visitors.length + 1,
      name: req.body.name || 'Anonymous',
      timestamp: new Date().toISOString(),
      userAgent: req.headers['user-agent'] || 'Unknown'
    };
    
    visitors.push(visitor);
    log.info('New visitor added', { visitorId: visitor.id, name: visitor.name });
    res.status(201).json(visitor);
  } catch (error) {
    log.error('Error adding visitor', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/visitors', (req, res) => {
  res.json(visitors);
});

// Error handling middleware
app.use((err, req, res, next) => {
  log.error('Unhandled error', err, {
    url: req.url,
    method: req.method,
    ip: req.ip
  });
  
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  log.warn('404 Not Found', { url: req.url, method: req.method });
  res.status(404).json({ error: 'Route not found' });
});

const server = app.listen(PORT, '0.0.0.0', () => {
  log.info('Server started', {
    port: PORT,
    environment: process.env.NODE_ENV || 'development',
    pid: process.pid
  });
});

// Handle server errors
server.on('error', (error) => {
  log.error('Server error', error);
  process.exit(1);
});
```

### 🔧 Bước 2: Production Dockerfile
Tạo `Dockerfile.production`:
```dockerfile
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM node:18-alpine AS runner
WORKDIR /app

# Install dumb-init for signal handling
RUN apk add --no-cache dumb-init curl

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy files
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs app.js package.json ./
COPY --chown=nodejs:nodejs public ./public

# Create logs directory
RUN mkdir -p /app/logs && \
    chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

# Health checks
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health/live || exit 1

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "app.js"]
```

### 🔧 Bước 3: Docker Compose Production
Tạo `docker-compose.production.yml`:
```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.production
    environment:
      - NODE_ENV=production
      - PORT=3000
    ports:
      - "3000:3000"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health/live"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
```

### 🧪 Testing Production Features
```bash
# Build và run production
docker-compose -f docker-compose.production.yml up -d

# Test health endpoints
curl http://localhost:3000/api/health
curl http://localhost:3000/api/health/ready
curl http://localhost:3000/api/health/live

# Test metrics
curl http://localhost:3000/api/metrics

# Test graceful shutdown
docker-compose -f docker-compose.production.yml stop

# Check logs
docker-compose -f docker-compose.production.yml logs
```

### 🏆 Success Criteria
- [ ] Structured logging implemented
- [ ] Graceful shutdown working
- [ ] Health checks (ready/live) available
- [ ] Metrics endpoint functional
- [ ] Resource limits set
- [ ] Proper error handling

---

## 🌍 Challenge 4: Multi-environment

### 🎯 Mục tiêu
- Tạo different Dockerfile cho dev/prod
- Use build args cho customization
- Implement different configurations
- Environment-specific optimizations

### 🔧 Bước 1: Build Args Dockerfile
Tạo `Dockerfile.args`:
```dockerfile
# Build arguments
ARG NODE_ENV=production
ARG NODE_VERSION=18
ARG ALPINE_VERSION=3.18

FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS base
WORKDIR /app

# Install dependencies based on environment
FROM base AS deps
COPY package*.json ./
RUN if [ "$NODE_ENV" = "development" ]; then \
        npm ci; \
    else \
        npm ci --only=production && npm cache clean --force; \
    fi

# Development stage
FROM base AS development
ARG NODE_ENV
ENV NODE_ENV=$NODE_ENV
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm install -g nodemon
EXPOSE 3000
CMD ["npm", "run", "dev"]

# Production stage
FROM base AS production
ARG NODE_ENV
ENV NODE_ENV=$NODE_ENV

# Install production utilities
RUN apk add --no-cache dumb-init curl

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy production files
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs app.js package.json ./
COPY --chown=nodejs:nodejs public ./public

USER nodejs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health/live || exit 1

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "app.js"]

# Final stage selection
FROM ${NODE_ENV} AS final
```

### 🔧 Bước 2: Environment-specific Compose files

**Base: `docker-compose.base.yml`**
```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.args
    volumes:
      - ./public:/app/public
    ports:
      - "3000:3000"
```

**Development: `docker-compose.dev.yml`**
```yaml
version: '3.8'
services:
  app:
    build:
      args:
        NODE_ENV: development
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - DEBUG=*
    ports:
      - "3000:3000"
      - "9229:9229"  # Debug port
    command: npm run dev
```

**Production: `docker-compose.prod.yml`**
```yaml
version: '3.8'
services:
  app:
    build:
      args:
        NODE_ENV: production
    environment:
      - NODE_ENV=production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health/live"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
```

**Staging: `docker-compose.staging.yml`**
```yaml
version: '3.8'
services:
  app:
    build:
      args:
        NODE_ENV: production
    environment:
      - NODE_ENV=staging
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health/live"]
      interval: 60s
      timeout: 15s
      retries: 2
```

### 🔧 Bước 3: Environment Config Files

**`.env.development`**
```bash
NODE_ENV=development
PORT=3000
DEBUG=app:*
LOG_LEVEL=debug
```

**`.env.production`**
```bash
NODE_ENV=production
PORT=3000
LOG_LEVEL=info
```

**`.env.staging`**
```bash
NODE_ENV=staging
PORT=3000
LOG_LEVEL=warn
```

### 🔧 Bước 4: Update package.json
```json
{
  "scripts": {
    "start": "node app.js",
    "dev": "nodemon app.js",
    "debug": "nodemon --inspect=0.0.0.0:9229 app.js",
    "docker:dev": "docker-compose -f docker-compose.base.yml -f docker-compose.dev.yml up",
    "docker:prod": "docker-compose -f docker-compose.base.yml -f docker-compose.prod.yml up",
    "docker:staging": "docker-compose -f docker-compose.base.yml -f docker-compose.staging.yml up"
  }
}
```

### 🔧 Bước 5: Build Script
Tạo `build.sh`:
```bash
#!/bin/bash

# Build script for different environments
ENVIRONMENT=${1:-development}
TAG=${2:-latest}

echo "Building for environment: $ENVIRONMENT"

case $ENVIRONMENT in
  "development")
    docker build \
      --build-arg NODE_ENV=development \
      --target development \
      -t my-node-app:dev-$TAG \
      -f Dockerfile.args .
    ;;
  "staging")
    docker build \
      --build-arg NODE_ENV=production \
      --target production \
      -t my-node-app:staging-$TAG \
      -f Dockerfile.args .
    ;;
  "production")
    docker build \
      --build-arg NODE_ENV=production \
      --target production \
      -t my-node-app:prod-$TAG \
      -f Dockerfile.args .
    ;;
  *)
    echo "Invalid environment. Use: development, staging, or production"
    exit 1
    ;;
esac

echo "Build completed for $ENVIRONMENT"
```

### 🧪 Testing Multi-environment
```bash
# Make build script executable
chmod +x build.sh

# Build for different environments
./build.sh development
./build.sh staging
./build.sh production

# Test development
docker-compose -f docker-compose.base.yml -f docker-compose.dev.yml up -d

# Test production
docker-compose -f docker-compose.base.yml -f docker-compose.prod.yml up -d

# Check images
docker images | grep my-node-app
```

### 🏆 Success Criteria
- [ ] Multi-stage builds with environment selection
- [ ] Build args working correctly
- [ ] Environment-specific configurations
- [ ] Compose file inheritance
- [ ] Automated build scripts

---

## 🎉 Completion Summary

### 📊 Achievement Overview
After completing all challenges, you should have:

1. **Optimized Images** 📏
   - ✅ Size reduced from ~300MB to <100MB
   - ✅ Multi-stage builds implemented
   - ✅ Alpine base images used

2. **Security Hardened** 🔒
   - ✅ Non-root user implementation
   - ✅ Vulnerability scanning
   - ✅ Secrets management
   - ✅ Container hardening

3. **Production Ready** 🚀
   - ✅ Structured logging
   - ✅ Graceful shutdown
   - ✅ Health checks & metrics
   - ✅ Resource limits

4. **Multi-environment** 🌍
   - ✅ Environment-specific builds
   - ✅ Build args utilization
   - ✅ Compose file inheritance
   - ✅ Automated deployment

### 🎯 Next Steps
1. **Container Orchestration** - Learn Kubernetes
2. **CI/CD Pipeline** - GitHub Actions với Docker
3. **Monitoring** - Prometheus & Grafana
4. **Cloud Deployment** - AWS ECS/EKS, GCP Cloud Run

### 📚 Resources
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Container Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Production Deployment](https://docs.docker.com/engine/swarm/stack-deploy/)

**🏆 Congratulations! Bạn đã hoàn thành tất cả Docker challenges!** 