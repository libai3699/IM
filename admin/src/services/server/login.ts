import { ACCOUNT_URL } from '@/config';
import { request } from '@umijs/max';

export async function adminLogin(account: string, password: string, googleAuthCode?: string) {
  return request<{
    data: any;
  }>('account/login', {
    method: 'POST',
    data: {
      account,
      password,
      googleAuthCode,
    },
    baseURL: ACCOUNT_URL,
  });
}

export async function adminInfo() {
  return request('account/info', {
    method: 'POST',
    data: {},
    headers: {
      isAccount: true,
    },
    baseURL: ACCOUNT_URL,
  });
}
