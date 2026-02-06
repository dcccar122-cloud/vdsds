# VDS IP Oluşturma ve Yazma Scripti
# Bu script ngrok tunnel'dan VDS IP'sini alıp kaydeder

param(
    [string]$OutputFile = "vds-info.txt",
    [int]$WaitSeconds = 5,
    [int]$MaxRetries = 10
)

Write-Host "VDS IP oluşturma scriptı başlatılıyor..."

# ngrok API endpoint
$ngrokApiUrl = "http://localhost:4040/api/tunnels"

# Tunnel oluşturulmasını bekle ve API'ye bağlan
$retryCount = 0
$vdsUrl = $null

while ($retryCount -lt $MaxRetries) {
    try {
        $response = Invoke-WebRequest -Uri $ngrokApiUrl -UseBasicParsing -ErrorAction Stop
        $tunnels = $response.Content | ConvertFrom-Json
        
        if ($tunnels.tunnels.Count -gt 0) {
            $vdsUrl = $tunnels.tunnels[0].public_url
            Write-Host "✓ VDS URL başarıyla alındı: $vdsUrl"
            break
        }
    } catch {
        $retryCount++
        Write-Host "⏳ Tunnel bekleniyor... ($retryCount/$MaxRetries)"
        Start-Sleep -Seconds $WaitSeconds
    }
}

if (-not $vdsUrl) {
    Write-Host "✗ HATA: VDS URL alınamadı!"
    exit 1
}

# VDS Bilgilerini hazırla
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$computerName = $env:COMPUTERNAME
$username = "runneradmin"
$password = "P@ssw0rd!"

# Host ve port bilgisini ayıkla
$urlParts = $vdsUrl -replace "tcp://", "" -split ":"
$host = $urlParts[0]
$port = if ($urlParts.Count -gt 1) { $urlParts[1] } else { "3389" }

# Dosya içeriğini oluştur
$content = @"
╔════════════════════════════════════════╗
║       VDS BAGLANTI BILGILERI           ║
╚════════════════════════════════════════╝

📅 Oluşturma Zamanı: $timestamp

🌐 BAGLANTI ADRESLERI:
   • ngrok URL: $vdsUrl
   • Host: $host
   • Port: $port

🖥️  SUNUCU BILGILERI:
   • Türü: Windows RDP
   • Bilgisayar Adı: $computerName
   • İşletim Sistemi: Windows

👤 GİRİŞ BİLGİLERİ:
   • Kullanıcı Adı: $username
   • Şifre: $password

📋 BAGLANTI ADIMLARI:
   1. RDP bağlantı uygulamasını aç
   2. Bilgisayar: $host:$port yazarak bağlan
   3. Kullanıcı adı: $username
   4. Şifre: $password
   5. Bağlan butonuna tıkla

⚠️  NOT: Bu session sınırlı süre için aktiftir.

"@

# Dosyaya kaydet
try {
    $content | Out-File -FilePath $OutputFile -Encoding UTF8 -Force
    Write-Host "✓ Bilgiler kaydedildi: $OutputFile"
    Write-Host ""
    Write-Host $content
} catch {
    Write-Host "✗ Dosya yazma hatası: $_"
    exit 1
}

# JSON format olarak da kaydet (script tarafından kullanım için)
$jsonContent = @{
    timestamp = $timestamp
    vdsUrl = $vdsUrl
    host = $host
    port = $port
    username = $username
    password = $password
    computerName = $computerName
} | ConvertTo-Json

$jsonContent | Out-File -FilePath "vds-info.json" -Encoding UTF8 -Force
Write-Host "✓ JSON bilgileri kaydedildi: vds-info.json"

exit 0
