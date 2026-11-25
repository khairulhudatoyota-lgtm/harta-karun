part of 'main.dart';

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
    {double scale = 1, int pirate = -1, int hero = 0}) {
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
  if (pirate >= 0) drawHero(c, -30, -2, heroes[hero % heroes.length], t, pirate, seed, scale: 0.95);
  c.restore();
}

/// Tokoh bergaya kartun (kepala besar). (x,y) = posisi kaki, menghadap kanan.
/// mood: 0 santai, 1 bersorak, 2 minta tolong, 3 mendorong/linggis, 4 menggali, 5 berjalan, 6 memukul/menendang
void drawHero(Canvas c, double x, double y, HeroDef h, double t, int mood, int seed, {double scale = 1}) {
  c.save();
  c.translate(x, y);
  c.scale(scale, scale);
  if (mood == 1) c.translate(0, -(sin(t * 10 + seed).abs()) * 8);
  final ol = Paint()
    ..color = const Color(0xFF3B2314)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  Paint fill(Color col) => Paint()..color = col;
  Color shade(Color col, double k) => Color.lerp(col, Colors.black, k)!;
  final a = sin(t * (mood == 1 || mood == 2 ? 12 : 9) + seed);
  const headC = Offset(0, -50);
  const headR = 15.0;
  final hijab = h.hat == 'hijab';

  // ---------- rambut belakang ----------
  if (!hijab) {
    if (h.hairStyle == 'braid') {
      for (int i = 0; i < 4; i++) {
        final p = Offset(-13.0 - i * 1.5, -44.0 + i * 7);
        c.drawCircle(p, 5.2 - i * 0.5, fill(h.hair));
        c.drawCircle(p, 5.2 - i * 0.5, ol);
      }
      c.drawCircle(const Offset(-19, -15), 2.5, fill(h.hatColor));
    } else if (h.hairStyle == 'pigtail') {
      for (final sx in [-1.0, 1.0]) {
        final p = Offset(17 * sx, -50);
        c.drawCircle(p, 7.5, fill(h.hair));
        c.drawCircle(p, 7.5, ol);
        c.drawCircle(Offset(13 * sx, -54), 2.6, fill(h.coat ?? h.hatColor));
      }
    } else if (h.hairStyle == 'bob') {
      final back = RRect.fromRectAndRadius(const Rect.fromLTRB(-18, -64, 18, -36), const Radius.circular(11));
      c.drawRRect(back, fill(h.hair));
      c.drawRRect(back, ol);
    }
  } else {
    // kerudung bagian belakang
    final drape = Path()
      ..moveTo(-19, -50)
      ..lineTo(-18, -24)
      ..quadraticBezierTo(0, -19, 18, -24)
      ..lineTo(19, -50)
      ..close();
    c.drawPath(drape, fill(h.hatColor));
    c.drawPath(drape, ol);
    c.drawCircle(headC, 19.5, fill(h.hatColor));
    c.drawCircle(headC, 19.5, ol);
  }

  // ---------- kaki ----------
  final pant = Paint()
    ..color = h.pants
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round;
  late Offset lf, rf;
  if (mood == 5) {
    lf = Offset(-5 + a * 7, 0);
    rf = Offset(5 - a * 7, 0);
  } else if (mood == 3) {
    lf = const Offset(-10, 0);
    rf = const Offset(8, 0);
  } else if (mood == 6) {
    lf = const Offset(-6, 0);
    rf = Offset(10 + a.abs() * 6, -6 - a.abs() * 4);
  } else {
    lf = const Offset(-6, 0);
    rf = const Offset(6, 0);
  }
  c.drawLine(const Offset(-4, -14), lf.translate(0, -3), pant);
  c.drawLine(const Offset(4, -14), rf.translate(0, -3), pant);
  final boot = fill(const Color(0xFF4E342E));
  for (final f in [lf, rf]) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(f.dx - 4.5, f.dy - 5, 10, 5.5), const Radius.circular(2.5));
    c.drawRRect(r, boot);
  }

  // ---------- tangan (posisi) ----------
  final List<Offset> hands = switch (mood) {
    1 => [Offset(-16, -48 + a * 3), Offset(16, -48 - a * 3)],
    2 => [Offset(-17 + a * 3, -52), Offset(17 - a * 3, -52)],
    3 => [Offset(22, -28 + a), Offset(22, -22 - a)],
    4 => [Offset(15, -30 + a * 9), Offset(19, -28 + a * 9)],
    5 => [Offset(-12 - a * 4, -17), Offset(12 + a * 4, -17)],
    6 => [Offset(-10, -22), Offset(21, -36 + a * 4)],
    _ => [Offset(-12, -17), Offset(12, -17 + a * 1.5)],
  };
  final sleeve = Paint()
    ..color = h.coat ?? h.shirt
    ..strokeWidth = 6.5
    ..strokeCap = StrokeCap.round;

  if (mood == 3) {
    c.save();
    c.rotate(0.16);
  }
  // lengan belakang
  c.drawLine(const Offset(-9, -32), hands[0], sleeve);

  // ---------- badan ----------
  final body = RRect.fromRectAndRadius(const Rect.fromLTWH(-11, -37, 22, 25), const Radius.circular(8));
  c.drawRRect(body, fill(h.shirt));
  if (h.stripes) {
    c.save();
    c.clipRRect(body);
    for (double yy = -34; yy < -12; yy += 6) {
      c.drawRect(Rect.fromLTWH(-11, yy, 22, 3), fill(h.hatColor));
    }
    c.restore();
  }
  final coat = h.coat;
  if (coat != null) {
    c.save();
    c.clipRRect(body);
    c.drawPath(
        Path()
          ..moveTo(-11, -37)
          ..lineTo(-3, -37)
          ..lineTo(-5, -12)
          ..lineTo(-11, -12)
          ..close(),
        fill(coat));
    c.drawPath(
        Path()
          ..moveTo(11, -37)
          ..lineTo(3, -37)
          ..lineTo(5, -12)
          ..lineTo(11, -12)
          ..close(),
        fill(shade(coat, 0.12)));
    c.restore();
    for (final by in [-30.0, -24.0]) {
      c.drawCircle(Offset(-6, by), 1.4, fill(const Color(0xFFFFD54F)));
    }
  }
  // sabuk
  c.drawRect(const Rect.fromLTWH(-11, -18, 22, 4), fill(const Color(0xFF4E342E)));
  c.drawRect(const Rect.fromLTWH(-2.5, -18.5, 5, 5), fill(const Color(0xFFFFC107)));
  c.drawRRect(body, ol);

  // alat di tangan
  if (mood == 4) {
    drawTool(c, 'cangkul', hands[1].translate(4, -2), 42, angle: -1.9 + a * 0.5);
  } else if (mood == 3) {
    drawTool(c, 'linggis', hands[0].translate(10, 2), 44, angle: 0.25);
  }
  // lengan depan
  c.drawLine(const Offset(9, -32), hands[1], sleeve);
  for (final hp in hands) {
    c.drawCircle(hp, 3.6, fill(h.skin));
    c.drawCircle(hp, 3.6, ol);
  }
  if (mood == 3) c.restore();

  // ---------- kepala ----------
  if (!hijab) {
    c.drawCircle(const Offset(-14, -48), 3.6, fill(h.skin));
    c.drawCircle(const Offset(-14, -48), 3.6, ol);
  }
  final faceC = hijab ? const Offset(0, -49) : headC;
  final faceR = hijab ? 13.5 : headR;
  c.drawCircle(faceC, faceR, fill(h.skin));
  c.drawCircle(faceC, faceR, ol);
  // pipi merah
  c.drawCircle(const Offset(-8, -44), 2.6, fill(const Color(0x55FF6F6F)));
  c.drawCircle(const Offset(10, -44), 2.6, fill(const Color(0x55FF6F6F)));
  // mata
  final eyeW = mood == 2 ? 4.4 : 3.6, eyeH = mood == 2 ? 5.4 : 4.6;
  final dark = fill(const Color(0xFF1B1B1B));
  final white = fill(Colors.white);
  for (final ex in [-4.5, 6.0]) {
    if (h.eyepatch && ex > 0) continue;
    final e = Offset(ex, -50);
    c.drawOval(Rect.fromCenter(center: e, width: eyeW * 2, height: eyeH * 2), white);
    c.drawOval(
        Rect.fromCenter(center: e, width: eyeW * 2, height: eyeH * 2),
        Paint()
          ..color = const Color(0xFF3B2314)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    c.drawCircle(e.translate(0.9, 0.6), 2.3, dark);
    c.drawCircle(e.translate(1.6, -0.6), 0.9, white);
    if (h.girl) {
      c.drawLine(e.translate(eyeW - 0.5, -eyeH + 1), e.translate(eyeW + 1.8, -eyeH - 0.6),
          Paint()
            ..color = const Color(0xFF1B1B1B)
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round);
    }
  }
  // alis
  final brow = Paint()
    ..color = shade(h.hair, 0.2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;
  final lift = mood == 2 ? -2.0 : 0.0;
  c.drawLine(Offset(-7.5, -56.5 + lift), Offset(-2, -57.2 + lift), brow);
  if (!h.eyepatch) c.drawLine(Offset(3.5, -57.2 + lift), Offset(9, -56.5 + lift), brow);
  // hidung
  c.drawArc(Rect.fromCenter(center: const Offset(1.5, -46), width: 3.6, height: 3), 0, pi, false,
      Paint()
        ..color = shade(h.skin, 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
  // mulut
  if (mood == 2) {
    c.drawOval(Rect.fromCenter(center: const Offset(1, -40.5), width: 5, height: 6), fill(const Color(0xFF7B1F1F)));
  } else if (mood == 1 || mood == 6) {
    final m = Path()
      ..moveTo(-4, -42.5)
      ..quadraticBezierTo(1, -35, 6, -42.5)
      ..close();
    c.drawPath(m, fill(const Color(0xFF7B1F1F)));
    c.drawCircle(const Offset(1, -38.6), 1.8, fill(const Color(0xFFFF8A80)));
  } else {
    c.drawArc(Rect.fromCenter(center: const Offset(1, -42), width: 9, height: 6), 0.2, pi - 0.4, false,
        Paint()
          ..color = const Color(0xFF6D2C10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.9
          ..strokeCap = StrokeCap.round);
  }
  if (h.eyepatch) {
    c.drawLine(const Offset(-14, -57), const Offset(14, -45), Paint()
      ..color = const Color(0xFF1B1B1B)
      ..strokeWidth = 1.8);
    c.drawOval(Rect.fromCenter(center: const Offset(6, -50), width: 10, height: 9), dark);
  }

  // ---------- rambut depan ----------
  if (!hijab) {
    final hairP = fill(h.hair);
    c.save();
    c.clipRect(const Rect.fromLTRB(-24, -80, 24, -54.5));
    c.drawCircle(headC, headR + 1.2, hairP);
    c.restore();
    if (h.hairStyle == 'spiky') {
      final sp = Path()..moveTo(-15, -56);
      for (int i = 0; i < 6; i++) {
        final x0 = -15 + i * 5.0;
        sp.lineTo(x0 + 2.5, -70 + (i.isEven ? 0 : 3));
        sp.lineTo(x0 + 5, -60);
      }
      sp.close();
      c.drawPath(sp, hairP);
    } else if (h.hairStyle == 'curly') {
      for (int i = 0; i < 7; i++) {
        final ang = pi + 0.25 + i * (pi - 0.5) / 6;
        c.drawCircle(Offset(cos(ang) * 14, -52 + sin(ang) * 14), 5.2, hairP);
      }
    } else if (h.hairStyle == 'bob' || h.hairStyle == 'braid' || h.hairStyle == 'pigtail') {
      // poni
      c.drawPath(
          Path()
            ..moveTo(-14, -56)
            ..quadraticBezierTo(-6, -50, 0, -56)
            ..quadraticBezierTo(6, -51, 13, -56)
            ..lineTo(13, -60)
            ..lineTo(-14, -60)
            ..close(),
          hairP);
      c.drawRect(const Rect.fromLTRB(-16.5, -58, -12.5, -42), hairP);
      c.drawRect(const Rect.fromLTRB(12.5, -58, 16.5, -42), hairP);
    }
  } else {
    // lingkar kerudung di dahi & pipi
    c.drawArc(Rect.fromCircle(center: faceC, radius: 14.8), pi * 0.85, pi * 1.3, false,
        Paint()
          ..color = h.hatColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
    c.drawCircle(const Offset(-14, -40), 2.2, fill(const Color(0xFFFFD54F)));
  }

  // ---------- penutup kepala ----------
  switch (h.hat) {
    case 'bandana':
      c.save();
      c.clipRect(const Rect.fromLTRB(-24, -80, 24, -55));
      c.drawCircle(headC, headR + 2, fill(h.hatColor));
      c.restore();
      c.drawLine(const Offset(-16.5, -55), const Offset(16.5, -55),
          Paint()
            ..color = shade(h.hatColor, 0.25)
            ..strokeWidth = 2.4);
      for (final d in [const Offset(-7, -62), const Offset(3, -65), const Offset(10, -59)]) {
        c.drawCircle(d, 1.5, white);
      }
      final knot = Path()
        ..moveTo(-15, -58)
        ..lineTo(-25, -63 + a)
        ..lineTo(-23, -54)
        ..close()
        ..moveTo(-15, -56)
        ..lineTo(-24, -50 + a)
        ..lineTo(-18, -49)
        ..close();
      c.drawPath(knot, fill(h.hatColor));
      break;
    case 'tricorn':
      final hat = Path()
        ..moveTo(-23, -57)
        ..quadraticBezierTo(-12, -60, 0, -82)
        ..quadraticBezierTo(12, -60, 23, -57)
        ..quadraticBezierTo(0, -63, -23, -57)
        ..close();
      if (h.feather) {
        c.drawPath(
            Path()
              ..moveTo(6, -70)
              ..quadraticBezierTo(22, -90, 30, -82)
              ..quadraticBezierTo(20, -78, 6, -70)
              ..close(),
            fill(const Color(0xFFFFFFFF)));
      }
      c.drawPath(hat, fill(h.hatColor));
      c.drawPath(hat, ol);
      c.drawPath(
          Path()
            ..moveTo(-21, -58)
            ..quadraticBezierTo(0, -64, 21, -58),
          Paint()
            ..color = const Color(0xFFFFC107)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      c.drawCircle(const Offset(0, -68), 3.4, white);
      c.drawCircle(const Offset(-1.2, -68.5), 0.8, dark);
      c.drawCircle(const Offset(1.2, -68.5), 0.8, dark);
      break;
    case 'crown':
      final cr = Path()
        ..moveTo(-13, -60)
        ..lineTo(-16, -76)
        ..lineTo(-7, -67)
        ..lineTo(0, -80)
        ..lineTo(7, -67)
        ..lineTo(16, -76)
        ..lineTo(13, -60)
        ..close();
      c.drawPath(cr, fill(const Color(0xFFFFC107)));
      c.drawPath(cr, ol);
      c.drawRect(const Rect.fromLTWH(-13, -63, 26, 3), fill(const Color(0xFFFFA000)));
      c.drawCircle(const Offset(0, -68), 2.6, fill(const Color(0xFFE53935)));
      c.drawCircle(const Offset(-8.5, -64.5), 1.9, fill(const Color(0xFF1E88E5)));
      c.drawCircle(const Offset(8.5, -64.5), 1.9, fill(const Color(0xFF43A047)));
      for (final p in [const Offset(-16, -76), const Offset(0, -80), const Offset(16, -76)]) {
        c.drawCircle(p, 2.2, fill(Colors.white));
      }
      break;
    case 'captain':
      c.drawOval(Rect.fromCenter(center: const Offset(0, -57), width: 38, height: 9), fill(shade(h.hatColor, 0.1)));
      final crown = RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -76, 28, 19), const Radius.circular(7));
      c.drawRRect(crown, fill(h.hatColor));
      c.drawRRect(crown, ol);
      c.drawRect(const Rect.fromLTWH(-14, -62, 28, 3), fill(const Color(0xFFFFC107)));
      c.drawCircle(const Offset(0, -69), 3.6, white);
      c.drawCircle(const Offset(-1.2, -69.5), 0.9, dark);
      c.drawCircle(const Offset(1.2, -69.5), 0.9, dark);
      break;
  }
  if (h.earring && !hijab) c.drawCircle(const Offset(-14, -43), 2.2, fill(const Color(0xFFFFC107)));
  if (h.flower) drawEmoji(c, '🌺', const Offset(-11, -63), 15);
  c.restore();
}

void drawNameTag(Canvas c, String text, Offset center, Color col, {double size = 15}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, color: Colors.white, fontWeight: FontWeight.w800)),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout(maxWidth: 220);
  final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: tp.width + 14, height: tp.height + 6), const Radius.circular(10));
  c.drawRRect(r, Paint()..color = withA(col, 0.92));
  c.drawRRect(
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

/// Kapal besar: semua kru di atas satu kapal.
void drawBigShip(Canvas c, double x, double y, double a, double t, List<int> heroIds, List<int> moods,
    {bool arrow = true, double scale = 1}) {
  if (arrow) {
    final tip = Offset(x + cos(a) * 190, y + sin(a) * 190);
    final start = Offset(x + cos(a) * 110, y + sin(a) * 110);
    c.drawLine(
        start,
        tip,
        Paint()
          ..color = const Color(0xDDFFFFFF)
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round);
    final l = Offset(tip.dx - cos(a - 0.5) * 32, tip.dy - sin(a - 0.5) * 32);
    final r = Offset(tip.dx - cos(a + 0.5) * 32, tip.dy - sin(a + 0.5) * 32);
    c.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(l.dx, l.dy)
          ..lineTo(r.dx, r.dy)
          ..close(),
        Paint()..color = const Color(0xEEFFFFFF));
  }
  final faceLeft = cos(a) < 0;
  c.save();
  c.translate(x, y + sin(t * 2) * 4 * scale);
  c.scale(scale, scale);
  c.drawOval(Rect.fromCenter(center: const Offset(0, 44), width: 280, height: 42), Paint()..color = const Color(0x55FFFFFF));
  c.rotate(sin(t * 1.6) * 0.03 + (faceLeft ? -1 : 1) * sin(a) * 0.1);
  if (faceLeft) c.scale(-1, 1);
  final ol = Paint()
    ..color = const Color(0xFF3B2314)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5
    ..strokeJoin = StrokeJoin.round;
  // kabin belakang
  final cabin = RRect.fromRectAndRadius(const Rect.fromLTWH(-118, -44, 54, 42), const Radius.circular(6));
  c.drawRRect(cabin, Paint()..color = const Color(0xFF8D5524));
  c.drawRRect(cabin, ol);
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-104, -34, 24, 16), const Radius.circular(4)),
      Paint()..color = const Color(0xFFFFE082));
  // tiang & layar
  final mast = Paint()..color = const Color(0xFF5D3A1A);
  c.drawRect(const Rect.fromLTWH(-24, -170, 9, 168), mast);
  c.drawRect(const Rect.fromLTWH(56, -150, 9, 148), mast);
  void sail(double mx, double top, double bottom, double bulge, Color col) {
    final p = Path()
      ..moveTo(mx + 6, top)
      ..quadraticBezierTo(mx + bulge, (top + bottom) / 2, mx + 6, bottom)
      ..lineTo(mx - 40, bottom + 4)
      ..quadraticBezierTo(mx - 40 + bulge * 0.5, (top + bottom) / 2, mx - 40, top + 6)
      ..close();
    c.drawPath(p, Paint()..color = col);
    c.drawPath(p, ol);
  }

  sail(-16, -160, -60, 70, const Color(0xFFFFF8E1));
  sail(64, -142, -56, 60, const Color(0xFFFFF8E1));
  c.drawCircle(const Offset(10, -110), 14, Paint()..color = const Color(0xFF212121));
  c.drawCircle(const Offset(6, -112), 3, Paint()..color = Colors.white);
  c.drawCircle(const Offset(14, -112), 3, Paint()..color = Colors.white);
  // bendera besar
  final wave = sin(t * 6) * 4;
  c.drawPath(
      Path()
        ..moveTo(65, -150)
        ..quadraticBezierTo(85, -156 + wave, 108, -146)
        ..lineTo(108, -124)
        ..quadraticBezierTo(85, -130 + wave, 65, -126)
        ..close(),
      Paint()..color = const Color(0xFF212121));
  c.drawCircle(Offset(86, -138 + wave * 0.5), 6, Paint()..color = Colors.white);
  // kru
  for (int i = 0; i < heroIds.length; i++) {
    final px = -50.0 + i * 42;
    drawHero(c, px, -4, heroes[heroIds[i] % heroes.length], t, i < moods.length ? moods[i] : 0, i, scale: 0.95);
  }
  // lambung
  final hull = Path()
    ..moveTo(-130, -6)
    ..lineTo(138, -16)
    ..quadraticBezierTo(124, 30, 94, 44)
    ..lineTo(-104, 44)
    ..quadraticBezierTo(-124, 28, -130, -6)
    ..close();
  c.drawPath(hull, Paint()..color = const Color(0xFF7B4A22));
  c.drawPath(hull, ol);
  c.drawRect(const Rect.fromLTWH(-124, 6, 250, 6), Paint()..color = const Color(0xFFFFC107));
  c.drawRect(const Rect.fromLTWH(-120, 20, 236, 4), Paint()..color = const Color(0xFF4E2C10));
  for (double px = -84; px <= 92; px += 34) {
    c.drawCircle(Offset(px, 32), 6.5, Paint()..color = const Color(0xFF3E2410));
    c.drawCircle(
        Offset(px, 32),
        6.5,
        Paint()
          ..color = const Color(0xFFFFC107)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }
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
  final Offset bigPos;
  final double bigA;

  GamePainter(this.gs, this.t, this.shipPos, this.mobPos, this.fx, this.target, this.targetAge, this.myId,
      this.walkerPos, this.bigPos, this.bigA);

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

    // kapal besar (level 11 ke atas)
    if (gs.bigMode) {
      final crew = gs.ids;
      final moods = [
        for (final _ in crew) gs.big.stuck ? 2 : (gs.big.cheer > 0 ? 1 : 0)
      ];
      drawBigShip(c, bigPos.dx, bigPos.dy, bigA, t, [for (final id in crew) gs.heroOf(id)], moods,
          arrow: gs.phase != 'map');
      if (gs.big.stuck) {
        c.drawCircle(bigPos.translate(0, -40), 150,
            Paint()
              ..color = const Color(0x66FFFFFF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 9);
        c.drawArc(
            Rect.fromCircle(center: bigPos.translate(0, -40), radius: 150),
            -pi / 2,
            pi * 2 * gs.big.help.clamp(0.0, 1.0),
            false,
            Paint()
              ..color = const Color(0xFF69F0AE)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 9
              ..strokeCap = StrokeCap.round);
        drawEmoji(c, '🆘', bigPos.translate(-60, -210 + sin(t * 8) * 6), 48);
      }
    }

    // kapal + bajak lautnya (urut dari atas ke bawah)
    final ids = gs.bigMode ? <int>[] : (shipPos.keys.toList()..sort((a, b) => shipPos[a]!.dy.compareTo(shipPos[b]!.dy)));
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
      drawShip(c, p.dx, p.dy, shipColor(id), sh?.left ?? false, t, id, pirate: mood, hero: gs.heroOf(id));
      drawNameTag(c, gs.nameOf(id), p.translate(0, 56), shipColor(id), size: 16);

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
        final victim = gs.mobs[i].grab == bigId ? bigPos.translate(60, -10) : shipPos[gs.mobs[i].grab];
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
        if (gs.bigMode || shipPos.length <= 1 || gs.ships[myId]?.stuck == true) {
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
    if (gs.bigMode) {
      drawBigShip(c, 20, 330, 0, t, const [], const [], arrow: false, scale: 0.75);
    } else {
      final sids = gs.ships.keys.toList()..sort();
      for (int i = 0; i < sids.length; i++) {
        drawShip(c, 40, 230.0 + i * 150, shipColor(sids[i]), false, t, sids[i], scale: 0.75);
      }
    }

    // ===== pemandangan khas tiap negara =====
    final m = gs.mission;
    final desert = k.grass == null;
    final snowy = k.sand == const Color(0xFFF5FBFF);
    final lm = m.isEven ? const Offset(1330, 190) : const Offset(1350, 712);
    final sc = Random(m * 71 + 9);
    final used = <Offset>[];
    bool free(Offset p, double r) {
      if ((p.dy - pathY(p.dx)).abs() < 70 + r * 0.5) return false;
      if (gs.hasGate && (p.dx - gateX).abs() < 60 + r * 0.6) return false;
      if (gs.hasBoulder && (p.dx - boulderX).abs() < 70 + r * 0.6) return false;
      if ((p - landX).distance < 160 + r) return false;
      if ((p - lm).distance < 120 + r) return false;
      if ((p - villagerPos).distance < 110 + r) return false;
      if (gs.bushes.any((bb) => (Offset(bb.x, bb.y) - p).distance < 80 + r)) return false;
      if (used.any((q) => (q - p).distance < 60 + r)) return false;
      return true;
    }

    Offset? spot(double r) {
      for (int a = 0; a < 250; a++) {
        final p = Offset(330 + sc.nextDouble() * 1190, 150 + sc.nextDouble() * 620);
        if (free(p, r)) {
          used.add(p);
          return p;
        }
      }
      return null;
    }

    // kolam / oasis / danau beku
    final pond = spot(110);
    if (pond != null) {
      final w = 170 + sc.nextDouble() * 80, h = 90 + sc.nextDouble() * 30;
      c.drawOval(Rect.fromCenter(center: pond, width: w + 22, height: h + 18),
          Paint()..color = snowy ? Colors.white : Color.lerp(k.sand, Colors.brown, 0.15)!);
      c.drawOval(Rect.fromCenter(center: pond, width: w, height: h),
          Paint()..color = snowy ? const Color(0xFFB3E5FC) : const Color(0xFF4FC3F7));
      c.drawOval(Rect.fromCenter(center: pond.translate(-w * 0.18, -h * 0.18), width: w * 0.3, height: h * 0.16),
          Paint()..color = const Color(0x66FFFFFF));
      final swim = Offset(pond.dx + sin(t * 0.6 + m) * w * 0.25, pond.dy + cos(t * 0.5) * h * 0.12);
      drawEmoji(c, snowy ? '🐧' : (desert ? '🐫' : (m % 3 == 0 ? '🦆' : (m % 3 == 1 ? '🐸' : '🦢'))), swim, 42);
      if (desert) {
        drawEmoji(c, '🌴', pond.translate(-w / 2 - 6, -30), 70);
        drawEmoji(c, '🌴', pond.translate(w / 2 + 4, -24), 64);
      }
    }

    // desa kecil di dekat warga
    final house = desert ? '⛺' : (m % 2 == 0 ? '🏠' : '🏡');
    for (final off in const [Offset(150, -40), Offset(-20, 120), Offset(170, 110)]) {
      final hp = villagerPos + off;
      if ((hp.dy - pathY(hp.dx)).abs() < 70 || (hp - landX).distance < 140) continue;
      used.add(hp);
      c.drawOval(Rect.fromCenter(center: hp.translate(0, 32), width: 80, height: 16), Paint()..color = const Color(0x33000000));
      drawEmoji(c, house, hp, 76);
    }

    // petak bunga / bukit pasir / gundukan salju
    for (int i = 0; i < 3 + m % 3; i++) {
      final fp = spot(55);
      if (fp == null) continue;
      if (desert) {
        final dune = Paint()
          ..color = Color.lerp(k.sand, Colors.deepOrange, 0.25)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        c.drawArc(Rect.fromCenter(center: fp, width: 110, height: 40), pi, pi, false, dune);
        c.drawArc(Rect.fromCenter(center: fp.translate(40, 18), width: 80, height: 30), pi, pi, false, dune);
      } else if (snowy) {
        c.drawOval(Rect.fromCenter(center: fp, width: 110, height: 44), Paint()..color = Colors.white);
        c.drawOval(Rect.fromCenter(center: fp.translate(-14, -8), width: 50, height: 16), Paint()..color = const Color(0x55B3E5FC));
      } else {
        const flowers = ['🌼', '🌷', '🌻', '🌸', '🌺'];
        for (int f = 0; f < 6; f++) {
          final ang = f * 1.05 + i;
          drawEmoji(c, flowers[(m + f) % flowers.length], fp.translate(cos(ang) * 34, sin(ang) * 18), 26);
        }
      }
    }

    // jalan setapak (bentuknya beda tiap negara)
    final path = Path()..moveTo(250, pathY(250));
    for (double x = 270; x <= landX.dx - 40; x += 20) {
      path.lineTo(x, pathY(x));
    }
    path.lineTo(landX.dx, landX.dy);
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
          ..color = Color.lerp(ground, snowy ? Colors.white : const Color(0xFFD7B98E), 0.6)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 58
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);

    // ikon negara + bendera
    if (k.landmark == 'PIRAMIDA') {
      drawPyramids(c, lm.translate(0, 30));
    } else {
      drawEmoji(c, k.landmark, lm, 150);
    }
    final pole = landX.translate(90, -50);
    c.drawLine(pole, pole.translate(0, -90),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 5);
    drawEmoji(c, k.flag, pole.translate(24, -74), 44, angle: sin(t * 3) * 0.08);

    // pepohonan & hiasan khas negara
    final base = snowy
        ? const ['🌲', '🌲', '⛄']
        : (desert ? const ['🌵', '🌴', '🌵'] : (m % 3 == 0 ? const ['🌳', '🌴', '🌳'] : const ['🌳', '🌲', '🌴']));
    final trees = <String>[...base, if (k.deco.isNotEmpty) k.deco[0], if (k.deco.length > 2) k.deco[2]];
    final treePos = <Offset>[];
    final nTree = 16 + (m % 4) * 5;
    for (int a = 0; a < 500 && treePos.length < nTree; a++) {
      final p = Offset(300 + sc.nextDouble() * 1260, 110 + sc.nextDouble() * 680);
      if (!free(p, 25)) continue;
      if (treePos.any((q) => (q - p).distance < 85)) continue;
      treePos.add(p);
    }
    // hewan khas berkeliaran
    final animal = k.deco.length > 1 ? k.deco[1] : '🐾';
    final animals = <Offset>[];
    for (int i = 0; i < 2; i++) {
      final ap = spot(30);
      if (ap != null) animals.add(ap);
    }
    final all = <MapEntry<Offset, String>>[
      for (int i = 0; i < treePos.length; i++) MapEntry(treePos[i], trees[(i * 7 + m) % trees.length]),
      for (int i = 0; i < animals.length; i++)
        MapEntry(animals[i].translate(sin(t * 0.7 + i * 2) * 30, 0), '@$animal'),
    ]..sort((a, b) => a.key.dy.compareTo(b.key.dy));
    for (int i = 0; i < all.length; i++) {
      final p = all[i].key;
      final isAnimal = all[i].value.startsWith('@');
      final e = isAnimal ? all[i].value.substring(1) : all[i].value;
      c.drawOval(Rect.fromCenter(center: p.translate(0, isAnimal ? 26 : 40), width: isAnimal ? 50 : 70, height: 14),
          Paint()..color = const Color(0x33000000));
      if (isAnimal) {
        drawEmoji(c, e, p.translate(0, -(sin(t * 6 + i).abs()) * 6), 58);
      } else {
        drawEmoji(c, e, p, 80.0 + (i % 3) * 14, angle: sin(t * 1.2 + i) * 0.03);
      }
    }

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
        final shaking = gs.allHave('linggis') &&
            walkerPos.values.any((w) => (w - gs.boulderPos).distance < 190);
        drawRock(c, gs.boulderPos, gs.boulderHp, t, shaking);
        if (!gs.has(myId, 'linggis')) {
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
      final mine = b.by.contains(myId);
      drawBush(c, Offset(b.x, b.y), mine, near && !mine, t, gs.mission, i);
      if (mine && !isTool(b.c)) {
        drawEmoji(c, b.c, Offset(b.x + 34, b.y - 30 + sin(t * 4 + i) * 4), 36);
      }
    }

    // warga lokal (lawan olahraga)
    {
      final vp = villagerPos;
      final done = gs.sportDone.contains(myId);
      c.drawOval(Rect.fromCenter(center: vp.translate(0, 2), width: 54, height: 14), Paint()..color = const Color(0x44000000));
      c.save();
      c.translate(vp.dx, vp.dy);
      c.scale(-1, 1);
      drawHero(c, 0, 0, villagerFor(gs.mission), t, done ? 1 : 0, 7, scale: 1.55);
      c.restore();
      drawEmoji(c, gs.c.sport.emoji, vp.translate(-48, -40 + sin(t * 3) * 4), 44);
      final bubble = RRect.fromRectAndRadius(
          Rect.fromCenter(center: vp.translate(0, -150), width: 74, height: 58), const Radius.circular(18));
      c.drawRRect(bubble, Paint()..color = Colors.white);
      c.drawRRect(
          bubble,
          Paint()
            ..color = const Color(0xFF8D6E3F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      c.drawPath(
          Path()
            ..moveTo(vp.dx - 8, vp.dy - 122)
            ..lineTo(vp.dx + 8, vp.dy - 122)
            ..lineTo(vp.dx, vp.dy - 108)
            ..close(),
          Paint()..color = Colors.white);
      drawEmoji(c, done ? '✅' : gs.c.sport.emoji, vp.translate(-10, -150), 34);
      if (!done) drawEmoji(c, '❗', vp.translate(22, -152 + sin(t * 6) * 3), 28);
      drawNameTag(c, 'Warga ${gs.c.name}', vp.translate(0, 22), const Color(0xFF5D4037), size: 14);
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
          gs.allHave('linggis') &&
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
      drawHero(c, 0, 0, heroes[gs.heroOf(id) % heroes.length], t, mood, id, scale: 1.55);
      c.restore();
      drawNameTag(c, gs.nameOf(id), p.translate(0, 20), shipColor(id), size: 15);
      if (mood == 3) drawEmoji(c, '💪', p.translate(-36, -120 + sin(t * 9) * 4), 32);
      if (id == myId && walkerPos.length > 1) {
        final ay = p.dy - 150 + sin(t * 6) * 6;
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
  // tambahan: Rusia, Skandinavia, Meksiko, Korea, Filipina, Selandia Baru, Afrika Selatan
  [0.68, 0.17, 0.17, 0.06], [0.51, 0.17, 0.025, 0.05], [0.20, 0.43, 0.04, 0.04], [0.85, 0.325, 0.01, 0.02],
  [0.835, 0.49, 0.01, 0.025], [0.94, 0.79, 0.012, 0.03], [0.55, 0.71, 0.03, 0.03], [0.475, 0.235, 0.01, 0.02],
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
      if (locked && !isNow) {
        c.drawCircle(o, 6, Paint()..color = const Color(0x998D6E3F));
        continue;
      }
      final rad = isNow ? 22 + sin(t * 4) * 3 : 15.0;
      c.drawCircle(o.translate(2, 3), rad, Paint()..color = const Color(0x44000000));
      c.drawCircle(o, rad, Paint()..color = locked ? const Color(0xFFBDBDBD) : Colors.white);
      c.drawCircle(
          o,
          rad,
          Paint()
            ..color = isNow ? const Color(0xFFFFB300) : const Color(0xFF6D4C2F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isNow ? 5 : 3);
      drawEmoji(c, countries[i].flag, o, isNow ? 26 : 18);
      if (isNow) drawLabel(c, '${i + 1}. ${countries[i].name}', o.translate(0, 38), 17, const Color(0xFF4E2C10));
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

