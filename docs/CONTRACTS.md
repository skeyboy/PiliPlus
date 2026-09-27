# 阶段 2–4 并行契约（CONTRACTS）

阶段 1（`packages/grpc`，24.8 万行 pb 生成代码）已落地并通过验证。
阶段 2（core）/ 3（models）/ 4（api）**不能原样并行** —— 实测存在两处环，
必须先冻结下面这份契约，再把作业面切成互不重叠的四份交给不同 agent 同时推进。

## 1. 为什么不能直接按目录并行

按 `lib/` 现有目录直接搬会得到两处环：

| 环 | 成因 | 破解 |
|----|------|------|
| **core ↔ models** | `utils/storage_pref.dart` 依赖 22 个 `models` 枚举；而 `models` 反向依赖 `utils/storage_pref.dart` 4 处 | `storage_pref` 必须独立成 `pref` 包（在 models 之上）；models 里的 4 处 Pref 引用在 models 包内解掉 |
| **api ↔ 账号/签名工具** | `http/**` 依赖 `utils/accounts.dart`(18) / `wbi_sign`(8) / `app_sign`(6)；而这些工具反过来依赖 `http` | 把它们**并入 api 包**，依赖在包内消化 |

## 2. 目标依赖层级（无环）

```
grpc ──▶ core ──▶ models ──┬──▶ pref  ──┐
                           └──▶ api   ──┴──▶ ui / player / services ──▶ feature_* ──▶ app
```

- `core` 不依赖 models / api / pages / common（零业务依赖）
- `models` 依赖 core + grpc
- `pref` 依赖 core + models
- `api` 依赖 core + models + pref + grpc

## 3. 四个作业面（目录互不重叠）

### A. packages/core —— 基础设施（零上游依赖，可立即开工）

搬入（保持相对路径，只换前缀 `package:PiliPlus/utils/` → `package:core/`）：

- `lib/utils/**` 中 **54 个纯文件**（不依赖 pages/common/http/plugin/services/models/models_new/grpc）：
  顶层 30 个：`asset_utils` `bili_colors` `cache_manager` `calc_window_position` `color_utils`
  `connectivity_utils` `danmaku_utils` `date_utils` `device_utils` `duration_utils` `em`
  `feed_back` `filtering_text` `font_utils` `fontconfig.g.dart` `global_data` `id_utils`
  `latex_to_unicode` `latex_unicode_data` `max_screen_size` `mobile_observer` `num_utils`
  `parse_bool` `parse_int` `parse_string` `path_utils` `permission_handler` `platform_utils`
  `screenshot` `set_int_adapter` `share_utils` `storage_key` `storage_utils` `utils`
  以及 `utils/extension/**` 中 17 个（排除 `three_dot_ext.dart`）、
  `utils/accounts/cookie_jar_adapter.dart`、`utils/android/**`
- **4 个零依赖共享文件**（主 agent 已前置搬好或由 A 搬）：
  - `lib/http/loading_state.dart` → `packages/core/lib/loading_state.dart`
  - `lib/common/constants.dart` → `packages/core/lib/constants.dart`（**实测零依赖**）
  - `lib/common/widgets/pair.dart` → `packages/core/lib/pair.dart`（**实测零依赖**）
  - `lib/pages/common/{common_controller.dart, common_list_controller.dart, multi_select/**}`
    → `packages/core/lib/controller/**`（controller 链下沉，解锁 models 8 处反向引用）
- **2 个常量**（从上层摘出来，供 `pref` 用）：
  - `deviceTouchSlop`（原 `common/widgets/gesture/horizontal_drag_gesture_recognizer.dart`）→ core
  - `kFullScreenSCWidth = 255.0`（原 `pages/setting/pages/fullscreen_sc_size.dart`）→ core

留在 `lib/utils/` 不搬（阶段 5+ 处理）：`page_utils` `app_scheme` `request_utils`(归 C)
`update` `waterfall` `grid` `image_utils` `bili_utils` `theme_utils` `reply_utils`
`linux_cookie_manager` `json_file_handler` `storage_pref`(归 D) …

### B. packages/models —— 数据模型

- `lib/models/**` → `packages/models/lib/models/**`
- `lib/models_new/**` → `packages/models/lib/models_new/**`
- 承接 `lib/pages/danmaku/danmaku_model.dart`（52 行纯数据 sealed class）
- 承接 **5 个播放器偏好枚举**（原 `plugin/pl_player/models/`）：
  `audio_output_type` `bottom_progress_behavior` `fullscreen_mode` `hwdec_type` `play_repeat`
  —— 它们是设置项的类型，本质属于 models，`pref` 与 `player` 都引用它们
- **解环任务 1**：删掉 models 内 4 处 `storage_pref` 引用（`models/dynamics/result.dart`、
  `models/common/member/tab_type.dart`、`models/common/audio_normalization.dart`、
  `models/common/sponsor_block/segment_model.dart`）。改法：默认值改为常量或改为构造参数传入，
  **不得** import pref。
- **解环任务 2**：6 个「枚举绑定页面」解绑 —— `home_tab_type`(11) `setting_type`(7)
  `fav_type`(6) `nav_bar_config`(3) `later_view_type`(1) `sponsor_block/segment_model`(1)。
  枚举只留数据与 label；`Widget get page` / controller 工厂移到 app 层 extension，
  写在 **`lib/ext/models_page_ext.dart`**（新建目录，不与其他 agent 冲突）。

### C. packages/api —— 网络层

- `lib/http/**` → `packages/api/lib/http/**`（**不含 `loading_state.dart`**，它归 core）
- `lib/grpc/{audio,dm,dyn,im,reply,space,view,grpc_req}.dart` → `packages/api/lib/grpc/**`
- **并入**（它们依赖 http，归入 api 内部消化）：`lib/utils/accounts.dart`、
  `lib/utils/accounts/{account,account_adapter,account_type_adapter,api_type,grpc_headers}.dart`、
  `lib/utils/accounts/account_manager/**`、`lib/utils/{wbi_sign,app_sign,login_utils,url_utils,request_utils}.dart`
- **解环任务 3**：`request_utils.dart` 的 pages 5 处 / common 3 处改为注入回调或引用 core 常量；
  `url_utils` `wbi_sign` `app_sign` 的 http 引用在包内改为相对路径 `http/...`
- `http/constants.dart` 已归 core，包内引用改为 `package:core/constants.dart`

### D. packages/pref —— 设置中心

- `lib/utils/storage_pref.dart`（1050 行）→ `packages/pref/lib/storage_pref.dart`
- `lib/utils/{storage,video_utils,subtitle_utils,recommend_filter}.dart` → `packages/pref/lib/**`
- **解环任务 4**：`storage_pref` 的 9 处上层依赖全部改为下层引用：
  - `common/widgets/pair.dart` → `package:core/pair.dart`（A 已下沉）
  - `common/.../horizontal_drag_gesture_recognizer.dart`(deviceTouchSlop) → `package:core/...`（A 已下沉）
  - `http/constants.dart` → `package:core/constants.dart`（A 已下沉）
  - `pages/setting/pages/fullscreen_sc_size.dart`(kFullScreenSCWidth) → `package:core/...`（A 已下沉）
  - 5 个 `plugin/pl_player/models/*` 枚举 → `package:models/...`（B 已下沉）
  - 余下 `utils/*` 引用 → 按 A 的清单改为 `package:core/...`

## 4. import 路径映射（主 agent 最后统一执行，子 agent 不要动公共区）

| 原前缀 | 新前缀 |
|--------|--------|
| `package:PiliPlus/utils/<纯文件>` | `package:core/<相对路径>` |
| `package:PiliPlus/utils/extension/<x>` | `package:core/extension/<x>` |
| `package:PiliPlus/http/loading_state.dart` | `package:core/loading_state.dart` |
| `package:PiliPlus/http/constants.dart` | `package:core/constants.dart` |
| `package:PiliPlus/common/constants.dart` | `package:core/constants.dart` |
| `package:PiliPlus/common/widgets/pair.dart` | `package:core/pair.dart` |
| `package:PiliPlus/pages/common/common_controller.dart` | `package:core/controller/common_controller.dart` |
| `package:PiliPlus/pages/common/multi_select/base.dart` | `package:core/controller/multi_select/base.dart` |
| `package:PiliPlus/models/` | `package:models/models/` |
| `package:PiliPlus/models_new/` | `package:models/models_new/` |
| `package:PiliPlus/http/` | `package:api/http/` |
| `package:PiliPlus/grpc/<业务文件>.dart` | `package:api/grpc/<业务文件>.dart` |
| `package:PiliPlus/utils/storage_pref.dart` | `package:pref/storage_pref.dart` |

## 5. 边界规则（所有 agent 必须遵守）

1. **只动自己的目录**：`packages/<你的包>/**` 与分配给你的 `lib/` 源文件。
   不得修改 `lib/pages/**`、`lib/router/**`、`lib/main.dart`、其他 agent 的 `packages/**`。
2. **公共区 import 改写不做**：`lib/pages/**` 等处指向旧前缀的 import 由主 agent 用脚本统一替换，
   子 agent 改了会造成写冲突。
3. **每个包交付三件套**：`pubspec.yaml`（`resolution: workspace` + 依赖写 `any`）、
   `lib/<pkg>.dart`（导出入口）、`analysis_options.yaml`（`include: ../../analysis_options.yaml`）。
4. **代码放 `lib/` 而非 `lib/src/`**：pb 与模型都要被跨包按路径 import，放 `src/` 会触发
   `implementation_imports`（阶段 1 实测 128 条）。`grpc` 包已是这个约定。
5. **不要跑 `pub get` / `build`**：workspace 解析与验证由主 agent 统一做，避免并发写 `.dart_tool`。
6. **用 `git mv` 搬文件**，保留历史。

## 6. 完成标准（主 agent 验收）

- 每个包内 grep 不到 `package:PiliPlus/{pages,router}` 的引用（下层不认识上层）
- 每个包 `dart analyze` 无 error（在根 `flutter pub get` 之后）
- 根 `pubspec.yaml` 的 `workspace:` 列表包含全部新包
