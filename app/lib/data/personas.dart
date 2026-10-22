import 'package:flutter/material.dart';

class Persona {
  const Persona({
    required this.id,
    required this.name,
    required this.species,
    required this.taglineEn,
    required this.taglineTr,
    required this.body,
    required this.belly,
    required this.accent,
    required this.hello,
  });

  final String id;
  final String name;
  final String species;
  final String taglineEn;
  final String taglineTr;
  final Color body;
  final Color belly;
  final Color accent;

  /// First German line when a chat starts.
  final String hello;

  String tagline(String lang) => lang == 'tr' ? taglineTr : taglineEn;
}

const personas = <String, Persona>{
  'bruno': Persona(
    id: 'bruno',
    name: 'Bruno',
    species: 'Bär',
    taglineEn: 'Warm & patient. Celebrates every small win.',
    taglineTr: 'Sıcak ve sabırlı. Her küçük başarıyı kutlar.',
    body: Color(0xFFB9783F),
    belly: Color(0xFFF2D3A4),
    accent: Color(0xFFE8832A),
    hello: 'Hallo! Ich bin Bruno. Wie heißt du?',
  ),
  'fuchs': Persona(
    id: 'fuchs',
    name: 'Frau Fuchs',
    species: 'Fuchs',
    taglineEn: 'Witty and strict. Sharp grammar, rare praise.',
    taglineTr: 'Zeki ve disiplinli. Keskin gramer, nadir övgü.',
    body: Color(0xFFE5622D),
    belly: Color(0xFFFFEBD6),
    accent: Color(0xFF1F8A8A),
    hello: 'Guten Tag. Ich bin Frau Fuchs. Fangen wir an: Wie heißen Sie?',
  ),
  'brezel': Persona(
    id: 'brezel',
    name: 'Brezel',
    species: 'Brezel',
    taglineEn: 'Meme lord. Jokes, slang and German culture.',
    taglineTr: 'Meme ustası. Espri, argo ve Alman kültürü.',
    body: Color(0xFFC98A3C),
    belly: Color(0xFFF6DDA8),
    accent: Color(0xFFD64545),
    hello: 'Servus! Ich bin Brezel 🥨 Wer bist du denn?',
  ),
};

Persona personaOf(String id) => personas[id] ?? personas['bruno']!;
