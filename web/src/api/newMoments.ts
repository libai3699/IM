/**
 * 新版朋友圈 API（对应 chart/internal/api/moment.go 中的路由）
 * 基础路由前缀：/moment
 */
import { useInfiniteQuery, useMutation, useQueryClient } from "react-query";
import { getChatUrl } from "@/config";
import createAxiosInstance from "@/utils/request";

const request = createAxiosInstance(getChatUrl(), false);

// --------- 类型 ---------

export interface MomentMeta {
  original: string;
  thumb: string;
  width: number;
  height: number;
}

export interface MomentContent {
  text: string;
  type: number; // 0=文字 1=图片 2=视频
  metas: MomentMeta[];
}

export interface MomentComment {
  commentID: string;
  momentID: string;
  userID: string;
  nickname: string;
  faceURL: string;
  replyToID: string;
  replyUserID: string;
  replyNickname: string;
  content: string;
  visibility: number; // 1=public 2=self
  isOfficial: boolean;
  createTime: number;
}

export interface MomentInfo {
  momentID: string;
  userID: string;
  nickname: string;
  faceURL: string;
  content: MomentContent;
  momentType: number; // 1=normal 2=top
  status: number; // 0=pending 1=approved 2=rejected
  isOfficial: boolean;
  likeCount: number;
  dislikeCount: number;
  commentCount: number;
  myVote: number; // 0=none 1=like 2=dislike
  comments: MomentComment[];
  createTime: number;
}

// --------- API ---------

/** 发布动态 */
export const useCreateMoment = () => {
  const queryClient = useQueryClient();
  return useMutation(
    (params: { content: MomentContent }) =>
      request.post<{ moment: MomentInfo }>("/moment/create", params),
    { onSuccess: () => queryClient.invalidateQueries("momentFeed") },
  );
};

/** 删除动态 */
export const useDeleteMoment = (queryKey = "momentFeed") => {
  const queryClient = useQueryClient();
  return useMutation(
    (momentID: string) => request.post("/moment/del", { momentID }),
    { onSuccess: () => queryClient.invalidateQueries(queryKey) },
  );
};

/** 获取动态列表（无限滚动） */
export const useMomentFeed = (enabled = true) => {
  return useInfiniteQuery<MomentInfo[]>(
    "momentFeed",
    async ({ pageParam = 1 }) => {
      const { data } = await request.post<{ moments: MomentInfo[]; total: number }>(
        "/moment/list",
        { pagination: { pageNumber: pageParam, showNumber: 20 } },
      );
      return data.moments ?? [];
    },
    {
      getNextPageParam: (lastPage, pages) =>
        lastPage.length < 20 ? undefined : pages.length + 1,
      enabled,
    },
  );
};

/** 获取我发布的动态（无限滚动） */
export const useMyMoments = (enabled = true) => {
  return useInfiniteQuery<MomentInfo[]>(
    "myMoments",
    async ({ pageParam = 1 }) => {
      const { data } = await request.post<{ moments: MomentInfo[]; total: number }>(
        "/moment/mine",
        { pagination: { pageNumber: pageParam, showNumber: 20 } },
      );
      return data.moments ?? [];
    },
    {
      getNextPageParam: (lastPage, pages) =>
        lastPage.length < 20 ? undefined : pages.length + 1,
      enabled,
    },
  );
};

/** 获取置顶动态 */
export const useTopMoment = () => {
  return useInfiniteQuery<MomentInfo[]>(
    "topMoment",
    async () => {
      const { data } = await request.post<{ moments: MomentInfo[] }>("/moment/list", {
        pagination: { pageNumber: 1, showNumber: 1 },
      });
      return data.moments ?? [];
    },
    { getNextPageParam: () => undefined },
  );
};

/** 投票（点赞/点踩） */
export const useVoteMoment = () => {
  const queryClient = useQueryClient();
  return useMutation(
    (params: { momentID: string; voteType: number }) =>
      request.post("/moment/vote", params),
    { onSuccess: () => queryClient.invalidateQueries("momentFeed") },
  );
};

/** 发表评论 */
export const useCommentMoment = () => {
  const queryClient = useQueryClient();
  return useMutation(
    (params: { momentID: string; content: string; replyToID?: string }) =>
      request.post("/moment/comment/add", params),
    { onSuccess: () => queryClient.invalidateQueries("momentFeed") },
  );
};

/** 删除评论 */
export const useDeleteComment = () => {
  const queryClient = useQueryClient();
  return useMutation(
    (params: { momentID: string; commentID: string }) =>
      request.post("/moment/comment/del", params),
    { onSuccess: () => queryClient.invalidateQueries("momentFeed") },
  );
};
