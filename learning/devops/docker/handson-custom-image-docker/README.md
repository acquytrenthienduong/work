# 🐳 Docker Practice - Custom Image

## 🎯 Mục tiêu thực hành
Tạo Dockerfile cho ứng dụng Node.js và thực hành các concepts quan trọng của Docker.

## 📋 Ứng dụng có sẵn
- **Backend**: Node.js Express server
- **Frontend**: HTML interface đẹp
- **Features**: API endpoints, file operations, statistics

## 🚀 Bước 1: Chạy ứng dụng local (không dùng Docker)

### 1.1. Cài đặt dependencies:
```bash
cd learning/devops/docker/handson-custom-image-docker
npm install
```

### 1.2. Chạy ứng dụng:
```bash
npm start
```

### 1.3. Test ứng dụng:
- Mở browser: `http://localhost:3000`
- Test các API endpoints trên giao diện web

---

## 📦 Bước 2: Tự viết Dockerfile

### 2.1. Tạo file `.dockerignore`:
```
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.vscode
data/
```

### 2.2. Tạo file `Dockerfile`:
Hãy tự viết Dockerfile theo các yêu cầu sau:

**Requirements:**
- [ ] Sử dụng Node.js 18 Alpine image
- [ ] Set working directory `/app`
- [ ] Copy package.json trước (để tận dụng Docker cache)
- [ ] Install dependencies production only
- [ ] Copy source code
- [ ] Create user không phải root
- [ ] Set appropriate ownership
- [ ] Expose port 3000
- [ ] Add health check
- [ ] Run với user không phải root

**Gợi ý commands:**
```dockerfile
# Base image
FROM node:18-alpine

# Working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Create user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Set ownership
RUN chown -R nodejs:nodejs /app
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

# Start application
CMD ["npm", "start"]
```

---

## 🔧 Bước 3: Build và Test Image

### 3.1. Build image:
```bash
docker build -t my-node-app .
```

### 3.2. Check image size:
```bash
docker images my-node-app
```

### 3.3. Run container:
```bash
docker run -d -p 3000:3000 --name my-app my-node-app
```

### 3.4. Test application:
```bash
# Health check
curl http://localhost:3000/api/health

# Stats
curl http://localhost:3000/api/stats

# Open browser
open http://localhost:3000
```

### 3.5. Check logs:
```bash
docker logs my-app
```

### 3.6. Inspect container:
```bash
docker exec -it my-app sh
```

---

## 🎯 Bước 4: Advanced Practices

### 4.1. Multi-stage Build
Tạo `Dockerfile.multi-stage`:
```dockerfile
# Stage 1: Build dependencies
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Production image
FROM node:18-alpine AS runner
WORKDIR /app

# Copy dependencies từ build stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Create user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Set ownership
RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

CMD ["npm", "start"]
```

### 4.2. Build multi-stage:
```bash
docker build -f Dockerfile.multi-stage -t my-node-app:multi-stage .
```

### 4.3. So sánh image size:
```bash
docker images | grep my-node-app
```

---

## 🌐 Bước 5: Test với Environment Variables

### 5.1. Run với env vars:
```bash
docker run -d -p 3000:3000 \
  -e NODE_ENV=production \
  -e PORT=3000 \
  --name my-app-prod \
  my-node-app
```

### 5.2. Test environment:
```bash
curl http://localhost:3000/api/health
```

---

## 💾 Bước 6: Test với Volumes

### 6.1. Run với volume:
```bash
docker run -d -p 3000:3000 \
  -v $(pwd)/data:/app/data \
  --name my-app-volume \
  my-node-app
```

### 6.2. Test file operations:
- Truy cập `http://localhost:3000`
- Sử dụng "Write File" feature
- Check file được tạo trong host: `./data/`

---

## 🧪 Bước 7: Testing và Debugging

### 7.1. Container stats:
```bash
docker stats my-app
```

### 7.2. Process trong container:
```bash
docker exec my-app ps aux
```

### 7.3. File system:
```bash
docker exec my-app ls -la /app
```

### 7.4. Network:
```bash
docker exec my-app netstat -tlnp
```

---

## 🎯 Challenges (Thử thách)

### Challenge 1: Optimize Image Size
- Giảm image size xuống dưới 100MB
- Sử dụng alpine base image
- Remove unnecessary packages

### Challenge 2: Security
- Run container với non-root user
- Scan image cho vulnerabilities
- Implement proper secrets management

### Challenge 3: Production Ready
- Add proper logging
- Implement graceful shutdown
- Add monitoring endpoints

### Challenge 4: Multi-environment
- Tạo different Dockerfile cho dev/prod
- Use build args cho customization
- Implement different configurations

---

## 🧹 Cleanup

```bash
# Stop containers
docker stop my-app my-app-prod my-app-volume

# Remove containers
docker rm my-app my-app-prod my-app-volume

# Remove images
docker rmi my-node-app my-node-app:multi-stage

# Remove volumes (optional)
docker volume prune
```

---

## 📚 Học được gì?

✅ **Dockerfile best practices**  
✅ **Multi-stage builds**  
✅ **Security với non-root user**  
✅ **Environment variables**  
✅ **Volume mounting**  
✅ **Health checks**  
✅ **Image optimization**  
✅ **Container debugging**  

## 🎉 Kết luận

Bạn đã hoàn thành việc dockerize một ứng dụng Node.js từ đầu!

**Next Steps:**
1. Thực hành với Docker Compose
2. Deploy lên cloud
3. Implement CI/CD
4. Learn Kubernetes 