// =====================================================================
//  HARTA KARUN DUNIA
//  Game petualangan bajak laut untuk anak — 30 level keliling dunia.
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

part 'data.dart';
part 'game.dart';
part 'draw.dart';
part 'sports.dart';
part 'update.dart';

// =====================================================================
//  WIDGET BANTU
// =====================================================================
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


class HeroIcon extends StatelessWidget {
  final int hero;
  final double size;
  final bool head;
  final int mood;
  final double t;
  const HeroIcon(this.hero, {super.key, this.size = 80, this.head = false, this.mood = 0, this.t = 0});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _HeroIconPainter(hero, head, mood, t)),
      );
}

class _HeroIconPainter extends CustomPainter {
  final int hero;
  final bool head;
  final int mood;
  final double t;
  _HeroIconPainter(this.hero, this.head, this.mood, this.t);
  @override
  void paint(Canvas c, Size s) {
    final h = heroes[hero % heroes.length];
    if (head) {
      final k = s.width / 42;
      drawHero(c, s.width / 2, s.height / 2 + 52 * k, h, t, mood, hero, scale: k);
    } else {
      final k = s.height / 96;
      drawHero(c, s.width / 2, s.height * 0.97, h, t, mood, hero, scale: k);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroIconPainter o) => o.hero != hero || o.t != t || o.mood != mood;
}

Future<Profile> loadProfile() async {
  try {
    final p = await SharedPreferences.getInstance();
    final h = p.getInt('hero') ?? 0;
    final n = p.getString('name') ?? heroes[h % heroes.length].name;
    return Profile(h.clamp(0, heroes.length - 1), n);
  } catch (_) {
    return Profile(0, heroes[0].name);
  }
}

// =====================================================================
//  APLIKASI
// =====================================================================
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

// =====================================================================
//  MENU UTAMA
// =====================================================================
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin, LoopTime {
  int unlocked = 0, coins = 0;
  bool tamat = false;
  Profile me = Profile(0, heroes[0].name);
  UpdateInfo? update;
  Timer? _refresh;
  bool _askedHero = false;

  @override
  void initState() {
    super.initState();
    startLoop();
    _load(first: true);
    _refresh = Timer.periodic(const Duration(seconds: 2), (_) => _load());
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    final u = await Updater.check();
    if (!mounted || u == null) return;
    setState(() => update = u);
    showDialog(context: context, builder: (_) => UpdateDialog(info: u));
  }

  Future<void> _load({bool first = false}) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;
      final hasHero = p.containsKey('hero');
      final prof = await loadProfile();
      if (!mounted) return;
      setState(() {
        unlocked = p.getInt('unlocked') ?? 0;
        coins = p.getInt('coins') ?? 0;
        tamat = p.getBool('tamat') ?? false;
        me = prof;
      });
      if (first && !hasHero && !_askedHero) {
        _askedHero = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _go(const HeroSelectScreen(first: true)));
      }
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
    final starsDone = tamat ? countries.length : unlocked;
    final u = update;
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _MenuPainter(time))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () => _go(const HeroSelectScreen()),
                  child: Container(
                    padding: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xCC3E2410),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      HeroIcon(me.hero, size: 46, head: true, t: time),
                      const SizedBox(width: 4),
                      Text('${me.name}  ✏️',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                Chip2(child: Text('⭐ $starsDone / ${countries.length}')),
                const Spacer(),
                if (u != null)
                  GestureDetector(
                    onTap: () => showDialog(context: context, builder: (_) => UpdateDialog(info: u)),
                    child: const Chip2(color: Color(0xEE2E7D32), child: Text('🎁 Update baru!')),
                  ),
                const SizedBox(width: 8),
                Chip2(child: Text('💰 $coins')),
              ]),
              const Spacer(),
              const OutlinedTitle('🏴‍☠️ Harta Karun Dunia', size: 44),
              const SizedBox(height: 4),
              const OutlinedTitle('Petualangan Bajak Laut Keliling 30 Negara', size: 19, color: Colors.white),
              const Spacer(),
              Wrap(spacing: 18, runSpacing: 12, alignment: WrapAlignment.center, children: [
                KidButton(
                    emoji: '⛵',
                    label: 'Main Sendiri',
                    color: const Color(0xFF43A047),
                    onTap: () => _go(LevelSelectScreen(host: false, me: me))),
                KidButton(
                    emoji: '👑',
                    label: 'Jadi Kapten\n(Mabar)',
                    color: const Color(0xFFE53935),
                    onTap: () => _go(LevelSelectScreen(host: true, me: me))),
                KidButton(
                    emoji: '🤝',
                    label: 'Ikut Main\n(Mabar)',
                    color: const Color(0xFF1E88E5),
                    onTap: () => _go(JoinScreen(me: me))),
              ]),
              const SizedBox(height: 4),
              Text(appBuild > 0 ? 'versi $appBuild' : '',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
    c.drawCircle(Offset(size.width * 0.86, size.height * 0.2), 46, Paint()..color = const Color(0xFFFFEE58));
    final ip = Offset(size.width * 0.12, size.height * 0.62);
    c.drawOval(Rect.fromCenter(center: ip, width: 190, height: 70), Paint()..color = const Color(0x88FFFFFF));
    c.drawOval(Rect.fromCenter(center: ip, width: 160, height: 54), Paint()..color = const Color(0xFFF2D49B));
    drawEmoji(c, '🌴', ip.translate(-20, -46), 70);
    drawEmoji(c, '💰', ip.translate(40, -16), 36);
    final x1 = ((t * 45) % (size.width + 240)) - 120;
    drawShip(c, x1, size.height * 0.42, shipColors[0], false, t, 0, scale: 0.8, pirate: 0, hero: 0);
    final x2 = ((t * 30 + size.width * 0.55) % (size.width + 400)) - 200;
    drawBigShip(c, x2, size.height * 0.8, 0, t, const [1, 3, 4], const [1, 1, 1], arrow: false, scale: 0.5);
    drawEmoji(c, '🦜', Offset(size.width * 0.9, size.height * 0.55 + sin(t * 3) * 8), 60);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =====================================================================
//  PILIH TOKOH
// =====================================================================
class HeroSelectScreen extends StatefulWidget {
  final bool first;
  const HeroSelectScreen({super.key, this.first = false});
  @override
  State<HeroSelectScreen> createState() => _HeroSelectScreenState();
}

class _HeroSelectScreenState extends State<HeroSelectScreen> with SingleTickerProviderStateMixin, LoopTime {
  int pick = 0;
  final nameCtl = TextEditingController();
  bool _custom = false;

  @override
  void initState() {
    super.initState();
    startLoop();
    loadProfile().then((p) {
      if (!mounted) return;
      setState(() {
        pick = p.hero;
        nameCtl.text = p.name;
        _custom = p.name != heroes[p.hero].name;
      });
    });
    Voice.say('Pilih tokoh bajak lautmu, lalu beri nama!');
  }

  @override
  void dispose() {
    stopLoop();
    nameCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    var name = nameCtl.text.trim();
    if (name.isEmpty) name = heroes[pick].name;
    if (name.length > 14) name = name.substring(0, 14);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('hero', pick);
      await p.setString('name', name);
    } catch (_) {}
    Voice.say('Halo Kapten $name! Ayo berpetualang!');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF01579B),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Row(children: [
          // tokoh terpilih
          SizedBox(
            width: 230,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              HeroIcon(pick, size: 190, mood: 1, t: time),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: nameCtl,
                  maxLength: 14,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  onChanged: (_) => _custom = true,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Nama',
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _save,
                icon: const Text('✅', style: TextStyle(fontSize: 20)),
                label: const Text('Simpan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ]),
          ),
          // daftar tokoh
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 10, 4),
                child: Row(children: [
                  if (!widget.first)
                    GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Chip2(child: Text('⬅'))),
                  const SizedBox(width: 10),
                  const OutlinedTitle('Pilih Tokoh Bajak Laut', size: 26),
                ]),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  padding: const EdgeInsets.all(8),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.05,
                  children: [
                    for (int i = 0; i < heroes.length; i++)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            pick = i;
                            if (!_custom) nameCtl.text = heroes[i].name;
                          });
                          Voice.say(heroes[i].name);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: pick == i
                                  ? const [Color(0xFFFFF59D), Color(0xFFFFB300)]
                                  : const [Color(0xFFB3E5FC), Color(0xFF4FC3F7)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: pick == i ? Colors.white : const Color(0x88FFFFFF), width: pick == i ? 5 : 2),
                          ),
                          child: Column(children: [
                            Expanded(child: HeroIcon(i, size: 120, t: pick == i ? time : 0, mood: pick == i ? 1 : 0)),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(heroes[i].name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF3E2410))),
                            ),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// =====================================================================
//  PILIH LEVEL (jalur 30 negara)
// =====================================================================
class LevelSelectScreen extends StatefulWidget {
  final bool host;
  final Profile me;
  const LevelSelectScreen({super.key, required this.host, required this.me});
  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> with SingleTickerProviderStateMixin, LoopTime {
  int unlocked = 0;
  bool busy = false;
  final scroll = ScrollController();
  static const double step = 150;

  @override
  void initState() {
    super.initState();
    startLoop();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() => unlocked = p.getInt('unlocked') ?? 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) {
          scroll.jumpTo((unlocked * step - 200).clamp(0.0, scroll.position.maxScrollExtent));
        }
      });
    }).catchError((_) {});
    Voice.say('Pilih negara yang mau kita kunjungi!');
  }

  @override
  void dispose() {
    stopLoop();
    scroll.dispose();
    super.dispose();
  }

  double _y(int i, double h) => h * (0.5 + 0.22 * sin(i * 1.1));

  Future<void> _pick(int i) async {
    if (busy) return;
    if (i > unlocked) {
      Voice.say('Negara ini masih terkunci. Selesaikan level sebelumnya dulu ya!');
      return;
    }
    busy = true;
    Voice.say('${countries[i].name}! Olahraganya ${countries[i].sport.name}!');
    final nav = Navigator.of(context);
    if (widget.host) {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => HostLobbyScreen(mission: i, me: widget.me)));
    } else {
      final s = await Session.createSolo(i, widget.me);
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
        final h = cons.maxHeight;
        final totalW = 140 + countries.length * step;
        return Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _SeaBg(time))),
          SingleChildScrollView(
            controller: scroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalW,
              height: h,
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _PathPainter(unlocked, time, h, step, _y))),
                for (int i = 0; i < countries.length; i++)
                  Positioned(
                    left: 80 + i * step - 52,
                    top: _y(i, h) - 52,
                    child: GestureDetector(onTap: () => _pick(i), child: _node(i)),
                  ),
              ]),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: Row(children: [
                GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Chip2(child: Text('⬅'))),
                const SizedBox(width: 10),
                OutlinedTitle(widget.host ? '👑 Kapten, pilih level!' : '🗺️ Pilih level!', size: 24),
              ]),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _node(int i) {
    final k = countries[i];
    final locked = i > unlocked;
    final now = i == unlocked;
    final done = i < unlocked;
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        Transform.scale(
          scale: now ? 1 + sin(time * 4) * 0.05 : 1,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: locked ? const Color(0xFF90A4AE) : Colors.white,
              border: Border.all(color: now ? const Color(0xFFFFB300) : const Color(0xFF6D4C2F), width: now ? 6 : 4),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4))],
            ),
            alignment: Alignment.center,
            child: Text(locked ? '🔒' : k.flag, style: TextStyle(fontSize: locked ? 30 : 40)),
          ),
        ),
        Positioned(
          top: -6,
          left: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF3E2410), borderRadius: BorderRadius.circular(12)),
            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ),
        Positioned(top: -8, right: -4, child: Text(k.sport.emoji, style: const TextStyle(fontSize: 26))),
        if (done) const Positioned(bottom: 6, right: 0, child: Text('⭐', style: TextStyle(fontSize: 24))),
        Positioned(
          bottom: -24,
          child: Text(k.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
        ),
      ]),
    );
  }
}

class _SeaBg extends CustomPainter {
  final double t;
  _SeaBg(this.t);
  @override
  void paint(Canvas c, Size size) => drawSea(c, size, const Color(0xFF4FC3F7), const Color(0xFF01579B), t);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PathPainter extends CustomPainter {
  final int unlocked;
  final double t, h, step;
  final double Function(int i, double h) yOf;
  _PathPainter(this.unlocked, this.t, this.h, this.step, this.yOf);
  @override
  void paint(Canvas c, Size size) {
    for (int i = 0; i < countries.length - 1; i++) {
      final a = Offset(80 + i * step, yOf(i, h));
      final b = Offset(80 + (i + 1) * step, yOf(i + 1, h));
      final d = (b - a).distance;
      final dir = (b - a) / d;
      final done = i < unlocked;
      for (double s = 0; s < d; s += 22) {
        c.drawCircle(a + dir * s, done ? 6 : 4, Paint()..color = done ? const Color(0xFFFFD54F) : const Color(0x99FFFFFF));
      }
      // pulau kecil di bawah titik
    }
    for (int i = 0; i < countries.length; i++) {
      final p = Offset(80 + i * step, yOf(i, h));
      c.drawOval(Rect.fromCenter(center: p.translate(0, 34), width: 120, height: 34), Paint()..color = const Color(0x55FFFFFF));
      c.drawOval(Rect.fromCenter(center: p.translate(0, 34), width: 100, height: 24), Paint()..color = countries[i].sand);
    }
    // tanda hadiah kapal besar
    final bp = Offset(80 + (bigShipFrom - 0.5) * step, yOf(bigShipFrom, h) - 120);
    drawBigShip(c, bp.dx, bp.dy + 40, 0, t, const [0, 1, 3], const [1, 1, 1], arrow: false, scale: 0.32);
    drawLabel(c, '🎁 Kapal Besar', bp.translate(0, 70), 14, Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =====================================================================
//  LOBI KAPTEN (host)
// =====================================================================
class HostLobbyScreen extends StatefulWidget {
  final int mission;
  final Profile me;
  const HostLobbyScreen({super.key, required this.mission, required this.me});
  @override
  State<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends State<HostLobbyScreen> {
  Session? s;
  bool handed = false;

  @override
  void initState() {
    super.initState();
    Session.createHost(widget.mission, widget.me).then((v) {
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
                        Expanded(child: OutlinedTitle('👑 Kapal ${widget.me.name} • ${c.flag} Level ${widget.mission + 1}', size: 22)),
                      ]),
                      const SizedBox(height: 10),
                      const Text('Kru yang sudah naik:',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Wrap(spacing: 12, runSpacing: 8, children: [
                          for (final id in v.lobbyIds)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: withA(shipColor(id), 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                HeroIcon(v.lobby[id]?.hero ?? 0, size: 84),
                                Text('${id == 0 ? '👑 ' : ''}${v.lobby[id]?.name ?? 'Kru'}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                              ]),
                            ),
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
                        Text('${v.lobbyIds.length} / 4 pemain',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        const Text('Semua pemain harus dapat alat\ndan lulus teka-teki masing-masing!',
                            textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
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

// =====================================================================
//  IKUT MAIN (client)
// =====================================================================
class JoinScreen extends StatefulWidget {
  final Profile me;
  const JoinScreen({super.key, required this.me});
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
    final v = await Session.createClient(widget.me);
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
    if (v.full) msg = 'Kapal sudah penuh (maksimal 4).';
    if (v.lost) {
      msg = 'Sambungan ke kapten terputus.';
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
              const Spacer(),
              HeroIcon(widget.me.hero, size: 50, head: true),
              Text(' ${widget.me.name}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 12),
            if (v == null)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else if (connected)
              Center(
                child: Column(children: [
                  Wrap(spacing: 12, children: [
                    for (final id in v.lobbyIds)
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        HeroIcon(v.lobby[id]?.hero ?? 0, size: 90),
                        Text('${id == 0 ? '👑 ' : ''}${v.lobby[id]?.name ?? ''}${id == v.myId ? ' (kamu)' : ''}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      ]),
                  ]),
                  const SizedBox(height: 10),
                  const Text('Menunggu kapten menekan mulai... ⏳', style: TextStyle(color: Colors.white70, fontSize: 16)),
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

// =====================================================================
//  LAYAR GAME
// =====================================================================
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
  Offset? bigSm;
  double bigA = 0;
  double _wrongT = 0;
  bool _sportOpen = false, _sportBlocked = false;
  String _lastHint = '';
  double _hintT = 0;
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
        final to = (e['to'] as num?)?.toInt();
        if (to == null || to == s.myId) Voice.say(e['s'] as String);
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
        if ((e['pid'] as num?)?.toInt() == s.myId) HapticFeedback.heavyImpact();
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
        if ((e['pid'] as num?)?.toInt() != s.myId) break;
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
        if ((e['pid'] as num?)?.toInt() != s.myId) break;
        HapticFeedback.mediumImpact();
        for (int i = 0; i < 3; i++) {
          _burst(400 + rnd.nextDouble() * 800, 150 + rnd.nextDouble() * 250);
        }
        break;
      case 'wrong':
        if ((e['pid'] as num?)?.toInt() != s.myId) break;
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
    final bt = Offset(gs.big.x, gs.big.y);
    final bc = bigSm;
    bigSm = bc == null || (bc - bt).distance > 300 ? bt : Offset.lerp(bc, bt, k)!;
    var da = gs.big.a - bigA;
    while (da > pi) {
      da -= 2 * pi;
    }
    while (da < -pi) {
      da += 2 * pi;
    }
    bigA += da * k;
    if (_wrongT > 0) _wrongT -= dt;
    // petunjuk muncul sebentar setiap kali berganti
    final hnow = _hint();
    if (hnow != _lastHint) {
      _lastHint = hnow;
      _hintT = 5;
    }
    if (_hintT > 0) _hintT -= dt;

    // buka mini game olahraga saat mendekati warga
    final mw = wm[s.myId];
    if (gs.phase == 'land' && gs.pz == 0 && mw != null && !gs.sportDone.contains(s.myId)) {
      final d = (mw - villagerPos).distance;
      if (d > 220) _sportBlocked = false;
      if (!_sportOpen && !_sportBlocked && d < 120) _sportOpen = true;
    } else if (_sportOpen && gs.phase != 'land') {
      _sportOpen = false;
    }
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
    if (!gs.onLand && gs.bigMode && gs.big.stuck) {
      return speak ? 'Semua ketuk guritanya bersama-sama!' : 'Semua ketuk guritanya! 🐙👆';
    }
    if (!gs.onLand && !gs.bigMode) {
      if (me != null && me.stuck) {
        return speak
            ? (gs.ships.length > 1 ? 'Tolong! Tunggu teman datang, atau ketuk guritanya!' : 'Ketuk guritanya biar geli!')
            : 'Tolong! Ketuk guritanya 🐙👆';
      }
      for (final o in gs.ships.values) {
        if (o.stuck) {
          return speak
              ? 'Kapal ${gs.nameOf(o.id)} ditangkap gurita! Ayo dekati kapalnya untuk menolong!'
              : '${gs.nameOf(o.id)} butuh bantuan! Dekati kapalnya 🆘';
        }
      }
    }
    switch (gs.phase) {
      case 'map':
        return 'Ayo berlayar ke ${c.name}!';
      case 'sail':
        if (gs.bigMode && !speak) return 'Kumpulkan ${itemCountFor(gs.mission)} ${c.item} bersama!';
        return speak ? countryIntro(gs.mission) : 'Kumpulkan ${itemCountFor(gs.mission)} ${c.itemName} ${c.item}';
      case 'island':
        return speak ? 'Berlayar ke dermaga pulau!' : 'Berlayar ke dermaga pulau ⚓';
      case 'land':
        return gs.nextHint(s.myId, speak);
      case 'dig':
        return speak ? 'Ketuk cangkulnya untuk menggali bersama!' : 'Gali bersama! Ketuk cangkul';
      case 'chest':
        return speak ? puzzleFor(gs.mission, 2, s.myId).q : 'Jawab teka-teki untuk membuka peti!';
      case 'treasure':
        return c.fact;
      default:
        return speak ? finishSpeech : '🏆 Kalian Raja Bajak Laut!';
    }
  }

  List<String> _myRoles() {
    final list = gs.ids;
    final idx = max(0, list.indexOf(s.myId));
    return rolesFor(idx, max(1, list.length));
  }

  String _myRolesText() => _myRoles().map(roleName).join(' & ');

  Widget _waitOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0x99000000),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D6),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFF8D6E3F), width: 5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('✅ Jawabanmu benar!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
            const SizedBox(height: 4),
            const Text('Tunggu teman-temanmu menjawab ya...',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF3E2410))),
            const SizedBox(height: 12),
            Wrap(spacing: 14, runSpacing: 8, children: [
              for (final id in gs.ids)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  HeroIcon(gs.heroOf(id), size: 64),
                  Text('${gs.nameOf(id)} ${gs.pzSolved.contains(id) ? '✅' : '⏳'}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ]),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _teamPanel() {
    final tl = toolsFor(gs.mission);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xAA3E2410),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        for (final id in gs.ids)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              HeroIcon(gs.heroOf(id), size: 30, head: true),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 80),
                child: Text(gs.nameOf(id),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: id == s.myId ? const Color(0xFFFFD54F) : Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 4),
              for (final t in tl) Opacity(opacity: gs.has(id, t) ? 1 : 0.2, child: ToolIcon(t, size: 24)),
            ]),
          ),
      ]),
    );
  }

  Widget _steering() {
    final roles = _myRoles();
    Widget btn(String k, String label, String icon, Color col) {
      final on = gs.pressed(k);
      return Listener(
        onPointerDown: (_) {
          HapticFeedback.selectionClick();
          s.control(k, true);
        },
        onPointerUp: (_) => s.control(k, false),
        onPointerCancel: (_) => s.control(k, false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 104,
          height: 104,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? Color.lerp(col, Colors.white, 0.35) : col,
            border: Border.all(color: Colors.white, width: on ? 7 : 4),
            boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 10, offset: Offset(0, 5))],
          ),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(icon, style: const TextStyle(fontSize: 38, color: Colors.white, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w900)),
          ]),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (roles.contains('L')) btn('L', 'KIRI', '◀', const Color(0xFF1E88E5)),
      if (roles.contains('G')) btn('G', 'GAS', '▲', const Color(0xFF43A047)),
      if (roles.contains('R')) btn('R', 'KANAN', '▶', const Color(0xFFE53935)),
    ]);
  }

  Widget _puzzleOverlay() {
    if (gs.pzSolved.contains(s.myId)) return _waitOverlay();
    final p = puzzleFor(gs.mission, gs.pz, s.myId);
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
                  painter: GamePainter(gs, t, sm, mobSm, fx, target, targetAge, s.myId, wm, bigSm ?? Offset(gs.big.x, gs.big.y), bigA),
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
                  if (phase != 'map') Chip2(child: Text('${c.flag} Level ${gs.mission + 1}/${countries.length}')),
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
                            opacity: gs.has(s.myId, tl) ? 1 : 0.22,
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

            // tim: siapa sudah punya alat apa (di pulau, saat mabar)
            if (showTools && gs.ids.length > 1)
              Positioned(top: 58, right: 10, child: SafeArea(child: IgnorePointer(child: _teamPanel()))),

            // kemudi kapal besar
            if (gs.bigMode && (phase == 'sail' || phase == 'island') && !gs.big.stuck)
              Positioned(right: 14, bottom: 14, child: SafeArea(child: _steering())),

            // bawah kiri: burung beo pemandu
            if (phase != 'map')
              Positioned(
                left: 10,
                bottom: 10,
                child: SafeArea(
                  child: GestureDetector(
                    onTap: () {
                      Voice.say(_hint(speak: true));
                      setState(() => _hintT = 5);
                    },
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Transform.translate(
                        offset: Offset(0, sin(t * 3) * 4),
                        child: const Text('🦜', style: TextStyle(fontSize: 44)),
                      ),
                      if (_hintT > 0)
                      Opacity(
                        opacity: _hintT.clamp(0.0, 1.0),
                        child: Container(
                        constraints: BoxConstraints(maxWidth: _size.width * 0.3),
                        margin: const EdgeInsets.only(bottom: 20, left: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF8D6E3F), width: 3),
                          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))],
                        ),
                        child: Text(_lastHint,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF3E2410))),
                      ),
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

            // mini game olahraga khas
            if (_sportOpen && phase == 'land')
              SportGame(
                mission: gs.mission,
                hero: heroes[gs.heroOf(s.myId) % heroes.length],
                playerName: gs.nameOf(s.myId),
                onWin: () {
                  s.sportWon();
                  setState(() {
                    _sportOpen = false;
                    _sportBlocked = true;
                  });
                },
                onClose: () => setState(() {
                  _sportOpen = false;
                  _sportBlocked = true;
                }),
              ),

            // hadiah kapal besar
            if (phase == 'treasure' && gs.mission == bigShipFrom - 1 && gs.phaseT > 3)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: const Color(0x77000000),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const OutlinedTitle('🎁 HADIAH: KAPAL BESAR!', size: 38),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 360,
                        height: 200,
                        child: CustomPaint(
                          painter: _FnPainter((c, sz) => drawBigShip(c, sz.width / 2, sz.height * 0.8, 0, t,
                              [for (final id in gs.ids) gs.heroOf(id)], [for (final _ in gs.ids) 1],
                              arrow: false, scale: 0.75)),
                        ),
                      ),
                      const OutlinedTitle('Mulai level 11, semua naik satu kapal.\nKemudikan bersama-sama: kiri, gas, kanan!',
                          size: 18, color: Colors.white),
                    ]),
                  ),
                ),
              ),

            // spanduk harta ditemukan
            if (phase == 'treasure' && !(gs.mission == bigShipFrom - 1 && gs.phaseT > 3))
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
                      const OutlinedTitle('30 negara sudah dikunjungi 🌍', size: 20, color: Colors.white),
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
