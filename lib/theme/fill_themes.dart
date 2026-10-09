import 'package:flutter/material.dart';

/// Theme + tile-style catalog for Color Fill.
///
/// Every theme lives in a physical material world (wood, felt, ceramic,
/// stone, enamel paint) — the flood tiles always feel like real game pieces.
/// No neon, no cyberpunk, no generic AI-dashboard looks.
class FillThemeDef {
  final String id;
  final String name;
  final bool pro;
  final Color tableDark; // backdrop, deep
  final Color tableMid; // backdrop, lighter
  final Color trayLight; // board tray face
  final Color trayDark; // board tray edge
  final Color accent; // buttons / highlights
  final Color accentDark;
  final Color text;
  final Color textSoft;
  final List<Color> palette; // 8 enamel colors; games use the first N
  final List<String> paletteNames;

  const FillThemeDef({
    required this.id,
    required this.name,
    this.pro = false,
    required this.tableDark,
    required this.tableMid,
    required this.trayLight,
    required this.trayDark,
    required this.accent,
    required this.accentDark,
    required this.text,
    required this.textSoft,
    required this.palette,
    required this.paletteNames,
  });
}

class FillThemes {
  /// The first 4 themes are FREE. The rest (incl. 'custom') are PRO.
  static const List<String> freeThemeIds = [
    'toybox',
    'cherry',
    'seaglass',
    'orchard',
  ];

  static bool isProTheme(String id) =>
      id != 'custom' && !freeThemeIds.contains(id);

  static const List<FillThemeDef> all = [
    FillThemeDef(
      id: 'toybox',
      name: 'Toybox Classic',
      tableDark: Color(0xFF3E2A1A),
      tableMid: Color(0xFF5C3A21),
      trayLight: Color(0xFF8A5A33),
      trayDark: Color(0xFF4E3018),
      accent: Color(0xFFD9A441),
      accentDark: Color(0xFF9A6F24),
      text: Color(0xFFFFF3DE),
      textSoft: Color(0xFFD9BE96),
      palette: [
        Color(0xFFE5484D),
        Color(0xFFFF9F2E),
        Color(0xFFFFD60A),
        Color(0xFF30B158),
        Color(0xFF2E9BF0),
        Color(0xFF9B6BF3),
        Color(0xFF2EC4B6),
        Color(0xFFF26D9D),
      ],
      paletteNames: [
        'Cherry',
        'Apricot',
        'Lemon',
        'Leaf',
        'Sky',
        'Grape',
        'Lagoon',
        'Rose'
      ],
    ),
    FillThemeDef(
      id: 'cherry',
      name: 'Cherry Workshop',
      tableDark: Color(0xFF33160D),
      tableMid: Color(0xFF572417),
      trayLight: Color(0xFF7C3A22),
      trayDark: Color(0xFF42190D),
      accent: Color(0xFFE0B34C),
      accentDark: Color(0xFF9C7A2E),
      text: Color(0xFFFFF1DC),
      textSoft: Color(0xFFD8B98E),
      palette: [
        Color(0xFFD63A3A),
        Color(0xFFE8813A),
        Color(0xFFF2C230),
        Color(0xFF4E9B4E),
        Color(0xFF3A7BD5),
        Color(0xFF7E5AC9),
        Color(0xFF3FA796),
        Color(0xFFD96C8A),
      ],
      paletteNames: [
        'Brick',
        'Ember',
        'Harvest',
        'Moss',
        'Denim',
        'Plum',
        'Sage',
        'Blush'
      ],
    ),
    FillThemeDef(
      id: 'seaglass',
      name: 'Sea Glass',
      tableDark: Color(0xFF1E3A3A),
      tableMid: Color(0xFF2F5450),
      trayLight: Color(0xFF4E7A72),
      trayDark: Color(0xFF243F3B),
      accent: Color(0xFFE8C86A),
      accentDark: Color(0xFFA8894A),
      text: Color(0xFFF2F7EC),
      textSoft: Color(0xFFBFD4C4),
      palette: [
        Color(0xFFDE5B5B),
        Color(0xFFF09A4B),
        Color(0xFFF2D06B),
        Color(0xFF5FB878),
        Color(0xFF4E9FD1),
        Color(0xFF8A72C9),
        Color(0xFF4FC3B8),
        Color(0xFFE88CA0),
      ],
      paletteNames: [
        'Coral',
        'Shell',
        'Sand',
        'Kelp',
        'Wave',
        'Iris',
        'Foam',
        'Pearl'
      ],
    ),
    FillThemeDef(
      id: 'orchard',
      name: 'Orchard',
      tableDark: Color(0xFF2C3A1E),
      tableMid: Color(0xFF44582C),
      trayLight: Color(0xFF6B8143),
      trayDark: Color(0xFF33411F),
      accent: Color(0xFFE8B84B),
      accentDark: Color(0xFFA07E2E),
      text: Color(0xFFF6F3E2),
      textSoft: Color(0xFFCBD2A6),
      palette: [
        Color(0xFFD94F3D),
        Color(0xFFE8933C),
        Color(0xFFF5CF4A),
        Color(0xFF6BAE4E),
        Color(0xFF4A90C9),
        Color(0xFF9A6BC4),
        Color(0xFF43B8A4),
        Color(0xFFE07E9A),
      ],
      paletteNames: [
        'Apple',
        'Peach',
        'Hay',
        'Clover',
        'Rain',
        'Lilac',
        'Mint',
        'Berry'
      ],
    ),
    FillThemeDef(
      id: 'terracotta',
      name: 'Terracotta',
      pro: true,
      tableDark: Color(0xFF40200F),
      tableMid: Color(0xFF63331A),
      trayLight: Color(0xFF8F4E28),
      trayDark: Color(0xFF4A2410),
      accent: Color(0xFFF0C25E),
      accentDark: Color(0xFFA8823C),
      text: Color(0xFFFFF0D8),
      textSoft: Color(0xFFDDBB92),
      palette: [
        Color(0xFFC4452B),
        Color(0xFFE07B39),
        Color(0xFFF0BE4E),
        Color(0xFF7A9B3F),
        Color(0xFF3E7CA8),
        Color(0xFF7D5BA6),
        Color(0xFF4AA394),
        Color(0xFFD4698A),
      ],
      paletteNames: [
        'Clay',
        'Paprika',
        'Saffron',
        'Olive',
        'Indigo',
        'Fig',
        'Eucalyptus',
        'Hibiscus'
      ],
    ),
    FillThemeDef(
      id: 'slate',
      name: 'Slate Studio',
      pro: true,
      tableDark: Color(0xFF23262B),
      tableMid: Color(0xFF363B42),
      trayLight: Color(0xFF525A64),
      trayDark: Color(0xFF2A2E34),
      accent: Color(0xFFE0B45C),
      accentDark: Color(0xFF9C7E3E),
      text: Color(0xFFF4F1E8),
      textSoft: Color(0xFFB9BDC4),
      palette: [
        Color(0xFFC9504A),
        Color(0xFFDD8A45),
        Color(0xFFE8C44F),
        Color(0xFF5FA86B),
        Color(0xFF4F96CC),
        Color(0xFF8B74C7),
        Color(0xFF4FB5AE),
        Color(0xFFD67E96),
      ],
      paletteNames: [
        'Signal',
        'Amber',
        'Brass',
        'Fern',
        'Steel',
        'Violet',
        'Teal',
        'Dusty Rose'
      ],
    ),
    FillThemeDef(
      id: 'honey',
      name: 'Honeycomb',
      pro: true,
      tableDark: Color(0xFF3A2A10),
      tableMid: Color(0xFF5A4418),
      trayLight: Color(0xFF85632A),
      trayDark: Color(0xFF463313),
      accent: Color(0xFFFFD873),
      accentDark: Color(0xFFB8943F),
      text: Color(0xFFFFF6DE),
      textSoft: Color(0xFFE3C98C),
      palette: [
        Color(0xFFD6563F),
        Color(0xFFF08A35),
        Color(0xFFFFD23F),
        Color(0xFF7FB069),
        Color(0xFF4D96D9),
        Color(0xFF9B72CF),
        Color(0xFF45C4B0),
        Color(0xFFF2789F),
      ],
      paletteNames: [
        'Cinnamon',
        'Caramel',
        'Honey',
        'Pistachio',
        'Blueberry',
        'Lavender',
        'Mint Leaf',
        'Raspberry'
      ],
    ),
    FillThemeDef(
      id: 'porcelain',
      name: 'Porcelain',
      pro: true,
      tableDark: Color(0xFF2E3440),
      tableMid: Color(0xFF434C5E),
      trayLight: Color(0xFFD8DEE9),
      trayDark: Color(0xFF4C566A),
      accent: Color(0xFFBF9B5F),
      accentDark: Color(0xFF8A6C40),
      text: Color(0xFFF6F2E8),
      textSoft: Color(0xFFC3C9D4),
      palette: [
        Color(0xFFC25E5E),
        Color(0xFFD98E5F),
        Color(0xFFE5C76B),
        Color(0xFF6FA287),
        Color(0xFF5E8FC0),
        Color(0xFF8E7BB8),
        Color(0xFF63B3A8),
        Color(0xFFD28A9B),
      ],
      paletteNames: [
        'Glaze Red',
        'Biscuit',
        'Celadon Gold',
        'Jade',
        'Cobalt',
        'Wisteria',
        'Aqua',
        'Peony'
      ],
    ),
    FillThemeDef(
      id: 'forest',
      name: 'Forest Cabin',
      pro: true,
      tableDark: Color(0xFF1F2A16),
      tableMid: Color(0xFF33431F),
      trayLight: Color(0xFF52662E),
      trayDark: Color(0xFF27331A),
      accent: Color(0xFFE8C25E),
      accentDark: Color(0xFFA08640),
      text: Color(0xFFF4F2E0),
      textSoft: Color(0xFFBCC79A),
      palette: [
        Color(0xFFC9503F),
        Color(0xFFDE8A3E),
        Color(0xFFE8C545),
        Color(0xFF5FA04A),
        Color(0xFF4588BE),
        Color(0xFF8666B8),
        Color(0xFF45A893),
        Color(0xFFCC6E8C),
      ],
      paletteNames: [
        'Rowan',
        'Acorn',
        'Birch',
        'Pine',
        'Lake',
        'Heather',
        'Brook',
        'Thistle'
      ],
    ),
    FillThemeDef(
      id: 'desert',
      name: 'Desert Dusk',
      pro: true,
      tableDark: Color(0xFF3B2417),
      tableMid: Color(0xFF5C3E24),
      trayLight: Color(0xFF8A6136),
      trayDark: Color(0xFF4A2F18),
      accent: Color(0xFFF2CD6B),
      accentDark: Color(0xFFA98A44),
      text: Color(0xFFFFF2DC),
      textSoft: Color(0xFFD9BE92),
      palette: [
        Color(0xFFD05540),
        Color(0xFFE88A45),
        Color(0xFFF5CE5E),
        Color(0xFF7FA653),
        Color(0xFF4E94C4),
        Color(0xFF9370C0),
        Color(0xFF4AB5A0),
        Color(0xFFDB7E92),
      ],
      paletteNames: [
        'Canyon',
        'Mesa',
        'Dune',
        'Agave',
        'Twilight',
        'Sage Bloom',
        'Oasis',
        'Prickly Pear'
      ],
    ),
    FillThemeDef(
      id: 'cocoa',
      name: 'Midnight Cocoa',
      pro: true,
      tableDark: Color(0xFF241611),
      tableMid: Color(0xFF3B251B),
      trayLight: Color(0xFF5C3D29),
      trayDark: Color(0xFF2C1B13),
      accent: Color(0xFFE3B968),
      accentDark: Color(0xFF9D7F45),
      text: Color(0xFFF9F0E0),
      textSoft: Color(0xFFCBB08E),
      palette: [
        Color(0xFFD65A50),
        Color(0xFFE8934E),
        Color(0xFFF2CE6B),
        Color(0xFF6FB377),
        Color(0xFF5C9BD4),
        Color(0xFF9B7BD1),
        Color(0xFF55BFAE),
        Color(0xFFE08CA2),
      ],
      paletteNames: [
        'Chili',
        'Toffee',
        'Nougat',
        'Pistachio',
        'Midnight Blue',
        'Truffle',
        'Eucalyptus',
        'Raspberry Cream'
      ],
    ),
    FillThemeDef(
      id: 'meadowfest',
      name: 'Meadow Festival',
      pro: true,
      tableDark: Color(0xFF2E3B1E),
      tableMid: Color(0xFF4C5E2E),
      trayLight: Color(0xFF6E8445),
      trayDark: Color(0xFF39451F),
      accent: Color(0xFFF0C95E),
      accentDark: Color(0xFFA68A3E),
      text: Color(0xFFF7F4E2),
      textSoft: Color(0xFFCCD2A4),
      palette: [
        Color(0xFFDE5B4B),
        Color(0xFFF0963F),
        Color(0xFFF7D154),
        Color(0xFF6DB35A),
        Color(0xFF4FA0D8),
        Color(0xFFA179D4),
        Color(0xFF4CC6B2),
        Color(0xFFF07FA3),
      ],
      paletteNames: [
        'Poppy',
        'Marigold',
        'Sunbeam',
        'Meadow',
        'Cornflower',
        'Orchid',
        'Dragonfly',
        'Zinnia'
      ],
    ),
  ];

  static FillThemeDef byId(String id, {required FillThemeDef custom}) {
    if (id == 'custom') return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

/// Physical tile styles. First 4 are FREE; the rest are PRO.
class TileStyles {
  static const List<String> names = [
    'Rounded',
    'Pebble',
    'Wood Block',
    'Marble',
    'Candy',
    'Ceramic',
    'Slate',
    'Pillow',
  ];

  static const List<String> blurbs = [
    'Classic chunky game tiles',
    'Smooth river-stone discs',
    'Grain-cut wooden blocks',
    'Polished stone with veins',
    'Glossy sugar-coated drops',
    'Hand-glazed pottery squares',
    'Rough-hewn rock slabs',
    'Soft plush cushions',
  ];

  static bool isPro(int i) => i >= 4;
}
