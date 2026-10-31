# Yerel ürün görseli eşlemesi

`manifest.json`, tarif ID'sini görsel dosyasına eşler. Şu an aktif 17 tarifin
tamamında `assets/recipes/photos/project_XX.webp` dosyaları kullanılır. Bunlar
`image_gen` ile üretilmiş **temsili AI ürün görselleridir**, gerçek çekim değildir.

AI kaydı:
```json
{"kind":"ai_generated","asset":"assets/recipes/photos/project_01.webp","title":"Karton Rulo Masa Düzenleyici","generator":"image_gen","verified":true,"matches_recipe":true}
```

Dosya adı talep edilen tarif ID'siyle eşleşmelidir. Etkin kayıt ancak doğrulanmış
ve tarifin gerçek sonucuyla uyumluysa yüklenir. AI kayıtlarına gerçek fotoğraf
lisansı/atıf bilgisi verilmez; arayüzde "AI görseli" bilgisi açılır.

Önceki lisanslı gerçek fotoğraf kayıtları desteği korunur: yerel
`assets/recipe_photos/` dosyası, başlık, yazar, HTTPS kaynak adresi ve lisans
alanları gereklidir. Kabul edilen lisanslar CC0-1.0, CC-BY-4.0 ve CC-BY-SA-4.0;
resmî lisans adresiyle birlikte kaydedilir. Şu an bu türde etkin kayıt yoktur.

Eksik veya bozuk dosya, geçersiz manifest ya da desteklenmeyen kayıt mevcut
vektör çizimi gösterir. Uygulama ağdan fotoğraf indirmez. Görsel üretim istemleri
ve dosya hash'leri `assets/recipes/photos/generation_manifest.json` içindedir.
