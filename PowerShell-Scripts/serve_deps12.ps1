Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;

public class SimpleHttp14 {
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
                "echo 'Unmasking Muffin 6.6 and Cinnamon-desktop 6.6...'\n" +
                "mkdir -p /etc/portage/package.accept_keywords\n" +
                "echo \"x11-wm/muffin ~amd64\" >> /etc/portage/package.accept_keywords/muffin\n" +
                "echo \"gnome-extra/cinnamon-desktop ~amd64\" >> /etc/portage/package.accept_keywords/muffin\n" +
                "echo \"gnome-extra/cinnamon-menus ~amd64\" >> /etc/portage/package.accept_keywords/muffin\n" +
                "echo \"gnome-extra/cinnamon-session ~amd64\" >> /etc/portage/package.accept_keywords/muffin\n" +
                "echo \"x11-libs/xapp ~amd64\" >> /etc/portage/package.accept_keywords/muffin\n" +
                "etc-update --automode -5\n" +
                "echo 'Upgrading Muffin and Desktop to 6.6...'\n" +
                "emerge --ask=n --autounmask-write=y --autounmask-continue=y x11-wm/muffin gnome-extra/cinnamon-desktop\n" +
                "etc-update --automode -5\n" +
                "emerge --ask=n x11-wm/muffin gnome-extra/cinnamon-desktop\n" +
                "echo 'Dependency upgrade complete. Retrying Cinnamon build...'\n" +
                "cd /root/cinnamon-master\n" +
                "rm -rf build\n" +
                "meson setup build --prefix=/usr\n" +
                "ninja -C build\n" +
                "ninja -C build install\n";
            script = script.Replace("\r", "");
            
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
[SimpleHttp14]::Start()
