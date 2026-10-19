# 红色警戒2 · Windows 显示兼容修复

这是 `ra2` 游戏目录的修复脚本、配置与复现说明。仓库不包含游戏本体、安装包、序列号、存档或过场动画，需自行准备合法取得的游戏文件。

本机已验证：修复启动黑屏后，可以进入原版主菜单与单机遭遇战并正常操作；最终全屏大小和鼠标点击位置也经实际确认。修复不改变兵种、规则或地图。

## 最终采用的设置

- 使用 [cnc-ddraw 7.1](https://github.com/FunkyFr3sh/cnc-ddraw/releases/tag/v7.1.0.0) 替代原目录中的旧 Wine DirectDraw 组件。
- 使用 Direct3D 9、独占全屏及原版 800×600 分辨率，使固定大小的菜单正常显示。
- 移除游戏程序的旧 Windows 98／2000 兼容模式；`game.exe` 使用应用程序 DPI 缩放（`HIGHDPIAWARE`）。
- 通过 `Ra2.exe` 原启动器启动；此安装实测直接运行 `game.exe` 会退出。

测试屏幕为 2560×1600。原版画面为 4:3，宽屏显示器保留左右黑边属于正常比例显示。本机尝试过无边框宽屏和系统 DPI 缩放，分别出现菜单缩小、画面或鼠标位置异常，因此没有采用。这些结论限于本次安装和硬件环境。

## 安装

先退出游戏。将本仓库的脚本和 `config`、`repair-tools` 目录放入自己的游戏目录，保留现有游戏文件。然后用 PowerShell 执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Compatibility.ps1
```

也可以把仓库放在其他目录，并明确指定游戏位置：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Compatibility.ps1 -GameDirectory 'E:\ra2'
```

安装脚本从 cnc-ddraw 官方 GitHub 下载固定版本并校验 SHA256，备份现有显示文件和兼容模式设置，再应用配置。它保留 `RA2.INI` 中的其他设置；不会启动游戏或更改系统全局显示设置。一般不需要管理员权限。

离线安装可以预先下载同一发布包，通过 `-ArchivePath 'C:\Downloads\cnc-ddraw.zip'` 指定文件，仍须通过同样的校验。

下载地址：<https://github.com/FunkyFr3sh/cnc-ddraw/releases/download/v7.1.0.0/cnc-ddraw.zip>

SHA256：`0B13AB89A64C9918189B1DADD449EF6ED3CB3B7B19CABD96D8ADBD95505BB908`

显示组件由上游项目提供，遵循其 [MIT 许可证](https://github.com/FunkyFr3sh/cnc-ddraw/blob/v7.1.0.0/LICENSE)。本仓库不重复分发其二进制文件。

## 启动与恢复

双击游戏目录中的 `Ra2.exe`，或同目录的 `Play-RA2.cmd`。单机对战入口为“单人游戏 → 遭遇战”。`Alt+Enter` 切换窗口／全屏，`Ctrl+Tab` 释放鼠标。

需要重新应用显示设置时，先退出游戏，再运行 `repair-tools\Apply-Fullscreen.ps1`；该脚本应放在游戏目录的 `repair-tools` 子目录。

安装脚本会输出本次备份位置。要恢复安装前的文件与兼容模式，先退出游戏，再执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Restore-Compatibility.ps1 -BackupDirectory 'E:\ra2\repair-backup\compat-实际备份编号'
```

这里的备份格式由 `Install-Compatibility.ps1` 创建，与之前人工修复的旧备份不同。不要将备份目录或其中的游戏文件上传至公开仓库。

## 文件用途

| 文件 | 用途 |
| --- | --- |
| `Install-Compatibility.ps1` | 下载并校验显示组件，备份并应用修复 |
| `Restore-Compatibility.ps1` | 恢复指定安装批次的文件和兼容模式 |
| `Play-RA2.cmd` | 以正确工作目录运行原启动器 |
| `config/ddraw.ini` | 可分享的最小显示配置，不含个人数据 |
| `config/RA2.INI` | 仅包含片头和分辨率设置的配置示例 |
| `repair-tools/Apply-Fullscreen.ps1` | 在游戏目录内重新应用最终显示设置 |
| `.gitignore` | 使用白名单，只允许上述脚本、示例配置和说明被 Git 跟踪 |
| `.gitattributes` | 固定脚本、配置与说明的换行格式 |

本次使用的旧安装还精简了音乐和过场动画。显示修复无法恢复缺失的游戏资源。
