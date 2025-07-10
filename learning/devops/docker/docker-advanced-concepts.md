# Docker Advanced Concepts - Network, Volume & Optimization

## 🌐 Docker Networking

### 📋 Các loại Network trong Docker

#### **1. Bridge Network (Default)**
```bash
# List networks
docker network ls

# Inspect bridge network
docker network inspect bridge

# Create custom bridge network
docker network create my-network
```

**Đặc điểm:**
- **Default network** cho containers
- Containers có thể communicate với nhau qua **IP address**
- **Isolated** từ host network
- **Port mapping** cần thiết để access từ bên ngoài

**Ví dụ:**
```bash
# Run 2 containers trên cùng network
docker run -d --name web nginx
docker run -d --name db postgres

# Check IP addresses
docker exec web ip addr show eth0
docker exec db ip addr show eth0

# Test connectivity
docker exec web ping db  # Sẽ fail vì không biết hostname
docker exec web ping 172.17.0.3  # OK nếu đúng IP
```

#### **2. Custom Bridge Network**
```bash
# Tạo custom network
docker network create --driver bridge my-app-network

# Run containers với custom network
docker run -d --name web --network my-app-network nginx
docker run -d --name db --network my-app-network postgres

# Test connectivity by hostname
docker exec web ping db  # OK! Có DNS resolution
```

**Lợi ích:**
- ✅ **Automatic DNS resolution** - containers có thể ping nhau bằng name
- ✅ **Better isolation** - tách biệt khỏi default bridge
- ✅ **Easy service discovery** - không cần hardcode IP
- ✅ **Dynamic connectivity** - connect/disconnect containers runtime

#### **3. Host Network**
```bash
# Run container with host network
docker run -d --network host nginx
```

**Đặc điểm:**
- Container **share network stack** với host
- **No network isolation** - trực tiếp bind host ports
- **Performance tối ưu** - no network overhead
- **Security risk** - container có full network access

**Khi nào sử dụng:**
- High performance requirements
- Legacy applications
- Network debugging

#### **4. None Network**
```bash
# Run container without network
docker run -d --network none alpine sleep 3600
```

**Đặc điểm:**
- **No network interface** ngoài loopback
- **Complete isolation** - không thể communicate
- **Security tối đa** - air-gapped containers

### 🔧 Network Best Practices

#### **1. Multi-tier Application**
```bash
# Create networks for different tiers
docker network create frontend-network
docker network create backend-network
docker network create db-network

# Web tier
docker run -d --name nginx \
  --network frontend-network \
  -p 80:80 nginx

# App tier (connected to both frontend và backend)
docker run -d --name app \
  --network frontend-network \
  myapp:latest

docker network connect backend-network app

# Database tier
docker run -d --name postgres \
  --network backend-network \
  -e POSTGRES_PASSWORD=secret \
  postgres

# Connect app to database network
docker network connect db-network app
```

#### **2. Service Discovery**
```yaml
# docker-compose.yml
version: '3.8'
services:
  web:
    image: nginx
    networks:
      - frontend
  
  api:
    image: myapi
    networks:
      - frontend
      - backend
    environment:
      - DB_HOST=database  # Hostname = service name
  
  database:
    image: postgres
    networks:
      - backend
    environment:
      - POSTGRES_PASSWORD=secret

networks:
  frontend:
  backend:
```

#### **3. Network Troubleshooting**
```bash
# Check container network config
docker exec -it container_name ip addr show
docker exec -it container_name route -n

# Test connectivity
docker exec -it web ping api
docker exec -it web telnet api 3000
docker exec -it web nslookup api

# Port scanning
docker exec -it web nmap -p 1-1000 api
```

---

## 💾 Docker Volumes

### 📋 Các loại Volume

#### **1. Named Volumes (Recommended)**
```bash
# Create named volume
docker volume create my-data

# List volumes
docker volume ls

# Inspect volume
docker volume inspect my-data

# Use volume
docker run -d --name app \
  -v my-data:/app/data \
  myapp:latest

# Remove volume
docker volume rm my-data
```

**Đặc điểm:**
- ✅ **Managed by Docker** - Docker quản lý storage location
- ✅ **Persistent** - data survive container deletion
- ✅ **Portable** - easy backup/restore
- ✅ **Performance** - optimized storage drivers

#### **2. Bind Mounts**
```bash
# Mount host directory
docker run -d --name app \
  -v /host/path:/container/path \
  myapp:latest

# Mount current directory
docker run -d --name app \
  -v $(pwd):/app \
  myapp:latest

# Read-only mount
docker run -d --name app \
  -v /host/path:/container/path:ro \
  myapp:latest
```

**Đặc điểm:**
- ✅ **Direct access** - file changes visible immediately
- ✅ **Development friendly** - live code reload
- ⚠️ **Host dependent** - path must exist on host
- ⚠️ **Security risk** - container can modify host files

#### **3. tmpfs Mounts**
```bash
# Mount tmpfs (RAM-based storage)
docker run -d --name app \
  --tmpfs /tmp:rw,size=100m \
  myapp:latest
```

**Đặc điểm:**
- ✅ **Fast performance** - stored in RAM
- ✅ **Temporary** - data deleted when container stops
- ✅ **Secure** - no disk writes
- ⚠️ **Limited size** - constrained by RAM

### 🔧 Volume Best Practices

#### **1. Database Persistence**
```bash
# PostgreSQL with named volume
docker run -d --name postgres \
  -v postgres_data:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=secret \
  postgres:13

# MySQL with named volume  
docker run -d --name mysql \
  -v mysql_data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=secret \
  mysql:8
```

#### **2. Configuration Files**
```bash
# Mount config files
docker run -d --name nginx \
  -v /host/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v /host/ssl:/etc/ssl:ro \
  nginx
```

#### **3. Log Files**
```bash
# Centralized logging
docker run -d --name app \
  -v /host/logs:/app/logs \
  myapp:latest

# Or use logging driver
docker run -d --name app \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  myapp:latest
```

#### **4. Backup & Restore**
```bash
# Backup volume
docker run --rm \
  -v my-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/backup.tar.gz -C /data .

# Restore volume
docker run --rm \
  -v my-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/backup.tar.gz -C /data
```

### 🚀 Volume với Docker Compose
```yaml
version: '3.8'
services:
  web:
    image: nginx
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - static_files:/var/www/html
  
  app:
    build: .
    volumes:
      - app_data:/app/data
      - ./src:/app/src:ro  # Development bind mount
      - /app/node_modules  # Anonymous volume
  
  db:
    image: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD=secret

volumes:
  postgres_data:
  app_data:
  static_files:
```

---

## 🏗️ Docker Image Optimization

### 📏 Giảm Image Size

#### **1. Chọn Base Image phù hợp**
```dockerfile
# ❌ Bad - Full Ubuntu (72MB)
FROM ubuntu:20.04

# ✅ Good - Alpine Linux (5MB) 
FROM alpine:3.18

# ✅ Better - Distroless (2MB)
FROM gcr.io/distroless/nodejs

# ✅ Best - Scratch (0MB) - chỉ cho static binaries
FROM scratch
```

**So sánh Base Images:**
```bash
# Check image sizes
docker images | grep -E "ubuntu|alpine|distroless"

# ubuntu:20.04     ~72MB
# alpine:3.18      ~5MB  
# distroless       ~2MB
```

#### **2. Multi-stage Builds**
```dockerfile
# ❌ Single stage - includes build tools in final image
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install  # includes devDependencies
COPY . .
RUN npm run build
CMD ["npm", "start"]

# ✅ Multi-stage - clean final image
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json
USER node
CMD ["npm", "start"]
```

#### **3. Minimize Layers**
```dockerfile
# ❌ Bad - nhiều RUN commands = nhiều layers
FROM alpine:3.18
RUN apk add --no-cache nodejs
RUN apk add --no-cache npm
RUN apk add --no-cache git
RUN apk add --no-cache curl

# ✅ Good - combine RUN commands
FROM alpine:3.18
RUN apk add --no-cache \
    nodejs \
    npm \
    git \
    curl

# ✅ Better - cleanup trong cùng layer
FROM alpine:3.18
RUN apk add --no-cache nodejs npm git && \
    npm install -g some-package && \
    apk del git  # Remove after use
```

#### **4. Optimize COPY Order**
```dockerfile
# ❌ Bad - copy all files first
FROM node:18-alpine
WORKDIR /app
COPY . .  # Changes here invalidate cache
RUN npm install

# ✅ Good - copy package.json first
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./  # Cache-friendly
RUN npm ci --only=production
COPY . .  # Source changes don't affect dependencies
```

#### **5. Use .dockerignore**
```bash
# .dockerignore
node_modules
.git
.gitignore
README.md
.env
.vscode
*.log
coverage/
.nyc_output/
tests/
docs/
*.md
```

### 🔧 Advanced Optimization

#### **1. Distroless Images**
```dockerfile
# For Node.js apps
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

FROM gcr.io/distroless/nodejs18-debian11
WORKDIR /app
COPY --from=builder /app /app
CMD ["app.js"]
```

#### **2. Scratch Images (Go/Rust)**
```dockerfile
# For Go applications
FROM golang:1.19-alpine AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o app

FROM scratch
COPY --from=builder /app/app /app
CMD ["/app"]
```

#### **3. Dependency Optimization**
```dockerfile
# Python example
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY . .
CMD ["python", "app.py"]
```

### 📊 Image Analysis Tools

#### **1. Docker History**
```bash
# Xem layer history
docker history my-app:latest

# Xem size của từng layer
docker history my-app:latest --human=false
```

#### **2. Dive Tool**
```bash
# Install dive
curl -LO https://github.com/wagoodman/dive/releases/download/v0.10.0/dive_0.10.0_linux_amd64.tar.gz
tar -xzf dive_0.10.0_linux_amd64.tar.gz
sudo mv dive /usr/local/bin/

# Analyze image
dive my-app:latest
```

#### **3. Docker Slim**
```bash
# Install docker-slim
curl -L https://github.com/docker-slim/docker-slim/releases/download/1.40.0/docker-slim_linux.tar.gz | tar -xz
sudo mv docker-slim /usr/local/bin/

# Optimize image
docker-slim build --target my-app:latest --tag my-app:slim
```

### 🏆 Optimization Checklist

#### **Build Stage:**
- [ ] Use appropriate base image (alpine/distroless)
- [ ] Multi-stage builds for complex apps
- [ ] Combine RUN commands
- [ ] Order COPY commands for cache efficiency
- [ ] Use .dockerignore file
- [ ] Clean up package caches

#### **Security:**
- [ ] Don't run as root user
- [ ] Remove unnecessary packages
- [ ] Use specific tags (not :latest)
- [ ] Scan for vulnerabilities

#### **Performance:**
- [ ] Minimize final image size
- [ ] Use health checks
- [ ] Set proper resource limits
- [ ] Use read-only filesystems where possible

---

## 🎯 Practical Examples

### Example 1: Full-Stack App với Networks
```yaml
version: '3.8'
services:
  frontend:
    build: ./frontend
    networks:
      - frontend-network
    ports:
      - "80:80"
  
  backend:
    build: ./backend
    networks:
      - frontend-network
      - backend-network
    environment:
      - DATABASE_URL=postgresql://user:pass@database:5432/app
  
  database:
    image: postgres:13-alpine
    networks:
      - backend-network
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD=secret

networks:
  frontend-network:
  backend-network:

volumes:
  postgres_data:
```

### Example 2: Optimized Node.js App
```dockerfile
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /app
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json
RUN chown -R nodejs:nodejs /app
USER nodejs
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

## 📚 Summary

### 🌐 **Network:**
- **Bridge**: Default, cần port mapping
- **Custom Bridge**: DNS resolution, better isolation
- **Host**: High performance, security risk
- **None**: Complete isolation

### 💾 **Volume:**
- **Named**: Recommended, Docker managed
- **Bind**: Development, direct access
- **tmpfs**: Temporary, RAM-based

### 🏗️ **Optimization:**
- **Multi-stage builds**: Clean final images
- **Alpine/Distroless**: Minimal base images
- **Layer optimization**: Combine commands
- **Cache efficiency**: Smart COPY ordering

**Key takeaway**: Docker networking và volumes là foundation cho container orchestration, còn image optimization là critical cho performance và security! 🚀 