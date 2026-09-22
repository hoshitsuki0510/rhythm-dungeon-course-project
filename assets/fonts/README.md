# 《律动遗迹》像素字体

## 正式使用

当前 MVP 使用：`FusionPixel_12px_Proportional_zh_hans.ttf`

- 来源：<https://github.com/TakWolf/fusion-pixel-font>
- Release：`2026.08.11`
- 下载包：`fusion-pixel-font-12px-proportional-ttf-v2026.08.11.zip`
- 下载地址：<https://github.com/TakWolf/fusion-pixel-font/releases/download/2026.08.11/fusion-pixel-font-12px-proportional-ttf-v2026.08.11.zip>
- 下载包 SHA-256：`58cc7021a24749ad9405845e499a2ef0a1709e2d90adc242cf198cb278dc065e`
- 变体：12 px、比例模式、简体中文（`zh_hans`）
- SHA-256：`5f43f090748d2ee00792d942a1257f44723b807b5cfefa133a856a3a0c5ff702`
- 许可证：SIL Open Font License 1.1，完整文本见 [FusionPixel_LICENSE-OFL.txt](FusionPixel_LICENSE-OFL.txt)；上游组件许可证见 `FusionPixel_LICENSES/`

选择该版本是因为它针对中日韩像素排版提供比例模式，官方说明比例模式适合一般 UI；在本项目实际中文 UI、ASCII、数字和节拍符号语料上完成了字符覆盖检查，并在 Godot 4.7.2 的 960×540 MVP 六种状态捕获中检查了 12–33 px 的清晰度、混排基线和长文本布局。

Godot 会在导入时识别该文件为像素字体，并关闭 hinting 与 subpixel positioning；项目导入设置同时关闭系统字体回退，避免缺字时悄悄混入非像素字形。正式入口由 `scripts/mvp/mvp_controller.gd` 通过 `FontFile` 载入；不要改用 macOS 专有系统字体作为默认字体。

## 渠道与下载复核（2026-08-28）

免费渠道中，Google Fonts 的目录页和 CSS 接口可以访问，但 `fonts.google.com/download?family=...` 当前返回的是 HTML 目录页而不是 ZIP；这不是项目文件损坏。通过 CSS 返回的 `fonts.gstatic.com` 直链可以下载 Press Start 2P、Silkscreen、Pixelify Sans、Tiny5、VT323 和 DotGothic16，但前五个没有项目所需的简体中文，DotGothic16 仍缺少“动、遗、步、节、战、敌、键”等核心字，因此没有把 Google Fonts 作为正式字体。Fusion Pixel 的 GitHub Release 直链可稳定下载并已按 SHA-256 校验，满足本项目的中文覆盖、像素清晰度和 UI 混排要求；不需要进入付费字体流程。

## 免费候选的取舍

本次对比过的免费/公开候选保留在 `candidates/` 或研究目录记录中：

- Z Labs Pixel 12px：覆盖和授权声明完整，但作者明确提示仍有字形不协调；实际 MVP 对比中中英文混排和小字号观感不如 Fusion，因此未作为正式字体。
- Ark Pixel Font：OFL-1.1，但当前版本仍缺少大量汉字，官方字符统计也标为开发中，不适合作为本项目唯一中文字体。
- Z Labs RoundPix 16px：OFL-1.1、风格偏圆，官方提示中宫和部件仍在调整；与本项目的窄栏 HUD 不匹配。
- Zpix、Pix32：视觉质量较高，但其官方说明对商业产品另行收费/限制使用，未作为本项目的免费正式字体。
- 其他点阵或自动补字候选存在缺字、错误字形、过密或 30 px 放大重叠问题，未接入。

字体本身不得脱离软件单独出售；若以后公开发布包含字体文件的游戏包，请一并保留本目录的许可证和来源说明。
