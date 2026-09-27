# 模块落地清单（MODULES）

按依赖顺序实现，每个模块自带 `pubspec.yaml` + `lib/<pkg>.dart` 导出入口 + `lib/src/**` 实现，
统一在 workspace 根 `fvm flutter pub get` 一次解析。本清单以 **as-built** 状态记录，`[x]` 为已完成项。

## 当前落地状态（2026-09-27 快照）

- [x] `packages/grpc` — `dart analyze` 全绿
- [x] `packages/core` — `dart analyze` 全绿（utils 纯工具 + controller 链 + 常量下沉）
- [x] `packages/models` — `dart analyze` 全绿（models / models_new / danmaku_model + 枚举解绑）
- [x] `packages/pref` — `dart analyze` 全绿（storage_pref 等设置中心；因 core↔models 环独立拆出，见 CONTRACTS.md）
- [x] `packages/api` — `dart analyze` 仅 1 条 info 级 `deprecated_member_use`（`request_utils.dart:91` 的 `ReplyInfo.create`）
- [ ] 根包（宿主 app）剩余 178 issues，**100% 为 Flutter SDK 补丁基线问题**（见 ARCHITECTURE.md「SDK 补丁门」），拆分引入回归已清零
- 待用户确认后：应用 `lib/scripts/*.patch` 到 fvm Flutter 3.47.5 以解锁 `flutter build`；随后推进阶段 5–8

## 通用约定（全程遵守）

- **版本策略只在根**：成员包的第三方依赖一律写 `any`，具体版本窗口集中在根 `pubspec.yaml` 的
  `dependency_overrides`。成员包自带窗口会让 workspace 解析出互不兼容的一组版本。
- **成员包三件套**：`resolution: workspace` + `publish_to: none` + `environment.sdk: ">=3.13.0"`。
- **单一导出入口**：每个包 `lib/<pkg>.dart` 导出对外 API，实现放 `lib/src/**`。
  例外：`grpc` 的 pb 生成代码有 100 个文件且互相按路径引用，全量 export 会引发命名冲突，
  因此**按路径 import**（`package:grpc/src/bilibili/...`），`lib/grpc.dart` 只导出 `GrpcUrl`。
- **逐包 analyze**：`flutter analyze` 只覆盖当前目录所在的包，跨包错误不会暴露，必须进到每个包里跑 `dart analyze`。
- **下层不认识上层**：下层包不得 import `pages/**`、`router/**`、`main.dart` 或任何 feature 包。
  需要跳转时用宿主注入的回调或 `Get.toNamed` 路由名；需要绑定 widget 的枚举成员用 app 层 extension 补齐。
- **`part of` 不跨包**：拆分时若发现 `part of` 指向另一个包的文件，必须先把该文件归位到宿主包。
- **import 前缀改写**：搬目录后按包改写 `package:PiliPlus/<dir>/` → `package:<pkg>/src/`，
  用脚本批量替换，不要手改（本工程单次改写 77 个文件 / 128 处）。
- **平台目录不动**：`android` / `ios` / `macos` / `windows` / `linux` 与 `lib/scripts/*.patch`
  （对 Flutter SDK 打补丁的脚本）始终留在根目录的宿主包里。

## packages/grpc（protobuf 生成代码）

- [x] `pubspec.yaml`：`fixnum: any` / `protobuf: any`，`resolution: workspace`，仅声明 `sdk` 约束（纯 Dart 包）。
- [x] `lib/src/bilibili/**`：247,731 行 pb 生成代码，由 `lib/grpc/bilibili/` 整体 `git mv` 而来。
- [x] `lib/src/url.dart`：`GrpcUrl` 路径常量（原 `lib/grpc/url.dart`）。
- [x] `lib/grpc.dart`：只 `export 'src/url.dart'`，pb 类型按需按路径导入。
- [x] `analysis_options.yaml`：继承根配置，整体排除 `lib/src/bilibili/**`（生成代码不做 lint）。
- [x] 根 `pubspec.yaml` 增加 `workspace: [packages/grpc]` 与 `grpc: path: packages/grpc`。
- [x] 根 `analysis_options.yaml` 的 `exclude` 由 `lib/grpc/bilibili/**` 改为 `packages/grpc/**`。
- [x] 全工程 import 前缀改写：`package:PiliPlus/grpc/` → `package:grpc/src/`（77 文件 / 128 处）。
- [x] 验证：`dart analyze` → **No issues found**；根 `flutter pub get` → `Got dependencies`。
- [ ] 待跟进：`lib/grpc/{audio,dm,dyn,im,reply,space,view,grpc_req}.dart`（915 行）是**业务请求封装**而非生成代码，
      依赖 `http/{init,constants,loading_state}.dart`，阶段 4 随 `http/**` 一起并入 `packages/api`。

## packages/core（基础设施） —— ✅ 已完成，`dart analyze` 全绿

来源：`lib/utils/**` 分流后的纯工具部分 + `pages/common/**` 的 controller 基类 + `Pref` 设置中心。

- [ ] `lib/src/utils/`：纯工具与 `extension/*`（`id_utils` / `num_utils` / `date_utils` / `duration_utils` / `utils.dart` …）
- [ ] `lib/src/storage/`：Hive 存储封装（`storage.dart` / `storage_pref.dart` / `storage_key.dart` / `accounts/**`）
- [ ] `lib/src/controller/`：`common_controller.dart` → `common_list_controller.dart` →
      `multi_select/{base,multi_select_controller}.dart` 整条链下沉（**解锁 models/models_new 的 8 处反向引用**）
- [ ] `lib/core.dart`：导出公共 API
- [ ] `analysis_options.yaml`

## packages/models（数据模型） —— ✅ 已完成，`dart analyze` 全绿

- [ ] `lib/src/models/**`（原 `lib/models/**`）与 `lib/src/models_new/**`（原 `lib/models_new/**`）
- [ ] 承接 `pages/danmaku/danmaku_model.dart`（52 行纯数据 sealed class）
- [ ] **枚举与页面解绑**：`home_tab_type` / `setting_type` / `fav_type` / `nav_bar_config` / `later_view_type`
      的 `Widget get page` 与 controller 工厂移到 app 层 extension（30 处反向引用）
- [ ] json_serializable 生成文件随包走：`models/user/{stat,info}.g.dart`、`models/model_owner.g.dart`

## packages/api（网络层） —— ✅ 已完成，仅 1 条 info 级 `deprecated_member_use`

- [ ] `lib/src/http/**`（原 `lib/http/**`，9,427 行）
- [ ] `lib/src/grpc/**`：原 `lib/grpc/{audio,dm,dyn,im,reply,space,view,grpc_req}.dart`（915 行）
      —— 与 http 合并后 `grpc ↔ http` 的 11 处环自然消失
- [ ] `LoadingState` / 请求常量作为 core 与 api 的共享契约，位置在合并时定

## packages/pref（设置中心） —— ✅ 已完成，`dart analyze` 全绿

> 因 `storage_pref` 与 `models` 互指（环），阶段 4 实际拆出为独立包，见 CONTRACTS.md §1。

- [x] `lib/storage_pref.dart`（1050 行设置中心，依赖 models 偏好枚举 → 合法，pref 在 models 之上）
- [x] `lib/{storage,video_utils,subtitle_utils,recommend_filter}.dart`
- [x] `lib/{cache_manager,calc_window_position,feed_back,font_utils}.dart`
- [x] `storage.dart` 用 `AccountsStorage` 接口 + `bindAccounts` 回调注入解环（不在 pref 内引用账号实现）
- [x] 根 `pubspec.yaml` 已加 `pref: path: packages/pref`

## packages/ui（通用组件）

- [ ] `lib/src/widgets/**`（原 `lib/common/widgets/**`，48k 行）
- [ ] **先归位 part-of**：`common/widgets/context_menu/{reply,live,dyn}_menu_helper.dart`
      是 `part of 'package:PiliPlus/pages/...'`，必须搬回 pages 后才能独立编译
- [ ] **打断 common → pages**：`video_popup_menu.dart`(4) / `image_save.dart` / `vertical_tabs.dart` / `appbar.dart`
      改为回调注入或 `Get.toNamed`
- [ ] `utils/waterfall.dart` / `grid.dart` 随本包（它们依赖 `common/widgets/*`）

## packages/player（播放器）

- [ ] `lib/src/pl_player/**`（原 `lib/plugin/pl_player/**`，6,177 行）
- [ ] 承接 `pages/sponsor_block/block_mixin.dart`（513 行）+ `models/common/sponsor_block/segment_model.dart`
- [ ] **打断 plugin → pages**（11 处）：`view.dart` / `controller.dart` / `bottom_control.dart`
      改用回调钩子，由 app 注入 video controller 与 post_panel

## packages/services（服务）

- [ ] `lib/src/services/**`（原 `lib/services/**`，1,670 行）
- [ ] `lib/src/tcp/**`（原 `lib/tcp/**`，324 行）
- [ ] 打断 `services → pages` 1 处（`shutdown_timer_service.dart`）

## packages/feature_*（业务域页面，二期）

按 `lib/pages/**` 的 88 个域切分，规模参考：`video` 18,136 / `setting` 7,196 / `dynamics` 4,732 /
`live_room` 3,898 / `member` 2,613 / `search_panel` 2,322 / `audio` 2,128 / `fav` 2,117 / `article` 2,080 行。

- [ ] `feature_video`、`feature_live`、`feature_dynamics`、`feature_member`
- [ ] `feature_fav`、`feature_search`、`feature_settings`、`feature_message`（whisper/*）
- [ ] 其余域按需归组

## packages/app（宿主应用）

- [ ] `lib/main.dart`、`lib/router/**`、`lib/build_config.dart`
- [ ] 平台目录 `android` / `ios` / `macos` / `windows` / `linux` 迁出根目录
- [ ] 承载被打断的 extension 与路由注入（模式 A / D / G 的落地侧）

## 统一验证

- [x] 根 `flutter pub get` —— workspace 解析通过，`grpc` 注册为 `../packages/grpc`
- [x] `packages/grpc`：`dart analyze` → **No issues found**
- [ ] 根包 `dart analyze`（44 万行，慢）
- [ ] 各包 `build_runner build --delete-conflicting-outputs`（5 个 `.g.dart`）
- [ ] `flutter build bundle --debug` / `flutter build apk --debug`

## 环境备注（本机）

- `.fvmrc` 锁定 `3.47.5`，对应 Dart **3.13.4**（`sdk: ">=3.13.0"` 的下限）。
  系统自带 flutter 为 3.41.7 / Dart 3.11.5，**不满足**该约束，所有命令必须走 `fvm`。
- fvm 的 3.47.5 首次运行会卡在 Gradle Wrapper 下载（`storage.flutter-io.cn` 返回 525）。
  已通过两步修复：① 从 3.41.7 复制 `bin/cache/artifacts/gradle_wrapper/` 的内容；
  ② 补写 `bin/cache/gradle_wrapper.stamp`（内容为 `fd5c1f2c013565a3bea56ada6df9d2b8e96d56aa`）。
  后续若再报 `Exception: 525`，检查这两个位置。
