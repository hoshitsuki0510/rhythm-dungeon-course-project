# 第 2～4 层 BHai 原图生成提示词

更新时间：2026-09-01

本文件与 `GENERATION_QUEUE.md` 的“第 2～4 层正式原图生成队列”配套。所有提示词都服务于已确认的主策划案；没有策划定义的第四层普通敌人不在本文件中。每次生成 1 张，结果下载后按队列精确命名。原图只做尺寸、模式、布局、方向与内容检查；本批选中原图全部到齐前不派生、不导入或接入 Godot。

## 共用像素风尾缀

以下尾缀附在所有 `gpt-image-2` 主表、状态、物件和特效提示词末尾：

```text
Original game-ready 2D top-down pixel art for the same Rhythm Ruins / Resonant Nexus rhythm-dungeon game. Strict crisp hard stepped pixel edges, limited 24-32 color palette, readable at the stated logical gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no photorealism, no 3D, no isometric perspective, no anime style, no labels, no text, no logo and no watermark.
```

透明资产再附加：

```text
True alpha background. Do not draw a checkerboard, white canvas, scenery, floor, cast shadow, UI panel, frame labels or duplicate objects.
```

## 背景与结尾

三个战斗房参数：`Seedream 5.0 Pro / 2K / 16:9 / 图生图 / 数量 1`，上传 `assets/backgrounds/heartcore_forest_room.png` 作为严格结构参考。提示词必须明确保留参考图的正交相机、外墙范围和 11×6 大地砖边界，移除中央祭坛/心核并补回连续地砖，再重绘本层材质与右墙中央门。地表复苏结尾图没有战斗网格，使用同模型文生图。背景不要求透明。所有战斗房背景必须清楚保留连续 11×6 行动地砖：左上约 `(153,95)`、每格 60px、整体到 `(813,455)`；右墙中央门洞约 `(850,270)`。画面不得预先放入角色、怪物、Boss、奖励物件、UI 或文字。

### `room_right_ventricle_raw.jpeg`

```text
Create one original 16:9 top-down pixel-art combat-room background for 2F Right Ventricle · Pressure Gallery in the Rhythm Ruins / Resonant Nexus game. Orthographic top-down view, not isometric. The chamber is a biological-mechanical pressure corridor: dark slate piston housings, restrained brass and amber gear teeth, muted-crimson vessel cables, red and blue hydraulic valve structures, and narrow cyan life-energy pressure gauges. High-pressure steam leaks only around the perimeter. Keep the central combat floor open and readable as exactly 11 columns by 6 rows of large alternating pixel tiles on a 960x540 target canvas: grid top-left approximately (153,95), tile size 60 pixels, grid ending approximately (813,455). Preserve a clear right-wall central doorway around (850,270). No characters, monsters, Boss, UI, text, labels, logo, watermark, perspective tilt, tiny dense floor tiles, blocked cells or decorations hiding the grid. Strict crisp 2D pixel art, hard stepped edges, limited charcoal, slate, muted-crimson, cyan, amber and restrained steel-blue palette; no antialiasing, blur, smooth gradients, painterly rendering, photorealism or 3D.
```

### `room_left_atrium_raw.jpeg`

```text
Create one original 16:9 top-down pixel-art combat-room background for 3F Left Atrium · Oxygenated Conservatory in the Rhythm Ruins / Resonant Nexus game. Orthographic top-down view, not isometric. The chamber is a ruined bio-mechanical greenhouse: deep blue-green stone, broad luminous oxygen veins, restrained cyan and pale-green fungal lamps, muted-crimson vessel roots, sealed pulmonary-vein jet nozzles on the outer walls, and sparse spore growth only along the perimeter. Keep the central combat floor open and readable as exactly 11 columns by 6 rows of large alternating pixel tiles on a 960x540 target canvas: grid top-left approximately (153,95), tile size 60 pixels, grid ending approximately (813,455). Preserve a clear right-wall central doorway around (850,270). No characters, monsters, Boss, UI, text, labels, logo, watermark, perspective tilt, tiny dense floor tiles, blocked central cells or decoration hiding hazards. Strict crisp 2D pixel art, hard stepped edges, limited charcoal, slate, deep teal, oxygen cyan, pale green, muted crimson and small amber palette; no antialiasing, blur, smooth gradients, painterly rendering, photorealism or 3D.
```

### `room_left_ventricle_raw.jpeg`

```text
Create one original 16:9 top-down pixel-art combat-room background for 4F Left Ventricle · Prime Heart Chamber in the Rhythm Ruins / Resonant Nexus game. Orthographic top-down view, not isometric. Show the deepest bio-mechanical heart chamber: a monumental but restrained heart-core recess at the far wall, thick dark slate myocardium-like architecture, four empty corner sockets for corruption conduits, distorted purple-magenta ground veins, broken cyan life-energy channels and a dangerous but readable central arena. Keep the combat floor open and readable as exactly 11 columns by 6 rows of large alternating pixel tiles on a 960x540 target canvas: grid top-left approximately (153,95), tile size 60 pixels, grid ending approximately (813,455). Preserve a clear right-wall central doorway around (850,270). No characters, monsters, Boss, actual conduit objects, UI, text, labels, logo, watermark, perspective tilt, tiny dense floor tiles or blocked central arena. Strict crisp 2D pixel art, hard stepped edges, limited charcoal, slate, cyan, restrained crimson, corrupted violet-magenta and small amber palette; no antialiasing, blur, smooth gradients, painterly rendering, photorealism or 3D.
```

### `scene_bleached_canopy_restored_raw.jpeg`

```text
Create one original 16:9 pixel-art ending still for the restored Bleached Canopy after the Prime Heart is repaired. A wide side-view landscape, not a combat room: thawed streams reflect golden and emerald life-energy, formerly gray-white trees regain restrained green foliage, cyan veins of light travel through the ground, and warm dawn reaches the revived forest. In the lower foreground, include only one small back-facing silhouette of the rhythm warden Echo walking toward the light with a compact tuning-fork sword lowered at his side. The mood is calm ecological recovery, not celebration fireworks. No monsters, Boss, gore, UI, captions, text, logo, watermark, photorealism, 3D or anime illustration. Strict crisp cinematic pixel art with hard stepped edges and a limited charcoal, pale gray, emerald, cyan, gold and muted-crimson palette.
```

## 第 2 层右心室主表

参数：`gpt-image-2 / high / 2K / 1:1 / 图生图 / 数量 1 / 透明请求`。普通敌人上传 `assets/generated/bhai/inbox/sprites/spit_slug_sheet_raw.png`，Boss 上传 `venous_glutton_sheet_raw.png`；参考图只约束 4×4 行列、单元中心、留白和方向顺序，提示词必须明确完全替换旧身份。切换到图生图会把页面重置为 `low / 1K`，必须在上传参考图和提交前重新选择 `high / 2K / 1:1`。

### `gear_stalker_sheet_raw.png`

```text
Generate ONE exact 4 by 4 transparent top-down pixel-art sprite sheet for a single enemy species: the Gear Stalker, a fast clockwork worker-ant parasite in 2F Right Ventricle · Pressure Gallery. It has a low segmented charcoal-steel body, six short mechanical legs, a forward pair of copper piston mandibles, one cyan line-of-sight lens, a small amber flywheel and restrained muted-crimson vessel cables. Compact hostile silhouette, readable in one 32x32 logical gameplay cell and clearly different from the organic first-floor enemies. Exact 4 columns by 4 rows, 16 equal square cells, no gutters, no labels. Rows are facing down, left, right, up. Columns are idle, patrol step 1, patrol step 2, straight-line charge. The same creature, palette, center pivot and ground baseline in every cell; side and up directions must be genuine rotations, not mirrored front views. Generous transparent padding in each cell. No scenery, floor, separate effects, duplicate creature, grid lines, text, logo, watermark or checkerboard.
Original game-ready 2D top-down pixel art for the same Rhythm Ruins / Resonant Nexus rhythm-dungeon game. Strict crisp hard stepped pixel edges, limited 24-32 color palette, readable at the stated logical gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no photorealism, no 3D, no isometric perspective, no anime style, no labels, no text, no logo and no watermark. True alpha background.
```

### `steam_vent_sheet_raw.png`

```text
Generate ONE exact 4 by 4 transparent top-down pixel-art sprite sheet for a single enemy species: the Steam Vent, a small ambulatory pressure-valve parasite in 2F Right Ventricle · Pressure Gallery. It has a squat slate valve body, a directional brass nozzle-mouth, four short clamp feet, a cyan pressure gauge, muted-crimson vessel tubing and tiny amber rivets. Compact silhouette readable in one 32x32 logical gameplay cell. Exact 4 columns by 4 rows, 16 equal square cells, no gutters, no labels. Rows are nozzle facing down, left, right, up. Columns are idle closed valve, pressure building, red warning glow, adjacent steam burst. The same creature, palette, center pivot and ground baseline in every cell; the nozzle must clearly point in the row direction even though the burst affects surrounding cells. Generous transparent padding. No scenery, floor, separate large cloud, duplicate creature, grid lines, text, logo, watermark or checkerboard.
Original game-ready 2D top-down pixel art for the same Rhythm Ruins / Resonant Nexus rhythm-dungeon game. Strict crisp hard stepped pixel edges, limited 24-32 color palette, readable at the stated logical gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no photorealism, no 3D, no isometric perspective, no anime style, no labels, no text, no logo and no watermark. True alpha background.
```

### `piston_colossus_sheet_raw.png`

```text
Generate ONE exact 4 by 4 transparent top-down pixel-art boss sprite sheet for the Piston Colossus, the unbalanced valve guardian of 2F Right Ventricle · Pressure Gallery. One massive compact bio-mechanical guardian visually occupying about a 2x2 gameplay area: broad charcoal-steel ram body, two heavy slate piston shoulders, a central cyan pressure-heart gauge, red and blue valve plates on opposite sides, restrained muted-crimson vessel cables, thick brass feet and small amber pressure lights. Readable in one 64x64 logical sprite cell. Exact 4 columns by 4 rows, 16 equal square cells, no gutters, no labels. Rows face down, left, right, up. Columns are idle, row-or-column lock pose, full piston charge, crashed-and-stunned pose. Preserve one identity, center pivot and ground baseline; side and up rows must show true direction. No room gates, floor, rubble pile, extra character, full-screen effect, text, logo, watermark or checkerboard.
Original game-ready 2D top-down pixel art for the same Rhythm Ruins / Resonant Nexus rhythm-dungeon game. Strict crisp hard stepped pixel edges, limited 24-32 color palette, readable at the stated logical gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no photorealism, no 3D, no isometric perspective, no anime style, no labels, no text, no logo and no watermark. True alpha background.
```

## 第 3 层左心房主表

参数和布局参考规则与第 2 层相同：普通敌人使用喷吐者 4×4 原图只约束布局，Boss 使用泥鳃 4×4 原图只约束布局；提交前复核 `high / 2K / 1:1`。

### `spore_pod_sheet_raw.png`

```text
Generate ONE exact 4 by 4 transparent top-down pixel-art sprite sheet for a single enemy species: the Spore Pod of 3F Left Atrium · Oxygenated Conservatory. A rooted but slightly crawling bio-mechanical fungal parasite with a charcoal root base, one plump deep-teal pod, three restrained pale-green oxygen bulbs, a cyan pulse seam, tiny amber spores and muted-crimson capillary threads. It must remain readable in one 32x32 logical cell and not resemble the first-floor slug. Exact 4 columns by 4 rows, 16 equal square cells, no gutters, no labels. Rows face down, left, right, up, indicated by the pod opening and root orientation. Columns are idle, swelling after being hit, one-beat explosion warning, compact detonation pose. Same identity, center pivot and ground baseline in every cell. No separate 3x3 blast cloud, scenery, floor, duplicate pod, grid lines, text, logo, watermark or checkerboard.
Original game-ready 2D top-down pixel art for the same Rhythm Ruins / Resonant Nexus rhythm-dungeon game. Strict crisp hard stepped pixel edges, limited 24-32 color palette, readable at the stated logical gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no photorealism, no 3D, no isometric perspective, no anime style, no labels, no text, no logo and no watermark. True alpha background.
```

### `vigor_sentinel_sheet_raw.png`

```text
Generate ONE exact 4 by 4 transparent top-down pixel-art sprite sheet for a single enemy species: the Vigor Sentinel of 3F Left Atrium · Oxygenated Conservatory. A compact upright bio-mechanical guard with a charcoal-slate body, broad forward oxygen shield shaped like a leaf-lung, cyan core slit, pale-green oxygen tubes, muted-crimson vessel joints and tiny amber rivets. The shield must make the front direction unmistakable, while the rear core remains vulnerable. Readable in one 32x32 logical cell. Exact 4 columns by 4 rows, no gutters, no labels. Rows face down, left, right, up. Columns are idle, shield raised, shielded step forward, shield bash attack. Same identity, center pivot and feet baseline in every cell; genuine directional rotations. No scenery, floor, extra weapon, duplicate guard, grid lines, text, logo, watermark or checkerboard.
Original game-ready 2D top-down pixel art for the same Rhythm Ruins / Resonant Nexus rhythm-dungeon game. Strict crisp hard stepped pixel edges, limited 24-32 color palette, readable at the stated logical gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no photorealism, no 3D, no isometric perspective, no anime style, no labels, no text, no logo and no watermark. True alpha background.
```

### `oxygen_reservoir_sheet_raw.png`

```text
Generate ONE exact 4 by 4 transparent top-down pixel-art boss sprite sheet for the Oxygen Reservoir, the Filling Brood-Mother of 3F Left Atrium · Oxygenated Conservatory. One huge elastic bio-mechanical orb visually occupying about a 3x3 gameplay area: layered deep-teal membrane, broad charcoal root cradle, central cyan oxygen-heart, pale-green pulmonary sacs, restrained muted-crimson vessel bands and small amber valves. Ancient and strange but not gory. Readable in one 64x64 logical sprite cell. Exact 4 columns by 4 rows, 16 equal square cells, no gutters, no labels. Rows face down, left, right, up, indicated by the central vent and membrane folds. Columns are idle, charge stage one contracted, charge stage two expanded, overload stage with exposed weak core. Same identity, center pivot and ground baseline. No room-wide warning frames, scenery, floor, extra creature, text, logo, watermark or checkerboard.
Original game-ready 2D top-down pixel art for the same Rhythm Ruins / Resonant Nexus rhythm-dungeon game. Strict crisp hard stepped pixel edges, limited 24-32 color palette, readable at the stated logical gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no photorealism, no 3D, no isometric perspective, no anime style, no labels, no text, no logo and no watermark. True alpha background.
```

## 第 4 层左心室主表

最终 Boss 使用 `venous_glutton_sheet_raw.png` 只约束 4×4 布局、单元中心和方向顺序；必须完全替换泥鳃身份，并在提交前复核 `high / 2K / 1:1`。

### `arrhythmia_boss_sheet_raw.png`

```text
Generate ONE exact 4 by 4 transparent top-down pixel-art final-boss sprite sheet for Arrhythmia, the Noise Sovereign, ruler of 4F Left Ventricle · Prime Heart Chamber. One giant compact multi-eyed noise parasite wrapped around a broken heart-core shell: asymmetric charcoal-violet armor, several small controlled magenta eyes, one central cyan life-energy wound, four thick corrupted conduit tendrils, restrained crimson tissue bands and sharp amber signal nodes. Menacing and alien but not anatomical gore. Readable in one 64x64 logical sprite cell. Exact 4 columns by 4 rows, 16 equal square cells, no gutters, no labels. Rows face down, left, right, up. Columns are idle, heavy bradycardia ground-slam pose, four-beat defibrillation overload pose, fast tachycardia claw-and-projectile attack pose. Same boss identity, center pivot and baseline; directions must be true rotations. Do not include the room heart core, corner conduits, full-screen spikes, multiple bosses, text, logo, watermark or checkerboard.
Original game-ready 2D top-down pixel art for the same Rhythm Ruins / Resonant Nexus rhythm-dungeon game. Strict crisp hard stepped pixel edges, limited 24-32 color palette, readable at the stated logical gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no photorealism, no 3D, no isometric perspective, no anime style, no labels, no text, no logo and no watermark. True alpha background.
```

## 四方向 hurt/death 单帧模板

每个单帧状态都从对应主表结果卡点击“以图生图”，参数保持 `gpt-image-2 / high / 2K / 1:1 / 1 张 / 透明请求`。实际粘贴时把 `<IDENTITY>`、`<LOGICAL_SIZE>`、`<DIRECTION>`、`<DIRECTION_CUE>` 和 `<DEATH_CUE>` 替换为下方身份表中的精确内容，再附共用像素风尾缀与透明资产尾缀。

### Hurt 模板

```text
Use the attached <IDENTITY> master sprite sheet as a strict identity, silhouette, palette, center-pivot and ground-baseline reference. Generate ONE single centered sprite, not a spritesheet and not multiple frames. Direction is STRICTLY <DIRECTION>: <DIRECTION_CUE>. Keep the exact same creature and do not reinterpret its species. State: a readable light-hit recoil; the body compresses slightly away from impact, one outer plate or membrane shows a small crack, the cyan core remains visible, and one restrained white-cyan impact chip touches the silhouette. The creature remains intact and recognizable. Fit inside one <LOGICAL_SIZE> logical pixel gameplay frame with balanced transparent padding and no external shadow. No extra creature, attack effect, projectile, floor, scenery, text, logo, watermark, checkerboard, grid or spritesheet. True alpha background.
```

### Death 模板

```text
Use the attached <IDENTITY> master sprite sheet as a strict identity, silhouette, palette, center-pivot and ground-baseline reference. Generate ONE single centered sprite, not a spritesheet and not multiple frames. Direction is STRICTLY <DIRECTION>: <DIRECTION_CUE>. Keep the exact same creature and do not reinterpret its species. State: defeated; <DEATH_CUE>. It must read as this exact creature's compact death state, not a new creature and not a large explosion. Fit inside one <LOGICAL_SIZE> logical pixel gameplay frame with balanced transparent padding and no external shadow. No extra creature, attack effect, projectile, floor, scenery, text, logo, watermark, checkerboard, grid or spritesheet. True alpha background.
```

### 通用方向替换

- `down`：`face DOWN toward the viewer; place the eyes, nozzle, shield-front, mouth-rim or core opening on the LOWER/front side of the body; never read as left, right or up.`
- `left`：`face LEFT in a true left-facing profile; the eyes, nozzle, shield-front, mouth-rim or core opening points to the LEFT edge and rear parts trail to the right; never use a symmetrical front view.`
- `right`：`face RIGHT in a true right-facing profile; the eyes, nozzle, shield-front, mouth-rim or core opening points to the RIGHT edge and rear parts trail to the left; never use a symmetrical front view.`
- `up`：`face UP away from the viewer; put the eyes, nozzle, shield-front, mouth-rim or core opening at the FAR TOP edge while the back shell dominates the center and lower half; never place the face cue at the bottom.`

### 身份与死亡替换表

| 文件前缀 | `<IDENTITY>` | `<LOGICAL_SIZE>` | `<DEATH_CUE>` |
| --- | --- | --- | --- |
| `gear_stalker` | `Gear Stalker` | `32x32` | `the segmented clockwork shell folds low, the amber flywheel stops, the cyan lens dims, and only a few copper gear teeth and muted-crimson cable pixels separate` |
| `steam_vent` | `Steam Vent` | `32x32` | `the squat valve body ruptures in a compact release, the cyan gauge goes dark, the brass nozzle buckles, and only a few restrained steam and rivet pixels separate` |
| `piston_colossus` | `Piston Colossus` | `64x64` | `the two heavy piston shoulders collapse inward, red and blue valve plates split, the cyan pressure-heart vents a compact life-energy pulse, and only a few brass and cable fragments separate` |
| `spore_pod` | `Spore Pod` | `32x32` | `the deep-teal pod folds into its charcoal root base, oxygen bulbs dim, and only a few pale-green spores and muted-crimson capillary pixels drift away` |
| `vigor_sentinel` | `Vigor Sentinel` | `32x32` | `the forward oxygen shield cracks and drops, the slate body kneels low, the cyan core dims, and only a few pale-green tube and amber rivet pixels separate` |
| `oxygen_reservoir` | `Oxygen Reservoir` | `64x64` | `the elastic membrane deflates into the charcoal root cradle, the cyan oxygen-heart opens and releases a compact pulse, and only a few pale-green sac and muted-crimson band fragments separate` |
| `arrhythmia` | `Arrhythmia, the Noise Sovereign` | `64x64` | `the asymmetric violet armor breaks away from the cyan heart wound, the controlled magenta eyes extinguish, corrupted tendrils collapse, and a compact cyan-gold restoration pulse escapes without a large explosion` |

## 第 2 层场地与招式特效

以下全部参数为 `gpt-image-2 / high / 2K / 1:1 / 文生图 / 1 张 / 透明请求`。

### `pressure_valve_gate_sheet_raw.png`

```text
Generate ONE exact horizontal 4-frame transparent top-down pixel-art spritesheet for the alternating hydraulic valve gates of 2F Right Ventricle. Each frame is one 64x64 logical cell, total 4 columns by 1 row, no gutters and one identical center pivot. Frame 1: a red valve barrier fully raised and blocking, with muted-crimson vessel bands and amber piston pins. Frame 2: the same red barrier fully lowered flush to the floor, passable. Frame 3: a blue-cyan valve barrier fully raised and blocking. Frame 4: the same blue-cyan barrier fully lowered, passable. The asset is only the compact gate mechanism, not a whole wall or room. No characters, monsters, text, symbols, labels, floor scenery, shadow, logo, watermark or checkerboard. True alpha background, strict crisp pixel art, limited charcoal, slate, crimson, cyan and amber palette.
```

### `steam_burst_sheet_raw.png`

```text
Generate ONE exact horizontal 4-frame transparent top-down pixel-art effect sheet for an adjacent-cell pressure-valve steam burst. Each frame is one 64x64 logical cell, total 4 columns by 1 row, no gutters and a fixed center pivot. Frame 1: tiny cyan pressure sparks gather at the center. Frame 2: a compact amber-red warning ring forms. Frame 3: a strong four-direction white-cyan steam burst fills the adjacent area with hard pixel clusters. Frame 4: only sparse fading steam pixels remain. Effect only, no valve creature, floor, characters, text, labels, logo, watermark or checkerboard. True alpha background and no soft smoke gradients.
```

### `piston_charge_sheet_raw.png`

```text
Generate ONE exact horizontal 4-frame transparent top-down pixel-art effect sheet for the Piston Colossus row-or-column charge. Each frame is one 64x64 logical cell, total 4 columns by 1 row, no gutters and a fixed center pivot. Frame 1: a narrow restrained red lock-line and amber pressure sparks. Frame 2: compressed cyan-white speed streaks point forward. Frame 3: a compact slate-and-amber wall-impact star with a few rock chips. Frame 4: small cyan dizzy sparks and leaking steam circle the same center to show two-beat stun. Effect only, no Boss body, whole wall, floor, text, labels, logo, watermark or checkerboard. True alpha background.
```

### `falling_rubble_sheet_raw.png`

```text
Generate ONE exact horizontal 4-frame transparent top-down pixel-art hazard sheet for falling rubble. Each frame is one 32x32 logical cell, total 4 columns by 1 row, no gutters and one center pivot. Frame 1: a small dark warning shadow with amber dust pixels. Frame 2: one compact slate rock falling into the cell. Frame 3: the rock breaks into three or four hard-edged chunks on impact. Frame 4: only a few fading dust and pebble pixels remain. No creature, room, text, label, logo, watermark, cast scenery or checkerboard. True alpha background.
```

## 第 3 层场地与招式特效

### `spore_explosion_sheet_raw.png`

```text
Generate ONE exact horizontal 4-frame transparent top-down pixel-art effect sheet for the Spore Pod's delayed 3x3-cell blast. Each frame is one 96x96 logical cell, total 4 columns by 1 row, no gutters and one center pivot. Frame 1: a compact teal pod-hit pulse. Frame 2: a readable amber-red one-beat warning ring with pale-green spores. Frame 3: a broad but clean 3x3-area cyan and pale-green spore explosion with restrained crimson edges. Frame 4: sparse spore dust fades from the same footprint. Effect only, no pod creature, floor, text, grid labels, logo, watermark or checkerboard. True alpha background; hard pixel clusters, no soft cloud gradients.
```

### `pulmonary_venous_jet_sheet_raw.png`

```text
Generate ONE exact horizontal 4-frame transparent top-down pixel-art effect sheet for a pulmonary-vein jet that pushes units two grid cells. Each frame is one 64x64 logical cell, total 4 columns by 1 row, no gutters and one center pivot. Frame 1: a thin cyan direction line lights from a small vessel nozzle edge. Frame 2: pale-green oxygen pressure gathers. Frame 3: a strong straight cyan-white liquid-energy jet crosses the cell. Frame 4: sparse teal mist pixels and two retreating ripples fade. Effect only, no complete wall, creature, floor, text, labels, logo, watermark or checkerboard. True alpha background; no soft gradients.
```

### `oxygen_charge_sheet_raw.png`

```text
Generate ONE exact horizontal 4-frame transparent top-down pixel-art warning/effect sheet for the Oxygen Reservoir's interruptible four-beat charge. Each frame is one 64x64 logical cell, total 4 columns by 1 row, no gutters and one fixed center pivot. Frame 1: a compact cyan core contraction surrounded by a clear yellow square pulse representing the 3x3 warning. Frame 2: the same center expands with an orange square pulse representing the 5x5 warning. Frame 3: a restrained crimson full-danger pulse with a bright exposed cyan center, no text or numbers. Frame 4: a white-cyan circular shockwave releases from that center. Use symbolic local effect shapes only, not an entire room map. No Boss body, floor, UI, labels, logo, watermark or checkerboard. True alpha background.
```

## 第 4 层场地、导管与结局特效

### `noise_conduit_sheet_raw.png`

```text
Generate ONE exact horizontal 4-frame transparent top-down pixel-art object sheet for one reusable corner Noise Conduit in 4F Left Ventricle. Each frame is one 64x64 logical cell, total 4 columns by 1 row, no gutters and one center pivot. The same compact corrupted bio-mechanical conduit in all frames: charcoal-violet pipe crown, controlled magenta eye-node, cyan energy stolen inside, muted-crimson vessel bands and amber clamps. Frame 1 idle and active. Frame 2 visibly hit with one white-cyan crack. Frame 3 breaking with the eye-node failing and the pipe split. Frame 4 destroyed low remains with a small cyan life-energy release. One object only; no Boss, wall, floor, multiple conduits, text, labels, logo, watermark or checkerboard. True alpha background.
```

### `ground_spike_wave_sheet_raw.png`

```text
Generate ONE exact horizontal 4-frame transparent top-down pixel-art effect sheet for Arrhythmia's heavy bradycardia ground-spike wave. Each frame is one 64x64 logical cell, total 4 columns by 1 row, no gutters and one center pivot. Frame 1: thin violet-crimson ground cracks. Frame 2: short warning spikes begin to rise. Frame 3: a high jagged charcoal-violet spike crest with cyan fracture light. Frame 4: spikes collapse into sparse rock and magenta noise fragments. Effect only, no Boss, floor tile background, text, labels, logo, watermark or checkerboard. True alpha background.
```

### `defibrillation_countdown_sheet_raw.png`

```text
Generate ONE exact horizontal 4-frame transparent top-down pixel-art effect sheet for a four-beat defibrillation overload warning before a BPM change. Each frame is one 64x64 logical cell, total 4 columns by 1 row, no gutters and one identical heart-centered pivot. Frame 1: a dim cyan broken-heart pulse with one restrained violet arc. Frame 2: stronger cyan contraction with two violet arcs. Frame 3: bright magenta danger contraction with amber edge sparks. Frame 4: a sharp white-cyan defibrillation flash surrounded by a violet warning ring. Communicate escalating four beats without numerals, letters, clock faces or text. Effect only, no Boss, room, UI panel, logo, watermark or checkerboard. True alpha background.
```

### `noise_projectile_sheet_raw.png`

```text
Generate ONE exact horizontal 4-frame transparent top-down pixel-art projectile sheet for a single corrupted noise bolt. Each frame is one 32x32 logical cell, total 4 columns by 1 row, no gutters and one center pivot. The same compact projectile pulses through four animation states: sharp violet shell, cyan unstable center, restrained magenta echo fragments and one amber warning pixel. It must remain one projectile that can be spawned by code in three directions, not three projectiles drawn together. No character, weapon, floor, text, labels, logo, watermark or checkerboard. True alpha background.
```

### `heart_core_restoration_sheet_raw.png`

```text
Generate ONE exact horizontal 4-frame transparent top-down pixel-art effect/object sheet for the Prime Heart restoration ending. Each frame is one 96x96 logical cell, total 4 columns by 1 row, no gutters and one identical center pivot. Frame 1: a cracked heart-shaped slate core restrained by violet noise bands. Frame 2: the bands peel away and a compact cyan center restarts. Frame 3: cyan, gold and emerald life-energy expands through broad clean veins. Frame 4: the same stable calm heart core glows cyan-green with small amber highlights and no remaining corruption. Ancient and life-giving, not anatomical or horrific. One heart core only; no altar, room, character, text, labels, logo, watermark or checkerboard. True alpha background.
```

## 原图验收顺序

1. 文件名与结果卡匹配，原图未被裁剪、缩放或改写。
2. 背景为 16:9 且 11×6 大地砖、右墙门位和中心开放区可读；主表严格 4×4；多帧素材严格单行 4 帧；单帧严格一对象一方向一状态。
3. 角色身份、朝向、动作语义和策划机制正确；无额外碎图、重复对象、标签、文字、Logo 或水印。
4. 记录实际像素尺寸与色彩模式。页面透明请求若仍返回 RGB 棋盘格/白底，只记录真实事实，不修改原图。
5. 记录生成时间、模型、质量、分辨率、比例、模式、完整提示词、页面是否显示 seed 和 SHA-256；失败候选另名保留。


## 2026-09-04 扩展批次：场景/角色/传送门/转场提示词规范

本节与 `GENERATION_QUEUE.md` 末尾的 CURRENT PENDING 队列绑定。统一参数、参考图、下载与原图审计规则沿用文件前文；本批全部原图到齐前不派生、不导入 Godot。

### 生成顺序

1. 先生成 15 张房间背景，再生成 12 个角色/Boss 主表；每个主表通过结果卡“以图生图”生成对应方向 hurt/death。
2. 再生成机制特效、中央传送门、开始页背景和 4 张层间/终局转场插图。
3. 每一项完成后立即下载至队列中的精确 raw 文件名；失败结果另存 candidate，不覆盖目标。

### 场景背景通用提示词

```text
Create one top-down 2D pixel-art dungeon chamber for the specified heart chamber and room role. Preserve a strict orthographic 16:9 composition with one readable walkable board of exactly 11 columns by 6 rows, using large open square floor tiles and the same lower entrance corridor and right-wall exit placement as the attached first-layer reference. Keep the center open for player, enemies and mechanisms. Use the specified biome palette and room details from the design appendix. The scene is a background only: no characters, enemies, Boss, items, portal, UI, text, logo, watermark, isometric perspective, 3D, small decorative sub-grid, extra tile columns, extra tile rows or full-screen fog. Crisp hard-edged pixel art, no blur or painterly gradients.
```

将 `<ROOM_SPEC>` 替换为队列表对应房间：

- 2F-01：oxidized brass pressure-release chamber, clean cast-iron tiles, large peripheral relief valves, calm warm brass accents.
- 2F-02：biomechanical power room, sparse steam vents at the perimeter, a distant heavy piston rod, scorched edge tiles.
- 2F-03：symmetrical pressure-control shrine, central clear four-tile reward space, warm brass core glow, no enemies.
- 2F-04：pressurized reconstruction room, cracked wall steam seams, sparse dark oil-and-blood stains, open center.
- 2F-05：piston-colossus forge arena, twin hydraulic cylinder walls, dark horizontal and vertical pressure rails, open Boss center.
- 3F-01：oxygenated venous spring chamber, translucent cyan vessels, calm storage sacs at edges, wet slate floor.
- 3F-02：glowing mycelium cultivation chamber, shallow water reflections, cyan moss and peripheral spore growth.
- 3F-03：life-fluid irrigation shrine, central pale-cyan calyx pedestal area, one suspended clean blood-vessel droplet.
- 3F-04：high-pressure oxygen greenhouse, tall pulmonary-vessel columns at edges, reserved jet openings, blue-green light.
- 3F-05：oxygen reservoir incubation pool, four peripheral pulmonary jet openings, smooth central floor and gentle water rings.
- 4F-01：damaged prime sanctuary porch, ancient pale stone columns, small violet crystal infection at edges, distant golden heart glow.
- 4F-02：noise-crystal corridor, sparse dark-violet crystals in floor seams, short flowing noise traces on the walls.
- 4F-03：ultimate tuning shrine, intact tuning-fork monument, clean gold-violet concentric resonance waves, quiet center.
- 4F-04：noise-bed trial room, thick dark-violet conduits rising mainly along edges, restrained red-violet flicker, open routes.
- 4F-05：prime heart altar arena, corrupted heart core recess in the far background, four empty corner conduit sockets, grand pale-stone ring walls.

Append the common pixel-art suffix and the negative prompt from the beginning of this file.

### 角色主表通用提示词

```text
Generate ONE exact transparent 4x4 top-down pixel-art sprite sheet for <IDENTITY>. The sheet has 4 equal rows facing down, left, right, up and 4 equal columns: <FRAME_1>, <FRAME_2>, <FRAME_3>, <FRAME_4>. No gutters, no labels, no extra sprites, one stable center pivot and ground baseline. Fit the creature into <LOGICAL_SIZE> per cell. Reuse only the attached reference's sheet layout and pivot; do not reuse its species identity. <IDENTITY_DESCRIPTION>. Keep the shape readable at gameplay size and use the layer palette. No room, floor, UI, text, logo, watermark, duplicate creature, checkerboard, 3D, isometric view or anti-aliased edges. True alpha requested, crisp hard pixel edges.
```

角色替换表：

- `gear_stalker`：compact brass four-legged clockwork insect, one red lens, rear wind-up key; patrol, sprint windup and sprint frames.
- `steam_vent`：heavy cast-iron bell pressure valve on a one-cell base, side gauge, cross-shaped exhaust cap; pressure and steam release frames.
- `pneumatic_vanguard`：small heavy plated biped carrying a hydraulic hammer and compact boiler; hammer windup, strike and stagger frames.
- `piston_colossus`：2x2 heavy brass-and-iron biomechanical piston guardian, hydraulic arms, restrained crimson pressure core; lock, charge and wall-stunned frames.
- `spore_pod`：translucent cyan-green swelling spore sac with a small heartbeat crystal; swell, warning and detonate frames.
- `vigor_sentinel`：one-cell blue crystalline bio-shell shield bearer with exposed rear cyan core; shield, step and attack frames.
- `resonance_medusa`：small floating cyan-lilac jellyfish with four restrained electric tendrils and a rhythmic core; drift, cross telegraph and pulse frames.
- `oxygen_reservoir`：3x3 elastic oxygen-filled cyan reservoir sphere with translucent veins and a bright central core; charge stages and stagger frames.
- `noise_scuttler`：one-cell black-violet crystal carapace scuttler with a small controlled magenta noise node; scream and arc frames.
- `arrhythmic_phantom`：one-cell desaturated violet-grey tuning warden afterimage holding a broken tuning fork, readable silhouette, no face detail; fade, phase-in and strike frames.
- `conduit_warden`：one-cell black armored conduit host with a compact violet conduit on its back and a controlled red-violet eye node; shield, link and break frames.
- `arrhythmia_boss`：3x3 giant multi-eyed noise sovereign wrapped around a broken heart-core shell; columns show bradycardia slam, defibrillation overload, tachycardia claw/projectile attack and defeated collapse while preserving one identity.

### 四方向 hurt/death

Use the existing Hurt/Death templates in this file. For every new identity, generate 8 single-frame transparent images from its accepted master result card, preserving the exact direction, logical size, center pivot and foot baseline.

### 机制特效通用提示词

```text
Generate ONE exact horizontal 4-frame transparent top-down pixel-art effect sheet for <EFFECT>. Each frame is <FRAME_SIZE>, total 4 columns by 1 row, no gutters and one stable center pivot. Frames are: <FRAME_SEQUENCE>. Effect only, no character, room, floor, UI, text, logo, watermark, duplicate effects or checkerboard. True alpha requested, crisp hard pixel edges, limited project palette, readable at gameplay scale.
```

替换 `<EFFECT>` 与 `<FRAME_SEQUENCE>`：

- red/blue valve gates: closed, rising, fully raised, lowering; each 64x64.
- steam burst: pressure, warning, white-hot release, dissipating steam; each 64x64.
- piston strike: locked rail, accelerating impact, wall collision, stunned sparks; each 64x64.
- spore explosion: intact warning, swelling cloud, 3x3 cyan detonation, fading spores; each 96x96.
- pulmonary jet: rim warning, compression, cyan water jet, mist fade; each 64x64.
- oxygen charge: 3x3 yellow pulse, 5x5 orange pulse, red overload, circular shockwave; each 96x96.
- medusa cross pulse: dim cross, bright cross, outward water pulse, fade; each 96x96.
- noise conduit: idle, cracked, breaking, destroyed with cyan energy; each 64x64.
- ground spike wave: cracks, short warning spikes, peak violet spikes, collapse; each 96x96.
- defibrillation countdown: dim cyan pulse, stronger pulse, magenta overload, white-cyan flash; each 96x96, no numbers.
- noise projectile: violet shell, cyan core, magenta fragments, amber warning pixel; each 32x32.
- heart restoration: corrupted shell, noise peeling, cyan restart, stable gold-green core; each 96x96.

### 中央传送门

```text
Generate ONE exact horizontal 4-frame transparent 2D top-down pixel-art central next-layer portal object sheet. Each frame is 64x64, total 4 columns by 1 row, no gutters and one center pivot. The same portal evolves from sealed to active: <PORTAL_STYLE>. Frame 1 sealed, frame 2 a narrow energy fissure, frame 3 the portal opens, frame 4 stable pulsing destination. Object only, no wall, floor, character, room, text, logo, watermark or checkerboard. True alpha requested, binary-alpha friendly hard pixels.
```

- 2F portal style: oxidized brass pressure iris with cyan-white steam and small amber clamps.
- 3F portal style: clean cyan-blue oxygen geyser ring with upward floating droplets and pale green life energy.
- 4F portal style: gold-white prime-heart resonance dais with controlled violet remnants peeling away.

### 初始界面背景

```text
Create a single atmospheric 16:9 top-down 2D pixel-art title-screen background for the Withered Forest / Heart-Core Ruins rhythm dungeon. In the upper center distance, show a colossal prime heart core deep in an ancient cavern, with restrained gold and cyan life conduits. In the lower foreground, show the back-view silhouette of the lone tuning-fork swordsman standing before a ruined entrance and bleached forest. Keep a broad dark low-detail empty area in the lower center, approximately 400x250 logical pixels, for the game title and menu buttons. No text, logo, UI, watermark, close-up face, modern sci-fi, 3D, isometric view or photorealism. Crisp pixel art, 16:9, readable under a dark UI overlay.
```

### 层间转场插图

```text
Create one cinematic but compact 16:9 2D pixel-art transition illustration with no text or UI. Use a dark vignette and a clear central focal action, leaving enough dark negative space for a short program-rendered transition caption. Preserve the same Withered Forest / Heart-Core Ruins palette and hard pixel edges. Depict exactly the specified transition: <TRANSITION_SCENE>. No extra characters, no duplicate objects, no logo, no watermark, no 3D or isometric view.
```

- `trans_atrium_to_ventricle_raw.jpeg`: the central portal sends the traveler downward through bronze pressure pipes, passing gears and steam into 2F.
- `trans_ventricle_to_atrium_raw.jpeg`: brass pressure flow opens into a calm blue-green oxygen greenhouse with floating luminous spores.
- `trans_atrium_to_ventricle4_raw.jpeg`: blue-green flow is swallowed by violet noise crystals and the entrance of the prime heart chamber.
- `trans_ending_revival_raw.jpeg`: the prime heart stabilizes, gold-green waves restore the bleached forest, thawing a stream and reviving trees.

### 全屏心跳擦拭 Overlay

```text
Generate ONE exact horizontal 4-frame transparent full-screen heartbeat wipe effect sheet. Each frame is 960x540, total 3840x540, no gutters. Frame 1 a thin cyan heartbeat line, frame 2 a growing cyan-gold wave, frame 3 a broad dark-green wipe with violet edge, frame 4 a clean dark transition field with a small cyan heart pulse. No text, UI, room details, characters or watermark. True alpha requested, crisp pixel edges and stable timing-friendly silhouette.
```
