import { generateInvitationCode, getInvitationCode } from '@/services/server/register_manage';
import { copy2Text } from '@/utils/common';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import { PageContainer, ProTable } from '@ant-design/pro-components';
import { Button, InputNumber, message, Modal, Tag } from 'antd';
import { useRef, useState } from 'react';
import type { InvitationCodeItem } from './data';

function getUsageStatus(item: Record<string, any>): '已使用' | '未使用' {
  const usedUserID =
    item.usedUserID ||
    item.usedUserId ||
    item.used_user_id ||
    item.usedUser?.userID ||
    item.usedUser?.userId ||
    '';
  return usedUserID ? '已使用' : '未使用';
}

/** 将接口数据转为表格/导出字段 */
function mapInvitationCodeItem(item: Record<string, any>): InvitationCodeItem {
  const usedUserID =
    item.usedUserID ||
    item.usedUserId ||
    item.used_user_id ||
    item.usedUser?.userID ||
    item.usedUser?.userId ||
    '';
  const usageStatus = getUsageStatus(item);
  return {
    invitationCode: item.invitationCode,
    createTime: item.createTime,
    lastTime: item.lastTime,
    userID: usedUserID,
    usedUserID,
    usedUserName: item.usedUser?.nickname ?? item.usedUserName ?? '',
    usedUserPhoneNumber: item.usedUser?.phoneNumber ?? item.usedUserPhoneNumber ?? '',
    usageStatus,
    status: usageStatus === '已使用' ? 1 : 2,
  };
}

/** 解析邀请码列表（兼容 data.list / data.data.list） */
function parseInvitationList(res: Record<string, any>): InvitationCodeItem[] {
  const payload = res?.data ?? res;
  const list = payload?.list ?? payload?.data?.list ?? [];
  return (Array.isArray(list) ? list : []).map(mapInvitationCodeItem);
}

function escapeCsvCell(val: string | number | undefined) {
  const s = String(val ?? '');
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

const columns: ProColumns<InvitationCodeItem>[] = [
  {
    key: 'index',
    title: '序号',
    dataIndex: 'index',
    valueType: 'indexBorder',
    width: 48,
    align: 'center',
  },
  {
    title: '邀请码',
    dataIndex: 'invitationCode',
    key: 'invitationCode',
    align: 'center',
  },
  {
    title: '使用状态',
    key: 'usageStatus',
    dataIndex: 'usageStatus',
    hideInSearch: true,
    align: 'center',
    render: (_, record) => (
      <Tag color={record.usageStatus === '已使用' ? 'success' : 'default'}>
        {record.usageStatus}
      </Tag>
    ),
  },
  {
    title: '使用状态',
    key: 'status',
    dataIndex: 'status',
    valueType: 'select',
    hideInTable: true,
    initialValue: 0,
    valueEnum: {
      0: { text: '全部' },
      1: { text: '已使用' },
      2: { text: '未使用' },
    },
  },
  {
    title: '使用人昵称',
    key: 'usedUserName',
    dataIndex: 'usedUserName',
    hideInSearch: true,
    align: 'center',
    render: (text) => text || '-',
  },
  {
    title: '使用人手机号',
    key: 'usedUserPhoneNumber',
    dataIndex: 'usedUserPhoneNumber',
    valueType: 'select',
    hideInSearch: true,
    align: 'center',
  },
  {
    title: '操作',
    valueType: 'option',
    key: 'option',
    render: (_text, record) => {
      return [
        <a href="#" key="copy" onClick={() => copy2Text(record.invitationCode)}>
          复制
        </a>,
      ];
    },
  },
];

const InvitionCode = () => {
  const actionRef = useRef<ActionType>();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [genNumber, setGenNumber] = useState(10);
  const [pageSize, setPageSize] = useState(10);
  const [allData, setAllData] = useState<InvitationCodeItem[]>([]);
  const lastSearchRef = useRef<{ status?: number; keyword?: string }>({ status: 0 });

  const showModal = () => {
    setIsModalOpen(true);
  };

  const genCode = () => {
    generateInvitationCode(genNumber).then(() => {
      message.success('生成成功！');
      actionRef.current?.reload();
    });
    // .catch(() => message.error('生成失败！'));
  };

  const handleOk = () => {
    setIsModalOpen(false);
    genCode();
  };

  const handleCancel = () => {
    setIsModalOpen(false);
  };

  // 导出为 CSV
  const exportToCSV = (rows: InvitationCodeItem[] = allData) => {
    if (rows.length === 0) {
      message.warning('没有数据可导出');
      return;
    }

    // 构建 CSV 内容
    const headers = ['序号', '邀请码', '使用状态', '使用人ID', '使用人昵称', '使用人手机号'];
    const csvContent = [
      headers.join(','),
      ...rows.map((item, index) => {
        const status = item.usageStatus ?? getUsageStatus(item);
        return [
          index + 1,
          escapeCsvCell(item.invitationCode),
          escapeCsvCell(status),
          escapeCsvCell(item.usedUserID || '-'),
          escapeCsvCell(item.usedUserName || '-'),
          escapeCsvCell(item.usedUserPhoneNumber || '-'),
        ].join(',');
      }),
    ].join('\n');

    // 添加 BOM 以支持中文
    const BOM = '\uFEFF';
    const blob = new Blob([BOM + csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);

    link.setAttribute('href', url);
    link.setAttribute('download', `邀请码列表_${new Date().getTime()}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    message.success('导出成功！');
  };

  // 获取数据用于导出（沿用当前筛选：全部/已使用/未使用）
  const fetchAllDataForExport = async () => {
    try {
      message.loading('正在获取数据...', 0);
      const res = await getInvitationCode({
        status: (lastSearchRef.current.status ?? 0) as any,
        keyword: lastSearchRef.current.keyword,
        pagination: {
          pageNumber: 1,
          showNumber: 10000,
        },
      } as any);
      message.destroy();
      const list = parseInvitationList(res);
      setAllData(list);
      exportToCSV(list);
    } catch (error) {
      message.destroy();
      message.error('获取数据失败');
    }
  };

  return (
    <PageContainer>
      <ProTable<InvitationCodeItem>
        columns={columns}
        actionRef={actionRef}
        cardBordered
        columnsState={{
          defaultValue: {
            option: {
              fixed: 'right',
            },
          },
        }}
        request={async (params = {}) => {
          const status = Number(params.status ?? 0);
          const keyword = params.invitationCode
            ? String(params.invitationCode)
            : params.keyword
            ? String(params.keyword)
            : undefined;
          lastSearchRef.current = { status, keyword };

          const res = await getInvitationCode({
            status: status as any,
            keyword,
            pagination: {
              pageNumber: params.current as number,
              showNumber: params.pageSize,
            },
          } as any);
          const list = parseInvitationList(res);
          const payload = res?.data ?? res;
          const total = payload?.total ?? payload?.data?.total ?? list.length;
          setAllData(list);
          return {
            data: list,
            success: true,
            total,
          };
        }}
        rowKey="invitationCode"
        search={{
          labelWidth: 'auto',
        }}
        pagination={{
          pageSize: pageSize,
          showSizeChanger: true,
          pageSizeOptions: ['10', '20', '50', '100', '200', '500', '1000', '2000'],
          onShowSizeChange: (_current, size) => {
            setPageSize(size);
          },
        }}
        dateFormatter="string"
        scroll={{ x: 'max-content' }}
        toolbar={{
          actions: [
            <Button key="create" type="primary" onClick={showModal}>
              生成邀请码
            </Button>,
            <Button key="export" onClick={fetchAllDataForExport}>
              导出邀请码
            </Button>,
          ],
          settings: [],
        }}
      />
      <Modal title="请选择生成数量" open={isModalOpen} onOk={handleOk} onCancel={handleCancel}>
        <div className="w-full flex justify-center">
          <InputNumber
            min={1}
            max={2000}
            value={genNumber}
            onChange={(value) => {
              setGenNumber(value as number);
            }}
          />
        </div>
      </Modal>
    </PageContainer>
  );
};

export default InvitionCode;
