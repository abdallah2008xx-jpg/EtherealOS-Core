const Main = imports.ui.main;
const PopupMenu = imports.ui.popupMenu;
const Util = imports.misc.util;
const GLib = imports.gi.GLib;
const St = imports.gi.St;

let _injected = [];

function init(metadata) {
    // Nothing needed
}

function _tryAddToPanel(panel) {
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
    
    // ── Task Manager (with icon, like Windows 11) ──
    let taskMgrItem = new PopupMenu.PopupIconMenuItem(
        "Task Manager",
        "utilities-system-monitor",
        St.IconType.SYMBOLIC
    );
    taskMgrItem.connect('activate', function() {
        Util.spawnCommandLine("/usr/bin/python3 " + GLib.get_home_dir() + "/ethereal-update/Ethereal-TaskMgr.py");
    });

    // ── System Settings shortcut ──
    let settingsItem = new PopupMenu.PopupIconMenuItem(
        "Settings",
        "preferences-system",
        St.IconType.SYMBOLIC
    );
    settingsItem.connect('activate', function() {
        Util.spawnCommandLine("cinnamon-settings");
    });

    // ── Terminal shortcut ──
    let terminalItem = new PopupMenu.PopupIconMenuItem(
        "Terminal",
        "utilities-terminal",
        St.IconType.SYMBOLIC
    );
    terminalItem.connect('activate', function() {
        Util.spawnCommandLine("x-terminal-emulator");
    });

    // ── File Manager shortcut ──
    let filesItem = new PopupMenu.PopupIconMenuItem(
        "Files",
        "system-file-manager",
        St.IconType.SYMBOLIC
    );
    filesItem.connect('activate', function() {
        Util.spawnCommandLine("nemo");
    });

    // Separator
    let sep = new PopupMenu.PopupSeparatorMenuItem();
    
    // Insert at top of menu (position 0, 1, 2...)
    menu.addMenuItem(taskMgrItem, 0);
    menu.addMenuItem(sep, 1);
    menu.addMenuItem(settingsItem, 2);
    menu.addMenuItem(terminalItem, 3);
    menu.addMenuItem(filesItem, 4);
    
    let sep2 = new PopupMenu.PopupSeparatorMenuItem();
    menu.addMenuItem(sep2, 5);
    
    _injected.push({ 
        menu: menu,
        items: [taskMgrItem, sep, settingsItem, terminalItem, filesItem, sep2]
    });
}

function enable() {
    try {
        let pm = Main.panelManager;
        if (pm && pm.panels) {
            for (let i = 0; i < pm.panels.length; i++) {
                if (pm.panels[i]) {
                    _tryAddToPanel(pm.panels[i]);
                }
            }
        }
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
            let items = _injected[i].items;
            for (let j = 0; j < items.length; j++) {
                if (items[j]) items[j].destroy();
            }
        } catch(e) {}
    }
    _injected = [];
}
