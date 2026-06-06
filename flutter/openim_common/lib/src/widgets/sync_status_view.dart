import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

class SyncStatusView extends StatelessWidget {
  const SyncStatusView({
    Key? key,
    required this.isFailed,
    required this.statusStr,
    this.isSuccess = false,
  }) : super(key: key);
  final bool isFailed;
  final String statusStr;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isFailed ? Styles.c_FFE1DD : (isSuccess ? Styles.c_E8F5E9 : Styles.c_F2F8FF),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFailed)
              ImageRes.syncFailed.toImage
                ..width = 12.w
                ..height = 12.h
            else if (isSuccess)
              Icon(
                CupertinoIcons.check_mark_circled_solid,
                size: 12.w,
                color: Styles.c_4CAF50,
              )
            else
              SizedBox(
                width: 12.w,
                height: 12.h,
                child: CupertinoActivityIndicator(
                  color: Styles.c_0089FF,
                  radius: 6.r,
                ),
              ),
            4.horizontalSpace,
            statusStr.toText
              ..style = (isFailed 
                  ? Styles.ts_FF381F_12sp 
                  : (isSuccess ? Styles.ts_4CAF50_12sp : Styles.ts_0089FF_12sp)),
          ],
        ),
      );
}
