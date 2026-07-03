.pragma library

function getScale(mw, userScale) {
    if (mw <= 0) return 1.0;
    let r = mw / 1920.0;
    let baseScale = 1.0;
    
    if (r <= 1.0) {
        baseScale = Math.max(0.35, Math.pow(r, 0.85));
    } else {
        // SCALING UP:
        baseScale = Math.pow(r, 0.5);
    }
    
    // Multiply the screen-calculated scale by the user's uiScale
    return baseScale * (userScale !== undefined ? userScale : 1.0);
}

// Helper to easily round scaled values
function s(val, scale) {
    return Math.round(val * scale);
}

// Centralized registry for all widget dimensions and positional mathematics.
// anchorX (optional): screen-local x to center a position-following popup under
// (e.g. the network popup follows its bar applet). Ignored by fixed-position popups.
function getLayout(name, mx, my, mw, mh, userScale, anchorX) {
    let scale = getScale(mw, userScale);

    let base = {
        // Right-aligned: pinned 20px from the right edge dynamically
        "powermenu": { w: mw, h: mh, rx: 0, ry: 0, comp: "power/PowerMenuOverlay.qml" },
        
        // Right-aligned: pinned 20px from the right edge dynamically (Width: 900 + 20 margin = 920)
        "network":   { w: s(440, scale), h: s(560, scale), rx: mw - s(460, scale), ry: s(70, scale), comp: "network/NetworkPopup.qml" },
        
        "plugininstall": { w: s(560, scale), h: s(620, scale), rx: Math.floor((mw/2)-(s(560, scale)/2)), ry: Math.floor((mh/2)-(s(620, scale)/2)), comp: "plugins/PluginInstallPopup.qml" },
        "sysinfo":   { w: s(500, scale), h: s(640, scale), rx: Math.floor((mw/2)-(s(500, scale)/2)), ry: Math.floor((mh/2)-(s(640, scale)/2)), comp: "sysinfo/SysInfoCard.qml" },
        "focustime": { w: s(900, scale), h: s(720, scale), rx: Math.floor((mw/2)-(s(900, scale)/2)), ry: Math.floor((mh/2)-(s(720, scale)/2)), comp: "focustime/FocusTimePopup.qml" },
        "hello":     { w: mw, h: mh, rx: 0, ry: 0, comp: "hello/HelloPopup.qml" },

        // Full width, centered vertically
        "wallpaper": { w: mw, h: s(650, scale), rx: 0, ry: Math.floor((mh/2)-(s(650, scale)/2)), comp: "wallpaper/WallpaperPicker.qml" },
        
        "hidden":    { w: 1, h: 1, rx: -5000 - mx, ry: -5000 - my, comp: "" } 
    };

    if (!base[name]) return null;

    let t = base[name];

    // Position-following popups: center under the supplied anchor x, clamped on-screen.
    // Falls back to the default (right-pinned) rx when no valid anchor is given.
    if (name === "network" && anchorX !== undefined && anchorX !== null && !isNaN(anchorX) && anchorX >= 0) {
        let margin = s(12, scale);
        let rx = Math.round(anchorX - t.w / 2);
        rx = Math.max(margin, Math.min(rx, mw - t.w - margin));
        t.rx = rx;
    }

    // Calculate final absolute coordinates based on active monitor offset
    t.x = mx + t.rx;
    t.y = my + t.ry;

    return t;
}

// -----------------------------------------------------------------------------
// Separate Layout function for the Notification OSD popups
// -----------------------------------------------------------------------------
function getPopupLayout(mw, userScale) {
    let scale = getScale(mw, userScale);
    return {
        // You can change dimensions and position here
        w: s(350, scale),
        marginTop: s(70, scale),
        marginRight: s(20, scale),
        
        // We can also centralize internal UI scaling sizes here if desired
        spacing: s(12, scale),
        radius: s(14, scale),
        padding: s(12, scale)
    };
}
