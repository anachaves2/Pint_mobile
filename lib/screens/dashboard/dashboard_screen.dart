import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/utils/badge_utils.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/podio_ranking.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/models/badge_recomendado.dart';
import 'package:pint_mobile/models/notificacao.dart';
import 'package:pint_mobile/models/ranking_entrada.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/providers/candidatura_provider.dart';
import 'package:pint_mobile/providers/objetivos_provider.dart';
import 'package:pint_mobile/providers/objetivos_resumo_provider.dart';
import 'package:pint_mobile/providers/badges_recomendados_provider.dart';
import 'package:pint_mobile/models/objetivos_resumo.dart';
import 'package:pint_mobile/providers/ranking_provider.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:pint_mobile/widgets/saudacao_evento.dart';
import 'package:pint_mobile/widgets/celebracao_marco.dart';
import 'package:pint_mobile/services/preferencias_service.dart';
import 'package:go_router/go_router.dart';

// Ecrã do Dashboard — segue os tokens de D e os componentes partilhados
// (CardSimples, PodioRanking), tal como Objetivos, Gamification e Perfil.
// Paridade com a web: saudação, os 4 cartões de resumo, secção de Objetivos
// (progresso + áreas/service lines + objetivos em curso), pódio do
// Gamification, "O teu desempenho" com mini-tabela de ranking, e badges
// recomendados. O Drawer mantém-se tal como estava.

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<Notificacao> _notificacoes = [];
  String _pesquisa = '';
  StreamSubscription? _subDados;

  @override
  void initState() {
    super.initState();
    // A verificação de marcos tem de esperar pela sincronização: os
    // providers leem do SQLite, e uma lista vazia não é "a carregar" — é
    // "carregado e vazio". Sem esta espera, a app gravava a linha de base a
    // zeros antes de os dados chegarem e, na abertura seguinte, celebrava
    // badges que já eram antigos.
    APIService.instance.sincronizarTodos().then((_) {
      if (mounted) _verificarMarcos();
    });
    _carregarExtras();
    _mostrarSaudacao();
    _subDados = atualizadorDados.stream.listen((_) {
      ref.invalidate(utilizadorProvider);
      ref.invalidate(badgesProvider);
      ref.invalidate(candidaturasProvider);
      ref.invalidate(objetivosProvider);
      ref.invalidate(objetivosResumoProvider);
      ref.invalidate(badgesRecomendadosProvider);
      ref.invalidate(rankingProvider);
      _carregarExtras();
    });
  }

  @override
  void dispose() {
    _subDados?.cancel();
    super.dispose();
  }

  // Notificações não têm provider: são carregadas directamente do SQLite
  Future<void> _carregarExtras() async {
    final notificacoes = await DatabaseService.instance.getNotificacoes();
    if (mounted) setState(() => _notificacoes = notificacoes);
  }

  // Modal de boas-vindas / regresso — só aparece uma vez por sessão
  Future<void> _mostrarSaudacao() async {
    final dados = await PreferenciasService().lerDadosSaudacao();
    final utilizador = await DatabaseService.instance.getUser();
    if (!mounted || utilizador == null) return;

    await SaudacaoEvento.mostrarSeNecessario(
      context,
      nome: utilizador.nome,
      primeiroAcesso: dados.primeiroAcesso,
      ultimoLoginAnterior: dados.ultimoLoginAnterior,
    );
  }

  // REQUISITO 16 — celebração de marcos.
  // Corre depois de os dados estarem carregados: compara os totais atuais
  // com os da última abertura e celebra o que subiu. A saudação tem
  // prioridade, por isso só se mostra a celebração se não houve saudação.
  bool _marcosVerificados = false;

  Future<void> _verificarMarcos() async {
    if (_marcosVerificados) return;
    _marcosVerificados = true;

    // Lê as contagens directamente da base de dados, já depois da
    // sincronização — não do build, que podia estar a mostrar dados
    // incompletos.
    final listaBadges = await DatabaseService.instance.getBadges();
    final listaObjetivos = await DatabaseService.instance.getObjetivos();

    final badges = listaBadges.where((b) => b.valido && b.idBadgeRegular != null).length;
    final especiais = listaBadges.where((b) => b.valido && b.idBadgeEspecial != null).length;
    final objetivos = listaObjetivos.where((o) => o.alcancado).length;
    final pontos = listaBadges.fold<int>(0, (soma, b) => soma + (b.pontos ?? 0));

    // Salvaguarda: se não há badges NEM objetivos, é quase certo que a
    // sincronização falhou (sem rede) em vez de o consultor não ter mesmo
    // nada. Nesse caso não gravamos linha de base a zeros — senão a
    // próxima abertura celebraria tudo outra vez como se fosse novo.
    if (listaBadges.isEmpty && listaObjetivos.isEmpty) {
      _marcosVerificados = false; // permite tentar de novo mais tarde
      return;
    }

    final prefs = PreferenciasService();
    final antes = await prefs.lerMarcosVistos();

    final marcos = CelebracaoMarco.calcular(
      badgesAgora: badges,
      especiaisAgora: especiais,
      objetivosAgora: objetivos,
      pontosAgora: pontos,
      badgesAntes: antes.badges,
      especiaisAntes: antes.especiais,
      objetivosAntes: antes.objetivos,
      pontosAntes: antes.pontos,
    );

    // Grava sempre a nova linha de base, mesmo quando não há nada a celebrar
    await prefs.guardarMarcosVistos(
      badges: badges, especiais: especiais, objetivos: objetivos, pontos: pontos,
    );

    // Espera que a saudação (se houver) feche primeiro
    await SaudacaoEvento.concluida;

    if (!mounted) return;
    await CelebracaoMarco.mostrar(context, marcos);
  }

  int get _notificacoesNaoLidas => _notificacoes.where((n) => !n.lida).length;

  // ── Saudação por hora, igual à web (components/Saudacao.jsx) ──────────────
  String _saudacaoPorHora() {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 13) return ref.t('mobile_dash_bom_dia');
    if (h >= 13 && h < 20) return ref.t('mobile_dash_boa_tarde');
    return ref.t('mobile_dash_boa_noite');
  }

  @override
  Widget build(BuildContext context) {
    final consultorAsync = ref.watch(utilizadorProvider);
    final badgesAsync = ref.watch(badgesProvider);
    final candidaturasAsync = ref.watch(candidaturasProvider);
    final objetivosAsync = ref.watch(objetivosProvider);
    final objetivosResumoAsync = ref.watch(objetivosResumoProvider);
    final badgesRecomendadosAsync = ref.watch(badgesRecomendadosProvider);
    final rankingAsync = ref.watch(rankingProvider);
    final podio = ref.watch(podioProvider);

    final isLoading = consultorAsync.isLoading ||
        badgesAsync.isLoading ||
        candidaturasAsync.isLoading;

    final consultor = consultorAsync.value;
    final badges = badgesAsync.value ?? [];
    final candidaturas = candidaturasAsync.value ?? [];
    final objetivos = objetivosAsync.value ?? [];
    final ranking = rankingAsync.value ?? [];

    // ── Resumo (4 cartões) — mesmos 4 números da web ─────────────────────
    final pedidosEmCurso = candidaturas.where((c) => !c.estaConcluida).length;
    final badgesConquistados =
        badges.where((b) => b.valido && b.idBadgeRegular != null).length;
    final badgesEspeciais =
        badges.where((b) => b.valido && b.idBadgeEspecial != null).length;
    final objetivosAlcancados = objetivos.where((o) => o.alcancado).length;

    // ── Ranking: a minha posição + próximos 3 lugares para a mini-tabela ──
    final primeiroNome = (consultor?.nome ?? '').split(' ').first;
    final meuDesempenho = ranking.where((r) => r.idUtilizador == consultor?.id).firstOrNull;
    final restoRanking = ranking.skip(3).take(3).toList();

    return Scaffold(
      backgroundColor: D.fundo,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: SvgPicture.asset(
              'assets/icons/drawerprimario.svg',
              height: 20,
              colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(ref.t('mobile_dash_titulo'), style: D.tituloPagina),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/notificacoesprimaria.svg',
                  height: 24,
                  colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn),
                ),
                onPressed: () => context.push(AppConstants.routeNotificacoes),
              ),
              if (_notificacoesNaoLidas > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: D.erro, shape: BoxShape.circle),
                    child: Text(
                      '$_notificacoesNaoLidas',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: D.azul600))
          : RefreshIndicator(
              onRefresh: () async {
                await APIService.instance.sincronizarTodos();
                ref.invalidate(utilizadorProvider);
                ref.invalidate(badgesProvider);
                ref.invalidate(candidaturasProvider);
                ref.invalidate(objetivosProvider);
                ref.invalidate(objetivosResumoProvider);
                ref.invalidate(badgesRecomendadosProvider);
                ref.invalidate(rankingProvider);
                await _carregarExtras();
              },
              color: D.azul600,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Saudação ──────────────────────────
                    Text(
                      '${_saudacaoPorHora()}, $primeiroNome 👋',
                      style: D.tituloSeccao.copyWith(fontSize: 18, color: D.azul600),
                    ),
                    const SizedBox(height: D.e4),

                    // ─── Barra de pesquisa ────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: D.superficie,
                        borderRadius: BorderRadius.circular(D.rMd),
                        boxShadow: D.elev1,
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => _pesquisa = value),
                        decoration: InputDecoration(
                          hintText: ref.t('mobile_geral_procurar'),
                          hintStyle: const TextStyle(color: D.tinta30, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: D.tinta30, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: D.e4, vertical: D.e3),
                        ),
                      ),
                    ),
                    const SizedBox(height: D.e5),

                    // ─── Resumo — os mesmos 4 números da web ──────────────
                    Text(ref.t('mobile_dash_resumo_atividade'), style: D.etiqueta),
                    const SizedBox(height: D.e3),
                    Row(
                      children: [
                        Expanded(child: _buildCartaoResumo(icon: Icons.description_outlined, valor: pedidosEmCurso, label: ref.t('mobile_dash_pedidos_pendentes'), onTap: () => context.push(AppConstants.routeCandidaturasDecorrentes))),
                        const SizedBox(width: D.e2),
                        Expanded(child: _buildCartaoResumo(icon: Icons.military_tech_outlined, valor: badgesConquistados, label: ref.t('mobile_dash_badges_conquistados'), onTap: () => context.push(AppConstants.routeMeusBadges))),
                      ],
                    ),
                    const SizedBox(height: D.e2),
                    Row(
                      children: [
                        Expanded(child: _buildCartaoResumo(icon: Icons.star_outline, valor: badgesEspeciais, label: ref.t('mobile_dash_badges_especiais'), onTap: () => context.push(AppConstants.routeBadgesEspeciais))),
                        const SizedBox(width: D.e2),
                        Expanded(child: _buildCartaoResumo(icon: Icons.track_changes_outlined, valor: objetivosAlcancados, label: ref.t('mobile_dash_objetivos_alcancados'), onTap: () => context.push(AppConstants.routeObjetivos))),
                      ],
                    ),
                    const SizedBox(height: D.e5),

                    // ─── Objetivos ─────────────────────────
                    Text(ref.t('mobile_dash_objetivos_titulo'), style: D.etiqueta),
                    const SizedBox(height: D.e3),
                    objetivosResumoAsync.when(
                      loading: () => const CardSimples(
                        child: Center(child: Padding(padding: EdgeInsets.all(D.e3), child: CircularProgressIndicator(color: D.azul600))),
                      ),
                      error: (_, __) => CardSimples(
                        child: Center(child: Text(ref.t('mobile_dash_objetivos_erro'), style: D.legenda)),
                      ),
                      data: (resumo) => _buildCardObjetivos(resumo, context),
                    ),
                    const SizedBox(height: D.e5),

                    // ─── Gamification — pódio ──────────────
                    Text(ref.t('mobile_dash_gamification_titulo'), style: D.etiqueta),
                    const SizedBox(height: D.e2),
                    podio.isEmpty
                        ? CardSimples(
                            child: Center(child: Text(ref.t('mobile_dash_ranking_vazio'), style: D.legenda)),
                          )
                        : GestureDetector(
                            onTap: () => context.push(AppConstants.routeRanking),
                            child: PodioRanking(
                              entradas: podio
                                  .map((r) => PodioEntrada(
                                        posicao: r.posicao,
                                        nome: r.nome,
                                        pontos: r.totalPontos,
                                        urlFoto: AppConstants.resolverUrlFicheiro(r.urlFoto),
                                        destacado: r.idUtilizador == consultor?.id,
                                      ))
                                  .toList(),
                            ),
                          ),
                    const SizedBox(height: D.e5),

                    // ─── O teu desempenho + mini-tabela de ranking ─────────
                    CardSimples(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ref.t('mobile_dash_desempenho_titulo'), style: D.tituloCard),
                          const SizedBox(height: D.e2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: D.e3, vertical: D.e2),
                            decoration: BoxDecoration(color: D.azul100, borderRadius: BorderRadius.circular(D.rSm)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  meuDesempenho != null ? '${meuDesempenho.posicao}ª Posição' : '— Posição',
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: D.azul600),
                                ),
                                Text(
                                  '${meuDesempenho?.totalPontos ?? 0} Pontos',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: D.azul600),
                                ),
                              ],
                            ),
                          ),
                          if (restoRanking.isNotEmpty) ...[
                            const SizedBox(height: D.e4),
                            Text(ref.t('mobile_dash_ranking_titulo'), style: D.tituloCard),
                            const SizedBox(height: D.e2),
                            for (final r in restoRanking) _buildLinhaRanking(r),
                          ],
                          const SizedBox(height: D.e2),
                          Center(
                            child: TextButton(
                              onPressed: () => context.push(AppConstants.routeGamification),
                              child: Text(ref.t('mobile_geral_ver_tudo'), style: const TextStyle(color: D.azul600, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: D.e5),

                    // ─── Badges Recomendados ──────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ref.t('mobile_dash_badges_recomendados_titulo'), style: D.etiqueta),
                        TextButton(
                          onPressed: () => context.push(AppConstants.routeCatalogo),
                          child: Text(ref.t('mobile_geral_ver_tudo'), style: const TextStyle(color: D.azul600, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    badgesRecomendadosAsync.when(
                      loading: () => const CardSimples(
                        child: Center(child: Padding(padding: EdgeInsets.all(D.e3), child: CircularProgressIndicator(color: D.azul600))),
                      ),
                      error: (_, __) => CardSimples(
                        child: Center(child: Text(ref.t('mobile_dash_badges_recomendados_erro'), style: D.legenda)),
                      ),
                      data: (recomendados) {
                        final filtrados = _pesquisa.isEmpty
                            ? recomendados
                            : recomendados.where((b) => b.nome.toLowerCase().contains(_pesquisa.toLowerCase())).toList();
                        if (filtrados.isEmpty) {
                          return CardSimples(
                            child: Center(child: Text(ref.t('mobile_dash_badges_recomendados_vazio'), style: D.legenda)),
                          );
                        }
                        return Column(
                          children: [for (final b in filtrados.take(3)) _buildBadgeRecomendadoItem(b)],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Cartão de resumo (Pedidos/Badges/Especiais/Objetivos) ────────────────
  Widget _buildCartaoResumo({required IconData icon, required int valor, required String label, VoidCallback? onTap}) {
    return CardSimples(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(D.e2),
            decoration: BoxDecoration(color: D.azul100, borderRadius: BorderRadius.circular(D.rSm)),
            child: Icon(icon, color: D.azul600, size: 20),
          ),
          const SizedBox(width: D.e2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$valor', style: D.tituloSeccao),
                Text(label, style: D.legenda.copyWith(fontSize: 10, height: 1.1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card de Objetivos: anel de progresso + áreas/SL + lista em curso ─────
  Widget _buildCardObjetivos(ObjetivosResumo resumo, BuildContext context) {
    return CardSimples(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: resumo.progressoLearningPath / 100,
                        strokeWidth: 10,
                        backgroundColor: D.fundoAlt,
                        color: D.azul600,
                      ),
                    ),
                    Text('${resumo.progressoLearningPath}%',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: D.azul600)),
                  ],
                ),
              ),
              const SizedBox(width: D.e4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${resumo.areasCompletas} Áreas Completas', style: D.corpo),
                    const SizedBox(height: 2),
                    Text(
                      '${resumo.serviceLinesConcluidas} Service Line${resumo.serviceLinesConcluidas == 1 ? '' : 's'} Concluída${resumo.serviceLinesConcluidas == 1 ? '' : 's'}',
                      style: D.corpo,
                    ),
                    const SizedBox(height: 2),
                    Text(ref.t('mobile_dash_objetivos_progresso_lp'), style: D.legenda),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: D.e4),
          Text(ref.t('mobile_dash_objetivos_em_progresso'), style: D.tituloCard),
          const SizedBox(height: D.e2),
          if (resumo.objetivosEmProgresso.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: D.e2),
              child: Text(ref.t('mobile_dash_objetivos_sem_curso'), style: D.legenda),
            )
          else
            for (final obj in resumo.objetivosEmProgresso) _buildLinhaObjetivoProgresso(obj),
          const SizedBox(height: D.e2),
          Center(
            child: TextButton(
              onPressed: () => context.push(AppConstants.routeObjetivos),
              child: Text(ref.t('mobile_geral_ver_tudo'), style: const TextStyle(color: D.azul600, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaObjetivoProgresso(ObjetivoProgresso obj) {
    final dataFimFormatada =
        '${obj.dataFim.day.toString().padLeft(2, '0')}/${obj.dataFim.month.toString().padLeft(2, '0')}/${obj.dataFim.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: D.e3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(obj.titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: obj.percentagem / 100,
              backgroundColor: D.fundoAlt,
              color: D.azul600,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(obj.textoProgresso, style: D.legenda),
              Text('Termina a $dataFimFormatada', style: D.legenda),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaRanking(RankingEntrada r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('${r.posicao}º', style: D.corpo)),
          Expanded(child: Text(r.nome, style: D.corpo, overflow: TextOverflow.ellipsis)),
          Text('${r.totalPontos} pts', style: D.corpo.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBadgeRecomendadoItem(BadgeRecomendado badge) {
    final cor = BadgeUtils.corDoNivel(badge.nomeNivel);
    final letra = (badge.nomeNivel?.isNotEmpty ?? false) ? badge.nomeNivel![0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: D.e2),
      child: CardSimples(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cor.withValues(alpha: 0.15),
                border: Border.all(color: cor, width: 2),
              ),
              child: badge.urlImagem != null
                  ? ClipOval(
                      child: Image.network(
                        AppConstants.resolverUrlFicheiro(badge.urlImagem)!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(letra, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(letra, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
            ),
            const SizedBox(width: D.e3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(badge.nome, style: D.tituloCard),
                  if (badge.nomeNivel != null) Text(badge.nomeNivel!, style: D.legenda),
                ],
              ),
            ),
            Column(
              children: [
                Text('${badge.numRequisitos}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: D.azul600)),
                Text(ref.t('mobile_geral_requisitos'), style: D.legenda.copyWith(fontSize: 11)),
              ],
            ),
            const SizedBox(width: D.e2),
            const Icon(Icons.chevron_right, color: D.tinta30),
          ],
        ),
      ),
    );
  }
}