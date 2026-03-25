Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;

public class SimpleHttp10 {
    public static void Start() {
        TcpListener listener = new TcpListener(IPAddress.Any, 8080);
        listener.Start();
        Console.WriteLine("Listening on 8080...");
        
        while (true) {
            TcpClient client = listener.AcceptTcpClient();
            NetworkStream stream = client.GetStream();
            StreamReader reader = new StreamReader(stream);
            string request = reader.ReadLine();
            Console.WriteLine("Got: " + request);
            
            string script = "#!/bin/bash\n" +
                "echo 'Installing remaining Cinnamon dependencies without ask confirmation...'\n" +
                "export FEATURES=\"-parallel-fetch\"\n" +
                "mkdir -p /etc/portage/package.use\n" +
                "etc-update --automode -5\n" +
                "emerge -v --getbinpkg --autounmask-write=y --autounmask-continue=y net-misc/networkmanager sys-power/upower media-libs/libpulse x11-libs/libnotify sys-apps/accountsservice dev-libs/keybinder:3 || true\n" +
                "etc-update --automode -5\n" +
                "emerge -v --autounmask-write=y --autounmask-continue=y net-misc/networkmanager sys-power/upower media-libs/libpulse x11-libs/libnotify sys-apps/accountsservice dev-libs/keybinder:3\n" +
                "cd /root/cinnamon-master\n" +
                "rm -rf build\n" +
                "meson setup build --prefix=/usr\n" +
                "ninja -C build\n" +
                "ninja -C build install\n";
            
            byte[] content = Encoding.UTF8.GetBytes(script);
            string header = "HTTP/1.1 200 OK\r\nContent-Length: " + content.Length + "\r\nConnection: close\r\n\r\n";
            byte[] headBytes = Encoding.UTF8.GetBytes(header);
            stream.Write(headBytes, 0, headBytes.Length);
            stream.Write(content, 0, content.Length);
            stream.Flush();
            client.Close();
            break;
        }
        listener.Stop();
    }
}
"@
[SimpleHttp10]::Start()
