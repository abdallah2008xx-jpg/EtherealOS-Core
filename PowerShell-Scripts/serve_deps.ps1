Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;

public class SimpleHttp3 {
    public static void Start() {
        TcpListener listener = new TcpListener(IPAddress.Any, 8080);
        listener.Start();
        Console.WriteLine("Listening on 8080...");
        TcpClient client = listener.AcceptTcpClient();
        NetworkStream stream = client.GetStream();
        StreamReader reader = new StreamReader(stream);
        string request = reader.ReadLine();
        Console.WriteLine("Got: " + request);
        
        string script = "#!/bin/bash\necho 'Resolving all Cinnamon dependencies via binary packages...'\nemerge --ask=n --getbinpkg --onlydeps gnome-extra/cinnamon\ncd /root/cinnamon-master\nrm -rf build\nmeson setup build --prefix=/usr\nninja -C build\nninja -C build install\n";
        byte[] content = Encoding.UTF8.GetBytes(script);
        string header = "HTTP/1.1 200 OK\r\nContent-Length: " + content.Length + "\r\nConnection: close\r\n\r\n";
        byte[] headBytes = Encoding.UTF8.GetBytes(header);
        stream.Write(headBytes, 0, headBytes.Length);
        stream.Write(content, 0, content.Length);
        stream.Flush();
        client.Close();
        listener.Stop();
    }
}
"@
[SimpleHttp3]::Start()
