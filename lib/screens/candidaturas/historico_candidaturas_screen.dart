import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/candidatura_badge.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/providers/candidatura_provider.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

class HistoricoCandidaturas extends ConsumerStatefulWidget {
  const HistoricoCandidaturas({super.key});

  @override
  ConsumerState<HistoricoCandidaturas> createState() => _HistoricoCandidaturasState();
}

class _HistoricoCandidaturasState extends ConsumerState<HistoricoCandidaturas> {

  @override
  void initState() {
    super.initState();
    // Quando chega uma actualização, invalida o provider para recarregar a lista
    atualizadorDados.stream.listen((_) {
      ref.invalidate(candidaturasProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: SvgPicture.asset('assets/icons/drawerprimario.svg', height: 20,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Candidaturas',
            style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg', height: 24,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => context.push(AppConstants.routeNotificacoes),
          ),
        ],
      ),
      // Riverpod - filtra apenas as candidaturas concluídas (aprovadas ou rejeitadas)
      body: ref.watch(candidaturasProvider).when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppConstants.corPrimaria)),
        error: (err, _) => Center(child: Text('Erro: $err')),
        data: (todas) {
          // Filtra apenas as candidaturas que já estão concluídas
          final historico = todas.where((c) => c.estaConcluida).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left, color: AppConstants.corPrimaria),
                    ),
                    const Text('Histórico de Candidaturas',
                        style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black12),
              Expanded(
                child: RefreshIndicator(
                  color: AppConstants.corPrimaria,
                  // Sincroniza com a API e invalida o provider para actualizar a lista
                  onRefresh: () async {
                    await APIService.instance.sincronizarCandidaturas();
                    ref.invalidate(candidaturasProvider);
                  },
                  child: historico.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 80),
                          Center(child: Column(children: [
                            Icon(Icons.history, size: 56, color: Colors.grey),
                            SizedBox(height: 10),
                            Text('Ainda não tens candidaturas concluídas.',
                                style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ])),
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: historico.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                          itemBuilder: (context, i) => _CardHistorico(
                            candidatura: historico[i],
                            onTap: () => context.push(
                              AppConstants.routeDetalheCandidatura,
                              extra: historico[i].numCandidatura,
                            ).then((_) => ref.invalidate(candidaturasProvider)),
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

// Card de cada candidatura do histórico: mostra o resultado final (Aprovado/Rejeitado)
class _CardHistorico extends StatelessWidget {
  final CandidaturaBadge candidatura;
  final VoidCallback onTap;

  const _CardHistorico({required this.candidatura, required this.onTap});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year.toString().substring(2)}';

  @override
  Widget build(BuildContext context) {
    final aprovada = candidatura.aprovada;
    // Verde se aprovada, vermelho se rejeitada
    final corDecisao = aprovada ? AppConstants.corSucesso : AppConstants.corErro;
    final textoDecisao = aprovada ? 'Aprovado' : 'Rejeitado';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(candidatura.nomeBadge,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
            if (candidatura.nomeNivel != null)
              Text('Nível ${candidatura.nomeNivel!}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.black38),
                const SizedBox(width: 4),
                Text('Criado em: ${_fmt(candidatura.dataCriacao)}',
                    style: const TextStyle(fontSize: 11, color: Colors.black38)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Fechado',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black54)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: corDecisao.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(textoDecisao,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: corDecisao)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}