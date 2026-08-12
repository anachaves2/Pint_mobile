import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/models/ranking_entrada.dart';
import 'package:pint_mobile/providers/ranking_provider.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';

/// Ecrã 45 do protótipo (GamificationRanking).
/// Lista completa, com pesquisa por nome e a linha do próprio destacada.
class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  final _controladorPesquisa = TextEditingController();
  String _pesquisa = '';

  @override
  void dispose() {
    _controladorPesquisa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(rankingProvider);
    final utilizador = ref.watch(utilizadorProvider).valueOrNull;

    return Scaffold(
      backgroundColor: D.fundo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppConstants.corPrimaria),
          onPressed: () => context.pop(),
        ),
        title: const Text('RANKING', style: D.tituloPagina),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg',
                height: 24,
                colorFilter: const ColorFilter.mode(
                    AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => context.push(AppConstants.routeNotificacoes),
          ),
        ],
      ),
      body: estado.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppConstants.corPrimaria)),
        error: (err, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(D.e6),
            child: Text('Não foi possível carregar o ranking.',
                style: D.legenda, textAlign: TextAlign.center),
          ),
        ),
        data: (ranking) {
          final filtrado = _pesquisa.isEmpty
              ? ranking
              : ranking
                  .where((r) =>
                      r.nome.toLowerCase().contains(_pesquisa.toLowerCase()))
                  .toList();

          return Column(
            children: [
              // ── Pesquisa ──
              Padding(
                padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e3),
                child: Container(
                  decoration: BoxDecoration(
                    color: D.superficie,
                    borderRadius: BorderRadius.circular(D.rSm),
                    boxShadow: D.elev1,
                  ),
                  child: TextField(
                    controller: _controladorPesquisa,
                    onChanged: (v) => setState(() => _pesquisa = v),
                    style: D.corpo.copyWith(color: D.tinta),
                    decoration: InputDecoration(
                      hintText: 'Procurar consultor',
                      hintStyle: D.corpo.copyWith(color: D.tinta30),
                      prefixIcon: const Icon(Icons.search,
                          size: 20, color: D.tinta30),
                      suffixIcon: _pesquisa.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: D.tinta30),
                              onPressed: () {
                                _controladorPesquisa.clear();
                                setState(() => _pesquisa = '');
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: D.e4, vertical: D.e3),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: filtrado.isEmpty
                    ? const Center(
                        child: Text('Nenhum consultor encontrado.',
                            style: D.legenda))
                    : RefreshIndicator(
                        color: AppConstants.corPrimaria,
                        onRefresh: () =>
                            ref.read(rankingProvider.notifier).atualizar(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              D.e4, 0, D.e4, D.e6),
                          itemCount: filtrado.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: D.e2),
                          itemBuilder: (_, i) => _Linha(
                            entrada: filtrado[i],
                            euMesmo:
                                filtrado[i].idUtilizador == utilizador?.id,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.entrada, required this.euMesmo});

  final RankingEntrada entrada;
  final bool euMesmo;

  @override
  Widget build(BuildContext context) {
    final conteudo = Row(
      children: [
        // Posição
        SizedBox(
          width: 32,
          child: Text(
            '${entrada.posicao}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: entrada.posicao <= 3 ? D.azul600 : D.tinta50,
            ),
          ),
        ),
        const SizedBox(width: D.e2),

        // Avatar
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: D.podioCirculoBg,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: entrada.urlFoto != null && entrada.urlFoto!.isNotEmpty
              ? Image.network(entrada.urlFoto!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _iniciais())
              : _iniciais(),
        ),
        const SizedBox(width: D.e3),

        // Nome
        Expanded(
          child: Text(
            entrada.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: D.tituloCard.copyWith(
              color: euMesmo ? D.azul600 : D.tinta,
              fontWeight: euMesmo ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),

        // Evolução
        _seta(),
        const SizedBox(width: D.e3),

        // Pontos
        Text('${entrada.totalPontos}',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: D.azul600)),
        const SizedBox(width: 2),
        Text('pts', style: D.legenda.copyWith(fontSize: 11)),
      ],
    );

    // A própria linha do utilizador usa o card de gradiente para se destacar
    return euMesmo
        ? CardGradiente(
            padding: const EdgeInsets.symmetric(
                horizontal: D.e3, vertical: D.e3),
            child: conteudo,
          )
        : CardSimples(
            padding: const EdgeInsets.symmetric(
                horizontal: D.e3, vertical: D.e3),
            child: conteudo,
          );
  }

  Widget _seta() {
    if (entrada.manteve) {
      return const Icon(Icons.remove, size: 14, color: D.tinta30);
    }
    return Icon(
      entrada.subiu ? Icons.arrow_upward : Icons.arrow_downward,
      size: 14,
      color: entrada.subiu ? D.ok : D.erro,
    );
  }

  Widget _iniciais() {
    final partes = entrada.nome.trim().split(RegExp(r'\s+'));
    final txt = partes.length >= 2
        ? '${partes.first[0]}${partes.last[0]}'
        : (partes.first.isNotEmpty ? partes.first[0] : '?');

    return Center(
      child: Text(
        txt.toUpperCase(),
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: D.podioCirculoTexto),
      ),
    );
  }
}