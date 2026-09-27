// pref 包导出入口。
//
// 本包代码放在 lib/ 而非 lib/src/，跨包也可以按路径 import
// （如 `import 'package:pref/storage_pref.dart'`），不会触发 implementation_imports。

// ---- 设置中心 ----
export 'storage_pref.dart';

// ---- 存储 ----
export 'storage.dart';

// ---- 偏好派生工具 ----
export 'cache_manager.dart';
export 'calc_window_position.dart';
export 'feed_back.dart';
export 'font_utils.dart';
export 'recommend_filter.dart';
export 'subtitle_utils.dart';
export 'video_utils.dart';
