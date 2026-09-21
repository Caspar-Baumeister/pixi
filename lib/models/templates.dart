import 'package:flutter/material.dart';

import 'pix_map.dart';

/// Template categories shown in the "new map" screen.
enum TemplateCategory { feelings, body, habits, custom }

class MapTemplate {
  const MapTemplate({
    required this.id,
    required this.category,
    required this.baseColor,
    required this.levels,
    this.catId = 'pixi',
  });

  final String id;
  final TemplateCategory category;
  final Color baseColor;

  /// Level label keys (resolved via Strings) with colours.
  final List<MapLevel> levels;
  final String catId;

  String get titleKey => '@t_$id';
  String get questionKey => '@q_$id';

  PixMap toMap(String id) => PixMap(
        id: id,
        title: titleKey,
        question: questionKey,
        baseColor: baseColor,
        levels: levels,
        catId: catId,
        templateId: this.id,
        category: category.name,
        createdAt: DateTime.now(),
      );
}

/// Base colours ("Grundfarben") – the glow colour of each map.
class BaseColors {
  BaseColors._();
  static const violet = Color(0xFF9B6BF5);
  static const black = Color(0xFF1B1B1F);
  static const sky = Color(0xFF5FA8E6);
  static const green = Color(0xFF6DB56A);
  static const coral = Color(0xFFE8735A);
  static const gold = Color(0xFFF2BE3C);
  static const rose = Color(0xFFE879A8);
  static const teal = Color(0xFF3FAF9E);
  static const orange = Color(0xFFF08A3E);
  static const brown = Color(0xFF9C6B4A);
  static const indigo = Color(0xFF4A5FC1);
  static const red = Color(0xFFD9534F);
  static const graphite = Color(0xFF6B6B72);

  static const List<Color> palette = [
    violet,
    black,
    sky,
    green,
    coral,
    gold,
    rose,
    teal,
    orange,
    brown,
    indigo,
    red,
    graphite,
  ];
}

/// Curated colour ramps for map levels. Index 0 = "lowest".
class Ramps {
  Ramps._();

  static const mood = [
    0xFF4B4E7A, // mies
    0xFF8E8FB8, // meh
    0xFFC4B4EC, // okay
    0xFF9B6BF5, // gut
    0xFFF2BE3C, // super (golden highlight)
  ];
  static const dreams = [
    0xFFE6E4DE, // keiner
    0xFFA9A7A2, // vage
    0xFF4A4A4E, // lebhaft
    0xFF1B1B1F, // sehr intensiv / Albtraum
  ];
  static const sleep = [
    0xFFE6E4DE,
    0xFFB4B2AC,
    0xFF7C7B78,
    0xFF45454A,
    0xFF1B1B1F,
  ];
  static const cry = [0xFFEAF2FA, 0xFFA9CBEB, 0xFF4F94D6];
  static const training = [0xFFE3EEDD, 0xFFA8D08D, 0xFF4E9A45];
  static const yesNo = [0xFFE6E4DE, 0xFF1B1B1F];
}

const List<MapTemplate> kTemplates = [
  // ---- Gefühle ----
  MapTemplate(
    id: 'mood',
    category: TemplateCategory.feelings,
    baseColor: BaseColors.violet,
    levels: [
      MapLevel(label: '@l_mood_0', color: Color(0xFF4B4E7A)),
      MapLevel(label: '@l_mood_1', color: Color(0xFF8E8FB8)),
      MapLevel(label: '@l_mood_2', color: Color(0xFFC4B4EC)),
      MapLevel(label: '@l_mood_3', color: Color(0xFF9B6BF5)),
      MapLevel(label: '@l_mood_4', color: Color(0xFFF2BE3C)),
    ],
  ),
  MapTemplate(
    id: 'cry',
    category: TemplateCategory.feelings,
    baseColor: BaseColors.sky,
    levels: [
      MapLevel(label: '@l_cry_0', color: Color(0xFFEAF2FA)),
      MapLevel(label: '@l_cry_1', color: Color(0xFFA9CBEB)),
      MapLevel(label: '@l_cry_2', color: Color(0xFF4F94D6)),
    ],
  ),
  MapTemplate(
    id: 'anxiety',
    category: TemplateCategory.feelings,
    baseColor: BaseColors.indigo,
    levels: [
      MapLevel(label: '@l_anx_0', color: Color(0xFFE9ECF8)),
      MapLevel(label: '@l_anx_1', color: Color(0xFFB4BCEA)),
      MapLevel(label: '@l_anx_2', color: Color(0xFF7583D6)),
      MapLevel(label: '@l_anx_3', color: Color(0xFF3B48A8)),
    ],
  ),
  MapTemplate(
    id: 'social',
    category: TemplateCategory.feelings,
    baseColor: BaseColors.rose,
    levels: [
      MapLevel(label: '@l_soc_0', color: Color(0xFFFAE6EF)),
      MapLevel(label: '@l_soc_1', color: Color(0xFFF1B6D1)),
      MapLevel(label: '@l_soc_2', color: Color(0xFFE879A8)),
    ],
  ),
  MapTemplate(
    id: 'gratitude',
    category: TemplateCategory.feelings,
    baseColor: BaseColors.gold,
    levels: [
      MapLevel(label: '@l_no', color: Color(0xFFE6E4DE)),
      MapLevel(label: '@l_yes', color: Color(0xFFF2BE3C)),
    ],
  ),
  // ---- Körper ----
  MapTemplate(
    id: 'dreams',
    category: TemplateCategory.body,
    baseColor: BaseColors.black,
    levels: [
      MapLevel(label: '@l_dr_0', color: Color(0xFFE6E4DE)),
      MapLevel(label: '@l_dr_1', color: Color(0xFFA9A7A2)),
      MapLevel(label: '@l_dr_2', color: Color(0xFF4A4A4E)),
      MapLevel(label: '@l_dr_3', color: Color(0xFF1B1B1F)),
    ],
  ),
  MapTemplate(
    id: 'sleep',
    category: TemplateCategory.body,
    baseColor: BaseColors.black,
    levels: [
      MapLevel(label: '@l_sl_0', color: Color(0xFFE6E4DE)),
      MapLevel(label: '@l_sl_1', color: Color(0xFFB4B2AC)),
      MapLevel(label: '@l_sl_2', color: Color(0xFF7C7B78)),
      MapLevel(label: '@l_sl_3', color: Color(0xFF45454A)),
      MapLevel(label: '@l_sl_4', color: Color(0xFF1B1B1F)),
    ],
  ),
  MapTemplate(
    id: 'energy',
    category: TemplateCategory.body,
    baseColor: BaseColors.orange,
    levels: [
      MapLevel(label: '@l_en_0', color: Color(0xFFFBE9DC)),
      MapLevel(label: '@l_en_1', color: Color(0xFFF6C4A0)),
      MapLevel(label: '@l_en_2', color: Color(0xFFF08A3E)),
      MapLevel(label: '@l_en_3', color: Color(0xFFC85A14)),
    ],
  ),
  MapTemplate(
    id: 'period',
    category: TemplateCategory.body,
    baseColor: BaseColors.red,
    levels: [
      MapLevel(label: '@l_pe_0', color: Color(0xFFE6E4DE)),
      MapLevel(label: '@l_pe_1', color: Color(0xFFF2B8B6)),
      MapLevel(label: '@l_pe_2', color: Color(0xFFE07A77)),
      MapLevel(label: '@l_pe_3', color: Color(0xFFC0302C)),
    ],
  ),
  MapTemplate(
    id: 'pain',
    category: TemplateCategory.body,
    baseColor: BaseColors.coral,
    levels: [
      MapLevel(label: '@l_pa_0', color: Color(0xFFE6E4DE)),
      MapLevel(label: '@l_pa_1', color: Color(0xFFF6C9BE)),
      MapLevel(label: '@l_pa_2', color: Color(0xFFE8735A)),
      MapLevel(label: '@l_pa_3', color: Color(0xFFB4412A)),
    ],
  ),
  // ---- Gewohnheiten ----
  MapTemplate(
    id: 'training',
    category: TemplateCategory.habits,
    baseColor: BaseColors.green,
    levels: [
      MapLevel(label: '@l_tr_0', color: Color(0xFFE3EEDD)),
      MapLevel(label: '@l_tr_1', color: Color(0xFFA8D08D)),
      MapLevel(label: '@l_tr_2', color: Color(0xFF4E9A45)),
    ],
  ),
  MapTemplate(
    id: 'alcohol',
    category: TemplateCategory.habits,
    baseColor: BaseColors.gold,
    levels: [
      MapLevel(label: '@l_al_0', color: Color(0xFFE6E4DE)),
      MapLevel(label: '@l_al_1', color: Color(0xFFF6DE9A)),
      MapLevel(label: '@l_al_2', color: Color(0xFFE0A81C)),
    ],
  ),
  MapTemplate(
    id: 'meditation',
    category: TemplateCategory.habits,
    baseColor: BaseColors.teal,
    levels: [
      MapLevel(label: '@l_no', color: Color(0xFFE6E4DE)),
      MapLevel(label: '@l_yes', color: Color(0xFF3FAF9E)),
    ],
  ),
  MapTemplate(
    id: 'reading',
    category: TemplateCategory.habits,
    baseColor: BaseColors.brown,
    levels: [
      MapLevel(label: '@l_no', color: Color(0xFFE6E4DE)),
      MapLevel(label: '@l_rd_1', color: Color(0xFFD5B8A2)),
      MapLevel(label: '@l_rd_2', color: Color(0xFF9C6B4A)),
    ],
  ),
  MapTemplate(
    id: 'screen',
    category: TemplateCategory.habits,
    baseColor: BaseColors.graphite,
    levels: [
      MapLevel(label: '@l_sc_0', color: Color(0xFFE6E4DE)),
      MapLevel(label: '@l_sc_1', color: Color(0xFFB4B4B9)),
      MapLevel(label: '@l_sc_2', color: Color(0xFF6B6B72)),
    ],
  ),
  MapTemplate(
    id: 'water',
    category: TemplateCategory.habits,
    baseColor: BaseColors.sky,
    levels: [
      MapLevel(label: '@l_wa_0', color: Color(0xFFEAF2FA)),
      MapLevel(label: '@l_wa_1', color: Color(0xFFA9CBEB)),
      MapLevel(label: '@l_wa_2', color: Color(0xFF4F94D6)),
    ],
  ),
];

MapTemplate templateById(String id) =>
    kTemplates.firstWhere((t) => t.id == id, orElse: () => kTemplates.first);

/// Builds a blank custom map with a base colour and generic levels.
PixMap customMap(String id, Color base) => PixMap(
      id: id,
      title: '',
      question: '',
      baseColor: base,
      levels: [
        const MapLevel(label: '@l_low', color: Color(0xFFE6E4DE)),
        MapLevel(label: '@l_mid', color: Color.lerp(Colors.white, base, 0.55)!),
        MapLevel(label: '@l_high', color: base),
      ],
      templateId: 'custom',
      category: 'custom',
      createdAt: DateTime.now(),
    );
