// 枚举 → 页面 / controller 的绑定。
//
// 这些成员原先写在 models 的枚举里，导致 models 反向依赖 pages；
// 现统一下沉到 app 层，用跨包 extension 声明，调用点无需改动
// （但需要调用方 import 本文件）。
import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/pages/dynamics/view.dart';
import 'package:PiliPlus/pages/fav/article/view.dart';
import 'package:PiliPlus/pages/fav/cheese/view.dart';
import 'package:PiliPlus/pages/fav/note/view.dart';
import 'package:PiliPlus/pages/fav/pgc/view.dart';
import 'package:PiliPlus/pages/fav/topic/view.dart';
import 'package:PiliPlus/pages/fav/video/view.dart';
import 'package:PiliPlus/pages/home/view.dart';
import 'package:PiliPlus/pages/hot/controller.dart';
import 'package:PiliPlus/pages/hot/view.dart';
import 'package:PiliPlus/pages/later/child_view.dart';
import 'package:PiliPlus/pages/live/controller.dart';
import 'package:PiliPlus/pages/live/view.dart';
import 'package:PiliPlus/pages/mine/view.dart';
import 'package:PiliPlus/pages/pgc/controller.dart';
import 'package:PiliPlus/pages/pgc/view.dart';
import 'package:PiliPlus/pages/rank/controller.dart';
import 'package:PiliPlus/pages/rank/view.dart';
import 'package:PiliPlus/pages/rcmd/controller.dart';
import 'package:PiliPlus/pages/rcmd/view.dart';
import 'package:PiliPlus/pages/setting/models/extra_settings.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/models/play_settings.dart';
import 'package:PiliPlus/pages/setting/models/privacy_settings.dart';
import 'package:PiliPlus/pages/setting/models/recommend_settings.dart';
import 'package:PiliPlus/pages/setting/models/style_settings.dart';
import 'package:PiliPlus/pages/setting/models/video_settings.dart';
import 'package:core/controller/common_controller.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:models/models/common/fav_type.dart';
import 'package:models/models/common/home_tab_type.dart';
import 'package:models/models/common/later_view_type.dart';
import 'package:models/models/common/nav_bar_config.dart';
import 'package:models/models/common/setting_type.dart';

extension HomeTabTypeExt on HomeTabType {
  ScrollOrRefreshMixin Function() get ctr => switch (this) {
    HomeTabType.live => Get.find<LiveController>,
    HomeTabType.rcmd => Get.find<RcmdController>,
    HomeTabType.hot => Get.find<HotController>,
    HomeTabType.rank => Get.find<RankController>,
    HomeTabType.bangumi ||
    HomeTabType.cinema => () => Get.find<PgcController>(tag: name),
  };

  Widget get page => switch (this) {
    HomeTabType.live => const LivePage(),
    HomeTabType.rcmd => const RcmdPage(),
    HomeTabType.hot => const HotPage(),
    HomeTabType.rank => const RankPage(),
    HomeTabType.bangumi => const PgcPage(tabType: HomeTabType.bangumi),
    HomeTabType.cinema => const PgcPage(tabType: HomeTabType.cinema),
  };
}

extension FavTabTypeExt on FavTabType {
  Widget get page => switch (this) {
    FavTabType.video => const FavVideoPage(),
    FavTabType.bangumi => const FavPgcPage(type: 1),
    FavTabType.cinema => const FavPgcPage(type: 2),
    FavTabType.article => const FavArticlePage(),
    FavTabType.note => const FavNotePage(),
    FavTabType.topic => const FavTopicPage(),
    FavTabType.cheese => const FavCheesePage(),
  };
}

extension NavigationBarTypeExt on NavigationBarType {
  Icon get icon => switch (this) {
    NavigationBarType.home => const Icon(Icons.home_outlined),
    NavigationBarType.dynamics => const Icon(
      CustomIcons.motion_photos_on_outlined,
    ),
    NavigationBarType.mine => const Icon(Icons.person_outline),
  };

  Icon get selectIcon => switch (this) {
    NavigationBarType.home => const Icon(Icons.home),
    NavigationBarType.dynamics => const Icon(CustomIcons.motion_photos_on),
    NavigationBarType.mine => const Icon(Icons.person),
  };

  Widget get page => switch (this) {
    NavigationBarType.home => const HomePage(),
    NavigationBarType.dynamics => const DynamicsPage(),
    NavigationBarType.mine => const MinePage(),
  };
}

extension LaterViewTypeExt on LaterViewType {
  Widget get page => LaterViewChildPage(laterViewType: this);
}

extension SettingTypeExt on SettingType {
  List<SettingsModel> get settings => switch (this) {
    SettingType.privacySetting => privacySettings,
    SettingType.recommendSetting => recommendSettings,
    SettingType.videoSetting => videoSettings,
    SettingType.playSetting => playSettings,
    SettingType.styleSetting => styleSettings,
    SettingType.extraSetting => extraSettings,
    _ => throw UnimplementedError(),
  };
}
