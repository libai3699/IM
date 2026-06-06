// WS 10001 API 10002 CHAT 10008 CONFIG 10009

// export const WS_URL = "ws://admin.skjdffsdfs.top/msg_gateway_enterprise";
// export const API_URL = "http://admin.skjdffsdfs.top/api_enterprise";
// export const CHAT_URL = "http://admin.skjdffsdfs.top/chat_enterprise";

export const WS_URL = "wss://open.qweenew.com/msg_gateway";
export const API_URL = "https://open.qweenew.com/api";
export const CHAT_URL = "https://open.qweenew.com/chat";
// export const CHAT_URL = "https://open.ijqtx.com/chat";

export const getWsUrl = () => localStorage.getItem("wsUrl") || WS_URL;
export const getApiUrl = () => localStorage.getItem("apiUrl") || API_URL;
export const getChatUrl = () => localStorage.getItem("chatUrl") || CHAT_URL;

export const APP_VERSION = "ichat v3.5.1-alpha.3";
export const APP_VERSION_CODE = 350;
export const SDK_VERSION = "SDK v3.5.1-alpha.3-e-v1.1.4";
export const CHECK_UPDATE_PREFIX =
  "https://app-1302656840.cos.ap-nanjing.myqcloud.com/";

export const isSaveLog = false; // 关闭 SDK 日志
