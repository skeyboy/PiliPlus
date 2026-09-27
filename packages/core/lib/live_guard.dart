/// 直播舰长头像框。
///
/// 原为 `utils/bili_utils.dart` 的 `BiliUtils.liveGuardPendant`。
/// 该函数被 `models_new/live/live_superchat/item.dart` 使用，而 `bili_utils`
/// 依赖 `common`（UI 层）进不了 core —— 为打断 `models → utils` 的反向边，
/// 把这个纯常量映射下沉到 core。
library;

const _liveGuard1 =
    'https://i0.hdslb.com/bfs/live/a454275dea465ac15a03f121f0d7edaf96e30bcf.png';
const _liveGuard2 =
    'https://i0.hdslb.com/bfs/live/3b46129e796df42ec7356fcba77c8a79d47db682.png';
const _liveGuard3 =
    'https://i0.hdslb.com/bfs/live/80f732943cc3367029df65e267960d56736a82ee.png';

String? liveGuardPendant(int guardLevel) => switch (guardLevel) {
  1 => _liveGuard1,
  2 => _liveGuard2,
  3 => _liveGuard3,
  _ => null,
};
