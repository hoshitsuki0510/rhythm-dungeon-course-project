# 第一层 hurt/death 续批 12 张原图提示词台账

本文件记录 2026-08-31 续批生成的泥浆喷吐者 right/up 4 张与静脉吸附者·泥鳃四方向 8 张单帧状态的 BHai 提示词。页面参数均为 `gpt-image-2 / high / 2K / 1:1 / 图生图 / 1 张`，参考图分别来自 `spit_slug_sheet_raw.png` 与 `venous_glutton_sheet_raw.png` 的站内结果卡；页面未显示 seed。喷吐者 down/left 4 张属于此前暂停前批次，不在本文件重复登记。

每张已选原图的实际提交提示词，等于下方对应“正文模板”替换方向条款后，追加一个半角空格和“共用风格尾缀”。除此之外没有追加文字。

## 共用风格尾缀

```text
Original 2D top-down pixel art for the same Withered Forest / Heart-Core Ruins rhythm dungeon game. Strict crisp pixel art, hard stepped 1-pixel edges, limited 24-32 color palette: charcoal green, slate stone, muted crimson, cyan life energy, and small amber highlights. Readable at small gameplay size and friendly to nearest-neighbor scaling. No anti-aliasing, no blur, no smooth gradients, no painterly rendering, no 3D, no isometric perspective, no anime style, no text, no logo, no watermark.
```

## 泥浆喷吐者

### 受击正文模板

```text
Use the attached Spit Slug master sprite sheet as a strict identity, silhouette, palette, center-pivot and ground-baseline reference. Generate ONE single centered sprite, not a spritesheet and not multiple frames. <DIRECTION> State: a clear light-hit recoil; the body compresses slightly away from impact, the nozzle and eyes stay recognizable, and one restrained white-cyan impact chip touches the silhouette. The creature remains intact. Fit inside one 32x32 logical pixel gameplay frame with balanced transparent padding and no external shadow. No extra creature, mud projectile, floor, scenery, text, logo, watermark, checkerboard, grid, or spritesheet. True alpha background.
```

### 死亡正文模板

```text
Use the attached Spit Slug master sprite sheet as a strict identity, silhouette, palette, center-pivot and ground-baseline reference. Generate ONE single centered sprite, not a spritesheet and not multiple frames. <DIRECTION_AND_STATE> Fit inside one 32x32 logical pixel gameplay frame with balanced transparent padding and no external shadow. No extra creature, projectile, floor, scenery, text, logo, watermark, checkerboard, grid, or spritesheet. True alpha background.
```

### 已选文件的精确替换条款

- `spit_slug_hurt_right_raw.png` 的 `<DIRECTION>`：

```text
The exact same low mud-parasite Spit Slug faces right: compact rounded dark-brown and charcoal mud body, small amber-brown throat nozzle, two tiny cyan life-energy eyes, and sparse muted-crimson vein streaks.
```

- `spit_slug_death_right_raw.png` 的 `<DIRECTION_AND_STATE>`：

```text
The exact same low mud-parasite Spit Slug faces right and is defeated: its dark-brown mud body collapses into a compact flattened heap, the amber-brown throat nozzle is visibly cracked, the two cyan eyes dim, and only a few restrained cyan and muted-crimson pixel fragments separate from the body. It must read as this exact enemy's death state, not a new creature and not a large explosion.
```

- `spit_slug_hurt_up_raw.png` 的实际正文没有使用受击模板，完整正文为：

```text
Use the attached Spit Slug master sprite sheet as a strict identity, silhouette, palette, center-pivot and ground-baseline reference. Generate ONE single centered sprite, not a spritesheet and not multiple frames. Direction is STRICTLY UP, away from the viewer: show the back shell as the dominant surface, place the small amber-brown throat nozzle only at the FAR TOP edge of the body, and keep the two tiny cyan eyes near that top edge; never place the nozzle or eyes at the bottom, and do not face down or toward the viewer. The exact same low mud-parasite Spit Slug has a compact rounded dark-brown and charcoal mud body with sparse muted-crimson vein streaks. State: a clear light-hit recoil; the body compresses slightly away from impact, the nozzle and eyes remain directionally correct, and one restrained white-cyan impact chip touches the silhouette. The creature remains intact. Fit inside one 32x32 logical pixel gameplay frame with balanced transparent padding and no external shadow. No extra creature, mud projectile, floor, scenery, text, logo, watermark, checkerboard, grid, or spritesheet. True alpha background.
```

- `spit_slug_death_up_raw.png` 的实际正文没有使用死亡模板，完整正文为：

```text
Use the attached Spit Slug master sprite sheet as a strict identity, silhouette, palette, center-pivot and ground-baseline reference. Generate ONE single centered sprite, not a spritesheet and not multiple frames. Direction is STRICTLY UP, away from the viewer: show the back shell as the dominant surface, place the cracked amber-brown throat nozzle only at the FAR TOP edge of the body, and keep the two dim cyan eyes near that top edge; never place the nozzle or eyes at the bottom, and do not face down or toward the viewer. The exact same low mud-parasite Spit Slug is defeated: its dark-brown mud body collapses into a compact flattened heap, the throat nozzle is visibly cracked, the cyan eyes dim, and only a few restrained cyan and muted-crimson pixel fragments separate from the body. It must read as this exact enemy's death state, not a new creature and not a large explosion. Fit inside one 32x32 logical pixel gameplay frame with balanced transparent padding and no external shadow. No extra creature, projectile, floor, scenery, text, logo, watermark, checkerboard, grid, or spritesheet. True alpha background.
```

### 拒绝候选

`spit_slug_hurt_up_candidate1_raw.png` 因喷口与双眼仍落在画面下侧、方向读作 down 而被拒绝。它使用的正文为：

```text
Use the attached Spit Slug master sprite sheet as a strict identity, silhouette, palette, center-pivot and ground-baseline reference. Generate ONE single centered sprite, not a spritesheet and not multiple frames. The exact same low mud-parasite Spit Slug faces up: compact rounded dark-brown and charcoal mud body, small amber-brown throat nozzle, two tiny cyan life-energy eyes, and sparse muted-crimson vein streaks. State: a clear light-hit recoil; the body compresses slightly away from impact, the nozzle and eyes stay recognizable, and one restrained white-cyan impact chip touches the silhouette. The creature remains intact. Fit inside one 32x32 logical pixel gameplay frame with balanced transparent padding and no external shadow. No extra creature, mud projectile, floor, scenery, text, logo, watermark, checkerboard, grid, or spritesheet. True alpha background.
```

## 静脉吸附者·泥鳃

### 朝下受击正文

```text
Use the attached Venous Glutton · Mudgill master sprite sheet as a strict identity, silhouette, palette, center-pivot and ground-baseline reference. Generate ONE single centered boss sprite, not a spritesheet and not multiple frames. The exact same huge compact Venous Glutton · Mudgill faces down: broad dark-slate and muddy-olive shell, central cyan heart-gill, four to six thick muted-crimson venous fins, wide mudgill mouth-rim, and small amber sediment nodes. State: a clear light-hit recoil; the heavy shell compresses slightly away from impact, one outer mud plate cracks, the heart-gill stays lit, and one restrained white-cyan impact chip touches the silhouette. The boss remains intact and recognizable. Fit inside one 64x64 logical pixel gameplay frame with balanced transparent padding and no external shadow. No extra creature, attack effect, mud projectile, floor, scenery, text, logo, watermark, checkerboard, grid, or spritesheet. True alpha background.
```

### 朝下死亡正文

```text
Use the attached Venous Glutton · Mudgill master sprite sheet as a strict identity, silhouette, palette, center-pivot and ground-baseline reference. Generate ONE single centered boss sprite, not a spritesheet and not multiple frames. The exact same huge compact Venous Glutton · Mudgill faces down and is defeated: its broad muddy-olive shell collapses and visibly splits, the central cyan heart-gill opens and releases a compact pulse of cyan life-energy, and only a few restrained muted-crimson venous-fin and amber sediment fragments separate from the body. It must read as this exact boss's death state, not a new creature and not a large explosion. Fit inside one 64x64 logical pixel gameplay frame with balanced transparent padding and no external shadow. No extra creature, attack effect, floor, scenery, text, logo, watermark, checkerboard, grid, or spritesheet. True alpha background.
```

### 左右受击正文模板

```text
Use the attached Venous Glutton · Mudgill master sprite sheet as a strict identity, silhouette, palette, center-pivot and ground-baseline reference. Generate ONE single centered boss sprite, not a spritesheet and not multiple frames. Direction is STRICTLY <SIDE>: turn the exact same huge compact Venous Glutton · Mudgill into a <side>-facing profile, with the central cyan heart-gill and wide mudgill mouth-rim clearly pointing toward the <SIDE> edge, the main dark-slate and muddy-olive shell ridge occupying the <OPPOSITE>/rear half, and four to six thick muted-crimson venous fins trailing backward toward the <opposite>. Do not face down, up, front, or <opposite>, and do not use a symmetrical front view. Small amber sediment nodes remain visible. State: a clear light-hit recoil; the heavy shell compresses slightly away from impact, one outer mud plate cracks, the heart-gill stays lit, and one restrained white-cyan impact chip touches the silhouette. The boss remains intact and recognizable. Fit inside one 64x64 logical pixel gameplay frame with balanced transparent padding and no external shadow. No extra creature, attack effect, mud projectile, floor, scenery, text, logo, watermark, checkerboard, grid, or spritesheet. True alpha background.
```

### 左右死亡正文模板

```text
Use the attached Venous Glutton · Mudgill master sprite sheet as a strict identity, silhouette, palette, center-pivot and ground-baseline reference. Generate ONE single centered boss sprite, not a spritesheet and not multiple frames. Direction is STRICTLY <SIDE>: keep the exact same huge compact Venous Glutton · Mudgill in a <side>-facing profile, with the central cyan heart-gill and wide mudgill mouth-rim pointing toward the <SIDE> edge, the main shell ridge occupying the <OPPOSITE>/rear half, and muted-crimson venous fins trailing backward toward the <opposite>. Do not face down, up, front, or <opposite>, and do not use a symmetrical front view. State: defeated; its broad muddy-olive shell collapses and visibly splits, the cyan heart-gill opens and releases a compact pulse of life-energy, and only a few restrained venous-fin and amber sediment fragments separate from the body. It must read as this exact boss's death state, not a new creature and not a large explosion. Fit inside one 64x64 logical pixel gameplay frame with balanced transparent padding and no external shadow. No extra creature, attack effect, floor, scenery, text, logo, watermark, checkerboard, grid, or spritesheet. True alpha background.
```

左右文件替换规则：

- `venous_glutton_{hurt,death}_left_raw.png`：`<SIDE>=LEFT`、`<side>=left`、`<OPPOSITE>=right`、`<opposite>=right`。
- `venous_glutton_{hurt,death}_right_raw.png`：`<SIDE>=RIGHT`、`<side>=right`、`<OPPOSITE>=left`、`<opposite>=left`。

### 朝上受击正文

```text
Use the attached Venous Glutton · Mudgill master sprite sheet as a strict identity, silhouette, palette, center-pivot and ground-baseline reference. Generate ONE single centered boss sprite, not a spritesheet and not multiple frames. Direction is STRICTLY UP, away from the viewer: place the central cyan heart-gill and wide mudgill mouth-rim only at the FAR TOP edge of the body, make the broad dark-slate and muddy-olive back shell the dominant surface across the center and lower half, and have four to six thick muted-crimson venous fins trail rearward toward the BOTTOM. Never place the heart-gill at the bottom, and do not face down, front, left, or right. Small amber sediment nodes remain visible. State: a clear light-hit recoil; the heavy shell compresses slightly away from impact, one outer mud plate cracks, the heart-gill stays lit, and one restrained white-cyan impact chip touches the silhouette. The boss remains intact and recognizable. Fit inside one 64x64 logical pixel gameplay frame with balanced transparent padding and no external shadow. No extra creature, attack effect, mud projectile, floor, scenery, text, logo, watermark, checkerboard, grid, or spritesheet. True alpha background.
```

### 朝上死亡正文

```text
Use the attached Venous Glutton · Mudgill master sprite sheet as a strict identity, silhouette, palette, center-pivot and ground-baseline reference. Generate ONE single centered boss sprite, not a spritesheet and not multiple frames. Direction is STRICTLY UP, away from the viewer: keep the central cyan heart-gill and wide mudgill mouth-rim only at the FAR TOP edge of the body, make the broad back shell dominate the center and lower half, and have muted-crimson venous fins trail rearward toward the BOTTOM. Never place the heart-gill at the bottom, and do not face down, front, left, or right. State: defeated; its broad muddy-olive shell collapses and visibly splits, the cyan heart-gill opens and releases a compact pulse of life-energy from the top-facing side, and only a few restrained venous-fin and amber sediment fragments separate from the body. It must read as this exact boss's death state, not a new creature and not a large explosion. Fit inside one 64x64 logical pixel gameplay frame with balanced transparent padding and no external shadow. No extra creature, attack effect, floor, scenery, text, logo, watermark, checkerboard, grid, or spritesheet. True alpha background.
```
