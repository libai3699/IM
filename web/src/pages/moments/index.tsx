/**
 * 朋友圈主入口
 */
import { PlusOutlined } from "@ant-design/icons";
import { Button, Tabs } from "antd";
import React, { useState } from "react";
import MomentFeed from "./MomentFeed";
import PublishMoment from "./PublishMoment";
import styles from "./index.module.scss";

// 从 store 获取当前用户ID，此处直接从 localStorage 兜底
const getMyUserID = (): string => {
  try {
    const raw = localStorage.getItem("userInfo");
    if (raw) return JSON.parse(raw)?.userID ?? "";
  } catch {}
  return "";
};

export const Moments: React.FC = () => {
  const [publishOpen, setPublishOpen] = useState(false);
  const myUserID = getMyUserID();

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <h2 className={styles.title}>朋友圈</h2>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => setPublishOpen(true)}
        >
          发布
        </Button>
      </div>

      <Tabs
        defaultActiveKey="feed"
        className={styles.tabs}
        items={[
          {
            key: "feed",
            label: "全部动态",
            children: <MomentFeed myUserID={myUserID} />,
          },
          {
            key: "mine",
            label: "我的",
            children: <MomentFeed myUserID={myUserID} />,
          },
        ]}
      />

      <PublishMoment open={publishOpen} onClose={() => setPublishOpen(false)} />
    </div>
  );
};

export default Moments;
