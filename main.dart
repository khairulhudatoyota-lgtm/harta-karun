// =====================================================================
//  HARTA KARUN DUNIA
//  Game petualangan bajak laut untuk anak — 10 misi keliling dunia.
//  Bisa main sendiri atau MABAR offline lewat hotspot / Wi-Fi lokal.
// =====================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------
//  KONSTANTA DUNIA
// ---------------------------------------------------------------------
const double worldW = 1600;
const double worldH = 800;
const double islandR = 150;
const int discPort = 47777; // UDP: mencari kapten
const int gamePort = 47778; // TCP: data permainan

const List<Color> shipColors = [
  Color(0xFFE53935), // merah
  Color(0xFF1E88E5), // biru
  Color(0xFF43A047), // hijau
  Color(0xFF8E24AA), // ungu
];
const List<String> shipNames = ['Merah', 'Biru', 'Hijau', 'Ungu'];
Color shipColor(int id) => shipColors[id % shipColors.length];

Color withA(Color c, double o) => c.withAlpha((o.clamp(0.0, 1.0) * 255).round());

// ---------------------------------------------------------------------
//  DATA 10 NEGARA / MISI
// ---------------------------------------------------------------------
class Country {
  final String name, flag, landmark, item, itemName, intro, fact;
  final int itemCount;
  final Offset island; // posisi pulau di dunia
  final Offset mapPos; // posisi di peta dunia (0..1)
  final Color sand, sea1, sea2;
  final Color? grass;
  final List<String> deco, mobs;
  const Country({
    required this.name,
    required this.flag,
    required this.landmark,
    required this.item,
    required this.itemName,
    required this.itemCount,
    required this.intro,
    required this.fact,
    required this.island,
    required this.mapPos,
    required this.sand,
    required this.grass,
    required this.sea1,
    required this.sea2,
    required this.deco,
    required this.mobs,
  });
}

const List<Country> countries = [
  Country(
    name: 'Indonesia', flag: '🇮🇩', landmark: '🦎', item: '🥥', itemName: 'kelapa', itemCount: 3,
    intro: 'Selamat datang di Indonesia! Ayo kumpulkan tiga buah kelapa!',
    fact: 'Hore, hartanya ketemu! Di Indonesia ada komodo, kadal paling besar di dunia!',
    island: Offset(1220, 430), mapPos: Offset(0.80, 0.585),
    sand: Color(0xFFF2D49B), grass: Color(0xFF5DBB63),
    sea1: Color(0xFF4FC3F7), sea2: Color(0xFF0277BD),
    deco: ['🌴', '🌋', '🌴'], mobs: ['🐙'],
  ),
  Country(
    name: 'Malaysia', flag: '🇲🇾', landmark: '🏙️', item: '🌺', itemName: 'bunga raya', itemCount: 3,
    intro: 'Sekarang kita di Malaysia! Kumpulkan tiga bunga raya!',
    fact: 'Hebat! Malaysia punya Menara Kembar Petronas yang tinggi sekali!',
    island: Offset(1250, 360), mapPos: Offset(0.765, 0.515),
    sand: Color(0xFFF4D9A6), grass: Color(0xFF4CAF50),
    sea1: Color(0xFF4DD0E1), sea2: Color(0xFF00838F),
    deco: ['🌴', '🐅', '🌴'], mobs: ['🐙'],
  ),
  Country(
    name: 'Amerika', flag: '🇺🇸', landmark: '🗽', item: '⭐', itemName: 'bintang', itemCount: 4,
    intro: 'Kita sampai di Amerika! Kumpulkan empat bintang!',
    fact: 'Keren! Di Amerika ada Patung Liberty yang memegang obor!',
    island: Offset(1200, 470), mapPos: Offset(0.21, 0.33),
    sand: Color(0xFFEED9A8), grass: Color(0xFF66BB6A),
    sea1: Color(0xFF64B5F6), sea2: Color(0xFF1565C0),
    deco: ['🌲', '🦅', '🌲'], mobs: ['🐙', '🦈'],
  ),
  Country(
    name: 'Arab', flag: '🇸🇦', landmark: '🐪', item: '💎', itemName: 'permata', itemCount: 4,
    intro: 'Selamat datang di Arab! Kumpulkan empat permata yang berkilau!',
    fact: 'Wah, hartanya ketemu! Di Arab ada gurun pasir yang luas dan unta yang kuat!',
    island: Offset(1230, 400), mapPos: Offset(0.625, 0.455),
    sand: Color(0xFFFFCC80), grass: null,
    sea1: Color(0xFF4DB6AC), sea2: Color(0xFF00695C),
    deco: ['🌴', '🕌', '🌵'], mobs: ['🐙', '🦈'],
  ),
  Country(
    name: 'Jepang', flag: '🇯🇵', landmark: '🗻', item: '🍣', itemName: 'sushi', itemCount: 4,
    intro: 'Konnichiwa! Kita di Jepang! Kumpulkan empat sushi!',
    fact: 'Hore! Jepang punya Gunung Fuji yang puncaknya bersalju!',
    island: Offset(1180, 380), mapPos: Offset(0.885, 0.33),
    sand: Color(0xFFF0DDB8), grass: Color(0xFF81C784),
    sea1: Color(0xFF7986CB), sea2: Color(0xFF283593),
    deco: ['🌸', '⛩️', '🌸'], mobs: ['🐙', '🦈'],
  ),
  Country(
    name: 'Cina', flag: '🇨🇳', landmark: '🐼', item: '🏮', itemName: 'lampion', itemCount: 5,
    intro: 'Ni hao! Kita di Cina! Kumpulkan lima lampion merah!',
    fact: 'Asyik! Di Cina ada panda yang lucu dan Tembok Besar yang panjang sekali!',
    island: Offset(1240, 450), mapPos: Offset(0.77, 0.36),
    sand: Color(0xFFF1D7A0), grass: Color(0xFF7CB342),
    sea1: Color(0xFF4FC3F7), sea2: Color(0xFF01579B),
    deco: ['🎋', '🐉', '🎋'], mobs: ['🐙', '🦈', '🐙'],
  ),
  Country(
    name: 'Mesir', flag: '🇪🇬', landmark: 'PIRAMIDA', item: '🏺', itemName: 'guci kuno', itemCount: 5,
    intro: 'Kita sampai di Mesir! Kumpulkan lima guci kuno!',
    fact: 'Luar biasa! Mesir punya piramida yang dibuat ribuan tahun yang lalu!',
    island: Offset(1200, 420), mapPos: Offset(0.555, 0.415),
    sand: Color(0xFFFFD180), grass: null,
    sea1: Color(0xFF26C6DA), sea2: Color(0xFF00695C),
    deco: ['🌴', '🐫', '🌴'], mobs: ['🐊', '🦈', '🐙'],
  ),
  Country(
    name: 'Brasil', flag: '🇧🇷', landmark: '🦜', item: '⚽', itemName: 'bola', itemCount: 5,
    intro: 'Ola! Kita di Brasil! Kumpulkan lima bola sepak!',
    fact: 'Hebat! Brasil punya hutan Amazon yang besar, rumah burung beo yang cantik!',
    island: Offset(1230, 390), mapPos: Offset(0.33, 0.60),
    sand: Color(0xFFF3D9A4), grass: Color(0xFF2E7D32),
    sea1: Color(0xFF4DD0E1), sea2: Color(0xFF006064),
    deco: ['🌴', '🐒', '🌳'], mobs: ['🐙', '🦈', '🐡'],
  ),
  Country(
    name: 'Australia', flag: '🇦🇺', landmark: '🦘', item: '🐚', itemName: 'kerang', itemCount: 5,
    intro: 'Halo! Kita di Australia! Kumpulkan lima kerang!',
    fact: 'Hore! Di Australia ada kanguru yang melompat dan koala yang suka tidur!',
    island: Offset(1210, 460), mapPos: Offset(0.85, 0.71),
    sand: Color(0xFFFFCC80), grass: Color(0xFF9CCC65),
    sea1: Color(0xFF29B6F6), sea2: Color(0xFF0D47A1),
    deco: ['🐨', '🌳', '🌴'], mobs: ['🦈', '🦈', '🐙'],
  ),
  Country(
    name: 'Kutub Selatan', flag: '🇦🇶', landmark: '🐧', item: '🐟', itemName: 'ikan untuk penguin', itemCount: 6,
    intro: 'Brrr, dingin! Ini Kutub Selatan, misi terakhir! Kumpulkan enam ikan untuk penguin!',
    fact: 'Kalian berhasil! Penguin senang sekali, dan ini harta karun paling besar!',
    island: Offset(1220, 410), mapPos: Offset(0.50, 0.93),
    sand: Color(0xFFF5FBFF), grass: Color(0xFFD6ECFA),
    sea1: Color(0xFF81D4FA), sea2: Color(0xFF01579B),
    deco: ['⛄', '❄️', '🐧'], mobs: ['🐳', '🐙', '🦈'],
  ),
];

const String finishSpeech =
    'Selamat! Kalian sudah keliling dunia dan menjadi Raja Bajak Laut!';
const List<String> countWords = ['Satu', 'Dua', 'Tiga', 'Empat', 'Lima', 'Enam', 'Tujuh'];

// ---------------------------------------------------------------------
//  SUARA (Text-to-Speech bahasa Indonesia)
// ---------------------------------------------------------------------
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

// ---------------------------------------------------------------------
//  MODEL PERMAINAN (dijalankan oleh Kapten / host)
// ---------------------------------------------------------------------
class Ship {
  final int id;
  double x, y, tx, ty;
  bool left = false;
  bool stuck = false; // ditangkap gurita
  double help = 0; // 0..1 progres ditolong
  double cheer = 0; // waktu bersorak
  Ship(this.id, this.x, this.y)
      : tx = x,
        ty = y;
}

class Item {
  double x, y;
  bool got;
  Item(this.x, this.y, [this.got = false]);
}

class Mob {
  double x, y, vx, vy;
  int grab = -1; // id kapal yang sedang ditangkap
  double cd = 5; // jeda sebelum bisa menangkap lagi
  Mob(this.x, this.y, this.vx, this.vy);
}

/// Bajak laut yang berjalan di pulau.
class Walker {
  final int id;
  double x, y, tx, ty;
  bool left = false, moving = false;
  Walker(this.id, this.x, this.y)
      : tx = x,
        ty = y;
}

/// Semak-semak yang bisa digeledah.
class Bush {
  final double x, y;
  final String c; // 'kunci' / 'cangkul' / 'linggis' / emoji hewan
  bool searched = false;
  double st = 0;
  Bush(this.x, this.y, this.c);
}

class Puzzle {
  final String q, show;
  final List<String> choices;
  final int answer;
  const Puzzle(this.q, this.show, this.choices, this.answer);
}

// --- tata letak pulau besar ---
const double gateX = 600, boulderX = 1000;
const Offset landX = Offset(1400, 445);
const Offset landBeach = Offset(210, 470);
double pathY(double x) => 470 + sin(x / 240) * 80;

bool isTool(String c) => c == 'kunci' || c == 'cangkul' || c == 'linggis';
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

/// Teka-teki untuk anak: slot 1 = gerbang, slot 2 = peti harta.
Puzzle puzzleFor(int mission, int slot) {
  final r = Random(mission * 31 + slot * 7 + 3);
  const gateTypes = [0, 0, 3, 1, 4, 2, 1, 2, 3, 2];
  const chestTypes = [1, 1, 1, 1, 1, 4, 3, 1, 4, 1];
  final type = slot == 2 ? chestTypes[mission % 10] : gateTypes[mission % 10];
  List<String> shuf(List<String> l) {
    final x = [...l];
    x.shuffle(r);
    return x;
  }

  switch (type) {
    case 1: // menghitung
    {
      const things = [
        ['🍌', 'pisang'],
        ['🍎', 'apel'],
        ['🐟', 'ikan'],
        ['⭐', 'bintang'],
        ['🥥', 'kelapa'],
      ];
      final th = things[r.nextInt(things.length)];
      final n = 2 + r.nextInt(4);
      final opts = <int>{n};
      while (opts.length < 3) {
        final v = 1 + r.nextInt(6);
        opts.add(v);
      }
      final ch = shuf([for (final v in opts) '$v']);
      return Puzzle('Ada berapa ${th[1]}? Ayo hitung!', List.filled(n, th[0]).join(' '), ch, ch.indexOf('$n'));
    }
    case 2: // pola
    {
      const pairs = [
        ['🍎', '🍌'],
        ['⭐', '🌙'],
        ['🐟', '🐚'],
        ['❤️', '💙'],
        ['🐶', '🐱'],
      ];
      final i = r.nextInt(pairs.length);
      final p = pairs[i];
      final other = pairs[(i + 1 + r.nextInt(pairs.length - 1)) % pairs.length][0];
      final ch = shuf([p[0], p[1], other]);
      return Puzzle('Apa gambar selanjutnya? Lihat polanya!', '${p[0]} ${p[1]} ${p[0]} ${p[1]} ❓', ch, ch.indexOf(p[0]));
    }
    case 3: // kategori
    {
      const qs = [
        ['Mana yang bisa terbang?', '🐦', '🐟', '🐢'],
        ['Mana yang hidup di laut?', '🐠', '🐄', '🐒'],
        ['Mana yang buah?', '🍌', '🚗', '⚽'],
        ['Mana hewan yang paling besar?', '🐘', '🐭', '🐜'],
        ['Mana yang dingin?', '⛄', '🔥', '☀️'],
      ];
      final qq = qs[r.nextInt(qs.length)];
      final ch = shuf([qq[1], qq[2], qq[3]]);
      return Puzzle(qq[0], '', ch, ch.indexOf(qq[1]));
    }
    case 4: // mana yang berbeda
    {
      const pairs = [
        ['🐶', '🐱'],
        ['🍎', '🍌'],
        ['🚗', '🚲'],
        ['🐟', '🐢'],
        ['⭐', '🌙'],
      ];
      final p = pairs[r.nextInt(pairs.length)];
      final ch = shuf([p[0], p[0], p[1]]);
      return Puzzle('Mana yang berbeda?', '', ch, ch.indexOf(p[1]));
    }
    default: // warna
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

double _n(dynamic v) => (v as num).toDouble();
double _r1(double v) => (v * 10).roundToDouble() / 10;

class GameState {
  int mission = 0;
  String phase = 'map'; // map, sail, island(batu), dig, treasure, finish
  double phaseT = 0;
  final Map<int, Ship> ships = {};
  List<Item> items = [];
  List<Mob> mobs = [];
  int dig = 0, digNeed = 12, coins = 0;
  // --- pulau besar ---
  final Map<int, Walker> walkers = {};
  List<Bush> bushes = [];
  final Set<String> tools = {};
  bool gateOpen = true;
  double boulderHp = 0;
  int pz = 0; // 0 tidak ada, 1 teka-teki gerbang, 2 teka-teki peti
  double hintCd = 0;
  int evId = 0;
  final List<Map<String, dynamic>> events = [];
  double bumpCd = 0;

  void Function(Map<String, dynamic> e)? onEmit;
  void Function(int mission, int coins)? onMissionDone;

  Country get c => countries[mission.clamp(0, countries.length - 1)];
  Offset get xPos => landX;
  Offset get dock => Offset(c.island.dx - islandR - 48, c.island.dy + 40);
  int get gotCount => items.where((i) => i.got).length;
  bool get onLand => phase == 'land' || phase == 'dig' || phase == 'chest' || phase == 'treasure' || phase == 'finish';
  bool get hasGate => gateFor(mission);
  bool get hasBoulder => boulderFor(mission);
  Offset get boulderPos => Offset(boulderX, pathY(boulderX));
  Offset get gatePos => Offset(gateX, pathY(gateX));
  bool get anyStuck => ships.values.any((s) => s.stuck);

  void emit(Map<String, dynamic> e) {
    evId++;
    e['id'] = evId;
    events.add(e);
    if (events.length > 30) events.removeAt(0);
    onEmit?.call(e);
  }

  void say(String s) => emit({'k': 'say', 's': s});

  Offset _startPos(int id) => Offset(140, 220.0 + (id % 4) * 130);

  void addShip(int id) {
    final p = _startPos(id);
    ships[id] = Ship(id, p.dx, p.dy);
  }

  void startMission(int m) {
    mission = m.clamp(0, countries.length - 1);
    phase = 'map';
    phaseT = 0;
    dig = 0;
    pz = 0;
    tools.clear();
    walkers.clear();
    bushes = [];
    gateOpen = true;
    boulderHp = 0;
    final r = Random(mission * 977 + 13);
    final isl = c.island;
    items = [];
    for (int i = 0; i < c.itemCount; i++) {
      Offset p = const Offset(600, 400);
      for (int a = 0; a < 300; a++) {
        final cand = Offset(260 + r.nextDouble() * (worldW - 460), 160 + r.nextDouble() * (worldH - 240));
        if ((cand - isl).distance < islandR + 100) continue;
        if ((cand - dock).distance < 140) continue;
        if (items.any((it) => (Offset(it.x, it.y) - cand).distance < 170)) continue;
        p = cand;
        break;
      }
      items.add(Item(p.dx, p.dy));
    }
    mobs = [];
    for (int i = 0; i < c.mobs.length; i++) {
      final ang = r.nextDouble() * pi * 2;
      final sp = 55 + r.nextDouble() * 35;
      final x = 520 + r.nextDouble() * 450;
      final y = 180 + r.nextDouble() * (worldH - 280);
      mobs.add(Mob(x, y, cos(ang) * sp, sin(ang) * sp)..cd = 6 + i * 4.0);
    }
    for (final s in ships.values) {
      final p = _startPos(s.id);
      s
        ..x = p.dx
        ..y = p.dy
        ..tx = p.dx
        ..ty = p.dy
        ..left = false
        ..stuck = false
        ..help = 0
        ..cheer = 0;
    }
    say('Misi ${mission + 1}! Ayo berlayar ke ${c.name}!');
  }

  Offset _clampTarget(double x, double y) {
    x = x.clamp(60.0, worldW - 60);
    y = y.clamp(110.0, worldH - 50);
    final isl = c.island;
    final d = Offset(x, y) - isl;
    final lim = islandR + 25;
    if (d.distance < lim) {
      final dir = d.distance < 1 ? const Offset(-1, 0) : d / d.distance;
      final p = isl + dir * lim;
      return Offset(p.dx, p.dy);
    }
    return Offset(x, y);
  }

  void _pushOut(Ship s) {
    final p = _clampTarget(s.x, s.y);
    s.x = p.dx;
    s.y = p.dy;
  }

  bool get _seaPhase => phase == 'sail' || phase == 'island';

  void tap(int id, double x, double y, {bool move = false}) {
    if (phase == 'map' || phase == 'finish') return;
    if (onLand) {
      _tapLand(id, x, y, move);
      return;
    }
    final s = ships[id];
    if (s == null) return;
    final tp = Offset(x, y);

    // gelitik gurita yang sedang menangkap kapal
    for (final m in mobs) {
      if (!move && m.grab >= 0 && (tp - Offset(m.x, m.y)).distance < 90) {
        final victim = ships[m.grab];
        if (victim != null && victim.stuck) {
          victim.help += 0.13;
          emit({'k': 'tickle', 'x': m.x, 'y': m.y});
          if (victim.help >= 1) _free(victim, id == victim.id ? null : id);
          return;
        }
      }
    }
    if (s.stuck) return;

    final t = _clampTarget(x, y);
    s.tx = t.dx;
    s.ty = t.dy;
  }

  void _free(Ship s, int? helperId) {
    s.stuck = false;
    s.help = 0;
    s.cheer = 2.5;
    final h = helperId == null ? null : ships[helperId];
    if (h != null) h.cheer = 2.5;
    for (final m in mobs) {
      if (m.grab == s.id) {
        m.grab = -1;
        m.cd = 14;
        final away = Offset(m.x - s.x, m.y - s.y);
        final d = max(1.0, away.distance);
        m.vx = away.dx / d * 150;
        m.vy = away.dy / d * 150;
        m.x += away.dx / d * 50;
        m.y += away.dy / d * 50;
      }
    }
    emit({'k': 'free', 'x': s.x, 'y': s.y});
    if (h != null) {
      say('Terima kasih, teman! Kita tim yang hebat!');
    } else {
      say('Hihi, guritanya geli! Kapal bebas lagi!');
    }
  }

  // ================= PULAU BESAR =================
  void _enterLand() {
    phase = 'land';
    phaseT = 0;
    pz = 0;
    tools.clear();
    gateOpen = !hasGate;
    boulderHp = hasBoulder ? 1 : 0;
    for (final s in ships.values) {
      s.stuck = false;
      s.help = 0;
    }
    for (final m in mobs) {
      m.grab = -1;
    }
    walkers.clear();
    final ids = ships.keys.toList()..sort();
    for (int i = 0; i < ids.length; i++) {
      walkers[ids[i]] = Walker(ids[i], landBeach.dx, 300.0 + i * 110);
    }
    // semak-semak berisi alat & hewan lucu
    final r = Random(mission * 53 + 7);
    final z1 = [260.0, hasGate ? gateX - 90 : 1280.0];
    final z2 = [gateX + 80, hasBoulder ? boulderX - 100 : 1280.0];
    final z3 = [boulderX + 90, 1280.0];
    final zones = <List<double>>[z1, if (hasGate) z2, if (hasBoulder) z3];
    final contents = <String, List<double>>{};
    bushes = [];
    void place(String c, List<double> z) {
      Offset p = Offset((z[0] + z[1]) / 2, 250);
      for (int a = 0; a < 200; a++) {
        final cand = Offset(z[0] + r.nextDouble() * (z[1] - z[0]), 200 + r.nextDouble() * 540);
        if (bushes.any((b) => (Offset(b.x, b.y) - cand).distance < 130)) continue;
        if ((cand - landX).distance < 160) continue;
        if ((cand.dy - pathY(cand.dx)).abs() < 50) continue;
        p = cand;
        break;
      }
      bushes.add(Bush(p.dx, p.dy, c));
    }

    for (final t in toolsFor(mission)) {
      final z = t == 'kunci' ? z1 : (t == 'linggis' ? z2 : zones.last);
      contents[t] = z;
      place(t, z);
    }
    final decoyList = decoyNames.keys.toList();
    final nDecoy = min(5, 1 + mission ~/ 2);
    for (int i = 0; i < nDecoy; i++) {
      place(decoyList[r.nextInt(decoyList.length)], zones[i % zones.length]);
    }
    say('Kita mendarat di pulau ${c.name}! ${_nextHint(true)}');
  }

  String _nextHint(bool speak) {
    if (hasGate && !gateOpen) {
      return tools.contains('kunci')
          ? (speak ? 'Bawa kuncinya ke gerbang!' : 'Bawa kunci ke gerbang 🚪')
          : (speak ? 'Cari kunci di semak-semak!' : 'Cari kunci 🗝️ di semak-semak');
    }
    if (hasBoulder && boulderHp > 0) {
      return tools.contains('linggis')
          ? (speak ? 'Hancurkan batunya dengan linggis, bersama-sama!' : 'Hancurkan batu bersama! 💪')
          : (speak ? 'Ada batu besar! Cari linggis di semak-semak!' : 'Cari linggis di semak-semak');
    }
    if (!tools.contains('cangkul')) {
      return speak ? 'Cari cangkul di semak-semak!' : 'Cari cangkul di semak-semak';
    }
    return speak ? 'Ayo ke tanda X merah dan gali hartanya!' : 'Pergi ke tanda ❌ dan gali!';
  }

  String hintText() => _nextHint(false);
  String hintSpeech() => _nextHint(true);

  Offset _clampLand(double x, double y) {
    x = x.clamp(170.0, 1520.0);
    y = y.clamp(170.0, 760.0);
    if (hasGate && !gateOpen) x = min(x, gateX - 45);
    if (hasBoulder && boulderHp > 0) x = min(x, boulderX - 75);
    return Offset(x, y);
  }

  void _tapLand(int id, double x, double y, bool move) {
    if (pz != 0) return;
    final w = walkers[id];
    if (w == null) return;
    final tp = Offset(x, y);
    if (!move && phase == 'dig' && (tp - landX).distance < 130) {
      doDig(id);
      return;
    }
    if (!move && hasBoulder && boulderHp > 0 && (tp - boulderPos).distance < 110 && tools.contains('linggis')) {
      if (walkers.values.any((o) => (Offset(o.x, o.y) - boulderPos).distance < 190)) {
        _hitBoulder(0.05);
        emit({'k': 'rocktap', 'x': boulderPos.dx, 'y': boulderPos.dy});
      }
    }
    Offset target = tp;
    for (final b in bushes) {
      if (!b.searched && (Offset(b.x, b.y) - tp).distance < 75) {
        target = Offset(b.x - 40, b.y + 10);
        break;
      }
    }
    final t = _clampLand(target.dx, target.dy);
    w.tx = t.dx;
    w.ty = t.dy;
  }

  void _hitBoulder(double amount) {
    if (!(hasBoulder && boulderHp > 0)) return;
    boulderHp -= amount;
    if (boulderHp <= 0) {
      boulderHp = 0;
      emit({'k': 'rockbreak', 'x': boulderPos.dx, 'y': boulderPos.dy});
      say('Batunya hancur! Kerja sama yang hebat! ${_nextHint(true)}');
    }
  }

  void _hint(String text) {
    if (hintCd > 0) return;
    hintCd = 7;
    say(text);
  }

  void answer(int id, int choice) {
    if (pz == 0) return;
    final p = puzzleFor(mission, pz);
    if (choice == p.answer) {
      emit({'k': 'correct'});
      if (pz == 1) {
        pz = 0;
        gateOpen = true;
        emit({'k': 'gate', 'x': gateX, 'y': pathY(gateX)});
        say('Benar! Gerbangnya terbuka! ${_nextHint(true)}');
      } else {
        pz = 0;
        _treasure();
      }
    } else {
      emit({'k': 'wrong'});
      say('Hmm, belum tepat. Coba lagi ya!');
    }
  }

  void _treasure() {
    phase = 'treasure';
    phaseT = 0;
    coins += 10;
    for (final s in ships.values) {
      s.cheer = 7;
    }
    emit({'k': 'treasure', 'x': landX.dx, 'y': landX.dy});
    say(c.fact);
    onMissionDone?.call(mission, coins);
  }

  void _updateLand(double dt) {
    hintCd -= dt;
    // jalan
    for (final w in walkers.values) {
      final dx = w.tx - w.x, dy = w.ty - w.y;
      final d = sqrt(dx * dx + dy * dy);
      if (d > 4) {
        final step = min(d, 230 * dt);
        w.x += dx / d * step;
        w.y += dy / d * step;
        if (dx.abs() > 2) w.left = dx < 0;
        w.moving = true;
      } else {
        w.moving = false;
      }
      final p = _clampLand(w.x, w.y);
      w.x = p.dx;
      w.y = p.dy;
    }
    if (phase == 'treasure') {
      if (phaseT > 7.5) {
        if (mission >= countries.length - 1) {
          phase = 'finish';
          phaseT = 0;
          say(finishSpeech);
          emit({'k': 'fw'});
        } else {
          startMission(mission + 1);
        }
      }
      return;
    }
    if (phase != 'land') return;
    if (pz != 0) return;

    // geledah semak
    for (final b in bushes) {
      if (b.searched) continue;
      final near = walkers.values.any((w) => (Offset(w.x, w.y) - Offset(b.x, b.y)).distance < 80);
      if (!near) {
        b.st = 0;
        continue;
      }
      b.st += dt;
      if (b.st >= 0.6) {
        b.searched = true;
        if (isTool(b.c)) {
          tools.add(b.c);
          emit({'k': 'found', 'x': b.x, 'y': b.y, 'tool': b.c});
          say('Hore! Kita dapat ${b.c}! ${_nextHint(true)}');
        } else {
          emit({'k': 'decoy', 'x': b.x, 'y': b.y, 'e': b.c});
          say('Cuma ada ${decoyNames[b.c] ?? 'hewan kecil'}. Cari di semak lain!');
        }
        hintCd = 4;
      }
    }

    // gerbang terkunci
    if (hasGate && !gateOpen && walkers.values.any((w) => w.x > gateX - 75)) {
      if (tools.contains('kunci')) {
        pz = 1;
        emit({'k': 'puzzle'});
        say('Gerbangnya dikunci teka-teki! ${puzzleFor(mission, 1).q}');
        return;
      } else {
        _hint('Gerbangnya terkunci! Cari kunci di semak-semak!');
      }
    }

    // batu besar
    if (hasBoulder && boulderHp > 0) {
      final n = walkers.values.where((w) => (Offset(w.x, w.y) - boulderPos).distance < 190).length;
      if (n > 0) {
        if (tools.contains('linggis')) {
          _hitBoulder(dt * 0.1 * n * (1 + 0.35 * (n - 1)));
        } else {
          _hint('Batunya keras sekali! Cari linggis dulu di semak-semak!');
        }
      }
    }

    // tanda X
    if (walkers.values.any((w) => (Offset(w.x, w.y) - landX).distance < 130)) {
      if (tools.contains('cangkul')) {
        phase = 'dig';
        phaseT = 0;
        dig = 0;
        digNeed = 10 + 4 * walkers.length;
        const spots = [Offset(-82, -6), Offset(82, -6), Offset(-66, 54), Offset(72, 54)];
        final ids = walkers.keys.toList()..sort();
        for (int i = 0; i < ids.length; i++) {
          final w = walkers[ids[i]]!;
          final sp = landX + spots[i % 4];
          w.tx = sp.dx;
          w.ty = sp.dy + 40;
        }
        say('Ayo gali bersama-sama! Ketuk cangkulnya!');
      } else {
        _hint('Hartanya di sini! Tapi kita perlu cangkul. Cari di semak-semak!');
      }
    }
  }

  void doDig(int id) {
    if (phase != 'dig') return;
    dig++;
    emit({'k': 'dig', 'x': xPos.dx, 'y': xPos.dy});
    if (dig >= digNeed) {
      if (chestPuzzleFor(mission)) {
        phase = 'chest';
        phaseT = 0;
        pz = 2;
        emit({'k': 'puzzle'});
        say('Petinya ketemu, tapi dikunci teka-teki! ${puzzleFor(mission, 2).q}');
      } else {
        _treasure();
      }
    }
  }

  void update(double dt) {
    final prevT = phaseT;
    phaseT += dt;
    bumpCd -= dt;

    if (phase == 'map') {
      if (phaseT > 4.5) {
        phase = 'sail';
        phaseT = 0;
        say(c.intro);
      }
      return;
    }
    if (phase == 'finish') return;
    if (onLand) {
      _updateLand(dt);
      return;
    }

    // --- gerak kapal ---
    for (final s in ships.values) {
      if (s.cheer > 0) s.cheer -= dt;
      if (s.stuck) continue;
      final dx = s.tx - s.x, dy = s.ty - s.y;
      final d = sqrt(dx * dx + dy * dy);
      if (d > 4) {
        final step = min(d, 250 * dt);
        s.x += dx / d * step;
        s.y += dy / d * step;
        if (dx.abs() > 2) s.left = dx < 0;
      }
      _pushOut(s);
    }

    // --- teman menolong kapal yang ditangkap ---
    for (final s in ships.values) {
      if (!s.stuck) continue;
      int? helper;
      for (final o in ships.values) {
        if (o.id == s.id || o.stuck) continue;
        if ((Offset(o.x, o.y) - Offset(s.x, s.y)).distance < 120) {
          s.help += dt * 0.9;
          helper = o.id;
        }
      }
      if (s.help >= 1) _free(s, helper);
    }

    // --- gerak hewan laut ---
    final isl = c.island;
    for (int i = 0; i < mobs.length; i++) {
      final m = mobs[i];
      final emo = c.mobs[i % c.mobs.length];
      if (m.grab >= 0) {
        final v = ships[m.grab];
        if (v == null || !v.stuck || !_seaPhase) {
          m.grab = -1;
          m.cd = 14;
          if (v != null) v.stuck = false;
        } else {
          m.x = v.x + 46 + sin(phaseT * 5) * 4;
          m.y = v.y + 18;
          continue;
        }
      }
      m.cd -= dt;
      // gurita mengincar kapal terdekat
      if (emo == '🐙' && m.cd <= 0 && _seaPhase && !anyStuck) {
        Ship? near;
        double best = 1e9;
        for (final s in ships.values) {
          final d = (Offset(s.x, s.y) - Offset(m.x, m.y)).distance;
          if (d < best) {
            best = d;
            near = s;
          }
        }
        if (near != null && best > 1) {
          final dir = (Offset(near.x, near.y) - Offset(m.x, m.y)) / best;
          m.vx += (dir.dx * 95 - m.vx) * min(1.0, dt * 0.8);
          m.vy += (dir.dy * 95 - m.vy) * min(1.0, dt * 0.8);
        }
      } else {
        final turn = sin(phaseT * 0.7 + i * 1.7) * 0.6 * dt;
        final vx = m.vx * cos(turn) - m.vy * sin(turn);
        final vy = m.vx * sin(turn) + m.vy * cos(turn);
        m.vx = vx;
        m.vy = vy;
      }
      m.x += m.vx * dt;
      m.y += m.vy * dt;
      if ((m.x < 80 && m.vx < 0) || (m.x > worldW - 80 && m.vx > 0)) m.vx = -m.vx;
      if ((m.y < 140 && m.vy < 0) || (m.y > worldH - 60 && m.vy > 0)) m.vy = -m.vy;
      final dv = Offset(m.x, m.y) - isl;
      final dd = dv.distance;
      if (dd < islandR + 60 && dd > 0.1) {
        final nx = dv.dx / dd, ny = dv.dy / dd;
        final dot = m.vx * nx + m.vy * ny;
        if (dot < 0) {
          m.vx -= 2 * dot * nx;
          m.vy -= 2 * dot * ny;
        }
        m.x = isl.dx + nx * (islandR + 60);
        m.y = isl.dy + ny * (islandR + 60);
      }
      // bertemu kapal
      for (final s in ships.values) {
        if (s.stuck) continue;
        final ds = Offset(s.x - m.x, s.y - m.y);
        final d = ds.distance;
        if (d >= 70) continue;
        if (emo == '🐙' && m.cd <= 0 && _seaPhase && !anyStuck) {
          // gurita menangkap kapal!
          s.stuck = true;
          s.help = 0;
          s.tx = s.x;
          s.ty = s.y;
          m.grab = s.id;
          emit({'k': 'grab', 'pid': s.id, 'x': s.x, 'y': s.y});
          if (ships.length > 1) {
            say('Tolong! Gurita menangkap kapal ${shipNames[s.id % 4]}! Teman-teman, ayo bantu!');
          } else {
            say('Tolong! Gurita menangkap kapalmu! Ketuk guritanya biar geli!');
          }
          break;
        }
        final dir = d < 1 ? const Offset(1, 0) : ds / d;
        s.x += dir.dx * 60;
        s.y += dir.dy * 60;
        _pushOut(s);
        s.tx = s.x;
        s.ty = s.y;
        m.vx = -m.vx;
        m.vy = -m.vy;
        m.x -= dir.dx * 20;
        m.y -= dir.dy * 20;
        emit({'k': 'bump', 'pid': s.id, 'x': s.x, 'y': s.y});
        if (bumpCd <= 0) {
          say(emo == '🦈' ? 'Ups, hiunya iseng!' : 'Ups, cuma bercanda!');
          bumpCd = 8;
        }
      }
    }

    // --- misi ---
    if (phase == 'sail') {
      for (final it in items) {
        if (it.got) continue;
        for (final s in ships.values) {
          if (s.stuck) continue;
          if ((Offset(s.x, s.y) - Offset(it.x, it.y)).distance < 62) {
            it.got = true;
            coins += 1;
            emit({'k': 'pop', 'x': it.x, 'y': it.y});
            final n = gotCount;
            say('${countWords[(n - 1).clamp(0, countWords.length - 1)]}!');
            break;
          }
        }
      }
      if (items.every((i) => i.got)) {
        phase = 'island';
        phaseT = 0;
      }
    } else if (phase == 'island') {
      if (prevT < 1.0 && phaseT >= 1.0) {
        say('Hebat! Sekarang berlayar ke dermaga pulau!');
      }
      for (final s in ships.values) {
        if (!s.stuck && (Offset(s.x, s.y) - dock).distance < 130) {
          _enterLand();
          break;
        }
      }
    }
  }

  // --- serialisasi untuk mabar ---
  Map<String, dynamic> toJson() => {
        't': 's',
        'm': mission,
        'p': phase,
        'pt': _r1(phaseT),
        'dg': dig,
        'dn': digNeed,
        'c': coins,
        'lw': [
          for (final w in walkers.values) [w.id, _r1(w.x), _r1(w.y), w.left ? 1 : 0, w.moving ? 1 : 0]
        ],
        'bu': [
          for (final b in bushes) [_r1(b.x), _r1(b.y), b.searched ? 1 : 0, b.c]
        ],
        'tl': tools.toList(),
        'go': gateOpen ? 1 : 0,
        'bh': (boulderHp * 100).round() / 100,
        'pz': pz,
        'sh': [
          for (final s in ships.values)
            [
              s.id,
              _r1(s.x),
              _r1(s.y),
              s.left ? 1 : 0,
              s.stuck ? 1 : 0,
              (s.help * 100).round() / 100,
              _r1(max(0.0, s.cheer)),
            ]
        ],
        'it': [
          for (final i in items) [_r1(i.x), _r1(i.y), i.got ? 1 : 0]
        ],
        'mb': [
          for (final m in mobs) [_r1(m.x), _r1(m.y), m.grab]
        ],
        'ev': events,
      };

  List<Map<String, dynamic>> applyJson(Map<String, dynamic> j) {
    mission = (j['m'] as num).toInt();
    phase = j['p'] as String;
    phaseT = _n(j['pt']);
    dig = (j['dg'] as num).toInt();
    digNeed = (j['dn'] as num).toInt();
    coins = (j['c'] as num).toInt();
    final lw = (j['lw'] as List?) ?? const [];
    final wseen = <int>{};
    for (final a in lw) {
      final l = a as List;
      final id = (l[0] as num).toInt();
      wseen.add(id);
      final w = walkers.putIfAbsent(id, () => Walker(id, _n(l[1]), _n(l[2])));
      w.x = _n(l[1]);
      w.y = _n(l[2]);
      w.left = (l[3] as num).toInt() == 1;
      w.moving = (l[4] as num).toInt() == 1;
    }
    walkers.removeWhere((k, v) => !wseen.contains(k));
    bushes = [
      for (final a in ((j['bu'] as List?) ?? const []))
        Bush(_n((a as List)[0]), _n(a[1]), a[3] as String)..searched = (a[2] as num).toInt() == 1
    ];
    tools
      ..clear()
      ..addAll([for (final t in ((j['tl'] as List?) ?? const [])) t as String]);
    gateOpen = (j['go'] as num?)?.toInt() != 0;
    boulderHp = j['bh'] is num ? _n(j['bh']) : 0;
    pz = (j['pz'] as num?)?.toInt() ?? 0;
    final seen = <int>{};
    for (final a in (j['sh'] as List)) {
      final l = a as List;
      final id = (l[0] as num).toInt();
      seen.add(id);
      final s = ships.putIfAbsent(id, () => Ship(id, _n(l[1]), _n(l[2])));
      s.x = _n(l[1]);
      s.y = _n(l[2]);
      s.left = (l[3] as num).toInt() == 1;
      if (l.length >= 7) {
        s.stuck = (l[4] as num).toInt() == 1;
        s.help = _n(l[5]);
        s.cheer = _n(l[6]);
      }
    }
    ships.removeWhere((k, v) => !seen.contains(k));
    items = [
      for (final a in (j['it'] as List))
        Item(_n((a as List)[0]), _n(a[1]), (a[2] as num).toInt() == 1)
    ];
    mobs = [
      for (final a in (j['mb'] as List))
        Mob(_n((a as List)[0]), _n(a[1]), 0, 0)..grab = a.length > 2 ? (a[2] as num).toInt() : -1
    ];
    return [
      for (final e in (j['ev'] as List)) Map<String, dynamic>.from(e as Map)
    ];
  }
}

// ---------------------------------------------------------------------
//  SESI: main sendiri / Kapten (host) / ikut main (client)
// ---------------------------------------------------------------------
class Room {
  final String ip, name;
  DateTime seen;
  Room(this.ip, this.name, this.seen);
}

class Session {
  final bool isHost;
  final bool solo;
  final int startMission;
  Session._(this.isHost, this.solo, this.startMission);

  int myId = 0;
  final GameState gs = GameState();
  final Map<int, Socket> _peers = {};
  ServerSocket? _server;
  RawDatagramSocket? _udp;
  Timer? _timer;
  Socket? _sock;
  final Map<String, Room> rooms = {};
  final String roomName = 'Kapal ${Random().nextInt(90) + 10}';
  List<int> lobbyIds = [0];
  List<String> myIps = [];
  bool started = false, lost = false, connected = false, full = false, closed = false;
  int _nextId = 1;
  double _acc = 0;
  int _lastEv = 0;
  SharedPreferences? _prefs;

  VoidCallback? onChange;
  void Function(Map<String, dynamic> e)? _onEvent;
  final List<Map<String, dynamic>> _pending = [];

  static const MethodChannel _wifi = MethodChannel('harta/wifi');

  // ---------- pembuat sesi ----------
  static Future<Session> createSolo(int m) async {
    final s = Session._(true, true, m);
    await s._setupHost();
    s.startGame();
    return s;
  }

  static Future<Session> createHost(int m) async {
    final s = Session._(true, false, m);
    await s._setupHost();
    await s._lock();
    try {
      s._server = await ServerSocket.bind(InternetAddress.anyIPv4, gamePort, shared: true);
      s._server!.listen(s._accept, onError: (_) {});
    } catch (_) {}
    await s._openUdp();
    s._timer = Timer.periodic(const Duration(seconds: 1), (_) => s._announce());
    s.myIps = await _localIps();
    return s;
  }

  static Future<Session> createClient() async {
    final s = Session._(false, false, 0);
    await s._lock();
    await s._openUdp();
    s._timer = Timer.periodic(const Duration(milliseconds: 1500), (_) => s._probe());
    s._probe();
    s.myIps = await _localIps();
    return s;
  }

  Future<void> _setupHost() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {}
    gs.coins = _prefs?.getInt('coins') ?? 0;
    gs.onEmit = _dispatch;
    gs.onMissionDone = _saveProgress;
    gs.addShip(0);
  }

  void _saveProgress(int m, int coins) {
    final p = _prefs;
    if (p == null) return;
    final u = p.getInt('unlocked') ?? 0;
    if (m + 1 > u) p.setInt('unlocked', min(m + 1, countries.length - 1));
    if (m == countries.length - 1) p.setBool('tamat', true);
    p.setInt('coins', coins);
  }

  void attach(void Function(Map<String, dynamic> e) handler) {
    _onEvent = handler;
    for (final e in _pending) {
      handler(e);
    }
    _pending.clear();
  }

  void _dispatch(Map<String, dynamic> e) {
    final h = _onEvent;
    if (h != null) {
      h(e);
    } else {
      _pending.add(e);
      if (_pending.length > 6) _pending.removeAt(0);
    }
  }

  void _changed() {
    if (!closed) onChange?.call();
  }

  Future<void> _lock() async {
    try {
      await _wifi.invokeMethod('acquire');
    } catch (_) {}
  }

  static Future<List<InternetAddress>> _targets() async {
    final out = <InternetAddress>[InternetAddress('255.255.255.255')];
    try {
      final list = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      for (final ni in list) {
        for (final a in ni.addresses) {
          final p = a.address.split('.');
          if (p.length == 4) out.add(InternetAddress('${p[0]}.${p[1]}.${p[2]}.255'));
        }
      }
    } catch (_) {}
    return out;
  }

  static Future<List<String>> _localIps() async {
    final out = <String>[];
    try {
      final list = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      for (final ni in list) {
        for (final a in ni.addresses) {
          out.add(a.address);
        }
      }
    } catch (_) {}
    return out;
  }

  String get _beaconMsg => 'HK|$roomName|$gamePort';

  void _sendUdp(String msg, InternetAddress to) {
    try {
      _udp?.send(utf8.encode(msg), to, discPort);
    } catch (_) {}
  }

  Future<void> _openUdp() async {
    try {
      final u = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discPort, reuseAddress: true);
      u.broadcastEnabled = true;
      _udp = u;
      u.listen((ev) {
        if (ev != RawSocketEvent.read) return;
        final d = u.receive();
        if (d == null) return;
        String msg;
        try {
          msg = utf8.decode(d.data);
        } catch (_) {
          return;
        }
        if (isHost) {
          if (msg == 'HK?') _sendUdp(_beaconMsg, d.address);
        } else if (msg.startsWith('HK|')) {
          final p = msg.split('|');
          final ip = d.address.address;
          rooms[ip] = Room(ip, p.length > 1 ? p[1] : 'Kapal', DateTime.now());
          _changed();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  Future<void> _announce() async {
    if (closed) return;
    for (final t in await _targets()) {
      _sendUdp(_beaconMsg, t);
    }
  }

  Future<void> _probe() async {
    if (closed) return;
    for (final t in await _targets()) {
      _sendUdp('HK?', t);
    }
    final now = DateTime.now();
    final before = rooms.length;
    rooms.removeWhere((k, r) => now.difference(r.seen).inSeconds > 6);
    if (rooms.length != before) _changed();
  }

  // ---------- host ----------
  void _accept(Socket so) {
    if (_peers.length >= 3 || closed) {
      try {
        so.write('{"t":"full"}\n');
        so.destroy();
      } catch (_) {}
      return;
    }
    final id = _nextId++;
    _peers[id] = so;
    try {
      so.setOption(SocketOption.tcpNoDelay, true);
    } catch (_) {}
    gs.addShip(id);
    _send(so, {'t': 'w', 'id': id});
    utf8.decoder.bind(so).transform(const LineSplitter()).listen((line) {
      try {
        _fromClient(id, jsonDecode(line) as Map<String, dynamic>);
      } catch (_) {}
    }, onDone: () => _drop(id), onError: (_) => _drop(id), cancelOnError: true);
    _lobbyUpdate();
    if (started) _send(so, {'t': 'go'});
  }

  void _drop(int id) {
    final so = _peers.remove(id);
    if (so != null) {
      try {
        so.destroy();
      } catch (_) {}
      gs.ships.remove(id);
      _lobbyUpdate();
    }
  }

  void _lobbyUpdate() {
    lobbyIds = [0, ..._peers.keys];
    _broadcast({'t': 'l', 'n': lobbyIds});
    _changed();
  }

  void _fromClient(int id, Map<String, dynamic> m) {
    switch (m['t']) {
      case 'tap':
        gs.tap(id, _n(m['x']), _n(m['y']), move: m['mv'] == 1);
        break;
      case 'dig':
        gs.doDig(id);
        break;
      case 'ans':
        gs.answer(id, (m['i'] as num).toInt());
        break;
    }
  }

  void _send(Socket s, Map<String, dynamic> m) {
    try {
      s.write('${jsonEncode(m)}\n');
    } catch (_) {}
  }

  void _broadcast(Map<String, dynamic> m) {
    if (_peers.isEmpty) return;
    final str = '${jsonEncode(m)}\n';
    for (final s in _peers.values.toList()) {
      try {
        s.write(str);
      } catch (_) {}
    }
  }

  void startGame() {
    started = true;
    gs.startMission(startMission);
    _broadcast({'t': 'go'});
    _changed();
  }

  // ---------- client ----------
  Future<bool> join(String ip) async {
    try {
      final so = await Socket.connect(ip.trim(), gamePort, timeout: const Duration(seconds: 5));
      _sock = so;
      try {
        so.setOption(SocketOption.tcpNoDelay, true);
      } catch (_) {}
      connected = true;
      lost = false;
      full = false;
      utf8.decoder.bind(so).transform(const LineSplitter()).listen((line) {
        try {
          _fromHost(jsonDecode(line) as Map<String, dynamic>);
        } catch (_) {}
      }, onDone: _hostGone, onError: (_) => _hostGone(), cancelOnError: true);
      _changed();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _hostGone() {
    if (closed) return;
    lost = true;
    connected = false;
    _changed();
  }

  void _fromHost(Map<String, dynamic> m) {
    switch (m['t']) {
      case 'w':
        myId = (m['id'] as num).toInt();
        break;
      case 'l':
        lobbyIds = [for (final v in (m['n'] as List)) (v as num).toInt()];
        break;
      case 'go':
        started = true;
        break;
      case 'full':
        full = true;
        break;
      case 's':
        started = true;
        final evs = gs.applyJson(m);
        if (_lastEv == 0) {
          // baru gabung: jangan putar ulang suara lama
          for (final e in evs) {
            _lastEv = max(_lastEv, (e['id'] as num).toInt());
          }
          if (_lastEv == 0) _lastEv = -1;
        } else {
          for (final e in evs) {
            final id = (e['id'] as num).toInt();
            if (id > _lastEv) {
              _lastEv = id;
              _dispatch(e);
            }
          }
        }
        break;
    }
    _changed();
  }

  // ---------- dipakai layar game ----------
  void tick(double dt) {
    if (closed) return;
    if (isHost) {
      gs.update(dt);
      if (!solo) {
        _acc += dt;
        if (_acc >= 0.05) {
          _acc = 0;
          _broadcast(gs.toJson());
        }
      }
    } else {
      gs.phaseT += dt;
    }
  }

  void tap(double x, double y, {bool move = false}) {
    if (isHost) {
      gs.tap(myId, x, y, move: move);
    } else {
      final so = _sock;
      if (so != null) _send(so, {'t': 'tap', 'x': _r1(x), 'y': _r1(y), if (move) 'mv': 1});
    }
  }

  void answer(int i) {
    if (isHost) {
      gs.answer(myId, i);
    } else {
      final so = _sock;
      if (so != null) _send(so, {'t': 'ans', 'i': i});
    }
  }

  void digTap() {
    if (isHost) {
      gs.doDig(myId);
    } else {
      final so = _sock;
      if (so != null) _send(so, {'t': 'dig'});
    }
  }

  void close() {
    if (closed) return;
    closed = true;
    onChange = null;
    _onEvent = null;
    _timer?.cancel();
    try {
      _udp?.close();
    } catch (_) {}
    try {
      _server?.close();
    } catch (_) {}
    for (final s in _peers.values) {
      try {
        s.destroy();
      } catch (_) {}
    }
    _peers.clear();
    try {
      _sock?.destroy();
    } catch (_) {}
    _wifi.invokeMethod('release').catchError((_) => null);
  }
}

// ---------------------------------------------------------------------
//  ALAT GAMBAR
// ---------------------------------------------------------------------
final Map<String, TextPainter> _emojiCache = {};
const double _emojiBase = 96;

void drawEmoji(Canvas c, String e, Offset center, double size, {double angle = 0}) {
  final tp = _emojiCache.putIfAbsent(e, () {
    final p = TextPainter(
      text: TextSpan(text: e, style: const TextStyle(fontSize: _emojiBase)),
      textDirection: TextDirection.ltr,
    );
    p.layout();
    return p;
  });
  c.save();
  c.translate(center.dx, center.dy);
  if (angle != 0) c.rotate(angle);
  final k = size / _emojiBase;
  c.scale(k, k);
  tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
  c.restore();
}

void drawLabel(Canvas c, String text, Offset center, double size, Color color, {bool bold = true}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
        shadows: const [Shadow(color: Color(0x88000000), blurRadius: 3, offset: Offset(1, 1))],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

/// Kapal bajak laut kartun. (0,0) = tengah lambung.
void drawShip(Canvas c, double x, double y, Color col, bool left, double t, int seed,
    {double scale = 1, int pirate = -1}) {
  c.save();
  c.translate(x, y + sin(t * 2.5 + seed) * 4 * scale);
  c.scale(scale, scale);
  // riak air
  c.drawOval(Rect.fromCenter(center: const Offset(0, 26), width: 130, height: 24),
      Paint()..color = const Color(0x55FFFFFF));
  c.rotate(sin(t * 2 + seed) * 0.05);
  if (left) c.scale(-1, 1);

  // lambung
  final hull = Path()
    ..moveTo(-58, -2)
    ..lineTo(60, -6)
    ..quadraticBezierTo(52, 18, 38, 26)
    ..lineTo(-42, 26)
    ..quadraticBezierTo(-54, 14, -58, -2)
    ..close();
  c.drawPath(hull, Paint()..color = const Color(0xFF8B5A2B));
  c.drawPath(
      hull,
      Paint()
        ..color = const Color(0xFF4E2C10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  c.drawRect(const Rect.fromLTWH(-52, 6, 104, 5), Paint()..color = const Color(0xFF5D3A1A));
  final gold = Paint()..color = const Color(0xFFFFD54F);
  for (final px in [-30.0, -6.0, 18.0]) {
    c.drawCircle(Offset(px, 17), 4, gold);
  }
  // tiang
  c.drawRect(const Rect.fromLTWH(-3, -84, 6, 82), Paint()..color = const Color(0xFF5D3A1A));
  // layar belakang
  final sail2 = Path()
    ..moveTo(-5, -70)
    ..quadraticBezierTo(-40, -42, -5, -14)
    ..close();
  c.drawPath(sail2, Paint()..color = Color.lerp(col, Colors.white, 0.45)!);
  // layar utama
  final sail = Path()
    ..moveTo(5, -78)
    ..quadraticBezierTo(56, -46, 5, -10)
    ..close();
  c.drawPath(sail, Paint()..color = col);
  c.drawPath(
      sail,
      Paint()
        ..color = withA(Colors.black, 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
  // tengkorak lucu di layar
  c.drawCircle(const Offset(20, -46), 8, Paint()..color = Colors.white);
  c.drawCircle(const Offset(17, -47), 2, Paint()..color = Colors.black);
  c.drawCircle(const Offset(23, -47), 2, Paint()..color = Colors.black);
  c.drawRect(const Rect.fromLTWH(16, -40, 8, 3), Paint()..color = Colors.white);
  // bendera hitam berkibar
  final wave = sin(t * 6 + seed) * 3;
  final flag = Path()
    ..moveTo(3, -84)
    ..quadraticBezierTo(14, -88 + wave, 28, -80)
    ..lineTo(3, -72)
    ..close();
  c.drawPath(flag, Paint()..color = const Color(0xFF212121));
  if (pirate >= 0) drawPirate(c, -32, -2, col, t, pirate, seed, scale: 1.2);
  c.restore();
}

/// Bajak laut kecil. (x,y) = posisi kaki.
/// mood: 0 santai, 1 bersorak, 2 minta tolong, 3 mendorong, 4 menggali
void drawPirate(Canvas c, double x, double y, Color col, double t, int mood, int seed, {double scale = 1}) {
  c.save();
  c.translate(x, y);
  c.scale(scale, scale);
  if (mood == 1) c.translate(0, -(sin(t * 10 + seed).abs()) * 8);
  final skin = Paint()..color = const Color(0xFFFFCC99);
  final outline = Paint()
    ..color = const Color(0xFF4E2C10)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final arm = Paint()
    ..color = const Color(0xFFFFCC99)
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;
  final leg = Paint()
    ..color = const Color(0xFF3E2723)
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;
  final a = sin(t * (mood == 1 || mood == 2 ? 12 : 9) + seed);
  final pushX = mood == 3 ? 4.0 : 0.0;
  // kaki
  if (mood == 5) {
    c.drawLine(const Offset(-4, -12), Offset(-5 + a * 6, 0), leg);
    c.drawLine(const Offset(4, -12), Offset(5 - a * 6, 0), leg);
  } else {
    c.drawLine(Offset(-4 + pushX, -12), Offset(-6 - pushX, 0), leg);
    c.drawLine(Offset(4 + pushX, -12), Offset(5 + pushX, 0), leg);
  }
  // tangan
  final List<Offset> hands = switch (mood) {
    1 => [Offset(-15, -44 + a * 3), Offset(15, -44 - a * 3)],
    2 => [Offset(-16 + a * 3, -46), Offset(16 - a * 3, -46)],
    3 => [Offset(20, -26 + a), Offset(20, -20 - a)],
    4 => [Offset(14, -30 + a * 9), Offset(18, -28 + a * 9)],
    5 => [Offset(-12 - a * 4, -15), Offset(12 + a * 4, -15)],
    _ => [Offset(-12, -14), Offset(12, -14 + a * 2)],
  };
  // badan miring saat mendorong
  if (mood == 3) {
    c.save();
    c.rotate(0.18);
  }
  c.drawLine(Offset(-7, -26), hands[0], arm);
  c.drawLine(Offset(7, -26), hands[1], arm);
  if (mood == 4) {
    drawTool(c, 'cangkul', hands[1].translate(4, -2), 42, angle: -1.9 + a * 0.5);
  } else if (mood == 3) {
    drawTool(c, 'linggis', hands[0].translate(10, 2), 44, angle: 0.25);
  }
  final body = RRect.fromRectAndRadius(const Rect.fromLTWH(-9, -30, 18, 20), const Radius.circular(6));
  c.drawRRect(body, Paint()..color = Colors.white);
  c.save();
  c.clipRRect(body);
  for (double yy = -27; yy < -10; yy += 6) {
    c.drawRect(Rect.fromLTWH(-9, yy, 18, 3), Paint()..color = col);
  }
  c.restore();
  c.drawRRect(body, outline);
  // kepala
  c.drawCircle(const Offset(0, -41), 11, skin);
  c.drawCircle(const Offset(0, -41), 11, outline);
  final black = Paint()..color = const Color(0xFF212121);
  if (mood == 2) {
    c.drawCircle(const Offset(-4, -42), 2.6, black);
    c.drawCircle(const Offset(4, -42), 2.6, black);
    c.drawCircle(const Offset(0, -35.5), 2.6, black);
  } else {
    c.drawCircle(const Offset(-4, -42), 1.9, black);
    c.drawCircle(const Offset(4, -42), 1.9, black);
    c.drawArc(
        Rect.fromCenter(center: const Offset(0, -38), width: mood == 1 ? 11 : 9, height: mood == 1 ? 8 : 6),
        0.2,
        pi - 0.4,
        false,
        Paint()
          ..color = const Color(0xFF6D2C10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
  }
  c.drawCircle(const Offset(-7, -38), 2.2, Paint()..color = const Color(0x66FF6F6F));
  c.drawCircle(const Offset(7, -38), 2.2, Paint()..color = const Color(0x66FF6F6F));
  // topi bajak laut
  final hat = Path()
    ..moveTo(-16, -46)
    ..quadraticBezierTo(0, -68, 16, -46)
    ..quadraticBezierTo(0, -51, -16, -46)
    ..close();
  c.drawPath(hat, black);
  c.drawRect(const Rect.fromLTWH(-11, -50, 22, 3), Paint()..color = col);
  c.drawCircle(const Offset(0, -56), 2.6, Paint()..color = Colors.white);
  if (mood == 3) c.restore();
  c.restore();
}

/// Batu besar penghalang pulau.
void drawRock(Canvas c, Offset p, double hp, double t, bool shaking) {
  final o = p.translate(shaking ? sin(t * 45) * 3 : 0, 0);
  c.drawOval(Rect.fromCenter(center: o.translate(0, 46), width: 160, height: 30), Paint()..color = const Color(0x33000000));
  const blobs = [
    [-30.0, 10.0, 44.0],
    [28.0, 14.0, 40.0],
    [0.0, -18.0, 48.0],
  ];
  final dark = Paint()..color = const Color(0xFF5F5F5F);
  final base = Paint()..color = const Color(0xFF9E9E9E);
  for (final b in blobs) {
    c.drawCircle(o.translate(b[0], b[1]), b[2] + 4, dark);
  }
  for (final b in blobs) {
    c.drawCircle(o.translate(b[0], b[1]), b[2], base);
  }
  c.drawCircle(o.translate(-14, -34), 14, Paint()..color = const Color(0xFFCFCFCF));
  c.drawCircle(o.translate(-40, 0), 7, Paint()..color = const Color(0xFFBDBDBD));
  final crack = Paint()
    ..color = const Color(0xFF424242)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  if (hp < 0.8) {
    c.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - 60)
          ..lineTo(o.dx - 8, o.dy - 34)
          ..lineTo(o.dx + 6, o.dy - 16)
          ..lineTo(o.dx - 4, o.dy + 6),
        crack);
  }
  if (hp < 0.55) {
    c.drawPath(
        Path()
          ..moveTo(o.dx + 6, o.dy - 16)
          ..lineTo(o.dx + 30, o.dy - 6)
          ..lineTo(o.dx + 44, o.dy + 14),
        crack);
  }
  if (hp < 0.3) {
    c.drawPath(
        Path()
          ..moveTo(o.dx - 4, o.dy + 6)
          ..lineTo(o.dx - 30, o.dy + 18)
          ..lineTo(o.dx - 46, o.dy + 8),
        crack);
  }
  // bar kekuatan batu
  final bar = Rect.fromLTWH(o.dx - 60, o.dy - 96, 120, 14);
  c.drawRRect(RRect.fromRectAndRadius(bar.inflate(3), const Radius.circular(9)), Paint()..color = const Color(0xCC3E2410));
  c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(bar.left, bar.top, bar.width * hp.clamp(0.0, 1.0), bar.height), const Radius.circular(7)),
      Paint()..color = const Color(0xFFFF7043));
}

void drawCoin(Canvas c, Offset p, double r) {
  c.drawCircle(p, r, Paint()..color = const Color(0xFFFFC107));
  c.drawCircle(
      p,
      r,
      Paint()
        ..color = const Color(0xFFE65100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.18);
  c.drawCircle(p.translate(-r * 0.3, -r * 0.3), r * 0.28, Paint()..color = const Color(0xAAFFFFFF));
}

void drawChest(Canvas c, Offset p, double open, double t) {
  if (open > 0) {
    final g = p.translate(0, -22);
    c.drawCircle(
        g,
        80 + sin(t * 4) * 6,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0xDDFFF176), Color(0x00FFF176)])
              .createShader(Rect.fromCircle(center: g, radius: 86)));
  }
  final body = RRect.fromRectAndRadius(Rect.fromLTWH(p.dx - 46, p.dy - 24, 92, 52), const Radius.circular(8));
  c.drawRRect(body, Paint()..color = const Color(0xFF8D5524));
  c.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF4E2C10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  final band = Paint()..color = const Color(0xFFFFC107);
  c.drawRect(Rect.fromLTWH(p.dx - 34, p.dy - 24, 9, 52), band);
  c.drawRect(Rect.fromLTWH(p.dx + 25, p.dy - 24, 9, 52), band);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(p.dx - 8, p.dy - 12, 16, 18), const Radius.circular(3)), band);
  if (open > 0.2) {
    for (int i = 0; i < 5; i++) {
      drawCoin(c, Offset(p.dx - 28 + i * 14, p.dy - 26 - (i.isEven ? 4 : 0)), 9);
    }
  }
  // tutup peti (berengsel di kiri)
  c.save();
  c.translate(p.dx - 46, p.dy - 24);
  c.rotate(-open * 1.15);
  final lid = RRect.fromRectAndCorners(const Rect.fromLTWH(0, -26, 92, 26),
      topLeft: const Radius.circular(18), topRight: const Radius.circular(18));
  c.drawRRect(lid, Paint()..color = const Color(0xFFA0632B));
  c.drawRRect(
      lid,
      Paint()
        ..color = const Color(0xFF4E2C10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  c.drawRect(const Rect.fromLTWH(12, -26, 9, 26), band);
  c.drawRect(const Rect.fromLTWH(71, -26, 9, 26), band);
  c.restore();
}

void drawPyramids(Canvas c, Offset p) {
  final light = Paint()..color = const Color(0xFFE6B95C);
  final dark = Paint()..color = const Color(0xFFC2923A);
  void pyr(double cx, double base, double w, double h) {
    c.drawPath(
        Path()
          ..moveTo(cx - w / 2, base)
          ..lineTo(cx, base - h)
          ..lineTo(cx + w / 2, base)
          ..close(),
        light);
    c.drawPath(
        Path()
          ..moveTo(cx, base - h)
          ..lineTo(cx + w / 2, base)
          ..lineTo(cx + w * 0.08, base)
          ..close(),
        dark);
  }

  pyr(p.dx - 62, p.dy + 22, 90, 70);
  pyr(p.dx + 8, p.dy + 26, 150, 118);
}

void drawSea(Canvas c, Size size, Color a, Color b, double t) {
  final r = Offset.zero & size;
  c.drawRect(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [a, b]).createShader(r));
  final wp = Paint()
    ..color = const Color(0x55FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  const rows = 9;
  for (int row = 0; row < rows; row++) {
    final y = size.height * (row + 0.5) / rows;
    for (int k = 0; k < 7; k++) {
      final x = ((k * size.width / 6) + t * 22 * (row.isEven ? 1 : -1) + row * 57) % (size.width + 80) - 40;
      final yy = y + sin(t * 2 + k + row) * 5;
      final path = Path()
        ..moveTo(x - 18, yy)
        ..quadraticBezierTo(x - 9, yy - 7, x, yy)
        ..quadraticBezierTo(x + 9, yy + 7, x + 18, yy);
      c.drawPath(path, wp);
    }
  }
}

void drawIsland(Canvas c, Country k, double t) {
  final cx = k.island.dx, cy = k.island.dy;
  const blobs = [
    [0.0, 0.0, 0.80],
    [-0.62, 0.18, 0.50],
    [0.60, -0.08, 0.53],
    [0.12, 0.48, 0.45],
    [-0.22, -0.46, 0.42],
  ];
  final shallow = Paint()..color = withA(Color.lerp(k.sea1, Colors.white, 0.45)!, 0.6);
  for (final b in blobs) {
    c.drawCircle(Offset(cx + b[0] * islandR, cy + b[1] * islandR), b[2] * islandR + 30 + sin(t * 1.5) * 3, shallow);
  }
  final edge = Paint()..color = Color.lerp(k.sand, Colors.brown, 0.25)!;
  for (final b in blobs) {
    c.drawCircle(Offset(cx + b[0] * islandR, cy + b[1] * islandR), b[2] * islandR + 5, edge);
  }
  final sand = Paint()..color = k.sand;
  for (final b in blobs) {
    c.drawCircle(Offset(cx + b[0] * islandR, cy + b[1] * islandR), b[2] * islandR, sand);
  }
  final g = k.grass;
  if (g != null) {
    final gp = Paint()..color = g;
    for (final b in blobs) {
      c.drawCircle(Offset(cx + b[0] * islandR * 0.85, cy + b[1] * islandR * 0.85 - 10), b[2] * islandR * 0.68, gp);
    }
  } else {
    // bukit pasir gurun
    final dune = Paint()
      ..color = Color.lerp(k.sand, Colors.deepOrange, 0.22)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final o in const [Offset(-70, 40), Offset(-20, -70), Offset(70, 10)]) {
      c.drawArc(Rect.fromCenter(center: Offset(cx + o.dx, cy + o.dy), width: 60, height: 26), pi, pi, false, dune);
    }
  }
  // hiasan
  final decoPos = [
    Offset(cx - islandR * 0.66, cy + islandR * 0.08),
    Offset(cx + islandR * 0.88, cy + islandR * 0.10),
    Offset(cx - islandR * 0.18, cy + islandR * 0.55),
  ];
  for (int i = 0; i < k.deco.length && i < decoPos.length; i++) {
    drawEmoji(c, k.deco[i], decoPos[i], 54, angle: sin(t * 1.3 + i) * 0.06);
  }
  // ikon negara
  if (k.landmark == 'PIRAMIDA') {
    drawPyramids(c, Offset(cx, cy - 40));
  } else {
    drawEmoji(c, k.landmark, Offset(cx, cy - 42), 120);
  }
  // tiang bendera
  final pole = Offset(cx + islandR * 0.6, cy - islandR * 0.2);
  c.drawLine(pole, pole.translate(0, -80),
      Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 4);
  drawEmoji(c, k.flag, pole.translate(22, -66), 40, angle: sin(t * 3) * 0.08);
}

// ---------------------------------------------------------------------
//  PARTIKEL EFEK
// ---------------------------------------------------------------------
class Particle {
  double x, y, vx, vy, life, max, grav, size;
  Color color;
  int kind; // 0 titik, 1 koin, 2 emoji
  String emoji;
  Particle(this.x, this.y, this.vx, this.vy, this.life, this.color, this.size,
      {this.grav = 0, this.kind = 0, this.emoji = ''})
      : max = life;
}

// ---------------------------------------------------------------------
//  PELUKIS LAYAR GAME
// ---------------------------------------------------------------------
void drawParticles(Canvas c, List<Particle> fx) {
  for (final p in fx) {
    final f = (p.life / p.max).clamp(0.0, 1.0);
    switch (p.kind) {
      case 1:
        drawCoin(c, Offset(p.x, p.y), p.size);
        break;
      case 2:
        drawEmoji(c, p.emoji, Offset(p.x, p.y), p.size * (0.5 + 0.5 * f));
        break;
      case 3:
        drawTool(c, p.emoji, Offset(p.x, p.y), p.size, angle: -0.6 + (1 - f) * 0.8);
        break;
      default:
        c.drawCircle(Offset(p.x, p.y), p.size * (0.4 + 0.6 * f), Paint()..color = withA(p.color, f));
    }
  }
}

/// Alat: 'kunci', 'cangkul', 'linggis'. size ~ panjang alat.
void drawTool(Canvas c, String kind, Offset p, double size, {double angle = -0.6}) {
  if (kind == 'kunci') {
    drawEmoji(c, '🗝️', p, size, angle: angle + 0.6);
    return;
  }
  c.save();
  c.translate(p.dx, p.dy);
  c.rotate(angle);
  final k = size / 110;
  c.scale(k, k);
  final outline = Paint()
    ..color = const Color(0xFF3E2410)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeJoin = StrokeJoin.round;
  if (kind == 'cangkul') {
    final handle = RRect.fromRectAndRadius(const Rect.fromLTWH(-40, -6, 92, 12), const Radius.circular(6));
    c.drawRRect(handle, Paint()..color = const Color(0xFFBC8F5F));
    c.drawRRect(handle, outline);
    final blade = Path()
      ..moveTo(-54, -10)
      ..lineTo(-34, -10)
      ..lineTo(-30, 46)
      ..lineTo(-60, 46)
      ..close();
    c.drawPath(blade, Paint()..color = const Color(0xFF90A4AE));
    c.drawPath(blade, outline);
    c.drawLine(const Offset(-57, 39), const Offset(-33, 39),
        Paint()
          ..color = const Color(0xFFECEFF1)
          ..strokeWidth = 3);
  } else {
    final bar = RRect.fromRectAndRadius(const Rect.fromLTWH(-46, -6, 86, 12), const Radius.circular(5));
    c.drawRRect(bar, Paint()..color = const Color(0xFFD32F2F));
    c.drawRRect(bar, outline);
    final hook = Path()
      ..moveTo(36, 0)
      ..quadraticBezierTo(64, -2, 58, 26)
      ..quadraticBezierTo(55, 35, 46, 32);
    c.drawPath(
        hook,
        Paint()
          ..color = const Color(0xFF3E2410)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 17
          ..strokeCap = StrokeCap.round);
    c.drawPath(
        hook,
        Paint()
          ..color = const Color(0xFF546E7A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round);
    final tip = Path()
      ..moveTo(-46, -6)
      ..lineTo(-62, -1)
      ..lineTo(-46, 6)
      ..close();
    c.drawPath(tip, Paint()..color = const Color(0xFF546E7A));
    c.drawPath(tip, outline);
  }
  c.restore();
}

void drawBush(Canvas c, Offset p, bool searched, bool rustle, double t, int mission, int seed) {
  final o = p.translate(rustle ? sin(t * 30) * 4 : 0, 0);
  final base = mission == countries.length - 1
      ? const Color(0xFF7CB342)
      : (countries[mission].grass == null ? const Color(0xFF9E9D24) : const Color(0xFF2E7D32));
  final dark = Color.lerp(base, Colors.black, 0.35)!;
  final light = Color.lerp(base, Colors.white, 0.25)!;
  final k = searched ? 0.7 : 1.0;
  c.drawOval(Rect.fromCenter(center: o.translate(0, 26 * k), width: 110 * k, height: 22 * k), Paint()..color = const Color(0x33000000));
  final blobs = [
    Offset(-28 * k, 4 * k),
    Offset(28 * k, 6 * k),
    Offset(0, -14 * k),
  ];
  for (final b in blobs) {
    c.drawCircle(o + b, 34 * k, Paint()..color = dark);
  }
  for (final b in blobs) {
    c.drawCircle(o + b.translate(0, -2), 30 * k, Paint()..color = searched ? Color.lerp(base, Colors.white, 0.15)! : base);
  }
  for (final b in blobs) {
    c.drawCircle(o + b.translate(-8 * k, -12 * k), 8 * k, Paint()..color = light);
  }
  if (mission == countries.length - 1) {
    c.drawCircle(o.translate(0, -36 * k), 14 * k, Paint()..color = Colors.white);
  }
  if (!searched) {
    final blink = sin(t * 2.5 + seed * 1.9);
    if (blink > 0.4) drawEmoji(c, '✨', o.translate(30, -40), 26 * blink);
  }
}

class GamePainter extends CustomPainter {
  final GameState gs;
  final double t;
  final Map<int, Offset> shipPos;
  final List<Offset> mobPos;
  final List<Particle> fx;
  final Offset? target;
  final double targetAge;
  final int myId;

  final Map<int, Offset> walkerPos;

  GamePainter(this.gs, this.t, this.shipPos, this.mobPos, this.fx, this.target, this.targetAge, this.myId,
      this.walkerPos);

  static (double, Offset) fit(Size size) {
    final s = min(size.width / worldW, size.height / worldH);
    return (s, Offset((size.width - worldW * s) / 2, (size.height - worldH * s) / 2));
  }

  @override
  void paint(Canvas c, Size size) {
    if (gs.onLand) {
      _paintLand(c, size);
      return;
    }
    final k = gs.c;
    drawSea(c, size, k.sea1, k.sea2, t);
    final (s, off) = fit(size);
    c.save();
    c.translate(off.dx, off.dy);
    c.scale(s, s);

    drawIsland(c, k, t);

    const bool onLand = false;
    // dermaga pulau
    {
      final dk = gs.dock;
      final plank = Paint()..color = const Color(0xFFA1887F);
      final dark = Paint()..color = const Color(0xFF5D4037);
      final pier = Rect.fromLTWH(dk.dx - 30, dk.dy - 22, (k.island.dx - islandR * 0.7) - (dk.dx - 30), 44);
      c.drawRect(pier.translate(0, 6), dark);
      c.drawRect(pier, plank);
      for (double x = pier.left + 16; x < pier.right; x += 22) {
        c.drawLine(Offset(x, pier.top), Offset(x, pier.bottom), Paint()
          ..color = const Color(0xFF6D4C41)
          ..strokeWidth = 2);
      }
      c.drawCircle(Offset(pier.left + 6, pier.bottom + 4), 7, dark);
      c.drawCircle(Offset(pier.left + 6, pier.top), 7, dark);
      drawEmoji(c, '⚓', dk.translate(-6, 0), 34);
      if (gs.phase == 'island') {
        drawEmoji(c, '👇', dk.translate(0, -78 + sin(t * 6) * 8), 52);
      }
    }

    // barang misi
    if (gs.phase == 'sail' || gs.phase == 'map') {
      for (int i = 0; i < gs.items.length; i++) {
        final it = gs.items[i];
        if (it.got) continue;
        final p = Offset(it.x, it.y + sin(t * 3 + i) * 6);
        c.drawCircle(
            p,
            42,
            Paint()
              ..shader = const RadialGradient(colors: [Color(0xBBFFF59D), Color(0x00FFF59D)])
                  .createShader(Rect.fromCircle(center: p, radius: 42)));
        drawEmoji(c, k.item, p, 52, angle: sin(t * 2 + i) * 0.12);
      }
    }

    // titik tujuan kapal sendiri
    final tg = target;
    if (tg != null && targetAge < 1.2) {
      final f = targetAge / 1.2;
      c.drawCircle(
          tg,
          18 + f * 30,
          Paint()
            ..color = withA(shipColor(myId), 1 - f)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5);
    }

    // kapal + bajak lautnya (urut dari atas ke bawah)
    final ids = shipPos.keys.toList()..sort((a, b) => shipPos[a]!.dy.compareTo(shipPos[b]!.dy));
    for (final id in ids) {
      final p = shipPos[id]!;
      final sh = gs.ships[id];
      final stuck = sh?.stuck ?? false;
      int mood = 0;
      if (onLand) {
        mood = -1; // sedang di pulau
      } else if (stuck) {
        mood = 2;
      } else if ((sh?.cheer ?? 0) > 0) {
        mood = 1;
      } else if (gs.phase == 'island' && (p - gs.dock).distance < 130) {
        mood = 3;
      }
      drawShip(c, p.dx, p.dy, shipColor(id), sh?.left ?? false, t, id, pirate: mood);

      if (stuck && sh != null) {
        // lingkaran progres ditolong
        c.drawCircle(p.translate(0, -20), 78,
            Paint()
              ..color = const Color(0x66FFFFFF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 8);
        c.drawArc(
            Rect.fromCircle(center: p.translate(0, -20), radius: 78),
            -pi / 2,
            pi * 2 * sh.help.clamp(0.0, 1.0),
            false,
            Paint()
              ..color = const Color(0xFF69F0AE)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 8
              ..strokeCap = StrokeCap.round);
        drawEmoji(c, '🆘', p.translate(-32, -128 + sin(t * 8) * 6), 40);
      } else if (mood == 3) {
        drawEmoji(c, '💪', p.translate((sh?.left ?? false) ? 40.0 : -40.0, -110 + sin(t * 9) * 4), 34);
      } else if (mood == 1) {
        drawEmoji(c, '🎉', p.translate(-34, -116 + sin(t * 6) * 4), 32);
      }

      if (id == myId && shipPos.length > 1 && !stuck) {
        final ay = p.dy - 128 + sin(t * 6) * 6;
        final tri = Path()
          ..moveTo(p.dx - 14, ay - 12)
          ..lineTo(p.dx + 14, ay - 12)
          ..lineTo(p.dx, ay + 6)
          ..close();
        c.drawPath(
            tri,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..strokeJoin = StrokeJoin.round);
        c.drawPath(tri, Paint()..color = shipColor(id));
      }
    }

    // hewan laut (di depan kapal supaya gurita terlihat memeluk kapal)
    for (int i = 0; i < mobPos.length; i++) {
      final p = mobPos[i];
      final grabbing = i < gs.mobs.length && gs.mobs[i].grab >= 0;
      final b = sin(t * 3 + i * 2) * 5;
      if (grabbing) {
        final victim = shipPos[gs.mobs[i].grab];
        if (victim != null) {
          final tent = Paint()
            ..color = const Color(0xFFF06292)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 11
            ..strokeCap = StrokeCap.round;
          for (int j = 0; j < 3; j++) {
            final end = victim.translate(-30.0 + j * 26, 8 + sin(t * 6 + j) * 5);
            c.drawPath(
                Path()
                  ..moveTo(p.dx, p.dy + 10)
                  ..quadraticBezierTo(p.dx - 20 + j * 10, p.dy + 50, end.dx, end.dy),
                tent);
          }
        }
        drawEmoji(c, k.mobs[i % k.mobs.length], p.translate(0, b), 84, angle: sin(t * 7) * 0.15);
        if (shipPos.length <= 1 || gs.ships[myId]?.stuck == true) {
          drawEmoji(c, '👆', p.translate(26, 58 + sin(t * 8) * 6), 40);
        }
      } else {
        c.drawOval(Rect.fromCenter(center: p.translate(0, 30), width: 70, height: 16), Paint()..color = const Color(0x33000000));
        drawEmoji(c, k.mobs[i % k.mobs.length], p.translate(0, b), 66, angle: sin(t * 2 + i) * 0.1);
      }
    }

    // partikel
    drawParticles(c, fx);
    c.restore();
  }

  // ======================= PULAU BESAR =======================
  void _paintLand(Canvas c, Size size) {
    final k = gs.c;
    final ground = k.grass ?? k.sand;
    c.drawRect(Offset.zero & size, Paint()..color = ground);
    final (s, off) = fit(size);
    c.save();
    c.translate(off.dx, off.dy);
    c.scale(s, s);

    // tanah + tekstur
    final tex = Random(gs.mission * 3 + 1);
    final spot = Paint()..color = Color.lerp(ground, Colors.white, 0.12)!;
    final spot2 = Paint()..color = Color.lerp(ground, Colors.black, 0.07)!;
    for (int i = 0; i < 46; i++) {
      c.drawCircle(Offset(150 + tex.nextDouble() * 1500, tex.nextDouble() * 800), 18 + tex.nextDouble() * 40,
          i.isEven ? spot : spot2);
    }
    // pantai & laut di kiri
    final sandP = Paint()..color = k.sand;
    c.drawRect(const Rect.fromLTWH(-1200, -1000, 1480, 3000), sandP);
    for (double y = -40; y < 860; y += 70) {
      c.drawCircle(Offset(285 + sin(y) * 10, y), 46, sandP);
    }
    final seaR = const Rect.fromLTWH(-1200, -1000, 1330, 3000);
    c.drawRect(seaR, Paint()..shader = LinearGradient(colors: [k.sea2, k.sea1]).createShader(Rect.fromLTWH(-200, 0, 330, 10)));
    final foam = Paint()..color = const Color(0xBBFFFFFF);
    for (double y = -40; y < 860; y += 46) {
      c.drawCircle(Offset(130 + sin(t * 2 + y) * 6, y), 18, foam);
    }
    // kapal-kapal berlabuh
    final sids = gs.ships.keys.toList()..sort();
    for (int i = 0; i < sids.length; i++) {
      drawShip(c, 40, 230.0 + i * 150, shipColor(sids[i]), false, t, sids[i], scale: 0.75);
    }

    // jalan setapak
    final path = Path()..moveTo(250, pathY(250));
    for (double x = 270; x <= landX.dx; x += 20) {
      path.lineTo(x, pathY(x));
    }
    c.drawPath(
        path,
        Paint()
          ..color = Color.lerp(ground, const Color(0xFF6D4C41), 0.45)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 78
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    c.drawPath(
        path,
        Paint()
          ..color = Color.lerp(ground, const Color(0xFFD7B98E), 0.6)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 58
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);

    // ikon negara + bendera
    if (k.landmark == 'PIRAMIDA') {
      drawPyramids(c, const Offset(1330, 220));
    } else {
      drawEmoji(c, k.landmark, const Offset(1330, 190), 150);
    }
    final pole = landX.translate(90, -50);
    c.drawLine(pole, pole.translate(0, -90),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 5);
    drawEmoji(c, k.flag, pole.translate(24, -74), 44, angle: sin(t * 3) * 0.08);

    // pepohonan hutan
    final trees = gs.mission == countries.length - 1
        ? const ['🌲', '⛄', '🌲']
        : (k.grass == null ? const ['🌵', '🌴', '🌵'] : const ['🌳', '🌲', '🌴']);
    final tr = Random(gs.mission * 11 + 5);
    final treePos = <Offset>[];
    for (int a = 0; a < 400 && treePos.length < 30; a++) {
      final p = Offset(300 + tr.nextDouble() * 1260, 110 + tr.nextDouble() * 680);
      if ((p.dy - pathY(p.dx)).abs() < 85) continue;
      if (gs.hasGate && (p.dx - gateX).abs() < 55) continue;
      if (gs.hasBoulder && (p.dx - boulderX).abs() < 60) continue;
      if ((p - landX).distance < 170) continue;
      if ((p - const Offset(1330, 200)).distance < 120) continue;
      if (gs.bushes.any((b) => (Offset(b.x, b.y) - p).distance < 95)) continue;
      if (treePos.any((q) => (q - p).distance < 85)) continue;
      treePos.add(p);
    }
    treePos.sort((a, b) => a.dy.compareTo(b.dy));
    for (int i = 0; i < treePos.length; i++) {
      final p = treePos[i];
      c.drawOval(Rect.fromCenter(center: p.translate(0, 40), width: 70, height: 16), Paint()..color = const Color(0x33000000));
      drawEmoji(c, trees[i % trees.length], p, 84.0 + (i % 3) * 12, angle: sin(t * 1.2 + i) * 0.03);
    }
    if (k.deco.length > 1) drawEmoji(c, k.deco[1], const Offset(1210, 715), 64);

    // gerbang kayu
    if (gs.hasGate) {
      final gy = pathY(gateX);
      final stake = Paint()..color = const Color(0xFF8D5524);
      final stakeD = Paint()..color = const Color(0xFF4E2C10);
      for (double y = 90; y < 820; y += 34) {
        if ((y - gy).abs() < 66) continue;
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gateX - 11, y - 2, 22, 34), const Radius.circular(5)), stakeD);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gateX - 9, y, 18, 30), const Radius.circular(5)), stake);
      }
      if (!gs.gateOpen) {
        final door = Rect.fromLTWH(gateX - 14, gy - 64, 28, 128);
        c.drawRRect(RRect.fromRectAndRadius(door.inflate(3), const Radius.circular(6)), stakeD);
        c.drawRRect(RRect.fromRectAndRadius(door, const Radius.circular(6)), Paint()..color = const Color(0xFFA0632B));
        drawEmoji(c, '🔒', Offset(gateX, gy), 44);
      } else {
        final door = Rect.fromLTWH(gateX, gy - 66, 86, 18);
        c.drawRRect(RRect.fromRectAndRadius(door, const Radius.circular(6)), Paint()..color = const Color(0xFFA0632B));
        c.drawRRect(RRect.fromRectAndRadius(door, const Radius.circular(6)),
            Paint()
              ..color = const Color(0xFF4E2C10)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      }
    }

    // tembok batu + batu besar
    if (gs.hasBoulder) {
      final by = pathY(boulderX);
      final dark = Paint()..color = const Color(0xFF5F5F5F);
      final grey = Paint()..color = const Color(0xFF9E9E9E);
      for (double y = 100; y < 820; y += 52) {
        if (gs.boulderHp > 0 && (y - by).abs() < 80) continue;
        if (gs.boulderHp <= 0 && (y - by).abs() < 80) continue;
        final o = Offset(boulderX + sin(y) * 10, y);
        c.drawCircle(o, 30, dark);
        c.drawCircle(o, 26, grey);
        c.drawCircle(o.translate(-8, -9), 7, Paint()..color = const Color(0xFFCFCFCF));
      }
      if (gs.boulderHp > 0) {
        final shaking = gs.tools.contains('linggis') &&
            walkerPos.values.any((w) => (w - gs.boulderPos).distance < 190);
        drawRock(c, gs.boulderPos, gs.boulderHp, t, shaking);
        if (!gs.tools.contains('linggis')) {
          drawTool(c, 'linggis', gs.boulderPos.translate(0, -140 + sin(t * 3) * 5), 56);
          drawEmoji(c, '❓', gs.boulderPos.translate(38, -150), 36);
        }
      } else {
        for (int i = 0; i < 6; i++) {
          c.drawCircle(gs.boulderPos.translate(-50.0 + i * 20, 30.0 + (i % 2) * 14), 9, grey);
        }
      }
    }

    // semak-semak
    for (int i = 0; i < gs.bushes.length; i++) {
      final b = gs.bushes[i];
      final near = walkerPos.values.any((w) => (w - Offset(b.x, b.y)).distance < 80);
      drawBush(c, Offset(b.x, b.y), b.searched, near && !b.searched, t, gs.mission, i);
      if (b.searched && !isTool(b.c)) {
        drawEmoji(c, b.c, Offset(b.x + 34, b.y - 30 + sin(t * 4 + i) * 4), 36);
      }
    }

    // tanda X / peti
    final xp = landX;
    if (gs.phase == 'land' || gs.phase == 'dig') {
      if (gs.phase == 'dig' && gs.dig > 0) {
        final f = (gs.dig / max(1, gs.digNeed)).clamp(0.0, 1.0);
        c.drawOval(Rect.fromCenter(center: xp.translate(0, 8), width: 40 + 80 * f, height: 20 + 40 * f),
            Paint()..color = const Color(0xFF6D4C2F));
      }
      final pulse = 28 + sin(t * 5) * 4;
      for (final p in [
        Paint()
          ..color = Colors.white
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round,
        Paint()
          ..color = const Color(0xFFD32F2F)
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round,
      ]) {
        c.drawLine(xp.translate(-pulse, -pulse), xp.translate(pulse, pulse), p);
        c.drawLine(xp.translate(pulse, -pulse), xp.translate(-pulse, pulse), p);
      }
    } else if (gs.phase == 'chest') {
      drawChest(c, xp, 0, t);
      drawEmoji(c, '🔒', xp.translate(0, 0), 34);
    } else {
      final open = gs.phase == 'finish' ? 1.0 : ((gs.phaseT - 0.3) / 0.8).clamp(0.0, 1.0);
      drawChest(c, xp, open, t);
    }

    // bajak laut berjalan
    final wids = walkerPos.keys.toList()..sort((a, b) => walkerPos[a]!.dy.compareTo(walkerPos[b]!.dy));
    for (final id in wids) {
      final p = walkerPos[id]!;
      final w = gs.walkers[id];
      int mood = 0;
      if (gs.phase == 'treasure' || gs.phase == 'finish') {
        mood = 1;
      } else if (gs.phase == 'dig' && (p - xp).distance < 170) {
        mood = 4;
      } else if (w?.moving ?? false) {
        mood = 5;
      } else if (gs.hasBoulder &&
          gs.boulderHp > 0 &&
          gs.tools.contains('linggis') &&
          (p - gs.boulderPos).distance < 190) {
        mood = 3;
      }
      bool faceLeft = w?.left ?? false;
      if (mood == 4) faceLeft = p.dx > xp.dx;
      if (mood == 3) faceLeft = false;
      c.drawOval(Rect.fromCenter(center: p.translate(0, 2), width: 50, height: 14), Paint()..color = const Color(0x44000000));
      c.save();
      c.translate(p.dx, p.dy);
      if (faceLeft) c.scale(-1, 1);
      drawPirate(c, 0, 0, shipColor(id), t, mood, id, scale: 1.7);
      c.restore();
      if (mood == 3) drawEmoji(c, '💪', p.translate(-36, -120 + sin(t * 9) * 4), 32);
      if (id == myId && walkerPos.length > 1) {
        final ay = p.dy - 140 + sin(t * 6) * 6;
        final tri = Path()
          ..moveTo(p.dx - 13, ay - 11)
          ..lineTo(p.dx + 13, ay - 11)
          ..lineTo(p.dx, ay + 6)
          ..close();
        c.drawPath(
            tri,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..strokeJoin = StrokeJoin.round);
        c.drawPath(tri, Paint()..color = shipColor(id));
      }
    }

    // titik tujuan
    final tg = target;
    if (tg != null && targetAge < 1.2 && gs.phase == 'land') {
      final f = targetAge / 1.2;
      c.drawCircle(
          tg,
          16 + f * 26,
          Paint()
            ..color = withA(shipColor(myId), 1 - f)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5);
    }

    drawParticles(c, fx);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------
//  PETA DUNIA (dipakai di pilih misi & perpindahan negara)
// ---------------------------------------------------------------------
const List<List<double>> _land = [
  // Amerika Utara
  [0.18, 0.28, 0.12, 0.13], [0.24, 0.38, 0.07, 0.08], [0.12, 0.19, 0.07, 0.07], [0.27, 0.22, 0.06, 0.07],
  // Amerika Selatan
  [0.33, 0.60, 0.055, 0.12], [0.31, 0.51, 0.05, 0.05], [0.315, 0.72, 0.03, 0.07],
  // Eropa
  [0.50, 0.26, 0.05, 0.05], [0.535, 0.30, 0.03, 0.03],
  // Afrika
  [0.53, 0.52, 0.07, 0.12], [0.515, 0.42, 0.065, 0.06], [0.56, 0.64, 0.04, 0.06],
  // Asia
  [0.70, 0.28, 0.15, 0.10], [0.77, 0.38, 0.06, 0.06], [0.68, 0.40, 0.04, 0.05], [0.625, 0.44, 0.03, 0.04],
  [0.755, 0.48, 0.015, 0.04],
  // Indonesia
  [0.785, 0.575, 0.03, 0.013], [0.825, 0.585, 0.028, 0.014], [0.80, 0.555, 0.02, 0.018], [0.86, 0.58, 0.02, 0.018],
  // Jepang
  [0.885, 0.32, 0.012, 0.045],
  // Australia
  [0.85, 0.71, 0.065, 0.06],
];

class WorldMapPainter extends CustomPainter {
  final int unlocked; // dipakai mode pilih
  final int current; // dipakai mode perjalanan
  final double progress;
  final double t;
  final bool select;
  WorldMapPainter({this.unlocked = 0, this.current = 0, this.progress = 1, required this.t, this.select = false});

  static Rect inner(Size size) => (Offset.zero & size).deflate(28);
  static Offset pos(Size size, int i) {
    final m = inner(size);
    final p = countries[i].mapPos;
    return Offset(m.left + p.dx * m.width, m.top + p.dy * m.height);
  }

  void _dashed(Canvas c, Offset a, Offset b, Paint p) {
    final d = (b - a).distance;
    if (d < 1) return;
    final dir = (b - a) / d;
    double s = 0;
    while (s < d) {
      final e = min(s + 14, d);
      c.drawLine(a + dir * s, a + dir * e, p);
      s += 24;
    }
  }

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    c.drawRect(
        r,
        Paint()
          ..shader = const RadialGradient(radius: 0.9, colors: [Color(0xFFF8E9C4), Color(0xFFD4AF72)]).createShader(r));
    final m = inner(size);
    Offset p(double x, double y) => Offset(m.left + x * m.width, m.top + y * m.height);

    // garis ombak di laut peta
    final wave = Paint()
      ..color = const Color(0x339C7A45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < 14; i++) {
      final wx = ((i * 0.37) % 1.0), wy = ((i * 0.61) % 1.0);
      final o = p(wx, wy);
      c.drawPath(
          Path()
            ..moveTo(o.dx - 14, o.dy)
            ..quadraticBezierTo(o.dx - 7, o.dy - 6, o.dx, o.dy)
            ..quadraticBezierTo(o.dx + 7, o.dy + 6, o.dx + 14, o.dy),
          wave);
    }

    // benua
    final land = Path();
    for (final o in _land) {
      land.addOval(Rect.fromCenter(center: p(o[0], o[1]), width: o[2] * 2 * m.width, height: o[3] * 2 * m.height));
    }
    c.drawPath(
        land,
        Paint()
          ..color = const Color(0xFF7A5A2E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
    c.drawPath(land, Paint()..color = const Color(0xFFA9C97F));
    // Antartika
    final ant = Rect.fromCenter(center: p(0.5, 1.0), width: m.width * 0.8, height: m.height * 0.1);
    c.drawOval(ant, Paint()..color = const Color(0xFFF4FAFF));
    c.drawOval(
        ant,
        Paint()
          ..color = const Color(0xFF90A4AE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    // hiasan
    drawEmoji(c, '🧭', p(0.07, 0.82), 64, angle: sin(t) * 0.1);
    drawEmoji(c, '🐙', p(0.43, 0.76), 44, angle: sin(t * 2) * 0.15);
    drawEmoji(c, '🐳', p(0.06, 0.50), 48);
    drawEmoji(c, '⛵', p(0.42, 0.20), 40);

    // bingkai
    c.drawRRect(
        RRect.fromRectAndRadius(r.deflate(7), const Radius.circular(20)),
        Paint()
          ..color = const Color(0xFF8D6E3F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9);

    // rute
    final done = Paint()
      ..color = const Color(0xFFC62828)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final todo = Paint()
      ..color = const Color(0x888D6E3F)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final reached = select ? unlocked : current;
    for (int i = 0; i < countries.length - 1; i++) {
      final a = pos(size, i), b = pos(size, i + 1);
      if (i + 1 <= reached && (select || i + 1 < current)) {
        c.drawLine(a, b, done);
      } else if (!select && i + 1 == current) {
        final e = Offset.lerp(a, b, Curves.easeInOut.transform(progress.clamp(0.0, 1.0)))!;
        c.drawLine(a, e, done);
        _dashed(c, e, b, todo);
      } else {
        _dashed(c, a, b, todo);
      }
    }

    // penanda negara
    for (int i = 0; i < countries.length; i++) {
      final o = pos(size, i);
      final locked = i > reached;
      final isNow = i == reached;
      final rad = isNow ? 25 + sin(t * 4) * 3 : 22.0;
      c.drawCircle(o.translate(2, 3), rad, Paint()..color = const Color(0x44000000));
      c.drawCircle(o, rad, Paint()..color = locked ? const Color(0xFFBDBDBD) : Colors.white);
      c.drawCircle(
          o,
          rad,
          Paint()
            ..color = isNow ? const Color(0xFFFFB300) : const Color(0xFF6D4C2F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isNow ? 5 : 3);
      if (locked) {
        drawEmoji(c, '🔒', o, 22);
      } else {
        drawEmoji(c, countries[i].flag, o, 28);
      }
      if (i < reached) drawEmoji(c, '⭐', o.translate(18, -18), 20);
      drawLabel(c, '${i + 1}', o.translate(0, 36), 16, const Color(0xFF4E2C10));
    }

    // kapal berlayar di peta
    if (!select) {
      final to = pos(size, current);
      final from = current == 0
          ? Offset(m.left + 0.70 * m.width, m.top + 0.80 * m.height)
          : pos(size, current - 1);
      final e = Offset.lerp(from, to, Curves.easeInOut.transform(progress.clamp(0.0, 1.0)))!;
      drawShip(c, e.dx, e.dy - 26, shipColors[0], to.dx < from.dx, t, 0, scale: 0.45);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------
//  WIDGET BANTU
// ---------------------------------------------------------------------
class OutlinedTitle extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  const OutlinedTitle(this.text, {super.key, this.size = 40, this.color = const Color(0xFFFFD54F)});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w900,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size / 6
                ..color = const Color(0xFF3E2410))),
      Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: color)),
    ]);
  }
}

class KidButton extends StatefulWidget {
  final String emoji, label;
  final Color color;
  final VoidCallback onTap;
  final double width;
  const KidButton({super.key, required this.emoji, required this.label, required this.color, required this.onTap, this.width = 170});

  @override
  State<KidButton> createState() => _KidButtonState();
}

class _KidButtonState extends State<KidButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(widget.color, Colors.white, 0.25)!, widget.color]),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 6))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text(widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Color(0x88000000), blurRadius: 3, offset: Offset(1, 1))])),
          ]),
        ),
      ),
    );
  }
}

class Chip2 extends StatelessWidget {
  final Widget child;
  final Color color;
  const Chip2({super.key, required this.child, this.color = const Color(0xCC3E2410)});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD54F), width: 2),
        ),
        child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900), child: child),
      );
}

class ToolIcon extends StatelessWidget {
  final String kind;
  final double size;
  const ToolIcon(this.kind, {super.key, this.size = 44});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _ToolIconPainter(kind)),
      );
}

class _ToolIconPainter extends CustomPainter {
  final String kind;
  _ToolIconPainter(this.kind);
  @override
  void paint(Canvas c, Size s) {
    drawTool(c, kind, Offset(s.width / 2, s.height / 2), s.width * 0.92, angle: kind == 'kunci' ? 0 : -0.75);
  }

  @override
  bool shouldRepaint(covariant _ToolIconPainter oldDelegate) => oldDelegate.kind != kind;
}

class ShipIcon extends StatelessWidget {
  final int id;
  final double size;
  const ShipIcon(this.id, {super.key, this.size = 90});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _ShipIconPainter(id)),
      );
}

class _ShipIconPainter extends CustomPainter {
  final int id;
  _ShipIconPainter(this.id);
  @override
  void paint(Canvas c, Size s) {
    drawShip(c, s.width / 2, s.height * 0.68, shipColor(id), false, 0, id, scale: s.width / 150);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mixin kecil untuk animasi terus-menerus di layar menu.
mixin LoopTime<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  late final Ticker _loop;
  double time = 0;
  void startLoop() {
    _loop = createTicker((d) => setState(() => time = d.inMicroseconds / 1e6))..start();
  }

  void stopLoop() => _loop.dispose();
}

// ---------------------------------------------------------------------
//  APLIKASI
// ---------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  Voice.init();
  runApp(const HartaApp());
}

class HartaApp extends StatelessWidget {
  const HartaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Harta Karun Dunia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFF0277BD), useMaterial3: true),
        home: const MenuScreen(),
      );
}

// ---------------------------------------------------------------------
//  MENU UTAMA
// ---------------------------------------------------------------------
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin, LoopTime {
  int unlocked = 0, coins = 0;
  bool tamat = false;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    startLoop();
    _load();
    _refresh = Timer.periodic(const Duration(seconds: 2), (_) => _load());
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        unlocked = p.getInt('unlocked') ?? 0;
        coins = p.getInt('coins') ?? 0;
        tamat = p.getBool('tamat') ?? false;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _refresh?.cancel();
    stopLoop();
    super.dispose();
  }

  Future<void> _go(Widget w) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final starsDone = tamat ? 10 : unlocked;
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _MenuPainter(time))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(children: [
                Chip2(child: Text('⭐ $starsDone / 10')),
                const Spacer(),
                Chip2(child: Text('💰 $coins')),
              ]),
              const Spacer(),
              const OutlinedTitle('🏴‍☠️ Harta Karun Dunia', size: 44),
              const SizedBox(height: 4),
              const OutlinedTitle('Petualangan Bajak Laut Cilik', size: 20, color: Colors.white),
              const Spacer(),
              Wrap(spacing: 18, runSpacing: 12, alignment: WrapAlignment.center, children: [
                KidButton(
                    emoji: '⛵',
                    label: 'Main Sendiri',
                    color: const Color(0xFF43A047),
                    onTap: () => _go(const MissionSelectScreen(host: false))),
                KidButton(
                    emoji: '👑',
                    label: 'Jadi Kapten\n(Mabar)',
                    color: const Color(0xFFE53935),
                    onTap: () => _go(const MissionSelectScreen(host: true))),
                KidButton(
                    emoji: '🤝',
                    label: 'Ikut Main\n(Mabar)',
                    color: const Color(0xFF1E88E5),
                    onTap: () => _go(const JoinScreen())),
              ]),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _MenuPainter extends CustomPainter {
  final double t;
  _MenuPainter(this.t);
  @override
  void paint(Canvas c, Size size) {
    drawSea(c, size, const Color(0xFF4FC3F7), const Color(0xFF01579B), t);
    // matahari
    c.drawCircle(Offset(size.width * 0.86, size.height * 0.2), 46, Paint()..color = const Color(0xFFFFEE58));
    // pulau kecil
    final ip = Offset(size.width * 0.12, size.height * 0.62);
    c.drawOval(Rect.fromCenter(center: ip, width: 190, height: 70), Paint()..color = const Color(0x88FFFFFF));
    c.drawOval(Rect.fromCenter(center: ip, width: 160, height: 54), Paint()..color = const Color(0xFFF2D49B));
    drawEmoji(c, '🌴', ip.translate(-20, -46), 70);
    drawEmoji(c, '💰', ip.translate(40, -16), 36);
    // kapal-kapal berlayar
    for (int i = 0; i < 2; i++) {
      final x = ((t * 45 + i * size.width * 0.55) % (size.width + 240)) - 120;
      drawShip(c, x, size.height * (0.42 + i * 0.36), shipColors[i], false, t, i, scale: 0.8);
    }
    drawEmoji(c, '🦜', Offset(size.width * 0.9, size.height * 0.55 + sin(t * 3) * 8), 60);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------
//  PILIH MISI (peta dunia)
// ---------------------------------------------------------------------
class MissionSelectScreen extends StatefulWidget {
  final bool host;
  const MissionSelectScreen({super.key, required this.host});
  @override
  State<MissionSelectScreen> createState() => _MissionSelectScreenState();
}

class _MissionSelectScreenState extends State<MissionSelectScreen> with SingleTickerProviderStateMixin, LoopTime {
  int unlocked = 0;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    startLoop();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => unlocked = p.getInt('unlocked') ?? 0);
    }).catchError((_) {});
    Voice.say('Pilih negara yang mau kita kunjungi!');
  }

  @override
  void dispose() {
    stopLoop();
    super.dispose();
  }

  Future<void> _pick(int i) async {
    if (busy) return;
    if (i > unlocked) {
      Voice.say('Negara ini masih terkunci. Selesaikan misi sebelumnya dulu ya!');
      return;
    }
    busy = true;
    Voice.say(countries[i].name);
    final nav = Navigator.of(context);
    if (widget.host) {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => HostLobbyScreen(mission: i)));
    } else {
      final s = await Session.createSolo(i);
      if (!mounted) {
        s.close();
        return;
      }
      nav.pushReplacement(MaterialPageRoute(builder: (_) => GameScreen(session: s)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (ctx, cons) {
        final size = cons.biggest;
        return Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              onTapUp: (d) {
                for (int i = 0; i < countries.length; i++) {
                  if ((WorldMapPainter.pos(size, i) - d.localPosition).distance < 40) {
                    _pick(i);
                    return;
                  }
                }
              },
              child: CustomPaint(painter: WorldMapPainter(unlocked: unlocked, t: time, select: true)),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Chip2(child: Text('⬅')),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: OutlinedTitle(widget.host ? '👑 Kapten, pilih negara!' : '🗺️ Pilih negara!', size: 26),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}

// ---------------------------------------------------------------------
//  LOBI KAPTEN (host)
// ---------------------------------------------------------------------
class HostLobbyScreen extends StatefulWidget {
  final int mission;
  const HostLobbyScreen({super.key, required this.mission});
  @override
  State<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends State<HostLobbyScreen> {
  Session? s;
  bool handed = false;

  @override
  void initState() {
    super.initState();
    Session.createHost(widget.mission).then((v) {
      if (!mounted) {
        v.close();
        return;
      }
      v.onChange = () {
        if (mounted) setState(() {});
      };
      setState(() => s = v);
    });
    Voice.say('Tunggu teman-temanmu bergabung, lalu tekan mulai!');
  }

  @override
  void dispose() {
    if (!handed) s?.close();
    super.dispose();
  }

  void _start() {
    final v = s;
    if (v == null) return;
    handed = true;
    v.onChange = null;
    v.startGame();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameScreen(session: v)));
  }

  @override
  Widget build(BuildContext context) {
    final v = s;
    final c = countries[widget.mission];
    return Scaffold(
      backgroundColor: const Color(0xFF01579B),
      body: SafeArea(
        child: v == null
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Chip2(child: Text('⬅'))),
                        const SizedBox(width: 12),
                        Expanded(child: OutlinedTitle('👑 Kapal Kapten • ${c.flag} Misi ${widget.mission + 1}', size: 24)),
                      ]),
                      const SizedBox(height: 10),
                      const Text('Kru kapal yang sudah naik:',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Wrap(spacing: 12, runSpacing: 8, children: [
                          for (final id in v.lobbyIds)
                            Column(mainAxisSize: MainAxisSize.min, children: [
                              ShipIcon(id, size: 96),
                              Text(id == 0 ? 'Kapten ${shipNames[id % 4]}' : 'Kru ${shipNames[id % 4]}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                            ]),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(14)),
                        child: Text(
                          '📶 Nyalakan HOTSPOT di HP ini. HP teman sambungkan Wi-Fi ke hotspot ini, '
                          'lalu pilih "Ikut Main".\nKalau tidak muncul otomatis, ketik alamat: '
                          '${v.myIps.isEmpty ? "-" : v.myIps.join("  /  ")}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${v.lobbyIds.length} / 4 kapal',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 14),
                        KidButton(
                            emoji: '🚀', label: 'Mulai Berlayar!', color: const Color(0xFF43A047), width: 220, onTap: _start),
                      ]),
                    ),
                  ),
                ]),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  IKUT MAIN (client)
// ---------------------------------------------------------------------
class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});
  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  Session? s;
  bool handed = false, connecting = false;
  String msg = '';
  final ipCtl = TextEditingController(text: '192.168.43.1');

  @override
  void initState() {
    super.initState();
    _create();
    Voice.say('Cari kapal kapten, lalu ketuk untuk naik!');
  }

  Future<void> _create() async {
    final v = await Session.createClient();
    if (!mounted) {
      v.close();
      return;
    }
    v.onChange = _onChange;
    setState(() => s = v);
  }

  void _onChange() {
    if (!mounted || handed) return;
    final v = s;
    if (v == null) return;
    if (v.started) {
      handed = true;
      v.onChange = null;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameScreen(session: v)));
      return;
    }
    if (v.full) {
      msg = 'Kapal sudah penuh (maksimal 4).';
    }
    if (v.lost) {
      msg = 'Sambungan ke kapten terputus.';
      // buat sesi baru agar bisa mencari lagi
      v.close();
      s = null;
      _create();
    }
    setState(() {});
  }

  @override
  void dispose() {
    if (!handed) s?.close();
    ipCtl.dispose();
    super.dispose();
  }

  Future<void> _join(String ip) async {
    final v = s;
    if (v == null || connecting) return;
    setState(() {
      connecting = true;
      msg = 'Menghubungi kapten...';
    });
    final ok = await v.join(ip);
    if (!mounted) return;
    setState(() {
      connecting = false;
      msg = ok ? '' : 'Kapten tidak ditemukan di $ip';
    });
    if (ok) Voice.say('Kamu sudah naik kapal! Tunggu kapten mulai ya!');
  }

  @override
  Widget build(BuildContext context) {
    final v = s;
    final connected = v?.connected ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Chip2(child: Text('⬅'))),
              const SizedBox(width: 12),
              const OutlinedTitle('🤝 Ikut Main', size: 26),
            ]),
            const SizedBox(height: 12),
            if (v == null)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else if (connected)
              Center(
                child: Column(children: [
                  ShipIcon(v.myId, size: 130),
                  Text('Kamu kapal ${shipNames[v.myId % 4]}!',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Kru: ${v.lobbyIds.length} kapal • Menunggu kapten menekan mulai... ⏳',
                      style: const TextStyle(color: Colors.white70, fontSize: 16)),
                ]),
              )
            else ...[
              const Text('Kapal kapten di sekitar:',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (v.rooms.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('🔭 Mencari kapal kapten... Pastikan Wi-Fi HP ini tersambung ke hotspot HP kapten.',
                      style: TextStyle(color: Colors.white70, fontSize: 15)),
                ),
              Wrap(spacing: 12, runSpacing: 10, children: [
                for (final r in v.rooms.values)
                  KidButton(emoji: '🏴‍☠️', label: r.name, color: const Color(0xFFE53935), onTap: () => _join(r.ip)),
              ]),
              const SizedBox(height: 16),
              const Text('Atau ketik alamat kapten (lihat di layar HP kapten):',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              Row(children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: ipCtl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: connecting ? null : () => _join(ipCtl.text),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    child: Text('Sambung', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ]),
            ],
            if (msg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(msg, style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 16, fontWeight: FontWeight.w700)),
              ),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  LAYAR GAME
// ---------------------------------------------------------------------
class GameScreen extends StatefulWidget {
  final Session session;
  const GameScreen({super.key, required this.session});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double t = 0;
  final List<Particle> fx = [];
  final Map<int, Offset> sm = {};
  final Map<int, Offset> wm = {};
  double _wrongT = 0;
  List<Offset> mobSm = [];
  Offset? target;
  double targetAge = 9;
  double _fwAcc = 0, _moveAcc = 0;
  Offset? _pendingMove;
  final Random rnd = Random();
  Size _size = Size.zero;

  Session get s => widget.session;
  GameState get gs => s.gs;

  @override
  void initState() {
    super.initState();
    s.onChange = () {};
    s.attach(_onEvent);
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    s.close();
    super.dispose();
  }

  // ---------- efek dari kejadian permainan ----------
  void _onEvent(Map<String, dynamic> e) {
    final x = e['x'] is num ? _n(e['x']) : 0.0;
    final y = e['y'] is num ? _n(e['y']) : 0.0;
    switch (e['k']) {
      case 'say':
        Voice.say(e['s'] as String);
        break;
      case 'pop':
        HapticFeedback.lightImpact();
        for (int i = 0; i < 16; i++) {
          final a = i / 16 * pi * 2;
          fx.add(Particle(x, y, cos(a) * 220, sin(a) * 220, 0.7, const Color(0xFFFFEB3B), 10, grav: 120));
        }
        fx.add(Particle(x, y, 0, -160, 1.0, Colors.white, 70, kind: 2, emoji: gs.c.item));
        fx.add(Particle(x + 30, y - 10, 40, -120, 0.9, Colors.white, 40, kind: 2, emoji: '✨'));
        break;
      case 'dig':
        HapticFeedback.selectionClick();
        for (int i = 0; i < 8; i++) {
          fx.add(Particle(x, y, (rnd.nextDouble() - 0.5) * 320, -120 - rnd.nextDouble() * 260, 0.6,
              const Color(0xFF8D6E63), 9, grav: 900));
        }
        break;
      case 'treasure':
        HapticFeedback.heavyImpact();
        for (int i = 0; i < 34; i++) {
          fx.add(Particle(x, y - 20, (rnd.nextDouble() - 0.5) * 520, -260 - rnd.nextDouble() * 380, 1.7,
              Colors.amber, 11, grav: 850, kind: 1));
        }
        _burst(x - 200, y - 220);
        _burst(x + 120, y - 260);
        break;
      case 'bump':
        if ((e['pid'] as num?)?.toInt() == s.myId) HapticFeedback.mediumImpact();
        for (int i = 0; i < 14; i++) {
          fx.add(Particle(x, y, (rnd.nextDouble() - 0.5) * 380, -60 - rnd.nextDouble() * 220, 0.7,
              const Color(0xFFE1F5FE), 8, grav: 600));
        }
        break;
      case 'grab':
        if ((e['pid'] as num?)?.toInt() == s.myId) HapticFeedback.heavyImpact();
        for (int i = 0; i < 18; i++) {
          fx.add(Particle(x, y, (rnd.nextDouble() - 0.5) * 420, -80 - rnd.nextDouble() * 260, 0.8,
              const Color(0xFFE1F5FE), 9, grav: 600));
        }
        break;
      case 'tickle':
        HapticFeedback.selectionClick();
        fx.add(Particle(x + (rnd.nextDouble() - 0.5) * 60, y - 30, (rnd.nextDouble() - 0.5) * 80, -140, 0.8,
            Colors.white, 34, kind: 2, emoji: rnd.nextBool() ? '😆' : '✨'));
        break;
      case 'free':
        HapticFeedback.mediumImpact();
        for (int i = 0; i < 6; i++) {
          fx.add(Particle(x + (rnd.nextDouble() - 0.5) * 80, y - 40, (rnd.nextDouble() - 0.5) * 160,
              -120 - rnd.nextDouble() * 120, 1.4, Colors.white, 38, kind: 2, emoji: i.isEven ? '💖' : '⭐'));
        }
        _burst(x, y - 60);
        break;
      case 'rocktap':
        for (int i = 0; i < 5; i++) {
          fx.add(Particle(x + (rnd.nextDouble() - 0.5) * 60, y - 20, (rnd.nextDouble() - 0.5) * 260,
              -120 - rnd.nextDouble() * 200, 0.6, const Color(0xFF9E9E9E), 8, grav: 900));
        }
        break;
      case 'rockbreak':
        HapticFeedback.heavyImpact();
        for (int i = 0; i < 36; i++) {
          final a = rnd.nextDouble() * pi * 2;
          final sp = 150 + rnd.nextDouble() * 320;
          fx.add(Particle(x, y, cos(a) * sp, sin(a) * sp - 200, 1.2,
              i.isEven ? const Color(0xFF9E9E9E) : const Color(0xFF616161), 10 + rnd.nextDouble() * 10, grav: 800));
        }
        fx.add(Particle(x, y - 40, 0, -100, 1.4, Colors.white, 80, kind: 2, emoji: '💥'));
        break;
      case 'found':
        HapticFeedback.heavyImpact();
        fx.add(Particle(x, y - 30, 0, -120, 1.6, Colors.white, 90, kind: 3, emoji: '${e['tool']}'));
        for (int i = 0; i < 18; i++) {
          final a = i / 18 * pi * 2;
          fx.add(Particle(x, y - 30, cos(a) * 240, sin(a) * 240, 0.8, const Color(0xFFFFEB3B), 9, grav: 100));
        }
        for (int i = 0; i < 10; i++) {
          fx.add(Particle(x, y, (rnd.nextDouble() - 0.5) * 300, -100 - rnd.nextDouble() * 200, 0.7,
              const Color(0xFF66BB6A), 9, grav: 700));
        }
        break;
      case 'decoy':
        HapticFeedback.lightImpact();
        fx.add(Particle(x, y - 30, 30, -110, 1.2, Colors.white, 56, kind: 2, emoji: '${e['e']}'));
        for (int i = 0; i < 10; i++) {
          fx.add(Particle(x, y, (rnd.nextDouble() - 0.5) * 300, -100 - rnd.nextDouble() * 200, 0.7,
              const Color(0xFF66BB6A), 9, grav: 700));
        }
        break;
      case 'gate':
        HapticFeedback.heavyImpact();
        _burst(x, y - 60);
        for (int i = 0; i < 14; i++) {
          fx.add(Particle(x, y, (rnd.nextDouble() - 0.5) * 360, -120 - rnd.nextDouble() * 220, 0.9,
              const Color(0xFFA0632B), 10, grav: 800));
        }
        break;
      case 'correct':
        HapticFeedback.mediumImpact();
        for (int i = 0; i < 3; i++) {
          _burst(400 + rnd.nextDouble() * 800, 150 + rnd.nextDouble() * 250);
        }
        break;
      case 'wrong':
        HapticFeedback.heavyImpact();
        _wrongT = 0.5;
        break;
      case 'fw':
        for (int i = 0; i < 5; i++) {
          _burst(250 + rnd.nextDouble() * 1100, 150 + rnd.nextDouble() * 300);
        }
        break;
    }
  }

  void _burst(double x, double y) {
    const cols = [Color(0xFFFF5252), Color(0xFFFFEB3B), Color(0xFF69F0AE), Color(0xFF40C4FF), Color(0xFFE040FB)];
    final col = cols[rnd.nextInt(cols.length)];
    for (int i = 0; i < 26; i++) {
      final a = i / 26 * pi * 2;
      final sp = 170 + rnd.nextDouble() * 90;
      fx.add(Particle(x, y, cos(a) * sp, sin(a) * sp, 1.1, col, 8, grav: 70));
    }
  }

  // ---------- loop ----------
  void _tick(Duration el) {
    final dt = ((el - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = el;
    t += dt;
    targetAge += dt;
    s.tick(dt);

    // kirim gerakan jari (seret) maksimal 12x per detik
    _moveAcc += dt;
    final pm = _pendingMove;
    if (pm != null && _moveAcc > 0.08) {
      _moveAcc = 0;
      _pendingMove = null;
      s.tap(pm.dx, pm.dy, move: true);
    }

    // posisi halus (penting untuk HP kru)
    final k = s.isHost ? 1.0 : min(1.0, dt * 12);
    final ids = gs.ships.keys.toSet();
    sm.removeWhere((id, _) => !ids.contains(id));
    for (final sh in gs.ships.values) {
      final tp = Offset(sh.x, sh.y);
      final cur = sm[sh.id];
      sm[sh.id] = cur == null || (cur - tp).distance > 300 ? tp : Offset.lerp(cur, tp, k)!;
    }
    final wids = gs.walkers.keys.toSet();
    wm.removeWhere((id, _) => !wids.contains(id));
    for (final w in gs.walkers.values) {
      final tp = Offset(w.x, w.y);
      final cur = wm[w.id];
      wm[w.id] = cur == null || (cur - tp).distance > 300 ? tp : Offset.lerp(cur, tp, k)!;
    }
    if (_wrongT > 0) _wrongT -= dt;
    if (mobSm.length != gs.mobs.length) mobSm = [for (final m in gs.mobs) Offset(m.x, m.y)];
    for (int i = 0; i < gs.mobs.length; i++) {
      final tp = Offset(gs.mobs[i].x, gs.mobs[i].y);
      mobSm[i] = (mobSm[i] - tp).distance > 300 ? tp : Offset.lerp(mobSm[i], tp, k)!;
    }

    // kembang api saat harta ditemukan
    if (gs.phase == 'treasure' || gs.phase == 'finish') {
      _fwAcc += dt;
      if (_fwAcc > 0.7) {
        _fwAcc = 0;
        _burst(250 + rnd.nextDouble() * 1100, 120 + rnd.nextDouble() * 300);
      }
    }

    for (final p in fx) {
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += p.grav * dt;
    }
    fx.removeWhere((p) => p.life <= 0);
    if (fx.length > 500) fx.removeRange(0, fx.length - 500);

    if (mounted) setState(() {});
  }

  Offset _toWorld(Offset local) {
    final (sc, off) = GamePainter.fit(_size);
    return (local - off) / sc;
  }

  void _pointer(Offset local, {bool move = false}) {
    if (gs.phase == 'map' || gs.phase == 'finish') return;
    final w = _toWorld(local);
    if (move) {
      _pendingMove = w;
    } else {
      s.tap(w.dx, w.dy);
    }
    target = w;
    targetAge = move ? 0.6 : 0;
  }

  String _hint({bool speak = false}) {
    final c = gs.c;
    final me = gs.ships[s.myId];
    if (me != null && me.stuck) {
      return speak
          ? (gs.ships.length > 1 ? 'Tolong! Tunggu teman datang, atau ketuk guritanya!' : 'Ketuk guritanya biar geli!')
          : 'Tolong! Ketuk guritanya 🐙👆';
    }
    for (final o in gs.ships.values) {
      if (o.stuck) {
        return speak
            ? 'Kapal ${shipNames[o.id % 4]} ditangkap gurita! Ayo dekati kapalnya untuk menolong!'
            : 'Kapal ${shipNames[o.id % 4]} butuh bantuan! Dekati kapalnya 🆘';
      }
    }
    switch (gs.phase) {
      case 'map':
        return 'Ayo berlayar ke ${c.name}!';
      case 'sail':
        return speak ? c.intro : 'Kumpulkan ${c.itemCount} ${c.itemName} ${c.item}';
      case 'island':
        return speak ? 'Berlayar ke dermaga pulau!' : 'Berlayar ke dermaga pulau ⚓';
      case 'land':
        return speak ? gs.hintSpeech() : gs.hintText();
      case 'dig':
        return speak ? 'Ketuk cangkulnya untuk menggali bersama!' : 'Gali bersama! Ketuk cangkul';
      case 'chest':
        return speak ? puzzleFor(gs.mission, 2).q : 'Jawab teka-teki untuk membuka peti!';
      case 'treasure':
        return c.fact;
      default:
        return speak ? finishSpeech : '🏆 Kalian Raja Bajak Laut!';
    }
  }

  Widget _puzzleOverlay() {
    final p = puzzleFor(gs.mission, gs.pz);
    final shake = _wrongT > 0 ? sin(_wrongT * 40) * 14 * _wrongT : 0.0;
    final isNum = p.choices.every((ch) => int.tryParse(ch) != null);
    return Positioned.fill(
      child: Container(
        color: const Color(0x99000000),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: min(_size.width * 0.86, 640.0), maxHeight: _size.height * 0.92),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Transform.translate(
              offset: Offset(shake, 0),
              child: Container(
                width: 600,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFF8D6E3F), width: 5),
                  boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 16, offset: Offset(0, 8))],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    const Text('🦜', style: TextStyle(fontSize: 44)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p.q,
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF3E2410))),
                    ),
                    GestureDetector(
                      onTap: () => Voice.say(p.q),
                      child: const Text('🔊', style: TextStyle(fontSize: 34)),
                    ),
                  ]),
                  if (p.show.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(p.show, textAlign: TextAlign.center, style: const TextStyle(fontSize: 46)),
                    ),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    for (int i = 0; i < p.choices.length; i++)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          s.answer(i);
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: const Color(0xFFFFB300), width: 5),
                            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 5))],
                          ),
                          child: Text(p.choices[i],
                              style: TextStyle(
                                  fontSize: isNum ? 64.0 : 62.0,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF3E2410))),
                        ),
                      ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _askExit() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari petualangan?'),
        content: Text(s.isHost && !s.solo ? 'Kalau kapten keluar, teman-teman juga berhenti main.' : 'Progres misi yang sudah selesai tetap tersimpan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Tidak')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Ya, keluar')),
        ],
      ),
    );
    if (yes == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = gs.c;
    final phase = gs.phase;
    final showItems = phase == 'sail' || phase == 'island';
    final showTools = phase == 'land' || phase == 'dig' || phase == 'chest';
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(builder: (ctx, cons) {
          _size = cons.biggest;
          return Stack(children: [
            // dunia permainan
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _pointer(e.localPosition),
                onPointerMove: (e) => _pointer(e.localPosition, move: true),
                child: CustomPaint(
                  painter: GamePainter(gs, t, sm, mobSm, fx, target, targetAge, s.myId, wm),
                ),
              ),
            ),

            // peta perjalanan antar negara
            if (phase == 'map')
              Positioned.fill(
                child: Stack(children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: WorldMapPainter(current: gs.mission, progress: (gs.phaseT - 0.5) / 3.0, t: t),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Chip2(
                        child: Text('Misi ${gs.mission + 1} • ${c.flag} ${c.name}', style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  ),
                ]),
              ),

            // atas kiri: keluar + misi
            Positioned(
              top: 10,
              left: 10,
              child: SafeArea(
                child: Row(children: [
                  GestureDetector(onTap: _askExit, child: const Chip2(child: Text('✖'))),
                  const SizedBox(width: 8),
                  if (phase != 'map') Chip2(child: Text('${c.flag} Misi ${gs.mission + 1}/10')),
                ]),
              ),
            ),

            // atas tengah: barang yang dikumpulkan
            if (showItems)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x99FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF8D6E3F), width: 3),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        for (final it in gs.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Opacity(opacity: it.got ? 1 : 0.25, child: Text(c.item, style: const TextStyle(fontSize: 30))),
                          ),
                        if (phase != 'sail') const Text('  ✅', style: TextStyle(fontSize: 26)),
                      ]),
                    ),
                  ),
                ),
              ),

            // atas tengah: alat yang sudah ditemukan
            if (showTools)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xAAFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF8D6E3F), width: 3),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        for (final tl in toolsFor(gs.mission))
                          Opacity(
                            opacity: gs.tools.contains(tl) ? 1 : 0.22,
                            child: ToolIcon(tl, size: 50),
                          ),
                      ]),
                    ),
                  ),
                ),
              ),

            // atas kanan: koin + jumlah kapal
            Positioned(
              top: 10,
              right: 10,
              child: SafeArea(
                child: Row(children: [
                  if (gs.ships.length > 1) ...[
                    Chip2(child: Text('⛵ ${gs.ships.length}')),
                    const SizedBox(width: 8),
                  ],
                  Chip2(child: Text('💰 ${gs.coins}')),
                ]),
              ),
            ),

            // bawah kiri: burung beo pemandu
            if (phase != 'map')
              Positioned(
                left: 10,
                bottom: 10,
                child: SafeArea(
                  child: GestureDetector(
                    onTap: () => Voice.say(_hint(speak: true)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Transform.translate(
                        offset: Offset(0, sin(t * 3) * 4),
                        child: const Text('🦜', style: TextStyle(fontSize: 54)),
                      ),
                      Container(
                        constraints: BoxConstraints(maxWidth: _size.width * 0.42),
                        margin: const EdgeInsets.only(bottom: 26, left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF8D6E3F), width: 3),
                          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))],
                        ),
                        child: Text('${_hint()}  🔊',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF3E2410))),
                      ),
                    ]),
                  ),
                ),
              ),

            // bawah kanan: tombol sekop
            if (phase == 'dig')
              Positioned(
                right: 22,
                bottom: 22,
                child: GestureDetector(
                  onTapDown: (_) => s.digTap(),
                  child: SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox(
                        width: 132,
                        height: 132,
                        child: CircularProgressIndicator(
                          value: (gs.dig / max(1, gs.digNeed)).clamp(0.0, 1.0),
                          strokeWidth: 10,
                          color: const Color(0xFFFFD54F),
                          backgroundColor: const Color(0x55FFFFFF),
                        ),
                      ),
                      Transform.scale(
                        scale: 1 + sin(t * 8) * 0.05,
                        child: Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF7043),
                            border: Border.all(color: Colors.white, width: 5),
                            boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 10, offset: Offset(0, 5))],
                          ),
                          alignment: Alignment.center,
                          child: const ToolIcon('cangkul', size: 82),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

            // teka-teki
            if (gs.pz != 0) _puzzleOverlay(),

            // spanduk harta ditemukan
            if (phase == 'treasure')
              Positioned(
                top: 64,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Transform.scale(
                      scale: Curves.elasticOut.transform((gs.phaseT / 1.2).clamp(0.0, 1.0)),
                      child: const OutlinedTitle('🎉 Harta ditemukan! +10 💰', size: 34),
                    ),
                  ),
                ),
              ),

            // tamat
            if (phase == 'finish')
              Positioned.fill(
                child: Container(
                  color: const Color(0x88000000),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Transform.scale(
                          scale: 1 + sin(t * 3) * 0.06, child: const Text('🏆', style: TextStyle(fontSize: 110))),
                      const OutlinedTitle('Raja Bajak Laut Dunia!', size: 40),
                      const SizedBox(height: 6),
                      const OutlinedTitle('10 negara sudah dikunjungi 🌍', size: 20, color: Colors.white),
                      const SizedBox(height: 16),
                      KidButton(
                          emoji: '🏠',
                          label: 'Kembali ke Menu',
                          color: const Color(0xFF43A047),
                          width: 220,
                          onTap: () => Navigator.of(context).pop()),
                    ]),
                  ),
                ),
              ),

            // kapten keluar (khusus kru)
            if (s.lost)
              Positioned.fill(
                child: Container(
                  color: const Color(0xAA000000),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('😢', style: TextStyle(fontSize: 80)),
                      const OutlinedTitle('Kapten berhenti main', size: 30, color: Colors.white),
                      const SizedBox(height: 16),
                      KidButton(
                          emoji: '🏠',
                          label: 'Kembali',
                          color: const Color(0xFF1E88E5),
                          onTap: () => Navigator.of(context).pop()),
                    ]),
                  ),
                ),
              ),
          ]);
        }),
      ),
    );
  }
}
