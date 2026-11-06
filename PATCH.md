# Patch details

## lib/client.js

Original chooses sidebar tab whenever ctx.get("betterSidebar") returns a service:

    if (betterSidebarService !== void 0) ctx.effect(() => mountSidebarTab(...));
    else { ... mountFloatingWatch ... }

Patched forces the floating branch and disables the later betterSidebar injection:

    // EGO_FORCE_FLOATING_PATCH
    betterSidebarService = void 0;
    if (false) ctx.inject(["betterSidebar"], ...)

## runtime/ego-linux/src/chrome.mjs

Chrome launch args add:

- --mute-audio
- --start-minimized
- --disable-blink-features=AutomationControlled

The window is parked off-screen (left/top -32000, 516x320) and restored only through the panel's pop-out action.

## lib/index.js

Keeps the Google login fix and popup/download capture from the 0.8.6 patch set.

## Settings additions (2026-11-06)

### enableSound

- lib/index.js: new boolean schema key, resolveConfig default false, ALLOWED_KEYS.
- lib/index.js resolveEgoEnv: sets EGO_BROWSER_UNMUTE=1/0 from the config.
- runtime/ego-linux/src/chrome.mjs: LAUNCH_FLAGS only includes --mute-audio when EGO_BROWSER_UNMUTE is not truthy.
- Default false = muted. Windows volume mixer may start at 0; raise it manually.
- Takes effect on the next Chrome cold start.

### mergeSidebar

- lib/index.js: new boolean schema key, resolveConfig default false, ALLOWED_KEYS.
- lib/client.js: new settings rows; save/load mirror the value to localStorage key ego.mergeSidebar.
- lib/client.js panel mount: reads localStorage; false forces floating, true uses dsh-better-sidebar.
- Refresh the page after saving.
