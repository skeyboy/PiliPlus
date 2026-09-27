import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:core/path_utils.dart';
import 'package:core/platform_utils.dart';
import 'package:core/utils.dart';
import 'package:models/models/common/video/video_type.dart';
import 'package:models/models_new/download/bili_download_entry_info.dart';

/// `BiliDownloadEntryInfo.moreBtn` 原本写在 models 包里，但它返回 Widget 且
/// 依赖 `PageUtils`（页面导航），会让 models 反向依赖 pages。
///
/// 这里用 app 层 extension 把它接回来 —— Dart 的 extension 可跨包声明，
/// 调用点 `entry.moreBtn(...)` 不用改。
extension BiliDownloadEntryInfoExt on BiliDownloadEntryInfo {
  Widget moreBtn(ColorScheme colorScheme) => SizedBox(
    width: 29,
    height: 29,
    child: PopupMenuButton(
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      icon: Icon(
        Icons.more_vert_outlined,
        color: colorScheme.outline,
        size: 18,
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          height: 38,
          child: const Text('查看详情页', style: TextStyle(fontSize: 13)),
          onTap: () {
            if (ep case final ep?) {
              if (ep.from == VideoType.pugv.name) {
                PageUtils.viewPugv(
                  seasonId: seasonId,
                  epId: ep.episodeId,
                );
              } else {
                PageUtils.viewPgc(
                  seasonId: seasonId,
                  epId: ep.episodeId,
                );
              }
              return;
            }
            PageUtils.toVideoPage(
              aid: avid,
              bvid: bvid,
              cid: cid,
              epId: ep?.episodeId,
              title: title,
              cover: cover,
              isVertical: pageData?.isVertical ?? false,
            );
          },
        ),
        if (PlatformUtils.isDesktop)
          PopupMenuItem(
            height: 38,
            child: const Text('打开本地文件夹', style: TextStyle(fontSize: 13)),
            onTap: () => PathUtils.openDir(entryDirPath),
          )
        else
          PopupMenuItem(
            height: 38,
            child: const Text('复制缓存路径', style: TextStyle(fontSize: 13)),
            onTap: () => Utils.copyText(entryDirPath),
          ),
        if (ownerId case final mid?)
          PopupMenuItem(
            height: 38,
            child: Text(
              '访问${ownerName != null ? '：$ownerName' : '用户主页'}',
              style: const TextStyle(fontSize: 13),
            ),
            onTap: () => Get.toNamed('/member?mid=$mid'),
          ),
      ],
    ),
  );
}
