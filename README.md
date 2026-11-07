# dsh-ego-browser 0.8.6 悬浮窗改版

> **本仓库全部内容由 DeepSeek Harness 生成。** 生成时间：2026-11-06。

这是 dsh-ego-browser 0.8.6 的悬浮窗改版，公开仓库。

上游：https://github.com/Fisfzy/dsh-ego-browser
许可证：MIT（见 LICENSE）

## 三个版本

| 版本 | 位置 | 说明 |
|---|---|---|
| 0.8.6 官方原版 | 0.8.6/original-0.8.6 | 未改动，供 diff |
| 0.8.6 悬浮窗改版 | 0.8.6/patched | 当前使用 |
| 0.9.10 官方最新 | 0.9.10/dsh-ego-browser-0.9.10.tgz | 仅存档，未替换 |

## 改了什么

### 1. 强制悬浮窗

0.8.6 原版检测到 dsh-better-sidebar 时会把观察窗挂到右侧栏。patched/lib/client.js 加了：

    // EGO_FORCE_FLOATING_PATCH
    betterSidebarService = void 0;
    if (false) ctx.inject(["betterSidebar"], ...)

效果：better-sidebar 仍然可用，但 ego-browser 始终使用悬浮观察球/悬浮窗。

### 2. 静音与后台

runtime/ego-linux/src/chrome.mjs 的 Chrome 启动参数包含：

    --mute-audio
    --start-minimized
    --disable-blink-features=AutomationControlled

窗口会被放到屏外（left=-32000, top=-32000, 516x320），需要人工登录时用面板里的 Pop out window。

### 3. 登录与弹出窗口

patched/lib/index.js 和 client.js 保留 Google 登录修复、弹出窗口捕获、下载捕获。

## 插件设置（设置 → 插件 → ego-browser）

新增两项，都在插件设置页，不放悬浮窗按钮：

- **启用 agent 浏览器声音**（默认关闭）
  - 关闭：Chrome 以 --mute-audio 启动，完全静音。
  - 开启：不再加 --mute-audio；声音交给 Windows 音量合成器。
  - 默认在合成器里可能是 0，需要手动调高；下次浏览器冷启动生效。
- **合并到边栏**（默认关闭）
  - 关闭：悬浮观察球/悬浮窗。
  - 开启：注册为 dsh-better-sidebar 标签页。
  - 保存后刷新页面生效，不要求立刻切换。

## 前置条件

这是一个插件补丁，不是完整的 DSH 安装包。

- DSH 0.2.2-rc.1 或兼容版本
- 已安装官方 dsh-ego-browser@0.8.6
- 若启动报 connection (required) webRuntime，先按 dsh-recovery 的 docs/ROOT-CAUSE-webRuntime.md 修复
- dsh-setting-restart 是可选便利插件，单独私有仓库，不是本插件的运行依赖

## 安装

先装官方 0.8.6：

    dsh plugin --profile web add dsh-ego-browser@0.8.6

再打补丁：

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\apply.ps1

脚本会备份旧文件到 .patch-backups，不会删除其他文件。

## 验证

    node --check 0.8.6/patched/lib/client.js
    node --check 0.8.6/patched/lib/index.js

在 DSH 页面刷新后检查：

    #dsh-ego-fab 可见
    #dsh-ego-panel 存在
    ego 侧栏节点不存在

## 说明

- 设置重启插件的改版不在这里，它在单独的私有仓库。
- vision-router 的 webStartup 修复属于 DSH 配置补丁，不在本仓库。

## 安装踩坑记录

在一台全新机器上按本 README 实测后，发现了几处文档与脚本本身的问题（`apply.ps1` 的断言必然报错、装任意插件都会静默还原补丁、宿主半边改动必须重启 DSH 等）。详见 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)，含可用的重打脚本与验证清单。
