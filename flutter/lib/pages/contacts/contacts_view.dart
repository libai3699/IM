import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'contacts_logic.dart';

class ContactsPage extends StatelessWidget {
  final logic = Get.find<ContactsLogic>();

  ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.contacts(
        onClickAddContacts: logic.addContacts,
        onClickSearch: logic.searchContacts,
      ),
      backgroundColor: Styles.c_F8F9FA,
      body: Obx(
        () => SmartRefresher(
          controller: logic.refreshController,
          enablePullDown: true,
          enablePullUp: false,
          header: IMViews.buildHeader(),
          onRefresh: logic.refreshFriendList,
          child: _buildScrollableContent(),
        ),
      ),
    );
  }

  // 构建可滚动内容 - 优化滑动性能
  Widget _buildScrollableContent() {
    return Stack(
      children: [
        // 主要内容区域
        ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _getTotalItemCount(),
          itemBuilder: (context, index) => _buildListItem(index),
        ),

        // 字母索引条 - 只在有好友时显示
        if (logic.friendList.isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _buildIndexBar(),
          ),
      ],
    );
  }

  // 获取总项目数量
  int _getTotalItemCount() {
    const headerItemCount = 4; // 顶部功能项：新的好友、群通知、我的好友、我的群组
    return headerItemCount + logic.friendList.length;
  }

  // 构建列表项
  Widget _buildListItem(int index) {
    const headerItemCount = 4;

    if (index < headerItemCount) {
      // 顶部功能项
      return _buildHeaderItem(index);
    } else {
      // 好友列表项
      final friendIndex = index - headerItemCount;
      final friend = logic.friendList[friendIndex];

      // 检查是否需要显示字母分组标题
      final showSuspension = friend.isShowSuspension;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSuspension) _buildSuspensionHeader(friend.getSuspensionTag()),
          _buildFriendItemView(friend),
        ],
      );
    }
  }

  // 构建头部功能项
  Widget _buildHeaderItem(int index) {
    switch (index) {
      case 0:
        return _buildItemView(
          assetsName: ImageRes.newFriend,
          label: StrRes.newFriend,
          count: logic.friendApplicationCount,
          onTap: logic.newFriend,
        );
      case 1:
        return _buildItemView(
          assetsName: ImageRes.newGroup,
          label: StrRes.newGroupRequest,
          count: logic.groupApplicationCount,
          onTap: logic.newGroup,
        );
      case 2:
        return _buildItemView(
          assetsName: ImageRes.myFriend,
          label: StrRes.myFriend,
          onTap: logic.myFriend,
        );
      case 3:
        return _buildItemView(
          assetsName: ImageRes.myGroup,
          label: StrRes.myGroup,
          onTap: logic.myGroup,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // 构建字母分组标题
  Widget _buildSuspensionHeader(String tag) {
    if (tag == '↑') return const SizedBox.shrink();

    return Container(
      height: 23.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      alignment: Alignment.centerLeft,
      width: double.infinity,
      color: Styles.c_E8EAEF,
      child: Text(tag, style: Styles.ts_8E9AB0_14sp),
    );
  }

  // 构建字母索引条
  Widget _buildIndexBar() {
    // 这里可以添加字母索引条的实现
    // 暂时返回空容器，保持原有的字母索引功能
    return const SizedBox.shrink();
  }

  Widget _buildItemView({
    String? assetsName,
    required String label,
    Widget? icon,
    int count = 0,
    bool showRightArrow = true,
    double? height,
    Function()? onTap,
  }) =>
      Ink(
        color: Styles.c_FFFFFF,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: height ?? 60.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                if (null != assetsName)
                  assetsName.toImage
                    ..width = 42.w
                    ..height = 42.h,
                if (null != icon) icon,
                12.horizontalSpace,
                label.toText..style = Styles.ts_0C1C33_17sp,
                const Spacer(),
                if (count > 0) UnreadCountView(count: count),
                4.horizontalSpace,
                if (showRightArrow)
                  ImageRes.rightArrow.toImage
                    ..width = 24.w
                    ..height = 24.h,
              ],
            ),
          ),
        ),
      );

  Widget _buildFriendItemView(ISUserInfo info) => Ink(
        height: 64.h,
        color: Styles.c_FFFFFF,
        child: InkWell(
          onTap: () => logic.viewFriendInfo(info),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                AvatarView(
                  url: info.faceURL,
                  text: info.showName,
                ),
                10.horizontalSpace,
                info.showName.toText..style = Styles.ts_0C1C33_17sp,
              ],
            ),
          ),
        ),
      );

// /// 我加入的部门
// List<Widget> _buildMyDeptView() => logic.myDeptList
//     .map((dept) => _buildItemView(
//           height: 48.h,
//           icon: SizedBox(
//             width: 42.w,
//             height: 42.h,
//             child: Center(
//               child: ImageRes.tree.toImage
//                 ..width = 18.w
//                 ..height = 18.h,
//             ),
//           ),
//           label: dept.department?.name ?? '',
//           onTap: () => logic.enterMyDepartment(dept.department),
//         ))
//     .toList();
}
