Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;

public class SimpleHttp {
    public static void Start() {
        TcpListener listener = new TcpListener(IPAddress.Any, 8080);
        listener.Start();
        Console.WriteLine("Listening on 8080...");
        TcpClient client = listener.AcceptTcpClient();
        NetworkStream stream = client.GetStream();
        StreamReader reader = new StreamReader(stream);
        string request = reader.ReadLine();
        Console.WriteLine("Got: " + request);
        
        byte[] content = File.ReadAllBytes("cinnamon-master.tar.gz");
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

[SimpleHttp]::Start()
