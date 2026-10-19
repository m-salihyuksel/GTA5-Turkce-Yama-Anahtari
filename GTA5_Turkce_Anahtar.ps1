<#
    GTA V Türkçe Yama Anahtarı
    ---------------------------------------------------------------
    GTA TR'nin Türkçe yamasını tek tıkla AÇIP KAPATIR.

    KAPAT (Online için): yamayı etkinleştiren dosyaları (xinput1_4.dll,
      dinput8.dll, dsound.dll, args.txt, *.asi ve isteğe bağlı mods
      klasörü) oyun klasörünün DIŞINA, yanındaki bir depo klasörüne taşır.
    AÇ (Hikaye için): depodaki dosyaları oyun klasörüne geri taşır.

    Hiçbir dosya silinmez veya değiştirilmez; sadece yer değiştirir.
    Oyunun kendi dosyalarına dokunulmaz.

    Kullanım:
      GTA5_Turkce_Anahtar.bat          -> pencereli uygulama
      Online_Oncesi_KAPAT.bat          -> pencere açmadan yamayı kapatır
      Hikaye_Icin_AC.bat               -> pencere açmadan yamayı açar
#>
param(
    [ValidateSet('Arayuz', 'Ac', 'Kapat')]
    [string]$Islem = 'Arayuz',
    [string]$OyunKlasoru
)

$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------------
#  Sabitler
# ------------------------------------------------------------------
$Script:UygulamaAdi     = 'GTA V Türkçe Yama Anahtarı'
$Script:YukleyiciAdlari = @('xinput1_4.dll', 'dinput8.dll', 'dsound.dll')  # ASI yükleyiciler (Enhanced / Legacy / OpenRPF)
$Script:AyarAdlari      = @('args.txt')                                    # BattlEye'ı kapatan başlatma argümanları
$Script:ModsKlasorAdi   = 'mods'
$Script:DepoBilgiDosya  = 'BU_KLASORU_SILMEYIN.txt'
$Script:DepoEskiKlasor  = '_eski'
$Script:OyunSurecleri   = @('GTA5_Enhanced', 'GTA5', 'GTA5_BE', 'PlayGTAV')
$Script:YamaSayfasi     = 'https://gtatr.com/gta-5/turkce-yama/'

# ------------------------------------------------------------------
#  Çekirdek işlevler (arayüzden bağımsız)
# ------------------------------------------------------------------

function Get-NormalYol {
    param([string]$Yol)
    if ([string]::IsNullOrWhiteSpace($Yol)) { return $null }
    $y = $Yol.Trim().Trim('"')
    if ($y.Length -gt 3) { $y = $y.TrimEnd('\', '/') }
    return $y
}

function Get-OyunSurumu {
    # 'Enhanced', 'Legacy' ya da $null döndürür
    param([string]$Klasor)
    $Klasor = Get-NormalYol $Klasor
    if (-not $Klasor -or -not (Test-Path -LiteralPath $Klasor -PathType Container)) { return $null }
    $dosyalar = @(Get-ChildItem -LiteralPath $Klasor -File -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
    if ($dosyalar -contains 'GTA5_Enhanced.exe') { return 'Enhanced' }
    if ($dosyalar -contains 'GTA5.exe') { return 'Legacy' }
    return $null
}

function Get-DepoYolu {
    # Depo, oyun klasörünün YANINDA (dışında) durur: ...\<OyunKlasoru>_TurkceYama_Depo
    param([string]$Klasor)
    $Klasor = Get-NormalYol $Klasor
    $ust  = Split-Path -Path $Klasor -Parent
    $isim = Split-Path -Path $Klasor -Leaf
    if ([string]::IsNullOrEmpty($ust)) { throw "Oyun bir sürücünün kök dizininde olamaz: $Klasor" }
    return (Join-Path $ust ($isim + '_TurkceYama_Depo'))
}

function Get-OgeTuru {
    # 'yukleyici' | 'ayar' | 'asi' | 'mods' | $null
    param([string]$Ad, [bool]$KlasorMu)
    if ($KlasorMu) {
        if ($Ad -ieq $Script:ModsKlasorAdi) { return 'mods' }
        return $null
    }
    if ($Script:YukleyiciAdlari -contains $Ad) { return 'yukleyici' }
    if ($Script:AyarAdlari -contains $Ad) { return 'ayar' }
    if ([System.IO.Path]::GetExtension($Ad) -ieq '.asi') { return 'asi' }
    return $null
}

function Get-TurSirasi {
    param([string]$Tur)
    switch ($Tur) { 'yukleyici' { 0 } 'ayar' { 1 } 'asi' { 2 } 'mods' { 3 } default { 9 } }
}

function Get-YamaOgeleri {
    # Bir klasörün kökündeki yama öğelerini listeler
    param([string]$Klasor, [bool]$ModsDahil = $true)
    if (-not $Klasor -or -not (Test-Path -LiteralPath $Klasor -PathType Container)) { return }
    foreach ($o in Get-ChildItem -LiteralPath $Klasor -Force -ErrorAction SilentlyContinue) {
        $klasorMu = [bool]$o.PSIsContainer
        $tur = Get-OgeTuru -Ad $o.Name -KlasorMu $klasorMu
        if (-not $tur) { continue }
        if ($tur -eq 'mods' -and -not $ModsDahil) { continue }
        [pscustomobject]@{ Ad = $o.Name; Yol = $o.FullName; Klasor = $klasorMu; Tur = $tur }
    }
}

function Get-Durum {
    param([string]$Klasor, [bool]$ModsDahil = $true)
    $Klasor = Get-NormalYol $Klasor
    $d = [ordered]@{
        Gecerli       = $false
        Klasor        = $Klasor
        Surum         = $null
        Depo          = $null
        Oyunda        = @()
        Depoda        = @()
        OnlineGuvenli = $true
        ModsOyunda    = $false
        Kod           = 'gecersiz'   # gecersiz | acik | kapali | yok
    }
    $d.Surum = Get-OyunSurumu $Klasor
    if (-not $d.Surum) { return [pscustomobject]$d }
    try { $d.Depo = Get-DepoYolu $Klasor } catch { $d.Surum = $null; return [pscustomobject]$d }
    $d.Gecerli = $true
    $d.Oyunda  = @(Get-YamaOgeleri -Klasor $Klasor -ModsDahil $true)
    $d.Depoda  = @(Get-YamaOgeleri -Klasor $d.Depo -ModsDahil $true)

    $etkin = @($d.Oyunda | Where-Object { $_.Tur -ne 'mods' })
    $d.ModsOyunda    = @($d.Oyunda | Where-Object { $_.Tur -eq 'mods' }).Count -gt 0
    $d.OnlineGuvenli = ($etkin.Count -eq 0)

    if ($etkin.Count -gt 0)                       { $d.Kod = 'acik' }    # yükleyici/args/asi oyun klasöründe
    elseif ($d.Depoda.Count -gt 0 -or $d.ModsOyunda) { $d.Kod = 'kapali' }  # yama var ama devre dışı
    else                                          { $d.Kod = 'yok' }     # hiç yama izi yok
    return [pscustomobject]$d
}

function Test-OyunCalisiyor {
    $p = @(Get-Process -Name $Script:OyunSurecleri -ErrorAction SilentlyContinue)
    return ($p.Count -gt 0)
}

function Move-YamaOgesi {
    # Dosya ya da klasörü taşır; hedef varsa hata verir (üzerine YAZMAZ)
    param([string]$Kaynak, [string]$Hedef, [bool]$Klasor)
    if (Test-Path -LiteralPath $Hedef) { throw "Hedefte aynı isimde öğe zaten var: $Hedef" }
    if ($Klasor) { [System.IO.Directory]::Move($Kaynak, $Hedef) }
    else         { [System.IO.File]::Move($Kaynak, $Hedef) }
}

function Initialize-Depo {
    param([string]$Depo, [string]$OyunKlasor)
    if (-not (Test-Path -LiteralPath $Depo)) {
        New-Item -ItemType Directory -Path $Depo -Force | Out-Null
    }
    $bilgi = Join-Path $Depo $Script:DepoBilgiDosya
    if (-not (Test-Path -LiteralPath $bilgi)) {
        $metin = @(
            'Bu klasörü GTA V Türkçe Yama Anahtarı oluşturdu.'
            ''
            "Türkçe yama KAPALIYKEN yamanın dosyaları burada bekler:"
            "  $OyunKlasor"
            ''
            'Silerseniz Türkçe yamayı tekrar açamazsınız (yeniden kurmanız gerekir).'
            "Yamayı açmak için uygulamada 'Türkçe AÇ' düğmesine basın."
        ) -join "`r`n"
        [System.IO.File]::WriteAllText($bilgi, $metin, (New-Object System.Text.UTF8Encoding($true)))
    }
}

function Invoke-YamaKapat {
    # Online öncesi: yama öğelerini oyun klasöründen depoya taşır
    param([string]$Klasor, [bool]$ModsDahil = $true, [scriptblock]$Log = { param($m) })
    $Klasor = Get-NormalYol $Klasor
    $sonuc = [ordered]@{ Basarili = $true; Tasinan = 0; Atlanan = 0; Hatalar = @() }

    if (-not (Get-OyunSurumu $Klasor)) { throw "Geçerli bir GTA V klasörü değil: $Klasor" }
    if (Test-OyunCalisiyor) { throw 'GTA V şu an açık. Önce oyunu tamamen kapatın.' }

    $depo = Get-DepoYolu $Klasor
    $ogeler = @(Get-YamaOgeleri -Klasor $Klasor -ModsDahil $ModsDahil |
        Sort-Object { Get-TurSirasi $_.Tur }, Ad)

    if ($ogeler.Count -eq 0) {
        & $Log 'Oyun klasöründe taşınacak yama dosyası yok. Zaten online''a hazır.'
        return [pscustomobject]$sonuc
    }

    Initialize-Depo -Depo $depo -OyunKlasor $Klasor
    $damga = Get-Date -Format 'yyyyMMdd-HHmmss'

    foreach ($o in $ogeler) {
        $hedef = Join-Path $depo $o.Ad
        try {
            if (Test-Path -LiteralPath $hedef) {
                # Depoda eskiden kalan aynı isimli öğe var: silmeden kenara al
                $eskiKlasor = Join-Path $depo $Script:DepoEskiKlasor
                if (-not (Test-Path -LiteralPath $eskiKlasor)) { New-Item -ItemType Directory -Path $eskiKlasor -Force | Out-Null }
                $eskiHedef = Join-Path $eskiKlasor ($o.Ad + '.' + $damga)
                Move-YamaOgesi -Kaynak $hedef -Hedef $eskiHedef -Klasor $o.Klasor
                & $Log "  Depodaki eski '$($o.Ad)' kenara alındı: $($Script:DepoEskiKlasor)\$($o.Ad).$damga"
            }
            Move-YamaOgesi -Kaynak $o.Yol -Hedef $hedef -Klasor $o.Klasor
            $sonuc.Tasinan++
            & $Log "  Taşındı -> depo: $($o.Ad)"
        }
        catch {
            $mesaj = $_.Exception.Message
            if ($o.Tur -eq 'mods') {
                # mods klasörü yükleyici olmadan zaten yüklenmez; taşınamazsa kritik değil
                $sonuc.Atlanan++
                & $Log "  UYARI: mods klasörü taşınamadı ($mesaj). Yükleyici kaldırıldığı için oyun bu klasörü okumaz."
            }
            else {
                $sonuc.Basarili = $false
                $sonuc.Hatalar += "$($o.Ad): $mesaj"
                & $Log "  HATA: $($o.Ad) taşınamadı: $mesaj"
            }
        }
    }

    # Son kontrol: online'ı engelleyen bir şey kaldı mı?
    $kalan = @(Get-YamaOgeleri -Klasor $Klasor -ModsDahil $false)
    if ($kalan.Count -gt 0) {
        $sonuc.Basarili = $false
        $sonuc.Hatalar += "Oyun klasöründe hâlâ duran: " + (($kalan | ForEach-Object { $_.Ad }) -join ', ') + " — bu haldeyken online'a GİRMEYİN."
    }
    return [pscustomobject]$sonuc
}

function Invoke-YamaAc {
    # Hikaye modu: depodaki öğeleri oyun klasörüne geri taşır
    param([string]$Klasor, [scriptblock]$Log = { param($m) })
    $Klasor = Get-NormalYol $Klasor
    $sonuc = [ordered]@{ Basarili = $true; Tasinan = 0; Atlanan = 0; Hatalar = @() }

    if (-not (Get-OyunSurumu $Klasor)) { throw "Geçerli bir GTA V klasörü değil: $Klasor" }
    if (Test-OyunCalisiyor) { throw 'GTA V şu an açık. Önce oyunu tamamen kapatın.' }

    $depo = Get-DepoYolu $Klasor
    # Yükleyici en son gelsin: önce mods, sonra .asi, sonra args.txt, en son dll
    $ogeler = @(Get-YamaOgeleri -Klasor $depo -ModsDahil $true |
        Sort-Object { - (Get-TurSirasi $_.Tur) }, Ad)

    if ($ogeler.Count -eq 0) {
        & $Log 'Depoda geri getirilecek dosya yok.'
        if (@(Get-YamaOgeleri -Klasor $Klasor -ModsDahil $false).Count -gt 0) {
            & $Log 'Türkçe yama zaten açık görünüyor.'
        }
        else {
            & $Log 'Türkçe yama kurulu görünmüyor. Önce GTA TR Türkçe yamasını kurun.'
            $sonuc.Basarili = $false
            $sonuc.Hatalar += 'Yama bulunamadı'
        }
        return [pscustomobject]$sonuc
    }

    foreach ($o in $ogeler) {
        $hedef = Join-Path $Klasor $o.Ad
        try {
            if (Test-Path -LiteralPath $hedef) {
                $sonuc.Atlanan++
                & $Log "  Atlandı: '$($o.Ad)' oyun klasöründe zaten var (depodaki kopya korunuyor)."
                continue
            }
            Move-YamaOgesi -Kaynak $o.Yol -Hedef $hedef -Klasor $o.Klasor
            $sonuc.Tasinan++
            & $Log "  Geri getirildi -> oyun: $($o.Ad)"
        }
        catch {
            $sonuc.Basarili = $false
            $sonuc.Hatalar += "$($o.Ad): $($_.Exception.Message)"
            & $Log "  HATA: $($o.Ad) geri getirilemedi: $($_.Exception.Message)"
        }
    }

    # Depo boşaldıysa (sadece bilgi dosyası kaldıysa) temizle
    try {
        $kalanlar = @(Get-ChildItem -LiteralPath $depo -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne $Script:DepoBilgiDosya })
        if ($kalanlar.Count -eq 0) {
            Remove-Item -LiteralPath (Join-Path $depo $Script:DepoBilgiDosya) -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $depo -Force -ErrorAction SilentlyContinue
        }
    }
    catch { }

    return [pscustomobject]$sonuc
}

function Find-OyunKlasorleri {
    # Steam, Epic ve Rockstar kurulumlarını arar; Enhanced olanlar önce gelir
    $adaylar = New-Object System.Collections.Generic.List[string]
    $ekle = { param($y) if ($y) { $adaylar.Add([string]$y) } }

    # Steam
    try {
        $steamYollari = @()
        foreach ($anahtar in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam') {
            $p = Get-ItemProperty -Path $anahtar -ErrorAction SilentlyContinue
            if ($p.SteamPath)   { $steamYollari += ($p.SteamPath -replace '/', '\') }
            if ($p.InstallPath) { $steamYollari += $p.InstallPath }
        }
        $steamYollari += "${env:ProgramFiles(x86)}\Steam"
        $kutuphaneler = @()
        foreach ($s in ($steamYollari | Select-Object -Unique)) {
            if (-not (Test-Path -LiteralPath $s)) { continue }
            $kutuphaneler += $s
            $vdf = Join-Path $s 'steamapps\libraryfolders.vdf'
            if (Test-Path -LiteralPath $vdf) {
                $icerik = Get-Content -LiteralPath $vdf -Raw -ErrorAction SilentlyContinue
                foreach ($m in [regex]::Matches($icerik, '"path"\s+"([^"]+)"')) {
                    $kutuphaneler += ($m.Groups[1].Value -replace '\\\\', '\')
                }
            }
        }
        foreach ($k in ($kutuphaneler | Select-Object -Unique)) {
            & $ekle (Join-Path $k 'steamapps\common\Grand Theft Auto V Enhanced')
            & $ekle (Join-Path $k 'steamapps\common\Grand Theft Auto V')
        }
    } catch { }

    # Epic Games
    try {
        $manifestler = Join-Path $env:ProgramData 'Epic\EpicGamesLauncher\Data\Manifests'
        if (Test-Path -LiteralPath $manifestler) {
            foreach ($f in Get-ChildItem -LiteralPath $manifestler -Filter '*.item' -ErrorAction SilentlyContinue) {
                try {
                    $j = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json
                    if ($j.DisplayName -like '*Grand Theft Auto V*' -or $j.InstallLocation -like '*GTA*') { & $ekle $j.InstallLocation }
                } catch { }
            }
        }
    } catch { }

    # Rockstar Games Launcher
    try {
        foreach ($kok in 'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games', 'HKLM:\SOFTWARE\Rockstar Games') {
            foreach ($alt in Get-ChildItem -Path $kok -ErrorAction SilentlyContinue) {
                $p = Get-ItemProperty -Path $alt.PSPath -ErrorAction SilentlyContinue
                if ($p.InstallFolder) { & $ekle $p.InstallFolder }
            }
        }
    } catch { }

    # Varsayılan yollar
    foreach ($y in @(
            "$env:ProgramFiles\Rockstar Games\Grand Theft Auto V Enhanced",
            "$env:ProgramFiles\Rockstar Games\Grand Theft Auto V",
            "$env:ProgramFiles\Epic Games\GTAVEnhanced",
            "$env:ProgramFiles\Epic Games\GTAV")) { & $ekle $y }

    $bulunan = @()
    $gorulen = @{}
    foreach ($a in $adaylar) {
        $n = Get-NormalYol $a
        if (-not $n) { continue }
        $anahtar = $n.ToLowerInvariant()
        if ($gorulen.ContainsKey($anahtar)) { continue }
        $gorulen[$anahtar] = $true
        $s = Get-OyunSurumu $n
        if ($s) { $bulunan += [pscustomobject]@{ Yol = $n; Surum = $s } }
    }
    $bulunan | Sort-Object { if ($_.Surum -eq 'Enhanced') { 0 } else { 1 } } | ForEach-Object { $_.Yol }
}

function Get-AyarDosyasi {
    $kok = Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'GTA5TurkceYamaAnahtari'
    return (Join-Path $kok 'ayarlar.json')
}

function Get-Ayarlar {
    $varsayilan = [pscustomobject]@{ OyunKlasoru = ''; ModsDahil = $true }
    try {
        $f = Get-AyarDosyasi
        if (Test-Path -LiteralPath $f) {
            $j = Get-Content -LiteralPath $f -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($null -ne $j.OyunKlasoru) { $varsayilan.OyunKlasoru = [string]$j.OyunKlasoru }
            if ($null -ne $j.ModsDahil)   { $varsayilan.ModsDahil   = [bool]$j.ModsDahil }
        }
    } catch { }
    return $varsayilan
}

function Save-Ayarlar {
    param([string]$OyunKlasoru, [bool]$ModsDahil)
    try {
        $f = Get-AyarDosyasi
        $kok = Split-Path $f -Parent
        if (-not (Test-Path -LiteralPath $kok)) { New-Item -ItemType Directory -Path $kok -Force | Out-Null }
        $json = [pscustomobject]@{ OyunKlasoru = $OyunKlasoru; ModsDahil = $ModsDahil } | ConvertTo-Json
        [System.IO.File]::WriteAllText($f, $json, (New-Object System.Text.UTF8Encoding($false)))
    } catch { }
}

function Format-Sonuc {
    param($Sonuc, [string]$Islem)
    if ($Sonuc.Basarili) {
        if ($Islem -eq 'Kapat') { return "Türkçe yama KAPATILDI ($($Sonuc.Tasinan) öğe depoya taşındı).`r`n`r`nArtık GTA Online'a girebilirsiniz." }
        return "Türkçe yama AÇILDI ($($Sonuc.Tasinan) öğe geri getirildi).`r`n`r`nHikaye modunda altyazıları açmayı unutmayın. Bu haldeyken GTA Online'a GİRMEYİN."
    }
    return "İşlem tamamlanamadı:`r`n`r`n" + (($Sonuc.Hatalar | ForEach-Object { "• $_" }) -join "`r`n")
}

# ------------------------------------------------------------------
#  Başlangıç: yönetici izni
# ------------------------------------------------------------------

function Test-Yonetici {
    $kimlik = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($kimlik)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-YoneticiOlarak {
    $argumanlar = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}" -Islem {1}' -f $PSCommandPath, $Islem
    $k = Get-NormalYol $OyunKlasoru
    if ($k) { $argumanlar += ' -OyunKlasoru "{0}"' -f $k }
    Start-Process -FilePath 'powershell.exe' -ArgumentList $argumanlar -Verb RunAs | Out-Null
}

# ------------------------------------------------------------------
#  Arayüz
# ------------------------------------------------------------------

function Show-Arayuz {
    $ayarlar = Get-Ayarlar

    try {
        Add-Type -Namespace Win32 -Name Dpi -MemberDefinition '[System.Runtime.InteropServices.DllImport("user32.dll")] public static extern bool SetProcessDPIAware();' -ErrorAction Stop
        [Win32.Dpi]::SetProcessDPIAware() | Out-Null
    } catch { }
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $g = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero)
    $olcek = [Math]::Max(1.0, $g.DpiX / 96.0)
    $g.Dispose()
    function px([double]$v) { [int][Math]::Round($v * $olcek) }

    $yazi      = New-Object System.Drawing.Font('Segoe UI', 10)
    $yaziKalin = New-Object System.Drawing.Font('Segoe UI Semibold', 10)
    $yaziBaslik= New-Object System.Drawing.Font('Segoe UI Semibold', 15)
    $yaziDurum = New-Object System.Drawing.Font('Segoe UI Semibold', 13)
    $yaziDugme = New-Object System.Drawing.Font('Segoe UI Semibold', 11)
    $yaziLog   = New-Object System.Drawing.Font('Consolas', 9)

    $renk = @{
        AcikZemin   = [System.Drawing.Color]::FromArgb(255, 243, 224); AcikYazi   = [System.Drawing.Color]::FromArgb(150, 70, 0)
        KapaliZemin = [System.Drawing.Color]::FromArgb(227, 242, 253); KapaliYazi = [System.Drawing.Color]::FromArgb(13, 71, 161)
        YokZemin    = [System.Drawing.Color]::FromArgb(238, 238, 238); YokYazi    = [System.Drawing.Color]::FromArgb(66, 66, 66)
        HataZemin   = [System.Drawing.Color]::FromArgb(255, 235, 238); HataYazi   = [System.Drawing.Color]::FromArgb(183, 28, 28)
        AcDugme     = [System.Drawing.Color]::FromArgb(198, 40, 40)
        KapatDugme  = [System.Drawing.Color]::FromArgb(21, 101, 192)
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Script:UygulamaAdi
    $form.Font = $yazi
    $form.StartPosition = 'CenterScreen'
    $form.ClientSize = New-Object System.Drawing.Size((px 680), (px 600))
    $form.MinimumSize = New-Object System.Drawing.Size((px 560), (px 520))
    $form.Padding = New-Object System.Windows.Forms.Padding((px 14))
    try { $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -Id $PID).Path) } catch { }

    $ana = New-Object System.Windows.Forms.TableLayoutPanel
    $ana.Dock = 'Fill'
    $ana.ColumnCount = 1
    $ana.RowCount = 8
    [void]$ana.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 100)))
    for ($i = 0; $i -lt 8; $i++) {
        if ($i -eq 6) { [void]$ana.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 100))) }
        else          { [void]$ana.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize'))) }
    }
    $form.Controls.Add($ana)

    # 0) Başlık
    $baslik = New-Object System.Windows.Forms.Label
    $baslik.Text = 'GTA V Türkçe Yama Anahtarı'
    $baslik.Font = $yaziBaslik
    $baslik.AutoSize = $true
    $baslik.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, (px 2))
    $ana.Controls.Add($baslik, 0, 0)

    # 1) Klasör seçimi
    $klasorSatir = New-Object System.Windows.Forms.TableLayoutPanel
    $klasorSatir.Dock = 'Fill'; $klasorSatir.AutoSize = $true
    $klasorSatir.ColumnCount = 3; $klasorSatir.RowCount = 1
    [void]$klasorSatir.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))
    [void]$klasorSatir.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 100)))
    [void]$klasorSatir.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))
    $klasorSatir.Margin = New-Object System.Windows.Forms.Padding(0, (px 8), 0, 0)

    $lblKlasor = New-Object System.Windows.Forms.Label
    $lblKlasor.Text = 'Oyun klasörü:'; $lblKlasor.AutoSize = $true; $lblKlasor.Anchor = 'Left'
    $cmbKlasor = New-Object System.Windows.Forms.ComboBox
    $cmbKlasor.Dock = 'Fill'; $cmbKlasor.DropDownStyle = 'DropDown'
    $btnGozat = New-Object System.Windows.Forms.Button
    $btnGozat.Text = 'Gözat...'; $btnGozat.AutoSize = $true
    $klasorSatir.Controls.Add($lblKlasor, 0, 0)
    $klasorSatir.Controls.Add($cmbKlasor, 1, 0)
    $klasorSatir.Controls.Add($btnGozat, 2, 0)
    $ana.Controls.Add($klasorSatir, 0, 1)

    # 2) Sürüm bilgisi
    $lblSurum = New-Object System.Windows.Forms.Label
    $lblSurum.AutoSize = $true
    $lblSurum.ForeColor = [System.Drawing.Color]::DimGray
    $lblSurum.Margin = New-Object System.Windows.Forms.Padding(0, (px 4), 0, (px 8))
    $ana.Controls.Add($lblSurum, 0, 2)

    # 3) Durum paneli
    $pnlDurum = New-Object System.Windows.Forms.TableLayoutPanel
    $pnlDurum.Dock = 'Fill'; $pnlDurum.AutoSize = $true
    $pnlDurum.ColumnCount = 1; $pnlDurum.RowCount = 2
    $pnlDurum.Padding = New-Object System.Windows.Forms.Padding((px 12))
    $pnlDurum.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, (px 10))
    $lblDurum = New-Object System.Windows.Forms.Label
    $lblDurum.Font = $yaziDurum; $lblDurum.AutoSize = $true
    $lblDurumAyrinti = New-Object System.Windows.Forms.Label
    $lblDurumAyrinti.AutoSize = $true
    $lblDurumAyrinti.MaximumSize = New-Object System.Drawing.Size((px 620), 0)
    $lblDurumAyrinti.Margin = New-Object System.Windows.Forms.Padding(0, (px 4), 0, 0)
    $pnlDurum.Controls.Add($lblDurum, 0, 0)
    $pnlDurum.Controls.Add($lblDurumAyrinti, 0, 1)
    $ana.Controls.Add($pnlDurum, 0, 3)

    # 4) Ana düğmeler
    $dugmeSatir = New-Object System.Windows.Forms.TableLayoutPanel
    $dugmeSatir.Dock = 'Fill'; $dugmeSatir.AutoSize = $true
    $dugmeSatir.ColumnCount = 2; $dugmeSatir.RowCount = 1
    [void]$dugmeSatir.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 50)))
    [void]$dugmeSatir.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 50)))
    $dugmeSatir.Margin = New-Object System.Windows.Forms.Padding(0)

    $yeniDugme = {
        param($metin, $zemin)
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $metin
        $b.Font = $yaziDugme
        $b.Dock = 'Fill'
        $b.Height = (px 64)
        $b.FlatStyle = 'Flat'
        $b.FlatAppearance.BorderSize = 0
        $b.BackColor = $zemin
        $b.ForeColor = [System.Drawing.Color]::White
        $b.Cursor = [System.Windows.Forms.Cursors]::Hand
        $b
    }
    $btnAc    = & $yeniDugme "Türkçe AÇ`r`n(Hikaye modu)" $renk.AcDugme
    $btnKapat = & $yeniDugme "Türkçe KAPAT`r`n(Online'a geçerken)" $renk.KapatDugme
    # Pasif düğme gri görünsün
    $btnAc.Add_EnabledChanged({ if ($this.Enabled) { $this.BackColor = $renk.AcDugme } else { $this.BackColor = [System.Drawing.Color]::Gainsboro } })
    $btnKapat.Add_EnabledChanged({ if ($this.Enabled) { $this.BackColor = $renk.KapatDugme } else { $this.BackColor = [System.Drawing.Color]::Gainsboro } })
    $btnAc.Margin    = New-Object System.Windows.Forms.Padding(0, 0, (px 5), 0)
    $btnKapat.Margin = New-Object System.Windows.Forms.Padding((px 5), 0, 0, 0)
    $dugmeSatir.Controls.Add($btnAc, 0, 0)
    $dugmeSatir.Controls.Add($btnKapat, 1, 0)
    $ana.Controls.Add($dugmeSatir, 0, 4)

    # 5) Seçenek
    $chkMods = New-Object System.Windows.Forms.CheckBox
    $chkMods.Text = "KAPAT'ta mods klasörünü de taşı (önerilir; aynı diskte anında olur)"
    $chkMods.AutoSize = $true
    $chkMods.Checked = [bool]$ayarlar.ModsDahil
    $chkMods.Margin = New-Object System.Windows.Forms.Padding(0, (px 8), 0, (px 6))
    $ana.Controls.Add($chkMods, 0, 5)

    # 6) Günlük
    $txtLog = New-Object System.Windows.Forms.TextBox
    $txtLog.Multiline = $true; $txtLog.ReadOnly = $true; $txtLog.ScrollBars = 'Vertical'
    $txtLog.Dock = 'Fill'; $txtLog.Font = $yaziLog
    $txtLog.BackColor = [System.Drawing.Color]::White
    $ana.Controls.Add($txtLog, 0, 6)

    # 7) Alt satır: solda bağlantı + düğmeler, sağ altta yapımcı
    $altSatir = New-Object System.Windows.Forms.TableLayoutPanel
    $altSatir.Dock = 'Fill'; $altSatir.AutoSize = $true
    $altSatir.ColumnCount = 2; $altSatir.RowCount = 1
    [void]$altSatir.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 100)))
    [void]$altSatir.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))
    $altSatir.Margin = New-Object System.Windows.Forms.Padding(0, (px 8), 0, 0)

    $alt = New-Object System.Windows.Forms.FlowLayoutPanel
    $alt.Dock = 'Fill'; $alt.AutoSize = $true; $alt.WrapContents = $true
    $alt.Margin = New-Object System.Windows.Forms.Padding(0)

    $lblYapimci = New-Object System.Windows.Forms.Label
    $lblYapimci.Text = 'Yapımcı: MSY'
    $lblYapimci.Font = $yaziKalin
    $lblYapimci.ForeColor = [System.Drawing.Color]::DimGray
    $lblYapimci.AutoSize = $true
    $lblYapimci.Anchor = 'Right, Bottom'
    $lblYapimci.Margin = New-Object System.Windows.Forms.Padding((px 12), 0, 0, (px 6))
    $lnkYama = New-Object System.Windows.Forms.LinkLabel
    $lnkYama.Text = 'Türkçe yamayı indir (GTA TR)'; $lnkYama.AutoSize = $true
    $lnkYama.Margin = New-Object System.Windows.Forms.Padding(0, (px 7), (px 12), 0)
    $btnOyunAc  = New-Object System.Windows.Forms.Button; $btnOyunAc.Text = 'Oyun klasörünü aç'; $btnOyunAc.AutoSize = $true
    $btnDepoAc  = New-Object System.Windows.Forms.Button; $btnDepoAc.Text = 'Depoyu aç'; $btnDepoAc.AutoSize = $true
    $btnYenile  = New-Object System.Windows.Forms.Button; $btnYenile.Text = 'Yenile'; $btnYenile.AutoSize = $true
    $alt.Controls.AddRange(@($lnkYama, $btnOyunAc, $btnDepoAc, $btnYenile))
    $altSatir.Controls.Add($alt, 0, 0)
    $altSatir.Controls.Add($lblYapimci, 1, 0)
    $ana.Controls.Add($altSatir, 0, 7)

    $ipucu = New-Object System.Windows.Forms.ToolTip
    $ipucu.SetToolTip($btnKapat, 'Yama dosyalarını oyun klasörünün dışına (yanındaki depo klasörüne) taşır.')
    $ipucu.SetToolTip($btnAc, 'Depodaki yama dosyalarını oyun klasörüne geri getirir.')

    # --- Yardımcılar ---
    $log = {
        param($m)
        $txtLog.AppendText(('[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $m) + "`r`n")
    }

    $yenile = {
        $k = Get-NormalYol $cmbKlasor.Text
        try { $d = Get-Durum -Klasor $k -ModsDahil $chkMods.Checked }
        catch { $d = [pscustomobject]@{ Gecerli = $false } }
        $calisiyor = Test-OyunCalisiyor

        if (-not $d.Gecerli) {
            $lblSurum.Text = ''
            $pnlDurum.BackColor = $renk.HataZemin; $lblDurum.ForeColor = $renk.HataYazi
            $lblDurum.Text = 'Oyun klasörü seçin'
            $lblDurumAyrinti.ForeColor = $renk.HataYazi
            $lblDurumAyrinti.Text = 'İçinde GTA5_Enhanced.exe (ya da Legacy için GTA5.exe) bulunan klasörü seçin.'
            $btnAc.Enabled = $false; $btnKapat.Enabled = $false; $btnDepoAc.Enabled = $false; $btnOyunAc.Enabled = $false
            return
        }

        $lblSurum.Text = "Sürüm: GTA V $($d.Surum)    •    Depo: $($d.Depo)"
        $btnOyunAc.Enabled = $true
        $btnDepoAc.Enabled = (Test-Path -LiteralPath $d.Depo)
        $oyundaAd = ($d.Oyunda | ForEach-Object { $_.Ad }) -join ', '
        $depodaAd = ($d.Depoda | ForEach-Object { $_.Ad }) -join ', '

        switch ($d.Kod) {
            'acik' {
                $pnlDurum.BackColor = $renk.AcikZemin; $lblDurum.ForeColor = $renk.AcikYazi; $lblDurumAyrinti.ForeColor = $renk.AcikYazi
                $lblDurum.Text = 'TÜRKÇE AÇIK  —  sadece Hikaye modu'
                $lblDurumAyrinti.Text = "GTA Online'a girmeden önce oyunu kapatıp 'Türkçe KAPAT'a basın.`r`nOyun klasöründe: $oyundaAd"
            }
            'kapali' {
                $pnlDurum.BackColor = $renk.KapaliZemin; $lblDurum.ForeColor = $renk.KapaliYazi; $lblDurumAyrinti.ForeColor = $renk.KapaliYazi
                $lblDurum.Text = "TÜRKÇE KAPALI  —  Online'a hazır"
                $ek = ''
                if ($d.ModsOyunda) { $ek = "`r`nNot: mods klasörü oyun klasöründe duruyor; yükleyici olmadığı için oyun onu okumaz." }
                if ($depodaAd) { $lblDurumAyrinti.Text = "Yama dosyaları depoda bekliyor: $depodaAd$ek" }
                else { $lblDurumAyrinti.Text = "Oyun klasöründe yama yükleyicisi yok.$ek" }
            }
            default {
                $pnlDurum.BackColor = $renk.YokZemin; $lblDurum.ForeColor = $renk.YokYazi; $lblDurumAyrinti.ForeColor = $renk.YokYazi
                $lblDurum.Text = 'Türkçe yama bulunamadı'
                $lblDurumAyrinti.Text = "Önce GTA TR'nin Türkçe yamasını kurun (aşağıdaki bağlantı), sonra bu uygulamayla açıp kapatın. Oyun şu an orijinal halde, online'a girebilirsiniz."
            }
        }

        if ($calisiyor) {
            $lblDurumAyrinti.Text += "`r`n`r`n⚠ GTA V açık. Değişiklik yapmak için önce oyunu kapatın."
        }
        $btnAc.Enabled    = (-not $calisiyor) -and ($d.Depoda.Count -gt 0)
        $btnKapat.Enabled = (-not $calisiyor) -and (($d.Kod -eq 'acik') -or ($chkMods.Checked -and $d.ModsOyunda))
    }

    $islemYap = {
        param([string]$Tur)
        $k = Get-NormalYol $cmbKlasor.Text
        $form.UseWaitCursor = $true
        $btnAc.Enabled = $false; $btnKapat.Enabled = $false
        [System.Windows.Forms.Application]::DoEvents()
        try {
            if ($Tur -eq 'Kapat') {
                & $log 'Türkçe yama kapatılıyor...'
                $s = Invoke-YamaKapat -Klasor $k -ModsDahil $chkMods.Checked -Log $log
            }
            else {
                & $log 'Türkçe yama açılıyor...'
                $s = Invoke-YamaAc -Klasor $k -Log $log
            }
            Save-Ayarlar -OyunKlasoru $k -ModsDahil $chkMods.Checked
            if ($s.Basarili) {
                if ($Tur -eq 'Kapat') { & $log "Tamam: Online'a girebilirsiniz." } else { & $log 'Tamam: Hikaye modunda Türkçe oynayabilirsiniz.' }
            }
            else {
                [System.Windows.Forms.MessageBox]::Show($form, (Format-Sonuc $s $Tur), $Script:UygulamaAdi, 'OK', 'Warning') | Out-Null
            }
        }
        catch {
            & $log "HATA: $($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show($form, $_.Exception.Message, $Script:UygulamaAdi, 'OK', 'Error') | Out-Null
        }
        finally {
            $form.UseWaitCursor = $false
            & $yenile
        }
    }

    # --- Olaylar ---
    $cmbKlasor.Add_TextChanged({ & $yenile })
    $chkMods.Add_CheckedChanged({ & $yenile; Save-Ayarlar -OyunKlasoru (Get-NormalYol $cmbKlasor.Text) -ModsDahil $chkMods.Checked })
    $btnYenile.Add_Click({ & $yenile; & $log 'Durum yenilendi.' })
    $form.Add_Activated({ & $yenile })
    $btnAc.Add_Click({ & $islemYap 'Ac' })
    $btnKapat.Add_Click({ & $islemYap 'Kapat' })
    $lnkYama.Add_LinkClicked({ Start-Process $Script:YamaSayfasi })
    $btnOyunAc.Add_Click({ $k = Get-NormalYol $cmbKlasor.Text; if ($k -and (Test-Path -LiteralPath $k)) { Start-Process explorer.exe -ArgumentList "`"$k`"" } })
    $btnDepoAc.Add_Click({
            $k = Get-NormalYol $cmbKlasor.Text
            try { $dp = Get-DepoYolu $k; if (Test-Path -LiteralPath $dp) { Start-Process explorer.exe -ArgumentList "`"$dp`"" } } catch { }
        })
    $btnGozat.Add_Click({
            $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
            $dlg.Description = 'GTA V klasörünü seçin (içinde GTA5_Enhanced.exe olan klasör)'
            $dlg.ShowNewFolderButton = $false
            $mevcut = Get-NormalYol $cmbKlasor.Text
            if ($mevcut -and (Test-Path -LiteralPath $mevcut)) { $dlg.SelectedPath = $mevcut }
            if ($dlg.ShowDialog($form) -eq 'OK') {
                $cmbKlasor.Text = $dlg.SelectedPath
                if (Get-OyunSurumu $dlg.SelectedPath) { Save-Ayarlar -OyunKlasoru $dlg.SelectedPath -ModsDahil $chkMods.Checked }
                else { & $log 'Seçilen klasörde GTA5_Enhanced.exe ya da GTA5.exe bulunamadı.' }
            }
        })

    # --- İlk yükleme ---
    $bulunan = @(Find-OyunKlasorleri)
    foreach ($b in $bulunan) { [void]$cmbKlasor.Items.Add($b) }
    $baslangic = Get-NormalYol $OyunKlasoru
    if (-not $baslangic -and $ayarlar.OyunKlasoru -and (Get-OyunSurumu $ayarlar.OyunKlasoru)) { $baslangic = $ayarlar.OyunKlasoru }
    if (-not $baslangic -and $bulunan.Count -gt 0) { $baslangic = $bulunan[0] }
    if ($baslangic) {
        if (-not $cmbKlasor.Items.Contains($baslangic)) { [void]$cmbKlasor.Items.Insert(0, $baslangic) }
        $cmbKlasor.Text = $baslangic
    }

    & $log 'Hazır. Oyun açıkken değişiklik yapılamaz: önce oyunu kapatın, sonra düğmeye basın.'
    if ($bulunan.Count -eq 0 -and -not $baslangic) { & $log "Oyun otomatik bulunamadı. 'Gözat...' ile oyun klasörünü seçin." }
    elseif ($bulunan.Count -gt 1) { & $log "$($bulunan.Count) GTA V kurulumu bulundu; listeden seçebilirsiniz." }
    & $yenile

    [void]$form.ShowDialog()
}

# ------------------------------------------------------------------
#  Hızlı mod (pencere açmadan Ac/Kapat)
# ------------------------------------------------------------------

function Invoke-HizliMod {
    $baslik = $Script:UygulamaAdi
    try {
        $k = Get-NormalYol $OyunKlasoru
        if (-not $k) {
            $a = Get-Ayarlar
            if ($a.OyunKlasoru -and (Get-OyunSurumu $a.OyunKlasoru)) { $k = $a.OyunKlasoru }
        }
        if (-not $k) {
            $bulunan = @(Find-OyunKlasorleri)
            if ($bulunan.Count -eq 1) { $k = $bulunan[0] }
            elseif ($bulunan.Count -gt 1) { throw "Birden fazla GTA V kurulumu bulundu. Önce GTA5_Turkce_Anahtar.bat ile uygulamayı açıp oyun klasörünü seçin." }
            else { throw "GTA V klasörü bulunamadı. Önce GTA5_Turkce_Anahtar.bat ile uygulamayı açıp oyun klasörünü seçin." }
        }
        $a = Get-Ayarlar
        if ($Islem -eq 'Kapat') { $s = Invoke-YamaKapat -Klasor $k -ModsDahil $a.ModsDahil }
        else                    { $s = Invoke-YamaAc -Klasor $k }
        Save-Ayarlar -OyunKlasoru $k -ModsDahil $a.ModsDahil
        $ikon = 'Information'; if (-not $s.Basarili) { $ikon = 'Warning' }
        [System.Windows.Forms.MessageBox]::Show((Format-Sonuc $s $Islem) + "`r`n`r`nKlasör: $k", $baslik, 'OK', $ikon) | Out-Null
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, $baslik, 'OK', 'Error') | Out-Null
    }
}

# ------------------------------------------------------------------
#  Giriş noktası
# ------------------------------------------------------------------

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

if (-not (Test-Yonetici)) {
    try { Start-YoneticiOlarak }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Oyun klasörü (çoğunlukla Program Files) korumalı olduğu için yönetici izni gerekiyor.`r`n`r`nTekrar açıp UAC penceresinde 'Evet'e basın.",
            $Script:UygulamaAdi, 'OK', 'Warning') | Out-Null
    }
    exit
}

if ($Islem -eq 'Arayuz') { Show-Arayuz }
else { Invoke-HizliMod }
