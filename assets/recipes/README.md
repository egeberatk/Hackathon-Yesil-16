# Onaylı tarif kütüphanesi

`projects.json` onaylı 17 kimliği ve 17 aktif tarif kaydını içerir.
Katalogdan çıkarılması istenen beş kayıt ve bu kayıtların onay kimlikleri silinmiştir.
Kalan tariflerin malzemeleri, miktarları ve adımları korunmuştur.
Tarif miktarları ve adımları bu dosyadan yüklenir.
Eski mock tarifler uygulamadan kaldırıldı. Test dosyalarındaki sentetik veriler asset'e eklenmez.

Kütüphanedeki 17 tarif:

| Kimlik | Tarif |
|---|---|
| project_01 | Karton Rulo Masa Düzenleyici |
| project_03 | Geri Dönüşüm XOX Oyunu |
| project_15 | Şişe Bowling Oyunu |
| project_19 | Renk Eşleştirme Hafıza Oyunu |
| project_26 | Karton Dürbün Oyuncak |
| project_38 | Örgü İpi Kasesi |
| project_39 | Ritim Davulu |
| project_40 | Kendini Sulayan PET Saksı |
| project_41 | PET Şişeden Poşet Ağzı Kapatıcı |
| project_42 | PET Şişeden Huni |
| project_43 | Yoğurt Kabından Asma Soğan ve Sarımsak Sepeti |
| project_44 | Yoğurt Kabından Kumbara |
| project_45 | Karton Kutudan Kedi Tırmalama Bloğu |
| project_46 | Karton Çekmece İçi Izgara Ayraç |
| project_47 | Cam Kavanozdan Meyve Sineği Tuzağı |
| project_48 | Yumurta Kolisinden Mangala Oyunu |
| project_49 | Kâğıt Bardaktan Mini Masa Çöp Kutusu |

## Asset sözleşmesi

Üst düzey nesne `approved_ids` (metin listesi) ve `projects` (tarif listesi)
alanlarından oluşur. Yalnızca `approved_ids` içindeki kayıtlar yüklenir.
Onaylı bir kaydı `projects` listesine eklemek yeterlidir;
Dart kodu veya pubspec değişikliği gerekmez. Gelecekte yeni bir tarif onaylanırsa
kimliği de aynı JSON'un `approved_ids` listesine eklenir. Asset değişikliğinden
sonra uygulamayı yeniden başlatın/derleyin.

Tarif kaydında beklenen alanlar:

| Alan | Tür |
|---|---|
| id, name, description | Boş olmayan metin |
| required_materials | Boş olmayan nesne listesi: material_id (metin), name (metin), quantity (pozitif tam sayı) |
| required_supplies, optional_supplies | Metin listesi; boş olabilir |
| category, difficulty | Boş olmayan Türkçe metin; ekranda olduğu gibi gösterilir |
| estimated_minutes | Pozitif tam sayı |
| steps | Boş olmayan sıralı metin listesi |
| practical_use | Boş olmayan metin |
| safety_warning, image_prompt | Metin; boş olabilir, alan bulunmalıdır |

JSON farklı iç içe yapılar kullanacaksa veri kaybı olmadan
parser uyarlanmalı; eksik içerik tahmin edilmemelidir. `image_prompt` modelde
saklanır ve görsel üretiminde başlangıç noktasıdır; görsel adresi olarak kullanılmaz.
Aktif 17 tarifin AI temsili ürün görselleri `photos/` altında, tarif kimliklerine
göre saklanır. Kart ve detay ekranları aynı yerel eşlemeyi ve vektör fallback'i kullanır.

Malzeme kimlikleri Gemini/onay ekranıyla aynı olmalıdır. Bilinen kimlikler:
`pet_bottle`, `plastic_cap`, `cardboard_box`, `cardboard_roll`, `clean_paper`,
`glass_jar`, `metal_can`, `plastic_packaging`, `yogurt_container`, `egg_carton`, `paper_cup`. Yeni bir içerik kimliği kendiliğinden
başka kategoriye eşlenmez; envanterde yoksa eksik olarak gösterilir.

Yardımcı malzemeler yalnızca detayda gösterilir. Eşleştirme her tarif için bağımsızdır;
bir tarif diğerinin envanterini tüketmez. Onaysız/unknown satırlar sayılmaz. Aynı
kimliğe ait envanter ve gereksinim satırları toplanır. Sıra: eksik tür sayısı,
toplam eksik adet, eşitlikte tarif kimliği; böylece tam eşleşmeler önce gelir.

Yalnızca tüm gerekli atık malzemeleri karşılanan kayıtlar **Yapabilirsin** grubuna
girer. Diğerleri mevcut arayüzde ayrı eksik malzeme bölümünde, gereken adetlerle
gösterilir; uygun tarif olarak işaretlenmez. Yardımcı malzemelerin temini ve kapak,
kap boyutu gibi nitelikler tarifte ayrıca kontrol edilir. `egg_carton` karton koli
içindir; plastik yumurta ambalajı otomatik olarak bu kategoriye eşlenmez.
`paper_cup` temiz, kuru ve sağlam kâğıt/karton içecek bardağı içindir;
plastik bardak, cam bardak, bardak kılıfı ve karton ruloyla karıştırılmaz.
Gemini algılamasından sonra ayrı aday filtresi, elektronik eşyaları ve katalogda
karşılığı olmayan nesneleri önerilerden çıkarır. Kullanıcı onayı yine gereklidir.

## İçerik ve güvenlik notları

PET kesimleri yetişkin tarafından soğuk aletlerle yapılır; huni tarifinde alev veya
sıcak metalle şekillendirme yoktur. Kedi tırmalama bloğu sıkıştırılarak birleştirilir;
açıkta bant, tel, ip, zımba veya yapıştırıcı bırakılmaz. Kedi materyali yutuyorsa
kullanım durdurulur. Karton üzerindeki bant ve zımbaları çıkarma yaklaşımı
[Small Door Veterinary rehberindeki](https://assets.ctfassets.net/82d3r48zq721/39NvV0Tnl6xJvtpWvqwPAc/3c04388da0bba29be9860b8b91d73ca8/Small-Door-Veterinary-Cat-Parenting-101.pdf)
karton oyuncak önerileriyle uyumludur.

Meyve sineği tuzağındaki sirke/yüzey gerilimi yaklaşımı
[Maryland Extension](https://www.extension.umd.edu/resource/fruit-flies), kağıt huni
yaklaşımı [McGill University](https://www.mcgill.ca/oss/article/did-you-know-you-asked/how-beat-fruit-fly-infestation)
bilgileri temel alınarak hazırlanmıştır. Tuzak, üreme kaynağını temizlemenin yerine geçmez.
Soğan/sarımsak sepetindeki hayvan erişimi uyarısı
[Cats Protection](https://www.cats.org.uk/help-and-advice/caring-for-your-cat/home-and-environment/poisoning)
bilgisiyle desteklenir. Soğanların kuru ve havadar saklanması
[UMN Extension](https://extension.umn.edu/garden-and-home/yard-and-garden/gardening-in-minnesota/growing-onions)
önerileriyle uyumludur. Tariflerin bu ölçülerde fiziksel dayanıklılık testi yapılmamıştır;
boyut ve yük kontrolleri adımlarda kullanıcıya belirtilir.
