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

  /// One of [tasks].
  final String task;
  String providerId;
  String model;
  String fallbackProviderId;
  String fallbackModel;

  static const tasks = ['chat', 'translate', 'simplify', 'memes', 'word', 'check', 'judge', 'practice', 'story', 'grammar', 'memory', 'image'];

  /// What each task does (shown in the admin panel).
  static const descriptions = {
    'chat': 'Tutor conversation & role-plays',
    'translate': 'Translator',
    'simplify': 'News at the learner level',
    'memes': 'Daily culture memes',
    'word': 'Word coach: mnemonics, examples',
    'check': 'Writing correction',
    'judge': 'Second opinion on typed answers',
    'practice': 'Personalised gap-fills',
    'story': 'Graded reader stories',
    'grammar': 'Grammar explanations',
    'memory': 'Memory consolidation (backend only)',
    'image': 'Picture-card images (OpenAI-compatible images API)',
  };

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

/// An alternative teaching-style instruction. The server picks one per chat
/// reply with Thompson sampling over 👍/👎 feedback (see PromptBandit).
class PromptVariant {
  PromptVariant({required this.id, required this.text, this.task = 'chat', this.enabled = true});
  final String id;
  String task;
  String text;
  bool enabled;

  Map<String, dynamic> toJson() => {'id': id, 'task': task, 'text': text, 'enabled': enabled};
  static PromptVariant fromJson(Map<String, dynamic> j) =>
      PromptVariant(id: j['id'] as String, task: (j['task'] ?? 'chat') as String, text: (j['text'] ?? '') as String, enabled: (j['enabled'] ?? true) as bool);
}

class ServerConfig {
  ServerConfig({
    List<AiProvider>? providers,
    List<AiRoute>? routes,
    List<FeedSource>? feeds,
    List<PromptVariant>? variants,
    this.maxTokens = 900,
    this.imagesEnabled = false,
    this.rateLimitPerMinute = 20,
    this.globalAiPerMinute = 120,
    this.dailyAiLimit = 5000,
    this.extraSystemPrompt = '',
  })  : providers = providers ?? [],
        routes = routes ?? [],
        feeds = feeds ?? [],
        variants = variants ?? [] {
    for (final t in AiRoute.tasks) {
      if (!this.routes.any((r) => r.task == t)) this.routes.add(AiRoute(task: t));
    }
  }

  final List<AiProvider> providers;
  final List<AiRoute> routes;
  final List<FeedSource> feeds;
  final List<PromptVariant> variants;
  int maxTokens;

  /// Generate AI pictures for word cards (costly; results are cached and shared).
  bool imagesEnabled;
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
          for (final t in ['chat', 'memes', 'check', 'story', 'memory']) AiRoute(task: t, providerId: 'anthropic', model: 'claude-sonnet-5-5'),
          for (final t in ['translate', 'simplify', 'word', 'judge', 'practice', 'grammar']) AiRoute(task: t, providerId: 'anthropic', model: 'claude-haiku-5-5'),
          AiRoute(task: 'image', providerId: 'openai', model: 'gpt-image-1'),
        ],
        variants: [
          PromptVariant(id: 'balanced', text: 'Balance correction and conversation; keep it light and encouraging.'),
          PromptVariant(id: 'curious', text: 'Ask one genuinely curious follow-up question about the learner\'s life each time; correct only the most important mistake.'),
          PromptVariant(id: 'storyteller', text: 'Use tiny anecdotes from your own (mascot) life in Germany to model the language, then invite the learner to share theirs.'),
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
        'variants': variants.map((v) => v.toJson()).toList(),
        'maxTokens': maxTokens,
        'imagesEnabled': imagesEnabled,
        'rateLimitPerMinute': rateLimitPerMinute,
        'globalAiPerMinute': globalAiPerMinute,
        'dailyAiLimit': dailyAiLimit,
        'extraSystemPrompt': extraSystemPrompt,
      };

  static ServerConfig fromJson(Map<String, dynamic> j) {
    final c = ServerConfig(
        providers: [for (final p in (j['providers'] as List? ?? [])) AiProvider.fromJson(Map<String, dynamic>.from(p as Map))],
        routes: [for (final r in (j['routes'] as List? ?? [])) AiRoute.fromJson(Map<String, dynamic>.from(r as Map))],
        feeds: [for (final f in (j['feeds'] as List? ?? [])) FeedSource.fromJson(Map<String, dynamic>.from(f as Map))],
        variants: j['variants'] is List
            ? [for (final v in j['variants'] as List) PromptVariant.fromJson(Map<String, dynamic>.from(v as Map))]
            : ServerConfig.defaults().variants,
        maxTokens: (j['maxTokens'] ?? 900) as int,
        imagesEnabled: (j['imagesEnabled'] ?? false) as bool,
        rateLimitPerMinute: (j['rateLimitPerMinute'] ?? 20) as int,
        globalAiPerMinute: (j['globalAiPerMinute'] ?? 120) as int,
        dailyAiLimit: (j['dailyAiLimit'] ?? 5000) as int,
        extraSystemPrompt: (j['extraSystemPrompt'] ?? '') as String,
      );
    // Configs saved by older versions lack routes for newer tasks: let those
    // tasks use the chat model so a server upgrade keeps working.
    final saved = {for (final r in (j['routes'] as List? ?? [])) (r as Map)['task']};
    final chat = c.route('chat');
    for (final r in c.routes) {
      if (!saved.contains(r.task) && r.task != 'image' && r.providerId.isEmpty) {
        r
          ..providerId = chat.providerId
          ..model = chat.model;
      }
    }
    return c;
  }

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
    if (j['variants'] is List) {
      variants
        ..clear()
        ..addAll([
          for (final v in j['variants'] as List)
            if (v is Map && '${v['id'] ?? ''}'.trim().isNotEmpty) PromptVariant.fromJson(Map<String, dynamic>.from(v))
        ]);
    }
    if (j['imagesEnabled'] is bool) imagesEnabled = j['imagesEnabled'] as bool;
    if (j['maxTokens'] is int) maxTokens = (j['maxTokens'] as int).clamp(64, 8000);
    if (j['rateLimitPerMinute'] is int) rateLimitPerMinute = (j['rateLimitPerMinute'] as int).clamp(1, 600);
    if (j['globalAiPerMinute'] is int) globalAiPerMinute = (j['globalAiPerMinute'] as int).clamp(1, 100000);
    if (j['dailyAiLimit'] is int) dailyAiLimit = (j['dailyAiLimit'] as int).clamp(1, 10000000);
    if (j['extraSystemPrompt'] is String) extraSystemPrompt = j['extraSystemPrompt'] as String;
  }
}
