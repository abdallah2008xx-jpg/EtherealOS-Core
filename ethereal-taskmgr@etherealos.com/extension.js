const Main = imports.ui.main;
const PopupMenu = imports.ui.popupMenu;
const Util = imports.misc.util;
const GLib = imports.gi.GLib;
const St = imports.gi.St;

let _injected = [];

function init(metadata) {
    // Nothing needed here
}

function _addTaskManagerToPanel(panel) {
    if (!panel || !panel._panelContextMenu) return;
    
    let menu = panel._panelContextMenu;
    
    // Create separator
    let sep = new PopupMenu.PopupSeparatorMenuItem();
    menu.addMenuItem(sep, 0);
    
    // Create "Task Manager" item with icon - insert at top (position 0)
    let item = new PopupMenu.PopupIconMenuItem(
        "Task Manager",
        "utilities-system-monitor",
        St.IconType.SYMBOLIC
    );
    
    item.connect('activate', function() {
        let pyPath = GLib.get_home_dir() + "/ethereal-update/Ethereal-TaskMgr.py";
        Util.spawnCommandLine("/usr/bin/python3 " + pyPath);
    });
    
    menu.addMenuItem(item, 0);
    
    _injected.push({ menu: menu, item: item, sep: sep });
}

function enable() {
    // Inject into ALL panels (top, bottom, side)
    let panels = Main.panelManager.panels;
    for (let i = 0; i < panels.length; i++) {
        if (panels[i]) {
            _addTaskManagerToPanel(panels[i]);
        }
    }
}

function disable() {
    for (let i = 0; i < _injected.length; i++) {
        let record = _injected[i];
        if (record.item) record.item.destroy();
        if (record.sep) record.sep.destroy();
    }
    _injected = [];
}
