import { t } from "i18next";
import { MessageReceiveOptType, MessageType } from "open-im-sdk-wasm";
import {
  ConversationItem,
  GroupItem,
  GroupMemberItem,
  MessageItem,
} from "open-im-sdk-wasm/lib/types/entity";
import { create } from "zustand";

import { IMSDK } from "@/layout/MainContentWrap";
import { feedbackToast } from "@/utils/common";
import { conversationSort, isGroupSession } from "@/utils/imCommon";

import { useContactStore } from "./contact";
import { useMessageStore } from "./message";
import {
  ConversationListUpdateType,
  ConversationStore,
  RevokeMessageData,
} from "./type";
import { useUserStore } from "./user";

const CONVERSATION_SPLIT_COUNT = 500;

const calcUnreadCount = (list: ConversationItem[]) =>
  list.reduce((acc, cur) => {
    if (cur.recvMsgOpt !== MessageReceiveOptType.Nomal) return acc;
    return acc + (cur.latestMsg ? (cur.unreadCount || 0) : 0);
  }, 0);

const setWithUnread = (
  set: (fn: (state: any) => any) => void,
  updates: Record<string, any>,
) => {
  set((state: any) => {
    const next = { ...state, ...updates };
    if ("conversationList" in updates) {
      next.unReadCount = calcUnreadCount(updates.conversationList);
      window.electronAPI?.ipcInvoke("updateUnreadCount", next.unReadCount);
    }
    return next;
  });
};

export const useConversationStore = create<ConversationStore>()((set, get) => ({
  conversationList: [],
  currentConversation: undefined,
  unReadCount: 0,
  currentGroupInfo: undefined,
  currentMemberInGroup: undefined,
  quoteMessage: undefined,
  revokeMap: {} as Record<string, RevokeMessageData>,
  getConversationListByReq: async (isOffset?: boolean) => {
    let tmpConversationList = [] as ConversationItem[];
    try {
      const { data } = await IMSDK.getConversationListSplit({
        offset: isOffset ? get().conversationList.length : 0,
        count: CONVERSATION_SPLIT_COUNT,
      });
      tmpConversationList = data;

      const friendList = useContactStore.getState().friendList;
      tmpConversationList = tmpConversationList.map((conversation) => {
        if (conversation.userID && !conversation.groupID) {
          const friend = friendList.find((f) => f.userID === conversation.userID);
          if (friend?.remark) {
            return { ...conversation, showName: friend.remark };
          }
        }
        return conversation;
      });
    } catch (error) {
      feedbackToast({ error, msg: t("toast.getConversationFailed") });
      return true;
    }
    const newList = [
      ...(isOffset ? get().conversationList : []),
      ...tmpConversationList,
    ];
    setWithUnread(set, { conversationList: newList });
    return tmpConversationList.length === CONVERSATION_SPLIT_COUNT;
  },
  updateConversationList: (
    list: ConversationItem[],
    type: ConversationListUpdateType,
  ) => {
    const currentConv = get().currentConversation;
    const idx = list.findIndex(
      (c) => c.conversationID === currentConv?.conversationID,
    );
    if (idx > -1) {
      const incoming = list[idx];
      // The user is actively inside this conversation, so always keep unreadCount at 0
      // regardless of what the SDK pushes.  The 2-second throttle on
      // checkConversationState means the local value may still be > 0 briefly after
      // opening a chat, which previously allowed SDK events to bleed through.
      if (incoming.unreadCount > 0) {
        list[idx] = { ...incoming, unreadCount: 0 };
      }
      get().updateCurrentConversation(list[idx]);
    }

    if (type === "filter") {
      const newList = conversationSort([...list, ...get().conversationList]);
      setWithUnread(set, { conversationList: newList });
      return;
    }
    const chids = list.map((ch) => ch.conversationID);
    const filterArr = get().conversationList.filter(
      (tc) => !chids.includes(tc.conversationID),
    );

    setWithUnread(set, { conversationList: conversationSort([...list, ...filterArr]) });
  },
  delConversationByCID: (conversationID: string) => {
    const tmpConversationList = get().conversationList;
    const idx = tmpConversationList.findIndex(
      (cve) => cve.conversationID === conversationID,
    );
    if (idx < 0) {
      return;
    }
    tmpConversationList.splice(idx, 1);
    setWithUnread(set, { conversationList: [...tmpConversationList] });
  },
  updateCurrentConversation: (conversation?: ConversationItem, isJump?: boolean) => {
    if (!conversation) {
      set(() => ({
        currentConversation: undefined,
        quoteMessage: undefined,
        currentGroupInfo: undefined,
        currentMemberInGroup: undefined,
      }));
      return;
    }
    const prevConversation = get().currentConversation;

    const toggleNewConversation =
      conversation.conversationID !== prevConversation?.conversationID;
    if (toggleNewConversation && isGroupSession(conversation.conversationType)) {
      get().getCurrentGroupInfoByReq(conversation.groupID);
      get().getCurrentMemberInGroupByReq(conversation.groupID);
    }
    if (toggleNewConversation && !isJump) {
      useMessageStore.getState().updateJumpClientMsgID();
    }
    set(() => ({ currentConversation: { ...conversation } }));
  },
  getUnReadCountByReq: async () => {
    const count = calcUnreadCount(get().conversationList);
    set(() => ({ unReadCount: count }));
    return count;
  },
  updateUnReadCount: (count: number) => {
    set(() => ({ unReadCount: count }));
  },
  getCurrentGroupInfoByReq: async (groupID: string) => {
    let groupInfo: GroupItem;
    try {
      const { data } = await IMSDK.getSpecifiedGroupsInfo([groupID]);
      groupInfo = data[0];
    } catch (error) {
      feedbackToast({ error, msg: t("toast.getGroupInfoFailed") });
      return;
    }
    set(() => ({ currentGroupInfo: { ...groupInfo } }));
  },
  updateCurrentGroupInfo: (groupInfo: GroupItem) => {
    set(() => ({ currentGroupInfo: { ...groupInfo } }));
  },
  getCurrentMemberInGroupByReq: async (groupID: string) => {
    let memberInfo: GroupMemberItem;
    const selfID = useUserStore.getState().selfInfo.userID;
    try {
      const { data } = await IMSDK.getSpecifiedGroupMembersInfo({
        groupID,
        userIDList: [selfID],
      });
      memberInfo = data[0];
    } catch (error) {
      feedbackToast({ error, msg: t("toast.getGroupMemberFailed") });
      return;
    }
    set(() => ({ currentMemberInGroup: { ...memberInfo } }));
  },
  tryUpdateCurrentMemberInGroup: (member: GroupMemberItem) => {
    const currentMemberInGroup = get().currentMemberInGroup;
    if (
      member.groupID === currentMemberInGroup?.groupID &&
      member.userID === currentMemberInGroup?.userID
    ) {
      set(() => ({ currentMemberInGroup: { ...member } }));
    }
  },
  updateQuoteMessage: (message?: MessageItem) => {
    set(() => ({ quoteMessage: message }));
  },
  addRevokedMessage: (message: MessageItem, quoteMessage?: MessageItem) => {
    set((state) => ({
      revokeMap: {
        ...state.revokeMap,
        [message.clientMsgID]: {
          text: getMessageText(message),
          quoteMessage,
        },
      },
    }));
  },
  clearConversationStore: () => {
    set(() => ({
      conversationList: [],
      currentConversation: undefined,
      unReadCount: 0,
      currentGroupInfo: undefined,
      currentMemberInGroup: undefined,
      quoteMessage: undefined,
    }));
  },
}));

const getMessageText = (message: MessageItem) => {
  if (message.contentType === MessageType.AtTextMessage) {
    return message.atTextElem.text;
  }
  if (message.contentType === MessageType.QuoteMessage) {
    return message.quoteElem.text;
  }
  return message.textElem.content;
};
