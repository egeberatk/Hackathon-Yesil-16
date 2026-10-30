# ReBorn AI analiz servisi

Flutter → `POST /analyze` (multipart `file`) → Gemini `gemini-3.1-flash-lite` → doğrulanmış JSON.
Gemini anahtarı yalnızca bu Python servisinde kullanılır. Flutter'a anahtar verilmez.

## Windows / PowerShell ile çalıştırma

Komutları depo kökünde çalıştırın:

```powershell
python -m venv backend/.venv
backend/.venv/Scripts/python.exe -m pip install -r backend/requirements-dev.txt
Copy-Item backend/.env.example backend/.env
```

`backend/.env` dosyasındaki `GEMINI_API_KEY=` alanını kendi anahtarınızla doldurun.
Dosya Git tarafından dışlanır ve Flutter asset'i değildir. Anahtarı komut satırına,
`--dart-define` içine, kaynak koda veya APK'ya koymayın. Ortam değişkeni dosyadan önce gelir.
`.env` değişikliğinden sonra servisi yeniden başlatın.

```powershell
backend/.venv/Scripts/python.exe -m uvicorn backend.app:app --host 0.0.0.0 --port 8000 --reload
```

Kontrol adresleri: `http://127.0.0.1:8000/health` ve `http://127.0.0.1:8000/docs`.
`/health` yalnızca backend'in çalıştığını gösterir; Gemini anahtarını/model erişimini doğrulamaz.

## Android fiziksel cihaz: USB + adb reverse

Flutter'ın okuduğu derleme değişkeni **BACKEND_URL**'dir; `API_BASE_URL` kullanılmaz.
Python `backend/.env` dosyası Flutter tarafından okunmaz. FastAPI çalışırken USB hata
ayıklaması açık ve bilgisayara izin vermiş fiziksel Android telefonu bağlayın.
Depo kökünde ikinci bir PowerShell terminalinde:

```powershell
& "$env:LOCALAPPDATA/Android/sdk/platform-tools/adb.exe" -d reverse tcp:8000 tcp:8000
& "$env:LOCALAPPDATA/Android/sdk/platform-tools/adb.exe" -d reverse --list
flutter run --debug --dart-define=BACKEND_URL=http://127.0.0.1:8000
```

`adb` PATH'teyse ilk komut `adb -d reverse tcp:8000 tcp:8000` olarak da çalışır.
Birden çok fiziksel cihaz varsa `adb devices -l` ile seri numarasını bulun ve
`-d` yerine `-s SERI_NUMARASI` kullanın; Flutter komutuna da `-d SERI_NUMARASI` ekleyin.
Bu yönlendirmeyle telefondaki `127.0.0.1:8000`, bilgisayardaki 8000 portuna ulaşır;
aynı Wi-Fi ağı veya bilgisayarın LAN IP'si gerekmez. USB bağlantısı/ADB yeniden
başlatılırsa yönlendirmeyi tekrar kurun. Gerekirse `adb -d reverse --remove tcp:8000`
ile yalnızca bu yönlendirmeyi kaldırabilirsiniz.

Debug sürümünde `BACKEND_URL` verilmezse varsayılan `http://127.0.0.1:8000` kullanılır;
USB yönlendirmesi yine gereklidir. Açıkça verilen `--dart-define` varsayılanı ezer.
Adres, derleme zamanı ayarıdır; değiştirdikten sonra uygulamayı durdurup doğru
komutla yeniden `flutter run` çalıştırın. Hot reload mevcut derleme ayarını değiştirmez.
Profile/release sürümlerinde yerel varsayılan yoktur ve HTTPS zorunludur.

## Wi-Fi ile alternatif bağlantı

Bilgisayarın Wi-Fi IPv4 adresini `ipconfig` ile bulun:

```powershell
flutter run --dart-define=BACKEND_URL=http://192.168.1.20:8000
```

Örnekteki IP'yi bilgisayarınızın gerçek yerel ağ IP'siyle değiştirin.
Telefon ve bilgisayar aynı Wi-Fi ağında olmalı. Telefonda `localhost` bilgisayarı
göstermez. Android emülatörde bilgisayara erişim için `http://10.0.2.2:8000` kullanılır.
Gerekirse Windows güvenlik duvarında yalnızca özel ağ için Python/8000 erişimine izin verin;
misafir ağları cihazlar arası erişimi engelleyebilir. Adres değişince uygulamayı yeniden başlatın.
Manuel ve örnek veri seçenekleri backend bağlantısı olmadan da çalışır.

## Akış ve sözleşme

Fotoğraf önizlemesinde **Analiz Et** seçilir; fotoğraf backend ve Gemini'ye gönderilir.
Analiz sırasında tekrar gönderim ve geri dönüş engellenir (en fazla 60 saniyelik istemci zaman aşımı).
Başarısızlıkta **Manuel malzeme seç** boş liste açar; **Örnek verilerle devam et** eski demo listesini açar.
Boş bir analiz sonucu demo malzemelerle doldurulmaz.

```json
{
  "materials": [{
    "name": "Plastik su şişesi",
    "material_id": "pet_bottle",
    "quantity": 2,
    "confidence": "uncertain",
    "requires_confirmation": true
  }]
}
```

Standart kimlikler: `pet_bottle`, `plastic_cap`, `cardboard_box`, `cardboard_roll`,
`clean_paper`, `glass_jar`, `metal_can`, `plastic_packaging`, `yogurt_container`, `egg_carton`.
`confidence`: `certain` veya `uncertain`. Adet 1–999, nesne adı 1–120 karakter;
bir yanıtta en fazla 50 satır bulunabilir.
Desteklenmeyen kimlikler adları korunarak `material_id: null`, `confidence: uncertain`,
`requires_confirmation: true` hâline getirilir; isimden tahmini kategori eşleştirilmez.
Belirsiz tespitler de her zaman onay gerektirir.

Onay ekranında nesne adı, tür ve adet düzenlenebilir. Onay gereken nesne düzenlenip
**Kaydet** ile onaylanmalıdır. Bilinmeyen nesne için kullanıcı uygun bir tür seçmeli
veya nesneyi silmelidir; uymayan bir kategori seçmek zorunda değildir.
Onay gerektiren satırlar çözülmeden proje adımına geçilmez.
Mevcut örnek tarifler korunur; yeni kategoriler için henüz tarif eklenmediğinden
bazı malzemeler yalnızca ek malzeme gerektiren örnek tarifleri gösterebilir.

Hatalar aynı biçimde döner:

```json
{"error":{"code":"analysis_timeout","message":"Analiz zaman aşımına uğradı. Manuel giriş kullanabilirsiniz."}}
```

Başlıca durum kodları: 400 boş dosya, 413 boyut aşımı, 415 geçersiz görsel,
422 eksik dosya alanı, 429 sağlayıcı limiti, 502 geçersiz/başarısız sağlayıcı yanıtı,
503 anahtar/model erişimi yapılandırması, 504 zaman aşımı.

JPEG/PNG/WebP kabul edilir; uzantı veya istemci MIME bilgisi yerine görsel içeriği
kontrol edilir. Sınır 8 MB ve 25 megapikseldir. Görsel yönü düzeltilip en fazla
1800×1800 boyutuna indirilir, metadata çıkarılır ve Gemini'ye JPEG olarak gönderilir.
HEIC desteklenmez; JPEG/PNG seçin. Backend fotoğrafları kalıcı olarak kaydetmez.
Gemini'nin veri işleme koşulları ayrıca geçerlidir.

## HTTP / üretim

Yerel HTTP yalnızca **Android debug** manifestinde açılır. Dart servisi de HTTP'yi
yalnızca debug modunda localhost/özel IPv4 adresleri için kabul eder. Ana manifest
cleartext bağlantıyı kapatır; profile ve release için HTTPS zorunludur:

```powershell
flutter build apk --release --dart-define=BACKEND_URL=https://api.example.com
```

Bu backend yerel geliştirme içindir. İnternete açmadan önce HTTPS reverse proxy,
kimlik doğrulama, kullanıcı başına kota/hız sınırı ve HTTP gövde boyutu sınırı ekleyin.
Uygulama düzeyindeki 8 MB kontrolü multipart ayrıştırmasından sonra çalışır;
reverse proxy sınırı yükleme aşamasını da korumalıdır.
Mobil istemci CORS gerektirmez; bu aşamada Flutter web için CORS yapılandırılmadı.

## Test

### Gemini hata teşhisi

Uvicorn başlangıcındaki `Gemini config` satırı `.env` dosyasının varlığını,
yükleme sonucunu, anahtarın yalnızca var/yok durumunu ve kullanılan modeli gösterir.
`key_source=process_environment` görülürse mevcut ortam değişkeni `.env` değerinden
önceliklidir. Değerlerin kendisi loglanmaz. `.env` değişikliğinden sonra servisi yeniden başlatın.

Başarısız çağrıda backend terminalindeki `Gemini failure` satırını inceleyin:
`http_status`, `provider_status` ve filtrelenmiş `message` gerçek sağlayıcı hatasını
gösterir. Başlıklar, anahtar, istek gövdesi, görsel, ham yanıt ve hata metadata'sı
loglanmaz. Mesaj içindeki kimlik bilgileri, URL'ler ve kaynak kimlikleri filtrelenir.
Bağlantı hataları `Gemini network failure`, zaman aşımı `Gemini timeout` olarak yazılır.
Uygulama SDK kullanmaz; `httpx` ile `v1beta/models/gemini-3.1-flash-lite:generateContent`
REST çağrısını kullanır.

Teşhis sırasında gerçek API ile `materials.maxItems: 50` alanının
`400 INVALID_ARGUMENT / Request contains an invalid argument.` sonucuna yol açtığı
doğrulandı. Mevcut tam istekten yalnızca bu alan çıkarılınca çağrı başarılı oldu.
Bu nedenle üretim şemasında `maxItems` gönderilmez; Pydantic 50 satır sınırını
yanıt alındıktan sonra uygulamaya devam eder. Bu bulgu model/API ile yapılan
kontrollü çağrıya aittir; tüm JSON Schema kısıtlarının desteklenmediği anlamına gelmez.

```powershell
backend/.venv/Scripts/python.exe -m pytest backend/tests -q
flutter analyze
flutter test
```

Testler sahte sağlayıcı yanıtları kullanır; gerçek Gemini çağrısı yapmaz ve anahtar gerektirmez.
Gerçek cihaz doğrulaması için servisi anahtarla başlatın, uygulamadan fotoğrafı analiz edin,
belirsiz satırları düzenleyip kaydedin ve proje adımına geçin. Sunucuyu durdurup manuel
girişin çalıştığını da kontrol edin.

Kaynaklar: [Gemini görsel girişi](https://ai.google.dev/gemini-api/docs/image-understanding),
[JSON şeması](https://ai.google.dev/gemini-api/docs/structured-output),
[model](https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-lite).
