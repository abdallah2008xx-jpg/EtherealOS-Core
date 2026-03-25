$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:$port/")
$listener.Start()
Write-Host "Started listener on $port..."

# Serve EXACTLY one file and stop
$context = $listener.GetContext()
Write-Host "Got connection..."
$response = $context.Response
$fileBytes = [System.IO.File]::ReadAllBytes("cinnamon-master.tar.gz")
$response.ContentLength64 = $fileBytes.Length
$response.OutputStream.Write($fileBytes, 0, $fileBytes.Length)
$response.Close()
$listener.Stop()
Write-Host "Served file and stopped!"
