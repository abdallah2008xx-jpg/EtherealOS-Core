Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;

public class SimpleHttp15 {
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
                "echo 'Cloning Muffin Master for 100% compatibility with Cinnamon Master...'\n" +
                "cd /root\n" +
                "git clone https://github.com/linuxmint/muffin.git muffin-master\n" +
                "cd muffin-master\n" +
                "rm -rf build\n" +
                "meson setup build --prefix=/usr\n" +
                "ninja -C build\n" +
                "ninja -C build install\n" +
                "echo 'Muffin Master installed. Retrying Cinnamon build...'\n" +
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
[SimpleHttp15]::Start()
