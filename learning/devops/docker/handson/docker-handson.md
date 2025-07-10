# Docker Hands-On Tutorial - Thực hành từ A đến Z

## 🎯 Mục tiêu
Xây dựng một ứng dụng web hoàn chỉnh với Docker bao gồm:
- Frontend (React)
- Backend API (Node.js)
- Database (PostgreSQL)
- Cache (Redis)
- Reverse Proxy (Nginx)

## 📋 Yêu cầu
- Docker Desktop đã cài đặt
- Code editor (VS Code)
- Terminal/Command Prompt

---

## 🚀 Phần 1: Tạo Simple Web App với Docker

### Bước 1: Tạo Node.js API đơn giản

**1.1. Tạo thư mục project:**
```bash
mkdir docker-demo
cd docker-demo
mkdir backend frontend
```

**1.2. Tạo backend API:**
```bash
cd backend
npm init -y
npm install express cors
```

**1.3. Tạo file `backend/app.js`:**
```javascript
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

// In-memory data
let users = [
  { id: 1, name: 'Nguyen Van A', email: 'a@example.com' },
  { id: 2, name: 'Tran Thi B', email: 'b@example.com' }
];

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.get('/api/users', (req, res) => {
  res.json(users);
});

app.post('/api/users', (req, res) => {
  const newUser = {
    id: users.length + 1,
    name: req.body.name,
    email: req.body.email
  };
  users.push(newUser);
  res.status(201).json(newUser);
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
```

**1.4. Update `backend/package.json`:**
```json
{
  "name": "docker-demo-backend",
  "version": "1.0.0",
  "scripts": {
    "start": "node app.js",
    "dev": "nodemon app.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
```

### Bước 2: Tạo Dockerfile cho Backend

**2.1. Tạo `backend/Dockerfile`:**
```dockerfile
# Sử dụng Node.js 18 Alpine image (nhẹ hơn)
FROM node:18-alpine

# Set working directory trong container
WORKDIR /app

# Copy package.json và package-lock.json (nếu có)
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy source code
COPY . .

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3001/api/health || exit 1

# Run application
CMD ["npm", "start"]
```

**2.2. Tạo `backend/.dockerignore`:**
```
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.nyc_output
coverage
.vscode
```

### Bước 3: Build và Test Backend

**3.1. Build image:**
```bash
cd backend
docker build -t docker-demo-backend .
```

**3.2. Run container:**
```bash
docker run -d -p 3001:3001 --name backend-container docker-demo-backend
```

**3.3. Test API:**
```bash
# Test health endpoint
curl http://localhost:3001/api/health

# Test users endpoint
curl http://localhost:3001/api/users

# Add new user
curl -X POST http://localhost:3001/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'
```

**3.4. Check logs:**
```bash
docker logs backend-container
```

**3.5. Stop và cleanup:**
```bash
docker stop backend-container
docker rm backend-container
```

---

## 🎨 Phần 2: Thêm Frontend với React

### Bước 1: Tạo React App

**1.1. Tạo React app:**
```bash
cd ../frontend
npx create-react-app . --template typescript
npm install axios
```

**1.2. Tạo `frontend/src/App.tsx`:**
```typescript
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

interface User {
  id: number;
  name: string;
  email: string;
}

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';

function App() {
  const [users, setUsers] = useState<User[]>([]);
  const [newUser, setNewUser] = useState({ name: '', email: '' });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_URL}/api/users`);
      setUsers(response.data);
    } catch (error) {
      console.error('Error fetching users:', error);
    } finally {
      setLoading(false);
    }
  };

  const addUser = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await axios.post(`${API_URL}/api/users`, newUser);
      setNewUser({ name: '', email: '' });
      fetchUsers();
    } catch (error) {
      console.error('Error adding user:', error);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>🐳 Docker Demo App</h1>
        
        <div className="users-section">
          <h2>Users List</h2>
          {loading ? (
            <p>Loading...</p>
          ) : (
            <ul className="users-list">
              {users.map(user => (
                <li key={user.id}>
                  <strong>{user.name}</strong> - {user.email}
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="add-user-section">
          <h2>Add New User</h2>
          <form onSubmit={addUser} className="user-form">
            <input
              type="text"
              placeholder="Name"
              value={newUser.name}
              onChange={(e) => setNewUser({...newUser, name: e.target.value})}
              required
            />
            <input
              type="email"
              placeholder="Email"
              value={newUser.email}
              onChange={(e) => setNewUser({...newUser, email: e.target.value})}
              required
            />
            <button type="submit">Add User</button>
          </form>
        </div>
      </header>
    </div>
  );
}

export default App;
```

**1.3. Update `frontend/src/App.css`:**
```css
.App {
  text-align: center;
}

.App-header {
  background-color: #282c34;
  padding: 20px;
  color: white;
  min-height: 100vh;
}

.users-section, .add-user-section {
  margin: 30px 0;
  padding: 20px;
  background-color: #363636;
  border-radius: 8px;
  max-width: 600px;
  margin-left: auto;
  margin-right: auto;
}

.users-list {
  list-style: none;
  padding: 0;
}

.users-list li {
  background-color: #4a4a4a;
  margin: 10px 0;
  padding: 15px;
  border-radius: 5px;
}

.user-form {
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-width: 400px;
  margin: 0 auto;
}

.user-form input, .user-form button {
  padding: 12px;
  border: none;
  border-radius: 5px;
  font-size: 16px;
}

.user-form button {
  background-color: #007acc;
  color: white;
  cursor: pointer;
}

.user-form button:hover {
  background-color: #005a99;
}
```

### Bước 2: Dockerize Frontend

**2.1. Tạo `frontend/Dockerfile`:**
```dockerfile
# Multi-stage build

# Stage 1: Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build app
RUN npm run build

# Stage 2: Production stage
FROM nginx:alpine

# Copy built app từ builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

**2.2. Tạo `frontend/nginx.conf`:**
```nginx
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    server {
        listen 80;
        server_name localhost;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
            try_files $uri $uri/ /index.html;
        }

        # API proxy
        location /api {
            proxy_pass http://backend:3001;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

**2.3. Tạo `frontend/.dockerignore`:**
```
node_modules
build
.git
README.md
.env
.vscode
```

---

## 🐘 Phần 3: Thêm Database với Docker Compose

### Bước 1: Setup Docker Compose

**1.1. Tạo `docker-compose.yml` ở root project:**
```yaml
version: '3.8'

services:
  # PostgreSQL Database
  db:
    image: postgres:15-alpine
    container_name: demo-postgres
    environment:
      POSTGRES_DB: demo_db
      POSTGRES_USER: demo_user
      POSTGRES_PASSWORD: demo_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backend/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U demo_user -d demo_db"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: demo-redis
    ports:
      - "6379:6379"
    networks:
      - app-network
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

  # Backend API
  backend:
    build: 
      context: ./backend
      dockerfile: Dockerfile
    container_name: demo-backend
    environment:
      - NODE_ENV=production
      - PORT=3001
      - DB_HOST=db
      - DB_PORT=5432
      - DB_NAME=demo_db
      - DB_USER=demo_user
      - DB_PASSWORD=demo_password
      - REDIS_URL=redis://redis:6379
    ports:
      - "3001:3001"
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - app-network
    volumes:
      - ./backend:/app
      - /app/node_modules

  # Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: demo-frontend
    environment:
      - REACT_APP_API_URL=http://localhost:3001
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
```

### Bước 2: Update Backend để sử dụng PostgreSQL

**2.1. Tạo `backend/init.sql`:**
```sql
-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (name, email) VALUES
('Nguyen Van A', 'a@example.com'),
('Tran Thi B', 'b@example.com'),
('Le Van C', 'c@example.com');
```

**2.2. Update `backend/package.json` - thêm dependencies:**
```bash
cd backend
npm install pg redis dotenv
npm install --save-dev @types/pg
```

**2.3. Tạo `backend/app.js` mới với database:**
```javascript
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const redis = require('redis');

const app = express();
const PORT = process.env.PORT || 3001;

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'demo_db',
  user: process.env.DB_USER || 'demo_user',
  password: process.env.DB_PASSWORD || 'demo_password',
});

// Redis connection
const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379'
});

redisClient.on('error', (err) => console.log('Redis Client Error', err));
redisClient.connect();

app.use(cors());
app.use(express.json());

// Health check
app.get('/api/health', async (req, res) => {
  try {
    // Check database
    await pool.query('SELECT 1');
    
    // Check redis
    await redisClient.ping();
    
    res.json({ 
      status: 'OK', 
      timestamp: new Date().toISOString(),
      services: {
        database: 'connected',
        redis: 'connected'
      }
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'ERROR', 
      error: error.message 
    });
  }
});

// Get all users
app.get('/api/users', async (req, res) => {
  try {
    // Try cache first
    const cacheKey = 'users:all';
    const cachedUsers = await redisClient.get(cacheKey);
    
    if (cachedUsers) {
      return res.json(JSON.parse(cachedUsers));
    }

    // Get from database
    const result = await pool.query('SELECT * FROM users ORDER BY id');
    
    // Cache for 5 minutes
    await redisClient.setEx(cacheKey, 300, JSON.stringify(result.rows));
    
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add new user
app.post('/api/users', async (req, res) => {
  try {
    const { name, email } = req.body;
    
    const result = await pool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [name, email]
    );

    // Clear cache
    await redisClient.del('users:all');
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get user by ID
app.get('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
```

---

## 🚀 Phần 4: Chạy Full Application

### Bước 1: Build và Start All Services

**1.1. Build tất cả images:**
```bash
docker-compose build
```

**1.2. Start all services:**
```bash
docker-compose up -d
```

**1.3. Check status:**
```bash
docker-compose ps
```

**1.4. View logs:**
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
```

### Bước 2: Test Application

**2.1. Test health:**
```bash
curl http://localhost:3001/api/health
```

**2.2. Test users API:**
```bash
curl http://localhost:3001/api/users
```

**2.3. Add user:**
```bash
curl -X POST http://localhost:3001/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Docker User","email":"docker@example.com"}'
```

**2.4. Test frontend:**
Mở browser: `http://localhost`

### Bước 3: Monitor và Debug

**3.1. Check container stats:**
```bash
docker stats
```

**3.2. Exec into containers:**
```bash
# Database
docker-compose exec db psql -U demo_user -d demo_db

# Backend
docker-compose exec backend sh

# Redis
docker-compose exec redis redis-cli
```

**3.3. Check database data:**
```bash
docker-compose exec db psql -U demo_user -d demo_db -c "SELECT * FROM users;"
```

---

## 🔧 Phần 5: Advanced Operations

### Scaling Services

**5.1. Scale backend:**
```bash
docker-compose up --scale backend=3 -d
```

**5.2. Load balancer config:**
Tạo `nginx/nginx.conf`:
```nginx
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend_1:3001;
        server backend_2:3001;
        server backend_3:3001;
    }

    server {
        listen 80;
        
        location /api {
            proxy_pass http://backend;
        }
        
        location / {
            root /usr/share/nginx/html;
            try_files $uri $uri/ /index.html;
        }
    }
}
```

### Production Deployment

**5.3. Tạo `docker-compose.prod.yml`:**
```yaml
version: '3.8'

services:
  backend:
    environment:
      - NODE_ENV=production
    restart: unless-stopped
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  frontend:
    restart: unless-stopped

  db:
    restart: unless-stopped
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    restart: unless-stopped
    volumes:
      - redis_data:/data
```

**5.4. Deploy production:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Cleanup

**5.5. Stop và cleanup:**
```bash
# Stop services
docker-compose down

# Remove volumes (careful!)
docker-compose down -v

# Remove images
docker-compose down --rmi all

# Full cleanup
docker system prune -a -f
```

---

## 📚 Kết luận

Bạn đã hoàn thành việc xây dựng một full-stack application với Docker bao gồm:

✅ **Frontend** - React with TypeScript  
✅ **Backend** - Node.js API với PostgreSQL  
✅ **Database** - PostgreSQL với init script  
✅ **Cache** - Redis cho performance  
✅ **Orchestration** - Docker Compose  
✅ **Production-ready** - Health checks, scaling, monitoring  

### Next Steps:
1. Thêm monitoring với Prometheus/Grafana
2. Implement CI/CD với GitHub Actions
3. Deploy lên cloud (AWS ECS, Google Cloud Run)
4. Add security scanning với tools như Snyk
5. Implement log aggregation với ELK stack

🎉 **Chúc mừng! Bạn đã thành công dockerize một ứng dụng thực tế!** 