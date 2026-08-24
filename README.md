# Rhythm Dungeon Prototype

一个为两周小学期课程制作的 2D 像素音乐节奏闯关游戏。项目使用 Godot 4.7.2 标准版与 GDScript，先建立可解释、可测试、可答辩的最小闭环，再逐步加入内容与表现。

## 当前状态

- Godot 工程与 Git 仓库已初始化。
- 当前主场景是环境验证用占位首页，尚未实现正式节奏玩法。
- 已配置 macOS DMG 与 Windows x86_64 EXE/PCK 导出预设。
- Windows 正式构建由用户在另一台 Windows 电脑上做实机测试，不使用虚拟机。

## 打开项目

在 Godot 项目管理器中导入本目录，或在终端执行：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --editor --path "/Users/hoshitsuki/大二上/小学期程序实践"
```

无界面启动检查：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path "/Users/hoshitsuki/大二上/小学期程序实践"
```

成功时会输出 `INIT_SMOKE_OK` 并自动退出。

## 目录

- `scenes/`：Godot 场景。
- `scripts/`：GDScript 源码。
- `assets/`：像素图、瓦片、音频、字体等项目资源。
- `开发记录/`：答辩需要的决策、日志、问题、环境和里程碑证据。
- `builds/`：本机构建输出，不纳入 Git。

## 导出

Godot 菜单中使用 `项目 → 导出`，选择 `macOS` 或 `Windows Desktop` 预设。默认目标分别为：

- `builds/macos/RhythmDungeonPrototype.dmg`
- `builds/windows/RhythmDungeonPrototype.exe` 与同目录 PCK

正式构建前先确认当前 Git 工作区状态，并在 `开发记录/01-环境与构建.md` 中登记版本与测试结果。
