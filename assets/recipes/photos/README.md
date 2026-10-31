# 17 temsili ürün görseli

Aktif katalogdaki 17 tarif için yerleşik `image_gen` ile sıfırdan ayrı görseller
üretilmiştir. Bunlar fotogerçekçi **yapay zekâ temsilleridir**; gerçek çekilmiş
ürün fotoğrafı değildir. İnternet fotoğrafı, eski kolaj veya aynı görselin kopyaları
kullanılmamıştır.

Her görselin başlangıç istemi, gerçek malzemeleri ve yapım adımları
`assets/recipes/projects.json` kaydından alınmıştır. İstemler, yapılan iki düzeltme,
kaynak tarif kayıtları, dosya boyutları ve SHA-256 hash'leri
`generation_manifest.json` içindedir. Katalog ve animasyon verileri değiştirilmemiştir.

Tüm dosyalar 1024×1024 WebP'dir. Kaynak PNG'lere yalnızca istenen boyutlandırma ve
WebP biçim dönüşümü uygulanmıştır. Fiziksel yapı düzeltmeleri yine `image_gen` ile
yapılmıştır. Toplam dosya boyutu 1.597.720 bayttır.

| Dosya | Bayt |
|---|---:|
| project_01.webp | 114658 |
| project_03.webp | 130366 |
| project_15.webp | 82166 |
| project_19.webp | 75138 |
| project_26.webp | 59210 |
| project_38.webp | 125366 |
| project_39.webp | 69666 |
| project_40.webp | 101476 |
| project_41.webp | 67536 |
| project_42.webp | 70762 |
| project_43.webp | 56460 |
| project_44.webp | 38364 |
| project_45.webp | 244410 |
| project_46.webp | 78306 |
| project_47.webp | 60060 |
| project_48.webp | 175274 |
| project_49.webp | 48502 |

Eksik görsel yoktur. Silinmiş beş tarif için dosya veya kayıt eklenmemiştir.
Kart ve detay ekranları `assets/recipe_photos/manifest.json` üzerinden aynı dosyayı
yükler. Parça sayıları kırpılarak kaybolmasın diye AI görsellerinde
`BoxFit.contain` kullanılır; yükleme başarısızsa mevcut vektör önizleme gösterilir.
Çözme boyutu cihaz genişliğine göre sınırlanır ve Flutter'ın ortak görsel önbelleği kullanılır.

Görsel kontrolde: üç rulolu düzenleyici, on kapaklı XOX ve hafıza setleri, altı şişeli
bowling, iki rulolu dürbün, ters yoğurt kabı davulu, görünür su/şeritli PET saksı,
dört şeritli ızgara ve 12 gözünde dörder fasulye bulunan mangala doğrulanmıştır.
Ölçüler ve hacimler görsel temsildir; imalat ölçüsü için tarifin asıl metni geçerlidir.
