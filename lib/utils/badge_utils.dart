import 'package:flutter/material.dart';

// Funções utilitárias partilhadas pelos ecrãs de badges.
// Antes estavam duplicadas em meus_badges_screen e todos_badges_screen.

class BadgeUtils {
  BadgeUtils._(); // construtor privado — classe só com métodos estáticos

  // Cor do círculo com base no tipo de nível (campo TIPO da tabela NIVEL).
  // JN=Júnior=laranja, IN=Intermédio=cinza, SN=Sénior=verde,
  // EP=Especialista=azul, LD=Líder de Conhecimento=roxo.
  static Color corDoNivel(String? tipoNivel) {
    switch (tipoNivel?.toUpperCase()) {
      case 'A':
      case 'JN':
        return const Color(0xFFF5A623); // laranja — Júnior
      case 'B':
      case 'IN':
        return Colors.grey; // cinza — Intermédio
      case 'C':
      case 'SN':
        return const Color(0xFF4CAF50); // verde — Sénior
      case 'D':
      case 'EP':
        return const Color(0xFF0066CC); // azul — Especialista
      case 'E':
      case 'LD':
        return const Color(0xFF9C27B0); // roxo — Líder de Conhecimento
      default:
        return const Color(0xFF0066CC);
    }
  }

  // Formata um DateTime para o formato DD-MM-AAAA usado em toda a app.
  static String formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.year}';
  }
}