import {
  addIPBlacklist,
  deleteIPBlacklist,
  getClientConfig,
  getIPBlacklist,
  setClientConfig,
} from '@/services/server/app_manage';
import { InfoCircleOutlined, PlusOutlined } from '@ant-design/icons';
import { PageContainer } from '@ant-design/pro-components';
import {
  Button,
  Checkbox,
  Form,
  Input,
  message,
  Modal,
  Popconfirm,
  Space,
  Table,
  Tag,
  Tooltip,
} from 'antd';
import { useEffect, useRef, useState } from 'react';

interface AppConfig {
  discoverPageURL?: string;
  allowSendMsgNotFriend?: string;
  needInvitationCodeRegister?: string;
  needVerificationCodeRegister?: string;
  super_code?: string;
  allow_add_friend?: string;
  allow_create_group?: string;
  singleDeviceLogin?: string;
}

interface IPItem {
  ip: string;
  limitRegister: boolean;
  limitLogin: boolean;
}

const ConfigManage = () => {
  const [appConfig, setAppConfig] = useState<AppConfig>({ discoverPageURL: '' });
  const [loading, setLoading] = useState<boolean>(false);
  const orzConfig = useRef<AppConfig>();

  const [ipList, setIpList] = useState<IPItem[]>([]);
  const [ipTotal, setIpTotal] = useState(0);
  const [ipPage, setIpPage] = useState(1);
  const [ipLoading, setIpLoading] = useState(false);
  const [addModalOpen, setAddModalOpen] = useState(false);
  const [addForm] = Form.useForm();

  const getConfig = () => {
    getClientConfig().then((res: any) => {
      if (!res.data.config) return;
      setAppConfig(res.data.config);
      orzConfig.current = res.data.config;
    });
  };

  const fetchIPList = (page = 1) => {
    setIpLoading(true);
    getIPBlacklist({ keyword: '', pagination: { pageNumber: page, showNumber: 20 } })
      .then((res: any) => {
        setIpList(res.data?.forbiddens ?? []);
        setIpTotal(res.data?.total ?? 0);
        setIpPage(page);
      })
      .finally(() => setIpLoading(false));
  };

  useEffect(() => {
    getConfig();
    fetchIPList();
    return () => {};
  }, []);

  const updateConfig = () => {
    if (orzConfig.current?.discoverPageURL === appConfig.discoverPageURL) {
      return;
    }
    setClientConfig({
      discoverPageURL: appConfig.discoverPageURL,
      allowSendMsgNotFriend: appConfig.allowSendMsgNotFriend,
      needInvitationCodeRegister: appConfig.needInvitationCodeRegister,
      needVerificationCodeRegister: appConfig.needVerificationCodeRegister,
    })
      .then(() => {
        message.success('设置成功！');
        getClientConfig();
      })
      .catch(() => {
        message.error('设置失败！');
      });
  };

  return (
    <PageContainer>
      <div>
        <div className="text-base font-medium mb-4">APP发现页配置</div>
        <Space.Compact>
          <Input
            style={{ width: '300px' }}
            value={appConfig.discoverPageURL}
            onChange={(e) => {
              setAppConfig({
                discoverPageURL: e.target.value,
              });
            }}
            suffix={
              <Tooltip title="URL需配置https/http前缀">
                <InfoCircleOutlined style={{ color: 'rgba(0,0,0,.45)' }} />
              </Tooltip>
            }
            placeholder="URL需配置https/http前缀"
          />
          <Button onClick={updateConfig} type="primary">
            保存
          </Button>
        </Space.Compact>
      </div>

      <div className=" mt-[2rem]">
        <div className="text-base font-medium mb-6 py-5 px-5 bg-white">
          <Checkbox
            disabled={loading}
            checked={appConfig?.allowSendMsgNotFriend === '1' ? true : false}
            onChange={(e) => {
              console.log(e);
              setLoading(true);
              setClientConfig({
                allowSendMsgNotFriend: e.target.checked ? '1' : '0',
              })
                .then(() => {
                  message.success('设置成功！');
                  getConfig();
                })
                .catch(() => {
                  message.error('设置失败！');
                })
                .finally(() => setLoading(false));
            }}
          >
            非好友是否允许发送消息
            <div className=" text-xs text-gray-400">*用户需要修改服务端配置文件并重启</div>
          </Checkbox>
        </div>
      </div>

      <div className="text-base font-medium mb-6 py-5 px-5 bg-white">
        <Checkbox
          className="needInvitationCodeRegister"
          disabled={loading}
          checked={appConfig?.needInvitationCodeRegister === '1' ? true : false}
          onChange={(e) => {
            setLoading(true);
            setClientConfig({
              needInvitationCodeRegister: e.target.checked ? '1' : '0',
            })
              .then(() => {
                message.success('设置成功！');
                getConfig();
              })
              .catch(() => {
                message.error('设置失败！');
              })
              .finally(() => setLoading(false));
          }}
        >
          是否需要邀请码才能注册
        </Checkbox>
      </div>

      <div className="text-base font-medium mb-6 py-5 px-5 bg-white">
        <Checkbox
          className="needVerificationCodeRegister"
          disabled={loading}
          checked={appConfig?.needVerificationCodeRegister === '1' ? true : false}
          onChange={(e) => {
            setLoading(true);
            setClientConfig({
              needVerificationCodeRegister: e.target.checked ? '1' : '0',
            })
              .then(() => {
                message.success('设置成功！');
                getConfig();
              })
              .catch(() => {
                message.error('设置失败！');
              })
              .finally(() => setLoading(false));
          }}
        >
          注册是否需要短信/邮箱验证码
          <div className="text-xs text-gray-400">
            * 开启后 Web/App 注册须填写验证码，后端同步校验；关闭则跳过验证码步骤，立即生效
          </div>
        </Checkbox>
      </div>

      {/* 万能验证码配置 */}
      <div className="mt-[2rem]">
        <div className="text-base font-medium mb-4">万能验证码</div>
        <Space.Compact>
          <Input
            style={{ width: '300px' }}
            value={appConfig.super_code || '666666'}
            onChange={(e) => {
              const value = e.target.value;
              // 只允许输入数字
              if (/^\d*$/.test(value) && value.length <= 6) {
                setAppConfig({
                  ...appConfig,
                  super_code: value,
                });
              }
            }}
            maxLength={6}
            placeholder="请输入6位数字验证码"
            suffix={
              <Tooltip title="用于测试或紧急情况，修改后立即生效">
                <InfoCircleOutlined style={{ color: 'rgba(0,0,0,.45)' }} />
              </Tooltip>
            }
          />
          <Button
            onClick={() => {
              if (!appConfig.super_code || appConfig.super_code.length !== 6) {
                message.error('验证码必须是6位数字');
                return;
              }
              setLoading(true);
              setClientConfig({
                super_code: appConfig.super_code,
              })
                .then(() => {
                  message.success('设置成功，立即生效！');
                  getConfig();
                })
                .catch(() => {
                  message.error('设置失败！');
                })
                .finally(() => setLoading(false));
            }}
            type="primary"
            loading={loading}
          >
            保存
          </Button>
        </Space.Compact>
        <div className="text-xs text-gray-400 mt-2">
          * 可在任何需要验证码的场景使用（注册、登录、重置密码等），无需重启服务器
        </div>
      </div>

      {/* 普通用户加好友配置 */}
      <div className="mt-[2rem]">
        <div className="text-base font-medium mb-6 py-5 px-5 bg-white">
          <Checkbox
            disabled={loading}
            checked={appConfig?.allow_add_friend === 'true'}
            onChange={(e) => {
              setLoading(true);
              setClientConfig({
                allow_add_friend: e.target.checked ? 'true' : 'false',
              })
                .then(() => {
                  message.success('设置成功，立即生效！');
                  getConfig();
                })
                .catch(() => {
                  message.error('设置失败！');
                })
                .finally(() => setLoading(false));
            }}
          >
            是否允许普通用户直接互相加好友
            <div className="text-xs text-gray-400">
              * 开启后普通用户可以直接搜索并添加好友，关闭后只能通过管理员添加，无需重启服务器
            </div>
          </Checkbox>
        </div>
      </div>

      {/* 普通用户建群/邀人配置 */}
      <div className="mt-[2rem]">
        <div className="text-base font-medium mb-6 py-5 px-5 bg-white">
          <Checkbox
            disabled={loading}
            checked={appConfig?.allow_create_group === 'true'}
            onChange={(e) => {
              setLoading(true);
              setClientConfig({
                allow_create_group: e.target.checked ? 'true' : 'false',
              })
                .then(() => {
                  message.success('设置成功，立即生效！');
                  getConfig();
                })
                .catch(() => {
                  message.error('设置失败！');
                })
                .finally(() => setLoading(false));
            }}
          >
            是否允许普通用户创建群组、邀请入群
            <div className="text-xs text-gray-400">
              * 开启后普通用户可建群和邀人，关闭后仅高级用户可建群/邀人，无需重启服务器
            </div>
          </Checkbox>
        </div>
      </div>

      {/* 单设备登录限制 */}
      <div className="mt-[2rem]">
        <div className="text-base font-medium mb-6 py-5 px-5 bg-white">
          <Checkbox
            disabled={loading}
            checked={appConfig?.singleDeviceLogin === '1'}
            onChange={(e) => {
              setLoading(true);
              setClientConfig({ singleDeviceLogin: e.target.checked ? '1' : '0' })
                .then(() => {
                  message.success('设置成功！');
                  getConfig();
                })
                .catch(() => message.error('设置失败！'))
                .finally(() => setLoading(false));
            }}
          >
            开启单设备登录限制（App）
            <div className="text-xs text-gray-400">
              * 开启后同一账号只允许一台手机登录，换设备须由管理员在用户列表解绑；Web 端不受影响
            </div>
          </Checkbox>
        </div>
      </div>

      {/* IP 黑名单 */}
      <div className="mt-[2rem]">
        <div className="flex items-center justify-between mb-3">
          <span className="text-base font-medium">IP 黑名单</span>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => {
              addForm.resetFields();
              setAddModalOpen(true);
            }}
          >
            添加 IP
          </Button>
        </div>
        <div className="text-xs text-gray-400 mb-3">
          * 被封禁的 IP 无法注册或登录（可单独控制），立即生效
        </div>
        <Table<IPItem>
          rowKey="ip"
          loading={ipLoading}
          dataSource={ipList}
          pagination={{ current: ipPage, pageSize: 20, total: ipTotal, onChange: fetchIPList }}
          columns={[
            { title: 'IP 地址', dataIndex: 'ip', key: 'ip' },
            {
              title: '禁止注册',
              dataIndex: 'limitRegister',
              key: 'limitRegister',
              align: 'center',
              render: (v) => (v ? <Tag color="red">是</Tag> : <Tag>否</Tag>),
            },
            {
              title: '禁止登录',
              dataIndex: 'limitLogin',
              key: 'limitLogin',
              align: 'center',
              render: (v) => (v ? <Tag color="red">是</Tag> : <Tag>否</Tag>),
            },
            {
              title: '操作',
              key: 'action',
              align: 'center',
              render: (_, record) => (
                <Popconfirm
                  title={`确定删除 ${record.ip} 吗？`}
                  onConfirm={() =>
                    deleteIPBlacklist([record.ip]).then(() => {
                      message.success('删除成功');
                      fetchIPList(ipPage);
                    })
                  }
                  okText="确定"
                  cancelText="取消"
                >
                  <a>删除</a>
                </Popconfirm>
              ),
            },
          ]}
        />
      </div>

      {/* 添加 IP 弹窗 */}
      <Modal
        title="添加 IP 黑名单"
        open={addModalOpen}
        onCancel={() => setAddModalOpen(false)}
        onOk={() => {
          addForm.validateFields().then((values) => {
            addIPBlacklist({
              ip: values.ip,
              limitRegister: !!values.limitRegister,
              limitLogin: !!values.limitLogin,
            }).then(() => {
              message.success('添加成功');
              setAddModalOpen(false);
              fetchIPList(1);
            });
          });
        }}
        okText="确定"
        cancelText="取消"
        destroyOnClose
      >
        <Form form={addForm} layout="vertical">
          <Form.Item
            name="ip"
            label="IP 地址"
            rules={[
              { required: true, message: '请输入 IP 地址' },
              { pattern: /^(\d{1,3}\.){3}\d{1,3}$/, message: 'IP 格式不正确' },
            ]}
          >
            <Input placeholder="例如：192.168.1.100" />
          </Form.Item>
          <Form.Item name="limitRegister" valuePropName="checked" initialValue={true}>
            <Checkbox>禁止该 IP 注册新账号</Checkbox>
          </Form.Item>
          <Form.Item name="limitLogin" valuePropName="checked" initialValue={true}>
            <Checkbox>禁止该 IP 登录</Checkbox>
          </Form.Item>
        </Form>
      </Modal>
    </PageContainer>
  );
};

export default ConfigManage;
