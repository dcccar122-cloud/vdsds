# VDS IP Oluşturma ve Yazma Scripti

# ngrok tunnel bilgilerini al
$ngrokUrl = "http://localhost:4040/api/tunnels"

# Tunnel oluşturulmasını bekle
Start-Sleep -Seconds 3

# JSON bilgisini indir
try {
    $response = Invoke-WebRequest -Uri $ngrokUrl -UseBasicParsing
    $tunnels = $response.Content | ConvertFrom-Json
    
    if ($tunnels.tunnels.Count -gt 0) {
        $tunnel = $tunnels.tunnels[0]
        $vdsIp = $tunnel.public_url
        
        # VDS IP'sini console'a yazdır
        Write-Host "================================"
        Write-Host "VDS IP (ngrok URL): $vdsIp"
        Write-Host "================================"
        
        # VDS IP'sini dosyaya kaydet
        $outputPath = "vds-connection-info.txt"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        $content = @"
VDS Bağlantı Bilgileri
======================
Oluşturma Zamanı: $timestamp
VDS URL/IP: $vdsIp
RDP Port: 3389
Kullanıcı: runneradmin
Şifre: P@ssw0rd!

Bağlantı Yöntemi:
- URL: $vdsIp
- Port: 3389'dan 22 numaralı porta yönlendirilmiştir
"@
        
        $content | Out-File -FilePath $outputPath -Encoding UTF8
        Write-Host "VDS bilgileri kaydedildi: $outputPath"
        
        # GitHub artifact olarak sakla
        Write-Host "::set-output name=vds-url::$vdsIp"
        
    } else {
        Write-Host "ERROR: ngrok tunnel bulunamadı!"
        exit 1
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}
