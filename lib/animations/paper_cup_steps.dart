part of 'workshop_steps.dart';

abstract final class _PaperCupSteps {
  static final _p = WorkshopSteps._p,
      _step = WorkshopSteps._step,
      _at = WorkshopSteps._at;
  static const _full = WorkshopSteps._full;
  static final steps = <WorkshopStep>[
    _step(
      'Temiz, kuru ve ezilmemiş bir kâğıt bardak seç. Yağlı, ıslak veya küflü bardak kullanma.',
      [_p('cup', WorkshopObject.paperCup, 160, 205, scale: 1.35)],
      warning: 'Yumuşamış veya yırtılmış bardak kullanma.',
    ),
    _step(
      'İstersen dışına küçük bir etiket ekle veya kalemle kullanım amacını yaz. İçini açık bırak.',
      [
        _p(
          'cup',
          WorkshopObject.paperCup,
          160,
          205,
          scale: 1.35,
          label: 'label',
        ),
      ],
      initial: {'cup': const MotionPose(amount: .01)},
      changes: [
        {'cup': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'Bardağı düz, kuru bir masaya dik koy. Hafif kâğıt kırpıntılarını veya silgi artıklarını içine at.',
      [
        _p(
          'cup',
          WorkshopObject.paperCup,
          160,
          215,
          scale: 1.35,
          label: 'label',
        ),
        for (var i = 0; i < 3; i++)
          _p(
            'scrap$i',
            WorkshopObject.receipt,
            142 + i * 18,
            202 - i % 2 * 7,
            scale: .32,
            angle: (i - 1) * .3,
          ),
        _p(
          'front',
          WorkshopObject.paperCup,
          160,
          215,
          scale: 1.35,
          label: 'front',
        ),
      ],
      initial: {for (var i = 0; i < 3; i++) 'scrap$i': _at(0, -105)},
      changes: [
        for (var i = 0; i < 3; i++) {'scrap$i': _full},
      ],
      warning: 'Sıvı, sıcak atık, pil, cam veya keskin parça koyma.',
    ),
    _step(
      'Dolmadan boşalt ve kuru tut. Yumuşamış, yırtılmış veya kirlenmiş bardağı değiştir.',
      [
        _p(
          'cup',
          WorkshopObject.paperCup,
          160,
          205,
          scale: 1.35,
          label: 'label',
        ),
      ],
      warning:
          'Yiyecek ve içecek için yeniden kullanma; devrilmeyecek yerde tut.',
    ),
  ];
}
