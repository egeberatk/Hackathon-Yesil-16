import '../animations/eco_mascot_motion.dart';

enum EcoGuideScene {
  home,
  photo,
  analyzing,
  analysisError,
  materials,
  noMaterials,
  recommendations,
  completed,
  caution,
}

abstract final class EcoGuideMessages {
  static String text(EcoGuideScene scene) => switch (scene) {
    EcoGuideScene.home =>
      'Önce azalt, sonra yeniden kullan. Birlikte yeni bir görev bulalım!',
    EcoGuideScene.photo =>
      'Yeniden kullanım için temiz ve sağlam malzemeleri seç.',
    EcoGuideScene.analyzing =>
      'Malzemelerine bakıyorum. Sonuçları birlikte kontrol edeceğiz.',
    EcoGuideScene.analysisError => 'Analiz tamamlanamadı. Yeniden deneyebilir veya malzemelerini kendin seçebilirsin.',
    EcoGuideScene.materials =>
      'Türleri ve adetleri kontrol et. Onayladıklarınla ilerleyelim!',
    EcoGuideScene.noMaterials => 'Her nesne yeniden kullanıma uygun olmayabilir. Yerel toplama seçeneklerini kontrol et.',
    EcoGuideScene.recommendations =>
      'Harika! Elindeki malzemelere yeni bir görev seçelim.',
    EcoGuideScene.completed => 'Kalan malzemelerine de yeni bir şans ver! Kullanmayacakların için yerel kurallara uygun geri dönüşüm veya özel toplama noktalarını kullan.',
    EcoGuideScene.caution => 'Keskin, kirli veya hasarlı parçaları kullanma. Güvenlik notlarını kontrol et.',
  };

  static EcoMascotMood mood(EcoGuideScene scene) => switch (scene) {
    EcoGuideScene.home => EcoMascotMood.greeting,
    EcoGuideScene.photo => EcoMascotMood.idle,
    EcoGuideScene.analyzing => EcoMascotMood.thinking,
    EcoGuideScene.materials ||
    EcoGuideScene.recommendations => EcoMascotMood.explaining,
    EcoGuideScene.noMaterials ||
    EcoGuideScene.caution ||
    EcoGuideScene.analysisError => EcoMascotMood.warning,
    EcoGuideScene.completed => EcoMascotMood.celebrating,
  };
}
