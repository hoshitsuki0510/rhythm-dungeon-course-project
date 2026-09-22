# BHai 美术生成任务单

更新时间：2026-09-04

这份任务单只针对通过学校合作企业 BHai 页面生成的位图素材。项目的玩家、窃能幼体、通用房间背景、遗迹瓦片和战斗特效 atlas 继续作为通用基线；2026-09-01 已接入第一层心核 V2、泥浆喷吐者、静脉吸附者·泥鳃、三组特效与血脉升降梯。文末各批次记录与“重生结果”区分生成、派生和接入状态；占位、未用户验收和未授权公开的状态不能误记为正式公开完成。


## 2026-09-04 上层 Boss 素材到位并接入（用户授权的暂停生图例外）

本轮不继续生成普通小怪、房间背景或大量特效。另一生图会话已提供 3 张上层 Boss 原图；已按当前运行时兼容方案完成确定性去棋盘格、缩放与静态 4×4 atlas 派生，并接入正式 `MvpRoomView`。原图保持不改；由于每张原图是单个 Boss 立绘而不是完整四状态表，运行时 atlas 的 16 格暂时复用同一清理帧，状态差异由程序预警、受击/阶段逻辑表达。

| 状态 | 原始文件 | 原图事实 / SHA-256 | 派生运行时文件 | 派生规格 / SHA-256 |
| --- | --- | --- | --- | --- |
| DOWNLOADED + DERIVED + RUNTIME INTEGRATED | `inbox/sprites/piston_colossus_boss_raw.png` | 2048×2048 / RGB PNG / `2e92dd28e7f672d27db014e23e690f960bb2079736afca928c567e7ba74b7de3` | `assets/sprites/piston_colossus_sheet.png` | 256×256 / RGBA / 4×4 静态 atlas / `5a72c9e3add641860e213cca0d724d79aee18fd2583099bbf320f4ce48f9227a` |
| DOWNLOADED + DERIVED + RUNTIME INTEGRATED | `inbox/sprites/oxygen_reservoir_boss_raw.png` | 2048×2048 / RGB PNG / `8825a19dbeb5c8f5d12893d3615975dffe8c7ab89ff31e87e5c100dcccd192a7` | `assets/sprites/oxygen_reservoir_sheet.png` | 256×256 / RGBA / 4×4 静态 atlas / `91f0b12d57c6ca879708679e7557acdd9ee2573b3a838cbb6aace00d6e80349` |
| DOWNLOADED + DERIVED + RUNTIME INTEGRATED | `inbox/sprites/arrhythmia_boss_raw.png` | 2048×2048 / RGB PNG / `f6150e9d32ba2689b871553245ce96f032dbe5a1a8cf4416651881c6c74ed533` | `assets/sprites/arrhythmia_boss_sheet.png` | 256×256 / RGBA / 4×4 静态 atlas / `8d7b5522601c88b23f7b99843beaa20e3589b8dbd3ce50f19c70402f6c497e6a` |

验证证据：Godot 4.7.2 headless editor 成功导入 3 张派生 PNG；`tests/upper_layers_smoke.gd` 运行时断言 2F/3F/4F Boss 分别引用正确 atlas；macOS 显示驱动捕获确认 Boss 名称已只显示身份名称。

## 本轮缩减范围下的最少必要生成清单

以下按“先提升可玩闭环的视觉识别，再补机制表现”的顺序排列；其余队列保持 PENDING，不阻塞当前功能开发。

1. **P0：3 张楼层主背景（已完成派生与接入）**：2F、3F、4F 各 1 张，必须保持可读的 `11×6` 地面、边界和 Boss 房中央开放区。可先作为同楼层所有房间的复用背景，暂不生成 15 张独立房间背景。
2. **P1：3 张增益图标（已完成派生与接入）**：
   - `inbox/items/impact_echo_raw.png`：余震增幅
   - `inbox/items/vigor_echo_raw.png`：心室扩容
   - `inbox/items/pulse_echo_raw.png`：回响修复
   `tempo_echo_raw.png` 与 `guard_echo_raw.png` 已有；后三种已派生为 `assets/items/echo_impact.png`、`echo_vigor.png`、`echo_pulse.png` 并接入卡片/HUD。
3. **P1：3 张专用中央传送门（已完成派生与接入）**：2F 加压、3F 高氧、4F 终局共鸣各 1 组 4 帧；程序光晕仍作为叠加表现。
4. **P1：2F～4F Boss 攻击特效（已完成派生与接入）**：
   - `inbox/effects/piston_strike_sheet_raw.png`：2F 行/列冲压、命中与回弹
   - `inbox/effects/pulmonary_jet_sheet_raw.png`：3F 肺静脉喷流
   - `inbox/effects/oxygen_charge_sheet_raw.png`：3F 四拍充能与打断/爆发
   - `inbox/effects/ground_spike_wave_sheet_raw.png`：4F 地刺波
   - `inbox/effects/defibrillation_countdown_sheet_raw.png`：4F 四拍除颤预警
   - `inbox/effects/noise_projectile_sheet_raw.png`：4F 三向杂音弹
   程序预警、危险范围和攻击判定仍保留，生成特效作为叠加表现；原图保持不变。
5. **P2：3 张 Boss 完整 4×4 主表或最少 hurt/death 单帧**：当前已有静态 Boss atlas 可玩；只在需要提升阶段差异、受击和死亡表现时生成。

本轮明确不生成：2F～4F 普通小怪换皮、大量 hurt/death 单帧、全部独立房间背景、装饰和独立小特效。

## 本批状态与范围

2026-08-27 至 2026-08-28 已完成 **P0 四张朝下受击/死亡状态**，并完成一组已选 P1 视觉素材：四张房间背景、小型心核、奖励祭坛、两种回响与四个 HUD 状态图标；本轮还完成了 **20 张补缺方向 hurt/death 状态**（玩家/普通敌人 left/right/up 共 12 张，Boss down/left/right/up 共 8 张）。基础素材原图与方向状态源均已纳入处理清单，并已通过 `--mvp-only` 派生成运行时 PNG；具体原图、派生路径和状态见文末账本。

正式 MVP 现已有 `facing` 字段，并按 down/left/right/up 使用 4×4 玩家、普通敌人与 Boss atlas。20 张补缺方向 hurt/death 运行时文件已落盘到 `assets/sprites/`，由 `derived_manifest.json` 记录尺寸、模式与 SHA-256，Godot 已导入并由 `MvpRoomView` 按 `facing` 接入；`tests/mvp_smoke.gd` 已逐方向断言。这批角色方向状态不再是素材缺口，剩余是逐张视觉、中心枢轴、脚底基线最终验收及 BHai/企业生成素材公开再分发授权确认。已有四方向 idle/step/attack 主表、基础环境和瓦片不需要重生；现有战斗特效 atlas 仍保留。2026-08-30 已按队列生成并下载两项专用表现素材，并由确定性脚本导出运行时 PNG；两项派生图已接入 Godot，出口特效作为程序门框/能量叠层，弹刀特效与通用刀光/火花叠加，仍需专门窗口逐帧验收与授权确认。

### 2026-08-30 本轮专用特效生成结果

两项均在 <https://bhai.elex-tech.com/image/100> 的“文生图”页面完成，参数为 `gpt-image-2`、`high`、`2K`、`1:1`、单张 PNG。BHai 下载的 2K 原图实际为 RGB 并带可识别的浅色棋盘格；原图保持不改，由 `tools/process_generated_assets.py` 的 `fit_effect_sheet()` 去棋盘格、统一四帧枢轴、二值化 alpha 并缩放到队列规格。seed 未在页面显示，以下哈希以落盘文件为准。

原图落盘时间（中国标准时间）：出口 `2026-08-30 11:13:27`；弹刀 `2026-08-30 11:16:35`。

| 原始文件 | 原图事实 | 原图 SHA-256 | 派生运行时文件 | 派生规格 / SHA-256 |
| --- | --- | --- | --- | --- |
| `inbox/effects/fx_room_exit_portal_sheet_raw.png` | 2048x2048 / RGB；四帧横向构图；棋盘格背景 | `e3da1bf05a8f9e5fe47d63ec31b0ffd05668201f6c1f564eead1ee6bb12d6e8b` | `assets/effects/fx_room_exit_portal_sheet.png` | 192x64 / RGBA；alpha `{0,255}`；`07e88b32c50821a211dc1c1bea2e34438d9345c9b64bb4c1eeab21d71dc3d490` |
| `inbox/effects/fx_weapon_clash_sheet_raw.png` | 2048x2048 / RGB；四帧横向构图；棋盘格背景 | `1a92f3d390426a87964342b7e302d7f8bf48470feeebe8ced9812e3c9487220e` | `assets/effects/fx_weapon_clash_sheet.png` | 128x32 / RGBA；alpha `{0,255}`；`389b13aeba4ec6f8e9f60f5537d5a632941d45fe083c6339f13f9c07dff8e73a` |

已通过原图视觉检查（出口：封闭→裂隙→开门→稳定脉冲；弹刀：交叉刀光→接触星芒→冲击环→碎屑）以及运行时尺寸、四帧边界、RGBA 和二值 alpha 检查。两项运行时派生图已导入并接入 Godot MVP；仍需弹刀/转场逐帧窗口验收和公开再分发授权确认。

“已生成 / 下载 / 派生 / 本地引用 / 窗口初检”不等于用户或教师验收、Git 提交/推送，亦不等于公开再分发授权已经确认。

## 下载位置与命名

把 BHai 下载的**原始文件**按下面的目录保存，不要覆盖 `assets/` 中已有文件：

```text
assets/generated/bhai/inbox/sprites/
assets/generated/bhai/inbox/ui/
assets/generated/bhai/inbox/objects/
assets/generated/bhai/inbox/items/
assets/generated/bhai/inbox/scenes/
assets/generated/bhai/inbox/effects/
```

文件名必须使用表中名称。若网站自动命名，下载后只改文件名，不要自行裁剪、缩放或重新压缩。保留 2K 原图；后续由项目脚本统一裁切、去背景、量化 alpha 和写入哈希台账。

## BHai 参数预设

### P0/P1 透明精灵、道具、图标和特效

- 模式：图生图（有参考图时）；全新图标/特效可用文生图
- 模型：`gpt-image-2`
- 质量：`high`
- 分辨率：`2K`
- 横纵比：`1:1`
- 背景：透明 / true alpha
- 参考图强度：如页面提供，`0.25-0.40`；优先 `0.30`
- 随机种子：固定一个种子；若页面不提供，记录页面返回的 seed 或生成时间
- 输出：PNG

### P1 房间背景

- 模式：图生图
- 模型：`Seedream 5.0 Pro`
- 质量：页面可选的最高质量
- 分辨率：`2K`
- 横纵比：`16:9`
- 背景：不透明
- 参考图强度：如页面提供，`0.35-0.50`；优先 `0.40`
- 随机种子：固定一个种子
- 输出：PNG 或最高质量原图；不要使用带文字的版本

如果页面没有某个参数，保留其他参数即可；不要用低质量/快速模型替代。若透明背景选项不存在，先不要生成透明精灵，避免把棋盘格或实色背景带进角色边缘。

### BHai 图生图参考图尺寸

BHai 当前要求上传图片的宽和高都不得小于 `300px`。项目中的 `32x128` 运行时动作条不能直接上传；上传用参考图必须通过最近邻放大保留硬像素边缘，并且不能替换 Godot 运行时资源。

ART-GEN-001 已准备好上传版参考图：

```text
assets/generated/bhai/references/player_idle_down_ref_512.png
```

该文件是玩家朝下 idle 单帧的 `512x512` RGBA 最近邻放大版，只用于 BHai 图生图；提示词中的目标逻辑尺寸仍为 `32x32`。

## 共用风格尾缀

把下面文字粘贴到每个提示词末尾：

```text
Original 2D top-down pixel art for the same Withered Forest / Heart-Core Ruins rhythm dungeon game. Strict crisp pixel art, hard stepped 1-pixel edges, limited 24-32 color palette: charcoal green, slate stone, muted crimson, cyan life energy, and small amber highlights. Readable at small gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no 3D, no isometric perspective, no anime style, no text, no logo, no watermark.
```

如果 BHai 有单独的 negative prompt 栏，再粘贴：

```text
anti-aliased edges, blurry pixels, soft shadows, gradients, photorealistic, 3D render, isometric view, anime illustration, multiple characters, duplicate objects, spritesheet, grid labels, text, logo, watermark, checkerboard pattern, background scenery
```

没有 negative prompt 栏时，把这些限制保留在主提示词中。

## P0：已生成的 4 张角色状态图

### ART-GEN-001 玩家受击

- 保存为：`assets/generated/bhai/inbox/sprites/player_hurt_down_raw.png`
- 状态：已于 2026-08-27 生成并下载 1 个候选；原图验收记录见下方“P0 当前进度”
- 模式：图生图
- 上传参考图：`assets/generated/bhai/references/player_idle_down_ref_512.png`
- 生成数量：先做 4 个候选，选 1 个作为后续玩家状态的参考
- 提示词：

```text
Use the attached player sprite reference only for identity, silhouette, palette, center pivot, and ground baseline. Generate ONE single centered sprite, not a spritesheet and not a multi-frame layout. The playable hero is the same young rhythm warden in a short dark gray-green cloak, teal luminous heart-core pendant, muted crimson scarf accent, and compact resonant short blade. Facing down. State: a clear hurt pose immediately after a light hit, body slightly recoiled, pendant still visible, one restrained white-cyan impact highlight on the silhouette. Keep the entire character inside a 32x32 logical pixel gameplay frame, with balanced transparent padding and no external shadow. Preserve the same proportions as the reference.

[粘贴共用风格尾缀]
```

### ART-GEN-002 玩家死亡

- 保存为：`assets/generated/bhai/inbox/sprites/player_death_down_raw.png`
- 模式：图生图
- 参考图：优先使用 ART-GEN-001 选中的 2K 原图；没有时使用 `assets/generated/bhai/references/player_idle_down_ref_512.png`
- 提示词：

```text
Use the attached player sprite reference as a strict identity and palette reference. Generate ONE single centered sprite, not a spritesheet. The same young rhythm warden is facing down and is defeated: cloak folded low, pendant dimmed, body dissolving into a few small cyan and muted crimson pixel fragments. Keep the defeat readable without making a large explosion; no separate effect object and no ground shadow. Preserve the same center pivot and baseline, fit inside a 32x32 logical pixel gameplay frame, and leave balanced transparent padding.

[粘贴共用风格尾缀]
```

### ART-GEN-003 普通敌人受击

- 保存为：`assets/generated/bhai/inbox/sprites/enemy_hurt_down_raw.png`
- 模式：图生图
- 参考图：`assets/sprites/enemy_siphonling_sheet_idle.png`
- 生成数量：先做 4 个候选，选 1 个
- 提示词：

```text
Use the attached siphonling sprite reference only for identity, silhouette, palette, center pivot, and ground baseline. Generate ONE single centered sprite, not a spritesheet. The same small crawling siphonling enemy is facing down: twisted dark roots, mossy charcoal shell, four short clawed limbs, narrow cyan eyes, and a bright amber-red stolen energy core. State: a readable hurt recoil with a brief white-cyan impact flash, but keep the creature intact and recognizable. Fit inside a 32x32 logical pixel gameplay frame, with balanced transparent padding and no external shadow.

[粘贴共用风格尾缀]
```

### ART-GEN-004 普通敌人死亡

- 保存为：`assets/generated/bhai/inbox/sprites/enemy_death_down_raw.png`
- 模式：图生图
- 参考图：优先使用 ART-GEN-003 选中的图；没有时使用 `assets/sprites/enemy_siphonling_sheet_idle.png`
- 提示词：

```text
Use the attached siphonling sprite reference as a strict identity and palette reference. Generate ONE single centered sprite, not a spritesheet. The same small crawling siphonling is facing down and is defeated: the charcoal root shell is collapsing into a compact cluster of cyan and amber energy pixels, with a few restrained crimson root fragments. The result must read as a small enemy death state, not a large explosion and not a new creature. Preserve center pivot and baseline, fit inside a 32x32 logical pixel gameplay frame, and leave balanced transparent padding.

[粘贴共用风格尾缀]
```

## P1：已选视觉素材与仍延后的内容

下列房间、奖励和 HUD 素材已在本批完成，并已被本地五房间 MVP 引用；它们仍处于未提交、未推送、未确认公开授权的开发状态。保留提示词和参数，以便后续重做与像素/锚点复核。

### P1 原图已生成：心核模型 V2（替换候选）

- 状态：原图已生成并下载；2048x2048 / RGB PNG；尚未派生、接入或经用户视觉验收
- 原始下载：`assets/generated/bhai/inbox/objects/heart_core_v2_raw.png`
- 候选运行时：`assets/objects/heart_core_v2.png`
- 逻辑规格：单物件 `96x96`；`true alpha`；居中；派生后二值 alpha
- 参考：只参考 `assets/backgrounds/heartcore_forest_room.png` 中的心形主题和项目配色；不以现有 `assets/objects/heart_core.png` 的形状为参考

建议提示词：

```text
Generate ONE single centered transparent top-down pixel-art game object: a clean, stylized heart-shaped life core for the Withered Forest / Heart-Core Ruins rhythm dungeon. Use a simple, nearly symmetrical outer silhouette made from broad slate-stone shell shapes, with one compact cyan life-energy center. Add only three to five restrained muted-crimson root bands around the shell, using broad readable color blocks. It must feel ancient but calm and life-giving, not anatomical and not horrific. No gore, flesh, face, eyes, mouth, teeth, dense ribs, tentacles, branching white veins, altar, pedestal, background scenery, ground shadow, text, logo, watermark, duplicate object or checkerboard. True alpha background, centered with balanced padding, crisp hard pixel edges, readable after reduction to exactly 96x96 logical pixels, and limited to the project's charcoal-green, slate, cyan, muted-crimson and small amber palette.
[粘贴共用风格尾缀]
```

验收标准：缩小到 `96x96` 后仍有干净轮廓和紧凑青色核心；不呈现解剖/恐怖感；不与 Boss 轮廓混淆；必须经用户视觉确认后，才能替换当前 `heart_core.png` 的运行时引用。

### 房间背景（Seedream 5.0 Pro，图生图，2K，16:9）

参考图：`assets/backgrounds/heartcore_forest_room.png`。四个房间都要保持相近的墙体比例、地面可行走区域和低饱和调色；不要生成角色、怪物、UI 或文字。

#### `room_reward_raw.jpeg`

```text
Create a top-down 2D pixel-art reward room in the same Withered Forest / Heart-Core Ruins game. Preserve the broad composition and palette of the attached room reference. Leave a large clear walkable floor area for an 8x5 combat-grid layout. Place two small empty stone pedestals in the upper half, with subtle cyan heart-core echo light and root-vein floor markings. The room should communicate a quiet choice shrine, not a battle arena. No characters, monsters, UI, text, logos, or blocked central path.
[粘贴共用风格尾缀]
```

#### `room_hard_raw.jpeg`

```text
Create a top-down 2D pixel-art difficult combat room in the same Withered Forest / Heart-Core Ruins game. Preserve the attached room reference style and keep the 8x5-grid floor readable. Add sparse cracked floor tiles, thorn-like hazard edges and slightly stronger crimson root veins, while keeping most cells open for movement. No characters, monsters, UI, text, logos, or dense decoration that hides the grid.
[粘贴共用风格尾缀]
```

#### `room_boss_raw.jpeg`

```text
Create a top-down 2D pixel-art boss arena in the same Withered Forest / Heart-Core Ruins game. Preserve the attached room reference palette and readable rectangular arena. Place a large restrained heart-shaped life-core recess at the far side, with ancient wall roots and cyan energy fissures. Keep the central floor open for a one-cell boss and player, with clear entrance and exit silhouettes. No characters, monsters, UI, text, logos, or isometric perspective.
[粘贴共用风格尾缀]
```

#### `room_restored_raw.jpeg`

```text
Create a top-down 2D pixel-art restored heart-core room using the attached room reference composition. Keep the same walls and floor readability, but show the transition from decay to life: stable cyan heart-core glow, a few newly growing green vines, small revived plants and slightly richer but still limited colors. Leave the combat floor open. No characters, UI, text, logos, or photorealistic effects.
[粘贴共用风格尾缀]
```

### 奖励房物件与局内强化图标（gpt-image-2，图生图/文生图，high，2K，1:1，透明）

参考图可用 `assets/ui/hud_icons_cc0.png` 或当前房间背景；每次只生成一个对象，不要生成图标表。

- `reward_shrine_raw.png`：单个小型根系石质祭坛，设计尺寸 64x64 logical pixels。
- `tempo_echo_raw.png`：稳定节奏回响晶体，设计尺寸 24x24 logical pixels。
- `guard_echo_raw.png`：守心挡伤回响晶体，设计尺寸 24x24 logical pixels；不要与“吸附轻微失拍”的节奏护盾混为同一机制。
- `heart_full_raw.png`、`heart_empty_raw.png`：满血/空血，设计尺寸 16x16 logical pixels。
- `charge_raw.png`：一层蓄力，设计尺寸 16x16 logical pixels。
- `shield_ready_raw.png`：护盾可用，设计尺寸 16x16 logical pixels。

通用提示词：

```text
Generate ONE single centered transparent pixel-art game asset: [replace with the exact object above]. It must be readable after reduction to the stated logical pixel size, use the same charcoal-green, slate, cyan, muted crimson and amber palette, and have a clean silhouette with no outer panel. No text, letters, numbers, duplicate objects, scenery, checkerboard pattern, or watermark.
[粘贴共用风格尾缀]
```

16x16 UI 图标优先考虑 Pixelorama 手工绘制或已核实 CC0 图标；只有在需要统一心核造型时才使用生图。

## 已完成：MVP 动作表现补全（20 张方向状态）

当前玩家和普通敌人的四方向 idle/step/attack 已存在，Boss 的 phase 1/phase 2/attack 也已存在。下列 **20 张独立 hurt/death 方向帧** 已完成落盘、处理、导入并接入；清单保留源文件名与复核约束，后续只做逐张视觉/锚点验收或在授权明确后替换，不再作为待生成缺口：

```text
inbox/sprites/player_hurt_left_raw.png
inbox/sprites/player_hurt_right_raw.png
inbox/sprites/player_hurt_up_raw.png
inbox/sprites/player_death_left_raw.png
inbox/sprites/player_death_right_raw.png
inbox/sprites/player_death_up_raw.png

inbox/sprites/enemy_hurt_left_raw.png
inbox/sprites/enemy_hurt_right_raw.png
inbox/sprites/enemy_hurt_up_raw.png
inbox/sprites/enemy_death_left_raw.png
inbox/sprites/enemy_death_right_raw.png
inbox/sprites/enemy_death_up_raw.png

inbox/sprites/boss_hurt_down_raw.png
inbox/sprites/boss_hurt_left_raw.png
inbox/sprites/boss_hurt_right_raw.png
inbox/sprites/boss_hurt_up_raw.png
inbox/sprites/boss_death_down_raw.png
inbox/sprites/boss_death_left_raw.png
inbox/sprites/boss_death_right_raw.png
inbox/sprites/boss_death_up_raw.png
```

上述文件的处理与复核标准仍是：每张只放一个角色、一个状态和一个方向，不做 spritesheet；玩家/普通敌人逻辑尺寸为 32x32，Boss 为 64x64；提示词复用对应主表的身份、轮廓、配色和基线；Boss death 表现心核能量释放但不超出 64x64。缩回逻辑尺寸后依次验收：二值 alpha、完整轮廓、水平中心、脚底基线、与相邻攻击帧衔接、四方向身份一致性。

现有 `combat_effects_atlas.png` 已支撑 BPM 切换、攻击、命中、死亡和清房反馈；以下独立特效列为后续可替换项，不是核心阻塞：

```text
inbox/effects/fx_bpm_shift_raw.png
inbox/effects/fx_enemy_death_raw.png
inbox/effects/fx_room_clear_raw.png
```

### P1 当前需要：右墙出口开启多帧特效

2026-08-30 的 MVP 已把“进入下一房间”的出口坐标校准到背景右侧墙壁中央，并用程序光晕、玩家冲门补间和扫屏光条完成可玩过场。本轮已生成、派生并接入专用右墙出口开启动画，程序表现继续作为叠层：

```text
原始下载：assets/generated/bhai/inbox/effects/fx_room_exit_portal_sheet_raw.png
目标运行时：assets/effects/fx_room_exit_portal_sheet.png
逻辑规格：4 帧横向 spritesheet；每帧 48x64，总尺寸 192x64；true alpha；统一中心枢轴
观察方向：顶视角房间的竖直右侧墙门，门洞朝画面左侧；所有帧必须覆盖同一个右墙门位
帧序：封闭的暗红根系门印 -> 青色裂隙点亮 -> 门洞向左侧张开 -> 稳定的青绿色脉冲入口
限制：只画门洞/根系门框/能量，不画整面墙、地砖、角色、怪物、文字、数字、UI、阴影或棋盘格
```

建议提示词：

```text
Generate ONE exact horizontal 4-frame transparent pixel-art spritesheet for a right-wall room-exit portal in the Withered Forest / Heart-Core Ruins rhythm dungeon. Each frame is exactly 48x64 logical pixels, total layout 4 columns by 1 row, no gutters, and one identical center pivot. Top-down room view: the portal is mounted on a vertical wall at the right side of the screen and opens toward the left walkable floor. Frame 1: a sealed restrained crimson root-rune doorway. Frame 2: a narrow cyan life-energy fissure lights through the same doorway. Frame 3: the root frame parts and a dark cyan portal mouth opens toward the left. Frame 4: a stable open doorway with a compact cyan-green pulse and a few amber root highlights. Asset only: no complete wall, floor tiles, characters, monsters, labels, text, numbers, logo, watermark, shadow or checkerboard. True alpha background, crisp hard pixel edges, readable at 48x64, limited charcoal-green, slate, muted crimson, cyan and small amber palette.
[粘贴共用风格尾缀]
```

当前程序使用 `MvpRoomView` 的四帧出口节点，并保留程序光晕、玩家冲门补间和扫屏光条作为叠层；原图参数/哈希登记、二值 alpha 检查、运行时导出、Godot 导入和贴图接入均已完成，仍待转场逐帧窗口验收与授权确认。

### P1 当前仍需要：无文字弹刀多帧特效

2026-08-29 的 MVP 已能使用双方 attack 帧、程序补间、短暂停顿、后坐以及 `combat_effects_atlas.png` 中的通用方向斩击/白色命中火花表现弹刀，并已移除“弹刀”浮字。本轮已生成、派生并接入专用武器碰撞多帧特效，通用方向斩击/冲击环作为叠层保留：

```text
原始下载：assets/generated/bhai/inbox/effects/fx_weapon_clash_sheet_raw.png
目标运行时：assets/effects/fx_weapon_clash_sheet.png
逻辑规格：4 帧横向 spritesheet；每帧 32x32，总尺寸 128x32；true alpha；统一中心枢轴
帧序：双向刀光交叉 -> 高亮接触星芒 -> 青色/琥珀冲击环扩开 -> 少量像素碎屑消散
限制：只画特效，不画角色、手臂、完整武器、地面、阴影、文字、数字、UI 或棋盘格
```

建议提示词：

```text
Generate ONE exact horizontal 4-frame transparent pixel-art spritesheet for a weapon parry impact in the Withered Forest / Heart-Core Ruins rhythm dungeon. Each frame is exactly one 32x32 logical cell, total layout 4 columns by 1 row, no gutters and one consistent center pivot. Frame 1: two short opposing resonant blade trails cross at the center, cyan from one side and restrained amber from the other. Frame 2: a sharp white-cyan contact star with a tiny amber core. Frame 3: a compact cyan-and-amber shock ring expands from the same center. Frame 4: only a few small fading pixel fragments remain. Effect only: no characters, hands, complete weapons, floor, shadow, labels, text, numbers, logo, watermark or checkerboard. True alpha background. It must remain readable at 32x32 with crisp hard pixel edges.
[粘贴共用风格尾缀]
```

原图/参数/哈希登记、确定性裁切和二值 alpha 检查已完成；仍需 Godot 导入、用专用 4 帧替换通用火花组合和弹刀捕获回归。未完成这些步骤前，不把任务单中的目标路径写成“已接入”。

### 当前真实未完成缺口（音频，非图片素材）

以下 **12 个事件音效、1 条循环 BGM** 已按用户要求清理，当前运行时只保留程序生成的简单节拍 click 占位；音频专门任务等待用户另行指定。后续应使用自制或许可证明确的音频，并单独登记来源、许可证与 SHA-256，不得交给图片生成流程。像素字体已由 `FONT-001` 完成，详情见 [`assets/fonts/README.md`](../../fonts/README.md)：

```text
assets/audio/sfx/beat.ogg
assets/audio/sfx/player_attack.ogg
assets/audio/sfx/enemy_attack.ogg
assets/audio/sfx/hit.ogg
assets/audio/sfx/enemy_death.ogg
assets/audio/sfx/player_death.ogg
assets/audio/sfx/guard_block.ogg
assets/audio/sfx/reward_select.ogg
assets/audio/sfx/room_clear.ogg
assets/audio/sfx/boss_phase_shift.ogg
assets/audio/sfx/run_victory.ogg
assets/audio/sfx/run_defeat.ogg
assets/audio/music/loop.ogg
```

### 2026-09-04 新增待生成素材：开始页与设置页装饰

本轮开始页和设置页先使用程序绘制面板、现有房间背景和 FusionPixel 字体占位，功能与布局不依赖这些图片。以下项目只登记为待生成素材，不代表已经生成、下载、派生或接入；未完成素材前不得替换当前占位表现：

```text
inbox/ui/main_menu_title_logo_raw.png
inbox/ui/main_menu_panel_ornament_raw.png
inbox/ui/settings_panel_ornament_raw.png
inbox/ui/menu_action_icons_raw.png
```

目标规格：透明 PNG；像素硬边；与右心房 charcoal-green / muted-crimson / cyan / amber 色板一致；不得含文字以外的额外 UI 文案、品牌水印或棋盘格。`main_menu_title_logo_raw.png` 为居中的《律动遗迹》像素标题字图；`main_menu_panel_ornament_raw.png` 为可平铺或拉伸的心核根系边框；`settings_panel_ornament_raw.png` 为与主菜单同源的设置面板边角/分隔装饰；`menu_action_icons_raw.png` 为开始、设置、退出三个小型功能图标。所有素材生成后仍需按“原图 -> 确定性派生 -> Godot 接入 -> 窗口验收”的顺序处理，并等待企业生成素材公开再分发授权确认。

### 后续可替换特效（非核心阻塞）

Boss hurt/death 的 8 张方向状态已在上方完成项中落盘并接入；本节只保留可替换的独立特效，不作为当前核心玩法阻塞：

- `fx_bpm_shift_raw.png`：心核闪烁、节奏切换预警，设计尺寸 64x64 logical pixels。
- `fx_enemy_death_raw.png`：小型敌人死亡能量爆发，设计尺寸 32x32 logical pixels。
- `fx_room_clear_raw.png`：能量沿根系回流，设计尺寸 64x64 logical pixels。

参考图：`assets/sprites/boss_corewarden_sheet_idle.png`。

特效通用提示词：

```text
Generate ONE single centered transparent pixel-art combat effect: [replace with the exact effect above]. It must have a consistent center pivot, a strong readable silhouette at the stated logical size, and use only cyan, white, amber, restrained magenta and charcoal-green accents. Keep it separate from scenery and characters. No atlas, no labels, no text, no logo, no checkerboard pattern.
[粘贴共用风格尾缀]
```

## P2：暂时不要生成

- 第二种普通敌人：敌人职责和规则尚未锁定。
- 新的四方向 idle/step/attack 主表：现有主表已经覆盖，不要重复生成；20 张 hurt/death 方向状态已接入，后续只做复核或授权明确后的替换。
- 大型开场、结尾和森林全图变化：现有五房间路线已有简短结算，不在当前 MVP 扩成过场动画。
- 大型 tileset atlas：模型容易破坏网格边界；已有 atlas 先由本地脚本和 Pixelorama 复核。
- BGM 和音效：按上方“当前真实未完成缺口（音频，非图片素材）”另行寻找或制作，不得伪装成 BHai 位图生成任务。像素字体已由 `FONT-001` 接入，不属于 BHai 图片生成任务。

## 下载后交给项目验收的内容

每张图同时记录：BHai 页面地址、生成日期、模型、质量、分辨率、比例、是否图生图、参考图、seed、完整提示词、选择理由和 SHA-256。不要在确认企业服务条款允许公开再分发前，把企业生成原图或派生图推送到公开 GitHub。

验收顺序固定为：透明 alpha -> 是否只有一个对象 -> 像素边缘/抗锯齿 -> 中心枢轴和脚底基线 -> 缩小到 32x32 或 64x64 后的可读性 -> 与已有角色色板的一致性。

## 2026-08-28 批次账本

原图统一保留；处理脚本去除与画布边界连通的烘焙棋盘格或近黑背景，再进行裁切、二值 alpha、缩放和确定性导出。四张房间原图保持 `.jpeg` 扩展名，不改写为 PNG。

| 优先级 | 原图 | 派生运行时文件 | 当前本地运行时使用 |
| --- | --- | --- | --- |
| P0 已接入 | `inbox/sprites/player_{hurt,death}_{down,left,right,up}_raw.png`（8 张） | `assets/sprites/player_{hurt,death}_{down,left,right,up}.png`（8 张） | 已落盘、处理、导入并接入；其中 6 张为本次补缺；待逐张视觉/枢轴/脚底基线最终验收；未授权公开 |
| P0 已接入 | `inbox/sprites/enemy_{hurt,death}_{down,left,right,up}_raw.png`（8 张） | `assets/sprites/enemy_siphonling_{hurt,death}_{down,left,right,up}.png`（8 张） | 已落盘、处理、导入并接入；其中 6 张为本次补缺；待逐张视觉/枢轴/脚底基线最终验收；未授权公开 |
| P0 已接入 | `inbox/sprites/boss_{hurt,death}_{down,left,right,up}_raw.png`（8 张） | `assets/sprites/boss_{hurt,death}_{down,left,right,up}.png`（8 张） | 已落盘、处理、导入并接入；8 张均为本次补缺；待逐张视觉/枢轴/脚底基线最终验收；未授权公开 |
| P1 待替换 v1 | `inbox/objects/heart_core_raw.png` | `assets/objects/heart_core.png` | 当前仍被引用；用户已要求重画，不再视为最终验收版；未授权公开 |
| P1 已接入 | `inbox/objects/heart_core_v2_raw.png` | `assets/objects/heart_core_v2.png` | 96x96 / RGBA / 二值 alpha 已派生并接入起始房与结算面板；需用户视觉确认 |
| P1 已选 | `inbox/objects/reward_shrine_raw.png` | `assets/objects/reward_shrine.png` | 已引用并通过窗口初检；未授权公开 |
| P1 已选 | `inbox/items/tempo_echo_raw.png` | `assets/items/echo_tempo.png` | 已引用并通过窗口初检；未授权公开 |
| P1 已选 | `inbox/items/guard_echo_raw.png` | `assets/items/echo_guard.png` | 已引用并通过窗口初检；未授权公开 |
| P1 已选 | `inbox/ui/heart_full_raw.png` | `assets/ui/heart_full.png`，`assets/ui/mvp_state_icons.png` | 单图标已引用；组合 atlas 未引用；未授权公开 |
| P1 已选 | `inbox/ui/heart_empty_raw.png` | `assets/ui/heart_empty.png`，`assets/ui/mvp_state_icons.png` | 单图标已引用；组合 atlas 未引用；未授权公开 |
| P1 已选 | `inbox/ui/charge_raw.png` | `assets/ui/charge_one.png`，`assets/ui/mvp_state_icons.png` | 单图标已引用；组合 atlas 未引用；未授权公开 |
| P1 已选 | `inbox/ui/shield_ready_raw.png` | `assets/ui/shield_ready.png`，`assets/ui/mvp_state_icons.png` | 单图标已引用；组合 atlas 未引用；未授权公开 |
| P1 已选 | `inbox/scenes/room_reward_raw.jpeg` | `assets/backgrounds/room_reward.png` | 已引用并通过 960x540 窗口初检；未授权公开 |
| P1 已选 | `inbox/scenes/room_hard_raw.jpeg` | `assets/backgrounds/room_hard.png` | 已引用并通过 960x540 窗口初检；未授权公开 |
| P1 已选 | `inbox/scenes/room_boss_raw.jpeg` | `assets/backgrounds/room_boss.png` | 已引用并通过 960x540 窗口初检；未授权公开 |
| P1 已选 | `inbox/scenes/room_restored_raw.jpeg` | `assets/backgrounds/room_restored.png` | 已引用并通过 960x540 窗口初检；未授权公开 |

### 当前未完成缺口与后续可替换项

- `heart_core_v2_raw.png`：原图已保留，运行时 V2 已确定性派生并接入，未覆盖 v1 原图文件；仍待用户视觉确认。
- 20 张补缺方向 hurt/death：已落盘、处理、导入并接入；`derived_manifest.json` 与 `tests/mvp_smoke.gd` 已支持。当前剩余逐张视觉/枢轴/脚底基线最终验收及 BHai/企业生成素材公开再分发授权确认，不再作为生成缺口。
- `fx_room_exit_portal_sheet_raw.png`：2026-08-30 已由 BHai 生成并下载，`assets/effects/fx_room_exit_portal_sheet.png` 已按 192x64/RGBA 派生并接入；运行时保留程序光晕、玩家冲门补间与扫屏光条作为叠层。
- `fx_weapon_clash_sheet_raw.png`：2026-08-30 已由 BHai 生成并下载，`assets/effects/fx_weapon_clash_sheet.png` 已按 128x32/RGBA 派生并接入；运行时继续使用双方 attack 帧、程序补间与通用方向斩击/冲击环作为叠层。
- `fx_bpm_shift_raw.png`、`fx_enemy_death_raw.png`、`fx_room_clear_raw.png`：现有特效 atlas 已提供可玩级表现，独立特效属于后续替换项，不阻塞核心玩法。
- 音频仍是未完成验收项：上述 12 个事件音效和 1 条循环 BGM 当前未落盘；节拍 click 继续由程序生成，待用户明确开启音频任务后再完成试听、来源/许可证台账、代码接入和回归。像素字体已由 `FONT-001` 接入。
- 大型 tileset atlas 与第二种普通敌人：继续保持 P2，不扩大当前 MVP。

本账本记录本地资产与引用状态。当前允许在本地场景中验证，但在公开再分发授权、像素边缘与中心/脚底锚点最终复核完成前，不得提交或推送这些 BHai/企业生成原图、运行时派生图及依赖它们的公开版本。

## 历史旧批次：2026-09-01 第 2～4 层原图队列（已被 2026-09-04 扩展队列取代）

> 以下表格只保留历史命名与设计记录，不得直接用于当前生图；当前唯一生图依据是文末“2026-09-04 第 2～4 层扩展生图队列（CURRENT PENDING）”。其中 `arrhythmia_sheet_raw.png`、旧升降梯命名与“第四层普通敌人待补充”均已由新附录 supersede。

本节由 2026-08-31 已确认的合并主策划案直接展开，只登记策划已经锁定的环境、敌人、Boss 和场地机制；完整可重建提示词见 [`UPPER_LAYERS_GENERATION_PROMPTS.md`](UPPER_LAYERS_GENERATION_PROMPTS.md)。生成仍使用学校 BHai 页面 `<https://bhai.elex-tech.com/image/100>`。战斗背景使用 `Seedream 5.0 Pro / 2K / 16:9 / 图生图 / 1 张`，上传现有 `assets/backgrounds/heartcore_forest_room.png` 作为严格 11×6 网格结构参考；地表结尾图不需要战斗网格，使用同模型文生图。角色/Boss 主表使用 `gpt-image-2 / high / 2K / 1:1 / 图生图 / 1 张`，普通敌人上传 `spit_slug_sheet_raw.png`、Boss 上传 `venous_glutton_sheet_raw.png`，仅继承 4×4 布局和枢轴，不继承旧身份；单帧状态再以对应新主表图生图。物件和特效使用同模型/参数文生图。透明精灵、物件和特效只把“透明”记为请求参数，原图模式必须按下载文件实际检查。

### 明确复用、禁止重复生成

- 玩家主表与四方向 hurt/death、通用奖励祭坛和回响/HUD 图标继续复用现有原图。
- 右墙出口、无文字弹刀、能量回流和通用攻击/命中特效继续复用现有原图或 atlas。
- 第一层当前已改为 Boss 房中央传送门交互；不再为第 2、3 层生成独立空传送房。各层出口只生成中央传送门/层间转场素材。
- 最终心核房可复用现有 `room_restored_raw.jpeg` 作为复苏后的室内状态；本批只新增策划要求但现有素材没有覆盖的地表复苏结尾图。
- 第四层普通敌人已由 2026-09-04 扩展策划锁定为杂音晶螯、失谐行者和精英导管守卫·杂音宿主；本节旧表仅保留历史记录，以下新增队列为当前生图依据。

### 背景与结尾（4 张）

| 状态 | 原始文件 | 参数 | 内容与逻辑用途 |
| --- | --- | --- | --- |
| HISTORICAL | `inbox/scenes/room_right_ventricle_raw.jpeg` | Seedream 5.0 Pro / 2K / 16:9 / 图生图 / 1 | 右心室·增压回廊；活塞、瓣膜、高压蒸汽；完整 11×6 可读战斗地砖 |
| HISTORICAL | `inbox/scenes/room_left_atrium_raw.jpeg` | Seedream 5.0 Pro / 2K / 16:9 / 图生图 / 1 | 左心房·充盈温室；富氧荧光、孢子、肺静脉喷口；完整 11×6 可读战斗地砖 |
| HISTORICAL | `inbox/scenes/room_left_ventricle_raw.jpeg` | Seedream 5.0 Pro / 2K / 16:9 / 图生图 / 1 | 左心室·始源心室；始源心核、紫色杂音导管、失真地脉；完整 11×6 可读战斗地砖 |
| HISTORICAL | `inbox/scenes/scene_bleached_canopy_restored_raw.jpeg` | Seedream 5.0 Pro / 2K / 16:9 / 文生图 / 1 | 最终胜利地表定格；溪流解冻、苍白林海恢复金色与翠绿生命力 |

### 第 2 层右心室（31 张）

主表均为 4×4、无间隔、统一枢轴：行顺序 down/left/right/up；列顺序由各敌人提示词明确。普通敌人每格逻辑 32×32，Boss 每格逻辑 64×64。四方向单帧状态严格使用对应主表的站内“以图生图”。

| 状态 | 原始文件 | 规格 / 用途 |
| --- | --- | --- |
| HISTORICAL | `inbox/sprites/gear_stalker_sheet_raw.png` | 4×4 普通敌人主表；idle/patrol1/patrol2/charge |
| HISTORICAL | `inbox/sprites/steam_vent_sheet_raw.png` | 4×4 普通敌人主表；idle/pressure/warning/burst |
| HISTORICAL | `inbox/sprites/piston_colossus_sheet_raw.png` | 4×4 Boss 主表；idle/lock/charge/stunned |
| HISTORICAL | `inbox/sprites/gear_stalker_{hurt,death}_{down,left,right,up}_raw.png` | 8 张单帧；32×32 logical |
| HISTORICAL | `inbox/sprites/steam_vent_{hurt,death}_{down,left,right,up}_raw.png` | 8 张单帧；32×32 logical |
| HISTORICAL | `inbox/sprites/piston_colossus_{hurt,death}_{down,left,right,up}_raw.png` | 8 张单帧；64×64 logical |
| HISTORICAL | `inbox/effects/pressure_valve_gate_sheet_raw.png` | 4 帧横向；每帧 64×64；红门升/降、蓝门升/降 |
| HISTORICAL | `inbox/effects/steam_burst_sheet_raw.png` | 4 帧横向；每帧 64×64；蓄压→预警→喷发→消散 |
| HISTORICAL | `inbox/effects/piston_charge_sheet_raw.png` | 4 帧横向；每帧 64×64；锁定→加速→撞击→眩晕火花 |
| HISTORICAL | `inbox/effects/falling_rubble_sheet_raw.png` | 4 帧横向；每帧 32×32；阴影→落石→碎裂→碎屑消散 |

### 第 3 层左心房（30 张）

| 状态 | 原始文件 | 规格 / 用途 |
| --- | --- | --- |
| HISTORICAL | `inbox/sprites/spore_pod_sheet_raw.png` | 4×4 普通敌人主表；idle/swell/warning/detonate |
| HISTORICAL | `inbox/sprites/vigor_sentinel_sheet_raw.png` | 4×4 普通敌人主表；idle/shield/step/attack |
| HISTORICAL | `inbox/sprites/oxygen_reservoir_sheet_raw.png` | 4×4 Boss 主表；idle/charge1/charge2/overload |
| HISTORICAL | `inbox/sprites/spore_pod_{hurt,death}_{down,left,right,up}_raw.png` | 8 张单帧；32×32 logical |
| HISTORICAL | `inbox/sprites/vigor_sentinel_{hurt,death}_{down,left,right,up}_raw.png` | 8 张单帧；32×32 logical |
| HISTORICAL | `inbox/sprites/oxygen_reservoir_{hurt,death}_{down,left,right,up}_raw.png` | 8 张单帧；64×64 logical |
| HISTORICAL | `inbox/effects/spore_explosion_sheet_raw.png` | 4 帧横向；每帧 96×96；受击→延迟→3×3 爆发→孢尘消散 |
| HISTORICAL | `inbox/effects/pulmonary_venous_jet_sheet_raw.png` | 4 帧横向；每帧 64×64；亮线→聚压→激流→水雾消散 |
| HISTORICAL | `inbox/effects/oxygen_charge_sheet_raw.png` | 4 帧横向；每帧 64×64；3×3 黄框→5×5 橙框→全屏红色预警→冲击波 |

### 第 4 层左心室（历史记录；旧表曾遗漏普通敌人）

| 状态 | 原始文件 | 规格 / 用途 |
| --- | --- | --- |
| HISTORICAL | `inbox/sprites/arrhythmia_sheet_raw.png` | 4×4 最终 Boss 主表；idle/bradycardia/defibrillation/tachycardia_attack |
| HISTORICAL | `inbox/sprites/arrhythmia_{hurt,death}_{down,left,right,up}_raw.png` | 8 张单帧；64×64 logical |
| HISTORICAL | `inbox/objects/noise_conduit_sheet_raw.png` | 4 帧横向；每帧 64×64；导管 idle/hurt/break/dead，可复用到四角 |
| HISTORICAL | `inbox/effects/ground_spike_wave_sheet_raw.png` | 4 帧横向；每帧 64×64；裂纹→突起→地刺峰值→回落 |
| HISTORICAL | `inbox/effects/defibrillation_countdown_sheet_raw.png` | 4 帧横向；每帧 64×64；无数字的四拍心核过载预警 |
| HISTORICAL | `inbox/effects/noise_projectile_sheet_raw.png` | 4 帧横向；每帧 32×32；单枚紫青杂音弹体脉冲，可由程序三向生成 |
| HISTORICAL | `inbox/effects/heart_core_restoration_sheet_raw.png` | 4 帧横向；每帧 96×96；杂音剥落→青色重启→金绿扩散→稳定心核 |

### 原图级验收与硬边界（历史旧批次，不作为当前生图依据）

1. 每项生成完成后立即下载到精确 `inbox/` 文件名；不得覆盖已有同名原图，候选失败图另加 `_candidateN_raw` 保留溯源。
2. 背景应为 2560×1440 左右的 16:9 RGB JPEG/PNG；其他项目应为 2048×2048 的 1:1 PNG。实际尺寸、色彩模式、生成时间、提示词和 SHA-256 必须逐项记录。
3. 主表必须严格 4×4；多帧特效/物件必须严格单行 4 帧；单帧状态只能有一个对象、一个方向和一个状态。不得接受额外碎图、错朝向、缺帧、标签、文字、Logo 或水印。
4. 原图透明请求若仍返回 RGB 棋盘格/白底，只记录真实模式并保留原图；本批全部选中原图到齐前，不运行任何去背景、裁切、缩放、派生脚本，不更新 `derived_manifest.json`，不触发 Godot 导入或运行时接入。
5. 本条统计属于旧批次；2026-09-04 新增的第 2～4 层扩展队列以本文末尾“扩展队列”表为准。

右心室背景文生图候选 1、2 均为 `2560x1440 / RGB JPEG`，但未保持精确 11×6 网格，因此分别保留为 `room_right_ventricle_candidate1_raw.jpeg` 与 `room_right_ventricle_candidate2_raw.jpeg`；候选 3 改用上述 960×540 结构参考做图生图，仍把大格细分且未保持 11×6，保留为 `room_right_ventricle_candidate3_raw.jpeg`。三者状态均为 `REJECTED_CANDIDATE`，正式目标文件尚未生成。

`gear_stalker_sheet_candidate1_raw.png` 与 `gear_stalker_sheet_candidate2_raw.png` 均为 `2048x2048 / RGB PNG`，身份、配色和动作方向基本符合，但实际只有 4×3、缺少第四行 up 状态；`gear_stalker_sheet_candidate3_raw.png` 使用 4×4 参考后布局和内容通过，但切换图生图时页面参数重置为 `low / 1K`，实际只有 `1024x1024 / RGB PNG`。三者均为 `REJECTED_CANDIDATE`；正式 `gear_stalker_sheet_raw.png` 必须在图生图模式重新确认 `high / 2K / 1:1` 后生成。

## 2026-08-31 第一层右心房新增缺口（2026-09-01 已完成原图重生、派生与接入）

本轮已按策划案把现有五房间骨架改为右心房可试玩逻辑。2026-08-31 通过学校 BHai 页面完成第一层主体原图生成；2026-09-01 按用户授权重生两项不合格原图，并完成参数、尺寸、模式与原图级内容复核。随后两张重生原图均已通过确定性派生、Godot 导入与运行时接入；失败候选仍只保留溯源，不覆盖正式路径。

| 优先级 | 原图 | 运行时占位 | 规格与用途 |
| --- | --- | --- | --- |
| P0 已接入 | `inbox/scenes/room_right_atrium_raw.jpeg` | `assets/backgrounds/heartcore_forest_room.png` | 候选 4 提升为正式原图；派生为 960x540 RGB PNG，确认 `ART_GRID_ORIGIN=(153,95)`、`ART_TILE_SIZE=60`、连续 11×6 地面和右墙门约 `(850,270)`；起始/普通房运行时已替换 |
| P0 已接入 | `inbox/sprites/spit_slug_sheet_raw.png` | `assets/sprites/spit_slug_sheet.png` | 128x128 RGBA，4×4、每格 32x32；固定位置泥浆喷吐者 |
| P0 已接入 | `inbox/sprites/spit_slug_{hurt,death}_*_raw.png` | `assets/sprites/spit_slug_{hurt,death}_*.png` | 8 张四方向状态均已派生接入；`death_down` 使用新正式原图，32x32 RGBA、正面朝下、中央下缘喷口与底线已复核 |
| P0 已接入 | `inbox/sprites/venous_glutton_sheet_raw.png` | `assets/sprites/venous_glutton_sheet.png` | 256x256 RGBA，4×4、每格 64x64；运行时按约 3×3 格视觉尺寸显示 |
| P0 已接入 | `inbox/sprites/venous_glutton_{hurt,death}_*_raw.png` | `assets/sprites/venous_glutton_{hurt,death}_*.png` | 8 张 64x64 RGBA 状态已按四方向接入 |
| P0 已接入 | `inbox/effects/mud_projectile_sheet_raw.png` | `assets/effects/mud_projectile_sheet.png` | 128x32 RGBA；弹体旋转到逻辑飞行方向，程序光环保留为叠层 |
| P0 已接入 | `inbox/effects/blood_sediment_hazard_raw.png` | `assets/effects/blood_sediment_hazard_sheet.png` | 128x32 RGBA；持续危险格固定使用完整红心帧，召唤时播放四帧 |
| RETIRED | `inbox/effects/venous_suction_raw.png` | `assets/effects/venous_suction_sheet.png` | 256x64 RGBA；原图与派生图保留溯源，2026-09-02 按用户反馈删除向心吸附后已从运行时代码退役，不再属于第一层必需接入项 |
| P1 已接入 | `inbox/objects/blood_vessel_elevator_raw.png` | `assets/objects/blood_vessel_elevator.png` | 96x96 RGBA；首层 Boss 后的血脉升降梯 |
| P1 已接入 | `inbox/objects/heart_core_v2_raw.png` | `assets/objects/heart_core_v2.png` | 96x96 RGBA；已替换起始房和结算面板心核，尚待用户视觉确认 |

验收沿用本任务单的透明 alpha、单对象、像素边缘、中心枢轴、逻辑尺寸和授权台账要求。`FIRST_LAYER_ASSETS_OK`、`MVP_SMOKE_OK` 与 Godot AI MCP 实时房间截图证明上述运行时接入可用；但占位、用户未验收和未授权公开的状态仍不能写成正式公开交付。

### 2026-09-01 两项不合格原图重生结果

当前两项图片生成缺口已清零；正式原图已处于“已生成/已下载/已复核/已派生/已接入”状态：

| 正式原图 | 参数与参考 | 实际尺寸 / 模式 | SHA-256 | 原图级验收 |
| --- | --- | --- | --- | --- |
| `inbox/scenes/room_right_atrium_raw.jpeg` | `Seedream 5.0 Pro / 最高质量 / 2K / 16:9 / 图生图 / 1`；参考 `assets/backgrounds/heartcore_forest_room.png` | 2560x1440 / RGB JPEG | `e30aa7424842d470a91ce38ca58d9fe5b0ed49334aeec0f5a0c28001a2fb2c89` | BHai 候选 4 于 2026-09-01 14:00:53 CST 落盘，15:11:19 CST 提升为正式路径；缩放到 960x540 并叠加坐标确认 11x6、60px、原点 `(153,95)`、地面范围 `x=153..813 / y=95..455`、右墙门约 `(850,270)`；运行时派生哈希 `fbb516aeec1e21e1f9aca81785aff9b6d4f7f851432b002357db0b73ed351f92` |
| `inbox/sprites/spit_slug_death_down_raw.png` | `gpt-image-2 / high / 2K / 1:1 / 图生图 / 1`；参考 `spit_slug_sheet_raw.png` 结果卡 | 2048x2048 / RGB PNG；棋盘格背景 | `fbff3a770d89c1f741b5a048e2432e5be44562299eccd6ff83cbb9dc473f8662` | 正面朝下；中央下缘破裂喷口；双眼对称位于喷口上方；低矮坍塌；不读作左/右侧倒地；派生为 `assets/sprites/spit_slug_death_down.png`（32x32 RGBA，`be30c0699304cd39b62dbba3dc1a75229a978a0b5df0369892564d9c4775eb35`） |

保留失败/较弱候选，不覆盖、不派生：背景 `room_right_atrium_candidate1_raw.jpeg`（旧目标副本）、`candidate2`、`candidate3`；喷吐者 `spit_slug_death_down_candidate1_raw.png`（旧错误方向）和 `candidate2`（方向正确但死亡特征偏弱）。

右心房背景重生实际参数：`Seedream 5.0 Pro / 最高质量 / 2K / 16:9 / 图生图 / 1 张`。生成时上传已校准的 `assets/backgrounds/heartcore_forest_room.png` 作为严格构图/网格参考，没有使用旧不合格目标作几何参考。

```text
Create one 16:9 top-down 2D pixel-art RIGHT ATRIUM dungeon room for the Rhythm Ruins game by repainting the attached accepted gameplay background while preserving its gameplay geometry exactly. STRUCTURE IS STRICT: after the result is resized to 960x540, the walkable floor must contain exactly 11 columns by 6 rows of large square gameplay tiles; the top-left gameplay-tile origin is exactly around pixel (153,95), each tile step is exactly 60 pixels, and the complete floor spans from x=153 to x=813 and y=95 to y=455. Keep the right-wall exit centered around pixel (850,270), outside the last gameplay column, and keep the lower entrance corridor centered like the reference. Do not add smaller decorative tile subdivisions inside the 11x6 floor, do not change the tile count, tile pitch, wall thickness, camera, perspective, door anchors, or walkable boundary. Re-theme only the surface art into the first-layer right atrium: dark venous waterways, restrained muddy sediment along outer edges, charcoal-green and slate chamber walls, muted-crimson vessel roots, compact cyan life-energy channels, and a few amber deposits. Most gameplay cells must remain visually clear and open. No characters, enemies, boss, heart core, elevator, projectile, hazard marker, UI, text, logo, watermark, grid overlay, isometric perspective, smooth gradients, painterly rendering or 3D. Crisp hard-edged top-down pixel art, limited 24-32 color palette, readable under nearest-neighbor gameplay rendering. The exact 11x6 tile geometry and exit anchor are mandatory; style changes must never alter them.
```

喷吐者向下死亡重生实际参数：`gpt-image-2 / high / 2K / 1:1 / 图生图 / 1 张`。从 BHai 中已选中的 `spit_slug_sheet_raw.png` 结果卡点击“以图生图”，没有使用错误 death 结果作参考。

```text
Use the attached Spit Slug master sprite sheet as a strict identity, palette, center-pivot and ground-baseline reference. Generate ONE single centered transparent pixel-art sprite, not a spritesheet and not multiple frames. Direction is STRICTLY DOWN, facing the viewer: the cracked amber-brown throat nozzle must remain centered on the NEAR BOTTOM edge of the body, and both dim cyan eyes must remain visibly above and beside that bottom nozzle. The same low dark-brown and charcoal mud-parasite Spit Slug is defeated: its body compresses downward into a compact mostly front-facing mound while preserving bilateral left-right symmetry and the down-facing facial landmarks. Do NOT turn the body into a horizontal left-facing or right-facing carcass; do not place the nozzle at either side; do not show a side profile. Add only a few restrained cyan and muted-crimson fragments close to the silhouette. It must read as this exact enemy's down-facing death state, not a new creature and not a large explosion. Fit inside one 32x32 logical pixel gameplay frame with balanced transparent padding, common bottom baseline and no external shadow. No extra creature, projectile, floor, scenery, text, logo, watermark, checkerboard, grid or spritesheet. True alpha background, crisp hard pixel edges and limited project palette.
```

### 2026-08-31 原图完成节点

- 已生成并下载原图：`room_right_atrium_raw.jpeg`（2026-09-01 由候选 4 提升）、`heart_core_v2_raw.png`、`spit_slug_sheet_raw.png`、`venous_glutton_sheet_raw.png`、`mud_projectile_sheet_raw.png`、`blood_sediment_hazard_raw.png`、`venous_suction_raw.png`、`blood_vessel_elevator_raw.png`，以及两类敌人的四方向 hurt/death 共 16 张单帧状态。
- `venous_suction_raw.png` 为第二次严格重生成后选中的单行四帧版；首次结果因画布下方额外生成无关碎图，保留为 `venous_suction_candidate1_raw.png`，不得派生或接入。
- 泥浆喷吐者四方向 hurt/death 8 张全部到齐；续批按 `hurt_right -> death_right -> hurt_up -> death_up` 完成。首次 `hurt_up` 因方向仍读作 down，被保留为 `spit_slug_hurt_up_candidate1_raw.png`，严格重生成的 `spit_slug_hurt_up_raw.png` 为选中版。
- 静脉吸附者·泥鳃四方向 hurt/death 8 张全部到齐；续批按 `down -> left -> right -> up` 完成，每张均从泥鳃主表结果卡重新点击“以图生图”。
- 参数为 `gpt-image-2 / high / 2K / 1:1 / 图生图 / 1 张`；页面未显示 seed。续批的完整提示词重建规则见 `FIRST_LAYER_STATE_PROMPTS.md`。
- 除右心房背景是 `2560x1440 / RGB JPEG` 外，本节点已下载的 PNG 原图均为 `2048x2048 / RGB`，网站“透明”请求实际返回棋盘格或白底；必须保留原图并由确定性脚本派生 RGBA，不得把原图记为 true alpha。
- 本节点只完成原图生成、下载、SHA-256 和原图方向/单对象视觉初检；随后 2026-09-01 派生节点已更新 `derived_manifest.json`、完成 Godot 导入/接入与运行时回归。用户视觉验收、Git 提交/推送和公开再分发授权仍需单独确认，不自动开始第二层。


## 2026-09-04 第 2～4 层扩展生图队列（CURRENT PENDING）

本节覆盖用户本轮要求的全部后续层角色、房间场景、精英、Boss、传送门、初始界面背景和层间转场。详细设定以 `游戏策划案/《律动遗迹》游戏策划案.md` 末尾“2026-09-04 第 2～4 层扩展设计与美术生成规范”为准；详细英文提示词写入 `UPPER_LAYERS_GENERATION_PROMPTS.md` 同名附录。原图必须继续落盘到 `assets/generated/bhai/inbox/`；已完成审核的转场子批次可单独确定性派生并接入，未完成的其他素材仍不提前处理。

### 奖励增益图标

| 状态 | 原始文件 | 规格与用途 |
| --- | --- | --- |
| DERIVED / INTEGRATED | `inbox/items/impact_echo_raw.png` | 原图为 RGB 棋盘格；已派生 32×32 RGBA `assets/items/echo_impact.png`，接入奖励卡和 HUD |
| DERIVED / INTEGRATED | `inbox/items/vigor_echo_raw.png` | 原图为 RGB 棋盘格；已派生 32×32 RGBA `assets/items/echo_vigor.png`，接入奖励卡和 HUD |
| DERIVED / INTEGRATED | `inbox/items/pulse_echo_raw.png` | 原图为 RGB 棋盘格；已派生 32×32 RGBA `assets/items/echo_pulse.png`，接入奖励卡和 HUD |

### 2026-09-04 本批原图审计（奖励图标 + Boss 攻击特效）

本批通过学校合作企业 BHai Chrome 页面完成文生图并立即下载；页面设置统一为 `gpt-image-2 / high / 2K / 1:1 / 1 张 / 文生图`，提示词分别来自本文件与 `UPPER_LAYERS_GENERATION_PROMPTS.md` 的奖励及机制特效设定。页面未显示 seed，以下记录不补写推测值。所有文件均保持 BHai 下载原图，未裁剪、缩放、去棋盘格、切帧、转 RGBA 或接入 Godot。

| 原始文件 | 实际落盘时间（文件系统） | 实际尺寸 / 模式 | Alpha / 布局原图级检查 | SHA-256 |
| --- | --- | --- | --- | --- |
| `inbox/items/impact_echo_raw.png` | 02:33:50（本轮文件系统记录时间；批次日期按本节 2026-09-04 记载） | 2048×2048 / RGB PNG | 无 alpha；单个居中余震增幅图标，视觉初检通过 | `ba85ab9c1326931d6e108847e4c6e852c1ee525e8dc897158dfdbaaf381687c4` |
| `inbox/items/vigor_echo_raw.png` | 02:38:22（本轮文件系统记录时间；批次日期按本节 2026-09-04 记载） | 2048×2048 / RGB PNG | 无 alpha；单个居中心室扩容图标，视觉初检通过 | `509701e94e03ff5bc7b6abf7031b195b2af7d8fc5f0d973dedea0dd3c0ec7fed` |
| `inbox/items/pulse_echo_raw.png` | 02:42:50（本轮文件系统记录时间；批次日期按本节 2026-09-04 记载） | 2048×2048 / RGB PNG | 无 alpha；单个居中回响修复图标，视觉初检通过 | `870cd41baa1cc91d68de0956c5d6bad7a676d77127e64405d6b969c713512212` |
| `inbox/effects/piston_strike_sheet_raw.png` | 02:47:15（本轮文件系统记录时间；批次日期按本节 2026-09-04 记载） | 2048×2048 / RGB PNG | 无 alpha；四个效果图形按单行排列，冲压→命中→回弹/眩晕语义初检通过 | `c5c565b8235e5d7c958bc46cd80fa2990fb4259e4c7f981254e64b6bf9d84b9d` |
| `inbox/effects/oxygen_charge_sheet_raw.png` | 02:50:12（本轮文件系统记录时间；批次日期按本节 2026-09-04 记载） | 2048×2048 / RGB PNG | 无 alpha；四个效果图形按单行排列，3×3→5×5→危险→冲击语义初检通过 | `b94de39dd644d1c4c5fe1cf6c78e4d38ce49a39aede39db3f72c5f7d68154eaa` |
| `inbox/effects/ground_spike_wave_sheet_raw.png` | 02:53:46（本轮文件系统记录时间；批次日期按本节 2026-09-04 记载） | 2048×2048 / RGB PNG | 无 alpha；四个效果图形按单行排列，裂缝→升刺→高刺→崩解语义初检通过 | `ddee0dafbb2e378886c2ae2b73718dff5c2762fa7f04b8f0fab671217a98d83a` |
| `inbox/effects/defibrillation_countdown_sheet_raw.png` | 02:57:35（本轮文件系统记录时间；批次日期按本节 2026-09-04 记载） | 2048×2048 / RGB PNG | 无 alpha；四个效果图形按单行排列，四拍除颤升级语义初检通过 | `54e3d98c5e84cede3e0b4a74540bbd02ee8bec703f8aeff6eeb3902eb884a1d8` |
| `inbox/effects/noise_projectile_sheet_raw.png` | 03:01:01（本轮文件系统记录时间；批次日期按本节 2026-09-04 记载） | 2048×2048 / RGB PNG | 无 alpha；四个效果图形按单行排列，单一杂音弹四状态语义初检通过 | `7979fb64ad270a2bc4dcb740f21bb8b88033d44104b1c15c1d573b5fe7d466e5` |
| `inbox/effects/pulmonary_jet_sheet_raw.png` | 03:06:38（本轮文件系统记录时间；批次日期按本节 2026-09-04 记载） | 2048×2048 / RGB PNG | 无 alpha；四个效果图形按单行排列，方向线→蓄压→喷流→余波语义初检通过 | `6885e819047c22d556df2e0368d75edf8243678757242caa20c4a7205499fac4` |

> 说明：BHai 的透明请求在这些下载结果中实际返回 RGB 棋盘格画布，因此“透明”只能作为生成请求，不能写成原图 true alpha。上述文件先标记为“已下载原图/视觉初检”，后续如需接入，必须另行执行确定性派生、尺寸/帧边界/中心枢轴验收和 Godot 导入回归；公开再分发授权仍未确认。

### 场景背景（15 张细分房间 + 3 张层通用主地图）

| 状态 | 原始文件 | 规格 | 用途 |
|---|---|---|---|
| DERIVED / INTEGRATED | `inbox/scenes/room_right_ventricle_raw.jpeg` | gpt-image-2 / high / 2K / 16:9 / 图生图；共享 11×6 地图作严格参考 | 2F 压力管道层通用主地图；原图实际 PNG/RGB，2560×1440；运行时派生为 `assets/backgrounds/room_right_ventricle.png`（960×540 RGB），已接入 2F 全部可玩房间 |
| DERIVED / INTEGRATED | `inbox/scenes/room_left_atrium_raw.jpeg` | gpt-image-2 / high / 2K / 16:9 / 图生图；共享 11×6 地图作严格参考 | 3F 高氧温室层通用主地图；原图实际 PNG/RGB，2560×1440；运行时派生为 `assets/backgrounds/room_left_atrium.png`（960×540 RGB），已接入 3F 全部可玩房间 |
| DERIVED / INTEGRATED | `inbox/scenes/room_left_ventricle_raw.jpeg` | gpt-image-2 / high / 2K / 16:9 / 图生图；共享 11×6 地图作严格参考 | 4F 始源心核圣域通用主地图；原图实际 PNG/RGB，2560×1440；运行时派生为 `assets/backgrounds/room_left_ventricle.png`（960×540 RGB），已接入 4F 全部可玩房间 |
| PENDING | `inbox/scenes/room_right_ventricle_01_prep_raw.jpeg` | Seedream 5.0 Pro / 2K / 16:9 / 图生图 | 2F 加压减压舱 |
| PENDING | `inbox/scenes/room_right_ventricle_02_battle_raw.jpeg` | 同上 | 2F 动力机房 |
| PENDING | `inbox/scenes/room_right_ventricle_03_reward_raw.jpeg` | 同上 | 2F 调压控制核心室 |
| PENDING | `inbox/scenes/room_right_ventricle_04_elite_raw.jpeg` | 同上 | 2F 增压裂隙重构室 |
| PENDING | `inbox/scenes/room_right_ventricle_05_boss_raw.jpeg` | 同上 | 2F 活塞巨像锻造腔 |
| PENDING | `inbox/scenes/room_left_atrium_01_prep_raw.jpeg` | 同上 | 3F 静脉充盈泉眼 |
| PENDING | `inbox/scenes/room_left_atrium_02_battle_raw.jpeg` | 同上 | 3F 菌丝培养槽 |
| PENDING | `inbox/scenes/room_left_atrium_03_reward_raw.jpeg` | 同上 | 3F 生命灵液灌溉中枢 |
| PENDING | `inbox/scenes/room_left_atrium_04_elite_raw.jpeg` | 同上 | 3F 高压增氧温室 |
| PENDING | `inbox/scenes/room_left_atrium_05_boss_raw.jpeg` | 同上 | 3F 充盈核心孵化池 |
| PENDING | `inbox/scenes/room_left_ventricle_01_prep_raw.jpeg` | 同上 | 4F 圣域破损门廊 |
| PENDING | `inbox/scenes/room_left_ventricle_02_battle_raw.jpeg` | 同上 | 4F 杂音结晶回廊 |
| PENDING | `inbox/scenes/room_left_ventricle_03_reward_raw.jpeg` | 同上 | 4F 终极调律圣坛 |
| PENDING | `inbox/scenes/room_left_ventricle_04_elite_raw.jpeg` | 同上 | 4F 杂音温床 |
| PENDING | `inbox/scenes/room_left_ventricle_05_boss_raw.jpeg` | 同上 | 4F 始源心核祭坛 |

### 角色与 Boss 主表

主表统一为 4×4、无间隔、行顺序 down/left/right/up。2F/3F 小怪与精英为 32×32 logical；2F Boss 为 64×64；3F/4F Boss 为 96×96。

| 状态 | 原始文件 | 规格与角色 |
|---|---|---|
| PENDING | `inbox/sprites/gear_stalker_sheet_raw.png` | 4×4，2F 发条工蚁，idle/patrol/sprint_windup/sprint |
| PENDING | `inbox/sprites/steam_vent_sheet_raw.png` | 4×4，2F 增压气阀怪，idle/pressure/warning/burst |
| PENDING | `inbox/sprites/pneumatic_vanguard_sheet_raw.png` | 4×4，2F 精英排气重装卫兵，idle/hammer_windup/strike/stagger |
| COMPLETED VIA SINGLE-FRAME BOSS SOURCE | `inbox/sprites/piston_colossus_boss_raw.png` | 已派生为静态 4×4 atlas 并接入 2F Boss；完整四状态表仍待后续生成 |
| PENDING | `inbox/sprites/spore_pod_sheet_raw.png` | 4×4，3F 荧光孢囊，idle/swell/warning/detonate |
| PENDING | `inbox/sprites/vigor_sentinel_sheet_raw.png` | 4×4，3F 充能卫士，idle/shield/step/attack |
| PENDING | `inbox/sprites/resonance_medusa_sheet_raw.png` | 4×4，3F 精英共鸣水母，drift/telegraph/pulse/recover |
| COMPLETED VIA SINGLE-FRAME BOSS SOURCE | `inbox/sprites/oxygen_reservoir_boss_raw.png` | 已派生为静态 4×4 atlas 并接入 3F Boss；完整四状态表仍待后续生成 |
| PENDING | `inbox/sprites/noise_scuttler_sheet_raw.png` | 4×4，4F 杂音晶螯，idle/scuttle/scream/arc |
| PENDING | `inbox/sprites/arrhythmic_phantom_sheet_raw.png` | 4×4，4F 失谐行者，fade/phase/step/strike |
| PENDING | `inbox/sprites/conduit_warden_sheet_raw.png` | 4×4，4F 精英导管守卫，idle/shield/link/break |
| COMPLETED VIA SINGLE-FRAME BOSS SOURCE | `inbox/sprites/arrhythmia_boss_raw.png` | 已派生为静态 4×4 atlas 并接入 4F Boss；完整四状态表仍待后续生成 |

每个上述角色另生成四方向 `hurt` 与 `death` 单帧；命名格式为 `<id>_hurt_<down|left|right|up>_raw.png` 与 `<id>_death_<down|left|right|up>_raw.png`。小怪/精英单帧 32×32，2F Boss 单帧 64×64，3F/4F Boss 单帧 96×96。

### 场地机制、传送门与转场素材

| 状态 | 原始文件 | 规格与用途 |
|---|---|---|
| PENDING | `inbox/effects/valve_gate_red_sheet_raw.png` | 4 帧，64×64，2F 红色瓣膜门升降 |
| PENDING | `inbox/effects/valve_gate_blue_sheet_raw.png` | 4 帧，64×64，2F 蓝色瓣膜门升降 |
| PENDING | `inbox/effects/steam_burst_sheet_raw.png` | 4 帧，64×64，2F 蒸汽喷发 |
| DERIVED / INTEGRATED | `inbox/effects/piston_strike_sheet_raw.png` | 4 帧，64×64，2F 冲压/撞击/眩晕；原图为 RGB 棋盘格，已派生为 256×64 RGBA 4 帧运行时特效并接入 Boss 表现 |
| PENDING | `inbox/effects/falling_rubble_sheet_raw.png` | 4 帧，32×32，2F 落石 |
| PENDING | `inbox/effects/spore_explosion_sheet_raw.png` | 4 帧，96×96，3F 3×3 孢囊爆炸 |
| DERIVED / INTEGRATED | `inbox/effects/pulmonary_jet_sheet_raw.png` | 4 帧，64×64，3F 肺静脉喷流；原图为 RGB 棋盘格，已派生为 256×64 RGBA 4 帧运行时特效并接入 Boss 表现 |
| DERIVED / INTEGRATED | `inbox/effects/oxygen_charge_sheet_raw.png` | 4 帧，96×96，3F 阶梯充能/冲击；原图为 RGB 棋盘格，已派生为 256×64 RGBA 4 帧运行时特效并接入 Boss 表现 |
| PENDING | `inbox/effects/medusa_cross_pulse_sheet_raw.png` | 4 帧，96×96，3F 十字水流脉冲 |
| PENDING | `inbox/objects/noise_conduit_sheet_raw.png` | 4 帧，64×64，4F 四角杂音导管 |
| DERIVED / INTEGRATED | `inbox/effects/ground_spike_wave_sheet_raw.png` | 4 帧，96×96，4F 地刺波；原图为 RGB 棋盘格，已派生为 256×64 RGBA 4 帧运行时特效并接入 Boss 表现 |
| DERIVED / INTEGRATED | `inbox/effects/defibrillation_countdown_sheet_raw.png` | 4 帧，96×96，4F 四拍除颤预警；原图为 RGB 棋盘格，已派生为 256×64 RGBA 4 帧运行时特效并接入 Boss 表现 |
| DERIVED / INTEGRATED | `inbox/effects/noise_projectile_sheet_raw.png` | 4 帧，32×32，4F 三向杂音弹；原图为 RGB 棋盘格，已派生为 256×64 RGBA 4 帧运行时特效并接入 Boss 表现 |
| PENDING | `inbox/effects/heart_core_restoration_sheet_raw.png` | 4 帧，96×96，终局心核复苏 |
| DERIVED / INTEGRATED | `inbox/objects/portal_pressurized_raw.png` | 2F 中央加压传送门；原图实际 2048×2048 RGB PNG，横向四帧 | 运行时派生为 `assets/objects/portal_pressurized_sheet.png`（384×96 RGBA，4×1），Boss 房清除后切换为中央传送门 |
| DERIVED / INTEGRATED | `inbox/objects/portal_oxygen_flow_raw.png` | 3F 中央高氧传送门；原图实际 2048×2048 RGB PNG，横向四帧 | 运行时派生为 `assets/objects/portal_oxygen_flow_sheet.png`（384×96 RGBA，4×1），Boss 房清除后切换为中央传送门 |
| DERIVED / INTEGRATED | `inbox/objects/portal_prime_resonance_raw.png` | 4F 终局共鸣台；原图实际 2048×2048 RGB PNG，横向四帧 | 运行时派生为 `assets/objects/portal_prime_resonance_sheet.png`（384×96 RGBA，4×1），Boss 房清除后切换为中央传送门 |
| DOWNLOADED | `inbox/scenes/room_upper_layers_shared_raw.jpeg` | 2560×1440，16:9，11×6 通用多层地图模板；实际 JPEG/RGB |
| DOWNLOADED | `inbox/scenes/title_screen_background_raw.jpeg` | 2560×1440，16:9，不透明，开始页背景 |
| DERIVED / INTEGRATED | `inbox/scenes/trans_atrium_to_ventricle_raw.jpeg` | 2560×1440，16:9，1F→2F 转场插图；原图实际 PNG/RGB | 已派生为 `assets/transitions/trans_atrium_to_ventricle.png`（960×540 RGB），Boss 房传送到 2F 时正式显示 |
| DERIVED / INTEGRATED | `inbox/scenes/trans_ventricle_to_atrium_raw.jpeg` | 2560×1440，16:9，2F→3F 转场插图；原图实际 PNG/RGB | 已派生为 `assets/transitions/trans_ventricle_to_atrium.png`（960×540 RGB），Boss 房传送到 3F 时正式显示 |
| DERIVED / INTEGRATED | `inbox/scenes/trans_atrium_to_ventricle4_raw.jpeg` | 2560×1440，16:9，3F→4F 转场插图；原图实际 PNG/RGB | 已派生为 `assets/transitions/trans_atrium_to_ventricle4.png`（960×540 RGB），Boss 房传送到 4F 时正式显示 |
| DERIVED / INTEGRATED | `inbox/scenes/trans_ending_revival_raw.jpeg` | 2560×1440，16:9，终局复苏插图；原图实际 PNG/RGB | 已派生为 `assets/transitions/trans_ending_revival.png`（960×540 RGB），4F Boss 击败后的复苏流程正式显示 |
| PENDING | `inbox/effects/heartbeat_wipe_sheet_raw.png` | 4 帧横向 960×540，全屏心跳擦拭 Overlay |

### 批次验收

- 本节所有透明请求的原图按实际模式登记；RGB 棋盘格不改写、不冒充 true alpha。
- 背景必须单独检查 11×6 地面、右侧出口和中心开放区；任何新增小砖、斜视角、文字、UI 或角色均退回。
- 主表和多帧特效必须按文件名逐项下载，候选失败图使用 `_candidateN_raw`，不覆盖正式目标。
- 全部原图到齐前不运行派生脚本、不更新 `derived_manifest.json`、不接入 Godot。

## 2026-09-04 旧素材清理记录

按用户要求删除了旧候选/失败原图及其 `.import` 文件，并删除已被替代或已取消玩法对应的旧素材：旧 v1 心核、旧 Corewarden Boss 资源、取消的血脉升降梯、已移除的向心吸附特效、未使用的心核近景派生图。本次共删除 86 个本地文件；不影响当前第一层运行时素材。

截图中的 BHai 结果属于 `title_screen_background_raw.jpeg` 的初始界面背景预览。截至本次清理，它已下载到项目 `assets/generated/bhai/inbox/scenes/`；当前实际文件为 2560x1440 RGB PNG，扩展名沿用队列要求。
