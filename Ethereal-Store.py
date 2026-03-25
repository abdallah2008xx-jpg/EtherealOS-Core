#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import os, threading, urllib.request, shutil

CSS = b"""
window { background-color: transparent; }
#main-bg {
    background-color: rgba(12, 14, 25, 0.98);
    border-radius: 20px;
    border: 1px solid rgba(126, 215, 255, 0.2);
    box-shadow: 0 15px 60px rgba(0,0,0,0.9);
}

.sidebar {
    background-color: rgba(0, 0, 0, 0.4);
    border-right: 1px solid rgba(255, 255, 255, 0.05);
    border-radius: 20px 0 0 20px;
    padding: 20px 10px;
}

list row.tab-row {
    background: transparent; color: #8892b0;
    padding: 14px 20px; margin: 4px 10px;
    border-radius: 12px; font-weight: bold; font-size: 14px;
    transition: all 250ms ease;
}
list row.tab-row:hover { background: rgba(255, 255, 255, 0.05); color: #ffffff; }
list row.tab-row:selected {
    background: rgba(126, 215, 255, 0.15);
    color: #7ed7ff; border-left: 4px solid #7ed7ff;
}

.search-bar { background: rgba(255,255,255,0.05); color: white; border: 1px solid rgba(255,255,255,0.1); border-radius: 12px; padding: 10px; font-size: 15px; margin: 10px 30px; }
.search-bar:focus { border: 1px solid #7ed7ff; box-shadow: 0 0 10px rgba(126,215,255,0.3); }

.app-card {
    background-color: rgba(255, 255, 255, 0.03);
    border: 1px solid rgba(255, 255, 255, 0.05);
    border-radius: 16px; padding: 20px; margin: 15px;
}
.app-card:hover {
    background-color: rgba(255, 255, 255, 0.06);
    border: 1px solid rgba(126, 215, 255, 0.3);
    box-shadow: 0 0 30px rgba(126, 215, 255, 0.15);
}

.app-name { color: #ffffff; font-size: 20px; font-weight: bold; }
.app-desc { color: #a3b2fa; font-size: 13px; margin-top: 5px; }

.install-btn {
    background: transparent; color: #00ff88; font-weight: bold; border-radius: 10px;
    border: 2px solid rgba(0,255,136, 0.4); padding: 8px 24px; transition: all 250ms;
}
.install-btn:hover { background: rgba(0,255,136, 0.1); box-shadow: 0 0 15px rgba(0,255,136, 0.3); }
.installed-btn { background: rgba(255,255,255,0.05); color: #8892b0; font-weight: bold; border-radius: 10px; border: 2px solid rgba(255,255,255, 0.1); padding: 8px 24px; }
"""

APPS = [
    {"id": "discord", "name": "Discord", "cat": "Internet", "desc": "Chat for Communities and Friends", "repo": "srevinsaju/Discord-AppImage", "icon": "discord"},
    {"id": "spotify", "name": "Spotify", "cat": "Media", "desc": "Music Player and Podcasts", "repo": "srevinsaju/Spotify-AppImage", "icon": "spotify"},
    {"id": "heroic", "name": "Heroic Games", "cat": "Games", "desc": "Epic, GOG & Amazon Games Launcher", "repo": "Heroic-Games-Launcher/HeroicGamesLauncher", "icon": "applications-games"},
    {"id": "freetube", "name": "FreeTube", "cat": "Media", "desc": "Private YouTube Client (No Ads)", "repo": "FreeTubeApp/FreeTube", "icon": "youtube"},
    {"id": "upscayl", "name": "Upscayl", "cat": "Media", "desc": "Free AI Image Upscaler", "repo": "upscayl/upscayl", "icon": "applications-graphics"},
    {"id": "localsend", "name": "LocalSend", "cat": "Internet", "desc": "AirDrop for Linux (Share Files)", "repo": "localsend/localsend", "icon": "network-workgroup"},
    {"id": "rpcs3", "name": "RPCS3 Emulator", "cat": "Games", "desc": "PlayStation 3 Emulator", "repo": "RPCS3/rpcs3-binaries-linux", "icon": "applications-games"},
    {"id": "audacity", "name": "Audacity", "cat": "Media", "desc": "Professional Audio Editor", "repo": "audacity/audacity", "icon": "applications-multimedia"},
    {"id": "floorp", "name": "FloorP Browser", "cat": "Internet", "desc": "Most Private Firefox Fork", "repo": "Floorp-Projects/Floorp", "icon": "web-browser"},
    {"id": "vscodium", "name": "VSCodium", "cat": "Productivity", "desc": "Free Open Source VS Code", "repo": "VSCodium/vscodium", "icon": "text-editor"},
    {"id": "bitwarden", "name": "Bitwarden", "cat": "Internet", "desc": "Secure Password Manager", "repo": "bitwarden/clients", "icon": "dialog-password"},
    {"id": "obsidian", "name": "Obsidian", "cat": "Productivity", "desc": "Personal Knowledge Base", "repo": "obsidianmd/obsidian-releases", "icon": "accessories-text-editor"},
    {"id": "kdenlive", "name": "Kdenlive", "cat": "Media", "desc": "Pro Video Editor", "repo": "KDE/kdenlive", "icon": "applications-multimedia"},
    {"id": "anydesk", "name": "AnyDesk", "cat": "Internet", "desc": "Remote Desktop Software", "repo": "srevinsaju/anydesk-appimage", "icon": "preferences-desktop-remote"},
    {"id": "postman", "name": "Postman", "cat": "Productivity", "desc": "API Platform Toolkit", "repo": "srevinsaju/Postman-AppImage", "icon": "applications-development"}
]

class AppStore(Gtk.Window):
    def __init__(self):
        super().__init__(title="Ethereal Software Center")
        self.set_default_size(1150, 780)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_app_paintable(True)
        if self.get_screen().get_rgba_visual() and self.get_screen().is_composited():
            self.set_visual(self.get_screen().get_rgba_visual())

        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        main_box.set_name("main-bg")
        self.add(main_box)
        
        self.app_dir = os.path.expanduser("~/Applications")
        os.makedirs(self.app_dir, exist_ok=True)
        self.shortcut_dir = os.path.expanduser("~/.local/share/applications")
        os.makedirs(self.shortcut_dir, exist_ok=True)
        
        # Sidebar
        self.sidebar = Gtk.ListBox(); self.sidebar.set_name("sidebar"); self.sidebar.set_size_request(240, -1)
        self.sidebar.connect("row-activated", self.on_cat_changed)
        main_box.pack_start(self.sidebar, False, False, 0)
        
        cats = ["🔥 Discover All", "🌐 Internet", "🎮 Games", "🎬 Media", "💼 Productivity"]
        for c in cats:
            r = Gtk.ListBoxRow(); r.set_name("tab-row")
            r.add(Gtk.Label(label=c, xalign=0)); self.sidebar.add(r)
        
        # Main Area
        right_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        main_box.pack_start(right_vbox, True, True, 0)
        
        self.search = Gtk.SearchEntry(placeholder_text="Search Ethereal Store..."); self.search.set_name("search-bar")
        self.search.connect("search-changed", self.on_search)
        right_vbox.pack_start(self.search, False, False, 10)
        
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        right_vbox.pack_start(scroll, True, True, 0)
        
        self.flow = Gtk.FlowBox(); self.flow.set_valign(Gtk.Align.START)
        self.flow.set_max_children_per_line(2); self.flow.set_min_children_per_line(1)
        self.flow.set_selection_mode(Gtk.SelectionMode.NONE)
        
        align_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        align_box.pack_start(self.flow, True, True, 20)
        scroll.add(align_box)
        
        self.cards = []
        for app in APPS: self.build_card(app)
        
        self.sidebar.select_row(self.sidebar.get_row_at_index(0))

    def build_card(self, app):
        card = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL); card.set_name("app-card")
        card.set_size_request(420, 120)
        
        icon = Gtk.Image.new_from_icon_name(app["icon"], Gtk.IconSize.DIALOG)
        if not icon.get_pixbuf(): icon = Gtk.Image.new_from_icon_name("application-x-executable", Gtk.IconSize.DIALOG)
        icon.set_pixel_size(64); icon.set_margin_right(20)
        card.pack_start(icon, False, False, 0)
        
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL); vbox.set_valign(Gtk.Align.CENTER)
        name = Gtk.Label(label=app["name"], xalign=0); name.set_name("app-name")
        desc = Gtk.Label(label=app["desc"], xalign=0); desc.set_name("app-desc")
        
        self.pbar = Gtk.ProgressBar(); self.pbar.set_visible(False); self.pbar.set_margin_top(15)
        app["pbar"] = self.pbar
        
        vbox.pack_start(name, False, False, 0)
        vbox.pack_start(desc, False, False, 0)
        vbox.pack_start(self.pbar, False, False, 0)
        card.pack_start(vbox, True, True, 0)
        
        btn = Gtk.Button()
        if os.path.exists(os.path.join(self.shortcut_dir, f"ethereal_{app['id']}.desktop")):
            btn.set_label("INSTALLED"); btn.set_name("installed-btn"); btn.set_sensitive(False)
        else:
            btn.set_label("INSTALL"); btn.set_name("install-btn"); btn.connect("clicked", self.on_install, app)
        
        btn.set_valign(Gtk.Align.CENTER)
        app["btn"] = btn
        card.pack_end(btn, False, False, 10)
        
        app["widget"] = card
        app["visible"] = True
        self.flow.add(card)
        self.cards.append(app)

    def filter_apps(self, term, category):
        for app in self.cards:
            match = True
            if category and category != "Discover All":
                if app["cat"] not in category: match = False
            if term and term not in app["name"].lower() and term not in app["desc"].lower():
                match = False
            
            if match and not app["visible"]:
                app["widget"].show()
                app["visible"] = True
            elif not match and app["visible"]:
                app["widget"].hide()
                app["visible"] = False

    def on_search(self, search_entry):
        cat_row = self.sidebar.get_selected_row()
        cat = cat_row.get_child().get_label().split(" ", 1)[1] if cat_row else None
        self.filter_apps(search_entry.get_text().lower(), cat)

    def on_cat_changed(self, lb, row):
        cat = row.get_child().get_label().split(" ", 1)[1]
        self.filter_apps(self.search.get_text().lower(), cat)

    def on_install(self, btn, app):
        btn.set_sensitive(False); btn.set_label("CONNECTING..."); btn.set_name("install-btn")
        app["pbar"].set_visible(True)
        threading.Thread(target=self.download_app, args=(app,), daemon=True).start()

    def download_app(self, app):
        try:
            # Bypass GitHub API Limits by scraping HTML for exact direct download URL!
            repo_url = f"https://github.com/{app['repo']}/releases/latest"
            req = urllib.request.Request(repo_url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0)'})
            GLib.idle_add(app["btn"].set_label, "FETCHING...")
            
            try:
                html = urllib.request.urlopen(req).read().decode('utf-8')
                dl_url = None
                for line in html.split('"'):
                    if line.endswith('.AppImage') and '/releases/download/' in line:
                        dl_url = "https://github.com" + line
                        break
            except:
                dl_url = None
                
            if not dl_url:
                GLib.idle_add(self.fail, app, "App Download Missing (404)")
                return
                
            filename = dl_url.split('/')[-1]
            out_path = os.path.join(self.app_dir, filename)
            
            GLib.idle_add(app["btn"].set_label, "DOWNLOADING...")
            
            def report(count, block, total):
                pct = min(1.0, count * block / total) if total > 0 else 0
                GLib.idle_add(app["pbar"].set_fraction, pct)
                
            urllib.request.urlretrieve(dl_url, out_path, reporthook=report)
            os.chmod(out_path, 0o755)
            
            # Desktop File Magic
            d_cont = f"[Desktop Entry]\nName={app['name']}\nComment={app['desc']}\nExec=\"{out_path}\"\nIcon={app['icon']}\nTerminal=false\nType=Application\nCategories={app['cat']};Utility;\n"
            dfile = os.path.join(self.shortcut_dir, f"ethereal_{app['id']}.desktop")
            with open(dfile, 'w') as f: f.write(d_cont)
            os.chmod(dfile, 0o755)
            
            GLib.idle_add(self.succ, app)
        except Exception as e:
            GLib.idle_add(self.fail, app, str(e))

    def succ(self, app):
        app["pbar"].set_visible(False)
        app["btn"].set_label("INSTALLED")
        app["btn"].set_name("installed-btn")

    def fail(self, app, msg):
        app["pbar"].set_visible(False)
        app["btn"].set_label("FAILED")
        app["btn"].set_sensitive(True)

if __name__ == "__main__":
    try:
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        
        win = AppStore()
        win.connect("destroy", Gtk.main_quit)
        win.show_all()
        Gtk.main()
    except Exception as err:
        import traceback
        w = Gtk.Window()
        l = Gtk.Label(label=traceback.format_exc()); l.set_selectable(True)
        w.add(l); w.show_all(); w.connect("destroy", Gtk.main_quit)
        Gtk.main()
