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

/// Base colours ("Grundfarben") – the glow colour of each map. A soft,
/// harmonious family: every hue sits at a similar lightness/saturation so
/// maps look good next to each other.
class BaseColors {
  BaseColors._();
  static const plum = Color(0xFF8C6FDB);
  static const midnight = Color(0xFF4A52A8);
  static const sky = Color(0xFF5E98C9);
  static const sage = Color(0xFF74AE66);
  static const coral = Color(0xFFE58D72);
  static const amber = Color(0xFFDFA24A);
  static const rose = Color(0xFFD9819F);
  static const teal = Color(0xFF3E9E8F);
  static const peach = Color(0xFFEE9A62);
  static const cocoa = Color(0xFF9A6B4E);
  static const indigo = Color(0xFF6A70C0);
  static const berry = Color(0xFFC2506A);
  static const slate = Color(0xFF737C8F);

  // Old names kept for existing code.
  static const violet = plum;
  static const black = midnight;
  static const green = sage;
  static const gold = amber;
  static const orange = peach;
  static const brown = cocoa;
  static const red = berry;
  static const graphite = slate;

  static const List<Color> palette = [
    plum, midnight, indigo, sky, teal, sage, amber, peach, coral, rose, berry, cocoa, slate,
  ];
}

const List<MapTemplate> kTemplates = [
  MapTemplate(
    id: 'mood',
    category: TemplateCategory.feelings,
    baseColor: BaseColors.plum,
    levels: [
      MapLevel(label: '@l_mood_0', color: Color(0xFF3F3B6E)),
      MapLevel(label: '@l_mood_1', color: Color(0xFF8A86B3)),
      MapLevel(label: '@l_mood_2', color: Color(0xFFCBC2EC)),
      MapLevel(label: '@l_mood_3', color: Color(0xFF9A7BE3)),
      MapLevel(label: '@l_mood_4', color: Color(0xFFE4A3D6)),
    ],
  ),
  MapTemplate(
    id: 'cry',
    category: TemplateCategory.feelings,
    baseColor: BaseColors.sky,
    catId: 'sad',
    levels: [
      MapLevel(label: '@l_cry_0', color: Color(0xFFE6EFF5)),
      MapLevel(label: '@l_cry_1', color: Color(0xFFA8CBE2)),
      MapLevel(label: '@l_cry_2', color: Color(0xFF5E98C9)),
      MapLevel(label: '@l_cry_3', color: Color(0xFF2E5B8F)),
    ],
  ),
  MapTemplate(
    id: 'anxiety',
    category: TemplateCategory.feelings,
    baseColor: BaseColors.indigo,
    levels: [
      MapLevel(label: '@l_anx_0', color: Color(0xFFE7E8F4)),
      MapLevel(label: '@l_anx_1', color: Color(0xFFB5BADF)),
      MapLevel(label: '@l_anx_2', color: Color(0xFF7A80C4)),
      MapLevel(label: '@l_anx_3', color: Color(0xFF3C4192)),
    ],
  ),
  MapTemplate(
    id: 'social',
    category: TemplateCategory.feelings,
    baseColor: BaseColors.rose,
    levels: [
      MapLevel(label: '@l_soc_0', color: Color(0xFFF4E4EA)),
      MapLevel(label: '@l_soc_1', color: Color(0xFFEBB9CB)),
      MapLevel(label: '@l_soc_2', color: Color(0xFFD9819F)),
      MapLevel(label: '@l_soc_3', color: Color(0xFFA94E72)),
    ],
  ),
  MapTemplate(
    id: 'gratitude',
    category: TemplateCategory.feelings,
    baseColor: BaseColors.amber,
    levels: [
      MapLevel(label: '@l_gr_0', color: Color(0xFFEFE9DF)),
      MapLevel(label: '@l_gr_1', color: Color(0xFFF1CF8C)),
      MapLevel(label: '@l_gr_2', color: Color(0xFFDFA24A)),
    ],
  ),
  MapTemplate(
    id: 'dreams',
    category: TemplateCategory.body,
    baseColor: BaseColors.midnight,
    catId: 'sleep',
    levels: [
      MapLevel(label: '@l_dr_0', color: Color(0xFFE9E7F0)),
      MapLevel(label: '@l_dr_1', color: Color(0xFFABC0E6)),
      MapLevel(label: '@l_dr_2', color: Color(0xFF6E7FD6)),
      MapLevel(label: '@l_dr_3', color: Color(0xFF9C73D2)),
      MapLevel(label: '@l_dr_4', color: Color(0xFFE39DC4)),
      MapLevel(label: '@l_dr_5', color: Color(0xFF2A2546)),
    ],
  ),
  MapTemplate(
    id: 'sleep',
    category: TemplateCategory.body,
    baseColor: BaseColors.midnight,
    catId: 'sleep',
    levels: [
      MapLevel(label: '@l_sl_0', color: Color(0xFFECE8F1)),
      MapLevel(label: '@l_sl_1', color: Color(0xFFB9BFDC)),
      MapLevel(label: '@l_sl_2', color: Color(0xFF7E8AC2)),
      MapLevel(label: '@l_sl_3', color: Color(0xFF465298)),
      MapLevel(label: '@l_sl_4', color: Color(0xFF1F2553)),
    ],
  ),
  MapTemplate(
    id: 'energy',
    category: TemplateCategory.body,
    baseColor: BaseColors.peach,
    levels: [
      MapLevel(label: '@l_en_0', color: Color(0xFFF3E7DD)),
      MapLevel(label: '@l_en_1', color: Color(0xFFF3C8A6)),
      MapLevel(label: '@l_en_2', color: Color(0xFFEE9A62)),
      MapLevel(label: '@l_en_3', color: Color(0xFFC9612E)),
    ],
  ),
  MapTemplate(
    id: 'period',
    category: TemplateCategory.body,
    baseColor: BaseColors.berry,
    levels: [
      MapLevel(label: '@l_pe_0', color: Color(0xFFEFE6E8)),
      MapLevel(label: '@l_pe_1', color: Color(0xFFF1C4CB)),
      MapLevel(label: '@l_pe_2', color: Color(0xFFE08A99)),
      MapLevel(label: '@l_pe_3', color: Color(0xFFC2506A)),
      MapLevel(label: '@l_pe_4', color: Color(0xFF8C2745)),
    ],
  ),
  MapTemplate(
    id: 'pain',
    category: TemplateCategory.body,
    baseColor: BaseColors.coral,
    levels: [
      MapLevel(label: '@l_pa_0', color: Color(0xFFF1E8E3)),
      MapLevel(label: '@l_pa_1', color: Color(0xFFF4C8B8)),
      MapLevel(label: '@l_pa_2', color: Color(0xFFE58D72)),
      MapLevel(label: '@l_pa_3', color: Color(0xFFB5503A)),
    ],
  ),
  MapTemplate(
    id: 'training',
    category: TemplateCategory.habits,
    baseColor: BaseColors.sage,
    catId: 'gym',
    levels: [
      MapLevel(label: '@l_tr_0', color: Color(0xFFE7EDE2)),
      MapLevel(label: '@l_tr_1', color: Color(0xFFB9D5A6)),
      MapLevel(label: '@l_tr_2', color: Color(0xFF74AE66)),
      MapLevel(label: '@l_tr_3', color: Color(0xFF3D7A45)),
    ],
  ),
  MapTemplate(
    id: 'alcohol',
    category: TemplateCategory.habits,
    baseColor: BaseColors.amber,
    levels: [
      MapLevel(label: '@l_al_0', color: Color(0xFFEFE9DF)),
      MapLevel(label: '@l_al_1', color: Color(0xFFF1D59B)),
      MapLevel(label: '@l_al_2', color: Color(0xFFDDA24B)),
      MapLevel(label: '@l_al_3', color: Color(0xFFA8672A)),
    ],
  ),
  MapTemplate(
    id: 'meditation',
    catId: 'meditation',
    category: TemplateCategory.habits,
    baseColor: BaseColors.teal,
    levels: [
      MapLevel(label: '@l_me_0', color: Color(0xFFE3EEEC)),
      MapLevel(label: '@l_me_1', color: Color(0xFF9FD3C9)),
      MapLevel(label: '@l_me_2', color: Color(0xFF3E9E8F)),
    ],
  ),
  MapTemplate(
    id: 'reading',
    category: TemplateCategory.habits,
    baseColor: BaseColors.cocoa,
    levels: [
      MapLevel(label: '@l_rd_0', color: Color(0xFFEEE7E1)),
      MapLevel(label: '@l_rd_1', color: Color(0xFFD6B9A3)),
      MapLevel(label: '@l_rd_2', color: Color(0xFF9A6B4E)),
    ],
  ),
  MapTemplate(
    id: 'screen',
    category: TemplateCategory.habits,
    baseColor: BaseColors.slate,
    levels: [
      MapLevel(label: '@l_sc_0', color: Color(0xFFE6E8EC)),
      MapLevel(label: '@l_sc_1', color: Color(0xFFB4BAC6)),
      MapLevel(label: '@l_sc_2', color: Color(0xFF737C8F)),
      MapLevel(label: '@l_sc_3', color: Color(0xFF3E4556)),
    ],
  ),
  MapTemplate(
    id: 'water',
    catId: 'water',
    category: TemplateCategory.habits,
    baseColor: BaseColors.sky,
    levels: [
      MapLevel(label: '@l_wa_0', color: Color(0xFFEAF0F5)),
      MapLevel(label: '@l_wa_1', color: Color(0xFFA8CBE2)),
      MapLevel(label: '@l_wa_2', color: Color(0xFF5E98C9)),
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
      catId: 'neutral',
      createdAt: DateTime.now(),
    );
