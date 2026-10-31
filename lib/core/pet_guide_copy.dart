/// PET-only presentation copy. Catalogue records and motion sequences stay intact.
abstract final class PetGuideCopy {
  static const step1 =
      'Şişeyi yıka, kurut ve kaymayan bir altlıkta işaretli çizgiden ikiye ayır. Alt parça su kabın olacak.';
  static const step2 =
      'Kesik kenarları bantla kapat. Şişene uyan, önceden delik açılmış bir kapak kullan.';
  static const step3 =
      'Yaklaşık 25 cm pamuklu kumaş şeridini kapaktan geçir ve kapağı tak. Üst ucunu toprağa yaklaşık 10 cm yay, alt ucu su kabının dibine uzansın.';
  static const step4 =
      'Üst parçayı ters çevirip alt parçaya oturt. Şeridin üst ucunu toprağa yerleştir, bitkini ekle ve toprağı hafifçe sula.';
  static const step5 =
      'Alt kaba su ekle; kapak ve toprak suyun üzerinde kalsın. Pamuklu kumaş şeridinin alt ucu suya değsin.';
  static const step6 =
      'İlk günlerde toprağı ve su seviyesini her gün kontrol et; toprak sürekli ıslaksa suyu azalt. Alt kabı düzenli temizle, bitkini yakıcı güneşten koru.';
  static const steps = [step1, step2, step3, step4, step5, step6];
  static const cuttingWarning =
      'Kesme işlemi için yardım al. Alev veya ısıtılmış alet kullanma.';
  static const holeWarning =
      'Kapakta delik yoksa delme işlemi için yardım al. Sert plastiği zorlayarak veya ısıtarak delme.';
  static const warnings = <String?>[
    cuttingWarning,
    holeWarning,
    null,
    null,
    null,
    null,
  ];
  static const safetySummary = 'Kesme ve delme işlemleri için yardım al.';
  static const safety =
      '$safetySummary Plastiği ısıtma veya yakma; kalem gibi doğaçlama araçlarla delmeye çalışma. Saksını devrilmeyecek düz bir yerde tut. Alt kaptaki suyu içme. Bant açılırsa veya plastik çatlayıp kırılganlaşırsa saksıyı kullanmayı bırak.';
  static const description =
      'Pamuklu kumaş şeridi, alt kaptaki suyu toprağa taşır. Su seviyesini dışarıdan kontrol edebilirsin.';
  static const practicalUse =
      'Bu saksı sulama aralığını uzatmana yardımcı olur. Düzenli nem kontrolünü yine de sürdür.';
  static const capNote =
      'Şeridin geçebileceği hazır delikli bir kapak kullanabilirsin. Yeni delik açılması gerekiyorsa yardım al.';

  static String clothSupply(String original) => original.replaceFirst(
    'Kalın pamuk ip veya pamuk fitil',
    'Pamuklu kumaş şeridi',
  );
}
