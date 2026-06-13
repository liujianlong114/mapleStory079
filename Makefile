GOPROXY=https://goproxy.cn,direct
DOCKER_COMPOSE=docker-compose

.PHONY: help build build-server build-init run-server run docker-up docker-down docker-build docker-restart clean test vet fmt init-data init

help:
	@echo "================= MapleStory 079 构建工具 ================="
	@echo ""
	@echo "本地开发:"
	@echo "  make build         - 编译所有二进制"
	@echo "  make build-server  - 编译服务器"
	@echo "  make build-init    - 编译数据初始化工具"
	@echo "  make run / run-server - 运行服务器"
	@echo "  make init / init-data - 初始化游戏数据"
	@echo "  make test          - 运行测试"
	@echo "  make vet           - 运行 go vet 检查"
	@echo "  make fmt           - 格式化 Go 代码"
	@echo "  make clean         - 清理构建产物"
	@echo ""
	@echo "Docker 部署:"
	@echo "  make docker-build  - 构建 Docker 镜像"
	@echo "  make docker-up     - 启动所有容器 (MySQL + Server + Adminer)"
	@echo "  make docker-down   - 停止所有容器"
	@echo "  make docker-restart - 重启服务"
	@echo "  make docker-logs   - 查看日志"
	@echo ""
	@echo "数据库:"
	@echo "  访问 http://localhost:8081 可使用 Adminer 管理数据库"
	@echo "  默认账号: maplestory / maplestory"
	@echo "  数据库名: maplestory"
	@echo ""

build: build-server build-init
	@echo "✅ 编译完成"

build-server:
	@echo "🚀 编译服务器..."
	GOPROXY=$(GOPROXY) go build -o bin/server ./cmd/server/
	@echo "✅ 服务器编译完成: bin/server"

build-init:
	@echo "📦 编译数据初始化工具..."
	GOPROXY=$(GOPROXY) go build -o bin/init_data ./scripts/
	@echo "✅ 初始化工具编译完成: bin/init_data"

run-server: build-server
	@echo "🎮 启动服务器..."
	@./bin/server

run: run-server

init-data: build-init
	@echo "📊 初始化游戏数据..."
	@./bin/init_data
	@echo "✅ 游戏数据初始化完成"

init: init-data

test:
	@echo "🧪 运行测试..."
	GOPROXY=$(GOPROXY) go test -v ./...

vet:
	@echo "🔍 运行 go vet..."
	GOPROXY=$(GOPROXY) go vet ./...
	@echo "✅ vet 通过"

fmt:
	@echo "🎨 格式化 Go 代码..."
	go fmt ./...
	@echo "✅ 代码格式化完成"

clean:
	@echo "🧹 清理构建产物..."
	@rm -rf bin/
	@echo "✅ 清理完成"

docker-build:
	@echo "🐳 构建 Docker 镜像..."
	$(DOCKER_COMPOSE) build
	@echo "✅ Docker 镜像构建完成"

docker-up:
	@echo "🚀 启动所有服务..."
	@if [ ! -f .env ]; then cp .env.example .env; echo "📝 使用默认 .env 配置"; fi
	$(DOCKER_COMPOSE) up -d
	@echo ""
	@echo "✅ 服务启动完成！"
	@echo "   - 游戏服务器: http://localhost:8080"
	@echo "   - 健康检查:   http://localhost:8080/health"
	@echo "   - 数据库管理: http://localhost:8081"
	@echo ""

docker-down:
	@echo "⏹️  停止所有服务..."
	$(DOCKER_COMPOSE) down
	@echo "✅ 所有服务已停止"

docker-restart: docker-down docker-up

docker-logs:
	@echo "📝 查看服务日志 (按 Ctrl+C 退出)..."
	$(DOCKER_COMPOSE) logs -f --tail=100

.PHONY: db-connect db-backup db-restore

db-connect:
	@echo "🗄️  连接到 MySQL 数据库..."
	@mysql -h 127.0.0.1 -P 3306 -u maplestory -p maplestory

db-backup:
	@echo "💾 备份数据库..."
	@mysqldump -h 127.0.0.1 -P 3306 -u maplestory -p maplestory > backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "✅ 数据库备份完成"

db-restore:
	@echo "📂 恢复数据库 - 请指定备份文件: make db-restore FILE=backup.sql"
	@if [ -z "$(FILE)" ]; then \
		echo "❌ 错误: 请指定备份文件"; \
		exit 1; \
	fi
	mysql -h 127.0.0.1 -P 3306 -u maplestory -p maplestory < $(FILE)
	@echo "✅ 数据库恢复完成"
