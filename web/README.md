## Getting Started

### Update Config

- For web
  > src->config
  > modify it to your own ip, but do not need to modify the port

```bash
export const WS_URL = "ws://125.124.195.201:10001";
export const API_URL = "http://125.124.195.201:10002";
export const CHAT_URL = "http://125.124.195.201:10008";
```

### Develop

- Get dependencies from npm

  ```bash
  npm install
  ```

- Run and preview at local (web & electron)

  ```
  npm run dev

  ```

### 构建与部署

#### 1. 打包 Web 端 (纯网页)

如果你只需要部署到 Web 服务器（如 Nginx），请运行：

```bash
npx vite build
```

打包结果会在 `dist/` 目录下。

#### 2. 打包桌面端 (Electron)

如果你需要打包成桌面客户端应用：

**Windows (.exe)**:
```bash
# 方法 1 (一键打包)
npm run build:win

# 方法 2 (分步打包，推荐用于排查问题)
npx vite build
npx electron-builder --win --x64
```
输出目录: `package/` (例如: `ichat Setup X.X.X.exe`)

**Mac (.dmg)**:
```bash
# Intel 芯片 (x64)
npm run build:mac

# Apple Silicon 芯片 (M1/M2 - arm64)
npm run build:mac-arm
```

**Linux (.deb)**:
```bash
npm run build:linux
```

## Getting Help

The best way to interact with our team is through GitHub.You can open an issue with this.You can also find some Doc in [Our Developer Guide](https://doc.rentsoft.cn/).

