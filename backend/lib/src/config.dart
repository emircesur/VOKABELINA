// Server-side configuration edited from the admin panel.
// API keys live only here (never shipped in the mobile app).

class AiProvider {
  AiProvider({
    required this.id,
    required this.name,
    required this.kind,
    this.baseUrl = '',
    this.apiKey = '',
    this.enabled = true,
  });

  /// Stable id referenced by [AiRoute].
  final String id;
  String name;

  /// 'anthropic' | 'openai' (any OpenAI-compatible API) | 'gemini'
  String kind;
  String baseUrl;
  String apiKey;
  bool enabled;

  static const kinds = ['anthropic', 'openai', 'gemini'];

  String get effectiveBaseUrl {
    if (baseUrl.trim().isNotEmpty) return baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    switch (kind) {
      case 'anthropic':
        return 'https://api.anthropic.com';
      case 'gemini':
        return 'https://generativelanguage.googleapis.com';
      default:
        return 'https://api.openai.com/v1';
    }
  }

  Map<String, dynamic> toJson({bool maskKey = false}) => {
        'id': id,
        'name': name,
        'kind': kind,
        'baseUrl': baseUrl,
        'apiKey': maskKey ? maskSecret(apiKey) : apiKey,
        'hasKey': apiKey.isNotEmpty,
        'enabled': enabled,
      };

  static AiProvider fromJson(Map<String, dynamic> j) => AiProvider(
        id: j['id'] as String,
        name: (j['name'] ?? j['id']) as String,
        kind: (j['kind'] ?? 'openai') as String,
        baseUrl: (j['baseUrl'] ?? '') as String,
        apiKey: (j['apiKey'] ?? '') as String,
        enabled: (j['enabled'] ?? true) as bool,
      );
}

String maskSecret(String s) {
  if (s.isEmpty) return '';
  if (s.length <= 8) return '••••';
  return '${s.substring(0, 3)}••••${s.substring(s.length - 4)}';
}

/// Which provider + model handles a task, with an optional fallback.
class AiRoute {
  AiRoute({
    required this.task,
    this.providerId = '',
    this.model = '',
    this.fallbackProviderId = '',
    this.fallbackModel = '',
  });

  /// 'chat' | 'translate' | 'simplify' | 'memes'
  final String task;
  String providerId;
  String model;
  String fallbackProviderId;
  String fallbackModel;

  static const tasks = ['chat', 'translate', 'simplify', 'memes'];

  Map<String, dynamic> toJson() => {
        'task': task,
        'providerId': providerId,
        'model': model,
        'fallbackProviderId': fallbackProviderId,
        'fallbackModel': fallbackModel,
      };

  static AiRoute fromJson(Map<String, dynamic> j) => AiRoute(
        task: j['task'] as String,
        providerId: (j['providerId'] ?? '') as String,
        model: (j['model'] ?? '') as String,
        fallbackProviderId: (j['fallbackProviderId'] ?? '') as String,
        fallbackModel: (j['fallbackModel'] ?? '') as String,
      );
}

class FeedSource {
  FeedSource({required this.name, required this.url, this.enabled = true});
  String name;
  String url;
  bool enabled;

  Map<String, dynamic> toJson() => {'name': name, 'url': url, 'enabled': enabled};
  static FeedSource fromJson(Map<String, dynamic> j) => FeedSource(
        name: j['name'] as String,
        url: j['url'] as String,
        enabled: (j['enabled'] ?? true) as bool,
      );
}

class ServerConfig {
  ServerConfig({
    List<AiProvider>? providers,
    List<AiRoute>? routes,
    List<FeedSource>? feeds,
    this.maxTokens = 900,
    this.rateLimitPerMinute = 20,
    this.globalAiPerMinute = 120,
    this.dailyAiLimit = 5000,
    this.extraSystemPrompt = '',
  })  : providers = providers ?? [],
        routes = routes ?? [],
        feeds = feeds ?? [] {
    for (final t in AiRoute.tasks) {
      if (!this.routes.any((r) => r.task == t)) this.routes.add(AiRoute(task: t));
    }
  }

  final List<AiProvider> providers;
  final List<AiRoute> routes;
  final List<FeedSource> feeds;
  int maxTokens;
  int rateLimitPerMinute;

  /// Cost guards across all devices, so minting device ids cannot drain the API keys.
  int globalAiPerMinute;
  int dailyAiLimit;

  /// Appended to every system prompt (global tone / safety rules).
  String extraSystemPrompt;

  AiProvider? provider(String id) {
    for (final p in providers) {
      if (p.id == id) return p;
    }
    return null;
  }

  AiRoute route(String task) => routes.firstWhere((r) => r.task == task);

  factory ServerConfig.defaults() => ServerConfig(
        providers: [
          AiProvider(id: 'anthropic', name: 'Anthropic', kind: 'anthropic'),
          AiProvider(id: 'openai', name: 'OpenAI', kind: 'openai'),
          AiProvider(id: 'gemini', name: 'Google Gemini', kind: 'gemini'),
          AiProvider(
              id: 'openrouter',
              name: 'OpenRouter',
              kind: 'openai',
              baseUrl: 'https://openrouter.ai/api/v1',
              enabled: false),
        ],
        routes: [
          AiRoute(task: 'chat', providerId: 'anthropic', model: 'claude-sonnet-5-5'),
          AiRoute(task: 'translate', providerId: 'anthropic', model: 'claude-haiku-5-5'),
          AiRoute(task: 'simplify', providerId: 'anthropic', model: 'claude-haiku-5-5'),
          AiRoute(task: 'memes', providerId: 'anthropic', model: 'claude-sonnet-5-5'),
        ],
        feeds: [
          FeedSource(name: 'Tagesschau', url: 'https://www.tagesschau.de/index~rss2.xml'),
          FeedSource(name: 'Deutsche Welle', url: 'https://rss.dw.com/xml/rss-de-top'),
        ],
      );

  Map<String, dynamic> toJson({bool maskKeys = false}) => {
        'providers': providers.map((p) => p.toJson(maskKey: maskKeys)).toList(),
        'routes': routes.map((r) => r.toJson()).toList(),
        'feeds': feeds.map((f) => f.toJson()).toList(),
        'maxTokens': maxTokens,
        'rateLimitPerMinute': rateLimitPerMinute,
        'globalAiPerMinute': globalAiPerMinute,
        'dailyAiLimit': dailyAiLimit,
        'extraSystemPrompt': extraSystemPrompt,
      };

  static ServerConfig fromJson(Map<String, dynamic> j) => ServerConfig(
        providers: [for (final p in (j['providers'] as List? ?? [])) AiProvider.fromJson(Map<String, dynamic>.from(p as Map))],
        routes: [for (final r in (j['routes'] as List? ?? [])) AiRoute.fromJson(Map<String, dynamic>.from(r as Map))],
        feeds: [for (final f in (j['feeds'] as List? ?? [])) FeedSource.fromJson(Map<String, dynamic>.from(f as Map))],
        maxTokens: (j['maxTokens'] ?? 900) as int,
        rateLimitPerMinute: (j['rateLimitPerMinute'] ?? 20) as int,
        globalAiPerMinute: (j['globalAiPerMinute'] ?? 120) as int,
        dailyAiLimit: (j['dailyAiLimit'] ?? 5000) as int,
        extraSystemPrompt: (j['extraSystemPrompt'] ?? '') as String,
      );

  /// Applies an admin-panel update. A blank / masked `apiKey` keeps the stored key.
  void applyAdminUpdate(Map<String, dynamic> j) {
    if (j['providers'] is List) {
      final old = {for (final p in providers) p.id: p};
      final next = <AiProvider>[];
      for (final raw in j['providers'] as List) {
        final m = Map<String, dynamic>.from(raw as Map);
        final p = AiProvider.fromJson(m);
        final key = (m['apiKey'] ?? '') as String;
        final prev = old[p.id];
        if (prev != null && (key.isEmpty || key.contains('••••'))) p.apiKey = prev.apiKey;
        next.add(p);
      }
      providers
        ..clear()
        ..addAll(next);
    }
    if (j['routes'] is List) {
      routes
        ..clear()
        ..addAll([for (final r in j['routes'] as List) AiRoute.fromJson(Map<String, dynamic>.from(r as Map))]);
      for (final t in AiRoute.tasks) {
        if (!routes.any((r) => r.task == t)) routes.add(AiRoute(task: t));
      }
    }
    if (j['feeds'] is List) {
      feeds
        ..clear()
        ..addAll([for (final f in j['feeds'] as List) FeedSource.fromJson(Map<String, dynamic>.from(f as Map))]);
    }
    if (j['maxTokens'] is int) maxTokens = (j['maxTokens'] as int).clamp(64, 8000);
    if (j['rateLimitPerMinute'] is int) rateLimitPerMinute = (j['rateLimitPerMinute'] as int).clamp(1, 600);
    if (j['globalAiPerMinute'] is int) globalAiPerMinute = (j['globalAiPerMinute'] as int).clamp(1, 100000);
    if (j['dailyAiLimit'] is int) dailyAiLimit = (j['dailyAiLimit'] as int).clamp(1, 10000000);
    if (j['extraSystemPrompt'] is String) extraSystemPrompt = j['extraSystemPrompt'] as String;
  }
}
