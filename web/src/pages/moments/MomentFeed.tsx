import {
  MomentComment,
  MomentInfo,
  useCommentMoment,
  useDeleteComment,
  useDeleteMoment,
  useMomentFeed,
  useVoteMoment,
} from "@/api/newMoments";
import { Avatar, Button, Empty, Image, Input, Spin, Tag, Tooltip } from "antd";
import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";
import "dayjs/locale/zh-cn";
import React, { useCallback, useEffect, useRef, useState } from "react";
import styles from "./MomentFeed.module.scss";

dayjs.extend(relativeTime);
dayjs.locale("zh-cn");

// -------------------- Sub-components --------------------

const MediaGrid = ({ metas }: { metas: MomentInfo["content"]["metas"] }) => {
  if (!metas || metas.length === 0) return null;
  const count = metas.length;
  return (
    <Image.PreviewGroup>
      <div
        className={styles.mediaGrid}
        data-count={Math.min(count, 9)}
      >
        {metas.slice(0, 9).map((m, i) => (
          <Image
            key={i}
            src={m.thumb || m.original}
            preview={{ src: m.original }}
            className={styles.mediaItem}
          />
        ))}
      </div>
    </Image.PreviewGroup>
  );
};

const CommentItem = ({
  comment,
  myUserID,
  onDelete,
  onReply,
}: {
  comment: MomentComment;
  myUserID: string;
  onDelete: (id: string) => void;
  onReply: (comment: MomentComment) => void;
}) => (
  <div className={styles.commentItem}>
    <span className={styles.commentAuthor}>
      {comment.isOfficial && <Tag color="blue" style={{ fontSize: 10, padding: "0 4px" }}>官方</Tag>}
      {comment.nickname || comment.userID}：
    </span>
    {comment.replyNickname && (
      <span className={styles.replyTarget}>回复 {comment.replyNickname}：</span>
    )}
    <span className={styles.commentContent}>{comment.content}</span>
    <span className={styles.commentActions}>
      <span
        className={styles.commentAction}
        onClick={() => onReply(comment)}
      >
        回复
      </span>
      {comment.userID === myUserID && (
        <span
          className={`${styles.commentAction} ${styles.danger}`}
          onClick={() => onDelete(comment.commentID)}
        >
          删除
        </span>
      )}
    </span>
  </div>
);

const VoteBar = ({
  moment,
  onVote,
}: {
  moment: MomentInfo;
  onVote: (momentID: string, voteType: number) => void;
}) => {
  const total = moment.likeCount + moment.dislikeCount;
  const likePercent = total > 0 ? Math.round((moment.likeCount / total) * 100) : 50;
  return (
    <div className={styles.voteBar}>
      <button
        className={`${styles.voteBtn} ${moment.myVote === 1 ? styles.voted : ""}`}
        onClick={() => onVote(moment.momentID, 1)}
      >
        👍 {moment.likeCount}
      </button>
      <div className={styles.voteProgress}>
        <div className={styles.voteProgressFill} style={{ width: `${likePercent}%` }} />
      </div>
      <button
        className={`${styles.voteBtn} ${styles.dislike} ${moment.myVote === 2 ? styles.voted : ""}`}
        onClick={() => onVote(moment.momentID, 2)}
      >
        👎 {moment.dislikeCount}
      </button>
    </div>
  );
};

// -------------------- Main card --------------------

const MomentCard = ({
  moment,
  myUserID,
  isPinned,
}: {
  moment: MomentInfo;
  myUserID: string;
  isPinned?: boolean;
}) => {
  const [showComments, setShowComments] = useState(false);
  const [replyTo, setReplyTo] = useState<MomentComment | null>(null);
  const [commentText, setCommentText] = useState("");
  const inputRef = useRef<any>(null);

  const voteMutation = useVoteMoment();
  const commentMutation = useCommentMoment();
  const deleteCommentMutation = useDeleteComment();
  const deleteMomentMutation = useDeleteMoment();

  const handleVote = useCallback(
    (momentID: string, voteType: number) => {
      voteMutation.mutate({ momentID, voteType });
    },
    [voteMutation],
  );

  const handleReply = (comment: MomentComment) => {
    setReplyTo(comment);
    setShowComments(true);
    setTimeout(() => inputRef.current?.focus(), 100);
  };

  const handleSubmitComment = () => {
    if (!commentText.trim()) return;
    commentMutation.mutate(
      {
        momentID: moment.momentID,
        content: commentText.trim(),
        replyToID: replyTo?.commentID,
      },
      {
        onSuccess: () => {
          setCommentText("");
          setReplyTo(null);
        },
      },
    );
  };

  const handleDeleteComment = (commentID: string) => {
    deleteCommentMutation.mutate({ momentID: moment.momentID, commentID });
  };

  const handleDeleteMoment = () => {
    deleteMomentMutation.mutate(moment.momentID);
  };

  return (
    <div className={`${styles.card} ${isPinned ? styles.pinnedCard : ""}`}>
      {isPinned && <div className={styles.pinnedBadge}>📌 置顶</div>}

      {/* Header */}
      <div className={styles.cardHeader}>
        <Avatar src={moment.faceURL} size={40}>
          {moment.nickname?.[0] ?? "U"}
        </Avatar>
        <div className={styles.authorInfo}>
          <div className={styles.authorName}>
            {moment.nickname || moment.userID}
            {moment.isOfficial && (
              <Tag color="blue" style={{ marginLeft: 6, fontSize: 11 }}>
                官方
              </Tag>
            )}
          </div>
          <div className={styles.publishTime}>
            <Tooltip title={dayjs(moment.createTime).format("YYYY-MM-DD HH:mm:ss")}>
              {dayjs(moment.createTime).fromNow()}
            </Tooltip>
          </div>
        </div>
        {moment.userID === myUserID && (
          <button className={styles.deleteBtn} onClick={handleDeleteMoment}>
            ✕
          </button>
        )}
      </div>

      {/* Content */}
      <div className={styles.cardBody}>
        {moment.content?.text && (
          <p className={styles.contentText}>{moment.content.text}</p>
        )}
        <MediaGrid metas={moment.content?.metas ?? []} />
      </div>

      {/* Vote bar (for pinned moments) */}
      {moment.momentType === 2 && (
        <VoteBar moment={moment} onVote={handleVote} />
      )}

      {/* Footer actions */}
      <div className={styles.cardFooter}>
        <button
          className={`${styles.actionBtn} ${moment.myVote === 1 ? styles.active : ""}`}
          onClick={() => handleVote(moment.momentID, 1)}
        >
          👍 {moment.likeCount > 0 ? moment.likeCount : ""}
        </button>
        <button
          className={styles.actionBtn}
          onClick={() => {
            setShowComments((v) => !v);
            setReplyTo(null);
          }}
        >
          💬 {moment.commentCount > 0 ? moment.commentCount : "评论"}
        </button>
      </div>

      {/* Comments */}
      {showComments && (
        <div className={styles.commentsSection}>
          {(moment.comments ?? []).map((c) => (
            <CommentItem
              key={c.commentID}
              comment={c}
              myUserID={myUserID}
              onDelete={handleDeleteComment}
              onReply={handleReply}
            />
          ))}
          {(moment.comments ?? []).length === 0 && (
            <span className={styles.noComment}>暂无评论，快来抢沙发</span>
          )}
          <div className={styles.commentInputWrap}>
            {replyTo && (
              <div className={styles.replyHint}>
                回复 {replyTo.nickname || replyTo.userID}
                <span
                  className={styles.cancelReply}
                  onClick={() => setReplyTo(null)}
                >
                  取消
                </span>
              </div>
            )}
            <Input.TextArea
              ref={inputRef}
              rows={2}
              placeholder={replyTo ? `回复 ${replyTo.nickname || replyTo.userID}…` : "写评论…"}
              value={commentText}
              onChange={(e) => setCommentText(e.target.value)}
              onPressEnter={(e) => {
                if (!e.shiftKey) {
                  e.preventDefault();
                  handleSubmitComment();
                }
              }}
              style={{ borderRadius: 8, resize: "none" }}
            />
            <Button
              type="primary"
              size="small"
              loading={commentMutation.isLoading}
              onClick={handleSubmitComment}
              style={{ marginTop: 6, alignSelf: "flex-end" }}
            >
              发送
            </Button>
          </div>
        </div>
      )}
    </div>
  );
};

// -------------------- Feed page --------------------

interface MomentFeedProps {
  myUserID: string;
}

const MomentFeed: React.FC<MomentFeedProps> = ({ myUserID }) => {
  const { data, isLoading, isFetchingNextPage, hasNextPage, fetchNextPage } = useMomentFeed();
  const loaderRef = useRef<HTMLDivElement>(null);

  // Intersection observer for infinite scroll
  useEffect(() => {
    if (!loaderRef.current) return;
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && hasNextPage && !isFetchingNextPage) {
          fetchNextPage();
        }
      },
      { threshold: 0.1 },
    );
    observer.observe(loaderRef.current);
    return () => observer.disconnect();
  }, [hasNextPage, isFetchingNextPage, fetchNextPage]);

  const allMoments = data?.pages.flat() ?? [];

  if (isLoading) {
    return (
      <div className={styles.center}>
        <Spin size="large" />
      </div>
    );
  }

  if (allMoments.length === 0) {
    return (
      <div className={styles.center}>
        <Empty description="暂无动态，快去发布吧！" />
      </div>
    );
  }

  const pinnedMoment = allMoments.find((m) => m.momentType === 2);
  const normalMoments = allMoments.filter((m) => m.momentType !== 2);

  return (
    <div className={styles.feedContainer}>
      {pinnedMoment && (
        <MomentCard
          key={pinnedMoment.momentID}
          moment={pinnedMoment}
          myUserID={myUserID}
          isPinned
        />
      )}
      {normalMoments.map((m) => (
        <MomentCard key={m.momentID} moment={m} myUserID={myUserID} />
      ))}
      <div ref={loaderRef} className={styles.loaderAnchor}>
        {isFetchingNextPage && <Spin size="small" />}
        {!hasNextPage && allMoments.length > 0 && (
          <span className={styles.noMore}>— 已经到底了 —</span>
        )}
      </div>
    </div>
  );
};

export default MomentFeed;
