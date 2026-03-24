#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib, Pango
import os, glob, cairo, time, math

CSS = b"""
window {
    background-color: transparent;
}
#main-bg {
    background-color: rgba(15, 18, 30, 0.90);
    border-radius: 16px;
    border: 1px solid rgba(126, 215, 255, 0.3);
    box-shadow: 0 10px 40px rgba(0,0,0,0.9);
}

.sidebar {
    background-color: rgba(0, 0, 0, 0.3);
    border-right: 1px solid rgba(255, 255, 255, 0.05);
    border-radius: 16px 0 0 16px;
    padding: 10px 0;
}

list row.tab-row {
    background: transparent;
    color: #8892b0;
    padding: 12px 20px;
    margin: 4px 8px;
    border-radius: 8px;
    font-weight: bold;
    transition: all 200ms ease;
}
list row.tab-row:hover {
    background: rgba(255, 255, 255, 0.05);
    color: #ffffff;
}
list row.tab-row:selected {
    background: rgba(126, 215, 255, 0.15);
    color: #7ed7ff;
    border-left: 3px solid #7ed7ff;
}

.header-row {
    color: #a3b2fa;
    font-weight: bold;
    font-size: 12px;
    padding: 8px 12px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.process-card {
    background-color: transparent;
    border-radius: 6px;
    margin: 2px 8px;
    padding: 6px 12px;
    border-bottom: 1px solid rgba(255,255,255,0.02);
    transition: all 150ms ease;
}
.process-card:hover {
    background-color: rgba(255, 255, 255, 0.06);
}
.process-card.killed {
    background-color: rgba(255, 50, 50, 0.3);
    opacity: 0;
}

.proc-title { color: #ffffff; font-weight: bold; }
.proc-sub { color: #8892b0; font-size: 11px; }

.val-safe { color: #00ff88; }
.val-warn { color: #ffaa00; font-weight: bold; }
.val-crit { color: #ff3333; font-weight: bold; text-shadow: 0 0 8px rgba(255, 50, 50, 0.5); }

button.kill-btn {
    background: transparent;
    color: #ff5555;
    border-radius: 6px;
    border: 1px solid rgba(255, 80, 80, 0.3);
    padding: 2px 8px;
    transition: all 200ms;
}
button.kill-btn:hover {
    background: rgba(255, 80, 80, 0.8);
    color: white;
}

.graph-container {
    background-color: rgba(0, 0, 0, 0.4);
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 12px;
    margin: 15px;
    padding: 10px;
}
.graph-title {
    color: #ffffff;
    font-size: 18px;
    font-weight: bold;
    margin-bottom: 5px;
}
.graph-subtitle {
    color: #7ed7ff;
    font-size: 24px;
    font-weight: 300;
}
"""

provider = Gtk.CssProvider()
provider.load_from_data(CSS)
Gtk.StyleContext.add_provider_for_screen(
    Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
)

class Tracker:
    def __init__(self):
        self.procs = {}
        self.last_total_cpu = self.get_total_cpu()
        self.sys_mem_total = 1
        self.sys_mem_free = 0
        self.sys_cpu_usage = 0
        
    def get_total_cpu(self):
        try:
            with open('/proc/stat') as f:
                return sum([float(c) for c in f.readline().strip().split()[1:]])
        except: return 0

    def update(self):
        current_total = self.get_total_cpu()
        delta_total = current_total - self.last_total_cpu
        
        try:
            with open('/proc/stat') as f:
                fields = [float(c) for c in f.readline().strip().split()[1:]]
            idle = fields[3]
            self.sys_cpu_usage = 100.0 * (1.0 - (idle - self.last_idle) / delta_total) if delta_total > 0 else 0
            self.last_idle = idle
        except: pass
        
        self.last_total_cpu = current_total
        
        try:
            with open('/proc/meminfo') as f:
                for line in f:
                    if line.startswith("MemTotal:"): self.sys_mem_total = int(line.split()[1])
                    if line.startswith("MemAvailable:"): self.sys_mem_free = int(line.split()[1])
        except: pass
        
        current_procs = {}
        for pid_folder in glob.glob('/proc/[0-9]*'):
            pid = os.path.basename(pid_folder)
            try:
                with open(pid_folder + '/stat') as f:
                    stat = f.read().split()
                name = stat[1][1:-1]
                utime, stime = float(stat[13]), float(stat[14])
                total_time = utime + stime
                rss_kb = int(stat[23]) * 4
                
                cpu_percent = 0.0
                if pid in self.procs and delta_total > 0:
                    cpu_percent = 100.0 * (total_time - self.procs[pid]['time']) / delta_total

                current_procs[pid] = {
                    'pid': pid, 'name': name[:20], 'time': total_time,
                    'cpu': cpu_percent, 'mem_kb': rss_kb
                }
            except: pass
            
        self.procs = current_procs
        output = [p for p in self.procs.values() if p['mem_kb'] > 1000]
        output.sort(key=lambda x: (x['cpu'], x['mem_kb']), reverse=True)
        return output

class LiveGraph(Gtk.DrawingArea):
    def __init__(self, color_top, color_bot):
        super().__init__()
        self.set_size_request(-1, 120)
        self.history = [0.0] * 60
        self.phase = 0.0
        self.c_top = color_top
        self.c_bot = color_bot
        GLib.timeout_add(16, self.tick)
        
    def add_point(self, val):
        self.history.pop(0)
        self.history.append(val)
        
    def tick(self):
        self.phase += 0.05
        self.queue_draw()
        return True

    def do_draw(self, cr):
        w, h = self.get_allocated_width(), self.get_allocated_height()
        cr.set_source_rgba(0,0,0,0)
        cr.paint()
        
        pat = cairo.LinearGradient(0, 0, 0, h)
        pat.add_color_stop_rgba(0, *self.c_top)
        pat.add_color_stop_rgba(1, *self.c_bot)
        
        cr.move_to(0, h)
        step = w / (len(self.history) - 1)
        for i, val in enumerate(self.history):
            x = i * step
            wave = math.sin(self.phase + i*0.2) * 3.0
            y = h - (val / 100.0 * h) + wave
            y = max(0, min(h, y))
            cr.line_to(x, y)
            
        cr.line_to(w, h)
        cr.close_path()
        cr.set_source(pat)
        cr.fill()
        
        cr.set_line_width(2.0)
        cr.set_source_rgba(*self.c_top[:3], 1.0)
        cr.move_to(0, h)
        for i, val in enumerate(self.history):
            x = i * step
            y = h - (val / 100.0 * h) + math.sin(self.phase + i*0.2) * 3.0
            cr.line_to(x, max(0, min(h, y)))
        cr.stroke()

class TaskManager(Gtk.Window):
    def __init__(self):
        super().__init__(title="EtherealOS Task Manager")
        self.set_default_size(750, 600)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_app_paintable(True)
        visual = self.get_screen().get_rgba_visual()
        if visual and self.get_screen().is_composited():
            self.set_visual(visual)

        self.tracker = Tracker()
        self.tracker.last_idle = 0

        # Main Layout
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.main_box.set_name("main-bg")
        self.add(self.main_box)

        # Custom Sidebar
        self.sidebar = Gtk.ListBox()
        self.sidebar.set_name("sidebar")
        self.sidebar.set_size_request(160, -1)
        self.sidebar.connect("row-activated", self.on_tab_changed)
        self.main_box.pack_start(self.sidebar, False, False, 0)
        
        lbl_proc = Gtk.Label(label="🧩 Processes")
        row_proc = Gtk.ListBoxRow()
        row_proc.set_name("tab-row")
        row_proc.add(lbl_proc)
        self.sidebar.add(row_proc)
        
        lbl_perf = Gtk.Label(label="📈 Performance")
        row_perf = Gtk.ListBoxRow()
        row_perf.set_name("tab-row")
        row_perf.add(lbl_perf)
        self.sidebar.add(row_perf)

        # Stack Content
        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.stack.set_transition_duration(250)
        self.main_box.pack_start(self.stack, True, True, 0)

        self.build_processes_page()
        self.build_performance_page()
        
        self.sidebar.select_row(row_proc)
        self.update_data()
        GLib.timeout_add(1500, self.update_data)

    def build_processes_page(self):
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        
        # Headers
        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        hbox.set_name("header-row")
        
        l1 = Gtk.Label(label="Name"); l1.set_xalign(0); l1.set_size_request(200, -1)
        l2 = Gtk.Label(label="PID"); l2.set_xalign(0); l2.set_size_request(80, -1)
        l3 = Gtk.Label(label="CPU %"); l3.set_xalign(1); l3.set_size_request(80, -1)
        l4 = Gtk.Label(label="Memory"); l4.set_xalign(1); l4.set_size_request(100, -1)
        l5 = Gtk.Label(label="Action"); l5.set_xalign(1); l5.set_size_request(80, -1)
        
        hbox.pack_start(l1, True, True, 0)
        hbox.pack_start(l2, False, False, 0)
        hbox.pack_start(l3, False, False, 0)
        hbox.pack_start(l4, False, False, 0)
        hbox.pack_start(l5, False, False, 0)
        vbox.pack_start(hbox, False, False, 0)

        # Scrolled List
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        self.proc_list = Gtk.ListBox()
        self.proc_list.set_selection_mode(Gtk.SelectionMode.NONE)
        scrolled.add(self.proc_list)
        vbox.pack_start(scrolled, True, True, 0)
        
        self.stack.add_named(vbox, "processes")

    def build_performance_page(self):
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        vbox.set_valign(Gtk.Align.CENTER)
        
        # CPU Section
        cpu_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        cpu_box.set_name("graph-container")
        self.cpu_lbl = Gtk.Label(label="Processor")
        self.cpu_lbl.set_name("graph-title")
        self.cpu_lbl.set_halign(Gtk.Align.START)
        self.cpu_val = Gtk.Label(label="0 %")
        self.cpu_val.set_name("graph-subtitle")
        self.cpu_val.set_halign(Gtk.Align.START)
        
        self.cpu_graph = LiveGraph((0.49, 0.84, 1.0, 0.8), (0.64, 0.70, 0.98, 0.2)) # Cyan/Purple
        cpu_box.pack_start(self.cpu_lbl, False, False, 0)
        cpu_box.pack_start(self.cpu_val, False, False, 0)
        cpu_box.pack_start(self.cpu_graph, True, True, 10)
        
        # RAM Section
        ram_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        ram_box.set_name("graph-container")
        self.ram_lbl = Gtk.Label(label="Memory")
        self.ram_lbl.set_name("graph-title")
        self.ram_lbl.set_halign(Gtk.Align.START)
        self.ram_val = Gtk.Label(label="0 GB")
        self.ram_val.set_name("graph-subtitle")
        self.ram_val.set_halign(Gtk.Align.START)
        
        self.ram_graph = LiveGraph((0.7, 0.4, 1.0, 0.8), (0.4, 0.2, 0.8, 0.2)) # Purple/Pink
        ram_box.pack_start(self.ram_lbl, False, False, 0)
        ram_box.pack_start(self.ram_val, False, False, 0)
        ram_box.pack_start(self.ram_graph, True, True, 10)

        vbox.pack_start(cpu_box, False, False, 0)
        vbox.pack_start(ram_box, False, False, 0)
        
        self.stack.add_named(vbox, "performance")

    def on_tab_changed(self, listbox, row):
        idx = row.get_index()
        if idx == 0: self.stack.set_visible_child_name("processes")
        elif idx == 1: self.stack.set_visible_child_name("performance")

    def update_data(self):
        procs = self.tracker.update()
        
        # Update Performance Graphs
        cpu_pct = self.tracker.sys_cpu_usage
        mem_used = self.tracker.sys_mem_total - self.tracker.sys_mem_free
        mem_pct = (mem_used / self.tracker.sys_mem_total) * 100.0 if self.tracker.sys_mem_total > 0 else 0
        
        self.cpu_val.set_text(f"{cpu_pct:.1f} %")
        self.cpu_graph.add_point(cpu_pct)
        
        self.ram_val.set_text(f"{(mem_used/1024/1024):.1f} GB / {(self.tracker.sys_mem_total/1024/1024):.1f} GB")
        self.ram_graph.add_point(mem_pct)

        # Only update GUI list if Processes tab is visible (saves CPU)
        if self.stack.get_visible_child_name() != "processes":
            return True
            
        for row in self.proc_list.get_children():
            self.proc_list.remove(row)
            
        for p in procs[:25]:
            row = Gtk.ListBoxRow()
            row.override_background_color(Gtk.StateFlags.NORMAL, Gdk.RGBA(0,0,0,0))
            
            box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
            box.set_name("process-card")
            
            l_name = Gtk.Label(label=p['name']); l_name.set_name("proc-title"); l_name.set_xalign(0); l_name.set_size_request(200, -1)
            l_pid = Gtk.Label(label=str(p['pid'])); l_pid.set_name("proc-sub"); l_pid.set_xalign(0); l_pid.set_size_request(80, -1)
            
            cpu_val = p['cpu']
            l_cpu = Gtk.Label(label=f"{cpu_val:.1f}%"); l_cpu.set_xalign(1); l_cpu.set_size_request(80, -1)
            if cpu_val > 20: l_cpu.set_name("val-crit")
            elif cpu_val > 5: l_cpu.set_name("val-warn")
            else: l_cpu.set_name("val-safe")
            
            mem_mb = p['mem_kb'] / 1024.0
            l_mem = Gtk.Label(label=f"{mem_mb:.1f} MB"); l_mem.set_xalign(1); l_mem.set_size_request(100, -1)
            if mem_mb > 500: l_mem.set_name("val-crit")
            elif mem_mb > 200: l_mem.set_name("val-warn")
            else: l_mem.set_name("val-safe")
            
            btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
            btn_box.set_size_request(80, -1)
            btn = Gtk.Button(label="End Task")
            btn.set_name("kill-btn")
            btn.set_halign(Gtk.Align.END)
            btn.connect("clicked", self.on_kill, p['pid'], box, row)
            btn_box.pack_end(btn, False, False, 0)
            
            box.pack_start(l_name, True, True, 0)
            box.pack_start(l_pid, False, False, 0)
            box.pack_start(l_cpu, False, False, 0)
            box.pack_start(l_mem, False, False, 0)
            box.pack_start(btn_box, False, False, 0)
            
            row.add(box)
            self.proc_list.add(row)
            
        self.proc_list.show_all()
        return True

    def on_kill(self, btn, pid, box, row):
        box.get_style_context().add_class("killed")
        def actually_kill():
            try: os.kill(int(pid), 9)
            except: pass
            self.proc_list.remove(row)
            return False
        GLib.timeout_add(150, actually_kill)

win = TaskManager()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
