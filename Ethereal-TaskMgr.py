#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import os, glob, cairo

# Setup completely custom transparent CSS
CSS = b"""
window {
    background-color: transparent;
}
#main-container {
    background-color: rgba(12, 14, 25, 0.85);
    border-radius: 20px;
    border: 1px solid rgba(126, 215, 255, 0.25);
    box-shadow: 0 10px 40px rgba(0,0,0,0.8);
}
.title-label {
    font-size: 24px;
    font-weight: bold;
    color: #ffffff;
    text-shadow: 0 0 10px rgba(126, 215, 255, 0.5);
}
.subtitle-label {
    font-size: 11px;
    color: #a3b2fa;
}
.process-list {
    background-color: transparent;
}
.process-card {
    background-color: rgba(255, 255, 255, 0.04);
    border-radius: 12px;
    margin: 4px 12px;
    padding: 8px 12px;
    border: 1px solid rgba(255,255,255,0.02);
    transition: all 200ms ease-in-out;
}
.process-card:hover {
    background-color: rgba(126, 215, 255, 0.12);
    border: 1px solid rgba(126, 215, 255, 0.3);
    box-shadow: 0 0 15px rgba(126, 215, 255, 0.1);
}
.process-card.killed {
    opacity: 0.0;
    margin-left: 50px;
    background-color: rgba(255, 0, 0, 0.2);
}
.proc-name { font-weight: bold; color: #ffffff; font-size: 14px; }
.proc-pid { color: rgba(255, 255, 255, 0.4); font-size: 11px; }
.proc-ram-safe { color: #00ff88; font-weight: bold; font-size: 13px; text-shadow: 0 0 8px rgba(0, 255, 136, 0.4); }
.proc-ram-warn { color: #ff6600; font-weight: bold; font-size: 14px; text-shadow: 0 0 10px rgba(255, 102, 0, 0.6); }

button.kill-btn {
    background-color: rgba(255, 80, 80, 0.1);
    color: #ff5555;
    border-radius: 8px;
    border: 1px solid rgba(255, 80, 80, 0.3);
    min-height: 24px;
    padding: 2px 12px;
    font-weight: bold;
    transition: all 200ms ease;
}
button.kill-btn:hover {
    background-color: rgba(255, 80, 80, 0.8);
    color: white;
    box-shadow: 0 0 15px rgba(255, 80, 80, 0.5);
}
"""

style_provider = Gtk.CssProvider()
style_provider.load_from_data(CSS)
Gtk.StyleContext.add_provider_for_screen(
    Gdk.Screen.get_default(), 
    style_provider, 
    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
)

class CpuTracker:
    def __init__(self):
        self.last_idle = 0
        self.last_total = 0
    def get_cpu(self):
        try:
            with open('/proc/stat') as f:
                fields = [float(column) for column in f.readline().strip().split()[1:]]
            idle, total = fields[3], sum(fields)
            idle_delta, total_delta = idle - self.last_idle, total - self.last_total
            self.last_idle, self.last_total = idle, total
            if total_delta == 0: return 0
            return 100.0 * (1.0 - idle_delta / total_delta)
        except: return 0

class LiveGraph(Gtk.DrawingArea):
    def __init__(self):
        super().__init__()
        self.set_size_request(-1, 80)
        self.history = [0.0] * 60
        self.cpu = CpuTracker()
        self.phase = 0.0
        GLib.timeout_add(16, self.tick) # 60 FPS animation
        GLib.timeout_add(500, self.update_data)
        
    def update_data(self):
        usage = self.cpu.get_cpu()
        self.history.pop(0)
        self.history.append(usage)
        return True
        
    def tick(self):
        self.phase += 0.05
        self.queue_draw()
        return True

    def do_draw(self, cr):
        w = self.get_allocated_width()
        h = self.get_allocated_height()
        
        # Transparent background
        cr.set_source_rgba(0,0,0,0)
        cr.paint()
        
        # Gradient Waves
        pat = cairo.LinearGradient(0, 0, w, h)
        pat.add_color_stop_rgba(0, 0.49, 0.84, 1.0, 0.7) # Cyan
        pat.add_color_stop_rgba(1, 0.64, 0.70, 0.98, 0.2) # Purple
        
        cr.move_to(0, h)
        step = w / (len(self.history) - 1)
        import math
        for i, val in enumerate(self.history):
            x = i * step
            # Add liquid wave sine effect to the line
            wave = math.sin(self.phase + i*0.2) * 5.0
            target_h = val / 100.0 * h
            y = h - target_h + wave
            if y > h: y = h
            if y < 0: y = 0
            cr.line_to(x, y)
        
        cr.line_to(w, h)
        cr.close_path()
        cr.set_source(pat)
        cr.fill()
        
        # Draw top stroke
        cr.set_line_width(2.0)
        cr.set_source_rgba(0.49, 0.84, 1.0, 1.0)
        cr.move_to(0, h)
        for i, val in enumerate(self.history):
            x = i * step
            wave = math.sin(self.phase + i*0.2) * 5.0
            target_h = val / 100.0 * h
            y = h - target_h + wave
            if y > h: y = h
            cr.line_to(x, y)
        cr.stroke()

class TaskManager(Gtk.Window):
    def __init__(self):
        super().__init__(title="EtherealOS Task Manager")
        self.set_default_size(450, 600)
        self.set_position(Gtk.WindowPosition.CENTER)
        
        # Transparent window setup
        self.set_app_paintable(True)
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and screen.is_composited():
            self.set_visual(visual)

        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.main_box.set_name("main-container")
        self.main_box.set_margin_top(15)
        self.main_box.set_margin_bottom(15)
        self.main_box.set_margin_left(15)
        self.main_box.set_margin_right(15)
        self.add(self.main_box)

        # Header
        header_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        header_box.set_margin_top(20)
        header_box.set_margin_left(20)
        header_box.set_margin_right(20)
        header_box.set_margin_bottom(10)
        
        title = Gtk.Label(label="System Pulse")
        title.set_name("title-label")
        title.set_halign(Gtk.Align.START)
        
        sub = Gtk.Label(label="LIVE TELEMETRY")
        sub.set_name("subtitle-label")
        sub.set_halign(Gtk.Align.START)
        
        header_box.pack_start(title, False, False, 0)
        header_box.pack_start(sub, False, False, 0)
        self.main_box.pack_start(header_box, False, False, 0)

        # Graph
        self.graph = LiveGraph()
        self.main_box.pack_start(self.graph, False, False, 0)

        # List
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        self.main_box.pack_start(scrolled, True, True, 10)

        self.listbox = Gtk.ListBox()
        self.listbox.set_selection_mode(Gtk.SelectionMode.NONE)
        self.listbox.set_name("process-list")
        scrolled.add(self.listbox)
        
        self.update_processes()
        GLib.timeout_add(2000, self.update_processes)
        
    def update_processes(self):
        # Clear old rows
        for row in self.listbox.get_children():
            self.listbox.remove(row)
            
        procs = []
        try:
            with open('/proc/meminfo') as f:
                meminfo = f.read()
            total_mem = 0
            for line in meminfo.splitlines():
                if line.startswith("MemTotal:"):
                    total_mem = int(line.split()[1])
                    break
                    
            for pid_folder in glob.glob('/proc/[0-9]*'):
                pid = os.path.basename(pid_folder)
                try:
                    with open(pid_folder + '/stat') as f:
                        stat = f.read().split()
                    name = stat[1][1:-1]
                    rss_pages = int(stat[23])
                    rss_kb = rss_pages * 4
                    if rss_kb > 10000:
                        procs.append({'pid': pid, 'name': name, 'mem': rss_kb, 'mem_percent': (rss_kb/total_mem)*100})
                except: pass
        except: pass
        
        procs.sort(key=lambda x: x['mem'], reverse=True)
        
        for p in procs[:15]:
            row = Gtk.ListBoxRow()
            box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            box.set_name("process-card")
            
            vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            lbl_name = Gtk.Label(label=p['name'])
            lbl_name.set_name("proc-name")
            lbl_name.set_halign(Gtk.Align.START)
            lbl_pid = Gtk.Label(label=f"PID: {p['pid']}")
            lbl_pid.set_name("proc-pid")
            lbl_pid.set_halign(Gtk.Align.START)
            vbox.pack_start(lbl_name, False, False, 0)
            vbox.pack_start(lbl_pid, False, False, 0)
            
            mem_mb = p['mem'] / 1024.0
            lbl_mem = Gtk.Label(label=f"{mem_mb:.1f} MB")
            if p['mem_percent'] > 5.0:
                lbl_mem.set_name("proc-ram-warn")
            else:
                lbl_mem.set_name("proc-ram-safe")
                
            btn_kill = Gtk.Button(label="End Task")
            btn_kill.set_name("kill-btn")
            btn_kill.connect("clicked", self.on_kill_clicked, p['pid'], box, row)
            
            box.pack_start(vbox, True, True, 0)
            box.pack_start(lbl_mem, False, False, 10)
            box.pack_start(btn_kill, False, False, 0)
            
            row.add(box)
            # Remove default row styling
            row.override_background_color(Gtk.StateFlags.NORMAL, Gdk.RGBA(0,0,0,0))
            self.listbox.add(row)
            
        self.listbox.show_all()
        return True

    def on_kill_clicked(self, btn, pid, box, row):
        # Trigger CSS animation
        box.get_style_context().add_class("killed")
        
        def actually_kill():
            try:
                os.kill(int(pid), signal.SIGKILL)
            except: pass
            self.listbox.remove(row)
            return False
            
        GLib.timeout_add(300, actually_kill)

win = TaskManager()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
