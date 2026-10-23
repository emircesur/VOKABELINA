import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ChatTurn {
  const ChatTurn(this.role, this.content);

  /// 'user' | 'assistant'
  final String role;
  final String content;
}

class AiException implements Exception {
  AiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => 'AiException($status): $message';
}

class AiResult {
  const AiResult(this.text, {this.inputTokens = 0, this.outputTokens = 0});
  final String text;
  final int inputTokens;
  final int outputTokens;
}

/// Talks to Anthropic, OpenAI-compatible and Gemini APIs.
class AiClient {
  AiClient(this._http);
  final http.Client _http;

  Future<AiResult> complete(
    AiProvider p,
    String model, {
    required String system,
    required List<ChatTurn> messages,
    int maxTokens = 800,
    bool json = false,
    double temperature = 0.7,
  }) async {
    if (p.apiKey.isEmpty) throw AiException('Provider "${p.id}" has no API key');
    if (model.isEmpty) throw AiException('No model set for provider "${p.id}"');
    switch (p.kind) {
      case 'anthropic':
        return _anthropic(p, model, system, messages, maxTokens, temperature);
      case 'gemini':
        return _gemini(p, model, system, messages, maxTokens, json, temperature);
      case 'openai':
        return _openai(p, model, system, messages, maxTokens, json, temperature);
      default:
        throw AiException('Unknown provider kind "${p.kind}"');
    }
  }

  Future<Map<String, dynamic>> _post(Uri url, Map<String, String> headers, Object body, {Duration timeout = const Duration(seconds: 60)}) async {
    final res = await _http.post(url, headers: {'content-type': 'application/json', ...headers}, body: jsonEncode(body)).timeout(timeout);
    final text = utf8.decode(res.bodyBytes);
    if (res.statusCode >= 300) {
      throw AiException(text.length > 300 ? text.substring(0, 300) : text, status: res.statusCode);
    }
    return jsonDecode(text) as Map<String, dynamic>;
  }

  static int _int(Object? v) => v is num ? v.toInt() : 0;

  Future<AiResult> _anthropic(AiProvider p, String model, String system, List<ChatTurn> msgs, int maxTokens, double temp) async {
    final data = await _post(
      Uri.parse('${p.effectiveBaseUrl}/v1/messages'),
      {'x-api-key': p.apiKey, 'anthropic-version': '2023-06-01'},
      {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temp,
        'system': system,
        'messages': [
          for (final m in msgs) {'role': m.role, 'content': m.content}
        ],
      },
    );
    final parts = (data['content'] as List?) ?? const [];
    final text = parts.where((c) => c is Map && c['type'] == 'text').map((c) => c['text']).join();
    if (text.isEmpty) throw AiException('Empty response from Anthropic');
    final u = data['usage'] as Map? ?? const {};
    return AiResult(text, inputTokens: _int(u['input_tokens']), outputTokens: _int(u['output_tokens']));
  }

  Future<AiResult> _openai(AiProvider p, String model, String system, List<ChatTurn> msgs, int maxTokens, bool json, double temp) async {
    final data = await _post(
      Uri.parse('${p.effectiveBaseUrl}/chat/completions'),
      {'authorization': 'Bearer ${p.apiKey}'},
      {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temp,
        'messages': [
          {'role': 'system', 'content': system},
          for (final m in msgs) {'role': m.role, 'content': m.content}
        ],
      },
    );
    final choices = (data['choices'] as List?) ?? const [];
    final text = choices.isEmpty ? '' : ((choices.first as Map)['message'] as Map?)?['content'] as String? ?? '';
    if (text.isEmpty) throw AiException('Empty response from OpenAI-compatible API');
    final u = data['usage'] as Map? ?? const {};
    return AiResult(text, inputTokens: _int(u['prompt_tokens']), outputTokens: _int(u['completion_tokens']));
  }

  Future<AiResult> _gemini(AiProvider p, String model, String system, List<ChatTurn> msgs, int maxTokens, bool json, double temp) async {
    final data = await _post(
      Uri.parse('${p.effectiveBaseUrl}/v1beta/models/$model:generateContent'),
      {'x-goog-api-key': p.apiKey},
      {
        'systemInstruction': {
          'parts': [
            {'text': system}
          ]
        },
        'contents': [
          for (final m in msgs)
            {
              'role': m.role == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': m.content}
              ]
            }
        ],
        'generationConfig': {
          'maxOutputTokens': maxTokens,
          'temperature': temp,
          if (json) 'responseMimeType': 'application/json',
        },
      },
    );
    final cands = (data['candidates'] as List?) ?? const [];
    final parts = cands.isEmpty ? const [] : (((cands.first as Map)['content'] as Map?)?['parts'] as List? ?? const []);
    final text = parts.map((x) => (x as Map)['text'] ?? '').join();
    if (text.isEmpty) throw AiException('Empty response from Gemini');
    final u = data['usageMetadata'] as Map? ?? const {};
    return AiResult(text, inputTokens: _int(u['promptTokenCount']), outputTokens: _int(u['candidatesTokenCount']));
  }

  /// Image generation via an OpenAI-compatible `/images/generations` endpoint. Returns PNG bytes.
  Future<List<int>> image(AiProvider p, String model, String prompt) async {
    if (p.kind != 'openai') throw AiException('Image generation needs an OpenAI-compatible provider');
    if (p.apiKey.isEmpty) throw AiException('Provider "${p.id}" has no API key');
    final data = await _post(
      Uri.parse('${p.effectiveBaseUrl}/images/generations'),
      {'authorization': 'Bearer ${p.apiKey}'},
      {'model': model, 'prompt': prompt, 'size': '1024x1024', 'n': 1},
      timeout: const Duration(seconds: 120),
    );
    final list = (data['data'] as List?) ?? const [];
    final b64 = list.isEmpty ? null : (list.first as Map)['b64_json'] as String?;
    if (b64 != null) return base64Decode(b64);
    final url = list.isEmpty ? null : (list.first as Map)['url'] as String?;
    if (url == null) throw AiException('No image returned');
    final res = await _http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) throw AiException('Image download failed', status: res.statusCode);
    return res.bodyBytes;
  }
}

typedef UsageSink = void Function(String providerId, String model, String task, int inputTokens, int outputTokens);

/// Resolves a task to provider(+fallback) according to the admin-edited config.
class AiRouter {
  AiRouter(this.config, this.client, {this.onUsage});
  final ServerConfig Function() config;
  final AiClient client;
  final UsageSink? onUsage;

  bool get hasAnyProvider => config().providers.any((p) => p.enabled && p.apiKey.isNotEmpty);

  /// Returns the raw model text and the `provider/model` that produced it.
  Future<({String text, String used})> run(
    String task, {
    required String system,
    required List<ChatTurn> messages,
    bool json = false,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    final cfg = config();
    final route = cfg.route(task);
    final attempts = <(String, String)>[
      (route.providerId, route.model),
      if (route.fallbackProviderId.isNotEmpty) (route.fallbackProviderId, route.fallbackModel),
    ];
    final fullSystem = cfg.extraSystemPrompt.trim().isEmpty ? system : '$system\n\n${cfg.extraSystemPrompt.trim()}';
    Object? lastError;
    for (final (pid, model) in attempts) {
      final p = cfg.provider(pid);
      if (p == null || !p.enabled || p.apiKey.isEmpty) {
        lastError = AiException('Provider "$pid" is not configured for "$task"');
        continue;
      }
      try {
        final r = await client.complete(p, model,
            system: fullSystem, messages: messages, maxTokens: maxTokens ?? cfg.maxTokens, json: json, temperature: temperature);
        onUsage?.call(p.id, model, task, r.inputTokens, r.outputTokens);
        return (text: r.text, used: '${p.id}/$model');
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? AiException('No provider configured for "$task"');
  }

  /// Runs a task that must return a JSON object. If the model breaks the
  /// contract, asks once more to repair its own output (cheap, low temperature).
  Future<({Map<String, dynamic> json, String used})> runJson(
    String task, {
    required String system,
    required List<ChatTurn> messages,
    double temperature = 0.5,
    int? maxTokens,
    bool Function(Map<String, dynamic>)? valid,
  }) async {
    final first = await run(task, system: system, messages: messages, json: true, temperature: temperature, maxTokens: maxTokens);
    final parsed = extractJsonObject(first.text);
    if (parsed != null && (valid == null || valid(parsed))) return (json: parsed, used: first.used);
    final repaired = await run(task,
        system: '$system\n\nIMPORTANT: Output ONLY one valid JSON object that follows the schema above. No prose, no code fences.',
        messages: [
          ...messages,
          ChatTurn('assistant', first.text.length > 4000 ? first.text.substring(0, 4000) : first.text),
          const ChatTurn('user', 'That was not valid JSON for the required schema. Reply again with only the JSON object.'),
        ],
        json: true,
        temperature: 0.1,
        maxTokens: maxTokens);
    final p2 = extractJsonObject(repaired.text);
    if (p2 != null && (valid == null || valid(p2))) return (json: p2, used: repaired.used);
    throw AiException('Model did not return valid JSON for "$task"');
  }
}

/// Extracts the first balanced JSON object from model output (tolerates ``` fences and chatter).
Map<String, dynamic>? extractJsonObject(String raw) {
  var start = raw.indexOf('{');
  while (start >= 0) {
    var depth = 0;
    var inStr = false;
    var esc = false;
    for (var i = start; i < raw.length; i++) {
      final c = raw[i];
      if (inStr) {
        if (esc) {
          esc = false;
        } else if (c == r'\') {
          esc = true;
        } else if (c == '"') {
          inStr = false;
        }
        continue;
      }
      if (c == '"') {
        inStr = true;
      } else if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) {
          try {
            final v = jsonDecode(raw.substring(start, i + 1));
            if (v is Map<String, dynamic>) return v;
          } catch (_) {}
          break;
        }
      }
    }
    start = raw.indexOf('{', start + 1);
  }
  return null;
}
