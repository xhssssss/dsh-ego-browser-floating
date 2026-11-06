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
