Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;

public class SimpleHttp7 {
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
                "echo 'Installing dependencies with fetch limit to prevent crash...'\n" +
                "mkdir -p /etc/portage/package.use\n" +
                "etc-update --automode -5\n" +
                "emerge --ask=n --getbinpkg --fetch-tasks=1 --autounmask-write=y --autounmask-continue=y gnome-extra/cjs x11-libs/xapp gnome-extra/cinnamon-desktop x11-wm/muffin gnome-extra/cinnamon-menus gnome-extra/cinnamon-session\n" +
                "etc-update --automode -5\n" +
                "emerge --ask=n --getbinpkg --fetch-tasks=1 --autounmask-write=y --autounmask-continue=y gnome-extra/cjs x11-libs/xapp gnome-extra/cinnamon-desktop x11-wm/muffin gnome-extra/cinnamon-menus gnome-extra/cinnamon-session\n" +
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
[SimpleHttp7]::Start()
