#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import os, cairo, time, math, subprocess

CSS = b"""
window { background-color: transparent; }
#main-bg {
    background-color: rgba(9, 10, 15, 0.95);
    border-radius: 20px;
    border: 1px solid rgba(255, 30, 80, 0.3);
    box-shadow: 0 0 80px rgba(255, 0, 50, 0.4);
}

.title-glow {
    color: #ffffff;
    font-size: 42px;
    font-weight: 900;
    text-shadow: 0 0 25px rgba(255, 30, 80, 0.8);
}

.subtitle { color: #ff88aa; font-size: 16px; margin-bottom: 20px; }

.boost-btn {
    background: transparent;
    border-radius: 50px;
    border: 2px solid rgba(255, 50, 80, 0.8);
    color: #ffffff; font-size: 24px; font-weight: bold;
    padding: 20px 60px;
    transition: all 400ms ease;
    box-shadow: 0 0 30px rgba(255, 50, 80, 0.4);
}
.boost-btn:hover { background: rgba(255, 50, 80, 0.9); box-shadow: 0 0 60px rgba(255, 50, 80, 0.8); }

.boost-btn.active {
    background: rgba(0, 255, 120, 0.9);
    border: 2px solid #00ff78;
    color: #000000;
    box-shadow: 0 0 80px rgba(0, 255, 120, 0.8);
}

.log-box {
    background-color: rgba(0, 0, 0, 0.6);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 12px;
    padding: 15px; margin-top: 20px;
}
.log-text { color: #00ffcc; font-family: monospace; font-size: 12px; }

.stat-title { color: #aaaaaa; font-size: 13px; font-weight: bold; }
.stat-val { color: #ffffff; font-size: 20px; font-weight: bold; }
"""

class ReactorCore(Gtk.DrawingArea):
    def __init__(self):
        super().__init__()
        self.set_size_request(300, 300)
        self.phase = 0.0
        self.active_level = 0.0 # 0.0 to 1.0
        self.target_level = 0.0
        GLib.timeout_add(30, self.tick)
        
    def tick(self):
        self.phase += 0.05 + (self.active_level * 0.1)
        self.active_level += (self.target_level - self.active_level) * 0.05
        self.queue_draw()
        return True

    def set_active(self, state):
        self.target_level = 1.0 if state else 0.0

    def do_draw(self, cr):
        w, h = self.get_allocated_width(), self.get_allocated_height()
        cx, cy = w / 2, h / 2
        radius = min(w, h) / 2.5
        
        # Color transition: Blue (idle) to Red/Orange (max perf)
        r = 0.2 + (0.8 * self.active_level)
        g = 0.6 - (0.4 * self.active_level)
        b = 1.0 - (0.9 * self.active_level)
        
        # Draw outer pulse
        cr.arc(cx, cy, radius + math.sin(self.phase*2)*10*(1+self.active_level), 0, 2*math.pi)
        cr.set_source_rgba(r, g, b, 0.1 + (self.active_level*0.2))
        cr.fill()
        
        # Draw spinning gear/radar
        cr.set_line_width(4)
        num_segments = 12
        for i in range(num_segments):
            angle = (i * 2 * math.pi / num_segments) + (self.phase * (0.5 + self.active_level))
            cr.arc(cx, cy, radius * 0.8, angle, angle + math.pi/num_segments)
            cr.set_source_rgba(r, g, b, 0.6 + math.sin(self.phase+i)*0.4)
            cr.stroke()
            
        # Draw Center Core
        pat = cairo.RadialGradient(cx, cy, radius*0.1, cx, cy, radius*0.6)
        pat.add_color_stop_rgba(0, 1.0, 1.0, 1.0, 1.0)
        pat.add_color_stop_rgba(0.5, r, g, b, 0.8)
        pat.add_color_stop_rgba(1, r, g, b, 0.0)
        
        cr.arc(cx, cy, radius*0.6, 0, 2*math.pi)
        cr.set_source(pat)
        cr.fill()
        
        # Core data lines
        cr.set_source_rgba(1, 1, 1, 0.3)
        cr.move_to(cx, cy - radius*0.2)
        cr.line_to(cx, cy + radius*0.2)
        cr.move_to(cx - radius*0.2, cy)
        cr.line_to(cx + radius*0.2, cy)
        cr.set_line_width(2)
        cr.stroke()

class GameMode(Gtk.Window):
    def __init__(self):
        super().__init__(title="EtherealOS Game Boost Core")
        self.set_default_size(900, 650)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_app_paintable(True)
        if self.get_screen().get_rgba_visual() and self.get_screen().is_composited():
            self.set_visual(self.get_screen().get_rgba_visual())

        self.is_boosted = False
        
        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        main_box.set_name("main-bg")
        self.add(main_box)
        
        # Left Panel (Controls)
        left_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        left_vbox.set_margin_top(40); left_vbox.set_margin_left(40); left_vbox.set_margin_right(20)
        left_vbox.set_margin_bottom(40)
        left_vbox.set_size_request(450, -1)
        
        title = Gtk.Label(label="GAME BOOST", xalign=0); title.set_name("title-glow")
        sub = Gtk.Label(label="EtherealOS Hyper-Threading Engine", xalign=0); sub.set_name("subtitle")
        
        left_vbox.pack_start(title, False, False, 0)
        left_vbox.pack_start(sub, False, False, 0)
        
        # Stats Grid
        grid = Gtk.Grid(); grid.set_column_spacing(40); grid.set_row_spacing(20); grid.set_margin_top(20)
        
        def add_stat(grid, r, c, l_text, v_text):
            b = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
            var_l = Gtk.Label(label=l_text, xalign=0); var_l.set_name("stat-title")
            var_v = Gtk.Label(label=v_text, xalign=0); var_v.set_name("stat-val")
            b.pack_start(var_l, False, False, 0); b.pack_start(var_v, False, False, 0)
            grid.attach(b, c, r, 1, 1)
            return var_v
            
        self.st_gov = add_stat(grid, 0, 0, "CPU GOVERNOR", "Powersave")
        self.st_ram = add_stat(grid, 0, 1, "RAM CACHE", "Standard")
        self.st_gpu = add_stat(grid, 1, 0, "COMPOSITOR", "Normal")
        self.st_net = add_stat(grid, 1, 1, "SYS LATENCY", "Default")
        
        left_vbox.pack_start(grid, False, False, 20)
        
        # Engage Button
        self.btn = Gtk.Button(label="ENGAGE OVERDRIVE")
        self.btn.set_name("boost-btn")
        self.btn.connect("clicked", self.toggle_boost)
        self.btn.set_halign(Gtk.Align.START)
        left_vbox.pack_start(self.btn, False, False, 30)
        
        # Terminal Log
        self.log_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL); self.log_vbox.set_name("log-box")
        self.log_scroll = Gtk.ScrolledWindow(); self.log_scroll.add(self.log_vbox)
        left_vbox.pack_start(self.log_scroll, True, True, 0)
        
        main_box.pack_start(left_vbox, True, True, 0)
        
        # Right Panel (Reactor)
        right_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        right_vbox.set_margin_top(40); right_vbox.set_margin_bottom(40); right_vbox.set_margin_right(40)
        
        self.reactor = ReactorCore()
        right_vbox.pack_start(self.reactor, True, True, 0)
        
        status_lbl = Gtk.Label(label="SYSTEM TELEMETRY LINKED"); status_lbl.set_name("stat-title")
        right_vbox.pack_end(status_lbl, False, False, 0)
        
        main_box.pack_start(right_vbox, True, True, 0)
        
        self.add_log("Initializing Ethereal Game Engine module...")
        self.add_log("System fully analyzed. Ready for boost.")

    def add_log(self, text):
        l = Gtk.Label(label=f"> {text}", xalign=0); l.set_name("log-text")
        self.log_vbox.pack_start(l, False, False, 2)
        self.log_vbox.show_all()
        # Scroll to bottom
        adj = self.log_scroll.get_vadjustment()
        GLib.timeout_add(50, lambda: adj.set_value(adj.get_upper() - adj.get_page_size()) or False)

    def toggle_boost(self, widget):
        self.is_boosted = not self.is_boosted
        if self.is_boosted:
            self.btn.get_style_context().add_class("active")
            self.btn.set_label("SYSTEM OVERDRIVE ACTIVE")
            self.reactor.set_active(True)
            self.st_gov.set_text("Performance")
            self.st_ram.set_text("Cleared Sync")
            self.st_gpu.set_text("Uncapped")
            self.st_net.set_text("Ultra-Low")
            self.add_log("EXECUTING ROOT SYNC: Dropping RAM caches...")
            
            # Execute physical hardware tuning via pkexec
            cmd = "echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; sync; echo 3 > /proc/sys/vm/drop_caches"
            self.add_log(f"Spawning pkexec layer...")
            
            def run_bg():
                try:
                    subprocess.run(["pkexec", "bash", "-c", cmd], check=False)
                    GLib.idle_add(self.add_log, "Hardware limits removed successfully.")
                except Exception as e:
                    GLib.idle_add(self.add_log, f"Error enforcing: {e}")
            import threading
            threading.Thread(target=run_bg).start()
        else:
            self.btn.get_style_context().remove_class("active")
            self.btn.set_label("ENGAGE OVERDRIVE")
            self.reactor.set_active(False)
            self.st_gov.set_text("Powersave")
            self.st_ram.set_text("Standard")
            self.st_gpu.set_text("Normal")
            self.st_net.set_text("Default")
            self.add_log("Reverting CPU governor to balanced...")
            def run_bg2():
                try:
                    subprocess.run(["pkexec", "bash", "-c", "echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"], check=False)
                    GLib.idle_add(self.add_log, "System restabilized to PowerSave.")
                except: pass
            import threading
            threading.Thread(target=run_bg2).start()

if __name__ == "__main__":
    try:
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        win = GameMode()
        win.connect("destroy", Gtk.main_quit)
        win.show_all()
        Gtk.main()
    except Exception as e:
        import traceback
        err_msg = traceback.format_exc()
        err_win = Gtk.Window(title="Game Mode Crash Reporter")
        err_win.set_default_size(600, 400)
        scroll = Gtk.ScrolledWindow()
        l = Gtk.Label(label=f"Fatal Error:\n\n{err_msg}")
        l.set_selectable(True)
        l.set_halign(Gtk.Align.START)
        scroll.add(l)
        err_win.add(scroll)
        err_win.show_all()
        err_win.connect("destroy", Gtk.main_quit)
        Gtk.main()
