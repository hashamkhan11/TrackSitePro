// schedule_of_rates.dart

class SORItem {
  final String? id;
  final String code;
  final String description;
  final String unit;
  final double rate;
  final String category; // New field for category

  const SORItem({
    this.id,
    required this.code,
    required this.description,
    required this.unit,
    required this.rate,
    required this.category,
  });
   // Create a copyWith method for updates
  SORItem copyWith({
    String? id,
    String? code,
    String? description,
    String? unit,
    double? rate,
    String? category,
  }) {
    return SORItem(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      category: category ?? this.category,
    );
  }
   // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'description': description,
      'unit': unit,
      'rate': rate,
      'category': category,
    };
  }

  // Create from Firebase document
  factory SORItem.fromFirestore(String id, Map<String, dynamic> data) {
    return SORItem(
      id: id,
      code: data['code'] ?? '',
      description: data['description'] ?? '',
      unit: data['unit'] ?? '',
      rate: (data['rate'] ?? 0).toDouble(),
      category: data['category'] ?? ScheduleOfRates.CATEGORY_CUSTOM,
    );
  }

}


class ScheduleOfRates {
  // Dynamic list for custom user-added SOR items
  static final List<SORItem> customRates = [];

  // Category constants
  static const String CATEGORY_X = 'X: Ditching, Backfilling & Reinstatement';
  static const String CATEGORY_B = 'B: Brick Laying over PE Pipe';
  static const String CATEGORY_C = 'C: Cleaning, Coating & Wrapping';
  static const String CATEGORY_P = 'P: MS Pipe Laying';
  static const String CATEGORY_V = 'V: Valve Pits & Covers';
  static const String CATEGORY_W = 'W: Welding';
  static const String CATEGORY_PE = 'PE: Polyethylene Pipe Laying';
  static const String CATEGORY_BR = 'BR: Boring';
  static const String CATEGORY_RCB = 'RCB: Road Cutting & Breaking';
  static const String CATEGORY_TT = 'TT: Tuff Tile';
  static const String CATEGORY_L = 'L: Labour Supply';
  static const String CATEGORY_CUSTOM = 'Custom: User Added';

  // Get all categories
  static List<String> getAllCategories() {
    return [
      CATEGORY_X,
      CATEGORY_B,
      CATEGORY_C,
      CATEGORY_P,
      CATEGORY_V,
      CATEGORY_W,
      CATEGORY_PE,
      CATEGORY_BR,
      CATEGORY_RCB,
      CATEGORY_TT,
      CATEGORY_L,
      CATEGORY_CUSTOM,
    ];
  }

  // Category X: Ditching, Backfilling & Reinstatement
  static const List<SORItem> categoryX = [
    SORItem(
      code: 'X-1-a',
      description: 'Ditching and Backfilling in Soft Soil (35% deduction in case of no backfilling)',
      unit: 'cu.m',
      rate: 508,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-1-b',
      description: 'Ditching and Backfilling in Hard Soil (27% deduction in case of no backfilling)',
      unit: 'cu.m',
      rate: 763,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-1-c',
      description: 'Ditching and Backfilling in solid rock (20% deduction in case of no backfilling)',
      unit: 'cu.m',
      rate: 1143,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-1-d',
      description: 'Ditching and Backfilling in dynamiting solid rock (14% deduction in case of no backfilling)',
      unit: 'cu.m',
      rate: 1714,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-1-e',
      description: 'Sand Filling',
      unit: 'Cu m',
      rate: 2200,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-2-a',
      description: 'Reinstatement of First class Tar road',
      unit: 'sq. m',
      rate: 3392,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-2-b',
      description: 'Reinstatement of Second Class Tar Road',
      unit: 'sq. m',
      rate: 2544,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-3-a',
      description: 'Reinstatement of P.C.C. Pavement 6-inch thick layer with 1:2:4 ratio',
      unit: 'sq. m',
      rate: 2393,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-3-b',
      description: 'Reinstatement of P.C.C. Pavement 4-inch thick layer with 1:2:4 ratio',
      unit: 'sq. m',
      rate: 1659,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-4-a',
      description: 'Brick Paving On Edge with 50% new bricks with sand base using ratio 1:4',
      unit: 'sq. m',
      rate: 938,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-4-a1',
      description: 'Brick Paving on edge with 50% new bricks and without Sand base',
      unit: 'sq. m',
      rate: 867,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-4-a2',
      description: 'Brick Paving on edge with Old bricks and with Sand Base',
      unit: 'sq. m',
      rate: 380,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-4-a3',
      description: 'Brick Paving on edge with Old bricks and without Sand Base',
      unit: 'sq. m',
      rate: 307,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-4-b',
      description: 'Brick Paving flat with 50% new bricks with sand base',
      unit: 'sq. m',
      rate: 628,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-4-b1',
      description: 'Brick Paving Flat with 50% new bricks and without sand base',
      unit: 'sq. m',
      rate: 557,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-4-b2',
      description: 'Brick Paving Flat with old bricks and with sand base',
      unit: 'sq. m',
      rate: 256,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-4-b3',
      description: 'Brick Paving Flat with Old Bricks and Without Sand Base',
      unit: 'sq. m',
      rate: 185,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-5-a',
      description: 'Brick Soling on Edge with 50% new bricks and with sand base',
      unit: 'sq. m',
      rate: 814,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-5-a1',
      description: 'Brick Soling on edge with 50% New bricks and without sand base',
      unit: 'sq. m',
      rate: 743,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-5-a2',
      description: 'Brick Soling on edge with old bricks and with sand base',
      unit: 'sq. m',
      rate: 256,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-5-a3',
      description: 'Brick Soling on edge with old bricks and without sand base',
      unit: 'sq. m',
      rate: 186,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-5-b',
      description: 'Brick Soling Flat with 50% new bricks and with sand base',
      unit: 'sq. m',
      rate: 567,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-5-b1',
      description: 'Brick Soling Flat with 50% new bricks & without sand base',
      unit: 'sq. m',
      rate: 495,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-5-b2',
      description: 'Brick Soling Flat with old bricks and with sand base',
      unit: 'sq. m',
      rate: 195,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-5-b3',
      description: 'Brick soling Flat with old bricks and without sand base',
      unit: 'sq. m',
      rate: 123,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-6',
      description: 'Brick Masonary',
      unit: 'cu. m',
      rate: 17278,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-7-a',
      description: 'P.C.C. (1:2:4)',
      unit: 'cu. m',
      rate: 18200,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-7-b',
      description: 'P.C.C. (1:5:10)',
      unit: 'cu. m',
      rate: 14462,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-8',
      description: 'Cement Plaster (1:3)',
      unit: 'sq. m',
      rate: 470,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-9',
      description: 'M. S. Reinforcement including Fabrication.',
      unit: 'kg',
      rate: 392,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-10-a',
      description: 'Brick Paving on Edge With 100% New Bricks',
      unit: 'sq. m',
      rate: 1496,
      category: CATEGORY_X,
    ),
    SORItem(
      code: 'X-10-b',
      description: 'Brick Paving Flat With 100% New Bricks',
      unit: 'sq. m',
      rate: 1000,
      category: CATEGORY_X,
    ),
  ];

  // Category B: Brick Laying over PE Pipe
  static const List<SORItem> categoryB = [
    SORItem(
      code: 'B-1',
      description: 'Brick Laying over Polyethylene Pipe, 3/4, 1, 2, 4 inch dia. for Bahawalpur, Multan, Sahiwal, Faisalabad & Sargodha',
      unit: 'm',
      rate: 163,
      category: CATEGORY_B,
    ),
    SORItem(
      code: 'B-2',
      description: 'Brick Laying over Polyethylene Pipe, 3/4, 1, 2, 4 inch dia. For Lahore, Sheikhupura, Sialkot, Gujranwala, Gujrat, Peshawar & Mardan',
      unit: 'm',
      rate: 200,
      category: CATEGORY_B,
    ),
    SORItem(
      code: 'B-3',
      description: 'Plant Bricks laying over Polyethylene Pipe for all Region',
      unit: 'm',
      rate: 173,
      category: CATEGORY_B,
    ),
    SORItem(
      code: 'B-4',
      description: 'Brick Laying over Polyethylene Pipe, 3/4, 1, 2, 4 inch dia. For Islamabad, Rawalpindi & Abbottabad Region',
      unit: 'm',
      rate: 206,
      category: CATEGORY_B,
    ),
  ];

  // Category C: Cleaning, Coating & Wrapping
  static const List<SORItem> categoryC = [
    SORItem(
      code: 'C-1-3/4-1',
      description: 'Cleaning, Coating & Wrapping of Steel Pipes (3/4" & 1")',
      unit: 'm',
      rate: 36,
      category: CATEGORY_C,
    ),
    SORItem(
      code: 'C-1-2',
      description: 'Cleaning, Coating & Wrapping of Steel Pipes (2")',
      unit: 'm',
      rate: 50,
      category: CATEGORY_C,
    ),
  ];

  // Category P: MS Pipe Laying
  static const List<SORItem> categoryP = [
    SORItem(
      code: 'P-1-a',
      description: 'Pipe laying of short service line in soft soil (3/4", 1" and 2") including cost of fire wood',
      unit: 'Short Service Line',
      rate: 1713,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-1-b',
      description: 'Pipe laying of short service line in hard/rocky soil (3/4", 1" and 2") including cost of fire wood',
      unit: 'Short Service Line',
      rate: 2570,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-2-3/4-1-2',
      description: 'Pipe Laying in Soft Soil including cost of fire wood (3/4", 1", 2")',
      unit: 'm',
      rate: 319,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-2-4',
      description: 'Pipe Laying in Soft Soil including cost of fire wood (4")',
      unit: 'm',
      rate: 432,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-2-6',
      description: 'Pipe Laying in Soft Soil including cost of fire wood (6")',
      unit: 'm',
      rate: 445,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-2-8',
      description: 'Pipe Laying in Soft Soil including cost of fire wood (8")',
      unit: 'm',
      rate: 506,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-2-10',
      description: 'Pipe Laying in Soft Soil including cost of fire wood (10")',
      unit: 'm',
      rate: 588,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-2-12',
      description: 'Pipe Laying in Soft Soil including cost of fire wood (12")',
      unit: 'm',
      rate: 609,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-2-16',
      description: 'Pipe Laying in Soft Soil including cost of fire wood (16")',
      unit: 'm',
      rate: 755,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-3-3/4-1-2',
      description: 'Pipe Laying In Hard / Rocky Soil including cost of fire wood (3/4", 1", 2")',
      unit: 'm',
      rate: 442,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-3-4',
      description: 'Pipe Laying In Hard / Rocky Soil including cost of fire wood (4")',
      unit: 'm',
      rate: 620,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-3-6',
      description: 'Pipe Laying In Hard / Rocky Soil including cost of fire wood (6")',
      unit: 'm',
      rate: 634,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-3-8',
      description: 'Pipe Laying In Hard / Rocky Soil including cost of fire wood (8")',
      unit: 'm',
      rate: 732,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-3-10',
      description: 'Pipe Laying In Hard / Rocky Soil including cost of fire wood (10")',
      unit: 'm',
      rate: 830,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-3-12',
      description: 'Pipe Laying In Hard / Rocky Soil including cost of fire wood (12")',
      unit: 'm',
      rate: 849,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-3-16',
      description: 'Pipe Laying In Hard / Rocky Soil including cost of fire wood (16")',
      unit: 'm',
      rate: 1051,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-4-3/4-1-2',
      description: 'Pipe Laying in Solid Rock including cost of fire wood (3/4", 1", 2")',
      unit: 'm',
      rate: 652,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-4-4',
      description: 'Pipe Laying in Solid Rock including cost of fire wood (4")',
      unit: 'm',
      rate: 903,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-4-6',
      description: 'Pipe Laying in Solid Rock including cost of fire wood (6")',
      unit: 'm',
      rate: 917,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-4-8',
      description: 'Pipe Laying in Solid Rock including cost of fire wood (8")',
      unit: 'm',
      rate: 1035,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-4-10',
      description: 'Pipe Laying in Solid Rock including cost of fire wood (10")',
      unit: 'm',
      rate: 1189,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-4-12',
      description: 'Pipe Laying in Solid Rock including cost of fire wood (12")',
      unit: 'm',
      rate: 1207,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-4-16',
      description: 'Pipe Laying in Solid Rock including cost of fire wood (16")',
      unit: 'm',
      rate: 1493,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-a-3/4-1-2',
      description: 'Pipe laying and reinstatement in first class Tar Road including cost of fire wood (3/4", 1", 2")',
      unit: 'm',
      rate: 2252,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-a-4',
      description: 'Pipe laying and reinstatement in first class Tar Road including cost of fire wood (4")',
      unit: 'm',
      rate: 2947,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-a-6',
      description: 'Pipe laying and reinstatement in first class Tar Road including cost of fire wood (6")',
      unit: 'm',
      rate: 2960,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-a-8',
      description: 'Pipe laying and reinstatement in first class Tar Road including cost of fire wood (8")',
      unit: 'm',
      rate: 3058,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-a-10',
      description: 'Pipe laying and reinstatement in first class Tar Road including cost of fire wood (10")',
      unit: 'm',
      rate: 3415,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-a-12',
      description: 'Pipe laying and reinstatement in first class Tar Road including cost of fire wood (12")',
      unit: 'm',
      rate: 3433,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-a-16',
      description: 'Pipe laying and reinstatement in first class Tar Road including cost of fire wood (16")',
      unit: 'm',
      rate: 3894,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-b-3/4-1-2',
      description: 'Pipe laying and reinstatement in second class Tar Road including cost of fire wood (3/4", 1", 2")',
      unit: 'm',
      rate: 1689,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-b-4',
      description: 'Pipe laying and reinstatement in second class Tar Road including cost of fire wood (4")',
      unit: 'm',
      rate: 2210,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-b-6',
      description: 'Pipe laying and reinstatement in second class Tar Road including cost of fire wood (6")',
      unit: 'm',
      rate: 2220,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-b-8',
      description: 'Pipe laying and reinstatement in second class Tar Road including cost of fire wood (8")',
      unit: 'm',
      rate: 2293,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-b-10',
      description: 'Pipe laying and reinstatement in second class Tar Road including cost of fire wood (10")',
      unit: 'm',
      rate: 2561,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-b-12',
      description: 'Pipe laying and reinstatement in second class Tar Road including cost of fire wood (12")',
      unit: 'm',
      rate: 2575,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-5-b-16',
      description: 'Pipe laying and reinstatement in second class Tar Road including cost of fire wood (16")',
      unit: 'm',
      rate: 2920,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-a-3/4-1-2',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 6-Inch thick including cost of fire wood (3/4", 1", 2")',
      unit: 'm',
      rate: 1728,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-a-4',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 6-Inch thick including cost of fire wood (4")',
      unit: 'm',
      rate: 2278,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-a-6',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 6-Inch thick including cost of fire wood (6")',
      unit: 'm',
      rate: 2292,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-a-8',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 6-Inch thick including cost of fire wood (8")',
      unit: 'm',
      rate: 2393,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-a-10',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 6-Inch thick including cost of fire wood (10")',
      unit: 'm',
      rate: 2676,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-a-12',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 6-Inch thick including cost of fire wood (12")',
      unit: 'm',
      rate: 2695,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-a-16',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 6-Inch thick including cost of fire wood (16")',
      unit: 'm',
      rate: 3267,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-b-3/4-1-2',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 4-Inch thick including cost of fire wood (3/4", 1", 2")',
      unit: 'm',
      rate: 1339,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-b-4',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 4-Inch thick including cost of fire wood (4")',
      unit: 'm',
      rate: 1775,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-b-6',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 4-Inch thick including cost of fire wood (6")',
      unit: 'm',
      rate: 1788,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-b-8',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 4-Inch thick including cost of fire wood (8")',
      unit: 'm',
      rate: 1889,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-b-10',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 4-Inch thick including cost of fire wood (10")',
      unit: 'm',
      rate: 2116,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-b-12',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 4-Inch thick including cost of fire wood (12")',
      unit: 'm',
      rate: 2136,
      category: CATEGORY_P,
    ),
    SORItem(
      code: 'P-6-b-16',
      description: 'Pipe Laying & Reinstatement of PCC Pavement. 4-Inch thick including cost of fire wood (16")',
      unit: 'm',
      rate: 2595,
      category: CATEGORY_P,
    ),
  ];

  // Category V: Valve Pits & Covers
  static const List<SORItem> categoryV = [
    SORItem(
      code: 'V-1-3/4-1-2',
      description: 'Construction Of valve Pits (3/4", 1", 2")',
      unit: 'No.',
      rate: 33084,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-1-4',
      description: 'Construction Of valve Pits (4")',
      unit: 'No.',
      rate: 41471,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-1-6',
      description: 'Construction Of valve Pits (6")',
      unit: 'No.',
      rate: 46484,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-1-8-10',
      description: 'Construction Of valve Pits (8" & 10")',
      unit: 'No.',
      rate: 50737,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-1-12-16',
      description: 'Construction Of valve Pits (12" & 16")',
      unit: 'No.',
      rate: 56272,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-2-a-3/4-1-2',
      description: 'Construction Of valve Pit Cover R.C.C. Slab (4" thick) (3/4", 1", 2")',
      unit: 'No.',
      rate: 25515,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-2-a-4',
      description: 'Construction Of valve Pit Cover R.C.C. Slab (4" thick) (4")',
      unit: 'No.',
      rate: 28000,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-2-a-6-8-10',
      description: 'Construction Of valve Pit Cover R.C.C. Slab (4" thick) (6,8,10")',
      unit: 'No.',
      rate: 31981,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-2-a-12-16',
      description: 'Construction Of valve Pit Cover R.C.C. Slab (4" thick) (12" & 16")',
      unit: 'No.',
      rate: 38465,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-2-b-3/4-1-2',
      description: 'Construction Of valve Pit Cover R.C.C. Slab (6" thick) (3/4", 1", 2")',
      unit: 'No.',
      rate: 27383,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-2-b-4',
      description: 'Construction Of valve Pit Cover R.C.C. Slab (6" thick) (4")',
      unit: 'No.',
      rate: 30341,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-2-b-6-8-10',
      description: 'Construction Of valve Pit Cover R.C.C. Slab (6" thick) (6,8,10")',
      unit: 'No.',
      rate: 34816,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-2-b-12-16',
      description: 'Construction Of valve Pit Cover R.C.C. Slab (6" thick) (12" & 16")',
      unit: 'No.',
      rate: 41837,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-2-c-3/4-1-2',
      description: 'Construction Of valve Pit Cover R.C.C. Slab (12" thick) (3/4", 1", 2")',
      unit: 'No.',
      rate: 32989,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-2-c-4',
      description: 'Construction Of valve Pit Cover R.C.C. Slab (12" thick) (4")',
      unit: 'No.',
      rate: 37363,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-2-c-6-8-10',
      description: 'Construction Of valve Pit Cover R.C.C. Slab (12" thick) (6,8,10")',
      unit: 'No.',
      rate: 43320,
      category: CATEGORY_V,
    ),
    SORItem(
      code: 'V-2-c-12-16',
      description: 'Construction Of valve Pit Cover R.C.C. Slab (12" thick) (12" & 16")',
      unit: 'No.',
      rate: 51952,
      category: CATEGORY_V,
    ),
  ];

  // Category W: Welding
  static const List<SORItem> categoryW = [
    SORItem(
      code: 'W-1-a',
      description: 'Welding rates 1"and 2" dia for all types of areas',
      unit: 'm',
      rate: 106,
      category: CATEGORY_W,
    ),
    SORItem(
      code: 'W-1-b',
      description: 'Welding rates 4" dia 12 meter length for all types of areas',
      unit: 'm',
      rate: 106,
      category: CATEGORY_W,
    ),
    SORItem(
      code: 'W-1-d',
      description: 'Welding rates 6" dia 12 meter length for all types of areas',
      unit: 'm',
      rate: 159,
      category: CATEGORY_W,
    ),
    SORItem(
      code: 'W-1-e',
      description: 'Welding rates 8" dia 12 meter length for all types of areas',
      unit: 'm',
      rate: 199,
      category: CATEGORY_W,
    ),
  ];

  // Category PE: Polyethylene Pipe Laying
  static const List<SORItem> categoryPE = [
    SORItem(
      code: 'PE-1-3/4-1-1-1/4-2',
      description: 'PE Pipe Laying in Soft Soil (3/4", 1", 1-1/4", 2")',
      unit: 'm',
      rate: 264,
      category: CATEGORY_PE,
    ),
    SORItem(
      code: 'PE-1-4-6',
      description: 'PE Pipe Laying in Soft Soil (4" & 6")',
      unit: 'm',
      rate: 412,
      category: CATEGORY_PE,
    ),
    SORItem(
      code: 'PE-2-3/4-1-1-1/4-2',
      description: 'PE Pipe Laying in Hard/Rocky Soil (3/4", 1", 1-1/4", 2")',
      unit: 'm',
      rate: 387,
      category: CATEGORY_PE,
    ),
    SORItem(
      code: 'PE-2-4-6',
      description: 'PE Pipe Laying in Hard/Rocky Soil (4" & 6")',
      unit: 'm',
      rate: 602,
      category: CATEGORY_PE,
    ),
    SORItem(
      code: 'PE-3-3/4-1-1-1/4-2',
      description: 'PE Pipe Laying in Solid Rock Soil (3/4", 1", 1-1/4", 2")',
      unit: 'm',
      rate: 573,
      category: CATEGORY_PE,
    ),
    SORItem(
      code: 'PE-3-4-6',
      description: 'PE Pipe Laying in Solid Rock Soil (4" & 6")',
      unit: 'm',
      rate: 885,
      category: CATEGORY_PE,
    ),
    SORItem(
      code: 'PE-5-a-3/4-1-1/4-2',
      description: 'Pipe laying in Black Top Surface & Reinstatement of Tar Road over Lap of 3\' (1.5\' on each side) (3/4", 1-1/4", 2")',
      unit: 'm',
      rate: 2197,
      category: CATEGORY_PE,
    ),
    SORItem(
      code: 'PE-5-a-4-6',
      description: 'Pipe laying in Black Top Surface & Reinstatement of Tar Road over Lap of 3\' (1.5\' on each side) (4" & 6")',
      unit: 'm',
      rate: 2928,
      category: CATEGORY_PE,
    ),
    SORItem(
      code: 'PE-5-b-3/4-1-1/4-2',
      description: 'Pipe laying in Black Top Surface & Reinstatement of Tar Road over Lap of 3\' (1.5\' on each side) (3/4", 1-1/4", 2")',
      unit: 'm',
      rate: 1647,
      category: CATEGORY_PE,
    ),
    SORItem(
      code: 'PE-5-b-4-6',
      description: 'Pipe laying in Black Top Surface & Reinstatement of Tar Road over Lap of 3\' (1.5\' on each side) (4" & 6")',
      unit: 'm',
      rate: 2196,
      category: CATEGORY_PE,
    ),
    SORItem(
      code: 'PE-6-a-3/4-1-1/4-2',
      description: 'Pipe laying & Reinstatement of PCC pavement of 6" (3/4", 1-1/4", 2")',
      unit: 'm',
      rate: 1672,
      category: CATEGORY_PE,
    ),
    SORItem(
      code: 'PE-6-a-4-6',
      description: 'Pipe laying & Reinstatement of PCC pavement of 6" (4" & 6")',
      unit: 'm',
      rate: 2259,
      category: CATEGORY_PE,
    ),
    SORItem(
      code: 'PE-6-b-3/4-1-1/4-2',
      description: 'Pipe laying & Reinstatement of PCC pavement of 4" (3/4", 1-1/4", 2")',
      unit: 'm',
      rate: 1283,
      category: CATEGORY_PE,
    ),
    SORItem(
      code: 'PE-6-b-4-6',
      description: 'Pipe laying & Reinstatement of PCC pavement of 4" (4" & 6")',
      unit: 'm',
      rate: 1756,
      category: CATEGORY_PE,
    ),
  ];

  // Category BR: Boring
  static const List<SORItem> categoryBR = [
    SORItem(
      code: 'BR-1-3/4-1-2',
      description: 'Boring rate for laying Pipe & Service Line within City for small streets and road. (3/4", 1" & 2")',
      unit: 'Ft',
      rate: 430,
      category: CATEGORY_BR,
    ),
    SORItem(
      code: 'BR-1-4',
      description: 'Boring rate for laying Pipe & Service Line within City for small streets and road. (4")',
      unit: 'Ft',
      rate: 506,
      category: CATEGORY_BR,
    ),
    SORItem(
      code: 'BR-1-6',
      description: 'Boring rate for laying Pipe & Service Line within City for small streets and road. (6")',
      unit: 'Ft',
      rate: 649,
      category: CATEGORY_BR,
    ),
    SORItem(
      code: 'BR-2-3/4-1-2',
      description: 'Boring rate for laying Pipe & Service Line for small road under NHA/Provincial Highways. (3/4", 1" & 2")',
      unit: 'Ft',
      rate: 623,
      category: CATEGORY_BR,
    ),
    SORItem(
      code: 'BR-2-4',
      description: 'Boring rate for laying Pipe & Service Line for small road under NHA/Provincial Highways. (4")',
      unit: 'Ft',
      rate: 914,
      category: CATEGORY_BR,
    ),
    SORItem(
      code: 'BR-2-6',
      description: 'Boring rate for laying Pipe & Service Line for small road under NHA/Provincial Highways. (6")',
      unit: 'Ft',
      rate: 990,
      category: CATEGORY_BR,
    ),
  ];

  // Category RCB: Road Cutting & Breaking
  static const List<SORItem> categoryRCB = [
    SORItem(
      code: 'RCB-3',
      description: 'Cutting & Breaking of 3" PCC & Asphalt Roads & Streets',
      unit: 'm',
      rate: 239,
      category: CATEGORY_RCB,
    ),
    SORItem(
      code: 'RCB-4',
      description: 'Cutting & Breaking of 4" PCC & Asphalt Roads & Streets',
      unit: 'm',
      rate: 354,
      category: CATEGORY_RCB,
    ),
    SORItem(
      code: 'RCB-6',
      description: 'Cutting & Breaking of 6" PCC & Asphalt Roads & Streets',
      unit: 'm',
      rate: 534,
      category: CATEGORY_RCB,
    ),
  ];

  // Category TT: Tuff Tile
  static const List<SORItem> categoryTT = [
    SORItem(
      code: 'TT-1-1/2-1-1/4-2',
      description: 'Pipe Laying in Tuff Tile soiling & reinstatement of Tuff Tile Pavement with 25% new Tuff Tiles and with sand (1/2", 1-1/4" & 2")',
      unit: 'm',
      rate: 654,
      category: CATEGORY_TT,
    ),
    SORItem(
      code: 'TT-1-4-6',
      description: 'Pipe Laying in Tuff Tile soiling & reinstatement of Tuff Tile Pavement with 25% new Tuff Tiles and with sand (4" & 6")',
      unit: 'm',
      rate: 917,
      category: CATEGORY_TT,
    ),
    SORItem(
      code: 'TT-2-3/4-1-1/4-2',
      description: 'Pipe Laying in Tuff Tile soiling & reinstatement of Tuff Tile Pavement without new Tuff Tiles and with sand (3/4", 1-1/4" & 2")',
      unit: 'm',
      rate: 441,
      category: CATEGORY_TT,
    ),
    SORItem(
      code: 'TT-2-4-6',
      description: 'Pipe Laying in Tuff Tile soiling & reinstatement of Tuff Tile Pavement without new Tuff Tiles and with sand (4" & 6")',
      unit: 'm',
      rate: 489,
      category: CATEGORY_TT,
    ),
    SORItem(
      code: 'TT-3-3/4-1-1/4-2',
      description: 'Pipe Laying in Tuff Tile soiling & reinstatement of Tuff Tile Pavement without new Tuff Tiles and without sand (3/4", 1-1/4" & 2")',
      unit: 'm',
      rate: 407,
      category: CATEGORY_TT,
    ),
    SORItem(
      code: 'TT-3-4-6',
      description: 'Pipe Laying in Tuff Tile soiling & reinstatement of Tuff Tile Pavement without new Tuff Tiles and without sand (4" & 6")',
      unit: 'm',
      rate: 446,
      category: CATEGORY_TT,
    ),
    SORItem(
      code: 'TT-4-3/4-1-1/4-2',
      description: 'Pipe Laying in Tuff Tile soiling & reinstatement of Tuff Tile Pavement with 25% new Tuff Tiles and without sand (3/4", 1-1/4" & 2")',
      unit: 'm',
      rate: 556,
      category: CATEGORY_TT,
    ),
    SORItem(
      code: 'TT-4-4-6',
      description: 'Pipe Laying in Tuff Tile soiling & reinstatement of Tuff Tile Pavement with 25% new Tuff Tiles and without sand (4" & 6")',
      unit: 'm',
      rate: 638,
      category: CATEGORY_TT,
    ),
  ];

  // Category L: Labour Supply
  static const List<SORItem> categoryL = [
    SORItem(
      code: 'L-1-a',
      description: 'Mason',
      unit: '8 hrs',
      rate: 1650,
      category: CATEGORY_L,
    ),
    SORItem(
      code: 'L-1-b',
      description: 'Welder (Qualified)',
      unit: '8 hrs',
      rate: 2180,
      category: CATEGORY_L,
    ),
    SORItem(
      code: 'L-1-b-others',
      description: 'Meter Mechanic/Grinderman/TR Fabricator/Outer Wrap Fabricator/Crane Operator/Excavator Operator/Auto Electrician/Driver/GIS Operator/Computer Operator/Record Keeper/Inspector (QA)',
      unit: '8 hrs',
      rate: 1650,
      category: CATEGORY_L,
    ),
    SORItem(
      code: 'L-1-c',
      description: 'Fitter',
      unit: '8 hrs',
      rate: 1650,
      category: CATEGORY_L,
    ),
    SORItem(
      code: 'L-1-d',
      description: 'Casual Labour/Helper',
      unit: '8 hrs',
      rate: 1518,
      category: CATEGORY_L,
    ),
    SORItem(
      code: 'L-2',
      description: 'Sub Engineer',
      unit: '8 hrs',
      rate: 2337,
      category: CATEGORY_L,
    ),
  ];

  // Get all rates as a flat list
  static List<SORItem> getAllRates() {
    return [
      ...categoryX,
      ...categoryB,
      ...categoryC,
      ...categoryP,
      ...categoryV,
      ...categoryW,
      ...categoryPE,
      ...categoryBR,
      ...categoryRCB,
      ...categoryTT,
      ...categoryL,
      ...customRates,
    ];
  }

  // Get all rates grouped by category
  static Map<String, List<SORItem>> getAllRatesByCategory() {
    return {
      CATEGORY_X: categoryX,
      CATEGORY_B: categoryB,
      CATEGORY_C: categoryC,
      CATEGORY_P: categoryP,
      CATEGORY_V: categoryV,
      CATEGORY_W: categoryW,
      CATEGORY_PE: categoryPE,
      CATEGORY_BR: categoryBR,
      CATEGORY_RCB: categoryRCB,
      CATEGORY_TT: categoryTT,
      CATEGORY_L: categoryL,
      CATEGORY_CUSTOM: customRates,
    };
  }

  // Get rates by specific category
  static List<SORItem> getRatesByCategory(String category) {
    switch (category) {
      case CATEGORY_X:
        return categoryX;
      case CATEGORY_B:
        return categoryB;
      case CATEGORY_C:
        return categoryC;
      case CATEGORY_P:
        return categoryP;
      case CATEGORY_V:
        return categoryV;
      case CATEGORY_W:
        return categoryW;
      case CATEGORY_PE:
        return categoryPE;
      case CATEGORY_BR:
        return categoryBR;
      case CATEGORY_RCB:
        return categoryRCB;
      case CATEGORY_TT:
        return categoryTT;
      case CATEGORY_L:
        return categoryL;
      case CATEGORY_CUSTOM:
        return customRates;
      default:
        return [];
    }
  }

  // Search rates by code, description, or category
  static List<SORItem> searchRates(String query) {
    final allRates = getAllRates();
    if (query.isEmpty) return allRates;
    
    final lowerQuery = query.toLowerCase();
    return allRates.where((rate) {
      return rate.code.toLowerCase().contains(lowerQuery) ||
             rate.description.toLowerCase().contains(lowerQuery) ||
             rate.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get rate by code
  static SORItem? getRateByCode(String code) {
    final allRates = getAllRates();
    return allRates.firstWhere(
      (rate) => rate.code == code,
      orElse: () => throw Exception('Rate not found for code: $code'),
    );
  }

  // Add a new SOR rate dynamically
  static void addRate(SORItem item) {
    // Check if code already exists
    final allRates = getAllRates();
    final exists = allRates.any((rate) => rate.code == item.code);

    if (exists) {
      throw Exception('A rate with code "${item.code}" already exists.');
    }

    customRates.add(item);
  }

  // Update existing rate (for custom rates only)
  static void updateRate(String oldCode, SORItem newItem) {
    final index = customRates.indexWhere((rate) => rate.code == oldCode);
    if (index != -1) {
      customRates[index] = newItem;
    } else {
      throw Exception('Rate with code "$oldCode" not found in custom rates.');
    }
  }

  // Delete custom rate
  static void deleteRate(String code) {
    customRates.removeWhere((rate) => rate.code == code);
  }
}