# Docker Cheatsheet - Tài liệu tham khảo nhanh

## 📋 Các khái niệm cơ bản
- **Image**: File đơn lẻ chứa tất cả dependencies và config cần thiết để chạy một chương trình
- **Container**: Instance của một image, chạy một chương trình cụ thể
- **Dockerfile**: File text chứa các instruction để build image
- **Registry**: Nơi lưu trữ các Docker images (Docker Hub, AWS ECR, etc.)

## 🐳 Container Commands

### `docker run` - Tạo và chạy container
```bash
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
```

**Parameters quan trọng:**
- `-d, --detach` (optional): Chạy container ở background
- `-i, --interactive` (optional): Giữ STDIN mở
- `-t, --tty` (optional): Allocate pseudo-TTY
- `-p, --publish` (optional): Map port host:container (vd: `-p 8080:80`)
- `-v, --volume` (optional): Mount volume host:container (vd: `-v /host/path:/container/path`)
- `--name` (optional): Đặt tên cho container
- `--rm` (optional): Tự động xóa container khi stop
- `-e, --env` (optional): Set environment variables
- `--network` (optional): Connect container to network

**Ví dụ:**
```bash
# Chạy nginx với port mapping
docker run -d -p 8080:80 --name my-nginx nginx

# Chạy interactive shell
docker run -it ubuntu bash

# Chạy với environment variables
docker run -e MYSQL_ROOT_PASSWORD=secret mysql
```

### `docker ps` - List containers
```bash
docker ps [OPTIONS]
```

**Parameters:**
- `-a, --all` (optional): Show tất cả containers (bao gồm stopped)
- `-q, --quiet` (optional): Chỉ show container IDs
- `--format` (optional): Format output (vd: `table {{.Names}}\t{{.Status}}`)
- `-f, --filter` (optional): Filter output (vd: `--filter status=running`)

### `docker stop` - Dừng container
```bash
docker stop [OPTIONS] CONTAINER [CONTAINER...]
```

**Parameters:**
- `CONTAINER` (required): Container ID hoặc name
- `-t, --time` (optional): Thời gian chờ trước khi force kill (default: 10s)

### `docker start` - Khởi động container đã stop
```bash
docker start [OPTIONS] CONTAINER [CONTAINER...]
```

**Parameters:**
- `CONTAINER` (required): Container ID hoặc name
- `-a, --attach` (optional): Attach STDOUT/STDERR
- `-i, --interactive` (optional): Attach STDIN

### `docker exec` - Chạy command trong container đang chạy
```bash
docker exec [OPTIONS] CONTAINER COMMAND [ARG...]
```

**Parameters:**
- `CONTAINER` (required): Container ID hoặc name
- `COMMAND` (required): Command cần chạy
- `-i, --interactive` (optional): Giữ STDIN mở
- `-t, --tty` (optional): Allocate pseudo-TTY
- `-d, --detach` (optional): Chạy command ở background

**Ví dụ:**
```bash
# Mở bash shell trong container
docker exec -it my-container bash

# Chạy command một lần
docker exec my-container ls /app
```

### `docker rm` - Xóa container
```bash
docker rm [OPTIONS] CONTAINER [CONTAINER...]
```

**Parameters:**
- `CONTAINER` (required): Container ID hoặc name
- `-f, --force` (optional): Force remove container đang chạy
- `-v, --volumes` (optional): Remove volumes associated với container

## 🖼️ Image Commands

### `docker build` - Build image từ Dockerfile
```bash
docker build [OPTIONS] PATH | URL | -
```

**Parameters:**
- `PATH` (required): Path đến build context (thường là `.`)
- `-t, --tag` (optional): Name và tag cho image (vd: `myapp:1.0`)
- `-f, --file` (optional): Path đến Dockerfile (default: `Dockerfile`)
- `--no-cache` (optional): Không sử dụng cache khi build
- `--build-arg` (optional): Set build-time variables

**Ví dụ:**
```bash
# Build image với tag
docker build -t myapp:latest .

# Build với custom Dockerfile
docker build -f custom.dockerfile -t myapp .
```

### `docker images` - List images
```bash
docker images [OPTIONS] [REPOSITORY[:TAG]]
```

**Parameters:**
- `-a, --all` (optional): Show tất cả images (bao gồm intermediate)
- `-q, --quiet` (optional): Chỉ show image IDs
- `--format` (optional): Format output
- `-f, --filter` (optional): Filter output

### `docker pull` - Download image từ registry
```bash
docker pull [OPTIONS] NAME[:TAG|@DIGEST]
```

**Parameters:**
- `NAME` (required): Image name
- `TAG` (optional): Image tag (default: `latest`)

### `docker push` - Upload image lên registry
```bash
docker push [OPTIONS] NAME[:TAG|@DIGEST]
```

**Parameters:**
- `NAME` (required): Image name
- `TAG` (optional): Image tag

### `docker rmi` - Xóa image
```bash
docker rmi [OPTIONS] IMAGE [IMAGE...]
```

**Parameters:**
- `IMAGE` (required): Image ID hoặc name:tag
- `-f, --force` (optional): Force remove image

## 🌐 Network Commands

### `docker network ls` - List networks
```bash
docker network ls [OPTIONS]
```

### `docker network create` - Tạo network
```bash
docker network create [OPTIONS] NETWORK
```

**Parameters:**
- `NETWORK` (required): Network name
- `-d, --driver` (optional): Network driver (bridge, overlay, etc.)

### `docker network connect` - Connect container to network
```bash
docker network connect [OPTIONS] NETWORK CONTAINER
```

## 💾 Volume Commands

### `docker volume ls` - List volumes
```bash
docker volume ls [OPTIONS]
```

### `docker volume create` - Tạo volume
```bash
docker volume create [OPTIONS] [VOLUME]
```

### `docker volume rm` - Xóa volume
```bash
docker volume rm [OPTIONS] VOLUME [VOLUME...]
```

## 🔍 System Commands

### `docker logs` - Xem logs của container
```bash
docker logs [OPTIONS] CONTAINER
```

**Parameters:**
- `CONTAINER` (required): Container ID hoặc name
- `-f, --follow` (optional): Follow log output real-time
- `--tail` (optional): Số dòng logs cuối cần show
- `-t, --timestamps` (optional): Show timestamps

### `docker inspect` - Xem thông tin chi tiết
```bash
docker inspect [OPTIONS] NAME|ID [NAME|ID...]
```

### `docker stats` - Xem resource usage real-time
```bash
docker stats [OPTIONS] [CONTAINER...]
```

### `docker system prune` - Cleanup unused data
```bash
docker system prune [OPTIONS]
```

**Parameters:**
- `-a, --all` (optional): Remove tất cả unused images
- `-f, --force` (optional): Không hỏi confirmation

## 🔧 Docker Compose - Quản lý Multi-Container Applications

### 📝 Docker Compose là gì?
Docker Compose là tool để define và run multi-container Docker applications. Sử dụng file YAML để configure services, networks và volumes của application.

**Lợi ích:**
- Quản lý nhiều containers như một application duy nhất
- Easy configuration với YAML file
- Environment isolation
- Service scaling
- Dependency management giữa các services

### 📄 File docker-compose.yml Structure

**Cấu trúc cơ bản:**
```yaml
version: '3.8'

services:
  service_name:
    image: image_name
    # hoặc
    build: ./path/to/dockerfile
    ports:
      - "host_port:container_port"
    environment:
      - KEY=value
    volumes:
      - host_path:container_path
    depends_on:
      - other_service
    networks:
      - network_name

networks:
  network_name:
    driver: bridge

volumes:
  volume_name:
    driver: local
```

**Ví dụ thực tế - Web Application với Database:**
```yaml
version: '3.8'

services:
  # Web server
  web:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    environment:
      - DEBUG=1
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
    depends_on:
      - db
    networks:
      - app-network

  # Database
  db:
    image: postgres:13
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

  # Redis cache
  redis:
    image: redis:6-alpine
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  postgres_data:
```

### 🎛️ Docker Compose Commands Chi Tiết

### `docker-compose up` - Start services
```bash
docker-compose up [OPTIONS] [SERVICE...]
```

**Parameters:**
- `-d, --detach` (optional): Run ở background
- `--build` (optional): Build images trước khi start
- `-f, --file` (optional): Specify compose file path
- `--scale SERVICE=NUM` (optional): Scale service to NUM instances
- `--force-recreate` (optional): Recreate containers ngay cả khi config không đổi
- `--no-deps` (optional): Không start linked services

**Ví dụ:**
```bash
# Start tất cả services
docker-compose up -d

# Start specific service
docker-compose up web

# Scale service
docker-compose up --scale web=3
```

### `docker-compose down` - Stop và remove services
```bash
docker-compose down [OPTIONS]
```

**Parameters:**
- `-v, --volumes` (optional): Remove named volumes declared trong compose file
- `--rmi TYPE` (optional): Remove images (all|local)
- `--remove-orphans` (optional): Remove containers cho services không defined trong compose file

### `docker-compose build` - Build hoặc rebuild services
```bash
docker-compose build [OPTIONS] [SERVICE...]
```

**Parameters:**
- `--no-cache` (optional): Build không dùng cache
- `--pull` (optional): Always pull newer version của base image

### `docker-compose logs` - View logs
```bash
docker-compose logs [OPTIONS] [SERVICE...]
```

**Parameters:**
- `-f, --follow` (optional): Follow log output real-time
- `--tail NUM` (optional): Show NUM lines từ cuối của mỗi container's log
- `-t, --timestamps` (optional): Show timestamps

### `docker-compose ps` - List containers
```bash
docker-compose ps [OPTIONS] [SERVICE...]
```

**Parameters:**
- `-q, --quiet` (optional): Chỉ show container IDs

### `docker-compose exec` - Execute command trong running service
```bash
docker-compose exec [OPTIONS] SERVICE COMMAND [ARGS...]
```

**Parameters:**
- `-d, --detach` (optional): Detached mode
- `-T` (optional): Disable pseudo-TTY allocation
- `-u, --user USER` (optional): Run command as USER

**Ví dụ:**
```bash
# Mở bash trong web service
docker-compose exec web bash

# Chạy Django migrations
docker-compose exec web python manage.py migrate
```

### `docker-compose restart` - Restart services
```bash
docker-compose restart [OPTIONS] [SERVICE...]
```

### `docker-compose stop` - Stop services
```bash
docker-compose stop [OPTIONS] [SERVICE...]
```

### `docker-compose start` - Start stopped services
```bash
docker-compose start [SERVICE...]
```

### `docker-compose pull` - Pull images cho services
```bash
docker-compose pull [OPTIONS] [SERVICE...]
```

## 🚀 Docker Compose Workflow

**1. Development Workflow:**
```bash
# 1. Start development environment
docker-compose up -d

# 2. View logs nếu cần
docker-compose logs -f web

# 3. Execute commands trong containers
docker-compose exec web python manage.py shell

# 4. Stop khi done
docker-compose down
```

**2. Production Deployment:**
```bash
# 1. Build images
docker-compose build

# 2. Start production services
docker-compose -f docker-compose.prod.yml up -d

# 3. Scale services nếu cần
docker-compose -f docker-compose.prod.yml up --scale web=3 -d
```

## 📁 Multiple Compose Files

Bạn có thể sử dụng nhiều compose files cho các environments khác nhau:

**docker-compose.yml** (base):
```yaml
version: '3.8'
services:
  web:
    build: .
    volumes:
      - .:/app
```

**docker-compose.override.yml** (development - tự động load):
```yaml
version: '3.8'
services:
  web:
    environment:
      - DEBUG=1
    ports:
      - "8000:8000"
```

**docker-compose.prod.yml** (production):
```yaml
version: '3.8'
services:
  web:
    environment:
      - DEBUG=0
    restart: unless-stopped
```

**Sử dụng:**
```bash
# Development (tự động merge base + override)
docker-compose up

# Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 🔗 Service Dependencies

**depends_on** - Chỉ định thứ tự start services:
```yaml
services:
  web:
    depends_on:
      - db
      - redis
  db:
    image: postgres
```

**⚠️ Lưu ý:** `depends_on` chỉ control start order, không đợi service "ready". Để wait for service ready, cần dùng tools như `wait-for-it` hoặc `dockerize`.

## 🌍 Environment Variables

**3 cách set environment variables:**

1. **Trong compose file:**
```yaml
services:
  web:
    environment:
      - DEBUG=1
      - SECRET_KEY=mysecret
```

2. **Từ .env file:**
```yaml
services:
  web:
    env_file:
      - .env
```

3. **Từ host environment:**
```yaml
services:
  web:
    environment:
      - SECRET_KEY=${SECRET_KEY}
```

## 💡 Tips và Best Practices

1. **Luôn sử dụng specific tags** thay vì `latest`
2. **Sử dụng .dockerignore** để exclude không cần thiết
3. **Multi-stage builds** để giảm image size
4. **Không run container as root** trong production
5. **Use volumes** cho data persistence
6. **Clean up regularly** với `docker system prune`

## 📚 Tài liệu tham khảo
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/) 