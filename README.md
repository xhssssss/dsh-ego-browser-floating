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
