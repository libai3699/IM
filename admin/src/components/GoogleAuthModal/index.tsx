import {
  bindGoogleAuth,
  getGoogleAuthQRCode,
  getUserGoogleAuthStatus,
  resetGoogleAuth,
} from '@/services/server/google_auth';
import { Alert, Form, Input, message, Modal, QRCode, Space, Typography } from 'antd';
import { useEffect, useState } from 'react';

const { Text, Paragraph } = Typography;

interface GoogleAuthModalProps {
  visible: boolean;
  userID: string;
  onCancel: () => void;
  onSuccess: () => void;
}

const GoogleAuthModal: React.FC<GoogleAuthModalProps> = ({
  visible,
  userID,
  onCancel,
  onSuccess,
}) => {
  const [form] = Form.useForm();
  const [qrData, setQrData] = useState<{
    secret: string;
    qrCodeURL: string;
  } | null>(null);
  const [status, setStatus] = useState<{
    enabled: boolean;
  } | null>(null);

  const loadData = async () => {
    try {
      // 获取用户状态
      const statusRes = await getUserGoogleAuthStatus(userID);
      setStatus(statusRes.data);

      // 如果未绑定，生成二维码
      if (!statusRes.data.enabled) {
        const qrRes = await getGoogleAuthQRCode(userID);
        setQrData(qrRes.data);
      }
    } catch (error) {
      message.error('加载失败');
    }
  };

  // 加载用户状态和二维码
  useEffect(() => {
    if (visible && userID) {
      loadData();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [visible, userID]);

  const handleBind = async (values: { code: string }) => {
    if (!qrData) {
      message.error('请先生成二维码');
      return;
    }

    try {
      await bindGoogleAuth({
        userID,
        secret: qrData.secret,
        code: values.code,
      });
      message.success('绑定成功');
      form.resetFields();
      onSuccess();
    } catch (error) {
      message.error('绑定失败，请检查验证码是否正确');
    }
  };

  const handleReset = async () => {
    Modal.confirm({
      title: '确认重置',
      content: '确定要重置该用户的谷歌验证码吗？重置后用户需要重新绑定。',
      onOk: async () => {
        try {
          await resetGoogleAuth(userID);
          message.success('重置成功');
          onSuccess();
        } catch (error) {
          message.error('重置失败');
        }
      },
    });
  };

  const handleCancel = () => {
    form.resetFields();
    setQrData(null);
    setStatus(null);
    onCancel();
  };

  return (
    <Modal title="谷歌验证码管理" open={visible} onCancel={handleCancel} footer={null} width={600}>
      {status?.enabled ? (
        <Space direction="vertical" style={{ width: '100%' }} size="large">
          <Alert message="该用户已绑定谷歌验证码" type="success" showIcon />
          <div style={{ textAlign: 'center' }}>
            <Space size="large">
              <a
                onClick={() => {
                  // 清除后重新加载
                  handleReset();
                }}
                style={{ color: 'red' }}
              >
                清除绑定
              </a>
              <a
                onClick={() => {
                  // 先清除，然后重新生成二维码
                  Modal.confirm({
                    title: '确认重新绑定',
                    content: '重新绑定会清除当前的谷歌验证码，用户需要重新扫码绑定。',
                    onOk: async () => {
                      try {
                        await resetGoogleAuth(userID);
                        message.success('已清除，请重新绑定');
                        loadData(); // 重新加载，会显示绑定界面
                      } catch (error) {
                        message.error('操作失败');
                      }
                    },
                  });
                }}
              >
                重新绑定
              </a>
            </Space>
          </div>
        </Space>
      ) : (
        <Space direction="vertical" style={{ width: '100%' }} size="large">
          <Alert
            message="绑定步骤"
            description={
              <ol style={{ paddingLeft: 20, margin: 0 }}>
                <li>用户使用 Google Authenticator 扫描下方二维码</li>
                <li>输入 APP 中显示的6位验证码</li>
                <li>点击绑定完成</li>
              </ol>
            }
            type="info"
          />

          {qrData && (
            <div style={{ textAlign: 'center' }}>
              <QRCode value={qrData.qrCodeURL} size={200} />
              <Paragraph copyable style={{ marginTop: 16, fontSize: 12, color: '#666' }}>
                密钥: {qrData.secret}
              </Paragraph>
              <Text type="secondary" style={{ fontSize: 12 }}>
                如果无法扫码，可以手动输入密钥
              </Text>
            </div>
          )}

          <Form form={form} onFinish={handleBind} layout="vertical">
            <Form.Item
              label="验证码"
              name="code"
              rules={[
                { required: true, message: '请输入6位验证码' },
                { len: 6, message: '验证码必须是6位数字' },
                { pattern: /^\d+$/, message: '验证码只能包含数字' },
              ]}
            >
              <Input
                placeholder="请输入6位验证码"
                maxLength={6}
                size="large"
                style={{ textAlign: 'center', fontSize: 20, letterSpacing: 5 }}
              />
            </Form.Item>

            <Form.Item style={{ marginBottom: 0 }}>
              <Space style={{ width: '100%', justifyContent: 'flex-end' }}>
                <a onClick={handleCancel}>取消</a>
                <a onClick={() => form.submit()} style={{ fontWeight: 'bold' }}>
                  绑定
                </a>
              </Space>
            </Form.Item>
          </Form>
        </Space>
      )}
    </Modal>
  );
};

export default GoogleAuthModal;
