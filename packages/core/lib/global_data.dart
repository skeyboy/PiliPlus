import 'package:core/device_utils.dart';

/// 全局可变状态。
///
/// 这些字段原本在构造时读 `Pref.*`（设置中心）。但 `pref` 包反过来要写
/// `GlobalData().blackMids`，两者互相依赖；而 `pref` 位于 `models` 之上、
/// `core` 位于 `models` 之下 —— 环必须断在 core 这一侧。
///
/// 因此改为**字段带默认值 + 由上层注入**：app 启动后把 `Pref` 里的用户偏好
/// 写回这些字段（与 models 包内偏好静态字段的处理手法一致）。
/// 注入点尚未接上，见 docs/CONTRACTS.md「遗留项」。
class GlobalData {
  /// 原 `Pref.picQuality`（`defaultValue: 10`）
  int imgQuality = 10;

  num? coins;

  void afterCoin(num coin) {
    if (coins != null) {
      coins = coins! - coin;
    }
  }

  /// 原 `Pref.blackMids`
  Set<int> blackMids = <int>{};

  /// 原 `Pref.dynamicsWaterfallFlow`（默认跟随横屏）
  bool dynamicsWaterfallFlow = DeviceUtils.isTablet;

  /// 原 `Pref.showMedal`（`defaultValue: true`）
  bool showMedal = true;

  // 私有构造函数
  GlobalData._();

  // 单例实例
  static final GlobalData _instance = GlobalData._();

  // 获取全局实例
  factory GlobalData() => _instance;
}
