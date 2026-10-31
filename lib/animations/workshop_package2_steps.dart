part of 'workshop_steps.dart';

/// Data and compositions only. Playback remains in the existing player/engine.
abstract final class _Package2Steps {
  static final _p = WorkshopSteps._p;
  static final _step = WorkshopSteps._step;
  static final _at = WorkshopSteps._at;
  static const _full = WorkshopSteps._full;
  static const _folded = MotionPose(amount: 2);
  static final recipes = <String, List<WorkshopStep>>{
    'project_19': _memoryGame(),
    'project_26': _binocularsSteps(),
    'project_48': _mangala(),
    'project_44': _bank(),
  };

  static Offset _tokenPosition(int i) =>
      Offset(60 + i % 5 * 50, 125 + i ~/ 5 * 85);
  static List<WorkshopPart> _coloredDots({bool color = false}) => [
    for (var i = 0; i < 10; i++)
      _p(
        'dot$i',
        WorkshopObject.paperDot,
        _tokenPosition(i).dx,
        _tokenPosition(i).dy,
        scale: .9,
        label: color ? '${i % 5}' : 'plain',
      ),
  ];
  static List<WorkshopPart> _memoryTokens() => [
    for (var i = 0; i < 10; i++)
      _p(
        'cap$i',
        WorkshopObject.flipCap,
        _tokenPosition(i).dx,
        _tokenPosition(i).dy,
        scale: .85,
        label: '${i % 5}',
      ),
  ];
  static List<WorkshopStep> _memoryGame() => [
    _step(
      'Kâğıttan kapakların içine sığacak on küçük daire ayır.',
      _coloredDots(),
      initial: {for (var i = 0; i < 10; i++) 'dot$i': const MotionPose()},
      changes: [
        for (var i = 0; i < 5; i++) {'dot$i': _full, 'dot${i + 5}': _full},
      ],
      kind: MotionKind.split,
      warning:
          'Kesme işlemi için yardım al. Küçük parçaları çocuklardan uzak tut.',
    ),
    _step(
      'Daireleri beş farklı renge boya. Her renkten iki tane olsun.',
      _coloredDots(color: true),
      initial: {
        for (var i = 0; i < 10; i++) 'dot$i': const MotionPose(amount: .01),
      },
      changes: [
        for (var i = 0; i < 5; i++) {'dot$i': _full, 'dot${i + 5}': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'Renkli kâğıtları kapakların içlerine bantla sabitle.',
      [
        for (var i = 0; i < 10; i++)
          _p(
            'cap$i',
            WorkshopObject.cap,
            _tokenPosition(i).dx,
            _tokenPosition(i).dy,
            scale: .85,
          ),
        ..._coloredDots(color: true),
        for (var i = 0; i < 10; i++)
          _p(
            'tape$i',
            WorkshopObject.tape,
            _tokenPosition(i).dx,
            _tokenPosition(i).dy + 14,
            scale: .32,
          ),
      ],
      initial: {
        for (var i = 0; i < 10; i++) ...{
          'dot$i': _at(0, -45),
          'tape$i': const MotionPose(),
        },
      },
      changes: [
        for (var i = 0; i < 5; i++)
          {
            'dot$i': _full,
            'dot${i + 5}': _full,
            'tape$i': _full,
            'tape${i + 5}': _full,
          },
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'Kapakları renkleri görünmeyecek şekilde ters çevirip masaya diz.',
      _memoryTokens(),
      changes: [
        for (var i = 0; i < 5; i++) {'cap$i': _folded, 'cap${i + 5}': _folded},
      ],
      kind: MotionKind.rotate,
    ),
    _step(
      'Sırayla iki kapak açarak aynı renkleri bulmaya çalış.',
      _memoryTokens(),
      initial: {for (var i = 0; i < 10; i++) 'cap$i': _folded},
      changes: [
        {'cap0': _full},
        {'cap5': _full},
      ],
      kind: MotionKind.rotate,
      warning: 'Kapaklar yutma tehlikesi taşır. Küçük çocukları kapaklarla yalnız bırakma.',
    ),
  ];

  static List<WorkshopPart> _binoculars({
    bool wrap = false,
    bool decorate = false,
  }) => [
    _p('roll0', WorkshopObject.roll, 130, 180, scale: 1.1),
    _p('roll1', WorkshopObject.roll, 190, 180, scale: 1.1),
    _p('tape0', WorkshopObject.tape, 160, 159, scale: .8),
    _p('tape1', WorkshopObject.tape, 160, 213, scale: .8),
    if (wrap)
      _p(
        'wrap',
        WorkshopObject.binocularWrap,
        160,
        181,
        label: decorate ? 'pattern' : '',
      ),
  ];
  static List<WorkshopStep> _binocularsSteps() => [
    _step(
      'İki ruloyu yan yana getir ve birbirine bantla.',
      _binoculars(),
      initial: {
        'roll0': _at(-65, 0),
        'roll1': _at(65, 0),
        'tape0': const MotionPose(),
        'tape1': const MotionPose(),
      },
      changes: [
        {'roll0': _full, 'roll1': _full},
        {'tape0': _full, 'tape1': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'Kâğıdı ruloların çevresine dola ve bantla sabitle.',
      _binoculars(wrap: true),
      initial: {'wrap': const MotionPose(amount: .01)},
      changes: [
        {'wrap': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'İstersen dış kâğıda sevdiğin desenleri çiz.',
      _binoculars(wrap: true, decorate: true),
      initial: {'wrap': const MotionPose(amount: .01)},
      changes: [
        {'wrap': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'Dürbünü gözlerine tutup çevreni keşfet. Kullanırken yerinde dur.',
      _binoculars(wrap: true, decorate: true),
      warning: 'Yürürken veya merdivenlerde kullanma; görüş alanın daralır ve düşebilirsin.',
    ),
  ];

  static Offset _well(int i) => Offset(75 + i % 6 * 34, 150 + i ~/ 6 * 55);
  static List<WorkshopPart> _mangalaBoard({bool stones = false}) => [
    _p('tray', WorkshopObject.eggTray, 160, 180),
    _p('treasure0', WorkshopObject.cup, 24, 180, scale: .34),
    _p('treasure1', WorkshopObject.cup, 296, 180, scale: .34),
    if (stones)
      for (var i = 0; i < 48; i++)
        _p(
          'stone$i',
          WorkshopObject.stone,
          _well(i ~/ 4).dx + (i % 2 == 0 ? -5 : 5),
          _well(i ~/ 4).dy + (i % 4 < 2 ? -6 : 6),
          scale: .85,
        ),
  ];
  static List<WorkshopStep> _mangala() => [
    _step(
      'Temiz, kuru ve sağlam bir koli seç. İki yoğurt kabını yıkayıp kurula.',
      _mangalaBoard(),
      warning: 'Kirli, nemli veya küflü koliyi kullanma; yıkayarak kurtarmaya çalışma.',
    ),
    _step(
      'Koliyi düz zemine aç. Altışarlı iki sıranın kısa uçlarına birer hazine kabı koy.',
      _mangalaBoard(),
      initial: {'treasure0': _at(0, -85), 'treasure1': _at(0, -85)},
      changes: [
        {'treasure0': _full},
        {'treasure1': _full},
      ],
    ),
    _step(
      'On iki gözün her birine dört taş koy: toplam 48 taş. Her oyuncunun hazinesi sağında olsun.',
      _mangalaBoard(stones: true),
      initial: {for (var i = 0; i < 48; i++) 'stone$i': const MotionPose()},
      changes: [
        for (var well = 0; well < 12; well++)
          {for (var n = 0; n < 4; n++) 'stone${well * 4 + n}': _full},
      ],
      warning: 'Küçük taşlar ve fasulyeler üç yaş altına uygun değildir. Ağza alma; çocukları gözetimsiz bırakma.',
    ),
    _step(
      'Başlamadan aynı kural setini seçin. Taşları bu kurallara göre sırayla dağıtıp hazinelerinizde biriktirin.',
      [
        ..._mangalaBoard(stones: true),
        _p(
          'rules',
          WorkshopObject.sheet,
          160,
          82,
          scale: .55,
          label: 'writing',
        ),
      ],
      // A neutral distribution illustration, not an invented scoring/rule set.
      changes: [
        {'stone0': _at(39, 6)},
        {'stone1': _at(63, 6)},
      ],
    ),
    _step(
      'Hazinelerdeki taşları sayın, sonra tüm taşları kaplarda toplayın. Koliyi kuru sakla ve ellerini yıka.',
      _mangalaBoard(stones: true),
      changes: [
        for (var well = 0; well < 12; well++)
          {
            for (var n = 0; n < 4; n++)
              'stone${well * 4 + n}': _at(
                (well < 6 ? 24 : 296) -
                    (_well(well).dx + (n % 2 == 0 ? -5 : 5)) +
                    (n % 2 == 0 ? -4 : 4),
                180 - (_well(well).dy + (n < 2 ? -6 : 6)) + (n < 2 ? -4 : 4),
              ),
          },
      ],
      warning:
          'Oyun için ayırdığın fasulyeleri yeme. Oyun sonunda ellerini yıka.',
    ),
  ];

  static List<WorkshopPart> _bankBody({
    bool closed = false,
    bool slot = false,
    bool protected = false,
    bool coin = false,
    bool guide = false,
  }) => [
    if (coin) _p('coin', WorkshopObject.coin, 160, 60, scale: .8),
    _p('cup', WorkshopObject.cup, 160, 225, scale: 1.35),
    _p('lid', WorkshopObject.lid, 160, closed ? 172 : 100, scale: 1.35),
    if (slot)
      _p(
        'slot',
        WorkshopObject.slot,
        160,
        closed ? 172 : 100,
        scale: 1.35,
        label: protected
            ? 'protected'
            : guide
            ? 'guide'
            : '',
      ),
  ];
  static List<WorkshopStep> _bank() => [
    _step(
      'Kabı ve kapağını yıka, tamamen kurut. Kapağın sıkıca kapanıp açıldığını kontrol et.',
      _bankBody(closed: true),
      changes: [
        {'lid': _at(0, -60)},
        {'lid': _full},
      ],
      warning: 'Paraları ve küçük parçaları üç yaş altı çocuklardan uzak tut.',
    ),
    _step(
      'Kapağı çıkar. En büyük parandan biraz uzun, yaklaşık 3,5 cm × 4 mm bir yuva işaretle.',
      _bankBody(slot: true, guide: true),
      initial: {'slot': const MotionPose()},
      changes: [
        {'slot': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'İşaretli yuvayı yardım alarak hazırla. Kapak sabit bir altlığın üzerinde dursun.',
      [
        _p('mat', WorkshopObject.sheet, 160, 100, scale: 2.1, label: 'mat'),
        ..._bankBody(slot: true),
      ],
      initial: {'slot': const MotionPose(amount: .02)},
      changes: [
        {'slot': _full},
      ],
      kind: MotionKind.assemble,
      warning: 'Kesme ve delme işlemleri için yardım al. Kapağı elde tutarak kesme; alev veya ısıtılmış alet kullanma.',
    ),
    _step(
      'Yuvanın kenarlarını ince bantla koru. Paranın zorlanmadan geçtiğini kontrol et.',
      _bankBody(slot: true, protected: true, coin: true),
      changes: [
        {'coin': _at(0, 145)},
      ],
      warning: 'Keskin kenar kalmasın; bant para yolunu kapatmasın. Parayı zorlayarak itme.',
    ),
    _step(
      'Kapağı kapat; istersen kabı etiketle. Paranı almak için kabı kesmek yerine kapağını aç.',
      _bankBody(closed: true, slot: true, protected: true),
      initial: {'lid': _at(0, -72), 'slot': _at(0, -72)},
      changes: [
        {'lid': _full, 'slot': _full},
      ],
    ),
    _step(
      'Kumbara ağırlaşmadan boşalt. Taban esnerse veya bant, kapak ya da plastik hasar görürse kullanmayı bırak.',
      _bankBody(closed: true, slot: true, protected: true),
      warning: 'Kumbara kilitli veya güvenli bir para saklama kutusu değildir.',
    ),
  ];
}
