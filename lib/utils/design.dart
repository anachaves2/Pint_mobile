import 'package:flutter/material.dart';

/// Tokens de design partilhados com a web.
/// As cores são as mesmas do `styles.css` para que as duas plataformas
/// fiquem coerentes sem ter de andar a acertar valores à mão.
///
/// Direção: profundidade por elevação e contraste de fundo — sem bordas sólidas.
class D {
  D._();

  // ── Marca ──────────────────────────────────────────────
  static const azul900 = Color(0xFF1E3A5F);
  static const azul700 = Color(0xFF2E4F7A);
  static const azul600 = Color(0xFF39639C); // = AppConstants.corPrimaria
  static const azul400 = Color(0xFF4A9FD4);
  static const azul100 = Color(0xFFE8EEF6);

  /// Gradiente assinatura (o mesmo do Figma usado no StatCard da web).
  /// Usado como "borda" dos cards de destaque.
  static const gradMarca = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00647A),
      Color(0xFF9CEDFF),
      Color(0xFF008EAD),
      Color(0xFFB1D2D9),
    ],
    stops: [0.0, 0.36, 0.62, 0.91],
  );

  // ── Neutros ────────────────────────────────────────────
  static const tinta = Color(0xFF1A1D23);
  static const tinta70 = Color(0xFF475569);
  static const tinta50 = Color(0xFF64748B);
  static const tinta30 = Color(0xFF94A3B8);
  static const superficie = Color(0xFFFFFFFF);
  static const fundo = Color(0xFFFFFFFF);
  static const fundoAlt = Color(0xFFF8FAFC);

  // ── Estado ─────────────────────────────────────────────
  static const ok = Color(0xFF2E7D32);
  static const okBg = Color(0xFFE8F5E9);
  static const erro = Color(0xFFC0392B);
  static const erroBg = Color(0xFFFDECEA);
  static const aviso = Color(0xFFB45309);
  static const avisoBg = Color(0xFFFEF3C7);
  static const neutro = Color(0xFF6B7280);
  static const neutroBg = Color(0xFFF3F4F6);

  // ── Elevação ───────────────────────────────────────────
  // Sombras cinzentas neutras — iguais ao .card da web (rgba(237,237,237,1)).
  // A cor só entra no brilho do pódio (podioXBrilho) mais abaixo; aqui é
  // sempre profundidade neutra, nunca tingida de azul ou de qualquer marca.
  static const elev1 = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 3)),
  ];
  static const elev2 = <BoxShadow>[
    BoxShadow(color: Color(0x1F000000), blurRadius: 20, offset: Offset(0, 6)),
  ];
  static const elev3 = <BoxShadow>[
    BoxShadow(color: Color(0x29000000), blurRadius: 30, offset: Offset(0, 12)),
  ];

  // ── Pódio ──────────────────────────────────────────────
  // Cores iguais às do pódio da web (serviceline/Gamification.jsx):
  // 1º esmeralda, 2º azul-céu, 3º índigo.

  static const podio1Grad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x66A7F3D0), Color(0xCC34D399)],
  );
  static const podio2Grad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x66BAE6FD), Color(0xCC38BDF8)],
  );
  static const podio3Grad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x66C7D2FE), Color(0xCC818CF8)],
  );

  static const podio1Brilho = <BoxShadow>[
    BoxShadow(color: Color(0x4D34D399), blurRadius: 20, offset: Offset(0, 4)),
  ];
  static const podio2Brilho = <BoxShadow>[
    BoxShadow(color: Color(0x3338BDF8), blurRadius: 15, offset: Offset(0, 4)),
  ];
  static const podio3Brilho = <BoxShadow>[
    BoxShadow(color: Color(0x33818CF8), blurRadius: 15, offset: Offset(0, 4)),
  ];

  /// Alturas das barras — a hierarquia lê-se pela altura, não só pela cor.
  static const podio1Altura = 130.0;
  static const podio2Altura = 100.0;
  static const podio3Altura = 85.0;

  static const podioCirculoBg = Color(0xFFF1F5F9);
  static const podioCirculoTexto = Color(0xFF475569);

  // ── Espaço ─────────────────────────────────────────────
  static const e1 = 4.0;
  static const e2 = 8.0;
  static const e3 = 12.0;
  static const e4 = 16.0;
  static const e5 = 24.0;
  static const e6 = 32.0;

  // ── Cantos ─────────────────────────────────────────────
  static const rSm = 8.0;
  static const rMd = 10.0;
  static const rLg = 16.0;

  // ── Tipografia ─────────────────────────────────────────
  static const tituloPagina =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: azul600);
  static const tituloSeccao =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tinta);
  static const tituloCard =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tinta);
  static const corpo = TextStyle(fontSize: 14, color: tinta70);
  static const legenda = TextStyle(fontSize: 13, color: tinta50);
  // Usada nos subtítulos de secção (RESUMO, OBJETIVOS, BADGES...) — 11px era
  // pequeno de mais para ler à distância normal no telemóvel.
  static const etiqueta = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: tinta50,
  );

  // ── Cor por tipo de objetivo ───────────────────────────
  // IDs fixos da tabela tipo_objetivo — iguais aos da web (Objetivos.jsx)
  static const Map<int, Color> corTipoObjetivo = {
    1: Color(0xFF39639C), // Completar Área
    2: Color(0xFF6F42C1), // Completar Service Line
    3: Color(0xFF0D9488), // Completar Learning Path
    4: Color(0xFFD4A017), // Atingir Nível Líder
    5: Color(0xFFE67E22), // Atingir Topo Gamification
  };

  static const Map<int, IconData> iconeTipoObjetivo = {
    1: Icons.layers_outlined,
    2: Icons.account_tree_outlined,
    3: Icons.route_outlined,
    4: Icons.workspace_premium_outlined,
    5: Icons.emoji_events_outlined,
  };

  static Color corDoTipo(int id) => corTipoObjetivo[id] ?? azul600;
  static IconData iconeDoTipo(int id) =>
      iconeTipoObjetivo[id] ?? Icons.flag_outlined;
}