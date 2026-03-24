#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import os, glob, cairo, time, math, subprocess

CSS = b"""
window { background-color: transparent; }
#main-bg {
    background-color: rgba(15, 18, 30, 0.95);
    border-radius: 16px;
    border: 1px solid rgba(126, 215, 255, 0.3);
    box-shadow: 0 10px 40px rgba(0,0,0,0.9);
}
.sidebar {
    background-color: rgba(0, 0, 0, 0.4);
    border-right: 1px solid rgba(255, 255, 255, 0.05);
    border-radius: 16px 0 0 16px;
    padding: 10px 0;
}
list row.tab-row {
    background: transparent; color: #8892b0;
    padding: 12px 20px; margin: 4px 8px;
    border-radius: 8px; font-weight: bold;
    transition: all 200ms ease;
}
list row.tab-row:hover { background: rgba(255, 255, 255, 0.05); color: #ffffff; }
list row.tab-row:selected {
    background: rgba(126, 215, 255, 0.15);
    color: #7ed7ff; border-left: 3px solid #7ed7ff;
}
.header-row {
    color: #a3b2fa; font-weight: bold; font-size: 12px;
    padding: 8px 12px; border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}
.process-card {
    background-color: transparent; border-radius: 6px;
    margin: 2px 8px; padding: 6px 12px;
    border-bottom: 1px solid rgba(255,255,255,0.02);
    transition: all 150ms ease;
}
.process-card:hover { background-color: rgba(255, 255, 255, 0.06); }
.proc-title { color: #ffffff; font-weight: bold; }
.proc-sub { color: #8892b0; font-size: 11px; }
.val-safe { color: #00ff88; }
.val-warn { color: #ffaa00; font-weight: bold; }
.val-crit { color: #ff3333; font-weight: bold; text-shadow: 0 0 8px rgba(255, 50, 50, 0.5); }
button.kill-btn {
    background: transparent; color: #ff5555; border-radius: 6px;
    border: 1px solid rgba(255, 80, 80, 0.3); padding: 4px 8px;
}
button.kill-btn:hover { background: rgba(255, 80, 80, 0.8); color: white; }

/* Startup Apps */
.startup-card {
    background-color: rgba(255,255,255,0.03); border-radius: 8px;
    margin: 5px 15px; padding: 15px; border-left: 3px solid #7ed7ff;
}
switch { background: #333; border-radius: 14px; }
switch:checked { background: #00ff88; }

/* Performance Split View */
.perf-sidebar {
    background-color: transparent;
    border-right: 1px solid rgba(255,255,255,0.05);
}
.perf-mini-card {
    padding: 10px 15px; margin: 4px 8px;
    border-radius: 8px; background: transparent;
    transition: all 150ms ease;
}
list row.perf-row { background: transparent; }
list row.perf-row:hover .perf-mini-card { background: rgba(255,255,255,0.05); }
list row.perf-row:selected .perf-mini-card {
    background: rgba(126, 215, 255, 0.15);
    border-left: 3px solid #7ed7ff;
}
.perf-mini-title { color: #ffffff; font-weight: bold; font-size: 14px; }
.perf-mini-val { color: #a3b2fa; font-size: 12px; margin-top: 4px; }

.perf-detail-title { font-size: 28px; color: #ffffff; font-weight: bold; }
.perf-detail-sub { font-size: 14px; color: #7ed7ff; margin-bottom: 15px; }

.perf-data-box {
    background-color: rgba(0, 0, 0, 0.3);
    border: 1px solid rgba(255,255,255,0.05);
    border-radius: 12px; padding: 20px; margin-top: 15px;
}
"""

provider = Gtk.CssProvider()
provider.load_from_data(CSS)
Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

class SysTracker:
    def __init__(self):
        self.procs = {}; self.last_total_cpu = self.get_total_cpu()
        self.gpu_name = self.get_gpu_name()
    def get_total_cpu(self):
        try:
            with open('/proc/stat') as f: return sum([float(c) for c in f.readline().strip().split()[1:]])
        except: return 0
    def get_gpu_name(self):
        try:
            out = subprocess.check_output("lspci | grep -i vga", shell=True).decode()
            parts = out.split(':')[-1].strip().split('(')[0]
            return parts[:30]
        except: return "Unknown GPU"
    def get_disk_usage(self):
        try:
            st = os.statvfs('/')
            total = st.f_blocks * st.f_frsize
            free = st.f_bavail * st.f_frsize
            return total - free, total
        except: return 0, 1
    def update(self):
        cur_total = self.get_total_cpu(); delta = cur_total - self.last_total_cpu
        self.last_total_cpu = cur_total
        sys_cpu = 0
        try:
            with open('/proc/stat') as f: idle = float(f.readline().strip().split()[4])
            if hasattr(self, 'last_idle'):
                sys_cpu = 100.0 * (1.0 - (idle - self.last_idle) / delta) if delta > 0 else 0
            self.last_idle = idle
        except: pass
        
        mem_tot, mem_avail = 1, 0
        try:
            with open('/proc/meminfo') as f:
                for line in f:
                    if line.startswith("MemTotal:"): mem_tot = int(line.split()[1])
                    if line.startswith("MemAvailable:"): mem_avail = int(line.split()[1])
        except: pass
        
        cur_procs = {}
        for pidf in glob.glob('/proc/[0-9]*'):
            pid = os.path.basename(pidf)
            try:
                with open(pidf + '/stat') as f: stat = f.read().split()
                name = stat[1][1:-1]; utime, stime = float(stat[13]), float(stat[14])
                total_time = utime + stime; rss_kb = int(stat[23]) * 4
                cpu_p = 0.0
                if pid in self.procs and delta > 0:
                    cpu_p = 100.0 * (total_time - self.procs[pid]['time']) / delta
                cur_procs[pid] = {'pid': pid, 'name': name[:20], 'time': total_time, 'cpu': cpu_p, 'mem_kb': rss_kb}
            except: pass
            
        self.procs = cur_procs
        output = [p for p in self.procs.values() if p['mem_kb'] > 1000]
        output.sort(key=lambda x: (x['cpu'], x['mem_kb']), reverse=True)
        return output, sys_cpu, mem_tot, mem_tot - mem_avail

class LiveGraph(Gtk.DrawingArea):
    def __init__(self, c_top, c_bot):
        super().__init__()
        self.set_size_request(-1, 150); self.history = [0.0]*60; self.phase = 0.0
        self.c_top = c_top; self.c_bot = c_bot
        GLib.timeout_add(30, self.tick)
    def add_point(self, val):
        self.history.pop(0); self.history.append(val)
    def tick(self):
        self.phase += 0.06; self.queue_draw(); return True
    def do_draw(self, cr):
        w, h = self.get_allocated_width(), self.get_allocated_height()
        cr.set_source_rgba(0,0,0,0); cr.paint()
        pat = cairo.LinearGradient(0, 0, 0, h)
        pat.add_color_stop_rgba(0, *self.c_top); pat.add_color_stop_rgba(1, *self.c_bot)
        cr.move_to(0, h); step = w / (len(self.history) - 1)
        for i, val in enumerate(self.history):
            y = h - (val / 100.0 * h) + math.sin(self.phase + i*0.2) * 2.0
            cr.line_to(i * step, max(0, min(h, y)))
        cr.line_to(w, h); cr.close_path(); cr.set_source(pat); cr.fill()
        
        cr.set_line_width(2.0); cr.set_source_rgba(*self.c_top[:3], 1.0); cr.move_to(0, h)
        for i, val in enumerate(self.history):
            y = h - (val / 100.0 * h) + math.sin(self.phase + i*0.2) * 2.0
            cr.line_to(i * step, max(0, min(h, y)))
        cr.stroke()

class TaskManager(Gtk.Window):
    def __init__(self):
        super().__init__(title="EtherealOS Task Manager")
        self.set_default_size(900, 650); self.set_position(Gtk.WindowPosition.CENTER)
        self.set_app_paintable(True)
        if self.get_screen().get_rgba_visual() and self.get_screen().is_composited():
            self.set_visual(self.get_screen().get_rgba_visual())

        self.tracker = SysTracker()
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.main_box.set_name("main-bg"); self.add(self.main_box)

        # Tab Sidebar
        self.sidebar = Gtk.ListBox(); self.sidebar.set_name("sidebar"); self.sidebar.set_size_request(180, -1)
        self.sidebar.connect("row-activated", self.on_tab_changed)
        self.main_box.pack_start(self.sidebar, False, False, 0)
        
        self.tabs = [("🧩 Processes", "processes"), ("📈 Performance", "performance"), ("🚀 Startup Apps", "startup")]
        for lbl, name in self.tabs:
            r = Gtk.ListBoxRow(); r.set_name("tab-row")
            r.add(Gtk.Label(label=lbl, xalign=0)); self.sidebar.add(r)

        self.stack = Gtk.Stack(); self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.main_box.pack_start(self.stack, True, True, 0)

        self.build_processes_page()
        self.build_performance_page()
        self.build_startup_page()

        self.sidebar.select_row(self.sidebar.get_row_at_index(0))
        self.update_data()
        GLib.timeout_add(1500, self.update_data)

    def on_tab_changed(self, lb, row):
        self.stack.set_visible_child_name(self.tabs[row.get_index()][1])

    # --- PROCESSES TAB ---
    def build_processes_page(self):
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL); hbox.set_name("header-row")
        for text, w, align in [("Name", 200, 0), ("PID", 80, 0), ("CPU %", 80, 1), ("Memory", 100, 1), ("Action", 80, 1)]:
            l = Gtk.Label(label=text); l.set_xalign(align); l.set_size_request(w, -1)
            hbox.pack_start(l, text=="Name", text=="Name", 0)
        vbox.pack_start(hbox, False, False, 0)
        sys_scroll = Gtk.ScrolledWindow(); sys_scroll.set_vexpand(True)
        self.proc_list = Gtk.ListBox(); self.proc_list.set_selection_mode(Gtk.SelectionMode.NONE)
        sys_scroll.add(self.proc_list)
        vbox.pack_start(sys_scroll, True, True, 0)
        self.stack.add_named(vbox, "processes")

    # --- PERFORMANCE TAB ---
    def build_performance_page(self):
        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        
        # Performance Left Sidebar
        perf_scroll = Gtk.ScrolledWindow()
        perf_scroll.set_size_request(220, -1)
        self.perf_listbox = Gtk.ListBox()
        self.perf_listbox.set_name("perf-sidebar")
        self.perf_listbox.connect("row-activated", self.on_perf_tab_changed)
        perf_scroll.add(self.perf_listbox)
        
        # Detail Area (Right)
        self.perf_stack = Gtk.Stack()
        self.perf_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        
        # 1. CPU
        self.cpu_row, self.cpu_mini_val = self.create_perf_mini("CPU", "0%")
        self.perf_listbox.add(self.cpu_row)
        self.build_perf_detail_cpu()
        
        # 2. RAM
        self.ram_row, self.ram_mini_val = self.create_perf_mini("Memory", "0 GB")
        self.perf_listbox.add(self.ram_row)
        self.build_perf_detail_ram()
        
        # 3. Disk
        self.disk_row, self.disk_mini_val = self.create_perf_mini("Disk 0  ( / )", "0%")
        self.perf_listbox.add(self.disk_row)
        self.build_perf_detail_disk()
        
        # 4. GPU
        gpu_name = self.tracker.gpu_name.split()[0] if self.tracker.gpu_name else "GPU 0"
        self.gpu_row, self.gpu_mini_val = self.create_perf_mini(gpu_name, "0%")
        self.perf_listbox.add(self.gpu_row)
        self.build_perf_detail_gpu()
        
        hbox.pack_start(perf_scroll, False, False, 0)
        hbox.pack_start(self.perf_stack, True, True, 25)
        
        self.stack.add_named(hbox, "performance")
        self.perf_listbox.select_row(self.cpu_row)

    def create_perf_mini(self, title, init_val):
        row = Gtk.ListBoxRow()
        row.set_name("perf-row")
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        box.set_name("perf-mini-card")
        l_title = Gtk.Label(label=title, xalign=0); l_title.set_name("perf-mini-title")
        l_val = Gtk.Label(label=init_val, xalign=0); l_val.set_name("perf-mini-val")
        box.pack_start(l_title, False, False, 0)
        box.pack_start(l_val, False, False, 0)
        row.add(box)
        return row, l_val

    def on_perf_tab_changed(self, lb, row):
        idx = row.get_index()
        pgs = ["cpu", "ram", "disk", "gpu"]
        self.perf_stack.set_visible_child_name(pgs[idx])

    def create_detail_view(self, title, subtitle, graph_colors):
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        vbox.set_valign(Gtk.Align.CENTER)
        lbl_title = Gtk.Label(label=title, xalign=0); lbl_title.set_name("perf-detail-title")
        lbl_sub = Gtk.Label(label=subtitle, xalign=0); lbl_sub.set_name("perf-detail-sub")
        
        graph = LiveGraph(graph_colors[0], graph_colors[1])
        info_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=60); info_box.set_name("perf-data-box")
        
        b1 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        b1.pack_start(Gtk.Label(label="Utilization", xalign=0, name="perf-mini-val"), False, False, 0)
        val1 = Gtk.Label(label="0", xalign=0, name="perf-detail-title")
        b1.pack_start(val1, False, False, 0)
        
        b2 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        lbl_b2 = Gtk.Label(label="Speed", xalign=0, name="perf-mini-val")
        b2.pack_start(lbl_b2, False, False, 0)
        val2 = Gtk.Label(label="0", xalign=0, name="perf-detail-title")
        b2.pack_start(val2, False, False, 0)
        
        info_box.pack_start(b1, False, False, 0)
        info_box.pack_start(b2, False, False, 0)
        
        vbox.pack_start(lbl_title, False, False, 0); vbox.pack_start(lbl_sub, False, False, 0)
        vbox.pack_start(graph, True, True, 0); vbox.pack_start(info_box, False, False, 0)
        return vbox, graph, val1, val2, lbl_b2

    def build_perf_detail_cpu(self):
        v, g, v1, v2, l2 = self.create_detail_view("CPU", "Processor Core", ((0.49, 0.84, 1.0, 0.8), (0.1, 0.1, 0.3, 0.2)))
        self.gr_cpu, self.lbl_cpu_util, self.lbl_cpu_up = g, v1, v2
        l2.set_text("Uptime")
        self.perf_stack.add_named(v, "cpu")
        
    def build_perf_detail_ram(self):
        v, g, v1, v2, l2 = self.create_detail_view("Memory", "Random Access Memory", ((0.8, 0.4, 1.0, 0.8), (0.3, 0.1, 0.4, 0.2)))
        self.gr_ram, self.lbl_ram_use, self.lbl_ram_tot = g, v1, v2
        l2.set_text("Available")
        self.perf_stack.add_named(v, "ram")
        
    def build_perf_detail_disk(self):
        v, g, v1, v2, l2 = self.create_detail_view("Disk 0 ( / )", "System Partition", ((0.0, 1.0, 0.5, 0.8), (0.0, 0.3, 0.1, 0.2)))
        self.gr_disk, self.lbl_disk_used, self.lbl_disk_free = g, v1, v2
        l2.set_text("Capacity")
        self.perf_stack.add_named(v, "disk")
        
    def build_perf_detail_gpu(self):
        v, g, v1, v2, l2 = self.create_detail_view("GPU 0", self.tracker.gpu_name, ((1.0, 0.6, 0.2, 0.8), (0.4, 0.2, 0.0, 0.2)))
        self.gr_gpu, self.lbl_gpu_util, self.lbl_gpu_mem = g, v1, v2
        l2.set_text("Adapter")
        v2.set_text("Primary")
        v2.set_name("proc-title")
        self.perf_stack.add_named(v, "gpu")

    # --- STARTUP APPS TAB ---
    def build_startup_page(self):
        scroll = Gtk.ScrolledWindow()
        self.startup_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.startup_vbox.set_margin_top(20)
        title = Gtk.Label(label="Manage apps that start automatically"); title.set_name("header-row"); title.set_xalign(0); title.set_margin_left(20)
        self.startup_vbox.pack_start(title, False, False, 10)
        scroll.add(self.startup_vbox); self.stack.add_named(scroll, "startup")
        self.load_startup_apps()

    def load_startup_apps(self):
        adir = os.path.expanduser('~/.config/autostart')
        if not os.path.exists(adir): return
        for f in os.listdir(adir):
            if f.endswith('.desktop'):
                path = os.path.join(adir, f)
                name, enabled = f, True
                with open(path, 'r') as fp:
                    cont = fp.read()
                    if 'Hidden=true' in cont or 'X-GNOME-Autostart-enabled=false' in cont: enabled = False
                    for line in cont.splitlines():
                        if line.startswith('Name='): name = line[5:]
                
                card = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL); card.set_name("startup-card")
                lbl = Gtk.Label(label=name); lbl.set_name("proc-title"); lbl.set_xalign(0)
                sub = Gtk.Label(label=f"File: {f}"); sub.set_name("proc-sub"); sub.set_xalign(0)
                v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
                v.pack_start(lbl, False, False, 0); v.pack_start(sub, False, False, 0)
                sw = Gtk.Switch(); sw.set_active(enabled); sw.set_valign(Gtk.Align.CENTER)
                sw.connect("notify::active", self.on_startup_toggle, path)
                card.pack_start(v, True, True, 0); card.pack_end(sw, False, False, 10)
                self.startup_vbox.pack_start(card, False, False, 0)
        self.startup_vbox.show_all()

    def on_startup_toggle(self, switch, gparam, filepath):
        try:
            with open(filepath, 'r') as f: lines = f.readlines()
            out = [l for l in lines if not l.startswith('Hidden=') and not l.startswith('X-GNOME-Autostart-enabled=')]
            if not switch.get_active(): out.extend(["Hidden=true\n", "X-GNOME-Autostart-enabled=false\n"])
            with open(filepath, 'w') as f: f.writelines(out)
        except Exception as e: print(e)

    # --- UPDATER ---
    def update_data(self):
        procs, cpu_pct, mem_tot, mem_used = self.tracker.update()
        
        # CPU Update
        self.cpu_mini_val.set_text(f"{cpu_pct:.0f}%")
        self.lbl_cpu_util.set_text(f"{cpu_pct:.1f}%")
        t = int(time.clock_gettime(time.CLOCK_BOOTTIME))
        self.lbl_cpu_up.set_text(f"{t//3600}:{(t%3600)//60:02d}:{t%60:02d}")
        self.gr_cpu.add_point(cpu_pct)
        
        # RAM Update
        mem_pct = (mem_used / mem_tot) * 100.0 if mem_tot > 0 else 0
        self.ram_mini_val.set_text(f"{(mem_used/1024/1024):.1f} / {(mem_tot/1024/1024):.1f} GB")
        self.lbl_ram_use.set_text(f"{(mem_used/1024/1024):.1f} GB")
        self.lbl_ram_tot.set_text(f"{((mem_tot - mem_used)/1024/1024):.1f} GB")
        self.gr_ram.add_point(mem_pct)
        
        # Disk Update
        disk_used, disk_tot = self.tracker.get_disk_usage()
        disk_pct = (disk_used / disk_tot) * 100.0 if disk_tot > 0 else 0
        self.disk_mini_val.set_text(f"{disk_pct:.0f}%")
        self.lbl_disk_used.set_text(f"{(disk_used/1024/1024/1024):.1f} GB")
        self.lbl_disk_free.set_text(f"{(disk_tot/1024/1024/1024):.1f} GB")
        self.gr_disk.add_point(disk_pct)
        
        # GPU Update
        self.gpu_mini_val.set_text("System")
        self.lbl_gpu_util.set_text("Auto")
        self.gr_gpu.add_point(20) # Placeholder wave
        
        # Processes Update
        if self.stack.get_visible_child_name() == "processes":
            for row in self.proc_list.get_children(): self.proc_list.remove(row)
            for p in procs[:30]:
                row = Gtk.ListBoxRow(); row.override_background_color(Gtk.StateFlags.NORMAL, Gdk.RGBA(0,0,0,0))
                box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL); box.set_name("process-card")
                
                ln = Gtk.Label(label=p['name']); ln.set_name("proc-title"); ln.set_xalign(0); ln.set_size_request(200, -1)
                lp = Gtk.Label(label=str(p['pid'])); lp.set_name("proc-sub"); lp.set_xalign(0); lp.set_size_request(80, -1)
                lc = Gtk.Label(label=f"{p['cpu']:.1f}%"); lc.set_xalign(1); lc.set_size_request(80, -1)
                lc.set_name("val-crit" if p['cpu'] > 20 else "val-warn" if p['cpu'] > 5 else "val-safe")
                lm = Gtk.Label(label=f"{(p['mem_kb']/1024.0):.1f} MB"); lm.set_xalign(1); lm.set_size_request(100, -1)
                lm.set_name("val-crit" if p['mem_kb']/1024.0 > 500 else "val-warn" if p['mem_kb']/1024.0 > 200 else "val-safe")
                
                bb = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL); bb.set_size_request(80, -1)
                btn = Gtk.Button(label="End Task"); btn.set_name("kill-btn"); btn.set_halign(Gtk.Align.END)
                btn.connect("clicked", lambda b,pid=p['pid'],bx=box,rw=row: [bx.get_style_context().add_class("killed"), GLib.timeout_add(150, lambda: os.kill(int(pid), 9) or self.proc_list.remove(rw) and False)])
                bb.pack_end(btn, False, False, 0)
                
                box.pack_start(ln, True, True, 0); box.pack_start(lp, False, False, 0)
                box.pack_start(lc, False, False, 0); box.pack_start(lm, False, False, 0)
                box.pack_start(bb, False, False, 0)
                row.add(box); self.proc_list.add(row)
            self.proc_list.show_all()
        return True

win = TaskManager()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
