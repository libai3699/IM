import login_bg from '@/assets/images/login_bg.png';
import AdminGoogleAuthModal from '@/components/AdminGoogleAuthModal';
import { adminLogin } from '@/services/server/login';
import { LockOutlined, SafetyOutlined, UserOutlined } from '@ant-design/icons';
import { history, useIntl, useModel } from '@umijs/max';
import { Button, Checkbox, Form, Input, message } from 'antd';
import md5 from 'md5';
import { useState } from 'react';

type FormField = {
  account: string;
  secrect: string;
  googleAuthCode?: string;
};

const Login = () => {
  const intl = useIntl();
  const { setInitialState } = useModel('@@initialState');
  const [showGoogleAuthModal, setShowGoogleAuthModal] = useState(false);
  const showGoogleAuthInput = true; // 默认显示谷歌验证码输入框
  const [pendingAccount, setPendingAccount] = useState('');
  const [pendingPassword, setPendingPassword] = useState('');

  const onFinish = async (value: FormField) => {
    try {
      const hashedPassword = md5(value.secrect);

      // 登录
      const res: any = await adminLogin(value.account, hashedPassword, value.googleAuthCode);
      if (res.errCode !== 0) {
        console.log(res);
        // 拼接 errDlt 和 errMsg 显示
        const parts = [];
        if (res.errDlt) {
          const colonIndex = res.errDlt.indexOf(':');
          if (colonIndex > 0) {
            parts.push(res.errDlt.substring(0, colonIndex).trim());
          } else {
            parts.push(res.errDlt);
          }
        }
        if (res.errMsg) {
          parts.push(res.errMsg);
        }
        const errorMsg = parts.length > 0 ? parts.join(' ') : '登录失败';
        message.error(errorMsg);
        return;
      }

      // 检查是否需要绑定谷歌验证码
      if (res.data.adminToken) {
        // 有 token，说明已绑定且验证通过，直接保存并跳转
        localStorage.setItem('level', res.data.level);
        localStorage.setItem('IMAccountToken', res.data.adminToken);
        localStorage.setItem('IMAdminToken', res.data.imToken);
        localStorage.setItem('IMAdminAccount', value.account);
        localStorage.setItem('IMAdminUserID', res.data.imUserID);

        await setInitialState((s: any) => ({
          ...s,
          currentUser: res.data,
          isAdmin: res.data.level === 100,
        }));

        message.success('登录成功！');
        setTimeout(() => {
          history.push('/business_system/user_manage/user_list');
        }, 500);
      } else {
        // 没有 token，说明未绑定或未提供验证码
        if (res.data.googleAuthEnabled === false) {
          // 明确标识未绑定，弹出绑定弹窗
          setPendingAccount(value.account);
          setPendingPassword(hashedPassword);
          message.warning('该账号未绑定谷歌验证码，请先完成绑定');
          setShowGoogleAuthModal(true);
        } else {
          // 已绑定但未提供验证码或验证码错误
          message.error('请输入谷歌验证码');
        }
      }
      return;
    } catch (error: any) {
      // 错误信息已经在响应拦截器中显示过了，这里只需要记录日志
      console.log(error);
    }
  };

  const handleGoogleAuthModalClose = () => {
    // 绑定成功后，关闭弹窗，用户需要重新登录并输入验证码
    setShowGoogleAuthModal(false);
    setPendingAccount('');
    setPendingPassword('');
    message.info('请重新登录并输入谷歌验证码');
  };

  return (
    <div className="w-screen h-screen flex justify-center items-center">
      <div className="flex">
        <img src={login_bg} alt="" />
        <div className="flex flex-col ml-24">
          <div className="text-2xl font-medium mb-16">
            {intl.formatMessage({ id: 'login.welcome' })}
          </div>
          <Form
            name="basic"
            className="w-[364px]"
            onFinish={onFinish}
            initialValues={{
              check: true,
              // account: localStorage.getItem('IMAdminAccount') ?? '',
              // account: 'openIM123456',
              // secrect: 'openIM123456',
            }}
            autoComplete="off"
            requiredMark={false}
            size="large"
          >
            <Form.Item
              name="account"
              rules={[
                { required: true, message: intl.formatMessage({ id: 'login.account.required' }) },
              ]}
            >
              <Input
                prefix={<UserOutlined className="text-[#4686fc]" />}
                placeholder={intl.formatMessage({ id: 'login.account' })}
              />
            </Form.Item>

            <Form.Item
              name="secrect"
              rules={[
                { required: true, message: intl.formatMessage({ id: 'login.secrect.required' }) },
              ]}
            >
              <Input.Password
                height={40}
                prefix={<LockOutlined className="text-[#4686fc]" />}
                placeholder={intl.formatMessage({ id: 'login.secrect' })}
              />
            </Form.Item>

            {showGoogleAuthInput && (
              <Form.Item name="googleAuthCode">
                <Input
                  prefix={<SafetyOutlined className="text-[#4686fc]" />}
                  placeholder="请输入谷歌验证码"
                  maxLength={6}
                />
              </Form.Item>
            )}

            <Form.Item wrapperCol={{ span: 24 }}>
              <Button className="w-full" type="primary" htmlType="submit">
                {intl.formatMessage({ id: 'login' })}
              </Button>
            </Form.Item>

            <Form.Item name="check" valuePropName="checked">
              <Checkbox>
                {intl.formatMessage({ id: 'login.agreement' })}
                <span className="text-[#4686fc]">
                  {intl.formatMessage({ id: 'login.agreement.service' })}
                </span>
                {intl.formatMessage({ id: 'and' })}
                <span className="text-[#4686fc]">
                  {intl.formatMessage({ id: 'login.agreement.privacy' })}
                </span>
              </Checkbox>
            </Form.Item>
          </Form>
        </div>
      </div>

      {/* 谷歌验证码绑定弹窗 */}
      <AdminGoogleAuthModal
        visible={showGoogleAuthModal}
        account={pendingAccount}
        password={pendingPassword}
        onClose={handleGoogleAuthModalClose}
      />
    </div>
  );
};

export default Login;
