# 企业生图素材台账

本目录保存通过学校合作企业生图服务取得的原始图像，以及从原始图像派生的环境参考图。原始文件保持不改；运行时 PNG 位于 `assets/sprites/`、`assets/tilesets/`、`assets/effects/`、`assets/ui/`、`assets/objects/`、`assets/items/` 和 `assets/backgrounds/`。

## 来源与生成范围

- 服务页面：<https://bhai.elex-tech.com/image>
- 生成/下载日期：初始批次 2026-08-26，MVP 补缺批次 2026-08-27 至 2026-08-28，专用特效批次 2026-08-30（中国标准时间）
- 游戏世界观：凋亡森林、心脏形生命核心、遗迹地牢、节拍战斗
- 目标风格：2D 顶视角像素艺术；硬边、有限色板、无文字和 Logo
- 生成约束：角色和特效要求真实透明背景、统一网格、统一中心枢轴和脚底基线；本地处理使用 Pillow，并在导出时采用二值 alpha 和确定性采样
- 企业页面会话：环境 `100`、玩家 `101`、普通敌人 `102`、Boss `103`、瓦片 `104`；特效在同批次新建工作页生成，现有记录未保留独立编号

带签名的对象存储下载地址没有写入本文件：它们是短期链接，且可能包含临时访问参数。原始文件名、尺寸和 SHA-256 足以复核当前落盘文件。

## 原始文件清单

| 用途 | 模型与参数 | 原始文件 | 尺寸 / 色彩 | SHA-256 |
| --- | --- | --- | --- | --- |
| 场景基准 | Seedream 5.0 Pro；2K；16:9 | `scene_heartcore_forest_raw.jpeg` | 2560x1440 / RGB | `27ba5eb6b3282d6bfe3d33ea0abb4a60ea799a7560b2e4afb6406e25561f4d15` |
| 玩家精灵表 | gpt-image-2；high；2K；1:1 | `player_sheet_raw.png` | 2048x2048 / RGB | `373b739517069b62d3e9d379ce0e79fb5ceb6888b1ce4f2f3b97b1d579dcad03` |
| 普通敌人精灵表 | gpt-image-2；high；2K；1:1 | `enemy_sheet_raw.png` | 2048x2048 / RGB | `3d98f8830b0a96ca45e648702fd8d135c3619a174fdd9542cb41b5fe9114a812` |
| Boss 精灵表 | gpt-image-2；high；2K；1:1 | `boss_sheet_raw.png` | 2048x2048 / RGB | `122eabe5269df82fbc21c423946c3d1d324c7de1239e4594507872f473eac94b` |
| 遗迹瓦片 atlas | gpt-image-2；high；2K；1:1 | `tileset_ruins_raw.png` | 2048x2048 / RGB | `f90d2ce414daba3cfa3684202c0339123e9ab5dc366fb4c32809f8f10e46826b` |
| 战斗特效 atlas | gpt-image-2；high；2K；1:1 | `effects_atlas_raw.png` | 2048x2048 / RGB | `e0190fc775bcbe115df3b2058133fde926eb32e387b8af868d59e8c0419108a0` |
| 右墙出口 4 帧特效 | gpt-image-2；high；2K；1:1；文生图；透明请求 | `inbox/effects/fx_room_exit_portal_sheet_raw.png` | 2048x2048 / RGB；棋盘格背景 | `e3da1bf05a8f9e5fe47d63ec31b0ffd05668201f6c1f564eead1ee6bb12d6e8b` |
| 无文字弹刀 4 帧特效 | gpt-image-2；high；2K；1:1；文生图；透明请求 | `inbox/effects/fx_weapon_clash_sheet_raw.png` | 2048x2048 / RGB；棋盘格背景 | `1a92f3d390426a87964342b7e302d7f8bf48470feeebe8ced9812e3c9487220e` |

## 2026-08-30：专用特效批次

两张图均在 <https://bhai.elex-tech.com/image/100> 完成，页面设置为“文生图”、`gpt-image-2`、`high`、`2K`、`1:1`、数量 1；页面未展示 seed。原图落盘时间（中国标准时间）分别为出口 `2026-08-30 11:13:27`、弹刀 `2026-08-30 11:16:35`。下载原图按队列命名保存，未改写原始像素。BHai 实际返回 RGB 棋盘格背景，透明请求不是原图事实；项目使用 `tools/process_generated_assets.py` 中的 `fit_effect_sheet()` 做确定性去棋盘格、二值 alpha、统一枢轴和缩放。

| 原始文件 | 派生运行时文件 | 派生规格 / SHA-256 | 当前状态 |
| --- | --- | --- | --- |
| `inbox/effects/fx_room_exit_portal_sheet_raw.png` | `assets/effects/fx_room_exit_portal_sheet.png` | 192x64 / RGBA / alpha `{0,255}` / `07e88b32c50821a211dc1c1bea2e34438d9345c9b64bb4c1eeab21d71dc3d490` | 原图和派生图已视觉检查；已由 `MvpRoomView` 接入 Godot 右墙门四帧播放 |
| `inbox/effects/fx_weapon_clash_sheet_raw.png` | `assets/effects/fx_weapon_clash_sheet.png` | 128x32 / RGBA / alpha `{0,255}` / `389b13aeba4ec6f8e9f60f5537d5a632941d45fe083c6339f13f9c07dff8e73a` | 原图和派生图已视觉检查；尚未替换通用弹刀火花 |

出口帧序为“封闭根系门印→青色裂隙→向左张开的门洞→稳定青绿色脉冲”；弹刀帧序为“交叉刀光→接触星芒→扩大的双色冲击环→消散碎屑”。四帧边界、目标尺寸、RGBA 和二值 alpha 均通过检查；Godot 导入和场景接入已完成，仍待逐帧窗口视觉验收、弹刀/转场捕获回归复核及公开再分发授权确认。

## 提示词记录

### 环境基准图（会话 100）

```text
原创 2D 顶视角像素艺术游戏环境，主题是“凋亡森林中的心脏形生命核心遗迹”。一个可用于 Godot 2D 节奏地牢的单房间战斗场景：正方形石质地板网格，厚重古代遗迹墙体，墙缝长出干枯树根与血管般的暗红藤蔓，房间中央有微微发光的心脏形生命核心和圆形祭坛，角落有少量青绿色晶体与落叶。整体构图清晰、可读、适合俯视角 8×5 格战斗房间，留出开阔的可行走地面，不出现角色、怪物、UI、文字、Logo。严格像素画风：低分辨率感、硬边、无抗锯齿、有限色板（深墨绿、灰石色、暗红、心核青绿高光）、清晰 1 像素网格、无平滑渐变、无摄影写实、无 3D、无等距视角。16:9 横构图，游戏背景概念资产。
```

### 玩家精灵表（会话 101）

```text
Game-ready original 2D pixel art sprite sheet for an indie top-down rhythm dungeon game, “Withered Forest / Heart-Core Ruins” setting. ONE playable hero design: a young rhythm warden in a short dark gray-green cloak, teal luminous heart-core pendant, muted crimson scarf accent, compact silhouette readable at 32x32 pixels, simple resonant short blade. Exact 4 by 4 sprite grid, 16 equal square cells, no gutters, no labels: rows are facing down, left, right, up; columns are idle, step 1, step 2, attack. Each cell contains the same character with consistent feet baseline and center pivot, clear pose changes only. Transparent background (true alpha), no checkerboard, no shadow outside the character, no scenery, no text, no logo. Strict pixel art: hard 1-pixel edges, limited palette of charcoal green, slate gray, cyan glow and restrained magenta, no antialiasing, no blur, no gradients, no painterly rendering, no 3D, no anime illustration, no isometric view. The sheet must be clean and evenly aligned for slicing in Godot; preserve generous transparent padding inside every cell.
```

### 普通敌人精灵表（会话 102）

```text
Original game-ready 2D top-down pixel art sprite sheet for the same “Withered Forest / Heart-Core Ruins” rhythm dungeon world. ONE small enemy species called a siphonling: a low crawling bundle of twisted dark roots and mossy charcoal shell, four short clawed limbs, a bright amber-red stolen energy core in the chest, thin muted crimson tendrils, two narrow cyan eyes; silhouette must be clearly different from the cloaked hero and readable at 32x32 pixels. Exact 4 by 4 sprite grid, 16 equal square cells, no gutters, no labels: rows facing down, left, right, up; columns idle, crawl step 1, crawl step 2, attack. Same creature and same center pivot/feet baseline in every cell, clear pose changes only. Transparent background as true alpha (do not draw a checkerboard), no scenery, no text, no logo, no UI. Strict pixel art with hard 1-pixel edges, limited palette charcoal green, slate gray, dull crimson and amber core with tiny cyan highlights, no antialiasing, blur, gradients, painterly style, 3D, anime, isometric view. Clean evenly aligned atlas suitable for Godot slicing, generous transparent padding in every cell.
```

### Boss 精灵表（会话 103）

```text
Original game-ready 2D top-down pixel art sprite sheet for the “Withered Forest / Heart-Core Ruins” rhythm dungeon game. ONE boss character, the Corewarden: an imposing ancient guardian fused with a cracked heart-shaped core and a crown of dead roots, broad cloak-like stone plates, asymmetric antler roots, cyan life-energy fissures and restrained magenta warning glow. Visually larger than the 32x32 hero/enemy but still a single-cell gameplay unit, readable at 64x64 pixels. Exact 4 by 4 sprite grid, 16 equal square cells, no gutters, no labels: rows facing down, left, right, up; columns idle, phase one, phase two (faster BPM corrupted glow), attack. Same boss silhouette, center pivot and ground baseline in every cell, clear pose changes only. Transparent background as true alpha (do not draw a checkerboard), no scenery, no text, no logo, no UI. Strict crisp pixel art, hard 1-pixel edges, limited charcoal green, slate stone, cyan core light and controlled magenta, no antialiasing, blur, smooth gradients, painterly rendering, 3D, anime, isometric view. Clean evenly aligned atlas suitable for Godot slicing, generous transparent padding in each cell; do not make a 2x2 multi-cell composition.
```

### 遗迹瓦片 atlas（会话 104）

```text
Original game-ready 2D pixel art tileset atlas for the Withered Forest / Heart-Core Ruins top-down rhythm dungeon game. Exact 8 columns by 4 rows grid, 32 equal square tiles, no gutters, no labels or text. Each tile is a seamless 16x16 logical pixel tile with hard edges and a transparent background where appropriate. Row 1: two cracked gray-green stone floor variants, two dark floor variants, two leaf-strewn floor variants, one heart-vein floor tile, one cyan crystal floor accent. Row 2: wall center, wall top edge, wall bottom edge, wall left edge, wall right edge, four outer corners. Row 3: closed left door, closed right door, open left door, open right door, root-covered wall, red vein wall, crystal cluster, altar stone. Row 4: dark corner filler, rune floor, heart-core mosaic, moss patch, loose stone, warning rune, energy-return path, empty transparent tile. Strict crisp pixel art, muted charcoal green and slate stone with restrained crimson roots and cyan life-energy accents, no antialiasing, no blur, no gradients, no painterly or 3D rendering, no isometric view. Keep every tile aligned to the grid and suitable for Godot nearest-neighbour slicing.
```

### 战斗特效 atlas（同批次工作页）

```text
Original game-ready 2D pixel art effects atlas for the Withered Forest / Heart-Core Ruins rhythm dungeon game. Exact 4 columns by 4 rows grid, 16 equal square cells, no gutters, no labels or text, transparent background as true alpha (do not draw a checkerboard). Each cell is a centered effect with consistent pivot. Row 1: cyan resonant blade slash in four directions. Row 2: white-cyan hit spark, enemy hurt flash, player hurt flash, red adjacent-threat pulse. Row 3: tiny cyan energy particle, magenta warning burst, heart-core beat pulse ring, open-door glow. Row 4: energy return trail, shield shimmer, charge sparkle, boss BPM phase-change warning. Strict crisp pixel art, hard 1-pixel edges, limited charcoal green, cyan, white, restrained magenta and amber, no antialiasing, blur, smooth gradients, painterly style, 3D, anime, isometric view. Keep effects readable at 16 to 64 pixels and aligned for Godot nearest-neighbour slicing.
```

## 派生与检查

运行命令：

```sh
python3 tools/process_generated_assets.py
```

处理脚本会：

- 从角色原图裁出 4x4 atlas，并导出按动作分列的竖向条；玩家和普通敌人单帧为 32x32，Boss 单帧为 64x64。
- 从瓦片原图按记录的非均匀网格边界裁出 `ruin_forest_atlas_16.png`（8x4、每格 16x16）。
- 从特效原图裁出 4x4、每格 32x32 的 `combat_effects_atlas.png`。
- 从 2026-08-30 两张横向特效原图按源单元裁切、去棋盘格、统一枢轴并导出 `fx_room_exit_portal_sheet.png`（4×48x64）和 `fx_weapon_clash_sheet.png`（4×32x32）。
- 从环境图导出 960x540 房间背景和 512x512 心核近景。
- 生成 `derived_manifest.json`，记录派生文件的尺寸、模式和 SHA-256。

2026-08-26 初始检查结果：派生角色、瓦片和特效文件均为 RGBA；运行时 atlas 的 alpha 为二值（无半透明边缘）。截至 2026-08-28，`derived_manifest.json` 的 `generated` 清单已覆盖本批所有运行时路径；其中 20 张补缺方向状态与此前 4 张 down 基线均有尺寸、模式和 SHA-256 条目，且无缺失路径。`previews/` 中的三个放大图仅用于人工 QA，不是运行时资源。

## 2026-08-28：MVP 补缺素材批次（基础素材与方向状态）

本节补充 2026-08-27 至 2026-08-28 落盘、由 `tools/process_generated_assets.py --mvp-only` 处理的 MVP 补缺批次，包含 16 个基础素材原图和 20 张补缺方向状态的运行时闭环。原图保持在 `inbox/`，没有重命名为其他格式或被覆盖；四张房间原图是 JPEG，运行时派生背景才是 PNG。本批结果卡位于工作页 `<https://bhai.elex-tech.com/image/100>`；页面未留存逐图 seed 或独立会话编号的条目，不以推测补写。下表参数以 `GENERATION_QUEUE.md` 的任务预设和实际下载格式为准。

| 原始文件 | 模型 / 参数 | 尺寸 / 模式 | SHA-256 |
| --- | --- | --- | --- |
| `inbox/sprites/player_hurt_down_raw.png` | gpt-image-2；high；2K；1:1；PNG；图生图；透明请求 | 2048x2048 / RGB | `1b0fb83fb29a510849ba8951a11f54d2523b49736dc684b4bce2b7a6758cf679` |
| `inbox/sprites/player_death_down_raw.png` | gpt-image-2；high；2K；1:1；PNG；图生图；透明请求 | 2048x2048 / RGB | `f7e0bbccd768c07ad3ec05bf232491fffccd3ec18f81fd820012a4114b65c72e` |
| `inbox/sprites/enemy_hurt_down_raw.png` | gpt-image-2；high；2K；1:1；PNG；图生图；透明请求 | 2048x2048 / RGB | `6ede358133ecd37df48f1b987b81fa061ca3bc1a01c658787aa2bae36f388991` |
| `inbox/sprites/enemy_death_down_raw.png` | gpt-image-2；high；2K；1:1；PNG；图生图；透明请求 | 2048x2048 / RGB | `7855e98e9d24d52cd30f42c85532ad11b32f4a7d901b0ceb5c5d45735e277be6` |
| `inbox/objects/heart_core_raw.png` | gpt-image-2；high；2K；1:1；PNG；单物件；透明请求 | 2048x2048 / RGB | `11b6b3be1bb9b06938baee006078a870d9239a6a6a34dc56921ceb5342500860` |
| `inbox/objects/reward_shrine_raw.png` | gpt-image-2；high；2K；1:1；PNG；单物件；透明请求 | 2048x2048 / RGB | `c96bdeec0067c9eeaa6e1e66968ad306d574a6febca71b54fc28824042bf67aa` |
| `inbox/items/tempo_echo_raw.png` | gpt-image-2；high；2K；1:1；PNG；单物件；透明请求 | 2048x2048 / RGB | `958ebadd24e407c767578575a1946c01d372cef1b42d32efcbbe73b5c3334f4f` |
| `inbox/items/guard_echo_raw.png` | gpt-image-2；high；2K；1:1；PNG；单物件；透明请求 | 2048x2048 / RGB | `68f49d29b25c008bc3aa5282a801e4ad7402de21edbd640d1ec41fcef09a67a8` |
| `inbox/ui/heart_full_raw.png` | gpt-image-2；high；2K；1:1；PNG；单图标；透明请求 | 2048x2048 / RGB | `960db9c09d8088d23f436c3b54eb848e67f55b2a378107efcc8f9eb76bada182` |
| `inbox/ui/heart_empty_raw.png` | gpt-image-2；high；2K；1:1；PNG；单图标；透明请求 | 2048x2048 / RGB | `d951dcaaf707a3fe31c55a25cd5bda21dea85d80e890ac357f96f7116af42c7d` |
| `inbox/ui/charge_raw.png` | gpt-image-2；high；2K；1:1；PNG；单图标；透明请求 | 2048x2048 / RGB | `63bb9564b35ec788e634f65c02744631bfdf7ccf987cd233be31c51fe6c1dd13` |
| `inbox/ui/shield_ready_raw.png` | gpt-image-2；high；2K；1:1；PNG；单图标；透明请求 | 2048x2048 / RGB | `8279472a22cb1f60caaf37b981136df61e359bd40a5a904f77d9247232b6f85d` |
| `inbox/scenes/room_reward_raw.jpeg` | Seedream 5.0 Pro；最高质量；2K；16:9；图生图；不透明 JPEG | 2560x1440 / RGB | `87f0b566b89fff6260a257d8787eafbef43146662b9cf97ed05ce94dca9d16b2` |
| `inbox/scenes/room_hard_raw.jpeg` | Seedream 5.0 Pro；最高质量；2K；16:9；图生图；不透明 JPEG | 2560x1440 / RGB | `6a29322fa2935bcd87e81507ae85ac7d06c11cea8bd69277e0a275058a29be78` |
| `inbox/scenes/room_boss_raw.jpeg` | Seedream 5.0 Pro；最高质量；2K；16:9；图生图；不透明 JPEG | 2560x1440 / RGB | `e7cfbee03f56a837676dafb05c83d9bf88e0ccb4a3c4c7acdc752acf3b0b3c8b` |
| `inbox/scenes/room_restored_raw.jpeg` | Seedream 5.0 Pro；最高质量；2K；16:9；图生图；不透明 JPEG | 2560x1440 / RGB | `15e82b4246d3cddf71e67dbdec2f3f7036d758e4836aee42661c3f8b03926f34` |

### 本批运行时派生组

| 组 | 运行时文件 | 规格 |
| --- | --- | --- |
| 玩家 hurt/death 状态 | `assets/sprites/player_{hurt,death}_{down,left,right,up}.png`（8 张） | 各 32x32 / RGBA；本次补缺方向 6 张 |
| 普通敌人 hurt/death 状态 | `assets/sprites/enemy_siphonling_{hurt,death}_{down,left,right,up}.png`（8 张） | 各 32x32 / RGBA；本次补缺方向 6 张 |
| Boss hurt/death 状态 | `assets/sprites/boss_{hurt,death}_{down,left,right,up}.png`（8 张） | 各 64x64 / RGBA；本次补缺方向 8 张 |
| 小型心核 | `assets/objects/heart_core.png` | 96x96 / RGBA |
| 奖励祭坛 | `assets/objects/reward_shrine.png` | 64x64 / RGBA |
| 局内强化回响 | `assets/items/echo_tempo.png`、`echo_guard.png` | 各 24x24 / RGBA |
| HUD 单图标 | `assets/ui/heart_full.png`、`heart_empty.png`、`charge_one.png`、`shield_ready.png` | 各 16x16 / RGBA |
| HUD 组合 atlas | `assets/ui/mvp_state_icons.png` | 64x16 / RGBA，四个 16x16 图标横向拼合 |
| 房间背景 | `assets/backgrounds/room_reward.png`、`room_hard.png`、`room_boss.png`、`room_restored.png` | 各 960x540 / RGB |

本次补缺的 20 张运行时方向状态（不含此前已存在的 4 张 down 基线）为：

```text
assets/sprites/player_hurt_left.png
assets/sprites/player_hurt_right.png
assets/sprites/player_hurt_up.png
assets/sprites/player_death_left.png
assets/sprites/player_death_right.png
assets/sprites/player_death_up.png
assets/sprites/enemy_siphonling_hurt_left.png
assets/sprites/enemy_siphonling_hurt_right.png
assets/sprites/enemy_siphonling_hurt_up.png
assets/sprites/enemy_siphonling_death_left.png
assets/sprites/enemy_siphonling_death_right.png
assets/sprites/enemy_siphonling_death_up.png
assets/sprites/boss_hurt_down.png
assets/sprites/boss_hurt_left.png
assets/sprites/boss_hurt_right.png
assets/sprites/boss_hurt_up.png
assets/sprites/boss_death_down.png
assets/sprites/boss_death_left.png
assets/sprites/boss_death_right.png
assets/sprites/boss_death_up.png
```

连同此前 4 张 down 基线，运行时共有 24 张 hurt/death 单帧；本批 20 张补缺状态已落盘、处理、导入并接入，当前只剩逐张视觉、中心枢轴、脚底基线最终验收及公开再分发授权确认。

### 当前本地 MVP 引用状态

2026-08-28 的本地五房间 MVP 已引用本批运行时文件，2026-08-29 完成两轮画面修订，2026-08-30 已生成、派生并接入右墙出口与专用弹刀两项特效；所有文件仍只存在于未提交的本地工作树中，不代表已经获得公开再分发许可。

| 运行时资源组 | 当前使用状态 | 运行时入口 |
| --- | --- | --- |
| 玩家、普通敌人和 Boss hurt/death 状态 | 20 张补缺方向状态已导入并由 `facing` 动态选择，连同 4 张 down 基线共 24 张；`tests/mvp_smoke.gd` 已逐方向断言；待逐张视觉/中心枢轴/脚底基线最终验收；未授权公开 | `scripts/mvp/mvp_room_view.gd` |
| 小型心核、奖励祭坛 | 已显示在起始/复苏房与奖励房 | `scripts/mvp/mvp_room_view.gd` |
| 疾拍/守心回响图标 | 已显示在奖励选择与局内回响栏 | `scripts/mvp/mvp_controller.gd` |
| 满/空生命、蓄力、节奏护盾单图标 | 生命已显示在左上角，蓄力/护盾只在生效时显示；状态闭环已实现 | `scripts/mvp/mvp_controller.gd` |
| 四张房间背景 | 已用于奖励、困难、Boss 与复苏房 | `scripts/mvp/mvp_state.gd` |
| 专用右墙出口开启 4 帧特效 | 原图已生成下载，运行时 `assets/effects/fx_room_exit_portal_sheet.png` 已按 192×64/RGBA 派生并接入；程序光晕、玩家冲门补间与扫屏光条作为叠层保留 | `scripts/mvp/mvp_room_view.gd` |
| 专用无文字弹刀 4 帧特效 | 原图已生成下载，运行时 `assets/effects/fx_weapon_clash_sheet.png` 已按 128×32/RGBA 派生并接入；双方 attack 帧、方向斩击与通用冲击环作为叠层保留 | `scripts/mvp/mvp_room_view.gd` |
| `mvp_state_icons.png` 组合 atlas | 未直接引用；当前仅为派生/预览文件 | 无 |

本批基础素材的 16 个 inbox 原图实际都是 RGB；方向状态源文件的模式以 `derived_manifest.json` 记录为准。“透明请求”是生成参数而不是原图事实。处理脚本输出的单对象、精灵和 HUD 运行时文件才是带二值 alpha 的 RGBA。当前状态应区分为“本地已引用”“用户试玩验收”“可公开发布”三层；方向状态的逐张视觉/锚点验收与公开授权仍未完成。

### 四张房间原图提示词

以下是四张房间的完整提示词，已将 `GENERATION_QUEUE.md` 中的共用风格尾缀展开写入。

#### `room_reward_raw.jpeg`

```text
Create a top-down 2D pixel-art reward room in the same Withered Forest / Heart-Core Ruins game. Preserve the broad composition and palette of the attached room reference. Leave a large clear walkable floor area for an 8x5 combat-grid layout. Place two small empty stone pedestals in the upper half, with subtle cyan heart-core echo light and root-vein floor markings. The room should communicate a quiet choice shrine, not a battle arena. No characters, monsters, UI, text, logos, or blocked central path.
Original 2D top-down pixel art for the same Withered Forest / Heart-Core Ruins rhythm dungeon game. Strict crisp pixel art, hard stepped 1-pixel edges, limited 24-32 color palette: charcoal green, slate stone, muted crimson, cyan life energy, and small amber highlights. Readable at small gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no 3D, no isometric perspective, no anime style, no text, no logo, no watermark.
```

#### `room_hard_raw.jpeg`

```text
Create a top-down 2D pixel-art difficult combat room in the same Withered Forest / Heart-Core Ruins game. Preserve the attached room reference style and keep the 8x5-grid floor readable. Add sparse cracked floor tiles, thorn-like hazard edges and slightly stronger crimson root veins, while keeping most cells open for movement. No characters, monsters, UI, text, logos, or dense decoration that hides the grid.
Original 2D top-down pixel art for the same Withered Forest / Heart-Core Ruins rhythm dungeon game. Strict crisp pixel art, hard stepped 1-pixel edges, limited 24-32 color palette: charcoal green, slate stone, muted crimson, cyan life energy, and small amber highlights. Readable at small gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no 3D, no isometric perspective, no anime style, no text, no logo, no watermark.
```

#### `room_boss_raw.jpeg`

```text
Create a top-down 2D pixel-art boss arena in the same Withered Forest / Heart-Core Ruins game. Preserve the attached room reference palette and readable rectangular arena. Place a large restrained heart-shaped life-core recess at the far side, with ancient wall roots and cyan energy fissures. Keep the central floor open for a one-cell boss and player, with clear entrance and exit silhouettes. No characters, monsters, UI, text, logos, or isometric perspective.
Original 2D top-down pixel art for the same Withered Forest / Heart-Core Ruins rhythm dungeon game. Strict crisp pixel art, hard stepped 1-pixel edges, limited 24-32 color palette: charcoal green, slate stone, muted crimson, cyan life energy, and small amber highlights. Readable at small gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no 3D, no isometric perspective, no anime style, no text, no logo, no watermark.
```

#### `room_restored_raw.jpeg`

```text
Create a top-down 2D pixel-art restored heart-core room using the attached room reference composition. Keep the same walls and floor readability, but show the transition from decay to life: stable cyan heart-core glow, a few newly growing green vines, small revived plants and slightly richer but still limited colors. Leave the combat floor open. No characters, UI, text, logos, or photorealistic effects.
Original 2D top-down pixel art for the same Withered Forest / Heart-Core Ruins rhythm dungeon game. Strict crisp pixel art, hard stepped 1-pixel edges, limited 24-32 color palette: charcoal green, slate stone, muted crimson, cyan life energy, and small amber highlights. Readable at small gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no 3D, no isometric perspective, no anime style, no text, no logo, no watermark.
```

### 处理与本地 QA

- `python3 tools/process_generated_assets.py --mvp-only` 会为本批导出 37 个运行时 PNG（24 张 hurt/death 单帧、2 个物件、2 个回响、4 个 HUD 单图标、1 个组合 atlas 和 4 张房间背景），并更新 `derived_manifest.json`；清单字段为 `sources` 与 `generated`。
- 本批已完成生成、下载、处理和本地视觉检查。运行时单对象、方向状态精灵和 HUD 文件按规格为 RGBA 且使用二值 alpha；四个房间派生背景为 960x540 RGB PNG。20 张补缺方向状态的路径、尺寸、模式和 SHA-256 均已写入清单。
- 本批已接入本地五房间 MVP，并完成 960x540 Metal 窗口画面检查；这仍不是用户试玩验收、教师验收或公开发布许可。相关素材尚未提交或推送，方向状态还需逐张视觉/枢轴/脚底基线最终验收，公开再分发授权仍待企业服务条款和学校合作约定复核。

## 2026-08-31：第一层右心房原图生成完成台账

本批在 <https://bhai.elex-tech.com/image/100> 使用学校 BHai 页面生成。2026-08-31 初始右心房背景使用 `Seedream 5.0 Pro / 2K / 16:9 / 文生图 / 1 张`；2026-09-01 重生背景改用 `Seedream 5.0 Pro / 最高质量 / 2K / 16:9 / 图生图 / 1 张` 并上传已校准的 `assets/backgrounds/heartcore_forest_room.png`。其余主表、状态、特效和物件使用 `gpt-image-2 / high / 2K / 1:1 / 1 张`。主表与特效为文生图；单帧 hurt/death 通过对应主表的站内“以图生图”生成。页面未显示 seed，不以推测补写。续批 12 张状态原图的可重建完整提示词见 [`FIRST_LAYER_STATE_PROMPTS.md`](FIRST_LAYER_STATE_PROMPTS.md)。

| 原始文件 | 实际尺寸 / 模式 | SHA-256 | 2026-08-31 原图完成节点状态 |
| --- | --- | --- | --- |
| `inbox/scenes/room_right_atrium_raw.jpeg` | 2560x1440 / RGB JPEG | `e30aa7424842d470a91ce38ca58d9fe5b0ed49334aeec0f5a0c28001a2fb2c89` | BHai 候选 4 于 2026-09-01 14:00:53 CST 落盘，15:11:19 CST 提升为正式路径；960x540 叠加复核确认 11x6、60px、原点 `(153,95)` 与右墙门 `(850,270)`；已派生/接入 `assets/backgrounds/heartcore_forest_room.png` |
| `inbox/objects/heart_core_v2_raw.png` | 2048x2048 / RGB PNG | `74234b84a0c257aea38e35aead0fcec6a6c8c58ebb88d5343b1eefaac24a3cd5` | 已下载；形状非解剖/非恐怖；未派生/接入/用户验收 |
| `inbox/sprites/spit_slug_sheet_raw.png` | 2048x2048 / RGB PNG | `5af2c000068961b7c1bfef97ce211ef26f0d7368db6a7f7c3bb6812273b6333b` | 4x4 主表已下载并初检；未派生/接入 |
| `inbox/sprites/venous_glutton_sheet_raw.png` | 2048x2048 / RGB PNG | `89582cfe281eb1253631799519d466cff76dc494213c5482f5666a59367e3c76` | 4x4 主表已下载并初检；未派生/接入 |
| `inbox/effects/mud_projectile_sheet_raw.png` | 2048x2048 / RGB PNG | `454690ee7d51df4c722c1608fd1bdf303fced7419f0099619ed6dcae30192074` | 四帧已下载并初检；未派生/接入 |
| `inbox/effects/blood_sediment_hazard_raw.png` | 2048x2048 / RGB PNG | `94c3092e4ded1e7f61804fb50d793b6f33cd62f17b0c236f2d7c7ad9dbd92f0c` | 四帧已下载并初检；未派生/接入 |
| `inbox/effects/venous_suction_raw.png` | 2048x2048 / RGB PNG | `8e1daa1f72934c05c3bf450c46a42d25879f6fb6e1d3ea6df3382ef372d28b6d` | 第二次严格重生成的单行四帧选中版；未派生/接入 |
| `inbox/effects/venous_suction_candidate1_raw.png` | 2048x2048 / RGB PNG | `9e660993f649a66bc93ec9e770b516a4defbb8903f5ecf684f503b8ad44f3084` | `REJECTED_CANDIDATE`；下方含额外无关碎图，只保留溯源，不派生/接入 |
| `inbox/objects/blood_vessel_elevator_raw.png` | 2048x2048 / RGB PNG | `14540db80e85058977e5f2a35cdb6d464b681f01baa4db23d58acc026e7c5992` | 已下载并初检；未派生/接入 |
| `inbox/sprites/spit_slug_hurt_down_raw.png` | 2048x2048 / RGB PNG | `8845ee475b3c833849637239497d7af61226d844d313497919fa0ceff72f047c` | 已下载并初检；未派生/接入 |
| `inbox/sprites/spit_slug_death_down_raw.png` | 2048x2048 / RGB PNG | `fbff3a770d89c1f741b5a048e2432e5be44562299eccd6ff83cbb9dc473f8662` | 2026-09-01 13:57:45 CST 重生；正面朝下、中央下缘破裂喷口、双眼对称、低矮坍塌通过原图级初检；已派生/接入 `assets/sprites/spit_slug_death_down.png` |
| `inbox/sprites/spit_slug_hurt_left_raw.png` | 2048x2048 / RGB PNG | `820a4e418c15ef971d15df68ac6007bbdfa9eb06a873efca1cab7d56329fd7d6` | 已下载并初检；未派生/接入 |
| `inbox/sprites/spit_slug_death_left_raw.png` | 2048x2048 / RGB PNG | `f3286dc681203b9133d406e4f3ab5b5478dfe28ed125054e87221c8b2e509ee3` | 已下载并初检；原暂停节点最后一张；未派生/接入 |
| `inbox/sprites/spit_slug_hurt_right_raw.png` | 2048x2048 / RGB PNG | `ff2be62469064c8eaefe6a3c08c15a4b7d49d20f15fdc2c0638bbef0a62a29de` | 22:28:55 CST 落盘；右向受击通过原图初检；未派生/接入 |
| `inbox/sprites/spit_slug_death_right_raw.png` | 2048x2048 / RGB PNG | `6ef72592df09613e0c98a7dbcb8a03833bcf3bdba59363a0c11ab4ef993a14e7` | 22:33:25 CST 落盘；右向死亡通过原图初检；未派生/接入 |
| `inbox/sprites/spit_slug_hurt_up_candidate1_raw.png` | 2048x2048 / RGB PNG | `61d0dae0804e897d370ad7d6f484a0e6ce93089fa5247c8888a0823ba474c934` | `REJECTED_CANDIDATE`；喷口/双眼位于下侧，读作 down；只保留溯源 |
| `inbox/sprites/spit_slug_hurt_up_raw.png` | 2048x2048 / RGB PNG | `7ca373da7e876375393037fde5f0fda98cc9b14290930a4526ebb16e5ce72dec` | 22:44:44 CST 落盘；严格上向重生成后通过原图初检；未派生/接入 |
| `inbox/sprites/spit_slug_death_up_raw.png` | 2048x2048 / RGB PNG | `2f904cca7f3b29fbc49c80c920568c0e1ec1b40e314645194859094372a9407a` | 22:49:18 CST 落盘；上向死亡通过原图初检；未派生/接入 |
| `inbox/sprites/venous_glutton_hurt_down_raw.png` | 2048x2048 / RGB PNG | `3d0e7122ac4b46f549e4d78440c29f2291ac344be0ab7b12e736d4888b9865f8` | 22:54:28 CST 落盘；朝下受击通过原图初检；未派生/接入 |
| `inbox/sprites/venous_glutton_death_down_raw.png` | 2048x2048 / RGB PNG | `50a752f5d0e48dd216360d900f8ecda2e6f75cfb92f08a7ff8dc9fc4e7a98362` | 22:59:13 CST 落盘；朝下死亡通过原图初检；未派生/接入 |
| `inbox/sprites/venous_glutton_hurt_left_raw.png` | 2048x2048 / RGB PNG | `8a14ba79df6b7c16d36152ee0192702d1d65d7c82fb057420a4014d964781858` | 23:04:34 CST 落盘；左向受击通过原图初检；未派生/接入 |
| `inbox/sprites/venous_glutton_death_left_raw.png` | 2048x2048 / RGB PNG | `f22a7fdc35aa48ea51275ffe198299f0dbc4be65c44bc302408748a129202e36` | 23:09:44 CST 落盘；左向死亡通过原图初检；未派生/接入 |
| `inbox/sprites/venous_glutton_hurt_right_raw.png` | 2048x2048 / RGB PNG | `20cff8f9180cceeb03f4d06638be01484d15e7b9ec02e33c65c7a58b3b442a0f` | 23:14:49 CST 落盘；右向受击通过原图初检；未派生/接入 |
| `inbox/sprites/venous_glutton_death_right_raw.png` | 2048x2048 / RGB PNG | `57e30219aec32b3a30780ddb0426cbf7dde3db07f122d0409547afde3724fa67` | 23:19:31 CST 落盘；右向死亡通过原图初检；未派生/接入 |
| `inbox/sprites/venous_glutton_hurt_up_raw.png` | 2048x2048 / RGB PNG | `be0694fcafdf64c9bae0d2e5ea8dae20c21c32468e117eb448b898ff0d68b918` | 23:25:02 CST 落盘；上向受击通过原图初检；未派生/接入 |
| `inbox/sprites/venous_glutton_death_up_raw.png` | 2048x2048 / RGB PNG | `110ef925240f6965d8eb595c35c90bf550b8eb8b68a61106d1daada2d6dc5661` | 23:30:10 CST 落盘；上向死亡通过原图初检；未派生/接入 |

第一层原图生成批次现已完整到齐：喷吐者四方向 hurt/death 8 张、泥鳃四方向 hurt/death 8 张，连同此前背景、心核 V2、两类主表、三组特效和血脉升降梯原图均已落盘。续批另保留 1 张错误朝向的喷吐者 `hurt_up` 候选，只用于溯源。全部 PNG 虽在提示词中请求透明，但实际为 RGB 棋盘格或白底；原图保持不改。这一段仅记录 2026-08-31 的原图完成节点；后续派生与接入状态见下方 2026-09-01 记录。

## 2026-09-01：第一层选中素材派生、Godot 接入与视觉审核

- `tools/process_generated_assets.py --mvp-only` 新增第一层专用派生流程：喷吐者/泥鳃 4×4 主表、16 张原图状态、3 组四帧特效、心核 V2 和血脉升降梯均输出固定逻辑尺寸、RGBA 与二值 alpha；本次也将右心房背景派生为 960x540 RGB PNG、将喷吐者 `death_down` 派生为 32x32 RGBA；当前 `derived_manifest.json` 共记录 77 个原图来源、99 个派生 PNG。
- `MvpRoomView` 已按角色类型选择 `spit_slug_sheet.png` 和 `venous_glutton_sheet.png`，四方向 hurt/death 按 `facing` 动态选取；泥浆弹和血沉危险格四帧特效已在逻辑对应时机播放。2026-09-02 按用户反馈删除向心吸附机制后，`venous_suction_sheet.png` 保留为已派生历史素材，但不再被运行时代码引用。
- `heart_core_v2.png` 已替换起始房心核与结算面板心核；`blood_vessel_elevator.png` 已替换升降梯房的旧心核染色占位。
- `tests/first_layer_assets_smoke.py` 对尺寸、RGBA、二值 alpha、每帧非空、单帧色数上限、manifest 与运行时引用输出 `FIRST_LAYER_ASSETS_OK`；`tests/mvp_smoke.gd` 已增加喷吐者和泥鳃新状态路径回归。
- Godot AI MCP 3.2.4 通过真实 Godot 4.7.2 编辑器连接检查起始房、困难房、Boss 房和升降梯房；2026-09-02 再次捕获无框泥浆弹/危险格和 Boss 三格扇扫蓄力，游戏/编辑器日志无错误。旧向心吸附截图只属于被取代的历史实现。

两项缺口已按 2026-09-01 用户授权完成原图重生、确定性派生与 Godot 接入：

1. 右心房背景正式原图为候选 4，缩到 960×540 后以预期边界叠加复核确认连续 11×6 大格、60px 步长、原点 `(153,95)`、地面范围 `x=153..813 / y=95..455` 和右墙门 `(850,270)`；已替换运行时 `assets/backgrounds/heartcore_forest_room.png`。旧不合格原图由 `room_right_atrium_candidate1_raw.jpeg` 保留，候选 2、3、4 均保留为独立溯源文件。
2. 喷吐者 `death_down` 正式原图为新重生结果，正面朝下特征明确；已替换运行时 `assets/sprites/spit_slug_death_down.png`，旧不合格图保留为 `spit_slug_death_down_candidate1_raw.png`，第一次重生结果保留为 `spit_slug_death_down_candidate2_raw.png`。

### 2026-09-01：两项不合格素材重生账本

| 正式原图 | BHai 参数 | 实际尺寸 / 模式 | SHA-256 | 原图级检查 |
| --- | --- | --- | --- | --- |
| `inbox/scenes/room_right_atrium_raw.jpeg` | Seedream 5.0 Pro / 最高质量 / 2K / 16:9 / 图生图 / 1；参考 `assets/backgrounds/heartcore_forest_room.png` | 2560x1440 / RGB JPEG | `e30aa7424842d470a91ce38ca58d9fe5b0ed49334aeec0f5a0c28001a2fb2c89` | 候选 4；缩放与坐标叠加确认 11x6 大格、60px、原点 `(153,95)`、右墙门约 `(850,270)`；已派生为 `assets/backgrounds/heartcore_forest_room.png`（960x540 RGB，`fbb516aeec1e21e1f9aca81785aff9b6d4f7f851432b002357db0b73ed351f92`）并接入起始/普通房 |
| `inbox/sprites/spit_slug_death_down_raw.png` | gpt-image-2 / high / 2K / 1:1 / 图生图 / 1；参考 `spit_slug_sheet_raw.png` 结果卡 | 2048x2048 / RGB PNG；棋盘格背景 | `fbff3a770d89c1f741b5a048e2432e5be44562299eccd6ff83cbb9dc473f8662` | 正面朝下；中央下缘破裂喷口；双眼位于喷口上方且对称；低矮坍塌；已派生为 `assets/sprites/spit_slug_death_down.png`（32x32 RGBA，`be30c0699304cd39b62dbba3dc1a75229a978a0b5df0369892564d9c4775eb35`）并接入 `MvpRoomView` |

保留的失败/较弱候选：背景 `room_right_atrium_candidate1_raw.jpeg`（旧目标副本，`6cdf68fd51d29502f8a91f9da1017454e45bfc5cac297d93cc5e9722042f3666`）、`candidate2`（`3bce9b9df68759fab32d45ea2cd0cd994404f9fa9171827d1620ac46baaf4a7a`）、`candidate3`（`835dcd09aca3667fa2a8795705a378094ce2c1ec675766ae4d3bfdc80324c6d9`）；喷吐者 `spit_slug_death_down_candidate1_raw.png`（旧错误方向，`b4c5ca063a2b794d03889bc3325d6054468e33cb5bd87e8d4650d5179b5adee8`）与 `candidate2`（方向正确但死亡特征偏弱，`a77f8f8ec93403258d9d36b44bbc1d0eb3c697e0ad2755ceb30d2db9295d7c0d`）。候选仅保留溯源，不派生、不接入。

本次已完成“生成、下载、原图参数/内容复核、确定性派生、Godot 导入/运行时接入和回归验证”，不等于用户视觉验收、Windows 实机验收或企业生成素材已获公开再分发授权；本轮未提交、未推送、未开始第二层。

## 2026-09-01：第 2～4 层原图生成批次（进行中）

本批按主策划案与 [`GENERATION_QUEUE.md`](GENERATION_QUEUE.md) 通过学校 BHai 页面 `<https://bhai.elex-tech.com/image/100>` 生成，只处理第 2～4 层且不重复玩家、奖励/HUD、出口、弹刀、能量回流、血脉升降梯和已存在复苏房素材。完整提示词与模板见 [`UPPER_LAYERS_GENERATION_PROMPTS.md`](UPPER_LAYERS_GENERATION_PROMPTS.md)。第四层普通敌人仍是主策划未定项，本批不擅自生成。

当前硬边界：所有 79 张已定义选中原图到齐前，不运行去背景、裁切、缩放或任何运行时派生，不更新 `derived_manifest.json`，不导入或接入 Godot。以下 PNG 即使请求透明，实际仍按下载文件记录为 RGB 棋盘格。

### 当前选中原图

| 原始文件 | BHai 参数 | 实际尺寸 / 模式 | SHA-256 | 原图级检查 |
| --- | --- | --- | --- | --- |
| `inbox/sprites/gear_stalker_sheet_raw.png` | `gpt-image-2 / high / 2K / 1:1 / 图生图 / 1`；以 `spit_slug_sheet_raw.png` 仅约束 4×4 布局 | 2048x2048 / RGB PNG | `9025beb36a919c033df662a9498dd2845f40c4aef9e29ab43e0968ded1f51de4` | 2026-09-01 10:20:24 CST 落盘；完整 4×4/16 格；down/left/right/up 四行与 idle/patrol1/patrol2/charge 四列可读；身份与配色通过；未派生/接入 |

### 当前拒绝候选

| 候选文件 | 参数与实际尺寸 | SHA-256 | 拒绝原因 |
| --- | --- | --- | --- |
| `inbox/scenes/room_right_ventricle_candidate1_raw.jpeg` | Seedream 5.0 Pro / 2K / 16:9 / 文生图；2560x1440 / RGB JPEG | `c5dec316e96ef695f54b4e84733d7da1ddeb9a67d8b213c0ded033793ae29e4f` | 主题与门洞可读，但大地砖不是精确 11×6 |
| `inbox/scenes/room_right_ventricle_candidate2_raw.jpeg` | Seedream 5.0 Pro / 2K / 16:9 / 文生图；2560x1440 / RGB JPEG | `fbcdffc2d6d691355d309b5ab702195df336953c9005345c15f1b456edb945cf` | 强调 66 格后仍生成更细密网格，且画面过亮 |
| `inbox/scenes/room_right_ventricle_candidate3_raw.jpeg` | Seedream 5.0 Pro / 2K / 16:9 / 图生图；2560x1440 / RGB JPEG | `c77854c3469977bc4f2e7542f0f7e9ebaff0c2ca91e7d15ad8336aa103db30f3` | 上传校准背景后仍细分参考地砖，未保持 11×6，也未形成可用右墙门 |
| `inbox/sprites/gear_stalker_sheet_candidate1_raw.png` | gpt-image-2 / high / 2K / 1:1 / 文生图；2048x2048 / RGB PNG | `aa90588ab06d2dce50e5cb8fe16edf121460f54f9dc295764b6f675033be4855` | 只有 4×3，缺少 up 行 |
| `inbox/sprites/gear_stalker_sheet_candidate2_raw.png` | gpt-image-2 / high / 2K / 1:1 / 严格文生图；2048x2048 / RGB PNG | `199b6f5cb71224ea93e28a2665e4b9be1bfd994e74735d90744feeae15ada285` | 仍只有 4×3，缺少 up 行 |
| `inbox/sprites/gear_stalker_sheet_candidate3_raw.png` | gpt-image-2 / low / 1K / 1:1 / 图生图；1024x1024 / RGB PNG | `f4ac0de710a46b6995ddf68b47e2a6ebc7c87c67e5e72bc4fdf8a4dd95ac271a` | 布局与内容为完整 4×4，但切换模式后页面参数被重置成 low/1K，不符合 high/2K 硬要求 |

页面未显示 seed，不以推测补写。右心室背景正式目标仍缺；其三个候选只保留溯源，不派生或接入。

## 授权边界

这些图像由学校合作企业服务生成。当前仓库保存了来源页面、日期、模型、参数、提示词和文件哈希，但没有把企业服务条款或学校合作协议复制到项目中。是否允许公开 GitHub 再分发、课程展示和后续商业使用，应以企业页面当前条款及学校合作约定为准；在确认前不要把企业原图或派生图推送到公开仓库。企业生成内容也仍需人工检查潜在的第三方相似性。

本目录的原始图与运行时派生图目前只在本地工作区；20 张补缺方向状态及此前 4 张 down 基线已由正式 MVP 的 `RoomView`、控制器和房间状态引用，但仍未提交或推送 Git。现有 atlas 与方向状态仍需逐张检查脚底基线和水平中心，运行时使用校正表暂时对齐；公开前仍需完成授权确认和逐像素复核，不能把“本地可运行”写成“允许公开再分发”。

## 2026-08-28 方向状态补缺记录与验收状态

本轮方向状态补缺已完成资产落盘闭环：玩家/普通敌人 left/right/up 的 hurt/death 共 12 张，Boss down/left/right/up 的 hurt/death 共 8 张，共 20 张补缺方向状态运行时 PNG。它们均已由 `tools/process_generated_assets.py --mvp-only` 处理到 `assets/sprites/`，存在对应 `.import` 文件，写入 `derived_manifest.json`，并由 `scripts/mvp/mvp_room_view.gd` 按 `facing` 接入；`tests/mvp_smoke.gd` 的逐方向状态检查覆盖这些路径。这里的“完成”仅表示落盘、处理、导入和接入，不等于逐张视觉/中心枢轴/脚底基线最终验收或公开授权。

本轮先在 BHai 工作页完成参数恢复（图生图、`gpt-image-2`、`high`、2K、1:1、单张）并将 Chrome 的“自动下载项”限定为 `bhai.elex-tech.com` 站点允许。当前可直接追溯到 BHai 下载记录的 2K 原图为：

| 原始文件 | 说明 | SHA-256 |
| --- | --- | --- |
| `inbox/sprites/player_hurt_left_raw.png` | 玩家左向受击；BHai 图生图；2048x2048 RGB | `6a4adaca249c8d2b7832d7769a73a910cc2df0b176fe59b2a60669e53ccef814` |
| `inbox/sprites/player_hurt_right_raw.png` | 玩家右向受击；BHai 图生图；2048x2048 RGB | `c5a97cd96db7279d4fd31d7c04b8f437afa9dca83fa02f6b8009d96dfa861375` |

其余方向状态源文件与每个运行时文件的尺寸、模式和 SHA-256 以 `derived_manifest.json` 为准；页面未留存的逐图 seed 或独立会话编号不据浏览器控制日志推断。所有企业生成素材的公开再分发授权仍待确认。

## 2026-09-04：按用户要求清理无用旧素材

已删除 86 个本地文件（旧候选原图及 `.import`、旧 Corewarden Boss 资源、被替代的旧心核、已取消的血脉升降梯/向心吸附素材，以及未使用的心核近景派生图）。本次清理不涉及当前第一层运行时正在使用的素材，也没有删除尚未生成的第 2～4 层任务项。

特别说明：截图中的图是 BHai 已生成的“初始界面背景”预览（`title_screen_background_raw.jpeg` 目标），不是项目中的已下载原图；截至 2026-09-04，该文件已从用户 Downloads 复制到 `inbox/scenes/`，原图保持未修改；实际文件内容为 2560x1440 RGB PNG（扩展名沿用队列要求）。
## 2026-09-04：奖励图标与上层 Boss 攻击特效原图批次

本批按用户授权通过 BHai Chrome 页面生成并立即下载，统一参数为 `gpt-image-2 / high / 2K / 1:1 / 文生图 / 1 张`；页面未显示 seed。终端实测所有新增文件为 `2048x2048 / RGB PNG`，均无 alpha；奖励图标视觉初检为单个居中图标，特效视觉初检为单行四个内容组。BHai 的透明请求实际返回棋盘格 RGB 原图，以下文件保持原样，尚未派生、切帧、接入 Godot 或公开。

| 原始文件 | SHA-256 | 文件系统记录时间 | 原图级检查 |
| --- | --- | --- | --- |
| `inbox/items/impact_echo_raw.png` | `ba85ab9c1326931d6e108847e4c6e852c1ee525e8dc897158dfdbaaf381687c4` | 02:33:50 | 单图标，余震冲击语义通过初检 |
| `inbox/items/vigor_echo_raw.png` | `509701e94e03ff5bc7b6abf7031b195b2af7d8fc5f0d973dedea0dd3c0ec7fed` | 02:38:22 | 单图标，心室扩容语义通过初检 |
| `inbox/items/pulse_echo_raw.png` | `870cd41baa1cc91d68de0956c5d6bad7a676d77127e64405d6b969c713512212` | 02:42:50 | 单图标，回响修复语义通过初检 |
| `inbox/effects/piston_strike_sheet_raw.png` | `c5c565b8235e5d7c958bc46cd80fa2990fb4259e4c7f981254e64b6bf9d84b9d` | 02:47:15 | 单行四帧，冲压→命中→回弹/眩晕 |
| `inbox/effects/oxygen_charge_sheet_raw.png` | `b94de39dd644d1c4c5fe1cf6c78e4d38ce49a39aede39db3f72c5f7d68154eaa` | 02:50:12 | 单行四帧，3×3→5×5→危险→冲击 |
| `inbox/effects/ground_spike_wave_sheet_raw.png` | `ddee0dafbb2e378886c2ae2b73718dff5c2762fa7f04b8f0fab671217a98d83a` | 02:53:46 | 单行四帧，裂缝→升刺→高刺→崩解 |
| `inbox/effects/defibrillation_countdown_sheet_raw.png` | `54e3d98c5e84cede3e0b4a74540bbd02ee8bec703f8aeff6eeb3902eb884a1d8` | 02:57:35 | 单行四帧，除颤预警逐拍升级 |
| `inbox/effects/noise_projectile_sheet_raw.png` | `7979fb64ad270a2bc4dcb740f21bb8b88033d44104b1c15c1d573b5fe7d466e5` | 03:01:01 | 单行四帧，单一杂音弹四状态 |
| `inbox/effects/pulmonary_jet_sheet_raw.png` | `6885e819047c22d556df2e0368d75edf8243678757242caa20c4a7205499fac4` | 03:06:38 | 单行四帧，方向线→蓄压→喷流→余波 |

