# Docker Build Internals - Bản chất của quá trình build

## 🎯 Tổng quan
Khi chạy `docker build`, Docker thực hiện một series các steps phức tạp để tạo ra image từ Dockerfile. Hãy cùng tìm hiểu chi tiết những gì xảy ra bên dưới.

---

## 🔄 Docker Build Process Flow

### 📋 High-level Overview
```
User Command: docker build -t myapp .
     ↓
1. Parse Dockerfile
2. Create Build Context
3. Send Context to Docker Daemon
4. Execute Instructions Layer by Layer
5. Cache Management
6. Create Final Image
7. Tag Image
```

---

## 🏗️ Step-by-Step Breakdown

### **Step 1: Parse Dockerfile**
```bash
docker build -t myapp .
```

**Những gì xảy ra:**
- Docker client đọc `Dockerfile` trong build context
- Parse từng instruction (FROM, RUN, COPY, etc.)
- Validate syntax và dependencies
- Tạo build plan

**Ví dụ Dockerfile:**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

**Build plan được tạo:**
```
Step 1/7: FROM node:18-alpine
Step 2/7: WORKDIR /app
Step 3/7: COPY package*.json ./
Step 4/7: RUN npm install
Step 5/7: COPY . .
Step 6/7: EXPOSE 3000
Step 7/7: CMD ["npm", "start"]
```

### **Step 2: Create Build Context**

**Build Context là gì:**
- Tất cả files và directories trong path được chỉ định (`.` trong example)
- Docker tar (archive) tất cả files này
- Gửi đến Docker daemon

**Commands để observe:**
```bash
# Check build context size
du -sh .

# List files trong build context
find . -type f | head -20

# Check .dockerignore
cat .dockerignore
```

**Internal process:**
```bash
# Docker tạo temporary tar file
/tmp/docker-build-context-123456.tar

# Exclude files theo .dockerignore
# Send tar to daemon qua Docker API
```

### **Step 3: Docker Daemon Processing**

**Docker Daemon nhận context:**
```
Sending build context to Docker daemon  2.048kB
```

**Daemon actions:**
1. Extract tar file vào temporary directory
2. Validate Dockerfile syntax
3. Check base image availability
4. Prepare build environment

### **Step 4: Layer-by-Layer Execution**

**Mỗi instruction = 1 layer mới:**

#### **FROM node:18-alpine**
```bash
# Internal actions:
1. Check local image cache
2. If not found, pull from registry
3. Create base container từ image
4. Set this làm starting point
```

**Docker output:**
```
Step 1/7 : FROM node:18-alpine
18-alpine: Pulling from library/node
4abcf2066143: Pull complete
cc4dc0dfefd3: Pull complete
...
```

#### **WORKDIR /app**
```bash
# Internal actions:
1. Tạo new layer từ previous layer
2. Create directory /app nếu chưa exist
3. Set working directory metadata
4. Commit layer
```

#### **COPY package*.json ./**
```bash
# Internal actions:
1. Tạo new layer
2. Copy files từ build context vào container filesystem
3. Set file permissions và ownership
4. Calculate layer hash cho caching
5. Commit layer
```

#### **RUN npm install**
```bash
# Internal actions:
1. Tạo temporary container từ previous layer
2. Execute command trong container
3. Capture filesystem changes
4. Create new layer với changes
5. Remove temporary container
6. Commit layer
```

**Chi tiết RUN execution:**
```bash
# Docker tạo container
docker run --rm -it <previous_layer_id> /bin/sh -c "npm install"

# Capture changes
diff -r /old_filesystem /new_filesystem

# Create layer từ diff
```

---

## 🗂️ Layer Management

### **Layer Structure**
Mỗi layer là một filesystem diff:
```
Layer 1 (FROM): Base filesystem
Layer 2 (WORKDIR): + /app directory
Layer 3 (COPY): + package.json, package-lock.json
Layer 4 (RUN): + node_modules/
Layer 5 (COPY): + application source code
Layer 6 (EXPOSE): + metadata (port 3000)
Layer 7 (CMD): + metadata (start command)
```

### **Layer Storage**
```bash
# Docker stores layers in
/var/lib/docker/overlay2/

# Each layer có unique hash
sha256:abc123...
sha256:def456...
```

### **Inspect layers:**
```bash
# View image layers
docker history myapp

# Detailed layer info
docker inspect myapp

# Layer sizes
docker system df -v
```

---

## 🚀 Caching Mechanism

### **Cache Key Generation**
Docker tạo cache key cho mỗi instruction:
```dockerfile
# Cache key = hash(instruction + context)
COPY package*.json ./
# Key = hash("COPY package*.json ./" + file_contents + file_metadata)

RUN npm install
# Key = hash("RUN npm install" + previous_layer_hash)
```

### **Cache Hit vs Miss**

**Cache Hit:**
```
Step 3/7 : COPY package*.json ./
 ---> Using cache
 ---> 2d3e4f567890
```

**Cache Miss:**
```
Step 3/7 : COPY package*.json ./
 ---> 1a2b3c456789
Removing intermediate container abc123def456
 ---> 9e8d7c654321
```

### **Cache Invalidation**
```dockerfile
# Nếu package.json changes
COPY package*.json ./  # Cache MISS - file changed
RUN npm install        # Cache MISS - dependency invalidated
COPY . .              # Cache MISS - all subsequent steps rebuilt
```

---

## 🔧 Build Optimizations

### **BuildKit (Modern Builder)**
```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1
docker build -t myapp .

# Or set in daemon.json
{
  "features": {
    "buildkit": true
  }
}
```

**BuildKit improvements:**
- Parallel layer building
- Advanced caching
- Dependency analysis
- Mount secrets
- Better output

### **Multi-stage Efficiency**
```dockerfile
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS final
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
CMD ["npm", "start"]
```

**Internal process:**
```
Build Stage 1 (deps):
  Layer 1: FROM node:18-alpine
  Layer 2: WORKDIR /app  
  Layer 3: COPY package*.json
  Layer 4: RUN npm ci

Build Stage 2 (final):
  Layer 1: FROM node:18-alpine
  Layer 2: WORKDIR /app
  Layer 3: COPY --from=deps (reference to stage 1)
  Layer 4: COPY source code
  Layer 5: CMD
```

---

## 📊 Build Context Optimization

### **What gets sent:**
```bash
# Debug build context
docker build --no-cache --progress=plain -t myapp . 2>&1 | grep "COPY\|ADD"

# Check context size
du -sh .

# List all files being sent
tar --exclude-from=.dockerignore -cf - . | tar -tv
```

### **.dockerignore Impact**
```bash
# Without .dockerignore
Sending build context to Docker daemon  156.7MB

# With proper .dockerignore
Sending build context to Docker daemon  2.048kB
```

**Example .dockerignore:**
```
node_modules
.git
*.log
coverage/
.env
README.md
```

---

## 🔍 Debugging Build Process

### **Verbose Build Output**
```bash
# See detailed build steps
docker build --progress=plain --no-cache -t myapp .

# BuildKit detailed output
DOCKER_BUILDKIT=1 docker build --progress=plain -t myapp .
```

### **Inspect Intermediate Layers**
```bash
# Run container từ intermediate layer
docker run -it <layer_id> /bin/sh

# Check filesystem changes
docker diff <container_id>

# Debug specific layer
docker history --no-trunc myapp
```

### **Build with Debug**
```bash
# Build và keep intermediate containers
docker build --rm=false -t myapp .

# List all containers (including stopped)
docker ps -a

# Inspect intermediate container
docker commit <container_id> debug-layer
docker run -it debug-layer /bin/sh
```

---

## ⚡ Performance Considerations

### **Build Time Factors**

**1. Base Image Size**
```dockerfile
# Large base image - slow pull
FROM ubuntu:20.04     # ~72MB

# Optimized base image - fast pull  
FROM alpine:3.18      # ~5MB
```

**2. Context Size**
```bash
# Large context - slow transfer
Sending build context to Docker daemon  500MB

# Optimized context - fast transfer
Sending build context to Docker daemon  5MB
```

**3. Layer Ordering**
```dockerfile
# ❌ Bad - invalidates cache frequently
COPY . .              # Changes often
RUN npm install       # Rebuilds dependencies

# ✅ Good - cache-friendly
COPY package*.json ./ # Changes rarely
RUN npm install       # Uses cache
COPY . .             # Only rebuilds app code
```

### **Cache Optimization**
```dockerfile
# Optimize for cache hits
FROM node:18-alpine

# Step that changes rarely
WORKDIR /app

# Dependencies (stable)
COPY package*.json ./
RUN npm ci --only=production

# Source code (changes frequently) 
COPY . .

# Metadata (rare changes)
EXPOSE 3000
CMD ["npm", "start"]
```

---

## 🧰 Build Tools & Commands

### **Useful Build Commands**
```bash
# Build với specific Dockerfile
docker build -f Dockerfile.prod -t myapp:prod .

# Build với build args
docker build --build-arg NODE_ENV=production -t myapp .

# Build với target stage
docker build --target deps -t myapp:deps .

# Build với no cache
docker build --no-cache -t myapp .

# Build với custom context
docker build -f ./docker/Dockerfile ./app-directory

# Build from URL
docker build https://github.com/user/repo.git#main:docker
```

### **Build Analysis**
```bash
# Analyze build performance
time docker build -t myapp .

# Check build cache usage
docker system df

# Prune build cache
docker builder prune

# Inspect build cache
docker system df -v | grep -i build
```

---

## 📈 Advanced Build Features

### **BuildKit Advanced Features**

**1. Build Secrets**
```dockerfile
# syntax=docker/dockerfile:1
FROM alpine
RUN --mount=type=secret,id=mypassword cat /run/secrets/mypassword
```

```bash
# Build với secret
echo "secret123" | docker build --secret id=mypassword,src=- .
```

**2. SSH Mount**
```dockerfile
# syntax=docker/dockerfile:1
FROM alpine
RUN --mount=type=ssh git clone git@github.com:private/repo.git
```

**3. Cache Mount**
```dockerfile
# syntax=docker/dockerfile:1
FROM node:18-alpine
RUN --mount=type=cache,target=/root/.npm npm install
```

### **Remote Build Context**
```bash
# Build từ Git repository
docker build https://github.com/user/repo.git

# Build từ tarball
docker build http://server.com/context.tar.gz

# Build từ stdin
tar -czf - . | docker build -
```

---

## 🎯 Best Practices Summary

### **Build Efficiency Checklist**
- [ ] Use appropriate base image (Alpine vs Ubuntu)
- [ ] Optimize .dockerignore file
- [ ] Order instructions for cache efficiency
- [ ] Use multi-stage builds
- [ ] Minimize layer count
- [ ] Use build args for flexibility
- [ ] Enable BuildKit
- [ ] Regular cache cleanup

### **Security Considerations**
- [ ] Don't include secrets trong build context
- [ ] Use specific image tags
- [ ] Run security scanning
- [ ] Use non-root user
- [ ] Minimize attack surface

### **Performance Tips**
- [ ] Build locally vs CI/CD differences
- [ ] Parallel builds với BuildKit
- [ ] Registry caching strategies
- [ ] Build context optimization

---

## 🔬 Real Example Walkthrough

Let's trace một actual build:

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

**Detailed internal execution:**

```bash
# User runs
docker build -t myapp .

# 1. Docker client tạo build context
tar -czf /tmp/build-context.tar.gz --exclude-from=.dockerignore .

# 2. Send context to daemon
POST /build HTTP/1.1
Content-Type: application/x-tar
Content-Length: 2048

# 3. Daemon extracts context
mkdir /tmp/docker-build-123456
tar -xzf build-context.tar.gz -C /tmp/docker-build-123456

# 4. Execute FROM
docker pull node:18-alpine  # if not cached
container_id=$(docker create node:18-alpine)

# 5. Execute WORKDIR
docker cp /dev/null $container_id:/app/.dockerenv
docker commit $container_id layer_1

# 6. Execute COPY package*.json
docker cp /tmp/docker-build-123456/package.json $container_id:/app/
docker cp /tmp/docker-build-123456/package-lock.json $container_id:/app/
docker commit $container_id layer_2

# 7. Execute RUN npm install
run_container=$(docker run -d layer_2 npm install)
docker wait $run_container
docker commit $run_container layer_3

# 8. Execute COPY . .
docker cp /tmp/docker-build-123456/. $container_id:/app/
docker commit $container_id layer_4

# 9. Execute EXPOSE & CMD (metadata only)
docker commit --change="EXPOSE 3000" --change='CMD ["npm", "start"]' $container_id final_layer

# 10. Tag final image
docker tag final_layer myapp:latest

# 11. Cleanup
rm -rf /tmp/docker-build-123456
docker rm $container_id $run_container
```

---

## 📚 Conclusion

**Key Takeaways:**

1. **Layer-based Architecture**: Mỗi instruction tạo new layer
2. **Caching System**: Docker uses intelligent caching để speed up builds
3. **Context Management**: Build context được tar và send đến daemon
4. **Optimization Opportunities**: Order matters, cache invalidation, context size
5. **Modern BuildKit**: Parallel execution, advanced features

**Understanding build internals giúp:**
- ✅ Optimize build performance
- ✅ Debug build issues
- ✅ Design better Dockerfiles
- ✅ Implement effective caching strategies
- ✅ Reduce build times and image sizes

**Next level**: Container runtime internals, registry interactions, orchestration với Kubernetes! 🚀 