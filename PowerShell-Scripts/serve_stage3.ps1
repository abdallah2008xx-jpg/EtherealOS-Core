$port = 3500
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:$port/")
$listener.Start()
Write-Host "Started listener on $port..."

$context = $listener.GetContext()
Write-Host "Got connection..."
$response = $context.Response
$file = "stage3-amd64-desktop-openrc-20260316T093103Z.tar.xz"
$fileStream = [System.IO.File]::OpenRead($file)
$response.ContentLength64 = $fileStream.Length

$buffer = New-Object byte[] 65536
$bytesRead = $fileStream.Read($buffer, 0, $buffer.Length)
while ($bytesRead -gt 0) {
    try {
        $response.OutputStream.Write($buffer, 0, $bytesRead)
    } catch {
        Write-Host "Client disconnected"
        break
    }
    $bytesRead = $fileStream.Read($buffer, 0, $buffer.Length)
}

$fileStream.Close()
$response.Close()
$listener.Stop()
Write-Host "Served file and stopped!"
