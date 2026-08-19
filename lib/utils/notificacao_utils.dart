import 'package:flutter/material.dart';
import 'package:pint_mobile/utils/design.dart';

// Funções e configuração partilhadas pelos ecrãs de notificações
// (lista + detalhe). Antes estavam duplicadas e usavam chaves que não
// existem em lado nenhum da API ('Badge Atribuido', 'Objetivo Alcancado'...)
// — os valores reais que o backend envia (notificacao.service.js) são os
// que estão no mapa abaixo. Com as chaves erradas, TODAS as notificações
// caíam sempre na configuração por omissão (sino cinzento genérico).

class NotificacaoConfig {
  final IconData icone;
  final Color cor;
  final Color corFundo;
  final String titulo;

  const NotificacaoConfig({
    required this.icone,
    required this.cor,
    required this.corFundo,
    required this.titulo,
  });
}

class NotificacaoUtils {
  NotificacaoUtils._();

  static const Map<String, NotificacaoConfig> _configs = {
    'aprovacao': NotificacaoConfig(
      icone: Icons.check_circle_outline, cor: D.ok, corFundo: D.okBg, titulo: 'Aprovado',
    ),
    'rejeicao': NotificacaoConfig(
      icone: Icons.cancel_outlined, cor: D.erro, corFundo: D.erroBg, titulo: 'Rejeitado',
    ),
    'retificacao': NotificacaoConfig(
      icone: Icons.rotate_left_outlined, cor: D.aviso, corFundo: D.avisoBg, titulo: 'Candidatura Devolvida',
    ),
    'candidatura_submetida': NotificacaoConfig(
      icone: Icons.send_outlined, cor: D.azul600, corFundo: D.azul100, titulo: 'Candidatura Submetida',
    ),
    'em_validacao': NotificacaoConfig(
      icone: Icons.hourglass_top_outlined, cor: D.azul600, corFundo: D.azul100, titulo: 'Em Validação',
    ),
    'nova_candidatura': NotificacaoConfig(
      icone: Icons.assignment_outlined, cor: D.azul600, corFundo: D.azul100, titulo: 'Nova Candidatura',
    ),
    'nova_validacao': NotificacaoConfig(
      icone: Icons.assignment_turned_in_outlined, cor: D.azul600, corFundo: D.azul100, titulo: 'Nova Validação',
    ),
    'BADGE_A_EXPIRAR': NotificacaoConfig(
      icone: Icons.timer_outlined, cor: D.aviso, corFundo: D.avisoBg, titulo: 'Badge a Expirar',
    ),
    'BADGE_EXPIRADO': NotificacaoConfig(
      icone: Icons.timer_off_outlined, cor: D.erro, corFundo: D.erroBg, titulo: 'Badge Expirado',
    ),
    'OBJETIVO_PRAZO': NotificacaoConfig(
      icone: Icons.track_changes_outlined, cor: D.aviso, corFundo: D.avisoBg, titulo: 'Objetivo a Terminar',
    ),
  };

  static const _defeito = NotificacaoConfig(
    icone: Icons.notifications_outlined, cor: D.tinta50, corFundo: D.neutroBg, titulo: 'Notificação',
  );

  static NotificacaoConfig configPara(String tipo) => _configs[tipo] ?? _defeito;

  // Igual ao tempoRelativo() da web (components/NotificacoesConteudo.jsx)
  static String tempoRelativo(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 1) return 'agora mesmo';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    return '${data.day.toString().padLeft(2, '0')}-${data.month.toString().padLeft(2, '0')}-${data.year}';
  }

  // Igual ao grupoData() da web — agrupa por Hoje / Ontem / Esta Semana / Mais Antigas
  static String grupoData(DateTime data) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final ontem = hoje.subtract(const Duration(days: 1));
    final semanaAtras = hoje.subtract(const Duration(days: 7));
    if (!data.isBefore(hoje)) return 'Hoje';
    if (!data.isBefore(ontem)) return 'Ontem';
    if (!data.isBefore(semanaAtras)) return 'Esta Semana';
    return 'Mais Antigas';
  }

  static const ordemGrupos = ['Hoje', 'Ontem', 'Esta Semana', 'Mais Antigas'];
}