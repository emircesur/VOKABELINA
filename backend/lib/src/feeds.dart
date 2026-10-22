import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'config.dart';

class NewsItem {
  NewsItem({required this.id, required this.source, required this.title, required this.summary, required this.link, this.published, this.image});
  final String id;
  final String source;
  final String title;
  final String summary;
  final String link;
  final DateTime? published;
  final String? image;

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'title': title,
        'summary': summary,
        'link': link,
        'published': published?.toUtc().toIso8601String(),
        'image': image,
      };
}

String stripHtml(String s) => s
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Parses RSS 2.0 (and basic Atom) into [NewsItem]s.
List<NewsItem> parseFeed(String xml, String source, {int limit = 15}) {
  final doc = XmlDocument.parse(xml);
  final items = [...doc.findAllElements('item'), ...doc.findAllElements('entry')];
  final out = <NewsItem>[];
  for (final it in items) {
    String text(String name) => it.getElement(name)?.innerText.trim() ?? '';
    final title = stripHtml(text('title'));
    if (title.isEmpty) continue;
    var link = text('link');
    if (link.isEmpty) link = it.getElement('link')?.getAttribute('href') ?? '';
    final summary = stripHtml(text('description').isNotEmpty ? text('description') : text('summary'));
    final dateStr = text('pubDate').isNotEmpty ? text('pubDate') : text('updated');
    final image = it.findAllElements('enclosure').map((e) => e.getAttribute('url')).whereType<String>().firstOrNull ??
        it.findAllElements('content', namespace: '*').map((e) => e.getAttribute('url')).whereType<String>().firstOrNull;
    out.add(NewsItem(
      id: sha1.convert(utf8.encode('$source|$link|$title')).toString().substring(0, 12),
      source: source,
      title: title,
      summary: summary,
      link: link,
      published: _parseDate(dateStr),
      image: image,
    ));
    if (out.length >= limit) break;
  }
  return out;
}

DateTime? _parseDate(String s) {
  if (s.isEmpty) return null;
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso;
  // RFC 822: "Wed, 22 Oct 2026 10:00:00 +0200"
  final m = RegExp(r'(\d{1,2}) (\w{3}) (\d{4}) (\d\d):(\d\d)(?::(\d\d))?\s*([+-]\d{4}|GMT|UTC|Z)?').firstMatch(s);
  if (m == null) return null;
  const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
  final mo = months.indexOf(m.group(2)!.toLowerCase()) + 1;
  if (mo == 0) return null;
  var dt = DateTime.utc(int.parse(m.group(3)!), mo, int.parse(m.group(1)!), int.parse(m.group(4)!), int.parse(m.group(5)!), int.parse(m.group(6) ?? '0'));
  final tz = m.group(7);
  if (tz != null && RegExp(r'^[+-]\d{4}$').hasMatch(tz)) {
    final sign = tz.startsWith('-') ? -1 : 1;
    dt = dt.subtract(Duration(hours: sign * int.parse(tz.substring(1, 3)), minutes: sign * int.parse(tz.substring(3, 5))));
  }
  return dt;
}

class FeedService {
  FeedService(this._http, this._sources, {this.ttl = const Duration(minutes: 30)});
  final http.Client _http;
  final List<FeedSource> Function() _sources;
  final Duration ttl;
  List<NewsItem> _cache = [];
  DateTime? _fetchedAt;

  Future<List<NewsItem>> news({bool force = false}) async {
    final fresh = _fetchedAt != null && DateTime.now().difference(_fetchedAt!) < ttl;
    if (fresh && !force && _cache.isNotEmpty) return _cache;
    final all = <NewsItem>[];
    await Future.wait([
      for (final s in _sources().where((s) => s.enabled))
        () async {
          try {
            final res = await _http.get(Uri.parse(s.url), headers: {'user-agent': 'Vokabelina/0.1'}).timeout(const Duration(seconds: 15));
            if (res.statusCode == 200) all.addAll(parseFeed(utf8.decode(res.bodyBytes), s.name));
          } catch (_) {
            // One broken source must not take the feed down.
          }
        }(),
    ]);
    if (all.isNotEmpty) {
      all.sort((a, b) => (b.published ?? DateTime(0)).compareTo(a.published ?? DateTime(0)));
      _cache = all;
      _fetchedAt = DateTime.now();
    }
    return _cache;
  }

  NewsItem? byId(String id) {
    for (final n in _cache) {
      if (n.id == id) return n;
    }
    return null;
  }
}
