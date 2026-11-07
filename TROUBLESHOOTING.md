# 实机安装记录与排错（2026-11-07）

在一台**全新的 Windows 机器**上按 README 完整走了一遍，记录实际结果与文档不符的地方。

## 按 README 走的步骤

```powershell
dsh plugin --profile web add dsh-ego-browser@0.8.6
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\apply.ps1
node --check .\0.8.6\patched\lib\client.js
```

结果是：**7 个文件都成功复制**（与 `patched/` 快照哈希逐一相同），但脚本以**退出码 1** 结束，报 `floating patch marker missing`。

---

## 问题 1：apply.ps1 的最终断言已失效，脚本必然报错

`scripts/apply.ps1` 第 37–39 行：

```powershell
$client = Get-Content -LiteralPath (Join-Path $target 'lib\client.js') -Raw -Encoding UTF8
if ($client -notmatch 'EGO_FORCE_FLOATING_PATCH') { throw "floating patch marker missing" }
```

但 `0.8.6\patched\lib\client.js` 里**没有任何 `EGO_FORCE_FLOATING_PATCH` 字样**（实测 0 处）。补丁早已改写成 `mergeSidebar` 开关实现：

```js
betterSidebarService = void 0;
if (!mergeSidebar) betterSidebarService = void 0;
```

**后果**：每次运行都在"已经成功"之后抛异常，使用者会以为失败，进而重复执行或误判环境坏了。

**建议**：删掉这段断言，或改成

```powershell
if ($client -notmatch 'mergeSidebar') { throw "floating patch marker missing" }
```

---

## 问题 2：任何 `dsh plugin add` / `install` 都会静默还原补丁

README 只提到「重新 `pnpm install` 后文件被覆盖」。实测影响范围更大：**安装或卸载任意插件**都会触发 pnpm 重新链接，把三个文件还原成官方原版。

验证方式（新机器上复现）：

```powershell
$inst = "$env:USERPROFILE\.dsh\profiles\web\node_modules\dsh-ego-browser"
foreach ($rel in 'lib\client.js','lib\index.js','runtime\ego-linux\src\chrome.mjs') {
  $a = (Get-FileHash (Join-Path $inst $rel)).Hash
  $b = (Get-FileHash ".\0.8.6\original-0.8.6\$rel").Hash
  "{0,-40} {1}" -f $rel, $(if ($a -eq $b) { '已被还原' } else { '仍是补丁版' })
}
```

**后果**：agent 浏览器悄悄退回官方行为——挂到 better-sidebar 侧栏，悬浮球消失，看起来像"插件不见了"。

**建议**：每次装/卸插件后固定跑一次校验；把 `reapply-ego-patch.ps1`（见文末）放进日常流程。

---

## 问题 3：宿主半边改动需要重启 DSH，不是刷新页面

`lib/index.js` 的改动（新增 `/api/ego/background` 路由、`ego_window` 工具）只有在**宿主重启**后才存在。README 里「保存后刷新页面生效」只适用于 `mergeSidebar` 这类纯客户端行为。

**典型症状**：客户端已经画出「退回后台」按钮，点了完全没反应。原因是客户端是补丁版、宿主还是原版，请求打到不存在的路由（404）。

路由对比：

| 路由 / 工具 | 原版 | 补丁版 |
|---|---|---|
| `/api/ego/raise`（弹出窗口） | 有 | 有 |
| `/api/ego/background`（退回后台） | **无** | 有 |
| `ego_window` 工具 | **无** | 有 |

**正确顺序**：装插件 → 打补丁 → **重启 DSH** → 刷新页面 → 验证 `#dsh-ego-fab`。

诊断方法：F12 看该请求状态码，**404 = 宿主仍是原版**（需要重启），**401 = 会话 cookie 问题**。

---

## 问题 4：README §5 的重打脚本路径不存在

README 第 5 节写：

```
powershell -File "D:\AI\agent\deepseek\ego-browser-backup-0.8.6\reapply-patch.ps1"
```

这是作者机器上的绝对路径，新机器上必然不存在。实际脚本在仓库的 `0.8.6\reapply-patch.ps1`。

**建议**：改成相对路径，或直接指向 `scripts/apply.ps1`。

---

## 问题 5：`--open` 是唯一可靠的弹窗手段（当面板还不可用时）

补丁默认把窗口移到屏幕外（`-32000,-32000`）。如果此时 DSH 面板还没出来（插件未加载/未重启），就没有「弹出窗口」按钮可点，人无法登录。

运行时自带 CLI 可以救：

```powershell
node "$env:USERPROFILE\.dsh\profiles\web\node_modules\dsh-ego-browser\runtime\ego-linux\bin\ego-browser.mjs" --open
```

执行后窗口恢复到屏幕内，并进入 30 分钟可见模式。这一条在 `0.8.6/README.md` 第 3 节有写，但顶层 README 没有，容易漏。

---

## 一份可用的重打脚本

建议随仓库提供一个不依赖绝对路径的版本：

```powershell
param(
  [string]$ProfileDir = "$env:USERPROFILE\.dsh\profiles\web",
  [string]$PatchRoot  = "$PSScriptRoot\..\0.8.6\patched",
  [switch]$Verify
)
$target = Join-Path $ProfileDir 'node_modules\dsh-ego-browser'
if (-not (Test-Path $target)) { throw "dsh-ego-browser 未安装: $target" }
$files = @('lib\client.js','lib\index.js','runtime\ego-linux\src\chrome.mjs')

if ($Verify) {
  foreach ($rel in $files) {
    $a = (Get-FileHash (Join-Path $target $rel)).Hash
    $b = (Get-FileHash (Join-Path $PatchRoot $rel)).Hash
    "{0,-40} {1}" -f $rel, $(if ($a -eq $b) { 'PATCHED' } else { 'ORIGINAL/MISMATCH' })
  }
  return
}

$backup = Join-Path $target ('.patch-backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
Get-ChildItem -LiteralPath $PatchRoot -Recurse -File |
  Where-Object { $_.Name -notlike '*.bak' } |
  ForEach-Object {
    $rel = $_.FullName.Substring($PatchRoot.Length).TrimStart('\')
    $dst = Join-Path $target $rel
    $dir = Split-Path $dst -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    if (Test-Path $dst) {
      $bd = Join-Path $backup $rel
      if (-not (Test-Path (Split-Path $bd -Parent))) { New-Item -ItemType Directory -Force -Path (Split-Path $bd -Parent) | Out-Null }
      Copy-Item $dst $bd -Force
    }
    Copy-Item $_.FullName $dst -Force
  }
foreach ($rel in @('lib\client.js','lib\index.js')) {
  node --check (Join-Path $target $rel)
  if ($LASTEXITCODE -ne 0) { throw "node --check failed: $rel" }
}
Write-Host "已重打补丁；宿主要重启，页面要刷新。"
```

---

## 验证清单（安装后按顺序）

1. 三个文件哈希与 `0.8.6/patched` 一致
2. `node --check lib/client.js`、`node --check lib/index.js` 通过
3. **重启 DSH**
4. 刷新页面
5. 控制台执行 `document.getElementById('dsh-ego-fab')` → 应返回元素而非 `null`
6. `chrome://version` 的启动命令行应含 `--mute-audio`、`--start-minimized`、`--disable-blink-features=AutomationControlled`
7. 点「退回后台」→ 窗口应回到屏幕外；若无效，F12 看请求是否 404
