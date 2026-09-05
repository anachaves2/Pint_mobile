import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pint_mobile/models/consultor.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/models/candidatura_badge.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/providers/candidatura_provider.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';

// Ecrã do Perfil
// Mostra os dados pessoais do consultor autenticado, mais Learning Path,
// Service Line, Evolução Profissional e os badges/candidaturas em separadores
// (Obtidos / Em Progresso / Especiais / Histórico), tal como na web.
// Segue os tokens de D e os cards partilhados (CardSimples/CardGradiente),
// os mesmos usados em Objetivos e Gamification — profundidade por elevação
// cinzenta, sem bordas sólidas.

enum _TabPerfil { obtidos, progresso, especiais, historico }

class Perfil extends ConsumerStatefulWidget {
  const Perfil({super.key});

  @override
  ConsumerState<Perfil> createState() => _PerfilState();
}

class _PerfilState extends ConsumerState<Perfil> {
  _TabPerfil _tabAtiva = _TabPerfil.obtidos;
  @override
  Widget build(BuildContext context) {
    final consultorAsync = ref.watch(utilizadorProvider);

    return Scaffold(
      backgroundColor: D.fundo,
      drawer: const CustomDrawer(),
      appBar: _buildAppBar(context),
      body: consultorAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: D.azul600),
        ),
        error: (err, _) => _buildErro(context, ref),
        data: (consultor) {
          if (consultor == null) return _buildErro(context, ref);

          final badges = ref.watch(badgesProvider).valueOrNull ?? [];
          final candidaturas = ref.watch(candidaturasProvider).valueOrNull ?? [];

          return RefreshIndicator(
            color: D.azul600,
            onRefresh: () async {
              await APIService.instance.sincronizarTodos();
              ref.invalidate(utilizadorProvider);
              ref.invalidate(badgesProvider);
              ref.invalidate(candidaturasProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCabecalho(consultor),
                  const SizedBox(height: D.e5),
                  _buildSecaoInformacoes(consultor),
                  const SizedBox(height: D.e5),
                  _buildEvolucaoProfissional(badges),
                  const SizedBox(height: D.e5),
                  _buildSecaoBadges(badges, candidaturas),
                  const SizedBox(height: D.e4),
                  _buildMembroDesde(consultor),
                  const SizedBox(height: D.e5),
                  _buildBotaoDefinicoes(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: SvgPicture.asset(
            'assets/icons/drawerprimario.svg',
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppConstants.corPrimaria,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(ref.t('mobile_perfil_titulo'), style: D.tituloPagina),
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/notificacoesprimaria.svg',
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppConstants.corPrimaria,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => context.push(AppConstants.routeNotificacoes),
        ),
      ],
    );
  }

  // ─── Ecrã de erro ─────────────────────────────────────────────────────────

  Widget _buildErro(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: D.tinta30, size: 64),
          const SizedBox(height: D.e4),
          Text(ref.t('mobile_perfil_erro_carregar'), style: D.corpo),
          const SizedBox(height: D.e4),
          OutlinedButton(
            onPressed: () => ref.invalidate(utilizadorProvider),
            style: OutlinedButton.styleFrom(foregroundColor: D.azul600),
            child: Text(ref.t('mobile_geral_tentar_novamente')),
          ),
        ],
      ),
    );
  }

  // ─── Cabeçalho: foto, nome, cargo, ranking/pontos ─────────────────────────

  Widget _buildCabecalho(Consultor consultor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: D.azul100,
          backgroundImage: consultor.urlFoto != null
              ? NetworkImage(AppConstants.resolverUrlFicheiro(consultor.urlFoto)!)
              : null,
          child: consultor.urlFoto == null
              ? const Icon(Icons.person, size: 44, color: D.azul600)
              : null,
        ),
        const SizedBox(height: D.e3),
        Text(consultor.nome, style: D.tituloSeccao, textAlign: TextAlign.center),
        const SizedBox(height: D.e2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: D.e3, vertical: 4),
          decoration: BoxDecoration(
            color: D.azul100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(ref.t('mobile_perfil_consultor'), style: D.etiqueta),
        ),
        const SizedBox(height: D.e4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChipEstado(
              icone: Icons.emoji_events_outlined,
              texto: consultor.posicaoRanking != null
                  ? '${consultor.posicaoRanking}${ref.t('mobile_perfil_posicao_sufixo')}'
                  : ref.t('mobile_perfil_sem_posicao'),
              cor: D.azul600,
              corFundo: D.azul100,
            ),
            const SizedBox(width: D.e2),
            ChipEstado(
              icone: Icons.star_outline,
              texto: '${consultor.totalPontos ?? 0} ${ref.t('mobile_ranking_pontos')}',
              cor: D.aviso,
              corFundo: D.avisoBg,
            ),
          ],
        ),
      ],
    );
  }

  // ─── Informações ──────────────────────────────────────────────────────────

  Widget _buildSecaoInformacoes(Consultor consultor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ref.t('mobile_perfil_informacoes'), style: D.etiqueta),
        const SizedBox(height: D.e3),
        CardSimples(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildLinhaInfo(icon: Icons.email_outlined, texto: consultor.email),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.phone_outlined,
                texto: consultor.telefone ?? ref.t('mobile_perfil_sem_telefone'),
                vazio: consultor.telefone == null,
              ),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.link,
                texto: consultor.urlLinkedin ?? ref.t('mobile_perfil_sem_linkedin'),
                vazio: consultor.urlLinkedin == null,
                isLink: consultor.urlLinkedin != null,
                url: consultor.urlLinkedin,
              ),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.language,
                // Link real da página pública do consultor (mesma rota que a
                // web usa em App.jsx: /consultores/:id). Antes estava aqui um
                // domínio inventado (www.softinsa.pt/galeria-publico/...) que
                // nunca existiu.
                texto: '${AppConstants.frontendUrl}/consultores/${consultor.id}',
                isLink: true,
                url: '${AppConstants.frontendUrl}/consultores/${consultor.id}',
              ),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.work_outline,
                texto: '${ref.t('mobile_perfil_area')} ${consultor.nomeArea ?? '-'}',
              ),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.account_tree_outlined,
                texto: '${ref.t('mobile_badges_service_line')} ${consultor.nomeServiceLine ?? '-'}',
                vazio: consultor.nomeServiceLine == null,
              ),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.map_outlined,
                texto: '${ref.t('mobile_perfil_learning_path')} ${consultor.nomeLearningPath ?? '-'}',
                vazio: consultor.nomeLearningPath == null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinhaInfo({
    required IconData icon,
    required String texto,
    bool vazio = false,
    bool isLink = false,
    String? url,
  }) {
    final linha = Padding(
      padding: const EdgeInsets.symmetric(horizontal: D.e4, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: vazio ? D.tinta30 : D.azul600),
          const SizedBox(width: D.e3),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                color: vazio ? D.tinta30 : (isLink ? D.azul600 : D.tinta),
                decoration: isLink ? TextDecoration.underline : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Botão de copiar — só nos links, e só quando há de facto um
          // (o LinkedIn pode estar por preencher, mesmo com isLink=true
          // se algum dia essa combinação surgir).
          if (isLink && url != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 16, color: D.tinta30),
              tooltip: ref.t('mobile_perfil_copiar_link'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ref.t('mobile_perfil_link_copiado'))),
                  );
                }
              },
            ),
        ],
      ),
    );

    if (!isLink || url == null) return linha;

    // Toda a linha fica tocável para abrir o link — mesmo padrão (tentar
    // abrir diretamente, sem confiar em canLaunchUrl()) já usado em
    // detalhe_badge_regular_screen.dart / detalhe_badge_premium_screen.dart.
    return InkWell(
      onTap: () async {
        try {
          final abriu = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          if (!abriu && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ref.t('mobile_perfil_erro_link'))),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ref.t('mobile_perfil_erro_link'))),
            );
          }
        }
      },
      child: linha,
    );
  }

  Widget _buildDivisor() {
    return Divider(height: 1, thickness: 1, color: D.fundoAlt, indent: D.e4, endIndent: D.e4);
  }

  // ─── Evolução Profissional ────────────────────────────────────────────────
  // Junta os badges regulares + especiais válidos, ordenados por data de
  // atribuição (mais antigo primeiro) — igual ao que o endpoint
  // /perfil/me/detalhe faz na web, mas calculado aqui a partir do que já
  // está sincronizado, sem pedir nada novo à API.

  Widget _buildEvolucaoProfissional(List<BadgeUtilizador> badges) {
    final itens = badges.where((b) => b.valido).toList()
      ..sort((a, b) => a.dataAtribuicao.compareTo(b.dataAtribuicao));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ref.t('mobile_perfil_evolucao'), style: D.etiqueta),
        const SizedBox(height: D.e3),
        if (itens.isEmpty)
          CardSimples(
            child: Center(
              child: Text(ref.t('mobile_perfil_sem_conquistas'), style: D.legenda),
            ),
          )
        else
          CardSimples(
            child: Column(
              children: [
                for (int i = 0; i < itens.length; i++)
                  _buildLinhaEvolucao(badge: itens[i], ultimo: i == itens.length - 1),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLinhaEvolucao({required BadgeUtilizador badge, required bool ultimo}) {
    final titulo = badge.idBadgeEspecial != null
        ? '${ref.t('mobile_perfil_conquista_especial')} ${badge.nomeBadge}'
        : '${ref.t('mobile_perfil_conquista')} ${badge.nomeBadge}';
    final data = badge.dataAtribuicao;
    final dataFormatada =
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: D.azul600, shape: BoxShape.circle),
              ),
              if (!ultimo)
                Expanded(child: Container(width: 2, color: D.fundoAlt)),
            ],
          ),
          const SizedBox(width: D.e3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: D.e4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: D.tituloCard),
                  const SizedBox(height: 2),
                  Text(dataFormatada, style: D.legenda),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Separadores de Badges (Obtidos / Em Progresso / Especiais / Histórico) ──
  // Mesma estrutura de 4 separadores da web, mais o filtro de pesquisa que já
  // existe em "Os Meus Badges" — tudo alimentado pelos providers já
  // sincronizados, sem pedidos novos à API.

  Widget _buildSecaoBadges(List<BadgeUtilizador> badges, List<CandidaturaBadge> candidaturas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ref.t('mobile_perfil_badges_titulo'), style: D.etiqueta),
        const SizedBox(height: D.e3),
        _buildTabsPills(),
        const SizedBox(height: D.e3),
        _buildConteudoTab(badges, candidaturas),
      ],
    );
  }

  Widget _buildTabsPills() {
    final tabs = {
      _TabPerfil.obtidos: ref.t('mobile_perfil_tab_obtidos'),
      _TabPerfil.progresso: ref.t('mobile_perfil_tab_progresso'),
      _TabPerfil.especiais: ref.t('mobile_perfil_tab_especiais'),
      _TabPerfil.historico: ref.t('mobile_perfil_tab_historico'),
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: D.superficie,
        borderRadius: BorderRadius.circular(D.rSm),
        boxShadow: D.elev1,
      ),
      child: Row(
        children: tabs.entries.map((entry) {
          final ativo = _tabAtiva == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabAtiva = entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: ativo ? D.azul600 : Colors.transparent,
                  borderRadius: BorderRadius.circular(D.rSm - 2),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ativo ? Colors.white : D.tinta30,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConteudoTab(List<BadgeUtilizador> badges, List<CandidaturaBadge> candidaturas) {
    switch (_tabAtiva) {
      case _TabPerfil.obtidos:
        final lista = badges.where((b) => b.valido && b.idBadgeEspecial == null).toList()
            ..sort((a, b) => b.dataAtribuicao.compareTo(a.dataAtribuicao));
        return _buildListaBadges(lista, vazio: ref.t('mobile_perfil_vazio_obtidos'));

      case _TabPerfil.especiais:
        final lista = badges.where((b) => b.valido && b.idBadgeEspecial != null).toList()
            ..sort((a, b) => b.dataAtribuicao.compareTo(a.dataAtribuicao));
        return _buildListaBadges(lista, vazio: ref.t('mobile_perfil_vazio_especiais'));

      case _TabPerfil.progresso:
        final lista = candidaturas.where((c) => !c.estaConcluida).toList()
            ..sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
        return _buildListaCandidaturas(lista, vazio: ref.t('mobile_perfil_vazio_progresso'));

      case _TabPerfil.historico:
        final lista = candidaturas.where((c) => c.estaConcluida).toList()
            ..sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
        return _buildListaCandidaturas(lista, vazio: ref.t('mobile_perfil_vazio_historico'));
    }
  }

  Widget _buildListaBadges(List<BadgeUtilizador> lista, {required String vazio}) {
    if (lista.isEmpty) return CardSimples(child: Center(child: Text(vazio, style: D.legenda)));
    return Column(
      children: lista.map((b) {
        final subtitulo =
            [b.nomeArea, b.nomeNivel].where((s) => s != null && s.isNotEmpty).join(' · ');
        return _buildLinhaBadge(
          titulo: b.nomeBadge,
          subtitulo: subtitulo.isEmpty ? null : subtitulo,
          data: b.dataAtribuicao,
          pontos: b.pontos,
          // Abre o detalhe do badge, tal como em "Os Meus Badges"
          onTap: () {
            if (b.idBadgeEspecial != null) {
              context.push(AppConstants.routeDetalheBadgePremium, extra: b);
            } else if (b.jaExpirou) {
              context.push(AppConstants.routeDetalheBadgeExpirado, extra: b);
            } else {
              context.push(AppConstants.routeDetalheBadge, extra: b);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildListaCandidaturas(List<CandidaturaBadge> lista, {required String vazio}) {
    if (lista.isEmpty) return CardSimples(child: Center(child: Text(vazio, style: D.legenda)));
    return Column(
      children: lista.map((c) {
        return _buildLinhaBadge(
          titulo: c.nomeBadge,
          subtitulo: c.nomeEstadoAtual,
          data: c.dataCriacao,
          aprovada: c.aprovada,
          rejeitada: c.rejeitada,
          onTap: () => context.push(AppConstants.routeDetalheCandidatura, extra: c.numCandidatura),
        );
      }).toList(),
    );
  }

  Widget _buildLinhaBadge({
    required String titulo,
    String? subtitulo,
    required DateTime data,
    int? pontos,
    bool aprovada = false,
    bool rejeitada = false,
    VoidCallback? onTap,
  }) {
    final dataFormatada =
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: D.e2),
      child: CardSimples(
        padding: const EdgeInsets.symmetric(horizontal: D.e4, vertical: D.e3),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: D.tituloCard),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 4),
                    aprovada || rejeitada
                        ? ChipEstado(
                            texto: subtitulo,
                            cor: aprovada ? D.ok : D.erro,
                            corFundo: aprovada ? D.okBg : D.erroBg,
                          )
                        : Text(subtitulo, style: D.legenda),
                  ],
                ],
              ),
            ),
            const SizedBox(width: D.e2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(dataFormatada, style: D.legenda),
                if (pontos != null) ...[
                  const SizedBox(height: 2),
                  Text('$pontos ${ref.t('mobile_ranking_pts')}',
                      style: const TextStyle(fontSize: 11, color: D.azul600, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
            if (onTap != null) const Icon(Icons.chevron_right, color: D.tinta30, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMembroDesde(Consultor consultor) {
    final data = consultor.dataMembro;
    final dataFormatada =
        '${data.day.toString().padLeft(2, '0')}-${data.month.toString().padLeft(2, '0')}-${data.year}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.calendar_today_outlined, size: 14, color: D.tinta30),
        const SizedBox(width: 6),
        Text('${ref.t('mobile_perfil_membro_desde')} $dataFormatada', style: D.legenda),
      ],
    );
  }

  Widget _buildBotaoDefinicoes(BuildContext context) {
    return OutlinedButton(
      onPressed: () => context.push(AppConstants.routeDefinicoes),
      style: OutlinedButton.styleFrom(
        foregroundColor: D.azul600,
        side: const BorderSide(color: D.azul600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(
        ref.t('mobile_perfil_definicoes_botao'),
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
    );
  }
}