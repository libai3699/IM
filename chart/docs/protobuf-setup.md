# Protobuf 代码生成工具安装指南

本文档说明如何在服务器上安装和配置 protobuf 代码生成工具。

## 前置要求

- **Go 1.22.9**
- **protoc 3.x**（Protocol Buffers 编译器）

## 安装 Go 1.22.9

```bash
# 下载 Go 1.22.9
cd /tmp
wget https://go.dev/dl/go1.22.9.linux-amd64.tar.gz

# 删除旧版本（如果存在）
sudo rm -rf /usr/local/go

# 解压安装
sudo tar -C /usr/local -xzf go1.22.9.linux-amd64.tar.gz

# 配置环境变量
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
source ~/.bashrc

# 验证安装
go version
# 应该显示: go version go1.22.9 linux/amd64
```

## 安装步骤

### 1. 检查 protoc 版本

```bash
protoc --version
# 应该显示: libprotoc 3.x.x
```

### 2. 卸载旧版本的 protoc-gen-go

```bash
rm -f /root/go/bin/protoc-gen-go
rm -f /root/go/bin/protoc-gen-go-grpc
```

### 3. 安装新版本工具

```bash
# 安装 protoc-gen-go（支持 --go_opt 参数）
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28.1

# 安装 protoc-gen-go-grpc（新版本 gRPC 生成是分离的）
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2.0
```

### 4. 验证安装

```bash
# 检查安装的文件
ls -lh /root/go/bin/protoc-gen-go*

# 应该看到两个文件：
# /root/go/bin/protoc-gen-go
# /root/go/bin/protoc-gen-go-grpc
```

### 5. 配置 PATH 环境变量

```bash
# 临时添加到 PATH
export PATH=$PATH:/root/go/bin

# 永久添加到 PATH（添加到 ~/.bashrc）
echo 'export PATH=$PATH:/root/go/bin' >> ~/.bashrc
source ~/.bashrc
```

### 6. 验证工具可用

```bash
# 检查 protoc-gen-go 是否在 PATH 中
which protoc-gen-go
which protoc-gen-go-grpc
```

## 生成 Protobuf 代码

### 使用 gen.sh 脚本

```bash
cd /wwwroot/openIm/chat/chat-enterprise/pkg/proto

# 运行生成脚本
bash gen.sh

# 检查生成的文件
ls -lh admin/*.pb.go
ls -lh chat/*.pb.go
ls -lh common/*.pb.go
ls -lh office/*.pb.go
```

### 手动生成单个文件

```bash
cd /wwwroot/openIm/chat/chat-enterprise/pkg/proto

# 生成 admin proto
protoc --go_out=. --go_opt=module=github.com/OpenIMSDK/chat/pkg/proto \
       --go-grpc_out=. --go-grpc_opt=module=github.com/OpenIMSDK/chat/pkg/proto \
       admin/admin.proto
```

## 生成的文件说明

新版本 protoc-gen-go 会为每个 .proto 文件生成两个文件：

- `xxx.pb.go` - 消息定义（message、enum 等）
- `xxx_grpc.pb.go` - gRPC 服务代码（service、client、server 等）

## 常见问题

### 问题 1: plugins are not supported

**错误信息：**
```
--go_out: protoc-gen-go: plugins are not supported
```

**原因：** 使用了新版本的 protoc-gen-go，但语法还是旧版本的。

**解决方案：** 按照本文档安装新版本工具，并使用新语法（已在 gen.sh 中更新）。

### 问题 2: protoc-gen-go-grpc not found

**错误信息：**
```
protoc-gen-go-grpc: program not found or is not executable
```

**解决方案：**
```bash
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2.0
export PATH=$PATH:/root/go/bin
```

### 问题 3: 文件没有生成

**检查步骤：**
1. 确认 protoc-gen-go 和 protoc-gen-go-grpc 在 PATH 中
2. 检查 .proto 文件语法是否正确
3. 查看是否有错误输出

## 版本信息

- **protoc**: 3.21.12
- **protoc-gen-go**: v1.28.1
- **protoc-gen-go-grpc**: v1.2.0

## 参考链接

- [Protocol Buffers 官方文档](https://protobuf.dev/)
- [gRPC Go 快速开始](https://grpc.io/docs/languages/go/quickstart/)
- [protoc-gen-go 仓库](https://github.com/protocolbuffers/protobuf-go)
