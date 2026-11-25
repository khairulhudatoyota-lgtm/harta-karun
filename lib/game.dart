part of 'main.dart';

// =====================================================================
//  MODEL PERMAINAN (dijalankan oleh Kapten / host)
// =====================================================================
class Profile {
  int hero;
  String name;
  Profile(this.hero, this.name);
  List<dynamic> toJson() => [hero, name];
  static Profile fromJson(dynamic j) {
    final l = j as List;
    return Profile((l[0] as num).toInt().clamp(0, heroes.length - 1), '${l[1]}');
  }
}

class Ship {
  final int id;
  double x, y, tx, ty;
  bool left = false;
  bool stuck = false;
  double help = 0;
  double cheer = 0;
  Ship(this.id, this.x, this.y)
      : tx = x,
        ty = y;
}

/// Kapal besar (level 11 ke atas) – dikemudikan bersama.
class BigShip {
  double x = 180, y = 400, a = 0, v = 0;
  bool stuck = false;
  double help = 0, cheer = 0;
}

class Item {
  double x, y;
  bool got;
  Item(this.x, this.y, [this.got = false]);
}

class Mob {
  double x, y, vx, vy;
  int grab = -1; // -1 bebas, >=0 id kapal, 999 kapal besar
  double cd = 5;
  Mob(this.x, this.y, this.vx, this.vy);
}

class Walker {
  final int id;
  double x, y, tx, ty;
  bool left = false, moving = false;
  Walker(this.id, this.x, this.y)
      : tx = x,
        ty = y;
}

class Bush {
  final double x, y;
  final String c; // 'kunci' / 'linggis' / emoji hewan
  final Set<int> by = {}; // pemain yang sudah menggeledah
  final Map<int, double> st = {};
  Bush(this.x, this.y, this.c);
}

double _n(dynamic v) => (v as num).toDouble();
double _r1(double v) => (v * 10).roundToDouble() / 10;
const int bigId = 999;

class GameState {
  int mission = 0;
  String phase = 'map'; // map, sail, island, land, dig, chest, treasure, finish
  double phaseT = 0;
  final Map<int, Profile> profiles = {};
  final Map<int, Ship> ships = {};
  final BigShip big = BigShip();
  final Map<int, Set<String>> ctl = {};
  List<Item> items = [];
  List<Mob> mobs = [];
  int dig = 0, digNeed = 12, coins = 0;
  // pulau besar
  final Map<int, Walker> walkers = {};
  List<Bush> bushes = [];
  final Map<int, Set<String>> tools = {};
  final Set<int> sportDone = {};
  final Set<int> pzSolved = {};
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
  bool get bigMode => mission >= bigShipFrom;
  Offset get xPos => landX;
  Offset get dock => Offset(c.island.dx - islandR - 48, c.island.dy + 40);
  int get gotCount => items.where((i) => i.got).length;
  bool get onLand =>
      phase == 'land' || phase == 'dig' || phase == 'chest' || phase == 'treasure' || phase == 'finish';
  bool get hasGate => gateFor(mission);
  bool get hasBoulder => boulderFor(mission);
  Offset get boulderPos => Offset(boulderX, pathY(boulderX));
  bool get anyStuck => big.stuck || ships.values.any((s) => s.stuck);
  List<int> get ids => profiles.keys.toList()..sort();
  String nameOf(int id) => profiles[id]?.name ?? 'Teman';
  int heroOf(int id) => profiles[id]?.hero ?? (id % heroes.length);
  bool has(int id, String tool) => tools[id]?.contains(tool) ?? false;
  bool allHave(String tool) => profiles.keys.every((id) => has(id, tool));
  List<String> missing(String tool) => [
        for (final id in ids)
          if (!has(id, tool)) nameOf(id)
      ];
  bool pressed(String k) => ctl.values.any((s) => s.contains(k));

  void emit(Map<String, dynamic> e) {
    evId++;
    e['id'] = evId;
    events.add(e);
    if (events.length > 40) events.removeAt(0);
    onEmit?.call(e);
  }

  /// [to] = hanya dibacakan di HP pemain tersebut.
  void say(String s, {int? to}) => emit({'k': 'say', 's': s, if (to != null) 'to': to});

  Offset _startPos(int id) => Offset(140, 220.0 + (id % 4) * 130);

  // ---------------- pemain ----------------
  void addPlayer(int id, Profile p) {
    profiles[id] = p;
    tools.putIfAbsent(id, () => {});
    final sp = _startPos(id);
    ships[id] = Ship(id, sp.dx, sp.dy);
    if (onLand) {
      walkers[id] = Walker(id, landBeach.dx, 300.0 + (id % 4) * 110);
    }
  }

  void removePlayer(int id) {
    profiles.remove(id);
    ships.remove(id);
    walkers.remove(id);
    tools.remove(id);
    ctl.remove(id);
    sportDone.remove(id);
    pzSolved.remove(id);
  }

  // ---------------- misi ----------------
  void startMission(int m) {
    mission = m.clamp(0, countries.length - 1);
    landMission = mission;
    phase = 'map';
    phaseT = 0;
    dig = 0;
    pz = 0;
    pzSolved.clear();
    sportDone.clear();
    for (final id in profiles.keys) {
      tools[id] = {};
    }
    walkers.clear();
    bushes = [];
    gateOpen = true;
    boulderHp = 0;
    ctl.clear();
    final r = Random(mission * 977 + 13);
    final isl = c.island;
    items = [];
    for (int i = 0; i < itemCountFor(mission); i++) {
      Offset p = const Offset(600, 400);
      for (int a = 0; a < 300; a++) {
        final cand = Offset(300 + r.nextDouble() * (worldW - 500), 160 + r.nextDouble() * (worldH - 240));
        if ((cand - isl).distance < islandR + 110) continue;
        if ((cand - dock).distance < 150) continue;
        if (items.any((it) => (Offset(it.x, it.y) - cand).distance < 170)) continue;
        p = cand;
        break;
      }
      items.add(Item(p.dx, p.dy));
    }
    mobs = [];
    final nMob = min(c.mobs.length, 1 + mission ~/ 3);
    for (int i = 0; i < nMob; i++) {
      final ang = r.nextDouble() * pi * 2;
      final sp = 55 + r.nextDouble() * 35 + min(30.0, mission * 1.0);
      final x = 520 + r.nextDouble() * 450;
      final y = 180 + r.nextDouble() * (worldH - 280);
      mobs.add(Mob(x, y, cos(ang) * sp, sin(ang) * sp)..cd = 6 + i * 4.0);
    }
    for (final id in profiles.keys) {
      final p = _startPos(id);
      ships[id] = Ship(id, p.dx, p.dy);
    }
    big
      ..x = 180
      ..y = 400
      ..a = 0
      ..v = 0
      ..stuck = false
      ..help = 0
      ..cheer = 0;
    say('Misi ${mission + 1}! Ayo berlayar ke ${c.name}!');
  }

  Offset _clampSea(double x, double y, double lim) {
    x = x.clamp(60.0, worldW - 60);
    y = y.clamp(110.0, worldH - 50);
    final isl = c.island;
    final d = Offset(x, y) - isl;
    if (d.distance < lim) {
      final dir = d.distance < 1 ? const Offset(-1, 0) : d / d.distance;
      final p = isl + dir * lim;
      return Offset(p.dx, p.dy);
    }
    return Offset(x, y);
  }

  bool get _seaPhase => phase == 'sail' || phase == 'island';

  // ---------------- input ----------------
  void tap(int id, double x, double y, {bool move = false}) {
    if (phase == 'map' || phase == 'finish') return;
    if (onLand) {
      _tapLand(id, x, y, move);
      return;
    }
    final tp = Offset(x, y);
    // gelitik gurita yang menangkap kapal
    for (final m in mobs) {
      if (!move && m.grab >= 0 && (tp - Offset(m.x, m.y)).distance < 100) {
        if (m.grab == bigId) {
          if (big.stuck) {
            big.help += 0.09;
            emit({'k': 'tickle', 'x': m.x, 'y': m.y});
            if (big.help >= 1) _freeBig();
            return;
          }
        } else {
          final victim = ships[m.grab];
          if (victim != null && victim.stuck) {
            victim.help += 0.13;
            emit({'k': 'tickle', 'x': m.x, 'y': m.y});
            if (victim.help >= 1) _free(victim, id == victim.id ? null : id);
            return;
          }
        }
      }
    }
    if (bigMode) return; // kapal besar dikemudikan dengan tombol
    final s = ships[id];
    if (s == null || s.stuck) return;
    final t = _clampSea(x, y, islandR + 25);
    s.tx = t.dx;
    s.ty = t.dy;
  }

  void control(int id, String k, bool down) {
    final set = ctl.putIfAbsent(id, () => {});
    if (down) {
      set.add(k);
    } else {
      set.remove(k);
    }
  }

  void _free(Ship s, int? helperId) {
    s.stuck = false;
    s.help = 0;
    s.cheer = 2.5;
    final h = helperId == null ? null : ships[helperId];
    if (h != null) h.cheer = 2.5;
    for (final m in mobs) {
      if (m.grab == s.id) _fling(m, s.x, s.y);
    }
    emit({'k': 'free', 'x': s.x, 'y': s.y});
    if (h != null) {
      say('Terima kasih, ${nameOf(h.id)}! Kita tim yang hebat!');
    } else {
      say('Hihi, guritanya geli! Kapal bebas lagi!');
    }
  }

  void _freeBig() {
    big.stuck = false;
    big.help = 0;
    big.cheer = 2.5;
    for (final m in mobs) {
      if (m.grab == bigId) _fling(m, big.x, big.y);
    }
    emit({'k': 'free', 'x': big.x, 'y': big.y});
    say('Hore! Kita bebas karena kompak menggelitik gurita!');
  }

  void _fling(Mob m, double fx, double fy) {
    m.grab = -1;
    m.cd = 14;
    final away = Offset(m.x - fx, m.y - fy);
    final d = max(1.0, away.distance);
    m.vx = away.dx / d * 150;
    m.vy = away.dy / d * 150;
    m.x += away.dx / d * 60;
    m.y += away.dy / d * 60;
  }

  // =================== PULAU BESAR ===================
  void _enterLand() {
    phase = 'land';
    phaseT = 0;
    pz = 0;
    pzSolved.clear();
    sportDone.clear();
    for (final id in profiles.keys) {
      tools[id] = {};
    }
    gateOpen = !hasGate;
    boulderHp = hasBoulder ? 1 : 0;
    big.stuck = false;
    for (final s in ships.values) {
      s.stuck = false;
      s.help = 0;
    }
    for (final m in mobs) {
      m.grab = -1;
    }
    ctl.clear();
    walkers.clear();
    final list = ids;
    for (int i = 0; i < list.length; i++) {
      walkers[list[i]] = Walker(list[i], landBeach.dx, 300.0 + i * 110);
    }
    final r = Random(mission * 53 + 7);
    final z1 = [260.0, hasGate ? gateX - 90 : 1080.0];
    final z2 = [gateX + 80, hasBoulder ? boulderX - 100 : 1080.0];
    final zones = <List<double>>[z1, if (hasGate) z2];
    bushes = [];
    void place(String what, List<double> z) {
      Offset p = Offset((z[0] + z[1]) / 2, 250);
      for (int a = 0; a < 200; a++) {
        final cand = Offset(z[0] + r.nextDouble() * (z[1] - z[0]), 200 + r.nextDouble() * 540);
        if (bushes.any((b) => (Offset(b.x, b.y) - cand).distance < 130)) continue;
        if ((cand - landX).distance < 160) continue;
        if ((cand - villagerPos).distance < 150) continue;
        if ((cand.dy - pathY(cand.dx)).abs() < 50) continue;
        p = cand;
        break;
      }
      bushes.add(Bush(p.dx, p.dy, what));
    }

    for (final t in toolsFor(mission)) {
      if (t == 'kunci') place(t, z1);
      if (t == 'linggis') place(t, z2);
    }
    final decoyList = decoyNames.keys.toList();
    final nDecoy = min(5, 1 + mission ~/ 4);
    for (int i = 0; i < nDecoy; i++) {
      place(decoyList[r.nextInt(decoyList.length)], zones[i % zones.length]);
    }
    say('Kita mendarat di pulau ${c.name}! Ingat, semua pemain harus mendapat alatnya masing-masing!');
  }

  /// Petunjuk untuk pemain [p].
  String nextHint(int p, bool speak) {
    if (hasGate && !gateOpen) {
      if (!has(p, 'kunci')) return speak ? 'Cari kunci di semak-semak!' : 'Cari kunci 🗝️ di semak-semak';
      if (!allHave('kunci')) {
        return speak ? 'Tunggu teman mendapat kunci juga, atau bantu cari!' : 'Tunggu: ${missing('kunci').join(', ')} belum punya kunci';
      }
      return speak ? 'Semua ke gerbang!' : 'Semua ke gerbang 🚪';
    }
    if (hasBoulder && boulderHp > 0) {
      if (!has(p, 'linggis')) return speak ? 'Cari linggis di semak-semak!' : 'Cari linggis di semak-semak';
      if (!allHave('linggis')) {
        return speak ? 'Tunggu teman mendapat linggis juga!' : 'Tunggu: ${missing('linggis').join(', ')} belum punya linggis';
      }
      return speak ? 'Hancurkan batunya bersama-sama!' : 'Hancurkan batu bersama! 💪';
    }
    if (!has(p, 'cangkul')) {
      return speak
          ? 'Temui warga ${c.name} dan menangkan ${c.sport.name} untuk mendapat cangkul!'
          : 'Temui warga & menangkan ${c.sport.name} ${c.sport.emoji}';
    }
    if (!allHave('cangkul')) {
      return speak ? 'Tunggu teman menang olahraga juga!' : 'Tunggu: ${missing('cangkul').join(', ')} belum dapat cangkul';
    }
    return speak ? 'Ayo ke tanda X merah dan gali hartanya!' : 'Semua ke tanda ❌ dan gali!';
  }

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
    if (!move &&
        hasBoulder &&
        boulderHp > 0 &&
        (tp - boulderPos).distance < 110 &&
        allHave('linggis') &&
        (Offset(w.x, w.y) - boulderPos).distance < 200) {
      _hitBoulder(0.04);
      emit({'k': 'rocktap', 'x': boulderPos.dx, 'y': boulderPos.dy});
    }
    Offset target = tp;
    for (final b in bushes) {
      if (!b.by.contains(id) && (Offset(b.x, b.y) - tp).distance < 75) {
        target = Offset(b.x - 40, b.y + 10);
        break;
      }
    }
    if ((tp - villagerPos).distance < 80) target = villagerPos.translate(-70, 0);
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
      say('Batunya hancur! Kerja sama yang hebat! Sekarang temui warga ${c.name}!');
    }
  }

  void _hint(String text) {
    if (hintCd > 0) return;
    hintCd = 7;
    say(text);
  }

  void answer(int id, int choice) {
    if (pz == 0 || pzSolved.contains(id) || !profiles.containsKey(id)) return;
    final p = puzzleFor(mission, pz, id);
    if (choice == p.answer) {
      pzSolved.add(id);
      emit({'k': 'correct', 'pid': id});
      if (profiles.keys.every(pzSolved.contains)) {
        if (pz == 1) {
          pz = 0;
          pzSolved.clear();
          gateOpen = true;
          emit({'k': 'gate', 'x': gateX, 'y': pathY(gateX)});
          say('Semua benar! Gerbangnya terbuka!');
        } else {
          pz = 0;
          pzSolved.clear();
          _treasure();
        }
      } else {
        say('Benar! Tunggu teman-temanmu menjawab ya.', to: id);
      }
    } else {
      emit({'k': 'wrong', 'pid': id});
      say('Hmm, belum tepat. Coba lagi ya!', to: id);
    }
  }

  void sportWin(int id) {
    if (!profiles.containsKey(id) || sportDone.contains(id) || phase != 'land') return;
    sportDone.add(id);
    tools.putIfAbsent(id, () => {}).add('cangkul');
    final w = walkers[id];
    emit({'k': 'found', 'x': w?.x ?? villagerPos.dx, 'y': w?.y ?? villagerPos.dy, 'tool': 'cangkul', 'pid': id});
    if (allHave('cangkul')) {
      say('${nameOf(id)} menang! Sekarang semua punya cangkul. Ayo gali hartanya!');
    } else {
      say('${nameOf(id)} menang ${c.sport.name} dan dapat cangkul!');
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
    if (mission == bigShipFrom - 1) {
      say('${c.fact} Dan ada hadiah istimewa: kapal besar! Mulai sekarang kita naik satu kapal bersama!');
      emit({'k': 'bigship'});
    } else {
      say(c.fact);
    }
    onMissionDone?.call(mission, coins);
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
        pzSolved.clear();
        emit({'k': 'puzzle'});
        say('Petinya ketemu, tapi dikunci teka-teki! Semua jawab teka-tekinya masing-masing!');
      } else {
        _treasure();
      }
    }
  }

  void _updateLand(double dt) {
    hintCd -= dt;
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
      final wait = mission == bigShipFrom - 1 ? 11.0 : 7.5;
      if (phaseT > wait) {
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
    if (phase != 'land' || pz != 0) return;

    // geledah semak (tiap pemain sendiri-sendiri)
    for (final b in bushes) {
      for (final w in walkers.values) {
        if (b.by.contains(w.id)) continue;
        if ((Offset(w.x, w.y) - Offset(b.x, b.y)).distance >= 80) {
          b.st[w.id] = 0;
          continue;
        }
        final st = (b.st[w.id] ?? 0) + dt;
        b.st[w.id] = st;
        if (st >= 0.6) {
          b.by.add(w.id);
          if (isTool(b.c)) {
            tools.putIfAbsent(w.id, () => {}).add(b.c);
            emit({'k': 'found', 'x': b.x, 'y': b.y, 'tool': b.c, 'pid': w.id});
            say('Hore! ${nameOf(w.id)} dapat ${b.c}!');
          } else {
            emit({'k': 'decoy', 'x': b.x, 'y': b.y, 'e': b.c, 'pid': w.id});
            say('Cuma ada ${decoyNames[b.c] ?? 'hewan kecil'}. Cari di semak lain!', to: w.id);
          }
          hintCd = 4;
        }
      }
    }

    // gerbang
    if (hasGate && !gateOpen && walkers.values.any((w) => w.x > gateX - 75)) {
      if (allHave('kunci')) {
        pz = 1;
        pzSolved.clear();
        emit({'k': 'puzzle'});
        say('Gerbangnya dikunci teka-teki! Semua harus menjawab teka-tekinya masing-masing!');
        return;
      } else {
        _hint('Gerbangnya terkunci! Semua harus punya kunci. Yang belum: ${missing('kunci').join(', ')}.');
      }
    }

    // batu besar
    if (hasBoulder && boulderHp > 0) {
      final n = walkers.values.where((w) => (Offset(w.x, w.y) - boulderPos).distance < 190).length;
      if (n > 0) {
        if (allHave('linggis')) {
          _hitBoulder(dt * 0.1 * n * (1 + 0.35 * (n - 1)));
        } else {
          _hint('Batunya keras sekali! Semua harus punya linggis. Yang belum: ${missing('linggis').join(', ')}.');
        }
      }
    }

    // tanda X
    if (walkers.values.any((w) => (Offset(w.x, w.y) - landX).distance < 130)) {
      if (allHave('cangkul')) {
        phase = 'dig';
        phaseT = 0;
        dig = 0;
        digNeed = 10 + 4 * walkers.length;
        const spots = [Offset(-82, -6), Offset(82, -6), Offset(-66, 54), Offset(72, 54)];
        final list = ids;
        for (int i = 0; i < list.length; i++) {
          final w = walkers[list[i]];
          if (w == null) continue;
          final sp = landX + spots[i % 4];
          w.tx = sp.dx;
          w.ty = sp.dy + 40;
        }
        say('Ayo gali bersama-sama! Ketuk cangkulnya!');
      } else {
        _hint('Hartanya di sini! Tapi semua perlu cangkul dari warga. Yang belum: ${missing('cangkul').join(', ')}.');
      }
    }
  }

  // =================== LAUT ===================
  void update(double dt) {
    final prevT = phaseT;
    phaseT += dt;
    bumpCd -= dt;

    if (phase == 'map') {
      if (phaseT > 4.5) {
        phase = 'sail';
        phaseT = 0;
        if (bigMode && profiles.length > 1) {
          final list = ids;
          final roles = [
            for (int i = 0; i < list.length; i++) '${nameOf(list[i])} ${rolesFor(i, list.length).map(roleName).join(' dan ')}'
          ];
          say('${countryIntro(mission)} Kemudikan kapal bersama! ${roles.join(', ')}.');
        } else {
          say(countryIntro(mission));
        }
      }
      return;
    }
    if (phase == 'finish') return;
    if (onLand) {
      _updateLand(dt);
      return;
    }

    if (bigMode) {
      _updateBig(dt);
    } else {
      _updateShips(dt);
    }
    _updateMobs(dt);

    if (phase == 'sail') {
      for (final it in items) {
        if (it.got) continue;
        bool got = false;
        if (bigMode) {
          got = !big.stuck && (Offset(big.x, big.y) - Offset(it.x, it.y)).distance < 95;
        } else {
          for (final s in ships.values) {
            if (!s.stuck && (Offset(s.x, s.y) - Offset(it.x, it.y)).distance < 62) got = true;
          }
        }
        if (got) {
          it.got = true;
          coins += 1;
          emit({'k': 'pop', 'x': it.x, 'y': it.y});
          say('${countWords[(gotCount - 1).clamp(0, countWords.length - 1)]}!');
        }
      }
      if (items.every((i) => i.got)) {
        phase = 'island';
        phaseT = 0;
      }
    } else if (phase == 'island') {
      if (prevT < 1.0 && phaseT >= 1.0) say('Hebat! Sekarang berlayar ke dermaga pulau!');
      bool arrived = false;
      if (bigMode) {
        arrived = !big.stuck && (Offset(big.x, big.y) - dock).distance < 160;
      } else {
        arrived = ships.values.any((s) => !s.stuck && (Offset(s.x, s.y) - dock).distance < 130);
      }
      if (arrived) _enterLand();
    }
  }

  void _updateShips(double dt) {
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
      final p = _clampSea(s.x, s.y, islandR + 25);
      s.x = p.dx;
      s.y = p.dy;
    }
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
  }

  void _updateBig(double dt) {
    final b = big;
    if (b.cheer > 0) b.cheer -= dt;
    if (b.stuck) {
      b.v = 0;
      return;
    }
    final l = pressed('L'), r = pressed('R'), g = pressed('G');
    if (l && !r) b.a -= 1.8 * dt;
    if (r && !l) b.a += 1.8 * dt;
    if (g) {
      b.v = min(240.0, b.v + 200 * dt);
    } else {
      b.v = max(0.0, b.v - 150 * dt);
    }
    b.x += cos(b.a) * b.v * dt;
    b.y += sin(b.a) * b.v * dt;
    final p = _clampSea(b.x, b.y, islandR + 60);
    if ((p.dx - b.x).abs() > 0.5 || (p.dy - b.y).abs() > 0.5) b.v *= 0.5;
    b.x = p.dx;
    b.y = p.dy;
  }

  void _updateMobs(double dt) {
    final isl = c.island;
    for (int i = 0; i < mobs.length; i++) {
      final m = mobs[i];
      final emo = c.mobs[i % c.mobs.length];
      if (m.grab >= 0) {
        if (m.grab == bigId) {
          if (!big.stuck || !_seaPhase) {
            m.grab = -1;
            m.cd = 14;
          } else {
            m.x = big.x + 70 + sin(phaseT * 5) * 4;
            m.y = big.y + 26;
            continue;
          }
        } else {
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
      }
      m.cd -= dt;
      final hunting = emo == '🐙' && m.cd <= 0 && _seaPhase && !anyStuck;
      if (hunting) {
        Offset? near;
        double best = 1e9;
        final targets = bigMode ? [Offset(big.x, big.y)] : [for (final s in ships.values) Offset(s.x, s.y)];
        for (final t in targets) {
          final d = (t - Offset(m.x, m.y)).distance;
          if (d < best) {
            best = d;
            near = t;
          }
        }
        if (near != null && best > 1) {
          final dir = (near - Offset(m.x, m.y)) / best;
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

      if (bigMode) {
        final ds = Offset(big.x - m.x, big.y - m.y);
        final d = ds.distance;
        if (!big.stuck && d < 105) {
          if (hunting) {
            big.stuck = true;
            big.help = 0;
            m.grab = bigId;
            emit({'k': 'grab', 'pid': -1, 'x': big.x, 'y': big.y});
            say(profiles.length > 1
                ? 'Tolong! Gurita menangkap kapal besar! Semua ketuk guritanya bersama-sama!'
                : 'Tolong! Gurita menangkap kapal! Ketuk guritanya biar geli!');
          } else {
            final dir = d < 1 ? const Offset(1, 0) : ds / d;
            big.x += dir.dx * 50;
            big.y += dir.dy * 50;
            big.v *= 0.3;
            m.vx = -m.vx;
            m.vy = -m.vy;
            emit({'k': 'bump', 'pid': -1, 'x': big.x, 'y': big.y});
            if (bumpCd <= 0) {
              say(emo == '🦈' ? 'Ups, hiunya iseng!' : 'Ups, hati-hati!');
              bumpCd = 8;
            }
          }
        }
        continue;
      }

      for (final s in ships.values) {
        if (s.stuck) continue;
        final ds = Offset(s.x - m.x, s.y - m.y);
        final d = ds.distance;
        if (d >= 70) continue;
        if (hunting && !anyStuck) {
          s.stuck = true;
          s.help = 0;
          s.tx = s.x;
          s.ty = s.y;
          m.grab = s.id;
          emit({'k': 'grab', 'pid': s.id, 'x': s.x, 'y': s.y});
          if (ships.length > 1) {
            say('Tolong! Gurita menangkap kapal ${nameOf(s.id)}! Teman-teman, ayo bantu!');
          } else {
            say('Tolong! Gurita menangkap kapalmu! Ketuk guritanya biar geli!');
          }
          break;
        }
        final dir = d < 1 ? const Offset(1, 0) : ds / d;
        s.x += dir.dx * 60;
        s.y += dir.dy * 60;
        final p = _clampSea(s.x, s.y, islandR + 25);
        s.x = p.dx;
        s.y = p.dy;
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
  }

  // =================== MABAR: kirim-terima keadaan ===================
  Map<String, dynamic> toJson() => {
        't': 's',
        'm': mission,
        'p': phase,
        'pt': _r1(phaseT),
        'dg': dig,
        'dn': digNeed,
        'c': coins,
        'pf': {for (final e in profiles.entries) '${e.key}': e.value.toJson()},
        'sh': [
          for (final s in ships.values)
            [s.id, _r1(s.x), _r1(s.y), s.left ? 1 : 0, s.stuck ? 1 : 0, (s.help * 100).round() / 100, _r1(max(0.0, s.cheer))]
        ],
        'bg': [
          _r1(big.x),
          _r1(big.y),
          (big.a * 1000).round() / 1000,
          _r1(big.v),
          big.stuck ? 1 : 0,
          (big.help * 100).round() / 100,
          _r1(max(0.0, big.cheer))
        ],
        'ct': {for (final e in ctl.entries) '${e.key}': e.value.toList()},
        'it': [
          for (final i in items) [_r1(i.x), _r1(i.y), i.got ? 1 : 0]
        ],
        'mb': [
          for (final m in mobs) [_r1(m.x), _r1(m.y), m.grab]
        ],
        'lw': [
          for (final w in walkers.values) [w.id, _r1(w.x), _r1(w.y), w.left ? 1 : 0, w.moving ? 1 : 0]
        ],
        'bu': [
          for (final b in bushes) [_r1(b.x), _r1(b.y), b.c, b.by.toList()]
        ],
        'tl': {for (final e in tools.entries) '${e.key}': e.value.toList()},
        'sd': sportDone.toList(),
        'ps': pzSolved.toList(),
        'go': gateOpen ? 1 : 0,
        'bh': (boulderHp * 100).round() / 100,
        'pz': pz,
        'ev': events,
      };

  List<Map<String, dynamic>> applyJson(Map<String, dynamic> j) {
    mission = (j['m'] as num).toInt();
    landMission = mission;
    phase = j['p'] as String;
    phaseT = _n(j['pt']);
    dig = (j['dg'] as num).toInt();
    digNeed = (j['dn'] as num).toInt();
    coins = (j['c'] as num).toInt();
    profiles.clear();
    (j['pf'] as Map).forEach((k, v) => profiles[int.parse('$k')] = Profile.fromJson(v));
    final seen = <int>{};
    for (final a in (j['sh'] as List)) {
      final l = a as List;
      final id = (l[0] as num).toInt();
      seen.add(id);
      final s = ships.putIfAbsent(id, () => Ship(id, _n(l[1]), _n(l[2])));
      s.x = _n(l[1]);
      s.y = _n(l[2]);
      s.left = (l[3] as num).toInt() == 1;
      s.stuck = (l[4] as num).toInt() == 1;
      s.help = _n(l[5]);
      s.cheer = _n(l[6]);
    }
    ships.removeWhere((k, v) => !seen.contains(k));
    final bg = j['bg'] as List;
    big
      ..x = _n(bg[0])
      ..y = _n(bg[1])
      ..a = _n(bg[2])
      ..v = _n(bg[3])
      ..stuck = (bg[4] as num).toInt() == 1
      ..help = _n(bg[5])
      ..cheer = _n(bg[6]);
    ctl.clear();
    (j['ct'] as Map).forEach((k, v) => ctl[int.parse('$k')] = {for (final x in (v as List)) '$x'});
    items = [
      for (final a in (j['it'] as List)) Item(_n((a as List)[0]), _n(a[1]), (a[2] as num).toInt() == 1)
    ];
    mobs = [
      for (final a in (j['mb'] as List)) Mob(_n((a as List)[0]), _n(a[1]), 0, 0)..grab = (a[2] as num).toInt()
    ];
    final wseen = <int>{};
    for (final a in (j['lw'] as List)) {
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
      for (final a in (j['bu'] as List))
        Bush(_n((a as List)[0]), _n(a[1]), '${a[2]}')..by.addAll([for (final x in (a[3] as List)) (x as num).toInt()])
    ];
    tools.clear();
    (j['tl'] as Map).forEach((k, v) => tools[int.parse('$k')] = {for (final x in (v as List)) '$x'});
    sportDone
      ..clear()
      ..addAll([for (final x in (j['sd'] as List)) (x as num).toInt()]);
    pzSolved
      ..clear()
      ..addAll([for (final x in (j['ps'] as List)) (x as num).toInt()]);
    gateOpen = (j['go'] as num).toInt() != 0;
    boulderHp = _n(j['bh']);
    pz = (j['pz'] as num).toInt();
    return [for (final e in (j['ev'] as List)) Map<String, dynamic>.from(e as Map)];
  }
}

// =====================================================================
//  SESI: main sendiri / Kapten (host) / ikut main (client)
// =====================================================================
class Room {
  final String ip, name;
  DateTime seen;
  Room(this.ip, this.name, this.seen);
}

class Session {
  final bool isHost;
  final bool solo;
  final int startMission;
  final Profile me;
  Session._(this.isHost, this.solo, this.startMission, this.me);

  int myId = 0;
  final GameState gs = GameState();
  final Map<int, Socket> _peers = {};
  ServerSocket? _server;
  RawDatagramSocket? _udp;
  Timer? _timer;
  Socket? _sock;
  final Map<String, Room> rooms = {};
  late final String roomName = 'Kapal ${me.name}';
  List<int> lobbyIds = [0];
  final Map<int, Profile> lobby = {};
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

  static Future<Session> createSolo(int m, Profile me) async {
    final s = Session._(true, true, m, me);
    await s._setupHost();
    s.startGame();
    return s;
  }

  static Future<Session> createHost(int m, Profile me) async {
    final s = Session._(true, false, m, me);
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

  static Future<Session> createClient(Profile me) async {
    final s = Session._(false, false, 0, me);
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
    gs.addPlayer(0, me);
    lobby[0] = me;
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
    final prof = Profile(id % heroes.length, 'Kru ${shipNames[id % 4]}');
    lobby[id] = prof;
    gs.addPlayer(id, prof);
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
      gs.removePlayer(id);
      lobby.remove(id);
      _lobbyUpdate();
    }
  }

  void _lobbyUpdate() {
    lobbyIds = [0, ..._peers.keys];
    _broadcast({
      't': 'l',
      'n': lobbyIds,
      'pf': {for (final e in lobby.entries) '${e.key}': e.value.toJson()}
    });
    _changed();
  }

  void _fromClient(int id, Map<String, dynamic> m) {
    switch (m['t']) {
      case 'hi':
        final p = Profile.fromJson([m['h'], m['n']]);
        lobby[id] = p;
        gs.profiles[id] = p;
        _lobbyUpdate();
        break;
      case 'tap':
        gs.tap(id, _n(m['x']), _n(m['y']), move: m['mv'] == 1);
        break;
      case 'dig':
        gs.doDig(id);
        break;
      case 'ans':
        gs.answer(id, (m['i'] as num).toInt());
        break;
      case 'ctl':
        gs.control(id, '${m['k']}', m['v'] == 1);
        break;
      case 'sport':
        gs.sportWin(id);
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
      _send(so, {'t': 'hi', 'h': me.hero, 'n': me.name});
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
        lobby.clear();
        (m['pf'] as Map).forEach((k, v) => lobby[int.parse('$k')] = Profile.fromJson(v));
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

  void _toHost(Map<String, dynamic> m) {
    final so = _sock;
    if (so != null) _send(so, m);
  }

  void tap(double x, double y, {bool move = false}) {
    if (isHost) {
      gs.tap(myId, x, y, move: move);
    } else {
      _toHost({'t': 'tap', 'x': _r1(x), 'y': _r1(y), if (move) 'mv': 1});
    }
  }

  void answer(int i) {
    if (isHost) {
      gs.answer(myId, i);
    } else {
      _toHost({'t': 'ans', 'i': i});
    }
  }

  void control(String k, bool down) {
    if (isHost) {
      gs.control(myId, k, down);
    } else {
      _toHost({'t': 'ctl', 'k': k, 'v': down ? 1 : 0});
    }
  }

  void sportWon() {
    if (isHost) {
      gs.sportWin(myId);
    } else {
      _toHost({'t': 'sport'});
    }
  }

  void digTap() {
    if (isHost) {
      gs.doDig(myId);
    } else {
      _toHost({'t': 'dig'});
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
