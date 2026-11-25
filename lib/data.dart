part of 'main.dart';

// =====================================================================
//  KONSTANTA
// =====================================================================
const double worldW = 1600;
const double worldH = 800;
const double islandR = 150;
const int discPort = 47777; // UDP: mencari kapten
const int gamePort = 47778; // TCP: data permainan

/// Nomor build diisi otomatis oleh GitHub Actions (--dart-define=BUILD=...).
const int appBuild = int.fromEnvironment('BUILD', defaultValue: 0);
const String repoOwner = 'khairulhudatoyota-lgtm';
const String repoName = 'harta-karun';

/// Mulai level ke-11 (index 10) semua naik satu kapal besar.
const int bigShipFrom = 10;

const List<Color> shipColors = [
  Color(0xFFE53935), // merah
  Color(0xFF1E88E5), // biru
  Color(0xFF43A047), // hijau
  Color(0xFF8E24AA), // ungu
];
const List<String> shipNames = ['Merah', 'Biru', 'Hijau', 'Ungu'];
Color shipColor(int id) => shipColors[id % shipColors.length];

Color withA(Color c, double o) => c.withAlpha((o.clamp(0.0, 1.0) * 255).round());

// =====================================================================
//  TOKOH (8 tokoh siap pilih)
// =====================================================================
class HeroDef {
  final String name;
  final bool girl;
  final Color skin, hair, shirt, pants, hatColor;
  final Color? coat;
  final String hairStyle; // spiky, braid, bob, curly, pigtail, short, long
  final String hat; // bandana, tricorn, captain, hijab, crown, none
  final bool eyepatch, earring, feather, flower, stripes;
  const HeroDef({
    required this.name,
    required this.girl,
    required this.skin,
    required this.hair,
    required this.shirt,
    required this.pants,
    required this.hatColor,
    this.coat,
    required this.hairStyle,
    required this.hat,
    this.eyepatch = false,
    this.earring = false,
    this.feather = false,
    this.flower = false,
    this.stripes = false,
  });
}

const List<HeroDef> heroes = [
  HeroDef(
      name: 'Queen', girl: true, skin: Color(0xFFF1C27D), hair: Color(0xFF3E2723), shirt: Color(0xFFFFF8E1),
      pants: Color(0xFF4A148C), hatColor: Color(0xFFFFC107), coat: Color(0xFFC62828), hairStyle: 'braid', hat: 'crown',
      earring: true),
  HeroDef(
      name: 'Enzio', girl: false, skin: Color(0xFFE0A877), hair: Color(0xFF4E342E), shirt: Color(0xFFFFFFFF),
      pants: Color(0xFF263238), hatColor: Color(0xFF1E88E5), coat: Color(0xFF283593), hairStyle: 'spiky', hat: 'bandana'),
  HeroDef(
      name: 'Beryl', girl: false, skin: Color(0xFFD9A066), hair: Color(0xFF1B1B1B), shirt: Color(0xFFFFF3E0),
      pants: Color(0xFF3E2723), hatColor: Color(0xFF4E342E), coat: Color(0xFFEF6C00), hairStyle: 'short', hat: 'tricorn',
      feather: true),
  HeroDef(
      name: 'Raka', girl: false, skin: Color(0xFFE0A877), hair: Color(0xFF1B1B1B), shirt: Color(0xFFFFFFFF),
      pants: Color(0xFF37474F), hatColor: Color(0xFFD32F2F), coat: Color(0xFF8E2A2A), hairStyle: 'spiky', hat: 'bandana'),
  HeroDef(
      name: 'Sari', girl: true, skin: Color(0xFFD49A6A), hair: Color(0xFF2B1B12), shirt: Color(0xFFFFF3E0),
      pants: Color(0xFF3E2723), hatColor: Color(0xFF263238), coat: Color(0xFF1565C0), hairStyle: 'braid', hat: 'tricorn',
      feather: true),
  HeroDef(
      name: 'Kapten Bima', girl: false, skin: Color(0xFFC68642), hair: Color(0xFF3E2723), shirt: Color(0xFFFFF8E1),
      pants: Color(0xFF212121), hatColor: Color(0xFF1A1A1A), coat: Color(0xFF2E7D32), hairStyle: 'short', hat: 'captain',
      eyepatch: true),
  HeroDef(
      name: 'Aisyah', girl: true, skin: Color(0xFFF1C27D), hair: Color(0xFF2B1B12), shirt: Color(0xFFFBC02D),
      pants: Color(0xFF4A148C), hatColor: Color(0xFF7B1FA2), coat: Color(0xFF6A1B9A), hairStyle: 'short', hat: 'hijab'),
  HeroDef(
      name: 'Joko', girl: false, skin: Color(0xFF8D5524), hair: Color(0xFF121212), shirt: Color(0xFFFFFFFF),
      pants: Color(0xFF5D4037), hatColor: Color(0xFFEF6C00), hairStyle: 'curly', hat: 'bandana', stripes: true),
  HeroDef(
      name: 'Mei', girl: true, skin: Color(0xFFFFDBAC), hair: Color(0xFF111111), shirt: Color(0xFFFFFFFF),
      pants: Color(0xFF263238), hatColor: Color(0xFFC62828), coat: Color(0xFFF5F5F5), hairStyle: 'bob', hat: 'tricorn'),
  HeroDef(
      name: 'Dimas', girl: false, skin: Color(0xFFBF8B5E), hair: Color(0xFF4E342E), shirt: Color(0xFFE0F2F1),
      pants: Color(0xFF1B5E20), hatColor: Color(0xFF2E7D32), coat: Color(0xFF00897B), hairStyle: 'short', hat: 'bandana',
      earring: true),
  HeroDef(
      name: 'Putri', girl: true, skin: Color(0xFFEAC086), hair: Color(0xFF6D4C41), shirt: Color(0xFFFFFFFF),
      pants: Color(0xFF880E4F), hatColor: Color(0xFFE91E63), coat: Color(0xFFE91E63), hairStyle: 'pigtail', hat: 'none',
      flower: true),
];

/// Warga lokal (lawan olahraga) dibuat dari warna negaranya.
HeroDef villagerFor(int mission) {
  final k = countries[mission];
  const skins = [Color(0xFFE0A877), Color(0xFFC68642), Color(0xFF8D5524), Color(0xFFFFDBAC), Color(0xFFD49A6A)];
  const hairs = [Color(0xFF1B1B1B), Color(0xFF4E342E), Color(0xFF8D6E63), Color(0xFFE0C068)];
  return HeroDef(
    name: 'Warga ${k.name}',
    girl: mission.isOdd,
    skin: skins[mission % skins.length],
    hair: hairs[(mission ~/ 2) % hairs.length],
    shirt: k.sea1,
    pants: k.sea2,
    hatColor: k.sea2,
    hairStyle: mission.isOdd ? 'bob' : 'short',
    hat: 'none',
  );
}

// =====================================================================
//  OLAHRAGA KHAS
// =====================================================================
/// type: timing (ketuk tepat), race (ketuk cepat balapan), tug (dorong-dorongan),
///       goal (tembak melewati penjaga), hoop (tembak ke sasaran)
class SportDef {
  final String name, emoji, type, how;
  final String lane; // water, sand, road, snow, ice, mat, field
  const SportDef(this.name, this.emoji, this.type, this.how, [this.lane = 'field']);
}

const String _howTiming = 'Ketuk tombolnya saat tanda masuk ke kotak hijau!';
const String _howRace = 'Ketuk tombolnya cepat-cepat supaya kamu sampai duluan!';
const String _howTug = 'Ketuk tombolnya cepat-cepat untuk mendorong lawan keluar!';
const String _howGoal = 'Ketuk tombolnya saat penjaga jauh dari sasaran!';
const String _howHoop = 'Ketuk tombolnya saat sasaran ada di garis panah!';

// =====================================================================
//  30 NEGARA / LEVEL
// =====================================================================
class Country {
  final String name, flag, landmark, item, itemName, fact;
  final Offset island; // posisi pulau di dunia (laut)
  final Offset mapPos; // posisi di peta dunia (0..1)
  final Color sand, sea1, sea2;
  final Color? grass;
  final List<String> deco, mobs;
  final SportDef sport;
  const Country({
    required this.name,
    required this.flag,
    required this.landmark,
    required this.item,
    required this.itemName,
    required this.fact,
    required this.island,
    required this.mapPos,
    required this.sand,
    required this.grass,
    required this.sea1,
    required this.sea2,
    required this.deco,
    required this.mobs,
    required this.sport,
  });
}

int itemCountFor(int m) => min(6, 3 + m ~/ 5);
String countryIntro(int m) {
  final k = countries[m];
  final n = itemCountFor(m);
  return 'Selamat datang di ${k.name}! Ayo kumpulkan ${countWords[n - 1].toLowerCase()} ${k.itemName}!';
}

const _sandA = Color(0xFFF2D49B), _sandB = Color(0xFFEED9A8), _sandD = Color(0xFFFFCC80), _snow = Color(0xFFF5FBFF);
const _grassA = Color(0xFF5DBB63), _grassB = Color(0xFF66BB6A), _grassC = Color(0xFF7CB342), _grassD = Color(0xFF2E7D32);

const List<Country> countries = [
  Country(
    name: 'Indonesia', flag: '🇮🇩', landmark: '🦎', item: '🥥', itemName: 'buah kelapa',
    fact: 'Hore, hartanya ketemu! Di Indonesia ada komodo, kadal paling besar di dunia!',
    island: Offset(1220, 430), mapPos: Offset(0.80, 0.585),
    sand: _sandA, grass: _grassA, sea1: Color(0xFF4FC3F7), sea2: Color(0xFF0277BD),
    deco: ['🌴', '🌋', '🌴'], mobs: ['🐙'],
    sport: SportDef('pencak silat', '🥋', 'timing', _howTiming, 'mat'),
  ),
  Country(
    name: 'Malaysia', flag: '🇲🇾', landmark: '🏙️', item: '🌺', itemName: 'bunga raya',
    fact: 'Hebat! Malaysia punya Menara Kembar Petronas yang tinggi sekali!',
    island: Offset(1250, 360), mapPos: Offset(0.765, 0.515),
    sand: Color(0xFFF4D9A6), grass: Color(0xFF4CAF50), sea1: Color(0xFF4DD0E1), sea2: Color(0xFF00838F),
    deco: ['🌴', '🐅', '🌴'], mobs: ['🐙'],
    sport: SportDef('bulu tangkis', '🏸', 'timing', _howTiming),
  ),
  Country(
    name: 'Amerika', flag: '🇺🇸', landmark: '🗽', item: '⭐', itemName: 'bintang',
    fact: 'Keren! Di Amerika ada Patung Liberty yang memegang obor!',
    island: Offset(1200, 470), mapPos: Offset(0.21, 0.33),
    sand: _sandB, grass: _grassB, sea1: Color(0xFF64B5F6), sea2: Color(0xFF1565C0),
    deco: ['🌲', '🦅', '🌲'], mobs: ['🐙', '🦈'],
    sport: SportDef('bola basket', '🏀', 'hoop', _howHoop),
  ),
  Country(
    name: 'Arab', flag: '🇸🇦', landmark: '🐪', item: '💎', itemName: 'permata',
    fact: 'Wah, hartanya ketemu! Di Arab ada gurun pasir yang luas dan unta yang kuat!',
    island: Offset(1230, 400), mapPos: Offset(0.625, 0.455),
    sand: _sandD, grass: null, sea1: Color(0xFF4DB6AC), sea2: Color(0xFF00695C),
    deco: ['🌴', '🕌', '🌵'], mobs: ['🐙', '🦈'],
    sport: SportDef('balap unta', '🐪', 'race', _howRace, 'sand'),
  ),
  Country(
    name: 'Jepang', flag: '🇯🇵', landmark: '🗻', item: '🍣', itemName: 'sushi',
    fact: 'Hore! Jepang punya Gunung Fuji yang puncaknya bersalju!',
    island: Offset(1180, 380), mapPos: Offset(0.885, 0.33),
    sand: Color(0xFFF0DDB8), grass: Color(0xFF81C784), sea1: Color(0xFF7986CB), sea2: Color(0xFF283593),
    deco: ['🌸', '⛩️', '🌸'], mobs: ['🐙', '🦈'],
    sport: SportDef('sumo', '🤼', 'tug', _howTug, 'mat'),
  ),
  Country(
    name: 'Cina', flag: '🇨🇳', landmark: '🐼', item: '🏮', itemName: 'lampion',
    fact: 'Asyik! Di Cina ada panda yang lucu dan Tembok Besar yang panjang sekali!',
    island: Offset(1240, 450), mapPos: Offset(0.77, 0.36),
    sand: Color(0xFFF1D7A0), grass: _grassC, sea1: Color(0xFF4FC3F7), sea2: Color(0xFF01579B),
    deco: ['🎋', '🐉', '🎋'], mobs: ['🐙', '🦈', '🐙'],
    sport: SportDef('tenis meja', '🏓', 'timing', _howTiming),
  ),
  Country(
    name: 'Mesir', flag: '🇪🇬', landmark: 'PIRAMIDA', item: '🏺', itemName: 'guci kuno',
    fact: 'Luar biasa! Mesir punya piramida yang dibuat ribuan tahun yang lalu!',
    island: Offset(1200, 420), mapPos: Offset(0.555, 0.415),
    sand: Color(0xFFFFD180), grass: null, sea1: Color(0xFF26C6DA), sea2: Color(0xFF00695C),
    deco: ['🌴', '🐫', '🌴'], mobs: ['🐊', '🦈', '🐙'],
    sport: SportDef('dayung di Sungai Nil', '🚣', 'race', _howRace, 'water'),
  ),
  Country(
    name: 'Brasil', flag: '🇧🇷', landmark: '🦜', item: '🍌', itemName: 'pisang',
    fact: 'Hebat! Brasil punya hutan Amazon yang besar, rumah burung beo yang cantik!',
    island: Offset(1230, 390), mapPos: Offset(0.33, 0.60),
    sand: Color(0xFFF3D9A4), grass: _grassD, sea1: Color(0xFF4DD0E1), sea2: Color(0xFF006064),
    deco: ['🌴', '🐒', '🌳'], mobs: ['🐙', '🦈', '🐡'],
    sport: SportDef('sepak bola', '⚽', 'goal', _howGoal),
  ),
  Country(
    name: 'Australia', flag: '🇦🇺', landmark: '🦘', item: '🐚', itemName: 'kerang',
    fact: 'Hore! Di Australia ada kanguru yang melompat dan koala yang suka tidur!',
    island: Offset(1210, 460), mapPos: Offset(0.85, 0.71),
    sand: _sandD, grass: Color(0xFF9CCC65), sea1: Color(0xFF29B6F6), sea2: Color(0xFF0D47A1),
    deco: ['🐨', '🌳', '🌴'], mobs: ['🦈', '🦈', '🐙'],
    sport: SportDef('kriket', '🏏', 'timing', _howTiming),
  ),
  Country(
    name: 'Thailand', flag: '🇹🇭', landmark: '🐘', item: '🥭', itemName: 'mangga',
    fact: 'Hebat! Thailand punya banyak gajah dan kuil emas yang berkilau!',
    island: Offset(1230, 420), mapPos: Offset(0.755, 0.47),
    sand: _sandA, grass: _grassA, sea1: Color(0xFF4DD0E1), sea2: Color(0xFF00838F),
    deco: ['🌴', '🌺', '🌴'], mobs: ['🐙', '🦈', '🐙'],
    sport: SportDef('sepak takraw', '🏐', 'timing', _howTiming),
  ),
  Country(
    name: 'India', flag: '🇮🇳', landmark: '🕌', item: '🌶️', itemName: 'cabai',
    fact: 'Keren! India punya Taj Mahal, bangunan putih yang sangat indah!',
    island: Offset(1220, 440), mapPos: Offset(0.69, 0.44),
    sand: _sandD, grass: _grassC, sea1: Color(0xFF4FC3F7), sea2: Color(0xFF0277BD),
    deco: ['🌴', '🐅', '🐘'], mobs: ['🐙', '🦈', '🐙'],
    sport: SportDef('kabaddi', '🤼', 'tug', _howTug, 'mat'),
  ),
  Country(
    name: 'Korea', flag: '🇰🇷', landmark: '🏯', item: '🍜', itemName: 'mangkuk mie',
    fact: 'Hore! Korea punya istana kuno yang cantik dan makanan kimchi yang terkenal!',
    island: Offset(1200, 380), mapPos: Offset(0.85, 0.32),
    sand: Color(0xFFF0DDB8), grass: _grassB, sea1: Color(0xFF7986CB), sea2: Color(0xFF283593),
    deco: ['🌸', '🌲', '🌸'], mobs: ['🐙', '🦈', '🐙'],
    sport: SportDef('taekwondo', '🥋', 'timing', _howTiming, 'mat'),
  ),
  Country(
    name: 'Filipina', flag: '🇵🇭', landmark: '🌋', item: '🍍', itemName: 'nanas',
    fact: 'Asyik! Filipina punya Gunung Mayon yang bentuknya kerucut sempurna!',
    island: Offset(1240, 430), mapPos: Offset(0.835, 0.49),
    sand: _sandA, grass: _grassA, sea1: Color(0xFF26C6DA), sea2: Color(0xFF006064),
    deco: ['🌴', '🥥', '🌴'], mobs: ['🐙', '🦈', '🐡'],
    sport: SportDef('tinikling lompat bambu', '🎋', 'timing', _howTiming),
  ),
  Country(
    name: 'Turki', flag: '🇹🇷', landmark: '🎈', item: '🍬', itemName: 'permen',
    fact: 'Wah! Di Turki ada balon udara yang terbang ramai-ramai di langit!',
    island: Offset(1210, 400), mapPos: Offset(0.57, 0.33),
    sand: _sandD, grass: _grassC, sea1: Color(0xFF4DB6AC), sea2: Color(0xFF00695C),
    deco: ['🌷', '🕌', '🌷'], mobs: ['🐙', '🦈', '🐙'],
    sport: SportDef('gulat', '🤼', 'tug', _howTug, 'mat'),
  ),
  Country(
    name: 'Belanda', flag: '🇳🇱', landmark: '🌷', item: '🧀', itemName: 'keju',
    fact: 'Hebat! Belanda punya kincir angin dan kebun bunga tulip yang warna-warni!',
    island: Offset(1230, 430), mapPos: Offset(0.50, 0.24),
    sand: _sandB, grass: _grassB, sea1: Color(0xFF64B5F6), sea2: Color(0xFF1565C0),
    deco: ['🌷', '🚲', '🌷'], mobs: ['🐙', '🦈', '🐡'],
    sport: SportDef('sepatu luncur es', '⛸️', 'race', _howRace, 'ice'),
  ),
  Country(
    name: 'Inggris', flag: '🇬🇧', landmark: '💂', item: '☕', itemName: 'cangkir teh',
    fact: 'Keren! Di Inggris ada tentara penjaga istana yang memakai topi tinggi!',
    island: Offset(1200, 450), mapPos: Offset(0.47, 0.235),
    sand: _sandB, grass: _grassD, sea1: Color(0xFF78909C), sea2: Color(0xFF37474F),
    deco: ['🌲', '🎡', '🌲'], mobs: ['🐙', '🦈', '🐙'],
    sport: SportDef('tenis', '🎾', 'timing', _howTiming),
  ),
  Country(
    name: 'Prancis', flag: '🇫🇷', landmark: '🗼', item: '🥐', itemName: 'roti croissant',
    fact: 'Hore! Prancis punya Menara Eiffel yang tinggi menjulang!',
    island: Offset(1220, 420), mapPos: Offset(0.485, 0.285),
    sand: _sandB, grass: _grassB, sea1: Color(0xFF64B5F6), sea2: Color(0xFF1565C0),
    deco: ['🌳', '🎨', '🌳'], mobs: ['🐙', '🦈', '🐡'],
    sport: SportDef('balap sepeda', '🚴', 'race', _howRace, 'road'),
  ),
  Country(
    name: 'Spanyol', flag: '🇪🇸', landmark: '💃', item: '🍊', itemName: 'jeruk',
    fact: 'Asyik! Spanyol terkenal dengan tarian flamenco dan sepak bolanya!',
    island: Offset(1240, 440), mapPos: Offset(0.47, 0.32),
    sand: _sandD, grass: _grassC, sea1: Color(0xFF4FC3F7), sea2: Color(0xFF0277BD),
    deco: ['🌳', '🎸', '🌳'], mobs: ['🐙', '🦈', '🐙'],
    sport: SportDef('sepak bola', '⚽', 'goal', _howGoal),
  ),
  Country(
    name: 'Italia', flag: '🇮🇹', landmark: '🍕', item: '🍝', itemName: 'piring spageti',
    fact: 'Hebat! Italia punya pizza yang enak dan kota air bernama Venesia!',
    island: Offset(1210, 410), mapPos: Offset(0.525, 0.31),
    sand: _sandA, grass: _grassC, sea1: Color(0xFF26C6DA), sea2: Color(0xFF00838F),
    deco: ['🌳', '🍇', '🌳'], mobs: ['🐙', '🦈', '🐡'],
    sport: SportDef('dayung gondola', '🚣', 'race', _howRace, 'water'),
  ),
  Country(
    name: 'Jerman', flag: '🇩🇪', landmark: '🏰', item: '🥨', itemName: 'roti pretzel',
    fact: 'Keren! Jerman punya istana seperti di negeri dongeng!',
    island: Offset(1220, 440), mapPos: Offset(0.52, 0.245),
    sand: _sandB, grass: _grassD, sea1: Color(0xFF78909C), sea2: Color(0xFF37474F),
    deco: ['🌲', '🌲', '🌲'], mobs: ['🐙', '🦈', '🐙'],
    sport: SportDef('bola tangan', '🤾', 'goal', _howGoal),
  ),
  Country(
    name: 'Swiss', flag: '🇨🇭', landmark: '🏔️', item: '🍫', itemName: 'cokelat',
    fact: 'Hore! Swiss punya gunung bersalju yang tinggi dan cokelat yang lezat!',
    island: Offset(1200, 400), mapPos: Offset(0.505, 0.275),
    sand: _snow, grass: Color(0xFFD6ECFA), sea1: Color(0xFF81D4FA), sea2: Color(0xFF01579B),
    deco: ['🌲', '⛄', '🌲'], mobs: ['🐙', '🦈', '🐳'],
    sport: SportDef('ski', '⛷️', 'race', _howRace, 'snow'),
  ),
  Country(
    name: 'Kenya', flag: '🇰🇪', landmark: '🦒', item: '🥁', itemName: 'gendang',
    fact: 'Wah! Kenya punya jerapah, zebra, dan pelari tercepat di dunia!',
    island: Offset(1230, 430), mapPos: Offset(0.585, 0.56),
    sand: _sandD, grass: Color(0xFFC0CA33), sea1: Color(0xFF4DD0E1), sea2: Color(0xFF00838F),
    deco: ['🌳', '🦓', '🌳'], mobs: ['🐙', '🦈', '🐊'],
    sport: SportDef('lari maraton', '🏃', 'race', _howRace, 'road'),
  ),
  Country(
    name: 'Afrika Selatan', flag: '🇿🇦', landmark: '🦁', item: '🌻', itemName: 'bunga matahari',
    fact: 'Hebat! Afrika Selatan punya singa, si raja hutan!',
    island: Offset(1210, 450), mapPos: Offset(0.55, 0.72),
    sand: _sandD, grass: Color(0xFF9CCC65), sea1: Color(0xFF29B6F6), sea2: Color(0xFF0D47A1),
    deco: ['🌳', '🐘', '🌳'], mobs: ['🐙', '🦈', '🦈'],
    sport: SportDef('rugbi', '🏉', 'hoop', _howHoop),
  ),
  Country(
    name: 'Meksiko', flag: '🇲🇽', landmark: '🌮', item: '🌽', itemName: 'jagung',
    fact: 'Asyik! Meksiko terkenal dengan topi sombrero, kaktus, dan makanan taco!',
    island: Offset(1220, 420), mapPos: Offset(0.19, 0.42),
    sand: _sandD, grass: null, sea1: Color(0xFF4DD0E1), sea2: Color(0xFF00838F),
    deco: ['🌵', '🌵', '🌵'], mobs: ['🐙', '🦈', '🐡'],
    sport: SportDef('gulat lucha', '🤼', 'timing', _howTiming, 'mat'),
  ),
  Country(
    name: 'Kanada', flag: '🇨🇦', landmark: '🍁', item: '🥞', itemName: 'kue panekuk',
    fact: 'Keren! Kanada punya daun maple merah dan beruang di hutannya!',
    island: Offset(1200, 430), mapPos: Offset(0.20, 0.20),
    sand: _snow, grass: Color(0xFFD6ECFA), sea1: Color(0xFF81D4FA), sea2: Color(0xFF01579B),
    deco: ['🌲', '🐻', '🌲'], mobs: ['🐙', '🦈', '🐳'],
    sport: SportDef('hoki es', '🏒', 'goal', _howGoal),
  ),
  Country(
    name: 'Argentina', flag: '🇦🇷', landmark: '🐎', item: '🥩', itemName: 'daging panggang',
    fact: 'Hore! Argentina punya padang rumput luas dan pemain sepak bola hebat!',
    island: Offset(1230, 440), mapPos: Offset(0.31, 0.76),
    sand: _sandB, grass: _grassC, sea1: Color(0xFF64B5F6), sea2: Color(0xFF1565C0),
    deco: ['🌳', '🐄', '🌳'], mobs: ['🐙', '🦈', '🐙'],
    sport: SportDef('sepak bola', '⚽', 'goal', _howGoal),
  ),
  Country(
    name: 'Selandia Baru', flag: '🇳🇿', landmark: '🥝', item: '🐑', itemName: 'domba',
    fact: 'Hebat! Selandia Baru punya burung kiwi yang tidak bisa terbang!',
    island: Offset(1210, 410), mapPos: Offset(0.94, 0.79),
    sand: _sandA, grass: _grassB, sea1: Color(0xFF26C6DA), sea2: Color(0xFF006064),
    deco: ['🌲', '🐑', '🌲'], mobs: ['🐙', '🦈', '🐳'],
    sport: SportDef('dayung kano', '🛶', 'race', _howRace, 'water'),
  ),
  Country(
    name: 'Rusia', flag: '🇷🇺', landmark: '⛪', item: '🍯', itemName: 'madu',
    fact: 'Wah! Rusia adalah negara paling luas di dunia dan punya istana berkubah warna-warni!',
    island: Offset(1220, 430), mapPos: Offset(0.68, 0.18),
    sand: _snow, grass: Color(0xFFD6ECFA), sea1: Color(0xFF81D4FA), sea2: Color(0xFF01579B),
    deco: ['🌲', '🐻', '🌲'], mobs: ['🐙', '🦈', '🐳'],
    sport: SportDef('senam', '🤸', 'timing', _howTiming, 'mat'),
  ),
  Country(
    name: 'Norwegia', flag: '🇳🇴', landmark: '🌌', item: '🦐', itemName: 'udang',
    fact: 'Indah sekali! Di Norwegia, langit malam bisa berwarna hijau, namanya aurora!',
    island: Offset(1200, 420), mapPos: Offset(0.505, 0.17),
    sand: _snow, grass: Color(0xFFD6ECFA), sea1: Color(0xFF81D4FA), sea2: Color(0xFF01579B),
    deco: ['🌲', '🦌', '🌲'], mobs: ['🐙', '🐳', '🦈'],
    sport: SportDef('lompat ski', '⛷️', 'timing', _howTiming, 'snow'),
  ),
  Country(
    name: 'Kutub Selatan', flag: '🇦🇶', landmark: '🐧', item: '🐟', itemName: 'ikan untuk penguin',
    fact: 'Kalian berhasil! Penguin senang sekali, dan ini harta karun paling besar!',
    island: Offset(1220, 410), mapPos: Offset(0.50, 0.93),
    sand: _snow, grass: Color(0xFFD6ECFA), sea1: Color(0xFF81D4FA), sea2: Color(0xFF01579B),
    deco: ['⛄', '❄️', '🐧'], mobs: ['🐳', '🐙', '🦈'],
    sport: SportDef('seluncur perut penguin', '🐧', 'race', _howRace, 'ice'),
  ),
];

const String finishSpeech =
    'Selamat! Kalian sudah keliling tiga puluh negara dan menjadi Raja Bajak Laut Dunia!';
const List<String> countWords = ['Satu', 'Dua', 'Tiga', 'Empat', 'Lima', 'Enam', 'Tujuh'];

// =====================================================================
//  PULAU BESAR, ALAT, TEKA-TEKI
// =====================================================================
const double gateX = 600, boulderX = 1000;
const Offset landX = Offset(1400, 445);
const Offset landBeach = Offset(210, 470);
double pathY(double x) => 470 + sin(x / 240) * 80;
const Offset villagerPos = Offset(1180, 560);

bool isTool(String c) => c == 'kunci' || c == 'cangkul' || c == 'linggis';

/// Alat yang dibutuhkan setiap pemain. Cangkul selalu didapat dari warga (olahraga).
List<String> toolsFor(int m) => m == 0
    ? const ['cangkul']
    : m == 1
        ? const ['kunci', 'cangkul']
        : const ['kunci', 'linggis', 'cangkul'];
bool gateFor(int m) => m >= 1;
bool boulderFor(int m) => m >= 2;
bool chestPuzzleFor(int m) => m >= 5;
const Map<String, String> decoyNames = {
  '🦋': 'kupu-kupu',
  '🐸': 'katak',
  '🐞': 'kumbang',
  '🐛': 'ulat',
  '🐌': 'siput',
};

class Puzzle {
  final String q, show;
  final List<String> choices;
  final int answer;
  const Puzzle(this.q, this.show, this.choices, this.answer);
}

/// Teka-teki: slot 1 = gerbang, slot 2 = peti. Tiap pemain dapat soal sendiri.
Puzzle puzzleFor(int mission, int slot, int player) {
  final r = Random(mission * 31 + slot * 7 + player * 101 + 3);
  final type = (mission * 2 + slot + player) % 5;
  List<String> shuf(List<String> l) {
    final x = [...l];
    x.shuffle(r);
    return x;
  }

  switch (type) {
    case 1:
      {
        const things = [
          ['🍌', 'pisang'],
          ['🍎', 'apel'],
          ['🐟', 'ikan'],
          ['⭐', 'bintang'],
          ['🥥', 'kelapa'],
          ['🐤', 'anak ayam'],
        ];
        final th = things[r.nextInt(things.length)];
        final n = 2 + r.nextInt(mission < 10 ? 3 : 5);
        final opts = <int>{n};
        while (opts.length < 3) {
          opts.add(max(1, n + r.nextInt(5) - 2));
        }
        final ch = shuf([for (final v in opts) '$v']);
        return Puzzle('Ada berapa ${th[1]}? Ayo hitung!', List.filled(n, th[0]).join(' '), ch, ch.indexOf('$n'));
      }
    case 2:
      {
        const pairs = [
          ['🍎', '🍌'],
          ['⭐', '🌙'],
          ['🐟', '🐚'],
          ['❤️', '💙'],
          ['🐶', '🐱'],
          ['🚗', '🚲'],
        ];
        final i = r.nextInt(pairs.length);
        final p = pairs[i];
        final other = pairs[(i + 1 + r.nextInt(pairs.length - 1)) % pairs.length][0];
        final ch = shuf([p[0], p[1], other]);
        return Puzzle('Apa gambar selanjutnya? Lihat polanya!', '${p[0]} ${p[1]} ${p[0]} ${p[1]} ❓', ch, ch.indexOf(p[0]));
      }
    case 3:
      {
        const qs = [
          ['Mana yang bisa terbang?', '🐦', '🐟', '🐢'],
          ['Mana yang hidup di laut?', '🐠', '🐄', '🐒'],
          ['Mana yang buah?', '🍌', '🚗', '⚽'],
          ['Mana hewan yang paling besar?', '🐘', '🐭', '🐜'],
          ['Mana yang dingin?', '⛄', '🔥', '☀️'],
          ['Mana yang bisa dikendarai?', '🚲', '🍎', '🌻'],
          ['Mana yang dipakai saat hujan?', '☂️', '🕶️', '🧢'],
          ['Mana yang suka makan wortel?', '🐰', '🦁', '🐟'],
        ];
        final qq = qs[r.nextInt(qs.length)];
        final ch = shuf([qq[1], qq[2], qq[3]]);
        return Puzzle(qq[0], '', ch, ch.indexOf(qq[1]));
      }
    case 4:
      {
        const pairs = [
          ['🐶', '🐱'],
          ['🍎', '🍌'],
          ['🚗', '🚲'],
          ['🐟', '🐢'],
          ['⭐', '🌙'],
          ['🌻', '🌵'],
        ];
        final p = pairs[r.nextInt(pairs.length)];
        final ch = shuf([p[0], p[0], p[1]]);
        return Puzzle('Mana yang berbeda?', '', ch, ch.indexOf(p[1]));
      }
    default:
      {
        const hearts = ['❤️', '💛', '💚', '💙', '💜'];
        const names = {'❤️': 'merah', '💛': 'kuning', '💚': 'hijau', '💙': 'biru', '💜': 'ungu'};
        final pick = shuf(hearts).take(3).toList();
        final target = pick[r.nextInt(3)];
        return Puzzle('Gemboknya berwarna ${names[target]}. Pilih hati yang warnanya sama!', target, pick,
            pick.indexOf(target));
      }
  }
}

// =====================================================================
//  KAPAL BESAR: pembagian tugas kemudi
// =====================================================================
/// Tombol yang dipegang pemain ke-[index] dari [count] pemain. L=kiri, G=gas, R=kanan.
List<String> rolesFor(int index, int count) {
  if (count <= 1) return const ['L', 'G', 'R'];
  if (count == 2) return index == 0 ? const ['L', 'R'] : const ['G'];
  const three = [
    ['L'],
    ['G'],
    ['R']
  ];
  if (index < 3) return three[index];
  return const ['G'];
}

String roleName(String r) => r == 'L' ? 'belok kiri' : (r == 'R' ? 'belok kanan' : 'gas');

// =====================================================================
//  SUARA (Text-to-Speech bahasa Indonesia)
// =====================================================================
class Voice {
  static final FlutterTts _tts = FlutterTts();
  static bool _init = false;

  static Future<void> init() async {
    if (_init) return;
    _init = true;
    try {
      await _tts.setLanguage('id-ID');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.15);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  static void say(String text) {
    try {
      _tts.stop();
      _tts.speak(text);
    } catch (_) {}
  }
}
