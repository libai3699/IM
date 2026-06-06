<!-- 分析参考: package.json, src/config/index.ts, src/utils/request.ts, src/store/index.ts, src/routes/index.tsx, src/api/login.ts -->

# ichat PC 客户端 — 子项目工程规范

## 技术栈

| 组件 | 版本 |
|---|---|
| React | ^18.2.0 |
| TypeScript | ^4.9.5 |
| Vite | ^4.1.4 |
| Electron | ^22.3.27 |
| Ant Design | ^5.6.0 |
| Zustand | ^4.3.3 |
| React Router DOM | ^6.11.1 |
| React Query | ^3.39.3 |
| Axios | ^1.4.0 |
| TailwindCSS | ^3.2.7 |
| i18next | ^22.5.0 |
| open-im-sdk-wasm | 3.5.1-alpha.3 |

---

## 真实目录结构

```
web/
├── src/
│   ├── api/                        # API 请求封装
│   │   ├── login.ts                # 登录/注册/用户信息 API
│   │   ├── imApi.ts                # IM 相关 API
│   │   ├── moments.ts              # 朋友圈 API
│   │   ├── newMoments.ts           # 新版朋友圈 API
│   │   ├── errorHandle.ts          # 错误处理
│   │   └── typings.d.ts            # API 类型定义
│   ├── assets/                     # 静态资源
│   │   ├── audio/                  # 音频文件
│   │   ├── avatar/                 # 默认头像
│   │   └── images/                 # 图片资源（按功能分目录）
│   ├── components/                 # 公共组件
│   │   ├── OIMAvatar/              # 头像组件
│   │   ├── CacheImage/             # 缓存图片
│   │   ├── DraggableModalWrap/     # 可拖动弹窗
│   │   ├── EditableContent/        # 可编辑内容
│   │   ├── FlexibleSider/          # 可调整侧边栏
│   │   ├── VideoPlayer/            # 视频播放器
│   │   └── ...
│   ├── config/
│   │   └── index.ts                # 全局配置（API URL / WS URL / 版本号）
│   ├── constants/                  # 常量定义
│   ├── hooks/                      # 自定义 Hooks
│   ├── i18n/                       # 国际化
│   │   └── resources/              # 语言文件
│   ├── layout/                     # 布局组件
│   │   ├── LeftNavBar/             # 左侧导航栏
│   │   └── TopSearchBar/           # 顶部搜索栏
│   ├── pages/                      # 页面
│   │   ├── chat/                   # 聊天页面
│   │   │   ├── ConversationSider/  # 会话列表侧边栏
│   │   │   └── queryChat/          # 聊天窗口
│   │   ├── contact/                # 联系人页面
│   │   ├── login/                  # 登录页面
│   │   ├── moments/                # 朋友圈页面
│   │   ├── common/                 # 公共弹窗页面
│   │   │   ├── ChooseModal/        # 选择弹窗
│   │   │   ├── UserCardModal/      # 名片弹窗
│   │   │   ├── GroupCardModal/     # 群名片弹窗
│   │   │   ├── RtcCallModal/       # 音视频通话
│   │   │   └── MomentsModal/       # 朋友圈弹窗
│   │   └── third/                  # 独立窗口页面
│   │       ├── personalSettings/   # 个人设置
│   │       ├── blackList/          # 黑名单
│   │       └── changePassword/     # 修改密码
│   ├── routes/                     # 路由配置
│   │   └── index.tsx               # 路由定义（createHashRouter）
│   ├── store/                      # 状态管理（Zustand）
│   │   ├── index.ts                # Store 导出
│   │   ├── user.ts                 # 用户状态
│   │   ├── contact.ts              # 联系人状态
│   │   ├── conversation.ts         # 会话状态
│   │   ├── message.ts              # 消息状态
│   │   └── type.d.ts               # Store 类型定义
│   ├── styles/                     # 全局样式
│   ├── svg/                        # SVG 图标组件
│   └── utils/                      # 工具函数
│       └── request.ts              # Axios 封装
├── electron/                       # Electron 主进程
├── dist-electron/                  # Electron 构建输出
└── package/                        # 应用打包输出
```

---

## 核心文件位置

| 用途 | 真实路径 |
|---|---|
| 全局配置（URL/版本） | `src/config/index.ts` |
| Axios 请求封装 | `src/utils/request.ts` |
| 路由配置 | `src/routes/index.tsx` |
| Store 入口 | `src/store/index.ts` |
| API 类型定义 | `src/api/typings.d.ts` |
| 错误处理 | `src/api/errorHandle.ts` |

---

## 接口请求规范

### request 封装（`src/utils/request.ts`）

```typescript
import axios from "axios";
const createAxiosInstance = (baseURL: string, imToken = true) => {
  const serves = axios.create({ baseURL, timeout: 25000 });
  // 请求拦截器：自动附加 token 和 operationID
  serves.interceptors.request.use(async (config) => {
    const token = imToken ? await getIMToken() : await getChatToken();
    config.headers.token = config.headers.token ?? token;
    config.headers.operationID = uuidv4();
    return config;
  });
  // 响应拦截器：errCode !== 0 时 reject
  serves.interceptors.response.use((res) => {
    if (res.data.errCode !== 0) return Promise.reject(res.data);
    return res.data;
  });
  return serves;
};
```

### API 调用示例（`src/api/login.ts`）

```typescript
import createAxiosInstance from "@/utils/request";
import { getChatUrl } from "@/config";

const request = createAxiosInstance(getChatUrl());

// 使用 react-query 的 useMutation
export const useLogin = () => {
  return useMutation(
    (params: API.Login.LoginParams) =>
      request.post<{ chatToken: string; imToken: string; userID: string }>(
        "/account/login",
        { ...params, platform, areaCode: getAreaCode(params.areaCode) },
        { headers: { operationID: uuidv4() } },
      ),
    { onError: errorHandle },
  );
};

// 直接调用（需手动传 token）
export const getBusinessUserInfo = async (userIDs: string[]) => {
  const token = (await getChatToken()) as string;
  return request.post<{ users: BusinessUserInfo[] }>(
    "/user/find/full",
    { userIDs },
    { headers: { operationID: uuidv4(), token } },
  );
};
```

---

## 环境变量 / 配置规范

配置集中在 `src/config/index.ts`：

```typescript
export const WS_URL = "wss://open.qweenew.com/msg_gateway";
export const API_URL = "https://open.qweenew.com/api";
export const CHAT_URL = "https://open.qweenew.com/chat";

// 支持 localStorage 覆盖
export const getWsUrl = () => localStorage.getItem("wsUrl") || WS_URL;
export const getApiUrl = () => localStorage.getItem("apiUrl") || API_URL;
export const getChatUrl = () => localStorage.getItem("chatUrl") || CHAT_URL;

export const APP_VERSION = "ichat v3.5.1-alpha.3";
```

---

## 状态管理规范（Zustand）

使用 `zustand` 的 `create` 函数创建 Store：

```typescript
import { create } from "zustand";

export const useUserStore = create<UserStore>()((set, get) => ({
  selfInfo: {} as BusinessUserInfo,
  appConfig: {} as AppConfig,
  getSelfInfoByReq: () => {
    IMSDK.getSelfUserInfo().then(({ data }) => {
      set(() => ({ selfInfo: data as unknown as BusinessUserInfo }));
    });
  },
  updateSelfInfo: (info: Partial<BusinessUserInfo>) => {
    set((state) => ({ selfInfo: { ...state.selfInfo, ...info } }));
  },
}));
```

Store 模块：`useUserStore`、`useContactStore`、`useConversationStore`、`useMessageStore`

---

## 组件规范

- 组件使用 **函数组件 + TypeScript**
- 每个组件一个目录，包含 `index.tsx` + 可选样式文件
- 使用 `@/` 路径别名引用 src 下的模块
- 样式方案：TailwindCSS + SCSS modules
- UI 库：Ant Design 5.x

---

## 路由规范

使用 `react-router-dom` v6 的 `createHashRouter`，支持懒加载：

```typescript
const router = createHashRouter([
  {
    path: "/",
    element: <MainContentWrap />,
    children: [
      { path: "/chat", async lazy() { const { Chat } = await import("@/pages/chat"); return { Component: Chat }; } },
      { path: "contact", async lazy() { ... } },
    ],
  },
  { path: "login", async lazy() { ... } },
  { path: "third", children: [...thirdRoutes] },
]);
```

---

## 实际命令

```bash
# 开发模式
npm run dev

# 构建（TypeScript 编译 + Vite 构建 + Electron 打包）
npm run build

# 仅 Windows 构建
npm run build:win

# 仅 Mac 构建
npm run build:mac

# 代码格式化
npm run format

# ESLint 检查
npm run lint
npm run lint:fix
```
