import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

// SharedPreferences
// Guarda preferências simples do utilizador de forma persistente
class PreferenciasService {
  static const _chaveToken = 'token';
  static const _chaveEmail = 'email';
  static const _chaveUltimaSync = 'ultima_sync';

  // Guardar token e email após login
  Future<void> guardarSessao(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveToken, token);
    await prefs.setString(_chaveEmail, email);
    debugPrint('Token hash (SHA-256): ${hashToken(token)}');
  }

  // Ler token guardado
  Future<String?> lerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveToken);
  }

  // Ler email guardado
  Future<String?> lerEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveEmail);
  }

  // Guardar data/hora da última sincronização
  Future<void> guardarUltimaSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveUltimaSync, DateTime.now().toIso8601String());
  }

  // Ler data da última sincronização
  Future<String?> lerUltimaSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveUltimaSync);
  }

  // Limpar tudo no logout
  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static String hashToken(String token){
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}