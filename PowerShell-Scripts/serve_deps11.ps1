Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;

public class SimpleHttp13 {
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
                "echo 'Fixing GPG keys for binary packages...'\n" +
                "getuto\n" +
                "echo 'Installing Cinnamon dependencies...'\n" +
                "export FEATURES=\"-parallel-fetch\"\n" +
                "export MAKEOPTS=\"-j4\"\n" +
                "mkdir -p /etc/portage/package.use\n" +
                "etc-update --automode -5\n" +
                "emerge -v --getbinpkg --autounmask-write=y --autounmask-continue=y gnome-extra/cinnamon || true\n" +
                "etc-update --automode -5\n" +
                "emerge -v --getbinpkg --autounmask-write=y --autounmask-continue=y gnome-extra/cinnamon\n" +
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
[SimpleHttp13]::Start()
