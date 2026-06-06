# Protocol Buffers 生成环境安装

## 环境版本
- Go: go1.21.5
- protoc: libprotoc 3.21.12
- protoc-gen-go: v1.31.0
- protoc-gen-go-grpc: v1.3.0

## 安装命令

### 1. 安装 Go
```bash
GO_VERSION="1.21.5"
wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

### 2. 安装 protoc (Linux)
```bash
PB_VERSION="25.1"
wget https://github.com/protocolbuffers/protobuf/releases/download/v${PB_VERSION}/protoc-${PB_VERSION}-linux-x86_64.zip
sudo unzip protoc-${PB_VERSION}-linux-x86_64.zip -d /usr/local
rm protoc-${PB_VERSION}-linux-x86_64.zip
sudo chmod +x /usr/local/bin/protoc
```

### 3. 安装 protoc-gen-go
```bash
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.31.0
```

### 4. 安装 protoc-gen-go-grpc
```bash
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0
```

### 5. 配置 PATH
```bash
export PATH="$PATH:$(go env GOPATH)/bin"
source ~/.bashrc
```

### 6. 验证安装
```bash
go version
protoc --version
protoc-gen-go --version
protoc-gen-go-grpc --version
```

## 生成代码

```bash
cd /path/to/chart/pkg/proto
./gen.sh
```