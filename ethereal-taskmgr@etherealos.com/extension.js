const Main = imports.ui.main;
const PopupMenu = imports.ui.popupMenu;
const Util = imports.misc.util;
const GLib = imports.gi.GLib;
const St = imports.gi.St;
const Lang = imports.lang;

let _injected = [];

function init(metadata) {
    // Nothing needed
}

function _tryAddToPanel(panel) {
    // Cinnamon panels can have different context menu property names
    let menu = null;
    
    if (panel._context_menu)
        menu = panel._context_menu;
    else if (panel._panelContextMenu)
        menu = panel._panelContextMenu;
    else if (panel.contextMenu)
        menu = panel.contextMenu;
    
    if (!menu) return;
    
    // Don't add twice
    for (let i = 0; i < _injected.length; i++) {
        if (_injected[i].menu === menu) return;
    }
    
    // Create "Task Manager" menu item
    let item = new PopupMenu.PopupMenuItem("  Task Manager");
    
    item.connect('activate', function() {
        let pyPath = GLib.get_home_dir() + "/ethereal-update/Ethereal-TaskMgr.py";
        Util.spawnCommandLine("/usr/bin/python3 " + pyPath);
    });
    
    // Add separator then item at top
    let sep = new PopupMenu.PopupSeparatorMenuItem();
    
    menu.addMenuItem(item, 0);
    menu.addMenuItem(sep, 1);
    
    _injected.push({ menu: menu, item: item, sep: sep });
}

function enable() {
    // Try all panels
    try {
        let pm = Main.panelManager;
        if (pm && pm.panels) {
            for (let i = 0; i < pm.panels.length; i++) {
                if (pm.panels[i]) {
                    _tryAddToPanel(pm.panels[i]);
                }
            }
        }
        // Also try Main.panel directly (older Cinnamon)
        if (Main.panel) {
            _tryAddToPanel(Main.panel);
        }
    } catch(e) {
        global.logError("EtherealTaskMgr: " + e.message);
    }
}

function disable() {
    for (let i = 0; i < _injected.length; i++) {
        try {
            if (_injected[i].item) _injected[i].item.destroy();
            if (_injected[i].sep) _injected[i].sep.destroy();
        } catch(e) {}
    }
    _injected = [];
}
