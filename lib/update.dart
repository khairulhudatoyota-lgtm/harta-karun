part of 'main.dart';

// =====================================================================
//  UPDATE OTOMATIS dari GitHub Releases
// =====================================================================
class UpdateInfo {
  final int build;
  final String url;
  UpdateInfo(this.build, this.url);
}

class Updater {
  static const MethodChannel _ch = MethodChannel('harta/update');

  /// Cek versi terbaru. null = tidak ada update / sedang offline.
  static Future<UpdateInfo?> check() async {
    if (appBuild <= 0) return null;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final req = await client
          .getUrl(Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest'))
          .timeout(const Duration(seconds: 8));
      req.headers.set('Accept', 'application/vnd.github+json');
      req.headers.set('User-Agent', 'harta-karun-app');
      final res = await req.close().timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 10));
      final j = jsonDecode(body) as Map<String, dynamic>;
      final tag = '${j['tag_name'] ?? ''}';
      final build = int.tryParse(tag.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (build <= appBuild) return null;
      for (final a in (j['assets'] as List? ?? const [])) {
        final m = a as Map<String, dynamic>;
        final name = '${m['name']}';
        if (name.endsWith('.apk')) return UpdateInfo(build, '${m['browser_download_url']}');
      }
    } catch (_) {
    } finally {
      client.close(force: true);
    }
    return null;
  }

  /// Download APK lalu buka layar instal Android.
  static Future<String> downloadAndInstall(UpdateInfo info, void Function(double p) onProgress) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(Uri.parse(info.url));
      req.headers.set('User-Agent', 'harta-karun-app');
      final res = await req.close();
      if (res.statusCode != 200) return 'Gagal download (kode ${res.statusCode})';
      final total = res.contentLength;
      final file = File('${Directory.systemTemp.path}/harta-karun-${info.build}.apk');
      final sink = file.openWrite();
      int got = 0;
      await for (final chunk in res) {
        sink.add(chunk);
        got += chunk.length;
        if (total > 0) onProgress(got / total);
      }
      await sink.close();
      final r = await _ch.invokeMethod<String>('install', {'path': file.path});
      return r ?? 'ok';
    } catch (e) {
      return 'Gagal: $e';
    } finally {
      client.close(force: true);
    }
  }
}

class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const UpdateDialog({super.key, required this.info});
  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double progress = 0;
  bool busy = false;
  String msg = '';

  Future<void> _go() async {
    setState(() {
      busy = true;
      msg = 'Mengunduh...';
    });
    final r = await Updater.downloadAndInstall(widget.info, (p) {
      if (mounted) setState(() => progress = p);
    });
    if (!mounted) return;
    setState(() {
      busy = false;
      if (r == 'ok') {
        msg = 'Ketuk "Instal" di layar Android yang muncul.';
      } else if (r == 'perm') {
        msg = 'Izinkan "Instal aplikasi tidak dikenal" untuk Harta Karun, lalu kembali dan ketuk Update lagi.';
      } else {
        msg = r;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🎁 Ada versi baru!'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Versi ${widget.info.build} siap dipasang. Progres permainan tetap tersimpan.'),
        const SizedBox(height: 12),
        if (busy) LinearProgressIndicator(value: progress > 0 ? progress : null),
        if (msg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(msg)),
      ]),
      actions: [
        TextButton(onPressed: busy ? null : () => Navigator.of(context).pop(), child: const Text('Nanti')),
        FilledButton(onPressed: busy ? null : _go, child: const Text('Update')),
      ],
    );
  }
}
