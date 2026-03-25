Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;

public class SimpleHttp12 {
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
            
            string script = "#!/bin/bash\nexport FEATURES=\"-parallel-fetch\"\nexport MAKEOPTS=\"-j4\"\nmkdir -p /etc/portage/package.use\netc-update --automode -5\nemerge -v --getbinpkg --autounmask-write=y --autounmask-continue=y gnome-extra/cinnamon\netc-update --automode -5\nemerge -v --getbinpkg --autounmask-write=y --autounmask-continue=y gnome-extra/cinnamon\ncd /root/cinnamon-master\nrm -rf build\nmeson setup build --prefix=/usr\nninja -C build\nninja -C build install\n";
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
[SimpleHttp12]::Start()
