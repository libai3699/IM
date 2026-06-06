FROM golang:1.21-alpine AS builder

WORKDIR /build

# 安装必要的工具
RUN apk add --no-cache git

# 复制 go.mod 和 go.sum
COPY go.mod go.sum ./
RUN go mod download

# 复制源代码
COPY . .

# 编译
RUN CGO_ENABLED=0 GOOS=linux go build -o route-service .

# 运行阶段
FROM alpine:latest

WORKDIR /app

# 安装 ca-certificates 和时区数据
RUN apk --no-cache add ca-certificates tzdata

# 设置时区
ENV TZ=Asia/Shanghai

# 从构建阶段复制二进制文件和配置文件
COPY --from=builder /build/route-service .
COPY --from=builder /build/config.yaml .

# 创建日志目录
RUN mkdir -p /app/logs

# 暴露端口
EXPOSE 10010

# 运行
CMD ["./route-service"]
