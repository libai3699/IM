/**
 * 发布动态弹窗
 * 支持纯文字 / 图片（最多9张）
 */
import { MomentContent, useCreateMoment } from "@/api/newMoments";
import { Button, Input, message, Modal, Upload } from "antd";
import type { UploadFile } from "antd/es/upload/interface";
import React, { useState } from "react";

interface PublishMomentProps {
  open: boolean;
  onClose: () => void;
}

const PublishMoment: React.FC<PublishMomentProps> = ({ open, onClose }) => {
  const [text, setText] = useState("");
  const [fileList, setFileList] = useState<UploadFile[]>([]);

  const createMutation = useCreateMoment();

  const handleSubmit = async () => {
    if (!text.trim() && fileList.length === 0) {
      message.warning("请输入内容或上传图片");
      return;
    }

    const metas = fileList.map((f) => ({
      original: f.response?.data?.url ?? (f.url as string) ?? "",
      thumb: f.response?.data?.url ?? (f.url as string) ?? "",
      width: 0,
      height: 0,
    }));

    const content: MomentContent = {
      text: text.trim(),
      type: fileList.length > 0 ? 1 : 0,
      metas,
    };

    createMutation.mutate(
      { content },
      {
        onSuccess: () => {
          message.success("发布成功！");
          setText("");
          setFileList([]);
          onClose();
        },
      },
    );
  };

  return (
    <Modal
      title="发布动态"
      open={open}
      onCancel={() => {
        setText("");
        setFileList([]);
        onClose();
      }}
      footer={null}
      width={480}
      destroyOnClose
    >
      <Input.TextArea
        rows={4}
        placeholder="记录一下这个美好的时刻…"
        value={text}
        onChange={(e) => setText(e.target.value)}
        style={{ marginBottom: 12, resize: "none" }}
        maxLength={500}
        showCount
      />

      <Upload
        listType="picture-card"
        fileList={fileList}
        onChange={({ fileList: list }) => setFileList(list)}
        beforeUpload={() => false}
        accept="image/*"
        multiple
        maxCount={9}
      >
        {fileList.length < 9 && (
          <div>
            <div style={{ fontSize: 24, color: "#bbb" }}>+</div>
            <div style={{ fontSize: 12, color: "#999" }}>图片</div>
          </div>
        )}
      </Upload>

      <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, marginTop: 16 }}>
        <Button onClick={onClose}>取消</Button>
        <Button
          type="primary"
          loading={createMutation.isLoading}
          onClick={handleSubmit}
        >
          发布
        </Button>
      </div>
    </Modal>
  );
};

export default PublishMoment;
