# Resmî çevre rehberi maskotu

- `mascot_reference.jpeg`: Kullanıcının sağladığı resmî görsel. Kaynak dosya korunur; uygulama paketine eklenmez.
- `mascot_cutout.png`: Referanstan görsel düzenleme aracıyla hazırlanmış saydam arka planlı uyarlama. Yeni karakter tasarımı değildir; arka plan, masa ve eski konuşma balonu kaldırılmıştır. Üretken düzenleme nedeniyle kaynak fotoğrafla piksel düzeyinde aynı değildir.

## Görsel kontrol

Ters karton bardak baş, yeşil kapak ve iki yapraklı filiz, oval açık renk gözler, karton gövde ve yeşil yaprak amblemi korunmuştur. Kırmızı el solda, mavi el sağda; turuncu ayak solda, sarı ayak sağdadır. Beyaz akordeon kollar ve bacaklar görünür kalır. Görselde bağımsız bir yaprak karakteri, yeni ağız veya ek aksesuar yoktur.

## Hareket ve kullanım

`EcoMascotPainter` aynı saydam görseli baş, filiz, gövde, kollar ve bacak maskeleriyle katmanlara ayırır. `EcoMascotPose` altı hafif hareketi tanımlar; ayrı bir tarif animasyon motoru oluşturmaz. Bu sınırlı bir 2.5D uyarlamadır; tam 3D model veya farklı yönlere dönen karakter değildir.

Hareketler 1,8 saniyelik kısa tepkilerden ve 7 saniyelik dinlenmeden oluşur. Dokunma duraklatır/devam ettirir. Azaltılmış hareket tercihinde statik poz kullanılır; gizli ekranda durur; ekran kaldırılınca zamanlayıcı ve controller temizlenir. Tek görsel çözülerek uygulama boyunca paylaşılır.

Krem konuşma balonu ekranın normal akışındadır; kamera, onay ve tarif düğmelerinin üzerinde yüzen bir katman değildir. Türkçe mesajlar `EcoGuideMessages` içinden ekrana göre seçilir. Malzeme tespiti, eşleştirme ve tarif verisi bu bileşene bağlı değildir.

## Doğrulama ve önizleme

`flutter test test/eco_mascot_test.dart --dart-define=MASCOT_PREVIEW=true`

Gerçek Flutter görüntüleri `.dart_tool/mascot/previews/` altına yazılır ve Git tarafından takip edilmez. `home.png`, `materials.png`, `completed.png` ekran görüntüleridir; diğer altı görüntü hareket pozlarını gösterir. `frames/` selamlama hareketinin kareleridir.

Referansın kullanıcı tarafından sağlanmış olması bağımsız bir stok görsel lisansı anlamına gelmez; yayımlama hakkı kaynak görselin haklarına bağlıdır.
