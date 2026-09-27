// core 包导出入口。
//
// 本包代码放在 lib/ 而非 lib/src/，跨包也可以按路径 import
// （如 `import 'package:core/utils.dart'`），不会触发 implementation_imports。

// ---- 共享基础 ----
export 'constants.dart';
export 'loading_state.dart';
export 'pair.dart';
export 'ui_constants.dart';

// ---- controller 基类 ----
export 'controller/common_controller.dart';
export 'controller/common_list_controller.dart';
export 'controller/multi_select/base.dart';
export 'controller/multi_select/multi_select_controller.dart';

// ---- 工具 ----
export 'asset_utils.dart';
export 'bili_colors.dart';
export 'color_utils.dart';
export 'connectivity_utils.dart';
export 'danmaku_utils.dart';
export 'date_utils.dart';
export 'device_utils.dart';
export 'duration_utils.dart';
export 'em.dart';
export 'filtering_text.dart';
export 'fontconfig.g.dart';
export 'id_utils.dart';
export 'latex_to_unicode.dart';
export 'latex_unicode_data.dart';
export 'mobile_observer.dart';
export 'num_utils.dart';
export 'parse_bool.dart';
export 'parse_int.dart';
export 'parse_string.dart';
export 'path_utils.dart';
export 'permission_handler.dart';
export 'platform_utils.dart';
export 'screenshot.dart';
export 'set_int_adapter.dart';
export 'share_utils.dart';
export 'storage_key.dart';
export 'storage_utils.dart';
export 'utils.dart';

// ---- 扩展 ----
export 'extension/box_ext.dart';
export 'extension/context_ext.dart';
export 'extension/core_palettes_ext.dart';
export 'extension/dimension_ext.dart';
export 'extension/file_ext.dart';
export 'extension/iterable_ext.dart';
export 'extension/map_ext.dart';
export 'extension/nested_scroll_ext.dart';
export 'extension/num_ext.dart';
export 'extension/rx_ext.dart';
export 'extension/scroll_controller_ext.dart';
export 'extension/size_ext.dart';
export 'extension/string_ext.dart';
export 'extension/theme_ext.dart';
export 'extension/widget_ext.dart';

// ---- android jni 绑定（jnigen 生成）----
export 'android/bindings.g.dart';
export 'build_config.dart';
