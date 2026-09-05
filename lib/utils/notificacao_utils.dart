import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';

// Funções e configuração partilhadas pelos ecrãs de notificações
// (lista + detalhe). Antes estavam duplicadas e usavam chaves que não
// existem em lado nenhum da API ('Badge Atribuido', 'Objetivo Alcancado'...)
// — os valores reais que o backend envia (notificacao.service.js) são os
// que estão no mapa abaixo. Com as chaves erradas, TODAS as notificações
// caíam sempre na configuração por omissão (sino cinzento genérico).
//
// `chaveTitulo` é uma chave de tradução (traducoes.dart), não o texto em
// si — os ecrãs que chamam configPara() é que traduzem com ref.t(...).

class NotificacaoConfig {
  final IconData icone;
  final Color cor;
  final Color corFundo;
  final String chaveTitulo;

  const NotificacaoConfig({
    required this.icone,
    required this.cor,
    required this.corFundo,
    required this.chaveTitulo,
  });
}

class NotificacaoUtils {
  NotificacaoUtils._();

  static const Map<String, NotificacaoConfig> _configs = {
    'aprovacao': NotificacaoConfig(
      icone: Icons.check_circle_outline, cor: D.ok, corFundo: D.okBg, chaveTitulo: 'mobile_notiftipo_aprovacao',
    ),
    'rejeicao': NotificacaoConfig(
      icone: Icons.cancel_outlined, cor: D.erro, corFundo: D.erroBg, chaveTitulo: 'mobile_notiftipo_rejeicao',
    ),
    'retificacao': NotificacaoConfig(
      icone: Icons.rotate_left_outlined, cor: D.aviso, corFundo: D.avisoBg, chaveTitulo: 'mobile_notiftipo_retificacao',
    ),
    'candidatura_submetida': NotificacaoConfig(
      icone: Icons.send_outlined, cor: D.azul600, corFundo: D.azul100, chaveTitulo: 'mobile_notiftipo_candidatura_submetida',
    ),
    'em_validacao': NotificacaoConfig(
      icone: Icons.hourglass_top_outlined, cor: D.azul600, corFundo: D.azul100, chaveTitulo: 'mobile_notiftipo_em_validacao',
    ),
    'nova_candidatura': NotificacaoConfig(
      icone: Icons.assignment_outlined, cor: D.azul600, corFundo: D.azul100, chaveTitulo: 'mobile_notiftipo_nova_candidatura',
    ),
    'nova_validacao': NotificacaoConfig(
      icone: Icons.assignment_turned_in_outlined, cor: D.azul600, corFundo: D.azul100, chaveTitulo: 'mobile_notiftipo_nova_validacao',
    ),
    'BADGE_A_EXPIRAR': NotificacaoConfig(
      icone: Icons.timer_outlined, cor: D.aviso, corFundo: D.avisoBg, chaveTitulo: 'mobile_notiftipo_badge_a_expirar',
    ),
    'BADGE_EXPIRADO': NotificacaoConfig(
      icone: Icons.timer_off_outlined, cor: D.erro, corFundo: D.erroBg, chaveTitulo: 'mobile_notiftipo_badge_expirado',
    ),
    // Avisos gerais difundidos pelo Admin / Service Line / Talent Manager
    // (bónus "Informações/Avisos" do enunciado). São criados com
    // tipoNotificacao: 'aviso' e ligados a todos os utilizadores ativos.
    'aviso': NotificacaoConfig(
      icone: Icons.campaign_outlined, cor: D.azul600, corFundo: D.azul100, chaveTitulo: 'mobile_notiftipo_aviso',
    ),
    // Celebração de marcos alcançados (requisito 16)
    'marco': NotificacaoConfig(
      icone: Icons.celebration_outlined, cor: D.aviso, corFundo: D.avisoBg, chaveTitulo: 'mobile_notiftipo_marco',
    ),
    // Bónus: SLA ultrapassado — chega por push a partir do cron do backend.
    // Sem esta entrada aparecia com o sino genérico e o título "Notificação".
    'SLA_ULTRAPASSADO': NotificacaoConfig(
      icone: Icons.alarm_outlined, cor: D.erro, corFundo: D.erroBg, chaveTitulo: 'mobile_notiftipo_sla_ultrapassado',
    ),
    'BADGES_A_EXPIRAR_TM': NotificacaoConfig(
      icone: Icons.timer_outlined, cor: D.aviso, corFundo: D.avisoBg, chaveTitulo: 'mobile_notiftipo_badges_a_expirar_tm',
    ),
    'OBJETIVO_PRAZO': NotificacaoConfig(
      icone: Icons.track_changes_outlined, cor: D.aviso, corFundo: D.avisoBg, chaveTitulo: 'mobile_notiftipo_objetivo_prazo',
    ),
  };

  static const _defeito = NotificacaoConfig(
    icone: Icons.notifications_outlined, cor: D.tinta50, corFundo: D.neutroBg, chaveTitulo: 'mobile_notiftipo_defeito',
  );

  static NotificacaoConfig configPara(String tipo) => _configs[tipo] ?? _defeito;

  // Igual ao tempoRelativo() da web (components/NotificacoesConteudo.jsx)
  static String tempoRelativo(DateTime? data, WidgetRef ref) {
    if (data == null) return ref.t('mobile_notif_sem_data');
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 1) return ref.t('mobile_notif_tempo_agora');
    if (diff.inMinutes < 60) return '${ref.t('mobile_notif_tempo_ha')} ${diff.inMinutes} ${ref.t('mobile_notif_tempo_min')}';
    if (diff.inHours < 24) return '${ref.t('mobile_notif_tempo_ha')} ${diff.inHours}h';
    if (diff.inDays < 7) return '${ref.t('mobile_notif_tempo_ha')} ${diff.inDays}d';
    return '${data.day.toString().padLeft(2, '0')}-${data.month.toString().padLeft(2, '0')}-${data.year}';
  }

  // Igual ao grupoData() da web — agrupa por Hoje / Ontem / Esta Semana / Mais Antigas.
  // Devolve a CHAVE de tradução, não o texto — quem mostra o grupo é que
  // chama ref.t(grupo) (mesma correção que já fizemos na web para o mesmo bug).
  static String grupoData(DateTime? data) {
    if (data == null) return 'mobile_notif_grupo_antigas';
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final ontem = hoje.subtract(const Duration(days: 1));
    final semanaAtras = hoje.subtract(const Duration(days: 7));
    if (!data.isBefore(hoje)) return 'mobile_notif_grupo_hoje';
    if (!data.isBefore(ontem)) return 'mobile_notif_grupo_ontem';
    if (!data.isBefore(semanaAtras)) return 'mobile_notif_grupo_semana';
    return 'mobile_notif_grupo_antigas';
  }

  static const ordemGrupos = [
    'mobile_notif_grupo_hoje',
    'mobile_notif_grupo_ontem',
    'mobile_notif_grupo_semana',
    'mobile_notif_grupo_antigas',
  ];
}