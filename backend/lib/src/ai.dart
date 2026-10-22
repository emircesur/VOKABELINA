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

/// Talks to Anthropic, OpenAI-compatible and Gemini APIs.
class AiClient {
  AiClient(this._http);
  final http.Client _http;

  Future<String> complete(
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

  Future<Map<String, dynamic>> _post(Uri url, Map<String, String> headers, Object body) async {
    final res = await _http
        .post(url, headers: {'content-type': 'application/json', ...headers}, body: jsonEncode(body))
        .timeout(const Duration(seconds: 60));
    final text = utf8.decode(res.bodyBytes);
    if (res.statusCode >= 300) {
      throw AiException(text.length > 300 ? text.substring(0, 300) : text, status: res.statusCode);
    }
    return jsonDecode(text) as Map<String, dynamic>;
  }

  Future<String> _anthropic(AiProvider p, String model, String system, List<ChatTurn> msgs, int maxTokens, double temp) async {
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
    return text;
  }

  Future<String> _openai(AiProvider p, String model, String system, List<ChatTurn> msgs, int maxTokens, bool json, double temp) async {
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
    return text;
  }

  Future<String> _gemini(AiProvider p, String model, String system, List<ChatTurn> msgs, int maxTokens, bool json, double temp) async {
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
    return text;
  }
}

/// Resolves a task to provider(+fallback) according to the admin-edited config.
class AiRouter {
  AiRouter(this.config, this.client);
  final ServerConfig Function() config;
  final AiClient client;

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
        lastError = AiException('Provider "$pid" is not configured');
        continue;
      }
      try {
        final text = await client.complete(
          p,
          model,
          system: fullSystem,
          messages: messages,
          maxTokens: maxTokens ?? cfg.maxTokens,
          json: json,
          temperature: temperature,
        );
        return (text: text, used: '${p.id}/$model');
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? AiException('No provider configured for "$task"');
  }
}

/// Extracts the first balanced JSON object from model output (tolerates ``` fences and chatter).
Map<String, dynamic>? extractJsonObject(String raw) {
  final start = raw.indexOf('{');
  if (start < 0) return null;
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
          return v is Map<String, dynamic> ? v : null;
        } catch (_) {
          return null;
        }
      }
    }
  }
  return null;
}
