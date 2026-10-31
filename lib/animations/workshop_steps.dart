import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/upcycling_project.dart';
import 'motion_sequence.dart';

part 'workshop_package2_steps.dart';
part 'workshop_package3_steps.dart';
part 'paper_cup_steps.dart';

enum WorkshopObject {
  board,
  roll,
  box,
  bottle,
  cap,
  ball,
  cup,
  yarn,
  thread,
  pencil,
  tape,
  grid,
  cross,
  ring,
  water,
  distance,
  cloth,
  sheet,
  foldingPaper,
  foldingFlap,
  cable,
  frameWrap,
  photo,
  jar,
  paperDot,
  flipCap,
  binocularWrap,
  eggTray,
  stone,
  lid,
  slot,
  coin,
  paperPanel,
  accordion,
  receipt,
  shallowFrame,
  cardboardStrip,
  slottedStrip,
  interlock,
  drawerGrid,
  compression,
  petTop,
  petBase,
  cutMark,
  sideCap,
  bagBody,
  bagMouth,
  dryStream,
  dryPile,
  ventHoles,
  suspensionRope,
  hangerRing,
  onion,
  liquidFill,
  pourStream,
  ingredientBottle,
  singleDrop,
  paperCone,
  paperCup,
}

/// Shared vector parts, positioned in a 320 × 330 logical scene.
@immutable
class WorkshopPart {
  const WorkshopPart(
    this.id,
    this.object,
    this.position, {
    this.scale = 1,
    this.angle = 0,
    this.label = '',
  });
  final String id, label;
  final WorkshopObject object;
  final Offset position;
  final double scale, angle;
}

@immutable
class WorkshopStep {
  const WorkshopStep({
    required this.description,
    required this.parts,
    required this.sequence,
    this.warning,
  });
  final String description;
  final String? warning;
  final List<WorkshopPart> parts;
  final MotionSequence sequence;
}

/// Recipe/step registry. No controller or recipe matching logic lives here.
/// A changed catalogue step count falls back to text rather than wrong media.
abstract final class WorkshopSteps {
  static final Map<String, List<WorkshopStep>> recipes = Map.unmodifiable(
    {
      'project_01': _organizer(),
      'project_03': _xox(),
      'project_15': _bowling(),
      'project_38': _yarnBowl(),
      'project_39': _drum(),
      ..._Package2Steps.recipes,
      ..._Package3Steps.recipes,
      'project_49': _PaperCupSteps.steps,
    }.map((id, steps) => MapEntry(id, List<WorkshopStep>.unmodifiable(steps))),
  );

  static bool supports(UpcyclingProject project) =>
      recipes[project.id]?.length == project.steps.length;
  static WorkshopStep? resolve(UpcyclingProject project, int index) {
    if (!supports(project) || index < 0 || index >= project.steps.length) {
      return null;
    }
    return recipes[project.id]![index];
  }

  static const _full = MotionPose(amount: 1);
  static MotionPose _at(double x, double y, {double angle = 0}) =>
      MotionPose(offset: Offset(x, y), angle: angle, amount: 1);
  static WorkshopPart _p(
    String id,
    WorkshopObject object,
    double x,
    double y, {
    double scale = 1,
    double angle = 0,
    String label = '',
  }) => WorkshopPart(
    id,
    object,
    Offset(x, y),
    scale: scale,
    angle: angle,
    label: label,
  );
  static WorkshopStep _step(
    String text,
    List<WorkshopPart> parts, {
    Map<String, MotionPose> initial = const {},
    List<Map<String, MotionPose>> changes = const [],
    MotionKind kind = MotionKind.insert,
    String? warning,
    Duration clipDuration = const Duration(milliseconds: 900),
  }) => WorkshopStep(
    description: text,
    warning: warning,
    parts: List.unmodifiable(parts),
    sequence: MotionSequence(
      initial: {for (final part in parts) part.id: _full, ...initial},
      clips: [
        for (final targets in changes)
          MotionClip(kind: kind, targets: targets, duration: clipDuration),
      ],
    ),
  );
  static List<WorkshopPart> _rolls() => [
    _p('base', WorkshopObject.board, 160, 260),
    for (var i = 0; i < 3; i++)
      _p('roll$i', WorkshopObject.roll, 100 + i * 60, 198),
  ];
  static List<WorkshopPart> _baseTape() => [
    for (var i = 0; i < 3; i++)
      _p('tape$i', WorkshopObject.tape, 100 + i * 60, 246, scale: .7),
  ];
  static List<WorkshopPart> _topTape() => [
    _p('join0', WorkshopObject.tape, 130, 177, scale: .8),
    _p('join1', WorkshopObject.tape, 190, 177, scale: .8),
  ];
  static List<WorkshopStep> _organizer() => [
    _step(
      'Kutunun bir kapağını kat yerinden yavaşça ayır. Düz parçayı taban olarak kullan.',
      [
        _p('box', WorkshopObject.box, 160, 220, scale: .75),
        _p('flap', WorkshopObject.board, 160, 140, scale: .7),
      ],
      changes: [
        {'flap': _at(0, -60, angle: -.15)},
      ],
      warning: 'Karton kenarları elini çizebilir; parçayı yavaşça ayır.',
    ),
    _step(
      'Üç ruloyu tabanın üzerine dik ve yan yana yerleştir.',
      _rolls(),
      initial: {for (var i = 0; i < 3; i++) 'roll$i': _at(0, -100)},
      changes: [
        for (var i = 0; i < 3; i++) {'roll$i': _full},
      ],
    ),
    _step(
      'Ruloların alt kısımlarını tabana bantla sabitle.',
      [..._rolls(), ..._baseTape()],
      initial: {for (var i = 0; i < 3; i++) 'tape$i': const MotionPose()},
      changes: [
        for (var i = 0; i < 3; i++) {'tape$i': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'Birbirine değen ruloları üstten de bantla. Böylece birlikte daha sağlam dururlar.',
      [..._rolls(), ..._baseTape(), ..._topTape()],
      initial: {'join0': const MotionPose(), 'join1': const MotionPose()},
      changes: [
        {'join0': _full},
        {'join1': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'Kalemlerini ruloların içine yerleştir.',
      [
        // Draw pencils before the rolls so the lower ends are hidden inside.
        _p('base', WorkshopObject.board, 160, 260),
        for (var i = 0; i < 3; i++)
          _p('pencil$i', WorkshopObject.pencil, 100 + i * 60, 160, scale: .85),
        ..._rolls().skip(1), ..._baseTape(), ..._topTape(),
      ],
      initial: {for (var i = 0; i < 3; i++) 'pencil$i': _at(0, -80)},
      changes: [
        for (var i = 0; i < 3; i++) {'pencil$i': _full},
      ],
    ),
  ];

  static List<WorkshopPart> _board({bool grid = false}) => [
    _p('board', WorkshopObject.board, 160, 165, scale: 1.1),
    if (grid) _p('grid', WorkshopObject.grid, 160, 165),
  ];
  static List<WorkshopPart> _tokens({bool signs = true}) => [
    for (var i = 0; i < 10; i++) ...[
      _p(
        'cap$i',
        WorkshopObject.cap,
        60 + (i % 5) * 50,
        140 + (i ~/ 5) * 70,
        scale: .75,
      ),
      if (signs)
        _p(
          'mark$i',
          i < 5 ? WorkshopObject.cross : WorkshopObject.ring,
          60 + (i % 5) * 50,
          140 + (i ~/ 5) * 70,
          scale: .75,
        ),
    ],
  ];
  static List<WorkshopStep> _xox() => [
    _step(
      'Kutudan düz bir karton parça ayır veya kutuyu düzleştir.',
      _board(),
      initial: {'board': _at(0, -55, angle: -.18)},
      changes: [
        {'board': _full},
      ],
      kind: MotionKind.assemble,
      warning: 'Karton kenarlarına dikkat ederek yavaşça çalış.',
    ),
    _step(
      'Kartona iki yatay ve iki dikey çizgi çiz. Dokuz karelik oyun alanın hazır.',
      [
        ..._board(grid: true),
        _p('pen', WorkshopObject.pencil, 218, 174, scale: .55, angle: .5),
      ],
      initial: {'grid': const MotionPose(), 'pen': _at(-100, -55)},
      changes: [
        {'grid': const MotionPose(amount: .5), 'pen': _at(0, -55)},
        {'grid': _full, 'pen': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'Beş kapağın içine X, diğer beş kapağın içine O çiz.',
      [
        ..._tokens(),
        _p('pen', WorkshopObject.pencil, 275, 265, scale: .55, angle: -.6),
      ],
      initial: {for (var i = 0; i < 10; i++) 'mark$i': const MotionPose()},
      changes: [
        for (var i = 0; i < 5; i++) {'mark$i': _full, 'mark${i + 5}': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'Sırayla birer kapak yerleştir. Aynı işaretle üçlü sıra oluşturmaya çalış.',
      [
        ..._board(grid: true),
        for (var i = 0; i < 10; i++) ...[
          _p(
            'cap$i',
            WorkshopObject.cap,
            i < 3 ? 100 + i * 60 : 40 + (i - 3) * 40,
            i < 3 ? 165 : 285,
            scale: i < 3 ? .7 : .52,
          ),
          _p(
            'mark$i',
            i.isEven ? WorkshopObject.cross : WorkshopObject.ring,
            i < 3 ? 100 + i * 60 : 40 + (i - 3) * 40,
            i < 3 ? 165 : 285,
            scale: i < 3 ? .7 : .52,
          ),
        ],
      ],
      initial: {
        for (var i = 0; i < 3; i++) ...{
          'cap$i': _at(0, 80),
          'mark$i': _at(0, 80),
        },
      },
      changes: [
        for (var i = 0; i < 3; i++) {'cap$i': _full, 'mark$i': _full},
      ],
      warning:
          'Oyun bitince ellerini yıka; kapakları küçük çocuklardan uzak tut.',
    ),
  ];

  static List<WorkshopPart> _bottles({bool water = false}) => [
    for (var i = 0; i < 6; i++) ...[
      _p(
        'bottle$i',
        WorkshopObject.bottle,
        [100.0, 160.0, 220.0, 130.0, 190.0, 160.0][i],
        [80.0, 80.0, 80.0, 160.0, 160.0, 240.0][i],
        scale: .48,
      ),
      if (water)
        _p(
          'water$i',
          WorkshopObject.water,
          [100.0, 160.0, 220.0, 130.0, 190.0, 160.0][i],
          [102.0, 102.0, 102.0, 182.0, 182.0, 262.0][i],
          scale: .4,
        ),
    ],
  ];
  static List<WorkshopStep> _bowling() => [
    _step('Altı şişeyi hafifçe yıka ve kapaklarını sıkıca kapat.', _bottles()),
    _step(
      'İstersen şişelerin dibine çok az su ekle. Bu adım isteğe bağlı.',
      _bottles(water: true),
      initial: {for (var i = 0; i < 6; i++) 'water$i': const MotionPose()},
      changes: [
        {for (var i = 0; i < 6; i++) 'water$i': _full},
      ],
      kind: MotionKind.pour,
      warning: 'Su eklediysen kapakları sıkıca kapat; zemin kuru kalsın.',
    ),
    _step(
      'Şişeleri arkada üç, ortada iki, önde bir olacak şekilde diz.',
      _bottles(),
      initial: {for (var i = 0; i < 6; i++) 'bottle$i': _at(100, 0)},
      changes: [
        for (var i = 0; i < 6; i++) {'bottle$i': _full},
      ],
    ),
    _step('Birkaç metre geri çekil. Topu yuvarlayacağın alanı boş bırak.', [
      ..._bottles(),
      _p('distance', WorkshopObject.distance, 65, 245, scale: .8),
    ]),
    _step(
      'Topu yerden yuvarlayıp şişeleri devirmeyi dene.',
      [..._bottles(), _p('ball', WorkshopObject.ball, 160, 310, scale: .75)],
      changes: [
        {'ball': _at(0, -18, angle: math.pi / 2)},
        {
          'ball': _at(0, -55, angle: math.pi * 1.5),
          'bottle5': _at(35, 0, angle: 1.2),
        },
      ],
      warning: 'Yerdeki eşyaları kaldır. Islak zeminde oynama; topu fırlatma.',
    ),
  ];

  static List<WorkshopPart> _bowl({bool yarn = false, bool thread = false}) => [
    _p('cup', WorkshopObject.cup, 160, 210, scale: 1.3),
    if (yarn) _p('yarn', WorkshopObject.yarn, 160, 177, scale: 1.05),
    // The front wall hides the lower half of the ball, not an opaque overlay.
    if (yarn)
      _p('front', WorkshopObject.cup, 160, 210, scale: 1.3, label: 'front'),
    if (thread) _p('thread', WorkshopObject.thread, 160, 177),
  ];
  static List<WorkshopStep> _yarnBowl() => [
    _step(
      'Kabı iyice yıka ve bir bezle tamamen kurula.',
      [
        _p('cup', WorkshopObject.cup, 160, 200, scale: 1.3),
        _p('cloth', WorkshopObject.cloth, 235, 265, scale: .7),
      ],
      warning: 'Kenarı keskin veya çatlak bir kap kullanma; ip takılabilir ve elin çizilebilir.',
    ),
    _step(
      'İp yumağını kabın içine yerleştir.',
      _bowl(yarn: true),
      initial: {'yarn': _at(0, -100)},
      changes: [
        {'yarn': _full},
      ],
    ),
    _step(
      'İpin ucunu kabın açık ağzından dışarı sarkıt.',
      _bowl(yarn: true, thread: true),
      initial: {'thread': const MotionPose()},
      changes: [
        {'thread': _full},
      ],
    ),
    _step(
      'Kabı yanına koy ve ipi yavaşça çekerek örgüne devam et.',
      _bowl(yarn: true, thread: true),
      changes: [
        {'thread': const MotionPose(amount: 1.18)},
        {'thread': _full},
        {'thread': const MotionPose(amount: 1.18)},
        {'thread': _full},
      ],
    ),
  ];

  static List<WorkshopPart> _drumBody({bool tape = false}) => [
    _p('cup', WorkshopObject.cup, 160, 225, scale: 1.25, angle: math.pi),
    if (tape) ...[
      for (var i = 0; i < 3; i++)
        _p(
          'tape$i',
          WorkshopObject.tape,
          120 + i * 40,
          222,
          scale: .65,
          angle: math.pi / 2,
        ),
    ],
  ];
  static List<WorkshopStep> _drum() => [
    _step('Yoğurt kabını temizle ve tamamen kurula.', [
      _p('cup', WorkshopObject.cup, 160, 210, scale: 1.25),
      _p('cloth', WorkshopObject.cloth, 235, 265, scale: .7),
    ]),
    _step(
      'Kabı ters çevir; açık ağzı yere baksın.',
      [_p('cup', WorkshopObject.cup, 160, 225, scale: 1.25)],
      changes: [
        {'cup': _at(0, 0, angle: math.pi)},
      ],
      kind: MotionKind.rotate,
    ),
    _step(
      'Kabın dışını renkli bantlar veya etiketlerle süsle.',
      _drumBody(tape: true),
      initial: {for (var i = 0; i < 3; i++) 'tape$i': const MotionPose()},
      changes: [
        for (var i = 0; i < 3; i++) {'tape$i': _full},
      ],
      kind: MotionKind.assemble,
    ),
    _step(
      'İki kalemin silgili uçlarıyla hafifçe vurarak ritim tut.',
      [
        ..._drumBody(tape: true),
        _p('stick0', WorkshopObject.pencil, 125, 86, scale: .95, angle: -.25),
        _p('stick1', WorkshopObject.pencil, 195, 86, scale: .95, angle: .25),
      ],
      changes: [
        {'stick0': _at(0, 23)},
        {'stick0': _full, 'stick1': _at(0, 23)},
        {'stick0': _at(0, 23), 'stick1': _full},
        {'stick0': _full, 'stick1': _at(0, 23)},
        {'stick1': _full},
      ],
      warning:
          'Yalnızca silgili uçlarla hafifçe vur. Sivri uçlar kabı delebilir.',
    ),
  ];
}
