# Yapım animasyonları

Bu prototip yalnızca `project_40` için etkin. Katalog JSON'u ve tarifin altı adımının metni değişmez. `PetPlanterSteps` ayrı sunum metadatasıdır; adım sayısı desteklenmiyorsa `RecipeStepViewer` metin görünümünü kullanır. Özel `mediaBuilder` verilmesi mevcut genişletme noktasını korur; `null` döndürerek çizimi kapatmak mümkündür.

## Motor

`MotionSequence`, başlangıç pozları ve ardışık `MotionClip` kayıtlarından oluşur. Her klip hedef kimlikleri için `MotionPose` belirtir: konum (`offset`), radyan cinsinden açı (`angle`), doluluk/görünürlük (`amount`). Tamamlanan pozlar sonraki klibe taşınır. `split` birden fazla parçayı ayırabilir; `rotate`, `insert`, `pour` ve `assemble` aynı zaman çizelgesinde birleştirilebilir. Bu katman tarif, PET şişe veya malzeme kimliği bilmez.

`RecipeMotionPlayer` tek `AnimationController` ile başta/sonda beklemeli döngü, duraklatma/devam ve erişilebilirliği yönetir. Her adımın anahtarı ayrıdır; geçişte eski oynatıcı dispose edilir. `disableAnimations` veya `accessibleNavigation` açıkken son durum sabit çizilir, ticker çalışmaz. Çizim adaptörü oluşturulamazsa bilgilendirme görünür; asıl adım metni bağımsızdır. Harici medya veya yeni paket kullanılmaz.

`MotionTransform` widget dönüşümünü, `transformMotionPoint` ise bağlantı çizgilerinde aynı dönüşümü sağlar. Çizim adaptörleri `MotionFrame` alır; başka bir çizim için motoru değiştirmek gerekmez. Hareketli `CustomPaint` katmanlarında `willChange` önbelleğe eski/eksik kare alınmasını önler.

## PET saksı: gerçek adım sırası

1. Makas sağdan gelir, kesme çizgisinde açılıp kapanarak ilerler. Kesim bitip makas çekilince üst parça ayrılır; alt hazne sabit kalır.
2. Kesik kenarlara koruma ve çıkarılmış kapakta delik hazırlığı. Yetişkin/güvenlik uyarısı görünür.
3. Peçete veya pamuklu kumaş şeridini kapaktan geçirme ve kapağı takma.
4. Ayrılmış üst parçayı 180° çevirme, alt parçaya yerleştirme; toprak, bitki ve ilk hafif sulama.
5. Üst parçayı hafif kaldırıp açık hazneye su doldurma, yeniden oturtma.
6. Su seviyesini kontrol etmek için kaldırma/yeniden oturtma. Bakımın tamamı katalog metninde kalır.

Çizim 320 × 330 birimlik ortak koordinat sisteminde ölçeklenir. Kesme düzlemi `(160,180)`, üst parçanın dönme merkezi `(160,125)` konumundadır; alt parça yer değiştirmez. Ayrılan parça kendi ortasında, haznenin üstünde döner; yan duvardan geçmeden ağızdan aşağı indirilir. Kurulu üst kenar `y=140`, kapağın altı `y=260`, su yüzeyi `y=268`, şeridin ucu `y=282`, haznenin tabanı `y=290` konumundadır. Ekranda aşağı doğru artan y nedeniyle kapak suyun üstünde, şeridin ucu suyun içindedir. Bunlar ölçülü imalat talimatı değil, tarifin okunabilir kesit çizimidir.

`pet_planter_parts.dart` içindeki ayrı `CustomPainter` bileşenleri makas, üst parça, hazne, kapak, şerit, toprak, bitki ve suyu çizer. Şekiller referans rehberdeki düz renkli, ince konturlu 2D vektör dilini kullanır: yarı saydam açık mavi PET, sade kahverengi toprak ve yeşil yapraklar. Gölge, parlama ve doku yoktur. Şerit, kapak deliğinden bütün olarak hareket eder; bitki de toprak doldurulduktan sonra ayrı bir parça olarak yerleşir. Hareket parametreleri mevcut motora verilen metadatada kalır; motor veya oynatıcı değişmez.

## Doğrulama ve yerel kayıt

```powershell
flutter analyze
flutter test
backend/.venv/Scripts/python.exe -m pytest backend/tests -q
flutter test test/stage4_test.dart --dart-define=STAGE4_PREVIEW=true
```

Son komut gerçek Flutter çizimlerinden 20 fps PNG karelerini `.dart_tool/design-preview/pet-vector-frames/` içine, altı adım önizlemesini aynı üst dizine `pet-vector-step-*.png` olarak yazar. `pet-vector-recording.json` güncel kare sayısını içerir. Dosyalar Git tarafından yok sayılan geliştirme çıktılarıdır. FFmpeg mevcutsa MP4 üretimi:

```powershell
$petRecording = Get-Content .dart_tool/design-preview/pet-vector-recording.json | ConvertFrom-Json
ffmpeg -y -framerate $petRecording.fps -i .dart_tool/design-preview/pet-vector-frames/frame%04d.png -frames:v $petRecording.frame_count -vf 'pad=ceil(iw/2)*2:ceil(ih/2)*2' -c:v libx264 -pix_fmt yuv420p -movflags +faststart .dart_tool/design-preview/pet-planter-vector.mp4
```
