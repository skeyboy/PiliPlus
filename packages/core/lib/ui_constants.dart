import 'package:flutter/foundation.dart' show PlatformDispatcher;
import 'package:flutter/gestures.dart' show kTouchSlop;

/// 全屏 SuperChat 卡片的固定宽度。
///
/// 原定义在 `pages/setting/pages/fullscreen_sc_size.dart`，为打断
/// `pref → pages` 的反向依赖下沉到 core。
const double kFullScreenSCWidth = 255.0;

/// 设备触控容差（逻辑像素）。
///
/// 原定义在 `common/widgets/gesture/horizontal_drag_gesture_recognizer.dart`，
/// 为打断 `pref → common` 的反向依赖下沉到 core。
final double deviceTouchSlop = _calcDeviceTouchSlop();

double _calcDeviceTouchSlop() {
  final view = PlatformDispatcher.instance.views.first;
  final physicalTouchSlop = view.gestureSettings.physicalTouchSlop;
  return physicalTouchSlop == null
      ? kTouchSlop
      : physicalTouchSlop / view.devicePixelRatio;
}
