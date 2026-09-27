import 'package:core/pair.dart';
import 'package:models/models/common/sponsor_block/segment_type.dart';
import 'package:models/models/common/sponsor_block/skip_type.dart';
import 'package:models/models_new/sponsor_block/segment_item.dart';

class SegmentModel implements Comparable<SegmentModel> {
  SegmentModel({
    required this.uuid,
    required this.segmentType,
    required this.segment,
    required this.skipType,
  });
  final String uuid;
  final SegmentType segmentType;
  final (int, int) segment;
  final SkipType skipType;
  bool hasSkipped = false;

  /// 未给 config 时的兜底跳过方式；与 Pref.pgcSkipType 的默认值一致，
  /// 由上层（pref / app）按偏好覆盖
  static SkipType defaultSkipType = SkipType.skipOnce;

  factory SegmentModel.fromItemModel(
    SegmentItemModel model,
    // 上层播放器 BlockConfigMixin 实例（提供 blockSettings / blockLimit）。
    // models 不能依赖 pages / player，故此处按结构访问。
    dynamic config,
  ) {
    final segmentType = SegmentType.values.byName(model.category);
    final segment = (model.segment[0], model.segment[1]);
    SkipType skipType;
    if (config != null) {
      final Pair<SegmentType, SkipType> setting =
          config.blockSettings[segmentType.index];
      skipType = setting.second;
      if (skipType != SkipType.showOnly) {
        if (segment.isEq || segment.length < (config.blockLimit as num)) {
          skipType = SkipType.showOnly;
        }
      }
    } else {
      skipType = defaultSkipType;
    }

    return SegmentModel(
      uuid: model.uuid,
      segmentType: segmentType,
      segment: segment,
      skipType: skipType,
    );
  }

  @override
  int compareTo(SegmentModel other) => segment.$1.compareTo(other.segment.$1);
}

extension IntRecordExt on (int, int) {
  bool get isEq => $1 == $2;
  int get length => $2 - $1;
  bool contains(num other) => $1 <= other && other < $2;
}
