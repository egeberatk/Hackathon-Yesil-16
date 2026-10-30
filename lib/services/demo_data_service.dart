import '../models/material_item.dart';
import '../models/upcycling_project.dart';

class DemoDataService {
  // Fotoğraf analizi yapılmaz. Her seçim için bağımsız Örnek liste döner.
  static List<MaterialItem> materials() => [
    MaterialItem(type: WasteType.glass, quantity: 2),
    MaterialItem(type: WasteType.plastic),
  ];
  static const projects = [
    UpcyclingProject(
      title: 'Kavanozdan mini bahçe',
      description: 'Boş bir kavanoza yeşil bir başlangıç ver.',
      symbol: '🌱',
      minutes: 20,
      requirements: {WasteType.glass: 1},
      extras: [
        'Küçük çakıl taşları',
        'Toprak',
        'Küçük bir bitki',
        'Bahçe eldiveni',
      ],
      steps: [
        'Çatlağı olmayan kavanozu yıka ve iyice kurula.',
        'Tabana ince bir çakıl katmanı ekle.',
        'Toprağı doldur ve bitkiyi dikkatlice yerleştir.',
        'Az miktarda sula. Drenaj deliği olmadığı için fazla su vermeden aydınlık bir yerde tut.',
      ],
    ),
    UpcyclingProject(
      title: 'Şişeden masa düzenleyici',
      description: 'Kalemlerine yer aç, plastiğe ikinci şans ver.',
      symbol: '✏️',
      minutes: 15,
      requirements: {WasteType.plastic: 1},
      extras: ['Makas', 'Kenarları kapatmak için kalın bant', 'Su bazlı boya'],
      steps: [
        'Şişeyi yıka, kurut ve kesim çizgisini işaretle.',
        'Bir yetişkin yardımıyla şişenin alt kısmını dikkatlice kes.',
        'Keskin kenarların tamamını kalın bantla kapat.',
        'Dışını boya, kurumasını bekle ve kalemlerini yerleştir.',
      ],
    ),
    UpcyclingProject(
      title: 'Kartondan çekmece bölücü',
      description: 'Küçük eşyalar için büyük bir düzen fikri.',
      symbol: '📦',
      minutes: 25,
      requirements: {WasteType.cardboard: 2},
      extras: ['Cetvel', 'Makas', 'Kağıt bant'],
      steps: [
        'Çekmecenin iç ölçülerini al.',
        'İki kartonu ölçülere uygun şeritler hâlinde kes.',
        'Şeritlerin ortasına yarıya kadar birer yuva aç.',
        'Yuvaları birbirine geçir, bantla sabitle ve çekmeceye yerleştir.',
      ],
    ),
    UpcyclingProject(
      title: 'Metal kutudan saksı kılıfı',
      description: 'Sade bir kutuyu renkli bir köşeye dönüştür.',
      symbol: '🌼',
      minutes: 20,
      requirements: {WasteType.metal: 1},
      extras: ['Kalın koruyucu bant', 'Su bazlı boya', 'Küçük saksılı bitki'],
      steps: [
        'Paslı veya keskin hasarlı kutuları kullanma. Kutuyu temizleyip kurut.',
        'Ağız kenarını koruyucu bantla tamamen kapat.',
        'Dış yüzeyi boya ve kurumaya bırak.',
        'Bitkiyi kendi drenajlı saksısıyla kutunun içine yerleştir. Sularken iç saksıyı çıkar.',
      ],
    ),
  ];
  static bool canMake(UpcyclingProject project, List<MaterialItem> items) =>
      project.requirements.entries.every(
        (entry) =>
            items
                .where((item) => item.type == entry.key)
                .fold<int>(0, (sum, item) => sum + item.quantity) >=
            entry.value,
      );
}
