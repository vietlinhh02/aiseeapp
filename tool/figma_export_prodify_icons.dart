// Xuất SVG từ Figma file Prodify — node Icon Family (381:3605), danh sách trong prodify_icon_nodes.txt
//
// Chạy từ thư mục gốc repo:
//   FIGMA_ACCESS_TOKEN=figd_xxx dart run tool/figma_export_prodify_icons.dart
//
// Token: https://www.figma.com/developers/api#access-tokens

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const String _fileKey = 'Z2puEDKMPEUvfZPRFw4NK7';

Future<void> main() async {
  final token = (Platform.environment['FIGMA_ACCESS_TOKEN'] ??
          Platform.environment['FIGMA_TOKEN'] ??
          '')
      .trim();
  if (token.isEmpty) {
    stderr.writeln(
      'Thiếu FIGMA_ACCESS_TOKEN (hoặc FIGMA_TOKEN) trong môi trường.',
    );
    stderr.writeln(
      'Tạo Personal Access Token: https://www.figma.com/developers/api#access-tokens',
    );
    exitCode = 1;
    return;
  }

  final scriptDir = File(Platform.script.toFilePath()).parent;
  final listFile = File('${scriptDir.path}/prodify_icon_nodes.txt');
  if (!listFile.existsSync()) {
    stderr.writeln('Không thấy ${listFile.path}');
    exitCode = 1;
    return;
  }

  final entries = <_Entry>[];
  for (final line in listFile.readAsLinesSync()) {
    final t = line.trim();
    if (t.isEmpty || t.startsWith('#')) continue;
    final tab = t.indexOf('\t');
    if (tab < 0) continue;
    final id = t.substring(0, tab).trim();
    final name = t.substring(tab + 1).trim();
    entries.add(_Entry(id, name));
  }

  final outDir = Directory('${scriptDir.parent.path}/assets/icons/nav');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final ids = entries.map((e) => e.id).toList();
  final urlMap = <String, String>{};

  const batchSize = 75;
  for (var i = 0; i < ids.length; i += batchSize) {
    final batch = ids.sublist(i, i + batchSize > ids.length ? ids.length : i + batchSize);
    final chunk = await _requestImageUrls(token, batch);
    urlMap.addAll(chunk);
  }

  final usedNames = <String>{};

  for (final e in entries) {
    final url = urlMap[e.id];
    if (url == null || url.isEmpty) {
      stderr.writeln('Bỏ qua (API không trả URL): ${e.id} ${e.name}');
      continue;
    }

    var baseName = _slugFileName(e.name);
    if (usedNames.contains(baseName)) {
      baseName =
          'ic_${_slugBody(e.name)}_${e.id.replaceAll(':', '_')}.svg';
    }
    usedNames.add(baseName);

    final file = File('${outDir.path}/$baseName');
    try {
      await _download(url, file);
      print('OK $baseName');
    } catch (err) {
      stderr.writeln('Lỗi tải $baseName: $err');
    }
  }

  print('Xong. Thư mục: ${outDir.path}');
}

Future<void> _writeResponseToFile(HttpClientResponse res, File out) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in res) {
    builder.add(chunk);
  }
  await out.writeAsBytes(builder.takeBytes());
}

class _Entry {
  _Entry(this.id, this.name);
  final String id;
  final String name;
}

String _slugBody(String raw) {
  var s = raw.trim();
  if (s.startsWith('Property 2=')) {
    s = s.substring('Property 2='.length).trim();
  }
  s = s.toLowerCase();
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  s = s.replaceAll(RegExp(r'_+'), '_');
  s = s.replaceAll(RegExp(r'^_|_$'), '');
  return s.isEmpty ? 'icon' : s;
}

String _slugFileName(String raw) => 'ic_${_slugBody(raw)}.svg';

Future<Map<String, String>> _requestImageUrls(
  String token,
  List<String> nodeIds,
) async {
  final uri = Uri.https(
    'api.figma.com',
    '/v1/images/$_fileKey',
    <String, String>{
      'ids': nodeIds.join(','),
      'format': 'svg',
    },
  );

  final client = HttpClient();
  try {
    final req = await client.getUrl(uri);
    req.headers.set('X-Figma-Token', token);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) {
      throw HttpException('HTTP ${res.statusCode}: $body', uri: uri);
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json['err'] != null) {
      throw StateError('Figma API err: ${json['err']}');
    }
    final images = json['images'] as Map<String, dynamic>? ?? {};
    return images.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  } finally {
    client.close(force: true);
  }
}

Future<void> _download(String url, File out) async {
  final uri = Uri.parse(url);
  final client = HttpClient();
  try {
    final req = await client.getUrl(uri);
    final res = await req.close();
    if (res.statusCode != 200) {
      throw HttpException('HTTP ${res.statusCode}', uri: uri);
    }
    await _writeResponseToFile(res, out);
  } finally {
    client.close(force: true);
  }
}
