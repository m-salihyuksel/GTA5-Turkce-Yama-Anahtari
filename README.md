# GTA V Türkçe Yama Anahtarı

GTA V **Enhanced** (ve Legacy) için Türkçe yamayı tek tıkla **açıp kapatan** küçük bir Windows uygulaması.

| Düğme | Ne olur |
|---|---|
| **Türkçe AÇ** | Hikaye modunu Türkçe oynarsın. |
| **Türkçe KAPAT** | Yama dosyaları oyun klasörünün dışına taşınır, oyun orijinal haline döner, GTA Online'a girebilirsin. |

Hiçbir dosya silinmez ya da değiştirilmez, dosyalar sadece yer değiştirir. Oyunun kendi dosyalarına dokunulmaz.

> **Not:** Bu depo çeviri dosyalarını **içermez**. Önce GTA TR'nin Türkçe yamasını kurman gerekir:
> https://gtatr.com/gta-5/turkce-yama/

---

## İndirme

1. Bu sayfanın üstündeki yeşil **Code** düğmesine bas, **Download ZIP**'i seç.
2. Zip'i masaüstünde bir klasöre çıkar (zip'in içinden çalıştırma).

## Kurulum

1. GTA TR'nin **Universal Türkçe Yama**'sını kur.
2. `GTA5_Turkce_Anahtar.bat` dosyasına çift tıkla.
3. Windows izin isterse **Evet** de. Oyun genelde Program Files içinde olduğu için dosya taşımak yönetici izni ister.
4. Uygulama oyunu Steam, Epic ya da Rockstar kurulumundan kendisi bulur. Bulamazsa **Gözat...** ile içinde `GTA5_Enhanced.exe` olan klasörü seç.

Windows dosyayı açmazsa: `.bat` dosyasına sağ tık → **Özellikler** → alttaki **Engellemeyi kaldır** kutusunu işaretle → **Tamam**.

## Kullanım

**Hikaye modu:** Oyunu kapat → **Türkçe AÇ** → oyunu başlat. Oyun ayarlarından altyazıları açmayı unutma.

**GTA Online'a geçerken:** Oyunu tamamen kapat → **Türkçe KAPAT** → durum kutusunda mavi **"TÜRKÇE KAPALI — Online'a hazır"** yazısını görünce oyunu başlat.

Oyun açıkken değişiklik yapılamaz, uygulama da buna izin vermez.

**Hızlı kısayollar** (pencere açmadan):

| Dosya | Ne yapar |
|---|---|
| `Online_Oncesi_KAPAT.bat` | Yamayı kapatır |
| `Hikaye_Icin_AC.bat` | Yamayı açar |

İlk seferde ana uygulamayı bir kez açıp oyun klasörünü seçmen yeterli, sonra hatırlanır.

## Ne taşınıyor?

**Türkçe KAPAT**, oyun ana klasöründeki şu öğeleri oyun klasörünün yanındaki bir depo klasörüne (`..._TurkceYama_Depo`) taşır:

| Öğe | Görevi |
|---|---|
| `xinput1_4.dll` | Enhanced'de yamayı yükleyen dosya |
| `dinput8.dll` | Legacy'de aynı işi yapan dosya |
| `dsound.dll` | OpenRPF'in yükleyicisi (varsa) |
| `args.txt` | BattlEye'ı kapatan ayar dosyası |
| `*.asi` | `OpenRPF.asi` gibi eklentiler |
| `mods` klasörü | Türkçe metinler (seçenek işaretliyse) |

Bu liste GTA TR'nin "GTA Online'a girerken" talimatlarıyla aynıdır. Uygulama bunu elle yapmak yerine tek tıkla yapar ve geri getirir. Türkçe kapalıyken depo klasörünü **silme**, yoksa yamayı yeniden kurman gerekir.

## Oyun güncellendikten sonra

Güncellemeden sonra Türkçe açıkken oyun çökerse yamayı yeniden kur (Universal Türkçe Yama'yı tekrar çalıştır). Sonra **Türkçe KAPAT**'a basarsan yeni dosyalar depoya gider. Eskiler silinmez, depodaki `_eski` klasörüne alınır.

## ⚠️ Online uyarısı

Rockstar, değiştirilmiş dosyalarla GTA Online'a girmeyi yasaklıyor. Online'a girmeden önce uygulamada mavi **"Online'a hazır"** yazısını gördüğünden emin ol. Uygulama, GTA TR'nin önerdiği yolu otomatikleştirir; ama Rockstar'ın kurallarını ve hile korumasını kontrol edemez, bu yüzden kesin bir "ban yemezsin" garantisi verilemez. Türkçe yamayla online'a girmenin yolunu anlatan paylaşımları uygulama.

## Gereksinimler

- Windows 10 veya 11
- Ekstra program gerekmez (Windows'taki PowerShell ile çalışır)

## Teşekkürler

Çeviriler **TechnoGame** ekibine, Türkçe yama kurulumu **GTA TR** ekibine aittir. Bu depo yalnızca kurulu yamayı açıp kapatan aracı içerir.

Bu proje Rockstar Games ile ilişkili değildir.

---

**Yapımcı: MSY**
