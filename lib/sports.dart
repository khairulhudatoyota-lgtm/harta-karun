part of 'main.dart';

// =====================================================================
//  MINI GAME OLAHRAGA KHAS (dimainkan di HP masing-masing)
// =====================================================================
class _FnPainter extends CustomPainter {
  final void Function(Canvas c, Size s) fn;
  _FnPainter(this.fn);
  @override
  void paint(Canvas canvas, Size size) => fn(canvas, size);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SportGame extends StatefulWidget {
  final int mission;
  final HeroDef hero;
  final String playerName;
  final VoidCallback onWin;
  final VoidCallback onClose;
  const SportGame(
      {super.key,
      required this.mission,
      required this.hero,
      required this.playerName,
      required this.onWin,
      required this.onClose});

  @override
  State<SportGame> createState() => _SportGameState();
}

class _SportGameState extends State<SportGame> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double t = 0;
  final Random rnd = Random();

  SportDef get sp => countries[widget.mission].sport;
  late final HeroDef villager = villagerFor(widget.mission);
  double get diff => (widget.mission / (countries.length - 1)).clamp(0.0, 1.0);

  int score = 0;
  int get need => 3;
  bool won = false;
  double wonT = 0;
  bool lost = false;
  double lostT = 0;
  String msg = '';
  double msgT = 0;
  double actT = 0;

  // timing
  double zoneC = 0.5;
  double phaseOff = 0;
  // race / tug
  double countdown = 3.2;
  double me = 0, foe = 0;
  // goal / hoop
  double targetY = 0;
  double shotT = -1;
  bool shotGood = false;
  double shotY = 0;

  @override
  void initState() {
    super.initState();
    _reset();
    _ticker = createTicker(_tick)..start();
    Voice.say('Ayo main ${sp.name} melawan warga ${countries[widget.mission].name}! ${sp.how}');
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _reset() {
    zoneC = 0.25 + rnd.nextDouble() * 0.5;
    phaseOff = rnd.nextDouble() * 6;
    me = 0;
    foe = 0;
    countdown = 3.2;
    targetY = rnd.nextDouble() * 1.4 - 0.7;
    lost = false;
  }

  double get marker => 0.5 + 0.5 * sin(t * (2.0 + diff * 1.6) + phaseOff);
  double get zoneW => [0.28, 0.23, 0.18][score.clamp(0, 2)] - diff * 0.05;
  double get keeperY => sin(t * (1.6 + diff * 1.4)) * 0.85;
  double get hoopY => sin(t * (1.5 + diff * 1.3)) * 0.85;

  void _say(String m) {
    msg = m;
    msgT = 1.6;
  }

  void _tick(Duration el) {
    final dt = ((el - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = el;
    t += dt;
    if (msgT > 0) msgT -= dt;
    if (actT > 0) actT -= dt;
    if (won) {
      wonT += dt;
      if (wonT > 2.8) {
        _ticker.stop();
        widget.onWin();
      }
      setState(() {});
      return;
    }
    if (lost) {
      lostT += dt;
      if (lostT > 2.2) _reset();
      setState(() {});
      return;
    }
    switch (sp.type) {
      case 'race':
        if (countdown > 0) {
          countdown -= dt;
        } else {
          foe += dt / (12.5 - diff * 4.5);
          if (foe >= 1 && !won) {
            lost = true;
            lostT = 0;
            Voice.say('Hampir menang! Ayo coba lagi!');
          }
        }
        break;
      case 'tug':
        if (countdown > 0) {
          countdown -= dt;
        } else {
          me -= dt * (0.10 + diff * 0.08);
          if (me <= -1 && !won) {
            lost = true;
            lostT = 0;
            Voice.say('Hampir menang! Ayo coba lagi!');
          }
        }
        break;
      case 'goal':
      case 'hoop':
        if (shotT >= 0) {
          shotT += dt;
          if (shotT > 0.7) {
            shotT = -1;
            if (shotGood) {
              score++;
              _say(sp.type == 'goal' ? 'GOL! ⭐' : 'MASUK! ⭐');
              HapticFeedback.mediumImpact();
              if (score >= need) _win();
            } else {
              _say(sp.type == 'goal' ? 'Ditangkap! Coba lagi' : 'Meleset! Coba lagi');
            }
            targetY = rnd.nextDouble() * 1.4 - 0.7;
          }
        }
        break;
    }
    setState(() {});
  }

  void _win() {
    won = true;
    wonT = 0;
    HapticFeedback.heavyImpact();
    Voice.say('Kamu menang! Warga memberimu cangkul!');
  }

  void _action() {
    if (won || lost) return;
    switch (sp.type) {
      case 'timing':
        if ((marker - zoneC).abs() <= zoneW / 2) {
          score++;
          actT = 0.6;
          HapticFeedback.mediumImpact();
          _say('Kena! ⭐');
          if (score >= need) {
            _win();
          } else {
            zoneC = 0.25 + rnd.nextDouble() * 0.5;
          }
        } else {
          HapticFeedback.lightImpact();
          _say('Hampir! Coba lagi');
        }
        break;
      case 'race':
        if (countdown > 0) return;
        me += 0.034;
        actT = 0.2;
        if (me >= 1) {
          score = need;
          _win();
        }
        break;
      case 'tug':
        if (countdown > 0) return;
        me += 0.055;
        actT = 0.2;
        if (me >= 1) {
          score = need;
          _win();
        }
        break;
      case 'goal':
        if (shotT >= 0) return;
        shotT = 0;
        shotY = targetY;
        shotGood = (keeperY - targetY).abs() > 0.34;
        actT = 0.5;
        break;
      case 'hoop':
        if (shotT >= 0) return;
        shotT = 0;
        shotY = hoopY;
        shotGood = hoopY.abs() < 0.2;
        actT = 0.5;
        break;
    }
  }

  String get _btnLabel {
    switch (sp.type) {
      case 'race':
        return 'CEPAT!';
      case 'tug':
        return 'DORONG!';
      case 'goal':
        return 'TEMBAK!';
      case 'hoop':
        return 'LEMPAR!';
      default:
        return 'AYO!';
    }
  }

  // ------------------------------------------------------------------
  Color get _laneColor {
    switch (sp.lane) {
      case 'water':
        return const Color(0xFF29B6F6);
      case 'sand':
        return const Color(0xFFFFCC80);
      case 'road':
        return const Color(0xFF78909C);
      case 'snow':
        return const Color(0xFFF5FBFF);
      case 'ice':
        return const Color(0xFFB3E5FC);
      case 'mat':
        return const Color(0xFFEF9A9A);
      default:
        return const Color(0xFF66BB6A);
    }
  }

  void _paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    final k = countries[widget.mission];
    // langit & lantai
    final sky = Offset.zero & size;
    c.drawRect(sky,
        Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [k.sea1, Colors.white]).createShader(sky));
    final floor = Rect.fromLTWH(0, h * 0.55, w, h * 0.45);
    c.drawRect(floor, Paint()..color = _laneColor);
    drawEmoji(c, k.landmark == 'PIRAMIDA' ? '🏜️' : k.landmark, Offset(w * 0.5, h * 0.3), h * 0.28);
    drawEmoji(c, k.flag, Offset(w * 0.08, h * 0.12), h * 0.1);
    final s = h / 330; // skala tokoh

    switch (sp.type) {
      case 'race':
        _paintRace(c, size);
        break;
      case 'tug':
        _paintTug(c, size, s);
        break;
      case 'goal':
      case 'hoop':
        _paintShoot(c, size, s);
        break;
      default:
        _paintTiming(c, size, s);
    }

    // bintang skor
    for (int i = 0; i < need; i++) {
      drawEmoji(c, i < score ? '⭐' : '☆', Offset(w - 40.0 - (need - 1 - i) * 42, 34), 34);
    }
    if (msgT > 0 && msg.isNotEmpty) {
      drawLabel(c, msg, Offset(w / 2, h * 0.16), 30 * (0.8 + 0.2 * msgT.clamp(0.0, 1.0)), const Color(0xFFFFEB3B));
    }
    if ((sp.type == 'race' || sp.type == 'tug') && countdown > 0 && !won) {
      final n = countdown.ceil();
      drawLabel(c, n > 3 ? '' : (countdown > 0.2 ? '$n' : 'MULAI!'), Offset(w / 2, h * 0.42), 80, Colors.white);
    }
    if (lost) drawLabel(c, 'Hampir! Coba lagi 💪', Offset(w / 2, h * 0.42), 36, Colors.white);
    if (won) {
      c.drawRect(Offset.zero & size, Paint()..color = withA(Colors.black, min(0.45, wonT)));
      drawLabel(c, '🏆 MENANG!', Offset(w / 2, h * 0.32), 54, const Color(0xFFFFD54F));
      drawTool(c, 'cangkul', Offset(w / 2, h * 0.58), 120 + sin(t * 6) * 6, angle: -0.6);
      drawLabel(c, 'Kamu dapat cangkul dari warga!', Offset(w / 2, h * 0.8), 24, Colors.white);
      for (int i = 0; i < 12; i++) {
        final a = i / 12 * pi * 2 + t;
        c.drawCircle(Offset(w / 2 + cos(a) * (120 + wonT * 60), h * 0.58 + sin(a) * (80 + wonT * 40)), 7,
            Paint()..color = shipColors[i % 4]);
      }
    }
  }

  void _paintTiming(Canvas c, Size size, double s) {
    final w = size.width, h = size.height;
    final heroP = Offset(w * 0.25, h * 0.78);
    final foeP = Offset(w * 0.75, h * 0.78);
    drawHero(c, heroP.dx, heroP.dy, widget.hero, t, actT > 0 ? 6 : 0, 1, scale: s * 1.6);
    c.save();
    c.translate(foeP.dx, foeP.dy);
    c.scale(-1, 1);
    drawHero(c, 0, 0, villager, t, actT > 0 ? 2 : 0, 2, scale: s * 1.6);
    c.restore();
    // benda olahraga bergerak
    if (actT > 0) {
      final f = 1 - actT / 0.6;
      final p = Offset.lerp(heroP.translate(30, -90 * s), foeP.translate(-30, -90 * s), f)!;
      drawEmoji(c, sp.emoji, p.translate(0, -sin(f * pi) * 60 * s), 46 * s);
    } else {
      drawEmoji(c, sp.emoji, heroP.translate(50 * s, -70 * s + sin(t * 4) * 4), 40 * s);
    }
    drawNameTag(c, widget.playerName, heroP.translate(0, 26 * s), shipColors[0]);
    drawNameTag(c, 'Warga', foeP.translate(0, 26 * s), const Color(0xFF5D4037));
    // bar waktu
    final bar = Rect.fromLTWH(w * 0.12, h * 0.9, w * 0.76, 26);
    c.drawRRect(RRect.fromRectAndRadius(bar.inflate(4), const Radius.circular(16)), Paint()..color = const Color(0xCC3E2410));
    c.drawRRect(RRect.fromRectAndRadius(bar, const Radius.circular(13)), Paint()..color = const Color(0xFFFFCDD2));
    final z = Rect.fromLTWH(bar.left + bar.width * (zoneC - zoneW / 2), bar.top, bar.width * zoneW, bar.height);
    c.drawRRect(RRect.fromRectAndRadius(z, const Radius.circular(10)), Paint()..color = const Color(0xFF66BB6A));
    final mx = bar.left + bar.width * marker;
    c.drawPath(
        Path()
          ..moveTo(mx - 14, bar.top - 18)
          ..lineTo(mx + 14, bar.top - 18)
          ..lineTo(mx, bar.top + 4)
          ..close(),
        Paint()..color = const Color(0xFFFFEB3B));
    c.drawLine(Offset(mx, bar.top), Offset(mx, bar.bottom),
        Paint()
          ..color = const Color(0xFF3E2410)
          ..strokeWidth = 4);
  }

  void _paintRace(Canvas c, Size size) {
    final w = size.width, h = size.height;
    final lanes = [h * 0.66, h * 0.86];
    final dash = Paint()
      ..color = withA(Colors.white, 0.6)
      ..strokeWidth = 4;
    for (final y in lanes) {
      c.drawRect(Rect.fromLTWH(0, y - h * 0.08, w, h * 0.16), Paint()..color = withA(Colors.white, 0.18));
      if (sp.lane == 'water') {
        for (int i = 0; i < 10; i++) {
          final x = (i * w / 9 + t * 40) % w;
          c.drawArc(Rect.fromCenter(center: Offset(x, y + 18), width: 30, height: 12), pi, pi, false,
              Paint()
                ..color = withA(Colors.white, 0.5)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3);
        }
      } else {
        for (double x = 0; x < w; x += 40) {
          c.drawLine(Offset(x, y + h * 0.08), Offset(x + 20, y + h * 0.08), dash);
        }
      }
    }
    final start = w * 0.1, end = w * 0.86;
    c.drawLine(Offset(end + 30, h * 0.56), Offset(end + 30, h * 0.96),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 6);
    drawEmoji(c, '🏁', Offset(end + 30, h * 0.52), 44);
    final racers = [me, foe];
    final names = [widget.playerName, 'Warga'];
    final cols = [shipColors[0], const Color(0xFF5D4037)];
    for (int i = 0; i < 2; i++) {
      final x = start + (end - start) * racers[i].clamp(0.0, 1.0);
      final bob = sin(t * (i == 0 && actT > 0 ? 18 : 8) + i) * 4;
      // penanda wajah pemain
      if (i == 0) {
        c.save();
        c.translate(x - 4, lanes[i] - 30 + bob);
        drawHero(c, 0, 0, widget.hero, t, 5, 1, scale: 0.75);
        c.restore();
      }
      c.save();
      c.translate(x, lanes[i] + bob);
      c.scale(-1, 1); // emoji olahraga menghadap kiri, dibalik supaya menghadap ke garis finis
      drawEmoji(c, sp.emoji, Offset.zero, 74);
      c.restore();
      drawNameTag(c, names[i], Offset(x, lanes[i] + 46), cols[i], size: 14);
    }
  }

  void _paintTug(Canvas c, Size size, double s) {
    final w = size.width, h = size.height;
    final center = Offset(w / 2, h * 0.8);
    c.drawOval(Rect.fromCenter(center: center.translate(0, 6), width: w * 0.8, height: h * 0.22),
        Paint()..color = withA(Colors.white, 0.35));
    c.drawOval(
        Rect.fromCenter(center: center.translate(0, 6), width: w * 0.8, height: h * 0.22),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
    final shift = me.clamp(-1.0, 1.0) * w * 0.28;
    final mid = center.translate(shift, 0);
    drawHero(c, mid.dx - 34 * s, mid.dy, widget.hero, t, 3, 1, scale: s * 1.6);
    c.save();
    c.translate(mid.dx + 34 * s, mid.dy);
    c.scale(-1, 1);
    drawHero(c, 0, 0, villager, t, 3, 2, scale: s * 1.6);
    c.restore();
    if (actT > 0) drawEmoji(c, '💥', mid.translate(0, -70 * s), 40 * s);
    drawNameTag(c, widget.playerName, Offset(mid.dx - 60 * s, mid.dy + 26 * s), shipColors[0]);
    drawNameTag(c, 'Warga', Offset(mid.dx + 60 * s, mid.dy + 26 * s), const Color(0xFF5D4037));
    // garis menang
    for (final sx in [-1.0, 1.0]) {
      final x = w / 2 + sx * w * 0.36;
      c.drawLine(Offset(x, h * 0.66), Offset(x, h * 0.94),
          Paint()
            ..color = sx > 0 ? const Color(0xFF66BB6A) : const Color(0xFFE57373)
            ..strokeWidth = 6);
    }
    drawEmoji(c, '🏆', Offset(w / 2 + w * 0.36, h * 0.6), 34);
  }

  void _paintShoot(Canvas c, Size size, double s) {
    final w = size.width, h = size.height;
    final heroP = Offset(w * 0.2, h * 0.86);
    final goalX = w * 0.8;
    final topY = h * 0.42, botY = h * 0.9;
    double yOf(double v) => (topY + botY) / 2 + v * (botY - topY) / 2;
    drawHero(c, heroP.dx, heroP.dy, widget.hero, t, actT > 0 ? 6 : 0, 1, scale: s * 1.5);
    drawNameTag(c, widget.playerName, heroP.translate(0, 22 * s), shipColors[0]);
    if (sp.type == 'goal') {
      // gawang
      final post = Paint()
        ..color = Colors.white
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(goalX, topY), Offset(goalX + 50, topY), post);
      c.drawLine(Offset(goalX, botY), Offset(goalX + 50, botY), post);
      c.drawLine(Offset(goalX + 50, topY), Offset(goalX + 50, botY), post);
      for (double y = topY; y < botY; y += 18) {
        c.drawLine(Offset(goalX, y), Offset(goalX + 50, y),
            Paint()
              ..color = withA(Colors.white, 0.4)
              ..strokeWidth = 1.5);
      }
      // sasaran
      final tg = Offset(goalX + 14, yOf(targetY));
      c.drawCircle(tg, 22 + sin(t * 6) * 3,
          Paint()
            ..color = const Color(0xFFFFEB3B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5);
      // penjaga
      final kp = Offset(goalX - 4, yOf(keeperY) + 40 * s);
      c.save();
      c.translate(kp.dx, kp.dy);
      c.scale(-1, 1);
      drawHero(c, 0, 0, villager, t, 2, 2, scale: s * 1.35);
      c.restore();
    } else {
      // tiang / ring bergerak
      final hp = Offset(goalX, yOf(hoopY));
      c.drawLine(Offset(goalX + 40, topY - 20), Offset(goalX + 40, botY + 20),
          Paint()
            ..color = const Color(0xFF9E9E9E)
            ..strokeWidth = 8);
      c.drawRect(Rect.fromCenter(center: hp.translate(28, -26), width: 22, height: 60), Paint()..color = Colors.white);
      c.drawOval(
          Rect.fromCenter(center: hp, width: 64, height: 18),
          Paint()
            ..color = const Color(0xFFFF5722)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6);
      // garis panah sasaran
      final ay = yOf(0);
      for (double x = heroP.dx + 80; x < goalX - 40; x += 30) {
        c.drawLine(Offset(x, ay), Offset(x + 16, ay),
            Paint()
              ..color = const Color(0xFFFFEB3B)
              ..strokeWidth = 5);
      }
      drawEmoji(c, '➡️', Offset(goalX - 60, ay), 30);
    }
    // bola
    if (shotT >= 0) {
      final f = (shotT / 0.7).clamp(0.0, 1.0);
      final end = sp.type == 'goal'
          ? (shotGood ? Offset(goalX + 20, yOf(shotY)) : Offset(goalX - 10, yOf(keeperY)))
          : Offset(goalX, yOf(shotY));
      final p = Offset.lerp(heroP.translate(40, -40 * s), end, f)!;
      drawEmoji(c, sp.emoji, p.translate(0, -sin(f * pi) * 90), 42, angle: f * 6);
    } else {
      drawEmoji(c, sp.emoji, heroP.translate(46, -20 * s), 40);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = countries[widget.mission];
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0D2B45),
        child: SafeArea(
          child: Stack(children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _action(),
                child: CustomPaint(painter: _FnPainter(_paint)),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Row(children: [
                GestureDetector(onTap: widget.onClose, child: const Chip2(child: Text('✖'))),
                const SizedBox(width: 8),
                Chip2(child: Text('${sp.emoji} ${sp.name} • ${k.flag} ${k.name}')),
              ]),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: GestureDetector(
                onTap: () => Voice.say(sp.how),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF8D6E3F), width: 3)),
                  child: Text('🦜 ${sp.how} 🔊',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF3E2410))),
                ),
              ),
            ),
            if (!won)
              Positioned(
                right: 18,
                bottom: 16,
                child: GestureDetector(
                  onTapDown: (_) => _action(),
                  child: Transform.scale(
                    scale: actT > 0 ? 0.92 : 1 + sin(t * 6) * 0.03,
                    child: Container(
                      width: 128,
                      height: 128,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF7043),
                        border: Border.all(color: Colors.white, width: 5),
                        boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 10, offset: Offset(0, 5))],
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(sp.emoji, style: const TextStyle(fontSize: 40)),
                        Text(_btnLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
