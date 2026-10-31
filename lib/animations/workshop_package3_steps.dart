part of 'workshop_steps.dart';

/// Final package: catalogue-ordered compositions, using the shared sequencer.
abstract final class _Package3Steps {
  static final _p = WorkshopSteps._p,
      _step = WorkshopSteps._step,
      _at = WorkshopSteps._at;
  static const _full = WorkshopSteps._full, _folded = MotionPose(amount: 2);
  static final recipes = <String, List<WorkshopStep>>{
    'project_45': _scratcher(),
    'project_46': _divider(),
    'project_41': _bagClip(),
    'project_42': _funnel(),
    'project_43': _basket(),
    'project_47': _flyTrap(),
  };

  static List<WorkshopPart> _scratchBlock({
    bool filled = false,
    bool squeeze = false,
  }) => [
    _p('frame', WorkshopObject.shallowFrame, 160, 218),
    if (filled)
      for (var i = 0; i < 32; i++)
        _p(
          'strip$i',
          WorkshopObject.cardboardStrip,
          69 + i * 5.88,
          218,
          scale: .42,
          angle: math.pi / 2,
          label: 'packed',
        ),
    if (squeeze) _p('pressure', WorkshopObject.compression, 160, 218),
  ];
  static List<WorkshopStep> _scratcher() => [
    _step(
      'Üç kutudaki bant, zımba, ip ve plastikleri çıkar. Yalnızca temiz ve kuru karton kullan.',
      [
        for (var i = 0; i < 3; i++)
          _p('box$i', WorkshopObject.box, 75 + i * 85, 195, scale: .35),
      ],
      warning: 'Yağlı, küflü, parfümlü veya kimyasal taşımış karton kullanma.',
    ),
    _step(
      'Bir kutudan yaklaşık 30 × 20 cm tabanlı, 4–5 cm yüksekliğinde sığ bir çerçeve hazırlat.',
      _scratchBlock(),
      warning:
          'Kesimleri kesilmeye dayanıklı altlık üzerinde, yardım alarak yap.',
    ),
    _step(
      'Diğer iki kutuyu düzleştir. Yaklaşık 4 cm yüksekliğinde, çerçevenin iç eni kadar uzun şeritler hazırlat.',
      [
        _p('strip0', WorkshopObject.cardboardStrip, 160, 145, scale: 1.2),
        _p('strip1', WorkshopObject.cardboardStrip, 160, 215, scale: 1.2),
      ],
      warning: 'Kesici aletleri kullanırken yardım al. Oluklu kenarlar üstte kalacak.',
    ),
    _step(
      'Şeritleri oluklu kenarları yukarı bakacak şekilde sıkıca yan yana diz. Kolayca çıkabilen parça kalmasın.',
      _scratchBlock(filled: true),
      initial: {for (var i = 0; i < 32; i++) 'strip$i': _at(0, -125)},
      changes: [
        for (var group = 0; group < 8; group++)
          {for (var n = 0; n < 4; n++) 'strip${group * 4 + n}': _full},
      ],
    ),
    _step(
      'Boşluk kalmayacak şekilde sıkıştır. Karton yetmiyorsa çerçeveyi küçült; bağlantı malzemesi ekleme.',
      _scratchBlock(filled: true, squeeze: true),
      initial: {'pressure': const MotionPose(amount: .1)},
      changes: [
        {'pressure': _full},
      ],
      kind: MotionKind.assemble,
      warning: 'Yapıştırıcı, tel, zımba, lastik veya ip kullanma; açıkta bant bırakma.',
    ),
    _step(
      'Bloğu kaymayan zemine koy ve ilk kullanımda kedini gözle. Gevşeyen veya yıpranan şeritleri yenile.',
      _scratchBlock(filled: true),
      warning: 'Kedin kartonu koparıp yutuyorsa veya blok kayıyorsa hemen kaldır. Gözetimsiz çiğneme oyuncağı olarak bırakma.',
    ),
  ];

  static List<WorkshopPart> _strips(String top, String bottom) => [
    for (var i = 0; i < 4; i++)
      _p(
        'strip$i',
        WorkshopObject.slottedStrip,
        160,
        78 + i * 65,
        label: i < 2 ? top : bottom,
      ),
  ];
  static List<WorkshopStep> _divider() => [
    _step(
      'Çekmecenin içini ölç. Kartonu düzleştirip üzerindeki bant ve zımbaları çıkar.',
      [
        _p('board', WorkshopObject.board, 160, 180),
        _p('pen', WorkshopObject.pencil, 250, 235, scale: .65, angle: .4),
      ],
    ),
    _step(
      'Şeritleri çekmeceden yaklaşık 1 cm kısa yükseklikte işaretle. Örnekte her yönde iki şerit var.',
      _strips('plain', 'plain'),
    ),
    _step(
      'Şeritleri yardım alarak kes. Kesişecekleri yerleri ölçüp işaretle.',
      _strips('marked', 'marked'),
      warning:
          'Kesimleri kesilmeye dayanıklı altlık üzerinde yardım alarak yap.',
    ),
    _step(
      'Bir yöndeki yuvaları üstten, diğerlerini alttan yarı yüksekliğe kadar hazırlat. Yuva genişliği karton kalınlığı kadar olsun.',
      _strips('top', 'bottom'),
      warning: 'Yuvaları keserken yardım al. Karşılıklı yarım yuvalar aynı noktada birleşmeli.',
    ),
    _step(
      'Yarım yuvaları karşılıklı geçirip ızgarayı çekmeceye oturt. Zorlamak yerine yuvayı azar azar düzelt.',
      [
        _p('joint', WorkshopObject.interlock, 160, 155),
        _p('grid', WorkshopObject.drawerGrid, 160, 291, scale: .53),
      ],
      initial: {'grid': const MotionPose()},
      changes: [
        {'joint': _folded},
        {'grid': _full},
      ],
      kind: MotionKind.assemble,
      clipDuration: const Duration(milliseconds: 2000),
      warning: 'Yakın plan tek birleşme noktasını gösterir. Kartonu zorlayıp yırtma.',
    ),
    _step(
      'Boş çekmeceyi yavaşça açıp kapat; takılma olmadığını kontrol et. Yalnızca hafif eşyalar yerleştir.',
      [_p('grid', WorkshopObject.drawerGrid, 160, 190, scale: 1.1)],
      changes: [
        {'grid': _at(0, 12)},
        {'grid': _full},
      ],
      warning: 'Ağır veya keskin eşya dayama; rayları engelleme. Islanan veya küflenen kartonu yenile.',
    ),
  ];

  static List<WorkshopPart> _bottle({bool cap = true, bool mark = false}) => [
    _p('base', WorkshopObject.petBase, 160, 180),
    _p('top', WorkshopObject.petTop, 160, 180),
    if (cap) _p('cap', WorkshopObject.sideCap, 160, 108),
    if (mark) _p('mark', WorkshopObject.cutMark, 160, 180),
  ];
  static List<WorkshopPart> _clipBody({
    bool bag = false,
    bool mouth = false,
    bool cap = true,
  }) => [
    if (bag) _p('bag', WorkshopObject.bagBody, 160, 254),
    if (mouth) _p('mouth', WorkshopObject.bagMouth, 160, 155),
    _p('top', WorkshopObject.petTop, 160, 155),
    _p('band', WorkshopObject.tape, 160, 155, scale: 1.2),
    if (cap) _p('cap', WorkshopObject.sideCap, 160, 83),
  ];
  static List<WorkshopStep> _bagClip() => [
    _step(
      'Şişeyi ve kapağını yıka, kurut. Boynun altında 2–3 cm omuz payı bırakıp kesim çizgisini işaretle.',
      _bottle(mark: true),
      initial: {'mark': const MotionPose()},
      changes: [
        {'mark': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'Şişenin üst parçasını işaretli çizgiden ayır. Kesik çevresini bantla kapat; vida kısmı açık kalsın.',
      [..._bottle(), _p('band', WorkshopObject.tape, 160, 180, scale: 1.2)],
      initial: {'band': const MotionPose()},
      changes: [
        {'top': _at(0, -50), 'cap': _at(0, -50), 'base': _at(0, 45)},
        {'band': _at(0, -50)},
      ],
      kind: MotionKind.split,
      warning: 'Sabit altlıkta keserken yardım al. Alev veya sıcak alet kullanma; sivri kenar bırakma.',
    ),
    _step(
      'Kapağı çıkar. Poşetin boş ağzını alttan şişe boynundan geçirip birkaç santimetre dışarı çek.',
      _clipBody(bag: true, mouth: true),
      initial: {'mouth': _full},
      changes: [
        {'cap': _at(80, -45)},
        {'mouth': _folded},
      ],
      clipDuration: const Duration(milliseconds: 1800),
    ),
    _step(
      'Poşet ağzını boynun dışına katla ve kapağı zorlamadan kapat. Kapanmıyorsa daha ince, sağlam bir poşet dene.',
      _clipBody(bag: true, mouth: true),
      initial: {'mouth': _folded, 'cap': _at(80, -45)},
      changes: [
        {'mouth': const MotionPose(amount: 3)},
        {'cap': _full},
      ],
      kind: MotionKind.assemble,
      clipDuration: const Duration(milliseconds: 1800),
    ),
    _step(
      'Çekerek kontrol et; poşeti ters çevirmeden sakla. Kapağı açıp kapatabilirsin; bantta veya poşette yırtık varsa yenile.',
      _clipBody(bag: true, mouth: true),
      initial: {'mouth': const MotionPose(amount: 3)},
      changes: [
        {'cap': _at(0, -35)},
        {'cap': _full},
      ],
      warning: 'Küçük kapakları çocuklardan uzak tut. Sıvı, kimyasal veya gıdayı uzun süre saklamak için kullanma.',
    ),
  ];

  static List<WorkshopPart> _funnelParts({
    bool band = true,
    bool receiver = false,
    bool flow = false,
  }) => [
    if (receiver) _p('receiver', WorkshopObject.cup, 160, 268, scale: .8),
    if (flow) ...[
      _p('pile', WorkshopObject.dryPile, 160, 242),
      _p('stream', WorkshopObject.dryStream, 160, 140),
    ],
    _p('top', WorkshopObject.petTop, 160, receiver ? 164 : 140, angle: math.pi),
    if (band)
      _p('band', WorkshopObject.tape, 160, receiver ? 164 : 140, scale: 1.2),
  ];
  static List<WorkshopStep> _funnel() => [
    _step(
      'Şişeyi yıka, kurut ve kapağı çıkar. Ağızdan yaklaşık 10–12 cm aşağıya kesim çizgisi çiz.',
      _bottle(mark: true),
      initial: {'mark': const MotionPose()},
      changes: [
        {'cap': _at(85, -45)},
        {'mark': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'Üst parçayı yardım alarak kes; keskin çıkıntı kalmasın. Şişenin ağzı aşağı bakınca huni şekli oluşur.',
      _bottle(cap: false),
      changes: [
        {'top': _at(0, -40), 'base': _at(80, 15)},
        {'top': _at(0, -40, angle: math.pi)},
      ],
      kind: MotionKind.rotate,
      warning: 'Sabit altlıkta keserken yardım al. Alev, sıcak metal veya başka bir ısıyla şekillendirme yapma.',
    ),
    _step(
      'Geniş kesik kenarı tamamen bantla. Bant, huninin içini ve akış yolunu kapatmasın.',
      _funnelParts(),
      initial: {'band': const MotionPose()},
      changes: [
        {'band': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'Dar ağzı alıcı kaba oturt ve elinle sabitle. Az miktarda kuru malzemeyle akışı dene.',
      _funnelParts(receiver: true, flow: true),
      initial: {
        'top': _at(0, -65),
        'band': _at(0, -65),
        'stream': const MotionPose(),
        'pile': const MotionPose(),
      },
      changes: [
        {'top': _full, 'band': _full},
        {'stream': _full, 'pile': const MotionPose(amount: .25)},
      ],
      clipDuration: const Duration(milliseconds: 1800),
      warning: 'Huniyi kendi başına dengede bırakma. Yalnızca kuru, gıda dışı malzeme aktar.',
    ),
    _step(
      'Kuru malzemeyi yavaşça aktar. Ardından huniyi yıka, kurut; gevşek bandı yenile, çatlak huniyi değiştir.',
      _funnelParts(receiver: true, flow: true),
      initial: {'stream': const MotionPose(), 'pile': const MotionPose()},
      changes: [
        {'stream': _full, 'pile': _full},
      ],
      kind: MotionKind.pour,
      clipDuration: const Duration(milliseconds: 2600),
      warning: 'Gıda, sıcak sıvı, yakıt, çözücü veya tehlikeli kimyasal aktarımında kullanma.',
    ),
  ];

  static List<WorkshopPart> _basketBody({
    bool holes = false,
    bool ropes = false,
    bool ring = false,
    bool food = false,
  }) => [
    _p('cup', WorkshopObject.cup, 160, 232, scale: 1.2),
    if (food) ...[
      _p('onion0', WorkshopObject.onion, 132, 185, scale: .75),
      _p('onion1', WorkshopObject.onion, 188, 185, scale: .75),
      _p('front', WorkshopObject.cup, 160, 232, scale: 1.2, label: 'front'),
    ],
    if (holes) _p('holes', WorkshopObject.ventHoles, 160, 232, scale: 1.2),
    if (ropes)
      for (var i = 0; i < 3; i++)
        _p('rope$i', WorkshopObject.suspensionRope, 160, 85, label: '$i'),
    if (ring) _p('ring', WorkshopObject.hangerRing, 160, 48),
  ];
  static List<WorkshopStep> _basket() => [
    _step(
      'Kabı yıka ve tamamen kurut; kapağını çıkar. Çatlak veya kırılgan kap kullanma.',
      [..._basketBody(), _p('lid', WorkshopObject.lid, 160, 181, scale: 1.2)],
      changes: [
        {'lid': _at(80, -85)},
      ],
    ),
    _step(
      'Yan yüzeyde havalandırma delikleri hazırlat. Üç askı deliği ağızdan yaklaşık 3 cm aşağıda, eşit aralıkta olsun.',
      [
        _p('cup', WorkshopObject.cup, 110, 236),
        _p('holes', WorkshopObject.ventHoles, 110, 236),
        _p(
          'closeup',
          WorkshopObject.ventHoles,
          235,
          100,
          scale: .7,
          label: 'top',
        ),
      ],
      initial: {'holes': const MotionPose(), 'closeup': const MotionPose()},
      changes: [
        {'holes': _full, 'closeup': _full},
      ],
      kind: MotionKind.assemble,
      warning: 'Delikleri kabı sabitleyerek, yardım alarak aç. Isıtılmış alet kullanma.',
    ),
    _step(
      'Keskin çıkıntıları temizlet. Yaklaşık 60 cm uzunluğunda üç eşit kordonu deliklerden geçir; içeriden kaymayacak büyük düğümlerle sabitle.',
      _basketBody(holes: true, ropes: true),
      initial: {for (var i = 0; i < 3; i++) 'rope$i': const MotionPose()},
      changes: [
        for (var i = 0; i < 3; i++) {'rope$i': _full},
      ],
      warning: 'Keskin plastik kalmasın. Düğümler delikten kaçmayacak kadar büyük olsun.',
    ),
    _step(
      'Üç kordonu üstte tek halkada birleştir. Önce boşken, sonra küçük bir yükü elinle destekleyerek dengele.',
      _basketBody(holes: true, ropes: true, ring: true),
      initial: {'ring': const MotionPose()},
      changes: [
        {for (var i = 0; i < 3; i++) 'rope$i': _folded, 'ring': _full},
      ],
      kind: MotionKind.assemble,
      warning: 'İnsanların veya hayvanların geçişinin üzerine asma. Yük testini destekleyerek yap.',
    ),
    _step(
      'Kuru, kabuklu soğan veya sarımsağı gevşekçe yerleştir. Toplam yükü yaklaşık 300 gramla sınırla.',
      _basketBody(holes: true, ropes: true, ring: true, food: true),
      initial: {
        for (var i = 0; i < 3; i++) 'rope$i': _folded,
        'onion0': _at(0, -85),
        'onion1': _at(0, -85),
      },
      changes: [
        {'onion0': _full},
        {'onion1': _full},
      ],
      warning: 'Serin, kuru ve havadar yerde; güneşten ve ocaktan uzak tut. Soğan ve sarımsak kedi ve köpekler için zararlıdır; erişemesinler.',
    ),
    _step(
      'Ürünleri ve askı deliklerini düzenli kontrol et. Çürüyen ürünü ayır; kap veya delik çevresi çatladıysa kullanmayı bırak.',
      _basketBody(holes: true, ropes: true, ring: true, food: true),
      initial: {for (var i = 0; i < 3; i++) 'rope$i': _folded},
      warning: 'Uzun kordonları çocuklardan ve hayvanlardan uzak tut.',
    ),
  ];

  static List<WorkshopPart> _trap({
    bool liquid = true,
    bool cone = true,
    bool mat = false,
  }) => [
    if (mat) _p('mat', WorkshopObject.board, 160, 312, scale: .8),
    if (liquid) _p('liquid', WorkshopObject.liquidFill, 160, 220),
    _p('jar', WorkshopObject.jar, 160, 220),
    if (cone) ...[
      _p('cone', WorkshopObject.paperCone, 160, 130),
      _p('tape', WorkshopObject.tape, 210, 120, scale: .4, angle: -.4),
    ],
  ];
  static List<WorkshopStep> _flyTrap() => [
    _step(
      'Sağlam kavanoza yaklaşık 50 ml elma sirkesi ve bir damla bulaşık deterjanı koy. Hafifçe çevirerek karıştır.',
      [
        ..._trap(cone: false),
        _p(
          'bottle',
          WorkshopObject.ingredientBottle,
          100,
          65,
          scale: .7,
          angle: 2.2,
        ),
        _p('stream', WorkshopObject.pourStream, 160, 90),
        _p('drop', WorkshopObject.singleDrop, 160, 90),
      ],
      initial: {
        'liquid': const MotionPose(),
        'stream': const MotionPose(),
        'drop': const MotionPose(),
      },
      changes: [
        {'stream': _full, 'liquid': _full},
        {'stream': const MotionPose(), 'drop': _full},
        {'drop': const MotionPose(offset: Offset(0, 175))},
        {'jar': _at(0, 0, angle: .04), 'liquid': _at(0, 0, angle: .04)},
        {'jar': _full, 'liquid': _full},
      ],
      kind: MotionKind.pour,
      warning: 'Çatlak cam kullanma. Karışım içilmez; sirkeyi çamaşır suyu veya başka temizlik kimyasallarıyla karıştırma.',
    ),
    _step(
      'Kâğıdı ucunda 3–4 mm açıklık kalacak şekilde koni yap. Yan birleşimini dıştan bantla.',
      [
        _p('cone', WorkshopObject.paperCone, 160, 180),
        _p('tape', WorkshopObject.tape, 210, 170, scale: .4, angle: -.4),
      ],
      initial: {'tape': const MotionPose()},
      changes: [
        {'cone': _folded},
        {'tape': _full},
      ],
      kind: MotionKind.assemble,
      clipDuration: const Duration(milliseconds: 1800),
    ),
    _step(
      'Huniyi kavanoza yerleştir; ucu sıvıya değmesin. Üst kenar kavanoz ağzını boşluk bırakmadan kapatsın.',
      _trap(),
      initial: {
        'cone': const MotionPose(offset: Offset(0, -55), amount: 2),
        'tape': _at(0, -55),
      },
      changes: [
        {'cone': _folded, 'tape': _full},
      ],
      clipDuration: const Duration(milliseconds: 1800),
    ),
    _step(
      'Tuzağı devrilmeyecek bir altlıkta, sinek görülen yere yakın tut. Gıda hazırlama yüzeyinden ayrı olsun.',
      _trap(mat: true),
      initial: {'cone': _folded},
      warning: 'Çocukların ve evcil hayvanların erişemeyeceği yerde; kenarlardan ve güneşten uzak tut.',
    ),
    _step(
      'Her gün kontrol et; karışımı 2–3 günde bir yenile. Kavanozu yıkayıp tekrar kullan, ıslanan kâğıt huniyi değiştir.',
      _trap(mat: true),
      initial: {'cone': _folded},
    ),
    _step(
      'Çürüyen meyveleri uzaklaştır, çöpü kapat ve yiyecek artıklarını temizle. Tuzak tek başına üreme kaynağını gidermez.',
      _trap(mat: true),
      initial: {'cone': _folded},
    ),
  ];
}
