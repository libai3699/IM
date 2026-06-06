import { message } from "@/AntdGlobalComp";
import { ErrCodeMap } from "@/constants";

interface ErrorData {
  errCode: number;
  errMsg?: string;
  errDlt?: string;
}

export const errorHandle = (err: unknown) => {
  const errData = err as ErrorData;
  if (errData.errMsg || errData.errDlt) {
    // 拼接 errDlt 和 errMsg，不切割
    const parts: string[] = [];
    if (errData.errDlt) {
      parts.push(errData.errDlt);
    }
    if (errData.errMsg) {
      parts.push(errData.errMsg);
    }
    const errorMsg = parts.length > 0 ? parts.join(' ') : '操作失败';
    message.error(ErrCodeMap[errData.errCode] || errorMsg);
  }
};
