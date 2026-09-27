# PiliPlus — 架构与 workspace 拆分

> 目标：把单包 Flutter 工程（1315 个 dart 文件 / 约 44.2 万行）改造成 **Dart package workspace** 多模块结构，
> 使数据层、网络层、UI 层、业务特性与宿主应用各自成为可独立 analyze / 可独立测试的成员包。

拆分前工程形态：一个 `pubspec.yaml` + 一个 `lib/`，平台目录（android / ios / macos / windows / linux）挂在根上。
下文 §1 的规模与依赖矩阵是**拆分前**的快照（2026-09-27），用于定位阻断项。

---

## 1. 起点：单包结构与规模

| 目录 | 行数 | 说明 |
|------|------|------|
| `lib/grpc/` | 248,646 | protobuf 生成代码（`grpc/bilibili/**` 占 247,731），零业务依赖 |
| `lib/pages/` | 93,145 | 88 个页面域，其中 `video` 18k / `setting` 7.2k / `dynamics` 4.7k / `live_room` 3.9k |
| `lib/common/` | 48,683 | 通用 widget、骨架屏、常量、主题样式 |
| `lib/utils/` | 17,161 | 工具、扩展、账号、存储（`storage_pref.dart` 是设置中心） |
| `lib/models_new/` + `lib/models/` | 16,229 | 数据模型与偏好枚举 |
| `lib/http/` | 9,427 | HTTP 接口封装、`LoadingState`、请求常量 |
| `lib/plugin/` | 6,177 | 播放器 `pl_player` |
| `lib/services/` | 1,670 | 账户服务、下载服务、音频服务 |
| `lib/tcp/` `lib/router/` | 505 | 直播 tcp、`app_pages` 路由表 |
| **合计** | **442,069** | |

跨顶层目录的 import 矩阵（行 = 引用方，列 = 被引用方，单位：处）：

| src \ dst | pages | common | utils | http | models | models_new | grpc | plugin | services |
|-----------|-------|--------|-------|------|--------|-----------|------|--------|----------|
| pages | 846 | 1185 | 1102 | 459 | 346 | 422 | 80 | 56 | 33 |
| utils | **24** | **25** | 142 | **29** | 43 | 6 | 13 | 6 | 2 |
| common | **7** | 133 | 76 | 7 | 14 | 3 | — | 1 | — |
| models | **30** | 4 | 27 | 6 | 47 | 7 | 2 | — | — |
| models_new | **9** | — | 32 | — | 38 | 317 | — | — | — |
| http | — | 9 | 64 | 82 | 38 | 120 | 1 | — | — |
| plugin | **11** | 20 | 42 | 6 | 15 | 3 | — | 27 | 1 |
| grpc | — | 1 | 1 | **10** | — | — | 30 | — | — |
| services | **1** | 1 | 18 | 3 | 3 | 13 | 2 | 5 | 3 |

**加粗的是逆向边**（下层引用上层），共 82 处 `→ pages` + 其余横向环。它们是拆包的唯一阻断项。

---

## 2. 阻断项：循环依赖清单与处理方案

按模式归类，每条给出「现状 → 处理手法」。工作量为改动文件数，不含连带 import 改写。

### A. 设置枚举绑定了页面（models → pages，30 处 / 7 文件）

| 文件 | 反向引用 | 处理 |
|------|---------|------|
| `models/common/home_tab_type.dart` | 11 | `Widget get page` 与 `ctr` 工厂移到 app 层 `extension HomeTabTypeExt` |
| `models/common/setting_type.dart` | 7 | 同上，setting 页模型由 app 层注入 |
| `models/common/fav_type.dart` | 6 | 同上 |
| `models/common/nav_bar_config.dart` | 3 | 同上 |
| `models/common/later_view_type.dart` | 1 | 同上 |
| `models/common/sponsor_block/segment_model.dart` | 1 | 依赖 `pages/sponsor_block/block_mixin.dart`，见模式 D |
| `models/model_hot_video_item.dart` | 1 | 依赖 `pages/common/multi_select/base.dart`，见模式 B |

**手法**：枚举只保留数据与 label，任何返回 `Widget` 或 `GetX controller` 的成员改为 app 层的 extension
（`extension on HomeTabType { Widget get page => ... }`）。Dart 的 extension 可以跨包声明，调用点不用改。

### B. 多选状态 mixin 放错了位置（8 文件 → `pages/common/multi_select/base.dart`）

`multi_select/base.dart`（180 行）本身是 `MultiSelectData` / `MultiSelectBase` / `BaseMultiSelectMixin` 三个纯状态抽象，
不渲染任何 UI；被 25 个文件引用（含 `models`、`models_new` 7 个模型）。

**手法**：连同它的依赖链一起下沉 ——
`common_controller.dart`(69 行) → `common_list_controller.dart`(71 行) → `multi_select/{base,multi_select_controller}.dart`
这条链只依赖 `http/loading_state.dart` + `utils/extension/scroll_controller_ext.dart` + `get` + `easy_debounce`，
是纯 controller 层，可以整体放进 `packages/core` 的 `lib/src/controller/`。下沉后 models → pages 的 8 处自动消失。

### C. 数据模型引用了页面里的模型（models_new → pages，9 处）

- 8 处 → `multi_select/base.dart`（模式 B，随之下沉）
- `models_new/live/live_danmaku/danmaku_msg.dart` → `pages/danmaku/danmaku_model.dart`（52 行的纯 sealed class，无 UI）

**手法**：`danmaku_model.dart` 下沉到 `packages/models`（它只是 `DanmakuExtra` / `VideoDanmaku` 数据类）。

### D. 播放器相关 mixin 位置（plugin ↔ pages，11 处；common → pages 1 处）

`pages/sponsor_block/block_mixin.dart`（513 行）被 `models/segment_model.dart`、`plugin/pl_player/controller.dart` 引用。

**手法**：`block_mixin.dart` 与 `segment_model.dart` 一起下沉到 `packages/player`（sponsor block 是播放器能力）。
`plugin/pl_player/view/view.dart` 的 8 处 pages 引用（video controller / post_panel / header_control）改为
**回调注入**：播放器暴露 `onShowPostPanel` / `onBuildHeaderControl` 等钩子，由 app 层传入实现。

### E. utils 是个大杂烩（utils → 上层，共 118 处）

| 文件 | 去向 | 原因 |
|------|------|------|
| `utils/page_utils.dart` | app 层 | 导航调度器，直接 import 5 个页面 + 4 个 http 接口 |
| `utils/app_scheme.dart` | app 层 | scheme 路由分发，import 9 个页面 |
| `utils/request_utils.dart` | app 层 / api 层 | 依赖 grpc + http + common 组件 |
| `utils/update.dart` | app 层 | 更新弹窗，依赖 http + common |
| `utils/storage_pref.dart` | `packages/core` 的 `pref` 模块 | 设置中心，依赖 22 个 models 枚举（**合法**，models 在它之下） |
| `utils/waterfall.dart` / `grid.dart` | `packages/ui` | 依赖 `common/widgets/*` 布局组件 |
| 其余 40+ 个纯工具与 `extension/*` | `packages/core` | 无上层依赖 |

**手法**：`utils/` 不是一个包，而是三个层次的东西。先按上表分流，再各自成包。

### F. grpc ↔ http（11 处）

`grpc/{grpc_req,audio,dm,dyn,im,reply,space,view}.dart` 引用 `http/{init,constants,loading_state}.dart`；
`http/video.dart` 反向引用 `grpc/view.dart`。

**手法**：不拆成两个包互指，而是**按代码性质重新切分** ——
- `grpc/bilibili/**`（247,731 行，纯 pb 生成，只依赖 `protobuf` / `fixnum`）→ `packages/grpc`
- `grpc/*.dart` 顶层 8 个业务请求文件（915 行）+ `http/**`（9,427 行）→ 合并为 `packages/api`

它们本来就是同一件事的两半（构造 pb 请求 / 发 HTTP），合并后环自然消失。✅ 已落地 `packages/grpc`。

### G. common → pages（7 处）与 part-of 跨目录

- `common/widgets/video_popup_menu.dart`(4) / `image_save.dart`(1) / `flutter/vertical_tabs.dart`(1) / `appbar/appbar.dart`(1)
  → 改为注入回调（`onNavigate` / `onPublish`）或改用 `Get.toNamed` 路由名
- ⚠️ `common/widgets/context_menu/{reply,live,dyn}_menu_helper.dart` 三个文件是
  `part of 'package:PiliPlus/pages/...'` —— **物理位置在 common，逻辑上属于 pages 文件**。
  Dart 的 `part of` 不能跨包，必须先把这三个文件搬回 pages 对应目录，否则拆包即编译失败。

### H. 零星边

`services → pages` 1 处（`shutdown_timer_service.dart`）、`tcp → services` 1 处、`utils → services` 2 处
→ 拆包时按依赖方向调整归属即可，无结构性障碍。

---

## 3. 目标模块拆分（workspace）

根 `pubspec.yaml` 声明 `workspace`，成员以 `path:` 互相引用，版本策略集中写在根的 `dependency_overrides`。

| 模块 | 类型 | 职责 | 来源（拆分前路径） |
|------|------|------|-------------------|
| `packages/grpc` | Dart pkg | bilibili protobuf 生成代码 + grpc 路径常量 | `lib/grpc/bilibili/**`、`lib/grpc/url.dart` |
| `packages/core` | Dart pkg | 纯工具与扩展、Hive 存储、账号、`Pref` 设置中心、controller 基类、主题常量 | `lib/utils/**`（分流后）、`lib/models/common/**` 的偏好枚举 |
| `packages/models` | Dart pkg | 数据模型与解析 | `lib/models/**`、`lib/models_new/**`、`pages/danmaku/danmaku_model.dart` |
| `packages/api` | Dart pkg | HTTP 接口、grpc 业务请求封装、`LoadingState`、请求常量 | `lib/http/**`、`lib/grpc/*.dart` |
| `packages/ui` | Flutter pkg | 通用 widget、骨架屏、图片/弹窗/视频卡片 | `lib/common/**` |
| `packages/player` | Flutter pkg | 播放器内核、弹幕、sponsor block | `lib/plugin/pl_player/**`、`pages/sponsor_block/block_mixin.dart` |
| `packages/services` | Dart pkg | 账户服务、下载服务、音频服务、直播 tcp | `lib/services/**`、`lib/tcp/**` |
| `packages/feature_*` | Flutter pkg | 按业务域切分页面（video / live / dynamics / member / fav / search / settings / message …） | `lib/pages/**`（二期） |
| `packages/app` | Flutter app | `main`、路由表、平台目录、`app_pages` | `lib/main.dart`、`lib/router/**`、android/ios/macos/windows/linux |

依赖方向（无环）：

```
app ──▶ feature_* ──▶ player ──┐
   │         │                  ├─▶ ui ──▶ core
   │         └──────────────────┘          ▲
   └────────────▶ services ──▶ api ──▶ models ──▶ grpc
```

`core` 位于最底层但**依赖 `models`**（`Pref` 要用偏好枚举），这与参照项目 `core → api` 的处理一致：
底层包认识上层的**类型**是可以的，只要上层不反向认识底层包里的实现。

---

## 4. 打断循环的四种手法（按优先级）

1. **归属调整**（零风险，优先）：文件放错了包，搬回去即可。模式 B / C / F 属此类。
2. **extension 跨界**（零调用点改动）：Dart 的 extension 可在任意包为任意类型声明，
   把枚举里的 `Widget get page` 搬到 app 层 extension，枚举本体变纯数据。模式 A 属此类。
3. **回调 / 路由名注入**（需改调用点）：下层需要"跳到某页"时，不 import 页面，改为
   由宿主传入 `VoidCallback` 或用 `Get.toNamed('/xxx')` 字符串路由。模式 D / G 属此类。
4. **part-of 归位**（必须做）：`part of` 不允许跨包，三个 `context_menu/*_menu_helper.dart` 必须先搬回 pages。

---

## 5. 构建与验证流程

1. 根目录 `fvm flutter pub get` —— workspace 一次性解析全部包；**新增/改动成员或依赖后必须先跑**。
2. 各包 `dart run build_runner build --delete-conflicting-outputs`（本工程 json_serializable 生成文件仅 5 个：
   `utils/fontconfig.g.dart`、`utils/android/bindings.g.dart`、`models/user/{stat,info}.g.dart`、`models/model_owner.g.dart`）。
3. **逐包** `dart analyze` —— ⚠️ `flutter analyze` 只分析当前目录所在的包，跨包错误不会暴露。
4. `flutter build bundle --debug`（验证 kernel 编译）与 `flutter build apk --debug`（验证 Gradle + 插件全链路）。

本机工具链：`.fvmrc` 锁定 `3.47.5`（Dart 3.13.4）。系统自带 flutter 为 3.41.7 / Dart 3.11.5，
**不满足** `sdk: ">=3.13.0"`，必须走 `fvm`（或直接 `/Users/lee/fvm/versions/3.47.5/bin/flutter`）。

---

## 6. 执行顺序与遗留项

按依赖自底向上：`grpc` → `core` → `models` → `api` → `ui` / `player` / `services` → `feature_*` → `app`。
每一层落地后必须 `pub get` + 逐包 `analyze` 全绿，再进入下一层。

> **当前快照（2026-09-27）**：阶段 1–4 已落地。实际产出 **5 个成员包** `grpc / core / models / pref / api`——
> 比原方案多出一个独立的 `pref`（因 `storage_pref` 与 `models` 互指，按 CONTRACTS.md 拆出，见 §3 依赖层级）。
> 5 包 `dart analyze` 全绿（`api` 仅 1 条 info 级 `deprecated_member_use`）。
> 根包（宿主 app）剩余 **178 issues**，经核验 **100% 为 Flutter SDK 补丁基线问题**（见下「SDK 补丁门」），
> **拆分本身引入的回归已清零**（修复 16 处：枚举 extension 缺 import、sponsor_block 的 accounts import 未改写、download/view 缺分号）。

- [x] 阶段 1：`packages/grpc` 落地（24.8 万行 pb 生成代码 + `url.dart`，128 处 import 前缀改写）
- [x] 阶段 2：`packages/core`（utils 分流 + `multi_select` controller 链下沉）
- [x] 阶段 3：`packages/models`（含 `danmaku_model.dart` 下沉、模式 A 枚举解绑）
- [x] 阶段 4：`packages/api`（`http/**` + `grpc/*.dart` 合并）+ 顺带拆出 `packages/pref`
- [ ] 阶段 5：`packages/ui` + `packages/player`（模式 D / G 打断）
- [ ] 阶段 6：`packages/services`
- [ ] 阶段 7：`packages/feature_*` 按业务域切分 88 个页面域
- [ ] 阶段 8：`packages/app`（`main.dart` + router + 平台目录迁出根目录）

**SDK 补丁门（全工程统一阻塞点）**：
- `lib/scripts/*.patch`（38 个，对应 Windows `patch.ps1`）是对 Flutter SDK 内部类打补丁，使
  `common/widgets` 与若干页面能编译（扩展 `DraggableScrollableSheet` / `Scrollable` / `SelectableRegion` /
  `EditableText` 等）。**未打补丁时根包有 121 个 error，全部来自这些补丁签名**。
- 2026-09-27 在 fvm 的 Flutter 3.47.5 上 `git apply --check` 试探：**25 个可干净应用，13 个失败**
  （失败集中在 `material/`、`cupertino/` 子目录及 iOS 专属 geetest/bottom_sheet_ios，针对旧版 SDK 上下文已漂移）。
- 应用补丁会**修改全局 fvm Flutter 3.47.5**（git 仓库，可逆），影响该 SDK 下的所有项目；需用户确认后再执行。
- 阶段 5–8 把 `common/plugin/services/pages` 搬进包后，这些 SDK 补丁错误依然存在，不会因拆包消失——
  因此 **SDK 补丁是阶段 5–8 能 `analyze` 全绿与 `flutter build` 通过的前置条件**。

**进一步定位（2026-09-27，已应用全部可用补丁）**：
- 全部 25 个干净补丁 + `material/*`、`cupertino/*` 补丁（后者需从 `packages/flutter/` 目录应用，路径为 `lib/src/...` 相对路径）均已落地，
  补丁已把 `BottomSheetState`/`handleDragStart` 等内部符号注入 SDK（`packages/flutter/lib/src/material/bottom_sheet.dart:257` 已确认存在）。
- 但根包仍余 **76 error**（62 在 `common/widgets`），`common/widgets` 经 `package:material_ui/material_ui.dart` 引用 `BottomSheetState` 等内部符号，
  而这些符号在 `material_ui` 中并不存在。
- **`material_ui` 真相（关键）**：它是 **Flutter 官方团队 flutter.dev 发布的正式包**（pub 上唯一来源，版本 1.0.0–1.4.0，Dart 3.12–3.13，与 3.47.5 同代），
  并非项目私有 fork。其 `lib/src/bottom_sheet.dart` 只有 **私有类 `_BottomSheetState`**，**从不公开导出 `BottomSheetState`** 等内部符号
  （`pubspec.yaml` 写 `material_ui: ^1.0.0` → 锁到 pub 上的 `1.4.0`）。项目 `common/widgets` 用 `extends BottomSheetState` 这类
  Flutter 内部符号，源自 commit `810c26a6e "migrate to material_ui (#2565)"` 之后的不兼容：迁移到了官方 material_ui，
  但 `common/widgets` 旧代码仍引用官方包刻意私有的内部类。
- **结论**：残余 76 error 是 `common/widgets` 代码与官方 `material_ui` 的 **API 不兼容**，**与 workspace 拆包无关**；
  **「锁定 material_ui 正确版本」不可行**（pub 上唯一的 official material_ui 从不暴露这些内部符号，无版本可 pin 解决）。
  真正解法（需用户决策，超出拆包范围）：
  ① 改造 `common/widgets` 改用官方 material_ui 公开 API（或 `import 'package:flutter/src/...'` 内部导入 + ignore）；
  ② 用自定义 material_ui fork 暴露内部符号；
  ③ 回退 material_ui 迁移对 `common/widgets` 的影响。
  已应用的 Flutter SDK 补丁（注入 `BottomSheetState` typedef 等到 SDK 内部）仍是有意义的（补丁原本目的），但项目经官方 material_ui 这条路无法触达这些内部符号。
- fvm Flutter 3.47.5 现已被补丁修改 36 个文件（全局影响该 SDK 下所有项目），可逆：`git -C /Users/lee/fvm/versions/3.47.5 checkout -- .`。

遗留项：
- `lib/scripts/*.patch` 是对 Flutter SDK 本身打补丁的脚本，与包结构无关，**保留在根目录**。
- `tool/jnigen.dart` 生成的 `utils/android/bindings.g.dart` 归属待定（随 core 还是单独包）。
- 三个 `part of` 跨目录文件必须在阶段 5 之前归位，否则 `packages/ui` 无法独立编译。
- `material_ui` 依赖的 `ColorScheme` 与 Flutter 3.47.5 的 `ColorScheme` 类型不匹配（3 处 `argument_type_not_assignable`），属依赖版本冲突基线，待评估是否升级 `material_ui` 或隔离引用。
