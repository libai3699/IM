import { ACCOUNT_URL } from '@/config';
import { request } from '@umijs/max';

export async function getIPBlacklist(params: {
  keyword?: string;
  pagination: { pageNumber: number; showNumber: number };
}) {
  return request<{ data: any }>('/forbidden/ip/search', {
    method: 'POST',
    data: params,
    headers: { isAccount: true },
    baseURL: ACCOUNT_URL,
  });
}

export async function addIPBlacklist(params: {
  ip: string;
  limitRegister: boolean;
  limitLogin: boolean;
}) {
  return request<{ data: any }>('/forbidden/ip/add', {
    method: 'POST',
    data: { forbiddens: [params] },
    headers: { isAccount: true },
    baseURL: ACCOUNT_URL,
  });
}

export async function deleteIPBlacklist(ips: string[]) {
  return request<{ data: any }>('/forbidden/ip/del', {
    method: 'POST',
    data: { ips },
    headers: { isAccount: true },
    baseURL: ACCOUNT_URL,
  });
}

// new
export async function getClientConfig() {
  return request<{
    data: any;
  }>('/client_config/get', {
    method: 'POST',
    data: {},
    headers: {
      isAccount: true,
    },
    baseURL: ACCOUNT_URL,
  });
}

// new
export async function setClientConfig(data: any) {
  return request<{
    data: any;
  }>('/client_config/set', {
    method: 'POST',
    data: {
      config: {
        ...data,
      },
    },
    headers: {
      isAccount: true,
    },
    baseURL: ACCOUNT_URL,
  });
}

// new
export async function getApplet(data: any) {
  return request<{
    data: any;
  }>('/applet/search', {
    method: 'POST',
    data,
    headers: {
      isAccount: true,
    },
    baseURL: ACCOUNT_URL,
  });
}

// new
export async function crteateApplet(data: any) {
  return request<{
    data: any;
  }>('/applet/add', {
    method: 'POST',
    data,
    headers: {
      isAccount: true,
    },
    baseURL: ACCOUNT_URL,
  });
}
