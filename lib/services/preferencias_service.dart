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
  // Dados da saudação de evento (bónus do enunciado) — guardados aqui em vez
  // de no SQLite para não obrigar a mais uma migração da base de dados.
  static const _chavePrimeiroAcesso = 'saudacao_primeiro_acesso';
  static const _chaveUltimoLoginAnterior = 'saudacao_ultimo_login_anterior';
  // Linha de base para a celebração de marcos (requisito 16)
  static const _chaveMarcoBadges = 'marco_badges';
  static const _chaveMarcoEspeciais = 'marco_especiais';
  static const _chaveMarcoObjetivos = 'marco_objetivos';
  static const _chaveMarcoPontos = 'marco_pontos';

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

  // Guardar o contexto para a saudação, no momento do login
  Future<void> guardarDadosSaudacao({
    required bool primeiroAcesso,
    DateTime? ultimoLoginAnterior,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chavePrimeiroAcesso, primeiroAcesso);
    if (ultimoLoginAnterior != null) {
      await prefs.setString(_chaveUltimoLoginAnterior, ultimoLoginAnterior.toIso8601String());
    } else {
      await prefs.remove(_chaveUltimoLoginAnterior);
    }
  }

  Future<({bool primeiroAcesso, DateTime? ultimoLoginAnterior})> lerDadosSaudacao() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chaveUltimoLoginAnterior);
    return (
      primeiroAcesso: prefs.getBool(_chavePrimeiroAcesso) ?? false,
      ultimoLoginAnterior: texto != null ? DateTime.tryParse(texto) : null,
    );
  }

  // Guardar os totais atuais, que servem de comparação na próxima abertura
  Future<void> guardarMarcosVistos({
    required int badges,
    required int especiais,
    required int objetivos,
    required int pontos,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chaveMarcoBadges, badges);
    await prefs.setInt(_chaveMarcoEspeciais, especiais);
    await prefs.setInt(_chaveMarcoObjetivos, objetivos);
    await prefs.setInt(_chaveMarcoPontos, pontos);
  }

  /// Devolve null em cada campo quando ainda não há linha de base — nesse
  /// caso não se celebra nada, apenas se grava o estado atual.
  Future<({int? badges, int? especiais, int? objetivos, int? pontos})> lerMarcosVistos() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      badges: prefs.getInt(_chaveMarcoBadges),
      especiais: prefs.getInt(_chaveMarcoEspeciais),
      objetivos: prefs.getInt(_chaveMarcoObjetivos),
      pontos: prefs.getInt(_chaveMarcoPontos),
    );
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