import type { InvitationCodeStatus } from '@/constants/enum';

export interface InvitationCodeItem {
  createTime: string;
  invitationCode: string;
  lastTime: string;
  status: InvitationCodeStatus;
  userID: string;
  usedUserID?: string;
  usedUserName?: string;
  usedUserPhoneNumber?: string;
  /** 列表/导出展示：已使用 | 未使用 */
  usageStatus?: '已使用' | '未使用';
}

export interface DefualtFriendItem {
  user: {
    nickname: string;
  };
  userID: string;
}
export interface DefualtGroupItem {
  groupID: string;
  groupName: any;
  createTime?: number;
}

export interface AssignIPItem {
  userID: string;
  ip: string;
}

export interface BrowseIPItem {
  createTime: string;
  ip: string;
  limitLogin: number;
  limitRegister: number;
}
